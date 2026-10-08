class_name AeroVehicle
extends CharacterBody3D

## High-speed arcade stunt vehicle controller for AeroRush: Impossible Circuit.
## Supports 3D loop & wall-ride adhesion, airborne pitch/yaw/roll trick authority,
## drift mini-turbo charging, nitro boost, suspension dynamics, and safe checkpoint recovery.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroVehicleCatalog = preload("res://games/aero-rush/vehicles/aero_vehicle_catalog.gd")
const AeroVehicleVisuals = preload("res://games/aero-rush/vehicles/aero_vehicle_visuals.gd")
const AeroPhysicsHelpers = preload("res://games/aero-rush/vehicles/aero_physics_helpers.gd")

signal stunt_action_triggered(stunt_id: int, points: int, label: String)
signal landing_performed(quality: String, angle_deg: float, bonus: int)
signal vehicle_crashed()
signal vehicle_respawned(respawn_position: Vector3)
signal boost_amount_changed(current_boost: float, max_boost: float)

# Configuration & Identity
@export var vehicle_id: String = AeroConstants.VEHICLE_APEX
@export var is_player: bool = true
@export var paint_color: Color = Color.WHITE

# Dynamic Physics Specs (Populated from catalog)
var top_speed: float = 58.0
var acceleration_rate: float = 38.0
var steer_speed: float = 3.8
var brake_force: float = 42.0
var drift_factor: float = 4.2
var boost_force: float = 24.0
var vehicle_mass: float = 1100.0
var suspension_stiffness: float = 16.0
var air_pitch_speed: float = 3.8
var air_yaw_speed: float = 4.0
var air_roll_speed: float = 4.5

# Runtime State
var forward_speed: float = 0.0
var steer_input: float = 0.0
var throttle_input: float = 0.0
var brake_input: float = 0.0
var handbrake_held: bool = false
var boost_requested: bool = false

# Drift & Boost Systems
var is_drifting: bool = false
var drift_direction: float = 0.0
var drift_charge: float = 0.0
var boost_gauge: float = 1.0 # 0.0 to 1.0
var max_boost_gauge: float = 1.0
var is_boost_active: bool = false
var boost_burn_rate: float = 0.28 # seconds to empty ~3.5s

# Airborne Stunt Metrics
var is_grounded: bool = true
var ground_normal: Vector3 = Vector3.UP
var airtime_duration: float = 0.0
var air_jump_origin: Vector3 = Vector3.ZERO
var total_air_yaw: float = 0.0
var total_air_pitch: float = 0.0
var total_air_roll: float = 0.0
var previous_air_euler: Vector3 = Vector3.ZERO

# Wall Ride & Loop Adhesion
var is_wall_riding: bool = false
var wall_ride_timer: float = 0.0
var in_loop_section: bool = false

# Checkpoint & Recovery State
var last_safe_checkpoint_pos: Vector3 = Vector3(0, 1.0, 0)
var last_safe_checkpoint_basis: Basis = Basis.IDENTITY
var rollover_timer: float = 0.0
var stuck_timer: float = 0.0
var controls_enabled: bool = true

# Visual & Node References
var visual_data: Dictionary = {}
var chassis_node: Node3D = null
var wheels: Array[Node3D] = []
var wheel_raycasts: Array[RayCast3D] = []
var wheel_roll_rot: float = 0.0
var suspension_offsets: Array[float] = [0.0, 0.0, 0.0, 0.0]
var base_wheel_y: Array[float] = [0.32, 0.32, 0.34, 0.34]
var landing_compression: float = 0.0

func _ready() -> void:
	collision_layer = AeroConstants.LAYER_PLAYER if is_player else AeroConstants.LAYER_ENEMIES
	collision_mask = AeroConstants.LAYER_WORLD | AeroConstants.LAYER_PLAYER | AeroConstants.LAYER_ENEMIES

	add_to_group("aero_vehicles")
	if is_player:
		add_to_group("players")
	else:
		add_to_group("ai_vehicles")

	floor_snap_length = 0.50
	floor_max_angle = deg_to_rad(85.0) # Allows driving steep banks without sliding
	floor_constant_speed = true
	up_direction = Vector3.UP

	_apply_catalog_specs()
	_setup_collision_shape()
	_setup_suspension_raycasts()
	_setup_visuals()

	if is_inside_tree():
		last_safe_checkpoint_pos = global_position
		last_safe_checkpoint_basis = global_basis
	else:
		last_safe_checkpoint_pos = position
		last_safe_checkpoint_basis = basis

