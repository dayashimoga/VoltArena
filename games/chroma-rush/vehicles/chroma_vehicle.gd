class_name ChromaVehicle
extends CharacterBody3D

## Unified CharacterBody3D vehicle controller for Chroma Rush
## Powers both player and AI vehicles with responsive arcade handling,
## drifting, suspension tilt, reliable grounding, and rollover recovery.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const VehicleCatalog = preload("res://games/chroma-rush/vehicles/vehicle_catalog.gd")
const VehicleVisuals = preload("res://games/chroma-rush/vehicles/vehicle_visuals.gd")

signal color_changed(new_color: int)
signal drift_boost_released(boost_level: int)
signal vehicle_recovered(recover_position: Vector3)

# Identity & Configuration
@export var vehicle_id: String = ChromaConstants.VEHICLE_APEX
@export var vehicle_owner_id: String = "player"
@export var is_player: bool = true
@export var initial_color: int = ChromaConstants.ChromaColor.CRIMSON
@export var paint_finish: String = "metallic"
var custom_paint_color: Color = Color(0.15, 0.75, 1.0)

# Configured Physical Parameters (populated via VehicleCatalog)
var top_speed: float = 38.0
var acceleration: float = 28.0
var steer_speed: float = 3.4
var brake_force: float = 36.0
var drift_factor: float = 4.2
var suspension_stiffness: float = 14.0
var vehicle_mass: float = 1100.0
var gravity: float = 28.0

var current_color: int = ChromaConstants.ChromaColor.CRIMSON:
	set(val):
		current_color = val
		if visual_node and is_instance_valid(visual_node):
			VehicleVisuals.apply_gameplay_color(visual_node, current_color, paint_finish)
		color_changed.emit(current_color)
var forward_speed: float = 0.0
var steer_input: float = 0.0
var smoothed_steer_input: float = 0.0
var throttle_input: float = 0.0
var brake_input: float = 0.0

var is_drifting: bool = false
var drift_direction: float = 0.0 # -1 left, +1 right
var drift_charge: float = 0.0
var boost_time_left: float = 0.0
var boost_speed_bonus: float = 12.0
var controls_enabled: bool = true

func get_speed_kmh() -> float:
	if is_inside_tree():
		var real_v = get_real_velocity()
		var h_speed = Vector2(real_v.x, real_v.z).length()
		return h_speed * 3.6
	return absf(forward_speed) * 3.6

# Grounding & Physics Recovery
var is_grounded: bool = true
var ground_normal: Vector3 = Vector3.UP
var rollover_timer: float = 0.0
var stuck_timer: float = 0.0
var last_valid_track_pos: Vector3 = Vector3.ZERO
var last_valid_track_rot: float = 0.0
var wheel_raycasts: Array[RayCast3D] = []

# Visual node references
var visual_node: Node3D
var front_left_wheel: Node3D
var front_right_wheel: Node3D
var rear_left_wheel: Node3D
var rear_right_wheel: Node3D
var wheel_roll_angle: float = 0.0

# Telemetry
var speed_kph: float:
	get: return get_speed_kmh()

var _is_ready_initialized: bool = false

func _ready() -> void:
	if _is_ready_initialized:
		return
	_is_ready_initialized = true

	collision_layer = GameConstants.LAYER_PLAYER if is_player else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

	add_to_group("chroma_vehicles")
	if is_player:
		add_to_group("players")
	else:
		add_to_group("ai_vehicles")

	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(65.0)
	floor_constant_speed = true
	up_direction = Vector3.UP

	apply_catalog_stats()
	setup_visuals()
	setup_suspension_rays()
	setup_collision_box()

	current_color = initial_color
	last_valid_track_pos = global_position if is_inside_tree() else position
	last_valid_track_rot = rotation.y

func apply_catalog_stats() -> void:
	var def = VehicleCatalog.get_vehicle_definition(vehicle_id)
	top_speed = def["top_speed"]
	acceleration = def["acceleration"]
	steer_speed = def["steer_speed"]
	brake_force = def["brake_force"]
	drift_factor = def["drift_factor"]
	suspension_stiffness = def["suspension_stiffness"]
	vehicle_mass = def["mass"]

