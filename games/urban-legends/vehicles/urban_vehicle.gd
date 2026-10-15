class_name UrbanVehicle
extends CharacterBody3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicleCatalog = preload("res://games/urban-legends/vehicles/urban_vehicle_catalog.gd")

## High-performance third-person vehicle physics controller for Urban Legends.
## Implements 4-wheel raycast suspension, Ackermann speed-sensitive steering,
## weight transfer (pitch/roll squat/dive), tire friction, drift mechanics,
## airborne stunt rotation authority, impact compression, damage, and auto-flip recovery.

signal speed_changed(speed_kmh: float, gear: int, rpm: float)
signal stunt_airborne_started()
signal stunt_landed(landing_rating: String, vertical_impact_speed: float, air_time_sec: float)
signal vehicle_damaged(current_health: float, damage: float)
signal vehicle_wrecked()
signal vehicle_reset_complete(spawn_pos: Vector3)

# Archetype identity
@export var vehicle_id: String = UrbanConstants.VEHICLE_VORTEX_GT
@export var is_player: bool = true
@export var paint_color: Color = Color(0.08, 0.45, 0.95)

# Physics attributes populated from catalog + upgrades
var top_speed: float = 68.0
var acceleration_rate: float = 32.0
var brake_force: float = 46.0
var steer_speed: float = 4.5
var max_steer_angle_rad: float = deg_to_rad(33.0)
var min_steer_angle_rad: float = deg_to_rad(12.0)
var vehicle_mass: float = 1250.0
var drift_factor: float = 1.25
var suspension_stiffness: float = 22.0
var suspension_damping: float = 4.2
var rest_suspension_length: float = 0.65
var max_suspension_travel: float = 0.28
var nitro_force: float = 28.0
var nitro_duration: float = 4.0

# Upgrades multiplier cache
var engine_mult: float = 1.0
var tires_mult: float = 1.0
var nitro_mult: float = 1.0
var suspension_mult: float = 1.0
var armor_mult: float = 1.0

# Driver inputs
var throttle_input: float = 0.0
var brake_input: float = 0.0
var steer_input: float = 0.0
var handbrake_input: bool = false
var nitro_input: bool = false
var air_pitch_input: float = 0.0
var air_roll_input: float = 0.0

# Dynamic state
var forward_speed: float = 0.0
var current_steer_angle: float = 0.0
var current_gear: int = 1
var engine_rpm: float = 1000.0
var nitro_gauge: float = 1.0
var is_nitro_active: bool = false
var health: float = 100.0
var is_wrecked: bool = false

# Drift state
var is_drifting: bool = false
var drift_angle_deg: float = 0.0
var drift_direction: float = 0.0
var current_lateral_velocity: float = 0.0

# Ground contact & suspension
var force_grounded_for_testing: bool = false
var wheel_raycasts: Array[RayCast3D] = []
var wheel_compressions: Array[float] = [0.0, 0.0, 0.0, 0.0]
var wheel_grounded: Array[bool] = [false, false, false, false]
var grounded_wheel_count: int = 0
var surface_normal: Vector3 = Vector3.UP
var current_surface_type: int = UrbanConstants.SURFACE_ASPHALT

# Airborne metrics
var is_airborne: bool = false
var air_timer: float = 0.0
var air_takeoff_pos: Vector3 = Vector3.ZERO
var total_air_yaw_deg: float = 0.0
var total_air_pitch_deg: float = 0.0
var total_air_roll_deg: float = 0.0
var previous_euler: Vector3 = Vector3.ZERO

# Weight transfer visual offsets
var chassis_node: Node3D = null
var visual_wheels: Array[Node3D] = []
var body_pitch: float = 0.0
var body_roll: float = 0.0
var wheel_roll_rot: float = 0.0

# Recovery & Safe Transform
var last_safe_ground_pos: Vector3 = Vector3(0, 1.0, 0)
var last_safe_ground_basis: Basis = Basis.IDENTITY
var upside_down_timer: float = 0.0
var controls_enabled: bool = true

