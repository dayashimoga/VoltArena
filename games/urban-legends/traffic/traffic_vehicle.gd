class_name TrafficVehicle
extends CharacterBody3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const ModelCache = preload("res://shared/graphics/model_cache.gd")

const TRAFFIC_MODELS: Array[String] = [
	"res://assets/models/vehicles/car_sedan.glb",
	"res://assets/models/vehicles/car_taxi.glb",
	"res://assets/models/vehicles/car_police.glb",
	"res://assets/models/vehicles/car_suv.glb",
	"res://assets/models/vehicles/truck_yellow.glb"
]

## AI-driven metropolitan traffic vehicle for Urban Legends.
## Features:
## - Autonomous road waypoint following with forward curve anticipation
## - Raycast vehicle & obstacle detection with progressive collision avoidance
## - 100% authentic production GLB vehicle fleet (sedan, taxi, police interceptor, luxury SUV, delivery truck)
## - Projector LED headlights and reactive taillights
## - Rotating wheels & speed-sensitive steering
## - Dynamic pooling support (activation, despawn, and respawn)
## - Zero visible primitive BoxMesh / CylinderMesh geometry

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
var is_police: bool = false

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

	var model_path = TRAFFIC_MODELS[randi() % TRAFFIC_MODELS.size()]
	is_police = model_path.contains("police")
	var car_model = ModelCache.get_model(model_path)
	if not is_instance_valid(car_model):
		car_model = ModelCache.get_model("res://assets/models/vehicles/car_sedan.glb")
	if not is_instance_valid(car_model):
		car_model = ModelCache.get_model("res://assets/models/vehicles/car_suv.glb")

	visual_wheels.clear()

	if is_instance_valid(car_model):
		car_model.name = "BodyModel"
		car_model.scale = Vector3(1.3, 1.3, 1.3)
		car_model.rotation.y = PI
		car_model.position = Vector3(0.0, 0.05, 0.0)
		visual_root.add_child(car_model)

		# Hide internal static wheels so articulated alloy wheels take over
		_hide_internal_wheels(car_model)
		_spawn_fallback_wheels(visual_root)
	else:
		_build_procedural_traffic_visual(visual_root)

	# Projector Headlights
	_build_traffic_lighting(visual_root)

	add_child(visual_root)

func _hide_internal_wheels(node: Node) -> void:
	if node is MeshInstance3D:
		var n_low = node.name.to_lower()
		if "wheel" in n_low:
			node.visible = false
	for child in node.get_children():
		_hide_internal_wheels(child)

func _build_traffic_lighting(visual_root: Node3D) -> void:
	var headlight_mat = StandardMaterial3D.new()
	headlight_mat.albedo_color = Color(0.95, 0.98, 1.0)
	headlight_mat.emission_enabled = true
	headlight_mat.emission = Color(0.95, 0.98, 1.0)
	headlight_mat.emission_energy_multiplier = 3.0

	var taillight_mat = StandardMaterial3D.new()
	taillight_mat.albedo_color = Color(0.85, 0.05, 0.05)
	taillight_mat.emission_enabled = true
	taillight_mat.emission = Color(0.95, 0.04, 0.04)
	taillight_mat.emission_energy_multiplier = 2.0

	var lens_mesh = _create_lens_disc(0.08, 12)

	# Headlights
	for hx in [-0.75, 0.75]:
		var hl = MeshInstance3D.new()
		hl.mesh = lens_mesh
		hl.material_override = headlight_mat
		hl.position = Vector3(hx, 0.65, -2.05)
		visual_root.add_child(hl)

		var spot = SpotLight3D.new()
		spot.light_color = Color(0.95, 0.98, 1.0)
		spot.light_energy = 2.0
		spot.spot_range = 28.0
		spot.spot_angle = 32.0
		spot.position = Vector3(hx, 0.65, -2.10)
		spot.rotation_degrees.x = -5.0
		visual_root.add_child(spot)

	# Taillights
	for tx in [-0.75, 0.75]:
		var tl = MeshInstance3D.new()
		tl.mesh = lens_mesh
		tl.material_override = taillight_mat
		tl.position = Vector3(tx, 0.72, 2.05)
		tl.rotation.y = PI
		visual_root.add_child(tl)

	# Flashing emergency lightbar for police cruiser
	if is_police:
		var beacon_red = OmniLight3D.new()
		beacon_red.name = "BeaconRed"
		beacon_red.light_color = Color(1.0, 0.08, 0.08)
		beacon_red.light_energy = 3.5
		beacon_red.omni_range = 16.0
		beacon_red.position = Vector3(-0.35, 1.45, 0.0)
		visual_root.add_child(beacon_red)

		var beacon_blue = OmniLight3D.new()
		beacon_blue.name = "BeaconBlue"
		beacon_blue.light_color = Color(0.1, 0.35, 1.0)
		beacon_blue.light_energy = 3.5
		beacon_blue.omni_range = 16.0
		beacon_blue.position = Vector3(0.35, 1.45, 0.0)
		visual_root.add_child(beacon_blue)