func setup_visuals() -> void:
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()

	visual_node = VehicleVisuals.build_vehicle_visual(vehicle_id, initial_color, paint_finish)
	# Align visual node with physics origin so wheels make direct contact with road surface
	visual_node.position.y = 0.0
	add_child(visual_node)

	var model_root = visual_node.get_node_or_null("ModelRoot")
	if model_root:
		front_left_wheel = model_root.get_node_or_null("wheel-front-left")
		front_right_wheel = model_root.get_node_or_null("wheel-front-right")
		rear_left_wheel = model_root.get_node_or_null("wheel-back-left")
		rear_right_wheel = model_root.get_node_or_null("wheel-back-right")
	if not front_left_wheel:
		front_left_wheel = visual_node.get_node_or_null("FrontWheelLeft")
	if not front_right_wheel:
		front_right_wheel = visual_node.get_node_or_null("FrontWheelRight")
	if not rear_left_wheel:
		rear_left_wheel = visual_node.get_node_or_null("RearWheelLeft")
	if not rear_right_wheel:
		rear_right_wheel = visual_node.get_node_or_null("RearWheelRight")

func setup_collision_box() -> void:
	if not has_node("ChromaCollision"):
		var col = CollisionShape3D.new()
		col.name = "ChromaCollision"
		var box = BoxShape3D.new()
		box.size = Vector3(1.85, 0.70, 4.10)
		col.shape = box
		# Center box at y=0.52 so bottom face is at y=0.17, giving 17cm curb/ramp clearance
		col.position = Vector3(0, 0.52, 0)
		add_child(col)

func setup_suspension_rays() -> void:
	wheel_raycasts.clear()
	# Front wheels at -Z (-1.15m), rear wheels at +Z (+1.15m)
	var ray_offsets = [
		Vector3(-0.85, 0.45, -1.15),
		Vector3(0.85, 0.45, -1.15),
		Vector3(-0.85, 0.45, 1.15),
		Vector3(0.85, 0.45, 1.15)
	]
	for i in range(4):
		var ray = RayCast3D.new()
		ray.name = "RayCast_" + str(i)
		ray.target_position = Vector3(0, -0.65, 0)
		ray.position = ray_offsets[i]
		ray.collision_mask = GameConstants.LAYER_WORLD
		add_child(ray)
		wheel_raycasts.append(ray)

# --- COMMON VEHICLE CONTROL INTERFACE ---
func set_inputs(steer: float, throttle: float, brake: float, handbrake: bool, boost: bool) -> void:
	steer_input = clampf(steer, -1.0, 1.0)
	throttle_input = clampf(throttle, 0.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)

	# Drift initiation and release
	if handbrake and absf(steer_input) > 0.2 and not is_drifting and forward_speed > 10.0:
		is_drifting = true
		drift_direction = signf(steer_input)
		drift_charge = 0.0
	elif not handbrake and is_drifting:
		# Release drift mini-turbo boost
		_release_drift_boost()
		is_drifting = false

	if boost and boost_time_left <= 0.0 and drift_charge >= 1.0:
		trigger_nitro_boost(2.0)

func _physics_process(delta: float) -> void:
	if is_player:
		_handle_player_input()
	_update_grounding_and_suspension()
	_update_physics_movement(delta)
	_update_visual_dynamics(delta)
	_check_rollover_and_recovery(delta)