func _ready() -> void:
	collision_layer = UrbanConstants.LAYER_PLAYER if is_player else UrbanConstants.LAYER_ENEMIES
	collision_mask = UrbanConstants.LAYER_WORLD | UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES

	add_to_group("urban_vehicles")
	if is_player:
		add_to_group("players")
	else:
		add_to_group("ai_traffic")

	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(75.0)
	floor_constant_speed = true
	up_direction = Vector3.UP

	_apply_catalog_specs()
	_setup_suspension_raycasts()
	_setup_collision_box()

func _apply_catalog_specs() -> void:
	var def = UrbanVehicleCatalog.get_vehicle_def(vehicle_id)
	top_speed = def.get("top_speed", 68.0) * engine_mult
	acceleration_rate = def.get("acceleration", 32.0) * engine_mult
	brake_force = def.get("brake_force", 46.0) * tires_mult
	steer_speed = def.get("steer_speed", 4.5) * tires_mult
	max_steer_angle_rad = deg_to_rad(def.get("max_steer_angle_deg", 33.0))
	min_steer_angle_rad = deg_to_rad(def.get("min_steer_angle_deg", 12.0))
	vehicle_mass = def.get("mass", 1250.0)
	drift_factor = def.get("drift_factor", 1.25)
	suspension_stiffness = def.get("suspension_stiffness", 22.0) * suspension_mult
	suspension_damping = def.get("suspension_damping", 4.2)
	rest_suspension_length = def.get("rest_length", 0.65)
	max_suspension_travel = def.get("max_travel", 0.28)
	nitro_force = def.get("nitro_force", 28.0) * nitro_mult
	nitro_duration = def.get("nitro_duration", 4.0)

func apply_upgrades(upgrades: Dictionary) -> void:
	var eng_lvl = upgrades.get("engine", 1)
	var tire_lvl = upgrades.get("tires", 1)
	var nit_lvl = upgrades.get("nitro", 1)
	var sus_lvl = upgrades.get("suspension", 1)
	var arm_lvl = upgrades.get("armor", 1)

	engine_mult = 1.0 + (eng_lvl - 1) * 0.08
	tires_mult = 1.0 + (tire_lvl - 1) * 0.07
	nitro_mult = 1.0 + (nit_lvl - 1) * 0.12
	suspension_mult = 1.0 + (sus_lvl - 1) * 0.08
	armor_mult = 1.0 + (arm_lvl - 1) * 0.15

	_apply_catalog_specs()

func _setup_suspension_raycasts() -> void:
	for r in wheel_raycasts:
		if is_instance_valid(r):
			r.queue_free()
	wheel_raycasts.clear()

	# 4 Raycasts relative to vehicle center: FL, FR, RL, RR
	var offsets = [
		Vector3(-0.85, 0.35, -1.35), # FL
		Vector3(0.85, 0.35, -1.35),  # FR
		Vector3(-0.88, 0.35, 1.35),  # RL
		Vector3(0.88, 0.35, 1.35)   # RR
	]

	for i in range(4):
		var ray = RayCast3D.new()
		ray.name = "SuspensionRay_%d" % i
		ray.position = offsets[i]
		ray.target_position = Vector3(0, -(rest_suspension_length + max_suspension_travel), 0)
		ray.collision_mask = UrbanConstants.LAYER_WORLD
		ray.enabled = true
		add_child(ray)
		wheel_raycasts.append(ray)

func _setup_collision_box() -> void:
	var col = get_node_or_null("VehicleCollision")
	if not col:
		col = CollisionShape3D.new()
		col.name = "VehicleCollision"
		var box = BoxShape3D.new()
		box.size = Vector3(1.95, 1.05, 4.4)
		col.shape = box
		col.position = Vector3(0, 0.65, 0)
		add_child(col)

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		move_and_slide()
		return

	_update_suspension_and_grounding(delta)
	_process_steering(delta)

	if grounded_wheel_count >= 2:
		_process_ground_physics(delta)
	else:
		_process_air_physics(delta)

	_update_weight_transfer(delta)
	_update_transmission(delta)
	_check_recovery_conditions(delta)

	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * delta

	# Post-movement collision evaluation
	_handle_collision_impacts()

