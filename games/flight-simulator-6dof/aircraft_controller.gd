class_name AircraftController
extends RigidBody3D

## Principal 6-DoF Aircraft Flight Dynamics Controller.
## Coordinates ISA atmosphere, engine thermodynamics, propeller thrust,
## control surface animation, landing gear, stall warning horn with WoW interlock,
## and cockpit/chase camera views.

signal flight_telemetry_updated(data: Dictionary)
signal stall_warning_changed(is_stalling: bool)
signal gear_toggled(is_down: bool)
signal flaps_changed(stage_index: int, angle_deg: float)

# Configuration Constants
const AIR_MOLAR_MASS: float = 0.0289644
const UNIVERSAL_GAS_CONST: float = 8.31432
const SPECIFIC_GAS_CONST: float = 287.058
const GRAVITY_CONST: float = 9.80665
const ADIABATIC_INDEX: float = 1.4

# Aircraft Specs (Standard 4-Seat Tourer / Trainer, e.g. Cirrus SR20 / C172SP)
@export var aircraft_name: String = "Volt Trainer 6-DoF"
@export var empty_mass_kg: float = 850.0
@export var fuel_mass_kg: float = 150.0
@export var payload_mass_kg: float = 150.0 # Total 1150 kg
@export var max_engine_power_watts: float = 155000.0 # ~210 HP
@export var prop_diameter_m: float = 1.90
@export var prop_efficiency_eta: float = 0.82
@export var idle_rpm: float = 800.0
@export var max_rpm: float = 2700.0
@export var stall_warning_aoa_deg: float = 13.5 ## Specified inboard stall threshold

# Pilot Controls
var throttle_input: float = 0.0
var pitch_input: float = 0.0
var roll_input: float = 0.0
var rudder_input: float = 0.0
var pitch_trim: float = 0.0
var brake_input: float = 0.0
var parking_brake_engaged: bool = false
var gear_extended: bool = true
var flaps_index: int = 0 # 0: 0 deg, 1: 15 deg (takeoff), 2: 35 deg (landing)
var flaps_angles: Array[float] = [0.0, 15.0, 35.0]

# Engine & Propeller State
var current_rpm: float = 800.0
var current_power_watts: float = 0.0
var current_thrust_n: float = 0.0
var prop_slipstream_vel: Vector3 = Vector3.ZERO
var prop_rotation_angle: float = 0.0

# Telemetry State
var altitude_msl: float = 0.0
var altitude_agl: float = 0.0
var airspeed_tas: float = 0.0 # True Airspeed (m/s)
var airspeed_ias: float = 0.0 # Indicated Airspeed (m/s)
var airspeed_kias: float = 0.0 # Knots Indicated Airspeed
var vertical_speed_fpm: float = 0.0 # Feet per minute
var current_g_force: float = 1.0
var weight_on_wheels: bool = true
var stall_horn_active: bool = false
var max_inboard_aoa_deg: float = 0.0

# Node References
var center_of_mass_node: Node3D
var aero_container: Node3D
var landing_gear_container: Node3D
var visual_airframe: Node3D
var prop_blur_mesh: MeshInstance3D
var cockpit_camera: Camera3D
var chase_spring_arm: SpringArm3D
var chase_camera: Camera3D
var engine_audio: AudioStreamPlayer3D
var wind_audio: AudioStreamPlayer3D
var stall_audio: AudioStreamPlayer3D
var tire_audio: AudioStreamPlayer3D
var left_vortex: GPUParticles3D
var right_vortex: GPUParticles3D
var hud_node: Control

var _aero_surfaces: Array[AeroSurface3D] = []
var _wheels: Array[RaycastWheel3D] = []
var _current_camera_mode: int = 0 # 0: Chase, 1: Cockpit
var _previous_linear_vel: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Configure RigidBody3D specifications
	mass = empty_mass_kg + fuel_mass_kg + payload_mass_kg # 1150 kg
	continuous_cd = true
	can_sleep = false
	custom_integrator = false
	linear_damp = 0.0
	angular_damp = 0.0

	_cache_nodes()
	_configure_center_of_mass()
	_setup_audio_players()