func _handle_player_input() -> void:
	if not is_inside_tree():
		return
	if not controls_enabled:
		set_inputs(0.0, 0.0, 0.8, false, false)
		return

	# Manual instant vehicle recovery hotkey
	if Input.is_key_pressed(KEY_R):
		recover_vehicle()
		return

	var steer: float = 0.0
	var throttle: float = 0.0
	var brake: float = 0.0
	var handbrake: bool = false
	var boost: bool = false

	# 1. Action mappings with direct key fallbacks
	if InputMap.has_action("move_left") and InputMap.has_action("move_right"):
		steer = Input.get_axis("move_left", "move_right")
	else:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			steer -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			steer += 1.0

	if InputMap.has_action("move_forward"):
		throttle = Input.get_action_strength("move_forward")
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			throttle = 1.0

	if InputMap.has_action("move_back"):
		brake = Input.get_action_strength("move_back")
	else:
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			brake = 1.0

	if InputMap.has_action("drift"):
		handbrake = Input.is_action_pressed("drift")
	else:
		handbrake = Input.is_key_pressed(KEY_SHIFT)

	if InputMap.has_action("boost"):
		boost = Input.is_action_pressed("boost")
	else:
		boost = Input.is_key_pressed(KEY_SPACE)

	# 2. Touch / Virtual Joystick input
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and "virtual_move_vector" in im and im.virtual_move_vector != Vector2.ZERO:
		if absf(im.virtual_move_vector.x) > 0.05:
			steer = im.virtual_move_vector.x
		if im.virtual_move_vector.y < -0.05:
			throttle = maxf(throttle, -im.virtual_move_vector.y)
		elif im.virtual_move_vector.y > 0.05:
			brake = maxf(brake, im.virtual_move_vector.y)

	set_inputs(steer, throttle, brake, handbrake, boost)

func _update_grounding_and_suspension() -> void:
	if not is_inside_tree():
		is_grounded = true
		ground_normal = Vector3.UP
		return

	var hits: int = 0
	var avg_normal: Vector3 = Vector3.ZERO
	for ray in wheel_raycasts:
		if ray.is_colliding():
			hits += 1
			avg_normal += ray.get_collision_normal()

	is_grounded = is_on_floor() or hits >= 2
	if hits > 0:
		ground_normal = (avg_normal / float(hits)).normalized()
	else:
		ground_normal = Vector3.UP