func _update_physics_movement(delta: float) -> void:
	_physics_process(delta)

func set_forward_speed(spd: float) -> void:
	forward_speed = spd
	var fwd = -(global_basis if is_inside_tree() else transform.basis).z
	velocity = fwd * spd

func set_inputs(steer: float, throttle: float, brake: float, handbrake: bool, nitro: bool) -> void:
	steer_input = clampf(steer, -1.0, 1.0)
	throttle_input = clampf(throttle, 0.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)
	handbrake_input = handbrake
	nitro_input = nitro

func _update_suspension_and_grounding(_delta: float) -> void:
	if force_grounded_for_testing:
		grounded_wheel_count = 4
		surface_normal = Vector3.UP
		wheel_grounded = [true, true, true, true]
		wheel_compressions = [0.08, 0.08, 0.08, 0.08]
		return

	grounded_wheel_count = 0
	var normal_accum = Vector3.ZERO

	for i in range(4):
		var ray = wheel_raycasts[i]
		if ray.is_colliding():
			var ray_pos = ray.global_position if ray.is_inside_tree() else ray.position
			var hit_dist = ray_pos.distance_to(ray.get_collision_point())
			var compression = clampf(rest_suspension_length - hit_dist, 0.0, max_suspension_travel)
			wheel_compressions[i] = compression
			wheel_grounded[i] = true
			grounded_wheel_count += 1
			normal_accum += ray.get_collision_normal()
		else:
			wheel_compressions[i] = 0.0
			wheel_grounded[i] = false

	if grounded_wheel_count > 0:
		surface_normal = (normal_accum / float(grounded_wheel_count)).normalized()
		if grounded_wheel_count >= 3:
			last_safe_ground_pos = global_position if is_inside_tree() else position
			last_safe_ground_basis = global_basis if is_inside_tree() else transform.basis
	else:
		surface_normal = Vector3.UP

func _process_steering(delta: float) -> void:
	# Ackermann speed-sensitive steering curve:
	# At zero speed: max steering angle (~33 degrees)
	# At top speed: tight steering angle (~12 degrees)
	var speed_ratio = clampf(absf(forward_speed) / top_speed, 0.0, 1.0)
	var target_max_angle = lerpf(max_steer_angle_rad, min_steer_angle_rad, speed_ratio * speed_ratio)
	var target_steer = steer_input * target_max_angle

	current_steer_angle = move_toward(current_steer_angle, target_steer, steer_speed * delta * (1.2 if absf(steer_input) < 0.1 else 1.0))