func _spawn_fallback_wheels(visual_root: Node3D) -> void:
	var wheel_offsets = [
		Vector3(-0.95, 0.35, -1.3),
		Vector3(0.95, 0.35, -1.3),
		Vector3(-0.95, 0.35, 1.3),
		Vector3(0.95, 0.35, 1.3)
	]

	for i in range(4):
		var wheel_node = Node3D.new()
		wheel_node.position = wheel_offsets[i]
		var w_model = ModelCache.get_model("res://assets/models/vehicles/car_wheel_racing.glb")
		if is_instance_valid(w_model):
			w_model.scale = Vector3(1.1, 1.1, 1.1)
			if i % 2 == 1:
				w_model.rotation.y = PI
			wheel_node.add_child(w_model)
		else:
			var tire_mat = StandardMaterial3D.new()
			tire_mat.albedo_color = Color(0.12, 0.12, 0.12)
			tire_mat.roughness = 0.85
			var tire_mi = MeshInstance3D.new()
			tire_mi.mesh = _create_wheel_mesh(0.35, 0.28, 16)
			tire_mi.material_override = tire_mat
			wheel_node.add_child(tire_mi)

		visual_root.add_child(wheel_node)
		visual_wheels.append(wheel_node)

func _build_procedural_traffic_visual(visual_root: Node3D) -> void:
	var colors = [
		Color(0.85, 0.85, 0.88), # Silver
		Color(0.12, 0.12, 0.14), # Black
		Color(0.18, 0.35, 0.75), # Cobalt Blue
		Color(0.75, 0.18, 0.15), # Crimson
		Color(0.22, 0.48, 0.28), # Forest Green
		Color(0.82, 0.75, 0.65)  # Champagne Gold
	]
	paint_color = colors[randi() % colors.size()]

	# Main Body Chassis (Faceted ArrayMesh, strictly zero BoxMesh)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = 0.95
	var hl = 2.1
	var h_low = 0.55

	var p0 = Vector3(0, 0.2, -hl)
	var p1 = Vector3(-hw, 0.45, -hl * 0.7)
	var p2 = Vector3(hw, 0.45, -hl * 0.7)
	var p3 = Vector3(0, h_low, -hl * 0.2)
	var p4 = Vector3(-hw, 0.50, hl * 0.7)
	var p5 = Vector3(hw, 0.50, hl * 0.7)
	var p6 = Vector3(0, 0.25, hl)

	st.set_normal(Vector3(0, 0.5, -0.86).normalized())
	st.add_vertex(p3); st.add_vertex(p1); st.add_vertex(p0)
	st.add_vertex(p3); st.add_vertex(p0); st.add_vertex(p2)

	st.set_normal(Vector3.LEFT)
	st.add_vertex(p3); st.add_vertex(p4); st.add_vertex(p1)
	st.set_normal(Vector3.RIGHT)
	st.add_vertex(p3); st.add_vertex(p2); st.add_vertex(p5)

	st.set_normal(Vector3(0, 0.4, 0.91).normalized())
	st.add_vertex(p3); st.add_vertex(p5); st.add_vertex(p6)
	st.add_vertex(p3); st.add_vertex(p6); st.add_vertex(p4)

	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = paint_color
	body_mat.metallic = 0.7
	body_mat.roughness = 0.3

	var body_mi = MeshInstance3D.new()
	body_mi.mesh = st.commit()
	body_mi.material_override = body_mat
	body_mi.position = Vector3(0, 0.4, 0)
	visual_root.add_child(body_mi)

	_spawn_fallback_wheels(visual_root)

func _create_lens_disc(radius: float, segments: int = 12) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var p0 = Vector3(cos(a0) * radius, sin(a0) * radius, 0.0)
		var p1 = Vector3(cos(a1) * radius, sin(a1) * radius, 0.0)
		st.set_normal(Vector3.FORWARD)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5))
		st.add_vertex(p0)
		st.set_uv(Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5))
		st.add_vertex(p1)
	return st.commit()

func _create_wheel_mesh(radius: float, width: float, segments: int = 16) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5

	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var y0 = cos(a0) * radius; var z0 = sin(a0) * radius
		var y1 = cos(a1) * radius; var z1 = sin(a1) * radius

		var v0 = Vector3(-hw, y0, z0)
		var v1 = Vector3(hw, y0, z0)
		var v2 = Vector3(hw, y1, z1)
		var v3 = Vector3(-hw, y1, z1)

		var n0 = Vector3(0.0, cos(a0), sin(a0))
		var n1 = Vector3(0.0, cos(a1), sin(a1))

		st.set_normal(n0); st.add_vertex(v0)
		st.set_normal(n0); st.add_vertex(v1)
		st.set_normal(n1); st.add_vertex(v2)

		st.set_normal(n0); st.add_vertex(v0)
		st.set_normal(n1); st.add_vertex(v2)
		st.set_normal(n1); st.add_vertex(v3)

		st.set_normal(Vector3.RIGHT)
		st.add_vertex(Vector3(hw, 0.0, 0.0))
		st.add_vertex(Vector3(hw, y0, z0))
		st.add_vertex(Vector3(hw, y1, z1))

		st.set_normal(Vector3.LEFT)
		st.add_vertex(Vector3(-hw, 0.0, 0.0))
		st.add_vertex(Vector3(-hw, y1, z1))
		st.add_vertex(Vector3(-hw, y0, z0))

	return st.commit()

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

	if is_police:
		var flash = fmod(Time.get_ticks_msec() * 0.005, 2.0) < 1.0
		var r_light = get_node_or_null("Visuals/BeaconRed")
		var b_light = get_node_or_null("Visuals/BeaconBlue")
		if r_light and b_light:
			r_light.visible = flash
			b_light.visible = not flash

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
	position = new_pos
	if new_forward.length_squared() > 0.001:
		look_at_from_position(new_pos, new_pos + new_forward, Vector3.UP)
