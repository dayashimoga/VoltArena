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

# Current State
var current_color: int = ChromaConstants.ChromaColor.CRIMSON
var forward_speed: float = 0.0
var steer_input: float = 0.0
var throttle_input: float = 0.0
var brake_input: float = 0.0
var is_drifting: bool = false
var drift_direction: float = 0.0 # -1 left, +1 right
var drift_charge: float = 0.0
var boost_time_left: float = 0.0
var boost_speed_bonus: float = 12.0

func get_speed_kmh() -> float:
	return absf(forward_speed) * 3.6

# Grounding & Physics Recovery
var is_grounded: bool = true
var ground_normal: Vector3 = Vector3.UP
var rollover_timer: float = 0.0
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
	get: return absf(forward_speed) * 3.6

func _ready() -> void:
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
	last_valid_track_pos = global_position
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
	add_child(visual_node)

	front_left_wheel = visual_node.get_node_or_null("FrontWheelLeft")
	front_right_wheel = visual_node.get_node_or_null("FrontWheelRight")
	rear_left_wheel = visual_node.get_node_or_null("RearWheelLeft")
	rear_right_wheel = visual_node.get_node_or_null("RearWheelRight")

func setup_collision_box() -> void:
	if not has_node("ChromaCollision"):
		var col = CollisionShape3D.new()
		col.name = "ChromaCollision"
		var box = BoxShape3D.new()
		box.size = Vector3(1.8, 0.85, 3.8)
		col.shape = box
		col.position = Vector3(0, 0.55, 0)
		add_child(col)

func setup_suspension_rays() -> void:
	wheel_raycasts.clear()
	var ray_offsets = [
		Vector3(-0.85, 0.5, -1.25),
		Vector3(0.85, 0.5, -1.25),
		Vector3(-0.90, 0.5, 1.30),
		Vector3(0.90, 0.5, 1.30)
	]
	for i in range(4):
		var ray = RayCast3D.new()
		ray.name = "RayCast_" + str(i)
		ray.target_position = Vector3(0, -0.95, 0)
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
	_update_grounding_and_suspension()
	_update_physics_movement(delta)
	_update_visual_dynamics(delta)
	_check_rollover_and_recovery(delta)

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

	# Lateral Steering & Drift Yaw
	if is_grounded:
		var speed_ratio = clampf(absf(forward_speed) / maxf(top_speed, 1.0), 0.0, 1.0)
		var effective_steer_speed = steer_speed * (1.15 if speed_ratio < 0.3 else 1.0)

		if is_drifting:
			# Enhanced yaw rotation during drift with boost charge accumulation
			var drift_yaw = -drift_direction * steer_speed * drift_factor * delta * speed_ratio
			rotate_y(drift_yaw)
			drift_charge = minf(drift_charge + delta * 0.9, 3.0)
		else:
			# Standard responsive arcade cornering
			var yaw = -steer_input * effective_steer_speed * delta * (1.0 if forward_speed >= 0.0 else -1.0) * minf(absf(forward_speed) / 4.0, 1.0)
			rotate_y(yaw)

	# Compose 3D velocity
	var t = global_transform if is_inside_tree() else transform
	var forward_dir = -t.basis.z.normalized()
	var horizontal_vel = forward_dir * forward_speed

	# Gravity and vertical grounding
	var vertical_vel = velocity.y
	if not is_grounded:
		vertical_vel -= gravity * delta
	else:
		vertical_vel = -2.0 # Downward snap force

	velocity = Vector3(horizontal_vel.x, vertical_vel, horizontal_vel.z)
	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * delta

	# Track valid road coordinates if grounded and level
	if is_grounded and t.basis.y.dot(Vector3.UP) > 0.7:
		last_valid_track_pos = global_position if is_inside_tree() else position
		last_valid_track_rot = rotation.y

func _update_visual_dynamics(delta: float) -> void:
	if not visual_node:
		return

	# Body roll during cornering
	var target_roll = -steer_input * deg_to_rad(4.5)
	if is_drifting:
		target_roll = -drift_direction * deg_to_rad(7.5)
	visual_node.rotation.z = lerpf(visual_node.rotation.z, target_roll, delta * 8.0)

	# Pitch tilt during accel/braking
	var target_pitch = (brake_input - throttle_input) * deg_to_rad(3.5)
	visual_node.rotation.x = lerpf(visual_node.rotation.x, target_pitch, delta * 8.0)

	# Wheel rolling animation
	wheel_roll_angle += (forward_speed / 0.36) * delta
	for w in [front_left_wheel, front_right_wheel, rear_left_wheel, rear_right_wheel]:
		if is_instance_valid(w):
			w.rotation.x = wheel_roll_angle

	# Front wheel steering angle
	var steer_angle = -steer_input * deg_to_rad(28.0)
	if is_instance_valid(front_left_wheel):
		front_left_wheel.rotation.y = steer_angle
	if is_instance_valid(front_right_wheel):
		front_right_wheel.rotation.y = steer_angle

func _check_rollover_and_recovery(delta: float) -> void:
	var t = global_transform if is_inside_tree() else transform
	var pos = global_position if is_inside_tree() else position
	var up_dot = t.basis.y.dot(Vector3.UP)
	var is_upside_down = up_dot < 0.25
	var is_falling_out_of_world = pos.y < -15.0

	if is_upside_down or is_falling_out_of_world:
		rollover_timer += delta
		if rollover_timer >= 0.75 or is_falling_out_of_world:
			recover_vehicle()
	else:
		rollover_timer = 0.0

func recover_vehicle() -> void:
	rollover_timer = 0.0
	forward_speed = 0.0
	velocity = Vector3.ZERO
	is_drifting = false
	drift_charge = 0.0

	# Restore safely to last valid track location with upright orientation
	if is_inside_tree():
		global_position = last_valid_track_pos + Vector3(0, 0.8, 0)
	else:
		position = last_valid_track_pos + Vector3(0, 0.8, 0)
	rotation = Vector3(0, last_valid_track_rot, 0)

	vehicle_recovered.emit(global_position if is_inside_tree() else position)

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
		VehicleVisuals.apply_gameplay_color(visual_node, new_color)
	color_changed.emit(new_color)

func set_vehicle_type(new_id: String) -> void:
	vehicle_id = new_id
	apply_catalog_stats()
	setup_visuals()