func _process_ground_physics(delta: float) -> void:
	# When transitioning from airborne to grounded
	if is_airborne:
		_on_touchdown()

	# Longitudinal drive / acceleration & brake
	var b = global_basis if is_inside_tree() else transform.basis
	var local_vel = b.inverse() * velocity
	forward_speed = -local_vel.z # Negative Z is vehicle forward in Godot convention

	# Low-speed launch boost multiplier (prevents sluggish starts)
	var launch_mult = 1.0
	if absf(forward_speed) < 14.0 and throttle_input > 0.1:
		launch_mult = lerpf(1.45, 1.0, absf(forward_speed) / 14.0)

	# Nitro boost handling
	is_nitro_active = false
	var effective_nitro = 0.0
	if nitro_input and nitro_gauge > 0.05 and throttle_input > 0.2:
		is_nitro_active = true
		effective_nitro = nitro_force
		nitro_gauge = maxf(0.0, nitro_gauge - (delta / nitro_duration))
	elif not nitro_input and nitro_gauge < 1.0:
		# Slow passive nitro recharge while driving
		nitro_gauge = minf(1.0, nitro_gauge + (delta * 0.08))

	# Throttle application
	var drive_accel = 0.0
	if throttle_input > 0.01:
		if forward_speed < top_speed:
			var speed_factor = clampf(1.0 - (forward_speed / top_speed), 0.1, 1.0)
			drive_accel = (acceleration_rate * launch_mult * speed_factor + effective_nitro) * throttle_input
	elif brake_input > 0.01:
		# Braking or reversing
		if forward_speed > 0.8:
			drive_accel = -brake_force * brake_input
		else:
			# Reverse gear
			drive_accel = -acceleration_rate * 0.55 * brake_input

	# Friction and coasting drag
	var rolling_resistance = 4.5
	var air_drag = 0.008 * (forward_speed * forward_speed)
	if throttle_input <= 0.01 and brake_input <= 0.01:
		drive_accel -= signf(forward_speed) * (rolling_resistance + air_drag)

	# Lateral Grip & Drift Slip Physics
	is_drifting = false
	var lateral_speed = local_vel.x
	current_lateral_velocity = lateral_speed

	var grip = 18.0 * tires_mult
	if handbrake_input:
		is_drifting = true
		grip = 4.2 / drift_factor # Low lateral friction lets the rear step out
		if absf(steer_input) > 0.1:
			drift_direction = signf(steer_input)
	elif absf(lateral_speed) > 5.5 and absf(steer_input) > 0.4:
		# Power slide / drift break through aggressive steering
		is_drifting = true
		grip = 8.5 / drift_factor

	# Calculate drift angle
	if absf(forward_speed) > 3.0:
		var raw_angle = rad_to_deg(atan2(absf(lateral_speed), absf(forward_speed)))
		drift_angle_deg = clampf(raw_angle, 0.0, 85.0)
	else:
		drift_angle_deg = 0.0

	# Apply lateral grip dampening
	local_vel.x = move_toward(local_vel.x, 0.0, grip * delta * 10.0)

	# Yaw rotation according to steering (vehicle-local coordinates)
	# By Godot right-hand convention (+Y UP, -Z Forward), rotating clockwise (turning right towards +X)
	# corresponds to a negative rotation angle around Vector3.UP.
	var yaw_rate = 0.0
	if absf(forward_speed) > 0.1:
		var speed_scale = clampf(forward_speed / 12.0, -1.0, 1.0)
		var drift_yaw_boost = 1.35 if is_drifting else 1.0
		yaw_rate = current_steer_angle * speed_scale * 3.2 * drift_yaw_boost

	# Rotate vehicle basis around its local UP axis (negated for correct clockwise right turn)
	rotate_object_local(Vector3.UP, -yaw_rate * delta)

	# Forward velocity update
	local_vel.z -= drive_accel * delta

	# Suspension vertical stabilization to road
	var target_vert_vel = 0.0
	if absf(local_vel.y) > 0.05:
		target_vert_vel = move_toward(local_vel.y, 0.0, suspension_stiffness * delta * 4.0)
	local_vel.y = target_vert_vel

	# Re-transform local velocity back to global
	var b_out = global_basis if is_inside_tree() else transform.basis
	velocity = b_out * local_vel

	# Snap gently to ground surface normal on steep hills (Las Colinas style)
	if surface_normal.dot(Vector3.UP) > 0.45:
		var current_up = b_out.y
		var align_quat = Quaternion(current_up, surface_normal)
		if is_inside_tree():
			global_basis = Basis(align_quat.slerp(Quaternion.IDENTITY, 1.0 - (delta * 8.0))) * global_basis
		else:
			transform.basis = Basis(align_quat.slerp(Quaternion.IDENTITY, 1.0 - (delta * 8.0))) * transform.basis