func _cache_nodes() -> void:
	center_of_mass_node = get_node_or_null("CenterOfMass")
	aero_container = get_node_or_null("AerodynamicsContainer")
	landing_gear_container = get_node_or_null("LandingGearContainer")
	visual_airframe = get_node_or_null("VisualAirframe")
	prop_blur_mesh = get_node_or_null("VisualAirframe/PropellerBlurDisk")

	var cam_rig = get_node_or_null("CameraRig")
	if cam_rig:
		cockpit_camera = cam_rig.get_node_or_null("CockpitCamera")
		chase_spring_arm = cam_rig.get_node_or_null("ChaseSpringArm")
		if chase_spring_arm:
			chase_camera = chase_spring_arm.get_node_or_null("ChaseCamera")

	var hud_layer = get_node_or_null("CockpitHUDLayer")
	if hud_layer:
		hud_node = hud_layer.get_node_or_null("CockpitHUD")

	_aero_surfaces.clear()
	if aero_container:
		for c in aero_container.get_children():
			if c is AeroSurface3D:
				_aero_surfaces.append(c)

	_wheels.clear()
	if landing_gear_container:
		for c in landing_gear_container.get_children():
			if c is RaycastWheel3D:
				_wheels.append(c)

func _configure_center_of_mass() -> void:
	# COM offset at (0, 0, -0.15) relative to geometric center
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.0, -0.15)

func _setup_audio_players() -> void:
	var audio_rig = get_node_or_null("AudioRig")
	if not audio_rig:
		return
	engine_audio = audio_rig.get_node_or_null("EngineAudio")
	wind_audio = audio_rig.get_node_or_null("WindAudio")
	stall_audio = audio_rig.get_node_or_null("StallHornAudio")
	tire_audio = audio_rig.get_node_or_null("TireAudio")

func _physics_process(delta: float) -> void:
	_read_inputs(delta)

	# 1. Atmospheric Model (ISA up to 20,000m)
	altitude_msl = global_position.y
	_update_altitude_agl()
	var atmo = calculate_isa_atmosphere(altitude_msl)
	var air_density = atmo["density"]
	var speed_of_sound = atmo["speed_of_sound"]

	# 2. Engine and Propeller Thrust Simulation
	_update_engine_and_propeller(delta, air_density)

	# 3. Aerodynamic Surfaces Force Integration
	_update_aerodynamics(delta, air_density)

	# 4. Landing Gear Suspension & Tire Friction
	_update_landing_gear(delta)

	# 5. Telemetry & G-Force Calculations
	_update_telemetry(delta, air_density, speed_of_sound)

	# 6. Audio, Visuals & Animations
	_update_visuals_and_audio(delta)

func _read_inputs(delta: float) -> void:
	# Read flight controls with deadzone handled by InputManager or local mapping
	var raw_pitch = Input.get_axis("pitch_up", "pitch_down") # nose up/down
	var raw_roll = Input.get_axis("roll_left", "roll_right")
	var raw_yaw = Input.get_axis("yaw_left", "yaw_right")

	pitch_input = lerp(pitch_input, raw_pitch, 18.0 * delta)
	roll_input = lerp(roll_input, raw_roll, 18.0 * delta)
	rudder_input = lerp(rudder_input, raw_yaw, 18.0 * delta)

	# Throttle increment/decrement
	if Input.is_action_pressed("throttle_up"):
		throttle_input = clamp(throttle_input + 0.35 * delta, 0.0, 1.0)
	elif Input.is_action_pressed("throttle_down"):
		throttle_input = clamp(throttle_input - 0.35 * delta, 0.0, 1.0)

	# Wheel Brakes
	brake_input = 1.0 if Input.is_action_pressed("wheel_brakes") else 0.0

	# Parking brake toggle
	if Input.is_action_just_pressed("parking_brake"):
		parking_brake_engaged = not parking_brake_engaged

	# Landing gear toggle
	if Input.is_action_just_pressed("landing_gear"):
		toggle_landing_gear()

	# Flaps toggle
	if Input.is_action_just_pressed("flaps_cycle"):
		cycle_flaps()

	# Camera toggle
	if Input.is_action_just_pressed("camera_toggle"):
		toggle_camera_mode()

## Cycles flap settings: 0 (clean) -> 1 (takeoff 15 deg) -> 2 (landing 35 deg) -> 0
func cycle_flaps() -> void:
	flaps_index = (flaps_index + 1) % flaps_angles.size()
	flaps_changed.emit(flaps_index, flaps_angles[flaps_index])

## Toggles landing gear if not blocked by ground contact
func toggle_landing_gear() -> void:
	if weight_on_wheels and gear_extended:
		# Safety interlock: cannot retract gear while on ground
		return
	gear_extended = not gear_extended
	gear_toggled.emit(gear_extended)
	for w in _wheels:
		w.enabled = gear_extended

func toggle_camera_mode() -> void:
	_current_camera_mode = 1 if _current_camera_mode == 0 else 0
	if cockpit_camera and chase_camera:
		cockpit_camera.current = (_current_camera_mode == 1)
		chase_camera.current = (_current_camera_mode == 0)

