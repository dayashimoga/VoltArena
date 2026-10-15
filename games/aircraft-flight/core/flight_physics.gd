class_name FlightPhysicsBody
extends CharacterBody3D

## FlightPhysicsBody: Authentic 6-DOF Aerodynamic Simulation Engine.
## Computes genuine lift, drag, thrust, gravity, angle of attack, stalls,
## ground effect, gear suspension, progressive braking, and rotorcraft dynamics.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")

# Aerodynamic Aircraft Properties
@export var aircraft_name: String = "F/A-18 Hornet"
@export var aircraft_type: FlightConst.AircraftType = FlightConst.AircraftType.FIGHTER_JET
@export var mass_kg: float = 12000.0
@export var wing_area: float = 38.0 # m^2 (Wing reference area S)
@export var wingspan: float = 12.3 # m (Wingspan b)
@export var aspect_ratio: float = 4.0 # AR = b^2 / S
@export var oswald_efficiency: float = 0.85 # e
@export var zero_lift_drag_cd0: float = 0.022 # CD0 parasite drag
@export var max_thrust_n: float = 98000.0 # Dry military thrust in Newtons
@export var afterburner_multiplier: float = 1.65 # Afterburner / WEP thrust multiplier
@export var has_afterburner: bool = true
@export var is_rotorcraft: bool = false
@export var stall_speed_ms: float = 42.0 # ~150 km/h clean
@export var max_speed_ms: float = 580.0 # ~Mach 1.7 at altitude
@export var max_g_rating: float = 9.0

# Dynamic Pitch, Roll, Yaw Control Rates (rad/s^2)
@export var pitch_authority: float = 2.4
@export var roll_authority: float = 4.5
@export var yaw_authority: float = 1.5
@export var pitch_damping: float = 3.2
@export var roll_damping: float = 4.8
@export var yaw_damping: float = 2.8

# Landing Gear & Ground Handling
@export var gear_height_offset: float = 1.8 # Distance from origin to wheels
@export var suspension_spring_stiffness: float = 120000.0 # N/m
@export var suspension_damper: float = 14000.0 # N/(m/s)
@export var wheel_friction_rolling: float = 0.03
@export var wheel_friction_braking: float = 0.75

# Runtime State & Telemetry
var throttle: float = 0.0 # 0.0 to 1.0
var afterburner_active: bool = false
var flaps_step: int = 0 # 0 = Retracted, 1 = Takeoff (15 deg), 2 = Landing (35 deg)
var gear_deployed: bool = true
var gear_position: float = 1.0 # 0.0 retracted to 1.0 fully down
var airbrake_deployed: bool = false
var wheel_brakes_active: bool = false

var indicated_airspeed_ms: float = 0.0
var indicated_airspeed_kmh: float = 0.0
var true_airspeed_ms: float = 0.0
var mach_number: float = 0.0
var barometric_altitude_m: float = 0.0
var radar_altitude_m: float = 0.0
var vertical_speed_ms: float = 0.0
var angle_of_attack_deg: float = 0.0
var sideslip_angle_deg: float = 0.0
var g_force_current: float = 1.0
var is_stalling: bool = false
var stall_severity: float = 0.0
var engine_rpm_pct: float = 0.0
var fuel_level_pct: float = 100.0
var airframe_damage_pct: float = 0.0

# Pilot Inputs (-1.0 to +1.0)
var input_pitch: float = 0.0
var input_roll: float = 0.0
var input_yaw: float = 0.0

# Control Surface Deflections (-1.0 to 1.0)
var elevator_deflection: float = 0.0
var aileron_left_deflection: float = 0.0
var aileron_right_deflection: float = 0.0
var rudder_deflection: float = 0.0
var flap_deflection: float = 0.0

# Dynamic Internal Vectors
var angular_velocity: Vector3 = Vector3.ZERO
var local_velocity: Vector3 = Vector3.ZERO
var is_airborne: bool = false
var flight_mode: FlightConst.FlightMode = FlightConst.FlightMode.SIMCADE
var flight_assist_enabled: bool = true
var autopilot_active: bool = false

# Rotorcraft specific states
var collective_pitch: float = 0.0 # 0.0 to 1.0 for helicopters
var rotor_rpm_pct: float = 0.0

# Signals
signal touchdown(impact_velocity: float)
signal stall_warning_triggered(severity: float)
signal aircraft_crashed(reason: String)
signal over_g_warning(current_g: float)

func _ready() -> void:
	motion_mode = MOTION_MODE_GROUNDED
	wall_min_slide_angle = deg_to_rad(15.0)