func _apply_catalog_specs() -> void:
	var def = AeroVehicleCatalog.get_vehicle_definition(vehicle_id)
	top_speed = def.get("top_speed", 58.0)
	acceleration_rate = def.get("acceleration", 38.0)
	steer_speed = def.get("steer_speed", 3.8)
	brake_force = def.get("brake_force", 42.0)
	drift_factor = def.get("drift_factor", 4.2)
	boost_force = def.get("boost_force", 24.0)
	vehicle_mass = def.get("mass", 1100.0)
	suspension_stiffness = def.get("suspension_stiffness", 16.0)
	air_pitch_speed = def.get("air_control_pitch", 3.8)
	air_yaw_speed = def.get("air_control_yaw", 4.0)
	air_roll_speed = def.get("air_control_roll", 4.5)

func _setup_collision_shape() -> void:
	# Capsule shaped chassis collision hull with rounded corners eliminates track seam catching.
	# Positioned with bottom at Y=+0.12m so hull never drags or snags into track road geometry beneath wheels.
	var col = CollisionShape3D.new()
	col.name = "VehicleCollisionHull"
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 3.2
	col.shape = capsule
	# Orient horizontally along forward axis
	col.rotation_degrees.x = 90.0
	col.position = Vector3(0, 0.60, 0)
	add_child(col)

func _setup_suspension_raycasts() -> void:
	var offsets = [
		Vector3(-0.48, 0.45, -0.75), # Front Left
		Vector3(0.48, 0.45, -0.75),  # Front Right
		Vector3(-0.50, 0.45, 1.15),  # Rear Left
		Vector3(0.50, 0.45, 1.15)    # Rear Right
	]
	for i in range(4):
		var ray = RayCast3D.new()
		ray.name = "WheelRay_%d" % i
		ray.position = offsets[i]
		ray.target_position = Vector3(0, -1.85, 0)
		ray.collision_mask = AeroConstants.LAYER_WORLD
		add_child(ray)
		wheel_raycasts.append(ray)

func _setup_visuals() -> void:
	visual_data = AeroVehicleVisuals.build_vehicle_visuals(vehicle_id, paint_color)
	var root = visual_data.get("root") as Node3D
	if root:
		add_child(root)
		chassis_node = visual_data.get("chassis") as Node3D
		wheels = visual_data.get("wheels", [])

func get_speed_kmh() -> float:
	return absf(forward_speed) * 3.6

func get_speed_mps() -> float:
	return absf(forward_speed)

var programmatic_override: bool = false

func set_inputs(steer: float, throttle: float, brake: float, handbrake: bool, boost: bool) -> void:
	steer_input = clampf(steer, -1.0, 1.0)
	throttle_input = clampf(throttle, 0.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)
	handbrake_held = handbrake
	boost_requested = boost
	programmatic_override = true

func _physics_process(delta: float) -> void:
	if is_player and not programmatic_override:
		_process_player_inputs()

	_update_grounding_and_suspension(delta)
	_process_movement(delta)
	_update_visual_dynamics(delta)
	_check_rollover_and_recovery(delta)