## Computes International Standard Atmosphere (ISA) parameters up to 20,000m.
## Returns Dictionary with temperature (K), pressure (Pa), density (kg/m^3), speed_of_sound (m/s).
static func calculate_isa_atmosphere(alt_m: float) -> Dictionary:
	var h = clamp(alt_m, -500.0, 20000.0)
	var t0 = 288.15
	var p0 = 101325.0
	var lapse_rate = 0.0065
	var r_gas = 287.058
	var g0 = 9.80665
	var gamma = 1.4

	var temp: float
	var press: float

	if h <= 11000.0:
		# Troposphere
		temp = t0 - lapse_rate * h
		var exp_factor = g0 / (r_gas * lapse_rate) # ~5.25588
		press = p0 * pow(temp / t0, exp_factor)
	else:
		# Stratosphere lower isothermal layer (11 km to 20 km)
		var temp_11 = t0 - lapse_rate * 11000.0 # 216.65 K
		var exp_factor_11 = g0 / (r_gas * lapse_rate)
		var press_11 = p0 * pow(temp_11 / t0, exp_factor_11) # ~22632 Pa

		temp = temp_11
		press = press_11 * exp(-g0 * (h - 11000.0) / (r_gas * temp_11))

	var density = press / (r_gas * temp)
	var speed_of_sound = sqrt(gamma * r_gas * temp)

	return {
		"temperature": temp,
		"pressure": press,
		"density": density,
		"speed_of_sound": speed_of_sound
	}

func _update_altitude_agl() -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3(0, -5000, 0),
		1 # World layer
	)
	query.exclude = [get_rid()]
	var res = space_state.intersect_ray(query)
	if res:
		altitude_agl = global_position.distance_to(res.position)
	else:
		altitude_agl = max(0.0, global_position.y)

func _update_engine_and_propeller(delta: float, air_density: float) -> void:
	# 1. RPM Spool-Up with rotational inertia
	var target_rpm = idle_rpm + throttle_input * (max_rpm - idle_rpm)
	current_rpm = lerp(current_rpm, target_rpm, 2.5 * delta)

	# 2. Engine Power (density-scaled power output)
	var density_ratio = air_density / 1.225
	var rpm_ratio = max(0.0, (current_rpm - 600.0) / (max_rpm - 600.0))
	current_power_watts = max_engine_power_watts * pow(density_ratio, 1.15) * rpm_ratio

	# 3. Propeller Thrust: T = eta * P / max(V_TAS, 12.0)
	var forward_axis_world = -global_transform.basis.z # Aircraft nose (-Z)
	var v_forward = linear_velocity.dot(forward_axis_world)
	airspeed_tas = max(0.0, v_forward)

	var effective_vel = max(airspeed_tas, 12.0)
	# Calibrated scale for trainer category (static thrust ~ 3200 N)
	var thrust_mag = (prop_efficiency_eta * current_power_watts * 0.28) / effective_vel
	current_thrust_n = thrust_mag

	var thrust_vector = forward_axis_world * current_thrust_n
	apply_force(thrust_vector, Vector3.ZERO)

	# 4. Propeller Slipstream Velocity (Momentum Theory)
	var prop_area = PI * pow(prop_diameter_m * 0.5, 2)
	var wash_term = (airspeed_tas * airspeed_tas) + (2.0 * current_thrust_n / max(0.2, air_density * prop_area))
	var delta_v_prop = sqrt(max(0.0, wash_term)) - airspeed_tas
	delta_v_prop = clamp(delta_v_prop, 0.0, 35.0)

	prop_slipstream_vel = forward_axis_world * delta_v_prop

	# Propeller visual rotation
	prop_rotation_angle += current_rpm * (2.0 * PI / 60.0) * delta
	if prop_rotation_angle > 2.0 * PI:
		prop_rotation_angle -= 2.0 * PI

func _update_aerodynamics(delta: float, air_density: float) -> void:
	var com_world = global_position + (global_transform.basis * center_of_mass)
	max_inboard_aoa_deg = 0.0

	var flap_deflection_norm = flaps_angles[flaps_index] / 35.0

	for s in _aero_surfaces:
		# Assign control inputs based on axis role
		if s.is_control_surface:
			match s.control_axis:
				"pitch":
					# Pitch up deflects elevator trailing edge up
					s.set_control_input(-pitch_input + pitch_trim)
				"roll":
					# Roll right: starboard aileron up, port aileron down
					var is_right_wing = s.position.x > 0.0
					var roll_sign = 1.0 if is_right_wing else -1.0
					s.set_control_input(roll_input * roll_sign)
				"yaw":
					s.set_control_input(rudder_input)
				"flaps":
					s.set_control_input(-flap_deflection_norm)

		# Evaluate forces
		var res = s.evaluate_and_apply_forces(
			self,
			com_world,
			air_density,
			prop_slipstream_vel,
			altitude_agl
		)

		# Track maximum inboard AoA for stall warning horn
		if "inboard" in s.name.to_lower() or "wing" in s.name.to_lower():
			var aoa_deg = rad_to_deg(abs(res.get("aoa", 0.0)))
			if aoa_deg > max_inboard_aoa_deg:
				max_inboard_aoa_deg = aoa_deg