func setup_aircraft_specs(specs: Dictionary) -> void:
	aircraft_name = specs.get("name", aircraft_name)
	aircraft_type = specs.get("type", aircraft_type)
	mass_kg = specs.get("mass_kg", mass_kg)
	wing_area = specs.get("wing_area", wing_area)
	wingspan = specs.get("wingspan", wingspan)
	aspect_ratio = specs.get("aspect_ratio", aspect_ratio)
	oswald_efficiency = specs.get("oswald_efficiency", oswald_efficiency)
	zero_lift_drag_cd0 = specs.get("cd0", zero_lift_drag_cd0)
	max_thrust_n = specs.get("max_thrust_n", max_thrust_n)
	afterburner_multiplier = specs.get("afterburner_multiplier", afterburner_multiplier)
	has_afterburner = specs.get("has_afterburner", has_afterburner)
	is_rotorcraft = specs.get("is_rotorcraft", is_rotorcraft)
	stall_speed_ms = specs.get("stall_speed_ms", stall_speed_ms)
	max_speed_ms = specs.get("max_speed_ms", max_speed_ms)
	max_g_rating = specs.get("max_g_rating", max_g_rating)
	pitch_authority = specs.get("pitch_authority", pitch_authority)
	roll_authority = specs.get("roll_authority", roll_authority)
	yaw_authority = specs.get("yaw_authority", yaw_authority)

func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return

	# 1. Update Altitudes & Atmospheric Conditions
	barometric_altitude_m = global_position.y if is_inside_tree() else position.y
	_update_radar_altitude()
	var air_density = _compute_air_density(barometric_altitude_m)

	# 2. Compute Local Velocities in Aircraft Frame
	# Forward: -transform.basis.z, Up: transform.basis.y, Right: transform.basis.x
	var cur_xform = global_transform if is_inside_tree() else transform
	var fwd_dir = -cur_xform.basis.z.normalized()
	var up_dir = cur_xform.basis.y.normalized()
	var right_dir = cur_xform.basis.x.normalized()

	var v_fwd = velocity.dot(fwd_dir)
	var v_up = velocity.dot(up_dir)
	var v_right = velocity.dot(right_dir)
	local_velocity = Vector3(v_right, v_up, v_fwd)

	indicated_airspeed_ms = maxf(0.0, v_fwd)
	indicated_airspeed_kmh = indicated_airspeed_ms * 3.6
	true_airspeed_ms = velocity.length()
	vertical_speed_ms = velocity.y
	mach_number = true_airspeed_ms / FlightConst.SOUND_SPEED_SEA_LEVEL

	# 3. Dynamic Pressure & Angles of Attack
	var speed_sq = velocity.length_squared()
	var dynamic_pressure = 0.5 * air_density * speed_sq

	if indicated_airspeed_ms > 1.0:
		angle_of_attack_deg = rad_to_deg(atan2(-v_up, indicated_airspeed_ms))
		sideslip_angle_deg = rad_to_deg(atan2(v_right, indicated_airspeed_ms))
	else:
		angle_of_attack_deg = 0.0
		sideslip_angle_deg = 0.0

	# 4. Compute Aerodynamic Forces
	var total_force = Vector3.ZERO

	if is_rotorcraft:
		total_force += _compute_rotorcraft_forces(delta, air_density)
	else:
		total_force += _compute_fixed_wing_forces(delta, air_density, dynamic_pressure)

	# 5. Add Gravity Force (W = m * g)
	var gravity_force = Vector3(0.0, -mass_kg * FlightConst.GRAVITY, 0.0)
	total_force += gravity_force

	# 6. Landing Gear & Ground Contact Reactions
	var ground_normal = Vector3.UP
	var ground_contact = false
	if radar_altitude_m <= gear_height_offset + 0.2:
		var gr_force = _compute_ground_reaction_forces(delta, v_fwd, v_right)
		total_force += gr_force
		ground_contact = true

	# 7. Integrate Linear Acceleration (F = m * a)
	var linear_accel = total_force / mass_kg
	velocity += linear_accel * delta

	# Calculate G-Force (Load Factor normal to wings)
	var normal_accel = linear_accel.dot(up_dir) + FlightConst.GRAVITY * up_dir.y
	g_force_current = clampf(normal_accel / FlightConst.GRAVITY, -4.0, 12.0)
	if g_force_current > max_g_rating:
		over_g_warning.emit(g_force_current)

	# 8. Compute Angular Moments and Integrate Rotations
	_integrate_aerodynamic_moments(delta, dynamic_pressure, v_fwd)

	# 9. Perform CharacterBody3D Collision & Movement
	move_and_slide()

	# 10. Post-Move Ground Status Check
	var was_airborne = is_airborne
	is_airborne = not is_on_floor() and radar_altitude_m > gear_height_offset + 0.5
	if not was_airborne and is_airborne:
		# Lift-off!
		pass
	elif was_airborne and not is_airborne:
		# Touchdown!
		touchdown.emit(absf(v_up))

	# 11. Animate Retractable Gear & Deflections
	_update_control_surfaces_and_gear(delta)