func _process_player_inputs() -> void:
	if not controls_enabled:
		steer_input = 0.0
		throttle_input = 0.0
		brake_input = 0.0
		handbrake_held = false
		boost_requested = false
		return

	# Manual reset hotkey
	if Input.is_key_pressed(KEY_R):
		recover_to_checkpoint()
		return

	var steer: float = 0.0
	var throttle: float = 0.0
	var brake: float = 0.0
	var handbrake: bool = false
	var boost: bool = false

	# Steering (InputMap action with physical key fallbacks)
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") and not InputMap.action_get_events("move_left").is_empty():
		steer = Input.get_axis("move_left", "move_right")
	if absf(steer) <= 0.01:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steer -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steer += 1.0

	# Throttle / Forward (InputMap action with physical key fallbacks)
	if InputMap.has_action("move_forward") and not InputMap.action_get_events("move_forward").is_empty():
		throttle = Input.get_action_strength("move_forward")
	if throttle <= 0.01:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			throttle = 1.0

	# Brake / Reverse (InputMap action with physical key fallbacks)
	if InputMap.has_action("move_back") and not InputMap.action_get_events("move_back").is_empty():
		brake = Input.get_action_strength("move_back")
	if brake <= 0.01:
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			brake = 1.0

	# Drift / Handbrake (Shift or action)
	if InputMap.has_action("drift") and not InputMap.action_get_events("drift").is_empty():
		handbrake = Input.is_action_pressed("drift")
	if not handbrake:
		handbrake = Input.is_key_pressed(KEY_SHIFT)

	# Nitro Boost (Space or action)
	if InputMap.has_action("boost") and not InputMap.action_get_events("boost").is_empty():
		boost = Input.is_action_pressed("boost")
	if not boost:
		boost = Input.is_key_pressed(KEY_SPACE)

	# Virtual / Mobile Joystick Support
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and "virtual_move_vector" in im and im.virtual_move_vector != Vector2.ZERO:
		if absf(im.virtual_move_vector.x) > 0.05:
			steer = im.virtual_move_vector.x
		if im.virtual_move_vector.y < -0.05:
			throttle = maxf(throttle, -im.virtual_move_vector.y)
		elif im.virtual_move_vector.y > 0.05:
			brake = maxf(brake, im.virtual_move_vector.y)

	steer_input = clampf(steer, -1.0, 1.0)
	throttle_input = clampf(throttle, 0.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)
	handbrake_held = handbrake
	boost_requested = boost

func _update_grounding_and_suspension(delta: float) -> void:
	var contact_count: int = 0
	var avg_normal: Vector3 = Vector3.ZERO

	for i in range(wheel_raycasts.size()):
		var ray = wheel_raycasts[i]
		if ray.is_inside_tree():
			ray.force_raycast_update()
		if ray.is_colliding():
			contact_count += 1
			avg_normal += ray.get_collision_normal()
			var dist = ray.global_position.distance_to(ray.get_collision_point())
			# Compression travel
			var comp = clampf(1.0 - dist, 0.0, 0.40)
			suspension_offsets[i] = lerpf(suspension_offsets[i], comp, delta * suspension_stiffness)
		else:
			suspension_offsets[i] = lerpf(suspension_offsets[i], 0.0, delta * 6.0)

	var was_grounded = is_grounded
	is_grounded = contact_count >= 1 or is_on_floor() or (not is_inside_tree() and is_grounded)

	if is_grounded:
		if contact_count >= 1:
			ground_normal = (avg_normal / float(contact_count)).normalized()
		elif is_on_floor():
			ground_normal = get_floor_normal()
		else:
			ground_normal = Vector3.UP
		up_direction = ground_normal

		# Evaluate Touchdown on Transition from Air to Ground
		if not was_grounded:
			_handle_touchdown()
	else:
		# Airborne state tracking
		if was_grounded:
			# Just launched into air
			airtime_duration = 0.0
			air_jump_origin = global_position
			total_air_yaw = 0.0
			total_air_pitch = 0.0
			total_air_roll = 0.0
			previous_air_euler = global_rotation
		else:
			airtime_duration += delta
			_track_airborne_rotations()

