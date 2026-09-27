class_name CoastalRush
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 2: Coastal Rush
## Shoreline highway, ocean suspension bridges, cliffside hairpins,
## seaside village, and harbor routes.

func _init() -> void:
	world_id = ChromaConstants.WORLD_COASTAL_RUSH
	world_name = "Coastal Rush"

func setup_lighting() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.65, 0.90) # Sunny coastal sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.75, 0.85)
	env.ambient_light_energy = 1.15
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = env
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.rotation_degrees = Vector3(-55, 45, 0)
	sun_light.light_color = Color(1.0, 0.95, 0.88) # Warm golden sunlight
	sun_light.light_energy = 1.4
	sun_light.shadow_enabled = true
	add_child(sun_light)

func generate_waypoints() -> void:
	waypoints.clear()
	# 16-point coastal circuit with ocean bridge and cliff curves
	var raw_points = [
		Vector3(0, 0, 0),         # 0 Harbor Start/Finish
		Vector3(30, 0, -80),      # 1 Promenade Straight
		Vector3(80, 0, -150),     # 2 Beach Marina Entry
		Vector3(140, 2, -200),    # 3 Ocean Suspension Bridge Incline
		Vector3(220, 4, -200),    # 4 Suspension Bridge Span
		Vector3(300, 2, -180),    # 5 Bridge Landfall
		Vector3(340, 6, -110),    # 6 Cliffside Hairpin 1
		Vector3(320, 8, -40),     # 7 Scenic Ridge
		Vector3(280, 10, 30),     # 8 Lighthouse Bluff
		Vector3(210, 8, 80),      # 9 Coastal Village North
		Vector3(140, 5, 110),     # 10 Village Center Square
		Vector3(70, 2, 100),      # 11 Sea Wall Highway
		Vector3(10, 0, 70),       # 12 Harbor Approach
		Vector3(-40, 0, 50),      # 13 Dockside Pier
		Vector3(-50, 0, 0),       # 14 Container Yard
		Vector3(-25, 0, 0)        # 15 Final Chicane
	]
	for p in raw_points:
		waypoints.append(p)

	player_spawn_transform = Transform3D(Basis(), Vector3(0, 0.4, 0))

	traffic_spawn_data = [
		{"waypoint_idx": 1, "color": ChromaConstants.ChromaColor.CRIMSON, "speed": 24.0},
		{"waypoint_idx": 4, "color": ChromaConstants.ChromaColor.COBALT, "speed": 22.0},
		{"waypoint_idx": 8, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 21.0},
		{"waypoint_idx": 11, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 25.0},
		{"waypoint_idx": 14, "color": ChromaConstants.ChromaColor.CYAN, "speed": 23.0}
	]

func build_road_mesh() -> void:
	for i in range(waypoints.size()):
		var p1 = waypoints[i]
		var p2 = waypoints[(i + 1) % waypoints.size()]
		add_road_segment(p1, p2, 13.5)

func build_checkpoints() -> void:
	checkpoints.clear()
	var gate_defs = [
		{"id": "gate_1", "wp_idx": 2, "color": ChromaConstants.ChromaColor.COBALT},
		{"id": "gate_2", "wp_idx": 4, "color": ChromaConstants.ChromaColor.CYAN},
		{"id": "gate_3", "wp_idx": 6, "color": ChromaConstants.ChromaColor.SOLAR},
		{"id": "gate_4", "wp_idx": 8, "color": ChromaConstants.ChromaColor.CRIMSON},
		{"id": "gate_5", "wp_idx": 10, "color": ChromaConstants.ChromaColor.EMERALD},
		{"id": "gate_6", "wp_idx": 13, "color": ChromaConstants.ChromaColor.MAGENTA}
	]

	for g in gate_defs:
		var gate = CheckpointGate.new()
		gate.gate_id = g["id"]
		gate.target_color = g["color"]

		var wp = waypoints[g["wp_idx"]]
		var next_wp = waypoints[(g["wp_idx"] + 1) % waypoints.size()]
		var dir = (next_wp - wp).normalized()

		gate.position = wp
		if dir.length_squared() > 0.001:
			gate.look_at_from_position(wp, wp + dir, Vector3.UP)

		gates_container.add_child(gate)
		checkpoints.append(gate)

func build_props() -> void:
	# Ocean Water Plane
	var ocean = MeshInstance3D.new()
	ocean.name = "OceanSurface"
	var p_mesh = PlaneMesh.new()
	p_mesh.size = Vector2(800, 800)
	ocean.mesh = p_mesh
	ocean.position = Vector3(150, -1.0, -50)

	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.05, 0.35, 0.55, 0.9)
	water_mat.roughness = 0.1
	water_mat.metallic = 0.2
	ocean.material_override = water_mat
	props_container.add_child(ocean)

	# Palm trees along promenade & village
	var palm_positions = [
		Vector3(15, 0, -50), Vector3(35, 0, -110), Vector3(65, 0, -130),
		Vector3(290, 10, 50), Vector3(230, 8, 90), Vector3(160, 5, 120),
		Vector3(90, 2, 110), Vector3(30, 0, 85)
	]
	for pos in palm_positions:
		var palm = MeshBuilder.build_palm_tree(randf_range(6.5, 9.0))
		palm.position = pos
		props_container.add_child(palm)

	# Harbor cranes & containers near docks
	var crane = MeshBuilder.build_harbor_crane(26.0)
	crane.position = Vector3(-65, 0, 30)
	props_container.add_child(crane)

	var container_positions = [
		Vector3(-55, 0, 15), Vector3(-55, 0, 25), Vector3(-65, 0, -15)
	]
	for c_pos in container_positions:
		var cont = MeshBuilder.build_shipping_container("container_blue")
		cont.position = c_pos
		props_container.add_child(cont)