func _update_physics_movement(delta: float) -> void:
	# Calculate target max speed including nitro boost
	var active_max_speed = top_speed + (boost_speed_bonus if boost_time_left > 0.0 else 0.0)
	if boost_time_left > 0.0:
		boost_time_left = maxf(0.0, boost_time_left - delta)

	# Longitudinal Acceleration & Braking
	if throttle_input > 0.0:
		var accel_rate = acceleration * (1.3 if boost_time_left > 0.0 else 1.0)
		forward_speed = move_toward(forward_speed, active_max_speed, accel_rate * delta)
	elif brake_input > 0.0:
		if forward_speed > 0.5:
			# Braking
			forward_speed = move_toward(forward_speed, 0.0, brake_force * delta)
		else:
			# Reverse (capped at 12 m/s)
			forward_speed = move_toward(forward_speed, -12.0, acceleration * 0.6 * delta)
	else:
		# Rolling friction drag
		forward_speed = move_toward(forward_speed, 0.0, 6.0 * delta)

	# Progressive Steering & Speed-Sensitive Cornering Limits
	var deadzone = 0.05
	var target_steer = steer_input if absf(steer_input) > deadzone else 0.0
	var steer_rate = 9.0 if absf(target_steer) > absf(smoothed_steer_input) else 14.0
	smoothed_steer_input = move_toward(smoothed_steer_input, target_steer, steer_rate * delta)

	if is_grounded:
		var speed_ratio = clampf(absf(forward_speed) / maxf(top_speed, 1.0), 0.0, 1.0)
		var speed_damp = 1.0 / (1.0 + maxf(0.0, (get_speed_kmh() - 40.0) / 70.0))
		var effective_steer_speed = steer_speed * speed_damp

		if is_drifting:
			# Enhanced yaw rotation during drift with boost charge accumulation
			var drift_yaw = -drift_direction * steer_speed * drift_factor * delta * speed_ratio
			rotate_y(drift_yaw)
			drift_charge = minf(drift_charge + delta * 0.9, 3.0)
		else:
			# Standard responsive arcade cornering with progressive smoothed steering
			var yaw = -smoothed_steer_input * effective_steer_speed * delta * (1.0 if forward_speed >= 0.0 else -1.0) * minf(absf(forward_speed) / 3.5, 1.0)
			rotate_y(yaw)

	# Compose 3D velocity
	var t = global_transform if is_inside_tree() else transform
	var forward_dir = -t.basis.z.normalized()

	if is_grounded:
		# Project forward driving direction onto ground plane to follow ramps and slopes
		var slope_forward = (forward_dir - ground_normal * forward_dir.dot(ground_normal)).normalized()
		var ground_drive_vel = slope_forward * forward_speed
		var snap_down = -2.5
		velocity = Vector3(ground_drive_vel.x, ground_drive_vel.y + snap_down, ground_drive_vel.z)
	else:
		# Mid-air ballistics
		var h_vel = Vector3(forward_dir.x, 0.0, forward_dir.z).normalized() * forward_speed
		velocity = Vector3(h_vel.x, velocity.y - gravity * delta, h_vel.z)

	if is_inside_tree():
		move_and_slide()
		var real_v = get_real_velocity()
		var fwd = -t.basis.z.normalized()
		var real_fwd_speed = real_v.dot(fwd)

		# Only clamp forward_speed on REAL vertical wall collisions (normal.y < 0.4), NOT driveable slopes (normal.y >= 0.4)
		if get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var slide_col = get_slide_collision(i)
				var normal = slide_col.get_normal()
				if absf(normal.y) < 0.4:
					# This is a vertical wall / barrier / building collision
					if normal.dot(fwd) < -0.35 and forward_speed > 0.0:
						forward_speed = maxf(0.0, real_fwd_speed)
					elif normal.dot(fwd) > 0.35 and forward_speed < 0.0:
						forward_speed = minf(0.0, real_fwd_speed)

				var collider = slide_col.get_collider()
				if collider is CharacterBody3D:
					# Clamp upward velocity to prevent climbing or wedging
					velocity.y = minf(velocity.y, 0.0)
					if collider is ChromaVehicle:
						var rel_fwd = forward_speed - collider.forward_speed
						if rel_fwd > 0.0:
							forward_speed = maxf(0.0, collider.forward_speed + rel_fwd * 0.3)
							collider.forward_speed += rel_fwd * 0.5
	else:
		position += velocity * delta

	# Track valid road coordinates if grounded and level
	if is_grounded and t.basis.y.dot(Vector3.UP) > 0.7:
		last_valid_track_pos = global_position if is_inside_tree() else position
		last_valid_track_rot = rotation.y

func _update_visual_dynamics(delta: float) -> void:
	if not visual_node:
		return

	var model_root = visual_node.get_node_or_null("ModelRoot")
	var has_model_root = (model_root != null)

	# Body roll during cornering
	var target_roll = -steer_input * deg_to_rad(4.5)
	if is_drifting:
		target_roll = -drift_direction * deg_to_rad(7.5)

	# Pitch tilt during accel/braking
	var target_pitch = (brake_input - throttle_input) * deg_to_rad(3.5)

	# Invert roll and pitch for 180° rotated ModelRoot coordinate frame
	if has_model_root:
		target_roll = -target_roll
		target_pitch = -target_pitch

	# Apply body suspension roll and pitch to the body mesh
	var body_mesh = null
	if model_root:
		body_mesh = model_root.get_node_or_null("body")
	if not body_mesh:
		body_mesh = visual_node.get_node_or_null("ChassisBody")

	if body_mesh:
		body_mesh.rotation.z = lerpf(body_mesh.rotation.z, target_roll, delta * 8.0)
		body_mesh.rotation.x = lerpf(body_mesh.rotation.x, target_pitch, delta * 8.0)
	else:
		visual_node.rotation.z = lerpf(visual_node.rotation.z, target_roll, delta * 8.0)
		visual_node.rotation.x = lerpf(visual_node.rotation.x, target_pitch, delta * 8.0)

	# Wheel rolling animation: inverted rolling in 180-deg rotated model space
	var roll_sign = -1.0 if has_model_root else 1.0
	wheel_roll_angle += roll_sign * (forward_speed / 0.36) * delta
	for w in [front_left_wheel, front_right_wheel, rear_left_wheel, rear_right_wheel]:
		if is_instance_valid(w):
			w.rotation.x = wheel_roll_angle

	# Front wheel steering angle aligned with car heading
	var steer_angle = (steer_input if has_model_root else -steer_input) * deg_to_rad(28.0)
	if is_instance_valid(front_left_wheel):
		front_left_wheel.rotation.y = steer_angle
	if is_instance_valid(front_right_wheel):
		front_right_wheel.rotation.y = steer_angle

	# Dynamic tail/brake and reverse lighting
	var is_b = (brake_input > 0.05 and forward_speed > 0.5)
	var is_rev = (forward_speed < -0.1 and brake_input > 0.05)
	VehicleVisuals.update_vehicle_lights(visual_node, is_b, is_rev)