func _process_air_physics(delta: float) -> void:
	if not is_airborne:
		_on_takeoff()

	air_timer += delta

	# Standard gravity
	velocity.y -= UrbanConstants.DEFAULT_GRAVITY * delta

	# Mid-air stunt trick authority (Pitch, Yaw, Roll)
	var air_pitch = air_pitch_input * 3.2 * delta
	var air_yaw = -steer_input * 2.8 * delta
	var air_roll = air_roll_input * 3.5 * delta

	if absf(air_pitch) > 0.001:
		rotate_object_local(Vector3.RIGHT, air_pitch)
		total_air_pitch_deg += rad_to_deg(absf(air_pitch))
	if absf(air_yaw) > 0.001:
		rotate_object_local(Vector3.UP, air_yaw)
		total_air_yaw_deg += rad_to_deg(absf(air_yaw))
	if absf(air_roll) > 0.001:
		rotate_object_local(Vector3.FORWARD, air_roll)
		total_air_roll_deg += rad_to_deg(absf(air_roll))

	# Calculate forward speed in air
	var b_air = global_basis if is_inside_tree() else transform.basis
	var local_vel = b_air.inverse() * velocity
	forward_speed = -local_vel.z

func _on_takeoff() -> void:
	is_airborne = true
	air_timer = 0.0
	air_takeoff_pos = global_position if is_inside_tree() else position
	total_air_yaw_deg = 0.0
	total_air_pitch_deg = 0.0
	total_air_roll_deg = 0.0
	previous_euler = global_rotation if is_inside_tree() else rotation
	stunt_airborne_started.emit()

func _on_touchdown() -> void:
	is_airborne = false
	var vert_speed = absf(velocity.y)
	var up_dot = (global_basis if is_inside_tree() else transform.basis).y.dot(Vector3.UP)

	var landing_rating = "Smooth"
	if vert_speed > 14.0 or up_dot < 0.6:
		landing_rating = "Hard"
		take_damage(vert_speed * 1.5)
	elif vert_speed > 7.0:
		landing_rating = "Good"

	stunt_landed.emit(landing_rating, vert_speed, air_timer)

func _update_weight_transfer(delta: float) -> void:
	# Pitch squat on acceleration, dive on braking
	var target_pitch = 0.0
	if throttle_input > 0.1:
		target_pitch = deg_to_rad(2.2) # Squat
	elif brake_input > 0.1:
		target_pitch = -deg_to_rad(3.5) # Dive

	body_pitch = move_toward(body_pitch, target_pitch, 8.0 * delta)

	# Roll into cornering
	var target_roll = 0.0
	if absf(forward_speed) > 2.0:
		target_roll = -steer_input * deg_to_rad(3.8)

	body_roll = move_toward(body_roll, target_roll, 9.0 * delta)

	if chassis_node:
		chassis_node.rotation.x = body_pitch
		chassis_node.rotation.z = body_roll

	# Visual wheel rolling & steering
	var roll_delta = -(forward_speed * delta) / UrbanConstants.TIRE_RADIUS
	wheel_roll_rot += roll_delta

	for i in range(visual_wheels.size()):
		var w = visual_wheels[i]
		if is_instance_valid(w):
			# Suspension vertical displacement
			var comp = wheel_compressions[i] if i < wheel_compressions.size() else 0.0
			w.position.y = 0.35 + comp * 0.8
			# Front wheels steer (index 0 and 1, negated to turn right towards +X)
			if i == 0 or i == 1:
				w.rotation.y = -current_steer_angle
			# Wheel spin
			w.rotation.x = wheel_roll_rot