func _update_landing_gear(delta: float) -> void:
	var com_world = global_position + (global_transform.basis * center_of_mass)
	var any_contact = false

	var ground_speed = linear_velocity.length()

	for w in _wheels:
		if w.is_steerable:
			w.set_steering_input(rudder_input, ground_speed)

		var res = w.evaluate_and_apply_forces(
			self,
			com_world,
			delta,
			brake_input,
			parking_brake_engaged
		)
		if res.get("in_contact", false):
			any_contact = true

	weight_on_wheels = any_contact

func _update_telemetry(delta: float, air_density: float, speed_of_sound: float) -> void:
	# Indicated Airspeed (IAS) = TAS * sqrt(rho / rho_0)
	var rho_0 = 1.225
	airspeed_ias = airspeed_tas * sqrt(air_density / rho_0)
	airspeed_kias = airspeed_ias * 1.94384 # m/s to knots

	# Vertical Speed (feet per minute)
	var vs_mps = linear_velocity.y
	vertical_speed_fpm = vs_mps * 196.85 # m/s to FPM

	# Load Factor G-Force: G = 1.0 + (a_normal / 9.80665)
	var accel = (linear_velocity - _previous_linear_vel) / max(delta, 0.001)
	_previous_linear_vel = linear_velocity
	var normal_axis = global_transform.basis.y
	var a_normal = accel.dot(normal_axis)
	current_g_force = 1.0 + (a_normal / GRAVITY_CONST)

	# Stall Warning Horn: Threshold >= 13.5 deg AND weight-on-wheels is false (in-flight)
	var should_stall = (max_inboard_aoa_deg >= stall_warning_aoa_deg) and (not weight_on_wheels)
	if should_stall != stall_horn_active:
		stall_horn_active = should_stall
		stall_warning_changed.emit(stall_horn_active)
		if stall_audio:
			if stall_horn_active and not stall_audio.playing:
				stall_audio.play()
			elif not stall_horn_active and stall_audio.playing:
				stall_audio.stop()

	# Emit telemetry packet
	var telemetry = {
		"airspeed_kias": airspeed_kias,
		"airspeed_tas": airspeed_tas,
		"altitude_msl": altitude_msl,
		"altitude_agl": altitude_agl,
		"vertical_speed_fpm": vertical_speed_fpm,
		"g_force": current_g_force,
		"rpm": current_rpm,
		"thrust_n": current_thrust_n,
		"aoa_deg": max_inboard_aoa_deg,
		"flaps_index": flaps_index,
		"flaps_deg": flaps_angles[flaps_index],
		"gear_down": gear_extended,
		"brakes_on": (brake_input > 0.0 or parking_brake_engaged),
		"stall_warning": stall_horn_active,
		"weight_on_wheels": weight_on_wheels
	}
	flight_telemetry_updated.emit(telemetry)

	if hud_node and hud_node.has_method("update_telemetry"):
		hud_node.update_telemetry(telemetry)

func _update_visuals_and_audio(delta: float) -> void:
	# Update Propeller Blur Mesh Material
	if prop_blur_mesh and prop_blur_mesh.material_override:
		var mat = prop_blur_mesh.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("rpm", current_rpm)
			mat.set_shader_parameter("rotation_angle", prop_rotation_angle)

	# Update Wingtip Vortices (Trigger above 2.5 G or high AoA at speed)
	var vortex_active = (current_g_force > 2.5 or max_inboard_aoa_deg > 12.0) and (airspeed_tas > 25.0)
	if left_vortex:
		left_vortex.emitting = vortex_active
	if right_vortex:
		right_vortex.emitting = vortex_active

	# Update Audio Rig
	if engine_audio:
		var rpm_pct = (current_rpm - idle_rpm) / (max_rpm - idle_rpm)
		engine_audio.pitch_scale = lerp(0.75, 1.35, rpm_pct)
		engine_audio.volume_db = lerp(-12.0, 0.0, throttle_input)
		if not engine_audio.playing:
			engine_audio.play()

	if wind_audio:
		var wind_volume = clamp((airspeed_tas - 15.0) / 45.0, 0.0, 1.0)
		wind_audio.volume_db = lerp(-30.0, -3.0, wind_volume)
		if not wind_audio.playing and wind_volume > 0.05:
			wind_audio.play()