func _handle_touchdown() -> void:
	var landing_eval = AeroPhysicsHelpers.evaluate_landing(global_basis.y, ground_normal)
	var quality = landing_eval.get("quality", "clean")
	var angle_deg = landing_eval.get("angle_deg", 0.0)
	var bonus = landing_eval.get("score_bonus", 0)
	var boost_refill = landing_eval.get("boost_refill", 0.0)
	var is_crash = landing_eval.get("is_crash", false)

	# Crash only when impact angle/velocity genuinely warrants it (>18 m/s speed and extreme angle >75 deg)
	var is_fatal_crash = is_crash and absf(forward_speed) > 18.0 and angle_deg > 75.0

	if is_fatal_crash:
		emit_signal("vehicle_crashed")
		recover_to_checkpoint()
		return
	elif is_crash:
		# Rough touchdown: absorb impact with chassis compression and sparks rather than insta-death
		quality = "rough"
		bonus = 30

	# Add boost refund on clean / perfect landing
	if boost_refill > 0.0:
		boost_gauge = clampf(boost_gauge + boost_refill, 0.0, max_boost_gauge)
		boost_amount_changed.emit(boost_gauge, max_boost_gauge)

	landing_performed.emit(quality, angle_deg, bonus)

	# Trigger stunt points if airtime was significant
	if airtime_duration >= 0.8 and absf(forward_speed) >= AeroConstants.MIN_STUNT_SPEED:
		var jump_dist = global_position.distance_to(air_jump_origin)
		if jump_dist >= 45.0:
			stunt_action_triggered.emit(AeroConstants.StuntType.LONG_JUMP, 600, "MEGA JUMP")
		elif jump_dist >= 25.0:
			stunt_action_triggered.emit(AeroConstants.StuntType.LONG_JUMP, 300, "LONG JUMP")
		else:
			stunt_action_triggered.emit(AeroConstants.StuntType.AIRTIME, int(airtime_duration * 120), "AIRTIME")

		if quality == "perfect":
			stunt_action_triggered.emit(AeroConstants.StuntType.PERFECT_LANDING, 500, "PERFECT LANDING")

	# Trigger Sparks and Dust on touchdown
	landing_compression = clampf(absf(velocity.y) * 0.04, 0.08, 0.35)
	var sparks = visual_data.get("sparks_emitter") as GPUParticles3D
	if sparks:
		sparks.restart()
		sparks.emitting = true
	var dust = visual_data.get("dust_burst") as GPUParticles3D
	if dust:
		dust.restart()
		dust.emitting = true

func _track_airborne_rotations() -> void:
	var cur_euler = global_rotation
	var delta_euler = cur_euler - previous_air_euler
	previous_air_euler = cur_euler

	# Wrap angles
	delta_euler.x = wrapf(delta_euler.x, -PI, PI)
	delta_euler.y = wrapf(delta_euler.y, -PI, PI)
	delta_euler.z = wrapf(delta_euler.z, -PI, PI)

	total_air_pitch += delta_euler.x
	total_air_yaw += delta_euler.y
	total_air_roll += delta_euler.z

	# Evaluate stunt rotation milestones
	if absf(total_air_yaw) >= deg_to_rad(330.0):
		stunt_action_triggered.emit(AeroConstants.StuntType.SPIN_360, 450, "360 FLAT SPIN")
		total_air_yaw = 0.0

	if absf(total_air_roll) >= deg_to_rad(330.0):
		stunt_action_triggered.emit(AeroConstants.StuntType.BARREL_ROLL, 550, "BARREL ROLL")
		total_air_roll = 0.0

	if total_air_pitch >= deg_to_rad(330.0):
		stunt_action_triggered.emit(AeroConstants.StuntType.BACKFLIP, 650, "BACKFLIP")
		total_air_pitch = 0.0
	elif total_air_pitch <= -deg_to_rad(330.0):
		stunt_action_triggered.emit(AeroConstants.StuntType.FRONTFLIP, 650, "FRONTFLIP")
		total_air_pitch = 0.0

func _process_movement(delta: float) -> void:
	if is_grounded:
		_process_ground_movement(delta)
	else:
		_process_airborne_movement(delta)

	# Apply Effective Gravity (with Loop & Wall Adhesion)
	var eff_grav = AeroPhysicsHelpers.calculate_effective_gravity(
		ground_normal,
		forward_speed,
		is_grounded,
		AeroConstants.DEFAULT_GRAVITY
	)
	velocity += eff_grav * delta

	if not velocity.is_finite():
		velocity = Vector3.ZERO

	# Execute Physics Move
	if is_inside_tree() and get_world_3d() and get_world_3d().space.is_valid():
		move_and_slide()
	else:
		position += velocity * delta

	# Synchronize forward speed with actual horizontal velocity on ground if wall collision
	if is_inside_tree() and is_on_wall():
		var forward_dir = -global_basis.z.normalized()
		var forward_proj = velocity.dot(forward_dir)
		if forward_proj < forward_speed:
			forward_speed = maxf(0.0, forward_proj)