func _update_transmission(_delta: float) -> void:
	var abs_speed = absf(forward_speed)
	# 6-speed automatic gearbox ratios
	if abs_speed < 8.0:
		current_gear = 1
		engine_rpm = lerpf(1000.0, 6500.0, abs_speed / 8.0)
	elif abs_speed < 18.0:
		current_gear = 2
		engine_rpm = lerpf(3000.0, 7000.0, (abs_speed - 8.0) / 10.0)
	elif abs_speed < 30.0:
		current_gear = 3
		engine_rpm = lerpf(3200.0, 7200.0, (abs_speed - 18.0) / 12.0)
	elif abs_speed < 44.0:
		current_gear = 4
		engine_rpm = lerpf(3500.0, 7400.0, (abs_speed - 30.0) / 14.0)
	elif abs_speed < 58.0:
		current_gear = 5
		engine_rpm = lerpf(3800.0, 7600.0, (abs_speed - 44.0) / 14.0)
	else:
		current_gear = 6
		engine_rpm = lerpf(4000.0, 8000.0, clampf((abs_speed - 58.0) / 15.0, 0.0, 1.0))

	var speed_kmh = abs_speed * 3.6
	var rpm_norm = clampf(engine_rpm / 8000.0, 0.1, 1.0)
	speed_changed.emit(speed_kmh, current_gear, rpm_norm)

var wreck_timer: float = 0.0

func _check_recovery_conditions(delta: float) -> void:
	# Automatic recovery when wrecked
	if is_wrecked:
		wreck_timer += delta
		if wreck_timer >= 2.5:
			repair(100.0)
			recover_vehicle()
			wreck_timer = 0.0
		return

	# Automatic flip recovery when upside down on the ground
	var curr_y = (global_position if is_inside_tree() else position).y
	var up_dot = (global_basis if is_inside_tree() else transform.basis).y.dot(Vector3.UP)
	if up_dot < 0.2 and grounded_wheel_count >= 1:
		upside_down_timer += delta
		if upside_down_timer > 2.0:
			recover_vehicle()
	else:
		upside_down_timer = 0.0

	# Fallen out of world
	if curr_y < -35.0:
		recover_vehicle()

func _handle_collision_impacts() -> void:
	if not is_inside_tree():
		return
	var slide_count = get_slide_collision_count()
	for i in range(slide_count):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider != self:
			var impact_vel = col.get_travel().length() / get_physics_process_delta_time()
			if impact_vel > 8.0:
				var damage_amount = (impact_vel - 8.0) * 1.8 / armor_mult
				take_damage(damage_amount)

func take_damage(amount: float) -> void:
	if is_wrecked:
		return
	health = maxf(0.0, health - amount)
	vehicle_damaged.emit(health, amount)
	if health <= 0.0:
		is_wrecked = true
		vehicle_wrecked.emit()

func repair(amount: float = 100.0) -> void:
	health = minf(100.0, health + amount)
	if health > 0.0:
		is_wrecked = false

func recover_vehicle() -> void:
	# Flip car right side up and place at last safe ground position
	velocity = Vector3.ZERO
	var target_pos = last_safe_ground_pos + Vector3(0, 0.75, 0)
	if is_inside_tree():
		global_position = target_pos
	else:
		position = target_pos

	# Align yaw to safe basis, clear roll/pitch
	var safe_yaw = last_safe_ground_basis.get_euler().y
	if is_inside_tree():
		global_rotation = Vector3(0, safe_yaw, 0)
	else:
		rotation = Vector3(0, safe_yaw, 0)
	upside_down_timer = 0.0
	is_airborne = false
	current_steer_angle = 0.0

	vehicle_reset_complete.emit(target_pos)

# --- Getters & QA Telemetry ---
func get_speed_kmh() -> float:
	return absf(forward_speed) * 3.6

func get_forward_speed_ms() -> float:
	return forward_speed

func get_health() -> float:
	return health

func is_on_ground() -> bool:
	return grounded_wheel_count >= 2

func get_grounded_wheel_count() -> int:
	return grounded_wheel_count

func get_drift_angle() -> float:
	return drift_angle_deg

func get_suspension_compressions() -> Array[float]:
	return wheel_compressions

func get_gear() -> int:
	return current_gear

func get_rpm() -> float:
	return engine_rpm

func get_nitro_gauge() -> float:
	return nitro_gauge
