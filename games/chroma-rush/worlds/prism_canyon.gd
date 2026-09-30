class_name PrismCanyon
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 3: Prism Canyon
## Sandstone gorges, dynamic elevation changes, restricted canyon passes,
## natural rock arches, and tactical desert pursuit driving.

func _init() -> void:
	world_id = ChromaConstants.WORLD_PRISM_CANYON
	world_name = "Prism Canyon"

func setup_lighting() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.85, 0.45, 0.22)       # Desert sunset amber
	sky_mat.sky_horizon_color = Color(0.95, 0.65, 0.40)   # Golden glow horizon
	sky_mat.ground_bottom_color = Color(0.35, 0.18, 0.10) # Red sandstone earth
	sky_mat.ground_horizon_color = Color(0.70, 0.45, 0.25)
	sky_mat.sun_angle_max = 25.0
	sky.sky_material = sky_mat
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.10
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.88, 0.62, 0.42)
	env.fog_density = 0.0018
	world_environment.environment = env
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.rotation_degrees = Vector3(-30, -55, 0)
	sun_light.light_color = Color(1.0, 0.88, 0.70)
	sun_light.light_energy = 1.6
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.03
	add_child(sun_light)

func setup_ground_plane() -> void:
	var ground = StaticBody3D.new()
	ground.name = "CanyonGroundPlane"
	ground.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1800, 1800)
	mi.mesh = plane_mesh

	var mat_ground = StandardMaterial3D.new()
	mat_ground.albedo_color = Color(0.58, 0.32, 0.18) # Warm red-brown sandstone desert floor
	mat_ground.roughness = 0.95
	mi.material_override = mat_ground
	ground.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1800, 1.0, 1800)
	col.shape = shape
	col.position = Vector3(0, -5.5, 0)
	ground.add_child(col)

	props_container.add_child(ground)

func generate_waypoints() -> void:
	waypoints.clear()
	# 16-point canyon circuit with significant elevation variance
	var raw_points = [
		Vector3(0, 0, 0),         # 0 Canyon Floor Oasis
		Vector3(20, 2, -70),      # 1 Lower Gorge Straight
		Vector3(60, 6, -140),     # 2 Mesa Climb
		Vector3(120, 12, -180),   # 3 High Plateau Switchback
		Vector3(190, 14, -160),   # 4 Sunstone Rim
		Vector3(240, 10, -100),   # 5 Canyon Rim Descent
		Vector3(250, 4, -30),     # 6 Rock Arch Pass 1
		Vector3(210, 0, 40),      # 7 Canyon Wash Basin
		Vector3(160, -2, 90),     # 8 Dry Riverbed Narrows
		Vector3(90, 0, 120),      # 9 Dust Alley
		Vector3(20, 4, 110),      # 10 Ridge Ascent
		Vector3(-40, 8, 80),      # 11 Red Mesa Overlook
		Vector3(-80, 5, 30),      # 12 Sandstone Drop
		Vector3(-70, 2, -20),     # 13 Restricted Chasm
		Vector3(-50, 0, -40),     # 14 Rock Arch Pass 2
		Vector3(-20, 0, -15)      # 15 Oasis Approach
	]
	for p in raw_points:
		waypoints.append(p)

	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var forward = (p1 - p0).normalized()
	player_spawn_transform = Transform3D().looking_at(forward, Vector3.UP)
	player_spawn_transform.origin = p0 + Vector3(0, 0.05, 0)

	traffic_spawn_data = [
		{"waypoint_idx": 2, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 22.0},
		{"waypoint_idx": 5, "color": ChromaConstants.ChromaColor.CRIMSON, "speed": 25.0},
		{"waypoint_idx": 8, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 21.0},
		{"waypoint_idx": 11, "color": ChromaConstants.ChromaColor.COBALT, "speed": 23.0},
		{"waypoint_idx": 14, "color": ChromaConstants.ChromaColor.MAGENTA, "speed": 20.0}
	]

func build_road_mesh() -> void:
	var road_w = 14.0
	build_continuous_road_network(waypoints, road_w)