func _process_ground_movement(delta: float) -> void:
	# 1. Nitro Boost
	is_boost_active = boost_requested and boost_gauge > 0.02
	var current_top = top_speed
	var current_accel = acceleration_rate

	if is_boost_active:
		boost_gauge = maxf(0.0, boost_gauge - boost_burn_rate * delta)
		current_top += boost_force
		current_accel *= 1.6
		boost_amount_changed.emit(boost_gauge, max_boost_gauge)

	# 2. Acceleration / Deceleration
	if throttle_input > 0.0:
		if forward_speed < 0.0:
			# Braking from reverse
			forward_speed = move_toward(forward_speed, 0.0, brake_force * delta)
		else:
			forward_speed = move_toward(forward_speed, current_top * throttle_input, current_accel * delta)
	elif brake_input > 0.0:
		if forward_speed > 0.5:
			# Braking
			forward_speed = move_toward(forward_speed, 0.0, brake_force * delta)
		else:
			# Reversing (capped at 16 m/s)
			forward_speed = move_toward(forward_speed, -16.0 * brake_input, acceleration_rate * 0.65 * delta)
	else:
		# Passive rolling friction
		forward_speed = move_toward(forward_speed, 0.0, 10.0 * delta)

	# 3. Steering & Drifting
	var steer_sens = steer_speed / (1.0 + (absf(forward_speed) / top_speed) * 0.75)

	if handbrake_held and absf(steer_input) > 0.15 and forward_speed > 12.0:
		# Drift Active
		if not is_drifting:
			is_drifting = true
			drift_direction = signf(steer_input)
			drift_charge = 0.0
		drift_charge += delta * 1.5
		# Faster yaw during drift
		rotate_object_local(Vector3.UP, -steer_input * steer_sens * drift_factor * delta)
		stunt_action_triggered.emit(AeroConstants.StuntType.DRIFT, int(delta * 80), "DRIFT")
	else:
		if is_drifting:
			# Release mini-turbo boost if drift was charged
			if drift_charge >= 1.2:
				boost_gauge = minf(max_boost_gauge, boost_gauge + 0.30)
				boost_amount_changed.emit(boost_gauge, max_boost_gauge)
			is_drifting = false
			drift_charge = 0.0
		# Standard grip steering
		if absf(forward_speed) > 0.5:
			var steer_dir = signf(forward_speed)
			rotate_object_local(Vector3.UP, -steer_input * steer_sens * steer_dir * delta)

	# 4. Surface Normal Alignment (Allows driving through loops and banked turns)
	if is_inside_tree():
		global_basis = AeroPhysicsHelpers.align_basis_to_normal(global_basis, ground_normal, delta * 14.0)
	else:
		transform.basis = AeroPhysicsHelpers.align_basis_to_normal(transform.basis, ground_normal, delta * 14.0)

	# 5. Wall Ride Detection
	var wall_angle = rad_to_deg(acos(clampf(ground_normal.dot(Vector3.UP), -1.0, 1.0)))
	if wall_angle >= AeroConstants.WALL_RIDE_MIN_PITCH_DEG and absf(forward_speed) >= AeroConstants.MIN_STUNT_SPEED:
		is_wall_riding = true
		wall_ride_timer += delta
		if wall_ride_timer >= 0.5:
			stunt_action_triggered.emit(AeroConstants.StuntType.WALL_RIDE, int(delta * 220), "WALL RIDE")
	else:
		is_wall_riding = false
		wall_ride_timer = 0.0

	# 6. Set Driving Velocity Along Tangent
	var forward_dir = -(global_basis.z if is_inside_tree() else transform.basis.z).normalized()
	velocity = forward_dir * forward_speed