func _compute_air_density(altitude: float) -> float:
	# Standard troposphere lapse model
	var alt_clamped = maxf(0.0, altitude)
	var lapse = maxf(0.18, 1.0 - 0.000095 * alt_clamped)
	return FlightConst.AIR_DENSITY_SEA_LEVEL * pow(lapse, 4.256)

func _update_radar_altitude() -> void:
	if not is_inside_tree() or get_world_3d() == null:
		radar_altitude_m = maxf(0.0, position.y)
		return

	var space_state = get_world_3d().direct_space_state
	if not space_state:
		radar_altitude_m = maxf(0.0, global_position.y)
		return

	var origin = global_position
	var end = origin + Vector3.DOWN * 2000.0
	var query = PhysicsRayQueryParameters3D.create(origin, end, 1) # Layer 1 World
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		radar_altitude_m = maxf(0.0, global_position.y)
	else:
		radar_altitude_m = maxf(0.0, origin.distance_to(result.position))

func _compute_fixed_wing_forces(delta: float, density: float, q: float) -> Vector3:
	var cur_xform = global_transform if is_inside_tree() else transform
	var fwd_dir = -cur_xform.basis.z.normalized()
	var up_dir = cur_xform.basis.y.normalized()
	var right_dir = cur_xform.basis.x.normalized()

	# --- Thrust ---
	var current_thrust_rating = max_thrust_n
	if has_afterburner and afterburner_active and throttle >= 0.95:
		current_thrust_rating *= afterburner_multiplier

	# Engine spool-up smoothing
	engine_rpm_pct = move_toward(engine_rpm_pct, throttle * 100.0, delta * 35.0)
	var thrust_magnitude = current_thrust_rating * (engine_rpm_pct / 100.0)
	var thrust_force = fwd_dir * thrust_magnitude

	# --- Lift Coefficient with Stall Polar ---
	var alpha_rad = deg_to_rad(angle_of_attack_deg)
	var cl: float = 0.0

	# Flap lift increment
	var cl_flap = 0.0
	if flaps_step == 1:
		cl_flap = 0.35
	elif flaps_step == 2:
		cl_flap = 0.70

	var crit_aoa = FlightConst.CRITICAL_AOA_RAD
	if absf(alpha_rad) <= crit_aoa:
		# Linear lift curve: CL = 2 * PI * alpha + flaps
		cl = 5.2 * alpha_rad + cl_flap + 0.15 # Camber baseline
		is_stalling = false
		stall_severity = 0.0
	else:
		# Post-stall collapse
		var stall_excess = absf(alpha_rad) - crit_aoa
		var stall_drop = exp(-stall_excess * 4.0)
		cl = signf(alpha_rad) * (5.2 * crit_aoa * stall_drop) + (cl_flap * 0.5)
		is_stalling = true
		stall_severity = clampf(stall_excess / deg_to_rad(15.0), 0.0, 1.0)
		stall_warning_triggered.emit(stall_severity)

	# Ground effect: Induced drag reduced and lift boosted within 1 wingspan of ground
	var ground_effect_factor: float = 1.0
	if radar_altitude_m < wingspan:
		var h_ratio = clampf(radar_altitude_m / wingspan, 0.0, 1.0)
		ground_effect_factor = 1.0 + 0.28 * (1.0 - h_ratio) * (1.0 - h_ratio)

	var lift_magnitude = q * wing_area * cl * ground_effect_factor
	var lift_force = up_dir * lift_magnitude

	# --- Drag Polar: CD = CD0 + k * CL^2 + CD_gear + CD_flaps + CD_airbrake ---
	var k_induced = 1.0 / (PI * aspect_ratio * oswald_efficiency)
	# Ground effect reduces induced drag:
	if radar_altitude_m < wingspan:
		var h_ratio = clampf(radar_altitude_m / wingspan, 0.0, 1.0)
		k_induced *= clampf((16.0 * h_ratio) / (1.0 + 16.0 * h_ratio), 0.35, 1.0)

	var cd_induced = k_induced * (cl * cl)
	var cd_gear = 0.035 * gear_position
	var cd_flaps = (0.02 if flaps_step == 1 else (0.055 if flaps_step == 2 else 0.0))
	var cd_airbrake = 0.08 if airbrake_deployed else 0.0

	var total_cd = zero_lift_drag_cd0 + cd_induced + cd_gear + cd_flaps + cd_airbrake
	var drag_magnitude = q * wing_area * total_cd
	var vel_norm = velocity.normalized() if velocity.length_squared() > 0.01 else fwd_dir
	var drag_force = -vel_norm * drag_magnitude

	return thrust_force + lift_force + drag_force

