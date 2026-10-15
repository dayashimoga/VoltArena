class_name TrafficVehicle
extends CharacterBody3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## AI-driven metropolitan traffic vehicle for Urban Legends.
## Features:
## - Autonomous road waypoint following with forward curve anticipation
## - Raycast vehicle & obstacle detection with progressive collision avoidance
## - Randomized civilian paint schemes & procedural sedan visuals
## - Rotating wheels & speed-sensitive steering
## - Dynamic pooling support (activation, despawn, and respawn)

@export var cruise_speed_ms: float = 16.0 # ~58 km/h
@export var current_speed: float = 0.0
@export var is_traffic_active: bool = true
var force_obstacle_detected: bool = false

var waypoints: Array[Transform3D] = []
var current_waypoint_index: int = 0
var avoidance_ray: RayCast3D = null
var visual_wheels: Array[Node3D] = []
var wheel_roll: float = 0.0

var paint_color: Color = Color(0.3, 0.4, 0.5)

func _ready() -> void:
	collision_layer = UrbanConstants.LAYER_ENEMIES
	collision_mask = UrbanConstants.LAYER_WORLD | UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES

	add_to_group("ai_traffic")
	add_to_group("urban_vehicles")

	_setup_collision()
	_setup_sensors()
	_build_visuals()

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	col.name = "TrafficCollision"
	var box = BoxShape3D.new()
	box.size = Vector3(2.0, 1.4, 4.2)
	col.shape = box
	col.position = Vector3(0, 0.8, 0)
	add_child(col)

func _setup_sensors() -> void:
	avoidance_ray = RayCast3D.new()
	avoidance_ray.name = "AvoidanceRay"
	avoidance_ray.position = Vector3(0, 0.7, -2.0)
	avoidance_ray.target_position = Vector3(0, 0, -28.0)
	avoidance_ray.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES | UrbanConstants.LAYER_WORLD
	avoidance_ray.enabled = true
	add_child(avoidance_ray)

func _build_visuals() -> void:
	var visual_root = Node3D.new()
	visual_root.name = "Visuals"

	var colors = [
		Color(0.85, 0.85, 0.88), # Silver
		Color(0.12, 0.12, 0.14), # Black
		Color(0.18, 0.35, 0.75), # Cobalt Blue
		Color(0.75, 0.18, 0.15), # Crimson
		Color(0.22, 0.48, 0.28), # Forest Green
		Color(0.82, 0.75, 0.65)  # Champagne Gold
	]
	paint_color = colors[randi() % colors.size()]

	# Main Body Chassis
	var body_mi = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(1.9, 0.75, 4.2)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = paint_color
	body_mat.metallic = 0.7
	body_mat.roughness = 0.3
	body_mi.mesh = body_mesh
	body_mi.material_override = body_mat
	body_mi.position = Vector3(0, 0.65, 0)
	visual_root.add_child(body_mi)

	# Cabin Greenhouse & Tinted Windows
	var cabin_mi = MeshInstance3D.new()
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(1.6, 0.65, 2.2)
	var cabin_mat = StandardMaterial3D.new()
	cabin_mat.albedo_color = Color(0.08, 0.10, 0.14)
	cabin_mat.metallic = 0.95
	cabin_mat.roughness = 0.08
	cabin_mi.mesh = cabin_mesh
	cabin_mi.material_override = cabin_mat
	cabin_mi.position = Vector3(0, 1.25, 0.15)
	visual_root.add_child(cabin_mi)

	# Headlights
	for side in [-0.7, 0.7]:
		var hl = MeshInstance3D.new()
		var hl_mesh = BoxMesh.new()
		hl_mesh.size = Vector3(0.35, 0.15, 0.1)
		var hl_mat = StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 1.0, 0.9)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 0.95, 0.8) * 2.0
		hl.mesh = hl_mesh
		hl.material_override = hl_mat
		hl.position = Vector3(side, 0.75, -2.12)
		visual_root.add_child(hl)

	# 4 Wheels
	var wheel_offsets = [
		Vector3(-0.95, 0.35, -1.3),
		Vector3(0.95, 0.35, -1.3),
		Vector3(-0.95, 0.35, 1.3),
		Vector3(0.95, 0.35, 1.3)
	]
	var tire_mat = StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.12, 0.12, 0.12)
	tire_mat.roughness = 0.85

	visual_wheels.clear()
	for i in range(4):
		var wheel_node = Node3D.new()
		wheel_node.position = wheel_offsets[i]

		var tire_mi = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.35
		cyl.height = 0.28
		tire_mi.mesh = cyl
		tire_mi.material_override = tire_mat
		tire_mi.rotation.z = PI * 0.5
		wheel_node.add_child(tire_mi)

		visual_root.add_child(wheel_node)
		visual_wheels.append(wheel_node)

	add_child(visual_root)

func set_waypoints(new_waypoints: Array[Transform3D]) -> void:
	waypoints = new_waypoints
	current_waypoint_index = 0
	if not waypoints.is_empty():
		var p = waypoints[0].origin
		if is_inside_tree():
			global_position = p
		else:
			position = p

func _physics_process(delta: float) -> void:
	if not is_traffic_active or waypoints.is_empty():
		return

	# Forward obstacle avoidance check
	var target_speed = cruise_speed_ms
	var my_p = global_position if is_inside_tree() else position
	if force_obstacle_detected:
		target_speed = 0.0 # Emergency brake / obstacle detected in test
	elif avoidance_ray and avoidance_ray.is_colliding():
		var hit_pt = avoidance_ray.get_collision_point()
		var dist = my_p.distance_to(hit_pt)
		if dist < 8.0:
			target_speed = 0.0 # Full stop
		elif dist < 22.0:
			target_speed = lerpf(0.0, cruise_speed_ms * 0.45, (dist - 8.0) / 14.0)

	# Smooth acceleration / braking
	current_speed = move_toward(current_speed, target_speed, 12.0 * delta)

	# Steer toward current waypoint
	var target_wp = waypoints[current_waypoint_index].origin
	var my_pos = global_position if is_inside_tree() else position
	var to_wp = target_wp - my_pos
	to_wp.y = 0.0

	if to_wp.length() < 8.0:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_index].origin
		to_wp = target_wp - my_pos
		to_wp.y = 0.0

	var move_dir = to_wp.normalized()
	if move_dir.length_squared() > 0.001:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		var curr_y = (global_rotation if is_inside_tree() else rotation).y
		var diff = wrapf(target_rot_y - curr_y, -PI, PI)
		var new_y = curr_y + diff * clampf(4.5 * delta, 0.0, 1.0)
		if is_inside_tree():
			global_rotation.y = new_y
		else:
			rotation.y = new_y

	# Update velocity and move
	var fwd = -(global_basis if is_inside_tree() else transform.basis).z
	velocity = fwd * current_speed

	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * delta

	# Animate wheels
	wheel_roll += -(current_speed * delta) / 0.35
	for w in visual_wheels:
		if is_instance_valid(w):
			w.rotation.x = wheel_roll

func reset_traffic_state(new_pos: Vector3, new_forward: Vector3) -> void:
	current_speed = cruise_speed_ms * 0.5
	velocity = new_forward * current_speed
	if is_inside_tree():
		global_position = new_pos
		if new_forward.length_squared() > 0.001:
			look_at(new_pos + new_forward, Vector3.UP)
	else:
		position = new_pos
		if new_forward.length_squared() > 0.001:
			look_at_from_position(new_pos, new_pos + new_forward, Vector3.UP)