func _process_airborne_movement(delta: float) -> void:
	var is_stunt_mode = handbrake_held or is_boost_active or (is_player and Input.is_key_pressed(KEY_SHIFT))

	# 1. Stunt Mode vs Normal Flight
	if is_stunt_mode:
		# Player deliberate stunt maneuvers:
		# Controlled flips (Pitch)
		if throttle_input > 0.0:
			rotate_object_local(Vector3.RIGHT, air_pitch_speed * throttle_input * delta)
		elif brake_input > 0.0:
			rotate_object_local(Vector3.RIGHT, -air_pitch_speed * brake_input * delta)

		# Controlled rolls / flat spins
		if absf(steer_input) > 0.1:
			if handbrake_held:
				# Aerial Barrel Roll
				rotate_object_local(Vector3.FORWARD, air_roll_speed * steer_input * delta)
			else:
				# Aerial Flat Spin
				rotate_object_local(Vector3.UP, -air_yaw_speed * steer_input * delta)
	else:
		# Normal Jump Mode:
		# Bounded gentle pitch (aiming nose up/down for landing angle)
		if throttle_input > 0.0:
			rotate_object_local(Vector3.RIGHT, (air_pitch_speed * 0.45) * throttle_input * delta)
		elif brake_input > 0.0:
			rotate_object_local(Vector3.RIGHT, -(air_pitch_speed * 0.45) * brake_input * delta)

		# Bounded gentle yaw / roll banking
		if absf(steer_input) > 0.1:
			rotate_object_local(Vector3.UP, -air_yaw_speed * 0.4 * steer_input * delta)
			rotate_object_local(Vector3.FORWARD, air_roll_speed * 0.25 * steer_input * delta)

		# Natural Horizon & Trajectory Flight Stabilization: Vehicle naturally tends toward wheels-down landing!
		var cur_basis = global_basis if is_inside_tree() else transform.basis
		var horizon_weight = clampf(delta * 5.5, 0.0, 1.0)
		var stabilized_basis = AeroPhysicsHelpers.calculate_flight_stabilization(cur_basis, velocity, horizon_weight)
		if is_inside_tree():
			global_basis = stabilized_basis
		else:
			transform.basis = stabilized_basis

	# 2. Multi-Point Landing Alignment Assistance & Prediction
	if is_inside_tree() and get_world_3d() and get_world_3d().direct_space_state:
		var space_state = get_world_3d().direct_space_state
		var prediction = AeroPhysicsHelpers.predict_landing(space_state, global_position, velocity, 28.0)
		if prediction.get("found", false):
			var hit_norm = prediction.get("normal", Vector3.UP) as Vector3
			var hit_dist = prediction.get("distance", 28.0) as float
			# Progressively assist orientation toward landing deck without snapping
			if hit_dist < 20.0:
				var assist_factor = clampf((20.0 - hit_dist) / 20.0, 0.0, 1.0) * delta * 7.5
				var aligned_basis = AeroPhysicsHelpers.align_basis_to_normal(global_basis, hit_norm, assist_factor)
				global_basis = aligned_basis

	# 3. Preserve forward momentum with realistic aerodynamic drag
	var drag = 0.995
	velocity.x *= drag
	velocity.z *= drag