func _check_rollover_and_recovery(delta: float) -> void:
	var t = global_transform if is_inside_tree() else transform
	var pos = global_position if is_inside_tree() else position
	var up_dot = t.basis.y.dot(Vector3.UP)
	var is_upside_down = up_dot < 0.25
	var is_falling_out_of_world = pos.y < -15.0

	# Stuck against an obstacle with full throttle
	if is_player and throttle_input > 0.5 and get_speed_kmh() < 1.0 and is_on_wall():
		stuck_timer += delta
		if stuck_timer >= 2.5:
			stuck_timer = 0.0
			recover_vehicle()
			return
	else:
		stuck_timer = 0.0

	if is_upside_down or is_falling_out_of_world:
		rollover_timer += delta
		if rollover_timer >= 0.75 or is_falling_out_of_world:
			recover_vehicle()
	else:
		rollover_timer = 0.0

func reset_to_road(target_pos: Variant = null, target_rot_y: Variant = null) -> void:
	rollover_timer = 0.0
	stuck_timer = 0.0
	forward_speed = 0.0
	velocity = Vector3.ZERO
	is_drifting = false
	drift_charge = 0.0
	smoothed_steer_input = 0.0

	var dest_pos = last_valid_track_pos + Vector3(0, 0.15, 0)
	var dest_rot = last_valid_track_rot

	if target_pos is Vector3 and target_pos != Vector3.ZERO:
		dest_pos = target_pos + Vector3(0, 0.15, 0)
		if target_rot_y is float:
			dest_rot = target_rot_y
	elif is_inside_tree():
		var world = get_tree().get_first_node_in_group("chroma_world")
		if world and world.has_method("get_nearest_safe_road_transform"):
			var safe_xf = world.get_nearest_safe_road_transform(global_position)
			dest_pos = safe_xf.origin
			dest_rot = atan2(-safe_xf.basis.z.x, -safe_xf.basis.z.z)
		elif target_rot_y is float:
			dest_rot = target_rot_y
	elif target_rot_y is float:
		dest_rot = target_rot_y

	if is_inside_tree():
		global_position = dest_pos
	else:
		position = dest_pos
	rotation = Vector3(0, dest_rot, 0)

	vehicle_recovered.emit(global_position if is_inside_tree() else position)

func recover_vehicle() -> void:
	reset_to_road()


func _release_drift_boost() -> void:
	var boost_level = 0
	if drift_charge >= 2.0:
		boost_level = 2
		trigger_nitro_boost(2.2)
	elif drift_charge >= 0.9:
		boost_level = 1
		trigger_nitro_boost(1.2)

	drift_boost_released.emit(boost_level)
	drift_charge = 0.0

func trigger_nitro_boost(duration: float) -> void:
	boost_time_left = duration

func set_color(new_color: int) -> void:
	current_color = new_color
	if visual_node:
		VehicleVisuals.apply_gameplay_color(visual_node, new_color, paint_finish)
	color_changed.emit(new_color)

func set_vehicle_type(new_id: String) -> void:
	vehicle_id = new_id
	apply_catalog_stats()
	setup_visuals()