func _compute_rotorcraft_forces(delta: float, density: float) -> Vector3:
	var cur_xform = global_transform if is_inside_tree() else transform
	var fwd_dir = -cur_xform.basis.z.normalized()
	var up_dir = cur_xform.basis.y.normalized()
	var right_dir = cur_xform.basis.x.normalized()

	# Helicopter rotor RPM
	rotor_rpm_pct = move_toward(rotor_rpm_pct, 100.0 if throttle > 0.05 else 0.0, delta * 30.0)
	var rotor_avail = rotor_rpm_pct / 100.0

	# Collective modulates main rotor thrust
	var hover_thrust = mass_kg * FlightConst.GRAVITY
	var max_heli_thrust = hover_thrust * 1.85
	var main_thrust = collective_pitch * max_heli_thrust * rotor_avail

	# Ground effect cushion for hovering
	if radar_altitude_m < wingspan * 1.2:
		var h_ratio = clampf(radar_altitude_m / (wingspan * 1.2), 0.0, 1.0)
		main_thrust *= (1.0 + 0.35 * (1.0 - h_ratio))

	# Cyclic tilts rotor thrust vector relative to fuselage
	var cyclic_tilt = Vector3(input_roll * 0.22, 1.0, -input_pitch * 0.25).normalized()
	var thrust_vector = (right_dir * cyclic_tilt.x + up_dir * cyclic_tilt.y + fwd_dir * cyclic_tilt.z).normalized()
	var main_rotor_force = thrust_vector * main_thrust

	# Fuselage air parasite drag
	var speed_sq = velocity.length_squared()
	var drag_force = -velocity.normalized() * (0.5 * density * speed_sq * 4.5 * 0.45)

	return main_rotor_force + drag_force

func _compute_ground_reaction_forces(delta: float, v_fwd: float, v_right: float) -> Vector3:
	var cur_xform = global_transform if is_inside_tree() else transform
	var fwd_dir = -cur_xform.basis.z.normalized()
	var right_dir = cur_xform.basis.x.normalized()
	var reaction = Vector3.ZERO

	# Compression depth of gear struts
	var compression = clampf(gear_height_offset - radar_altitude_m, 0.0, 0.8)
	if compression > 0.0 and gear_position > 0.8:
		# Spring + Damping
		var v_vertical = velocity.y
		var spring_force = compression * suspension_spring_stiffness
		var damper_force = -v_vertical * suspension_damper
		var normal_force = maxf(0.0, spring_force + damper_force)
		reaction += Vector3.UP * normal_force

		# Rolling friction & Wheel braking
		var current_friction = wheel_friction_rolling
		if wheel_brakes_active or airbrake_deployed:
			current_friction = wheel_friction_braking

		# Deceleration forces opposing forward and lateral roll
		var brake_drag = -signf(v_fwd) * minf(absf(v_fwd) * mass_kg * 8.0, normal_force * current_friction)
		var lateral_scrub = -signf(v_right) * minf(absf(v_right) * mass_kg * 12.0, normal_force * 0.85)

		reaction += fwd_dir * brake_drag + right_dir * lateral_scrub

	return reaction