func build_checkpoints() -> void:
	checkpoints.clear()
	var gate_defs = [
		{"id": "gate_1", "wp_idx": 2, "color": ChromaConstants.ChromaColor.SOLAR},
		{"id": "gate_2", "wp_idx": 4, "color": ChromaConstants.ChromaColor.CRIMSON},
		{"id": "gate_3", "wp_idx": 6, "color": ChromaConstants.ChromaColor.COBALT},
		{"id": "gate_4", "wp_idx": 9, "color": ChromaConstants.ChromaColor.EMERALD},
		{"id": "gate_5", "wp_idx": 11, "color": ChromaConstants.ChromaColor.CYAN},
		{"id": "gate_6", "wp_idx": 14, "color": ChromaConstants.ChromaColor.MAGENTA}
	]

	for g in gate_defs:
		var gate = CheckpointGate.new()
		gate.gate_id = g["id"]
		gate.target_color = g["color"]

		var wp = waypoints[g["wp_idx"]]
		var next_wp = waypoints[(g["wp_idx"] + 1) % waypoints.size()]
		var dir = (next_wp - wp).normalized()

		gates_container.add_child(gate)
		gate.position = wp + Vector3(0.0, 0.2, 0.0)
		if dir.length_squared() > 0.001:
			gate.look_at_from_position(gate.position, gate.position + dir, Vector3.UP)

		checkpoints.append(gate)

func build_props() -> void:
	# Sandstone arches spanning the canyon track
	var arch1 = MeshBuilder.build_rock_arch(26.0, 18.0)
	arch1.position = Vector3(250, 4, -30)
	props_container.add_child(arch1)

	var arch2 = MeshBuilder.build_rock_arch(24.0, 16.0)
	arch2.position = Vector3(-50, 0, -40)
	props_container.add_child(arch2)

	# Mesa rock pillars and bluffs
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.72, 0.38, 0.22)
	rock_mat.roughness = 0.9

	var mesa_positions = [
		Vector3(150, 8, -120), Vector3(280, 5, -80), Vector3(120, -5, 40),
		Vector3(-110, 10, 60), Vector3(-80, 4, -80)
	]
	for pos in mesa_positions:
		var radius = 16.0
		var height = 35.0
		var mesa = StaticBody3D.new()
		mesa.name = "MesaPillar"
		mesa.collision_layer = GameConstants.LAYER_WORLD

		var mi = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = radius
		cyl.bottom_radius = radius + 4.0
		cyl.height = height
		mi.mesh = cyl
		mi.material_override = rock_mat
		mesa.add_child(mi)

		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.radius = radius + 2.0
		c_shape.height = height
		col.shape = c_shape
		mesa.add_child(col)

		mesa.position = pos
		props_container.add_child(mesa)

	# Pine trees along the canyon ridges and shoulders
	var pine_positions = [
		Vector3(40, 0, -40), Vector3(90, 2, -100), Vector3(130, 4, -130),
		Vector3(200, 6, -90), Vector3(240, 8, -30), Vector3(210, 5, 20),
		Vector3(130, 0, 30), Vector3(50, -2, 10), Vector3(-30, 2, -30)
	]
	for pos in pine_positions:
		var pine = _build_pine_tree()
		pine.position = pos
		props_container.add_child(pine)

func _build_pine_tree() -> Node3D:
	var root = StaticBody3D.new()
	root.name = "PineTree"
	root.collision_layer = GameConstants.LAYER_WORLD

	var col = CollisionShape3D.new()
	var c_shape = CylinderShape3D.new()
	c_shape.height = 5.0
	c_shape.radius = 0.40
	col.shape = c_shape
	col.position = Vector3(0, 2.5, 0)
	root.add_child(col)

	var model = ModelCache.get_model("res://assets/models/environment/tree_pine.glb")
	if model:
		model.scale = Vector3(5.2, 5.2, 5.2)
		root.add_child(model)
		return root

	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.3
	cyl.height = 5.0
	trunk.mesh = cyl
	var mat_trunk = StandardMaterial3D.new()
	mat_trunk.albedo_color = Color(0.30, 0.20, 0.14)
	trunk.material_override = mat_trunk
	trunk.position = Vector3(0, 2.5, 0)
	root.add_child(trunk)

	var cone = MeshInstance3D.new()
	var pyr = PrismMesh.new()
	pyr.size = Vector3(3.0, 5.5, 3.0)
	cone.mesh = pyr
	var mat_leaf = StandardMaterial3D.new()
	mat_leaf.albedo_color = Color(0.12, 0.32, 0.16)
	cone.material_override = mat_leaf
	cone.position = Vector3(0, 5.5, 0)
	root.add_child(cone)
	return root