func _update_visual_dynamics(delta: float) -> void:
	# 1. Wheel Axle Rolling Rotation
	var travel_dist = forward_speed * delta
	wheel_roll_rot += travel_dist / 0.35 # Approx tire radius 0.35m

	if not chassis_node:
		_setup_visuals()
	if not chassis_node:
		return

	# 2. Front Wheels Steering Yaw & Suspension Travel
	var target_steer_angle = deg_to_rad(-steer_input * 32.0)
	if wheels.size() >= 2:
		wheels[0].rotation.y = lerp_angle(wheels[0].rotation.y, target_steer_angle, delta * 16.0)
		wheels[1].rotation.y = lerp_angle(wheels[1].rotation.y, target_steer_angle, delta * 16.0)

	for i in range(wheels.size()):
		var w = wheels[i]
		var mesh = w.get_node_or_null("WheelMesh")
		if mesh:
			mesh.rotation.x = wheel_roll_rot
		# Suspension compression translation in local Y
		var b_y = base_wheel_y[i] if i < base_wheel_y.size() else 0.32
		var comp = suspension_offsets[i] if i < suspension_offsets.size() else 0.0
		w.position.y = lerpf(w.position.y, b_y + comp * 0.45, delta * 18.0)

	# 3. Chassis Roll into Corners, Braking Dive & Landing Spring Compression
	var target_roll = deg_to_rad(steer_input * clampf(forward_speed / top_speed, 0.0, 1.0) * 8.5)
	var target_pitch = 0.0
	if brake_input > 0.0 and forward_speed > 2.0:
		target_pitch = deg_to_rad(3.5) # Braking dive
	elif throttle_input > 0.0 and forward_speed < top_speed * 0.7:
		target_pitch = deg_to_rad(-2.8) # Acceleration squat

	landing_compression = lerpf(landing_compression, 0.0, delta * 8.0)
	chassis_node.position.y = -landing_compression
	chassis_node.rotation.z = lerp_angle(chassis_node.rotation.z, target_roll, delta * 12.0)
	chassis_node.rotation.x = lerp_angle(chassis_node.rotation.x, target_pitch, delta * 12.0)

	# 4. Active Aero Stunt Wing Articulation
	var active_wing = visual_data.get("active_wing") as Node3D
	if is_instance_valid(active_wing):
		var target_wing_pitch = 0.0
		if brake_input > 0.0 and forward_speed > 5.0:
			target_wing_pitch = deg_to_rad(-24.0) # Active airbrake deployment
		elif is_boost_active:
			target_wing_pitch = deg_to_rad(6.0)   # Low-drag DRS speed trim
		active_wing.rotation.x = lerp_angle(active_wing.rotation.x, target_wing_pitch, delta * 14.0)

	# 5. Particle Emitter Dynamics
	var exhausts = visual_data.get("exhaust_emitters", [])
	for ex in exhausts:
		if is_instance_valid(ex):
			ex.emitting = is_boost_active

	var smokes = visual_data.get("smoke_emitters", [])
	for sm in smokes:
		if is_instance_valid(sm):
			sm.emitting = is_drifting and is_grounded

	var air_trails = visual_data.get("air_trails", [])
	var show_trails = (not is_grounded and absf(forward_speed) > 15.0) or (absf(forward_speed) > 38.0) or is_boost_active
	for tr in air_trails:
		if is_instance_valid(tr):
			tr.emitting = show_trails

	# 6. Shader Uniform Updates (Brake / Reverse Lights / Boost Glow)
	var mat = visual_data.get("body_material") as ShaderMaterial
	if mat:
		mat.set_shader_parameter("is_braking", brake_input > 0.0 and forward_speed > 0.5)
		mat.set_shader_parameter("is_reversing", forward_speed < -0.5)
		mat.set_shader_parameter("is_boosting", is_boost_active)

func _check_rollover_and_recovery(delta: float) -> void:
	if not is_inside_tree():
		return

	# 1. Out-of-bounds fall detection: vehicle falls below elevated course or prolonged airborne flight
	var current_y = global_position.y
	if current_y < -2.5 or (not is_grounded and airtime_duration > 3.8):
		recover_to_checkpoint()
		return

	# 2. Check if straying outside playable track corridor (>65m from last safe checkpoint)
	if global_position.distance_to(last_safe_checkpoint_pos) > 65.0:
		recover_to_checkpoint()
		return

	# 3. Check if upside down on ground
	var up_dot = global_basis.y.dot(Vector3.UP)
	if is_grounded and up_dot < -0.2:
		rollover_timer += delta
		if rollover_timer >= 1.2:
			recover_to_checkpoint()
			rollover_timer = 0.0
	elif is_grounded and absf(forward_speed) < 1.5 and up_dot < 0.4:
		stuck_timer += delta
		if stuck_timer >= 1.8:
			recover_to_checkpoint()
			stuck_timer = 0.0
	else:
		rollover_timer = 0.0
		stuck_timer = 0.0

	# 4. Record safe checkpoint transform if driving cleanly on flat track
	if is_grounded and up_dot > 0.75 and absf(forward_speed) > 10.0:
		last_safe_checkpoint_pos = global_position
		last_safe_checkpoint_basis = global_basis

func update_checkpoint(pos: Vector3, b: Basis) -> void:
	last_safe_checkpoint_pos = pos
	last_safe_checkpoint_basis = b

func recover_to_checkpoint() -> void:
	if is_inside_tree():
		global_position = last_safe_checkpoint_pos + Vector3(0, 1.2, 0)
		global_basis = last_safe_checkpoint_basis
	else:
		position = last_safe_checkpoint_pos + Vector3(0, 1.2, 0)
		transform.basis = last_safe_checkpoint_basis


	var fwd = -last_safe_checkpoint_basis.z.normalized()
	velocity = fwd * 15.0 # Rolling launch forward along track
	forward_speed = 15.0
	is_grounded = true
	airtime_duration = 0.0
	rollover_timer = 0.0
	up_direction = last_safe_checkpoint_basis.y.normalized()
	vehicle_respawned.emit(global_position if is_inside_tree() else position)