func _integrate_aerodynamic_moments(delta: float, q: float, v_fwd: float) -> void:
	# Surface effectiveness scales with forward airspeed:
	var surface_effectiveness = clampf(v_fwd / 35.0, 0.15, 1.25)
	if is_rotorcraft:
		surface_effectiveness = clampf(rotor_rpm_pct / 100.0, 0.2, 1.0)

	# Pilot commanded torques
	var cmd_pitch = input_pitch
	var cmd_roll = input_roll
	var cmd_yaw = input_yaw

	# Autopilot / Flight Assists:
	if flight_assist_enabled or flight_mode == FlightConst.FlightMode.ARCADE:
		# Auto-trim pitch and roll stabilization
		var cur_xform = global_transform if is_inside_tree() else transform
		var current_roll_deg = rad_to_deg(cur_xform.basis.get_euler().z)
		var current_pitch_deg = rad_to_deg(cur_xform.basis.get_euler().x)

		if absf(input_roll) < 0.05 and is_airborne:
			cmd_roll -= clampf(current_roll_deg * 0.035, -0.6, 0.6)
		if absf(input_pitch) < 0.05 and is_airborne:
			cmd_pitch -= clampf(current_pitch_deg * 0.02, -0.4, 0.4)

		# Coordinated turn assist (rudder automatically follows roll)
		if absf(input_yaw) < 0.05 and absf(input_roll) > 0.1:
			cmd_yaw += input_roll * 0.25

	# Calculate angular accelerations (rad/s^2)
	var target_pitch_accel = cmd_pitch * pitch_authority * surface_effectiveness - angular_velocity.x * pitch_damping
	var target_roll_accel = cmd_roll * roll_authority * surface_effectiveness - angular_velocity.z * roll_damping
	var target_yaw_accel = cmd_yaw * yaw_authority * surface_effectiveness - angular_velocity.y * yaw_damping

	# Adverse yaw / directional stability damping
	if not is_rotorcraft and absf(sideslip_angle_deg) > 1.0:
		target_yaw_accel -= deg_to_rad(sideslip_angle_deg) * 2.2

	# Post-stall buffet jitter:
	if is_stalling and stall_severity > 0.2:
		var buffet = sin(Time.get_ticks_msec() * 0.05) * stall_severity * 0.8
		target_pitch_accel += buffet
		target_roll_accel += buffet * 1.5

	# Angular acceleration integration
	angular_velocity.x += target_pitch_accel * delta
	angular_velocity.y += target_yaw_accel * delta
	angular_velocity.z += target_roll_accel * delta

	# Apply rotation to aircraft basis:
	# Pitch (local X), Yaw (local Y), Roll (local Z)
	rotate_object_local(Vector3.RIGHT, angular_velocity.x * delta)
	rotate_object_local(Vector3.UP, angular_velocity.y * delta)
	rotate_object_local(Vector3.FORWARD, angular_velocity.z * delta)

	# Store deflection states for visuals:
	elevator_deflection = move_toward(elevator_deflection, cmd_pitch, delta * 8.0)
	aileron_left_deflection = move_toward(aileron_left_deflection, cmd_roll, delta * 10.0)
	aileron_right_deflection = -aileron_left_deflection
	rudder_deflection = move_toward(rudder_deflection, cmd_yaw, delta * 8.0)
	flap_deflection = float(flaps_step) / 2.0

func _update_control_surfaces_and_gear(delta: float) -> void:
	# Smooth landing gear retraction/extension
	var target_gear = 1.0 if gear_deployed else 0.0
	gear_position = move_toward(gear_position, target_gear, delta * 0.75)

# --- Public Pilot Input API ---
func set_pilot_inputs(pitch: float, roll: float, yaw: float) -> void:
	input_pitch = clampf(pitch, -1.0, 1.0)
	input_roll = clampf(roll, -1.0, 1.0)
	input_yaw = clampf(yaw, -1.0, 1.0)

func set_throttle(new_throttle: float) -> void:
	throttle = clampf(new_throttle, 0.0, 1.0)
	if is_rotorcraft:
		collective_pitch = throttle

func adjust_throttle(delta_throttle: float) -> void:
	set_throttle(throttle + delta_throttle)

func set_afterburner(active: bool) -> void:
	afterburner_active = active and has_afterburner

func toggle_landing_gear() -> void:
	gear_deployed = not gear_deployed

func cycle_flaps() -> void:
	flaps_step = (flaps_step + 1) % 3

func set_airbrake(active: bool) -> void:
	airbrake_deployed = active

func set_wheel_brakes(active: bool) -> void:
	wheel_brakes_active = active

func recover_to_safe_flight(pos: Vector3, heading_deg: float, speed_kmh: float, airborne: bool) -> void:
	var rot_y = deg_to_rad(heading_deg)
	var new_basis = Basis(Vector3.UP, rot_y)
	if is_inside_tree():
		global_position = pos
		global_basis = new_basis
	else:
		position = pos
		basis = new_basis
	angular_velocity = Vector3.ZERO

	var speed_ms = speed_kmh / 3.6
	var fwd = -new_basis.z.normalized()
	velocity = fwd * speed_ms

	if airborne:
		gear_deployed = false
		gear_position = 0.0
		throttle = 0.75
		flaps_step = 0
		is_airborne = true
	else:
		gear_deployed = true
		gear_position = 1.0
		throttle = 0.0
		flaps_step = 0
		is_airborne = false
		wheel_brakes_active = true

	is_stalling = false
	stall_severity = 0.0
	airframe_damage_pct = 0.0
