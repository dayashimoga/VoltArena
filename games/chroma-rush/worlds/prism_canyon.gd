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
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.85, 0.55, 0.35) # Warm sandstone sunset sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.70, 0.45, 0.30)
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = env
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.rotation_degrees = Vector3(-35, -50, 0)
	sun_light.light_color = Color(1.0, 0.85, 0.65)
	sun_light.light_energy = 1.5
	sun_light.shadow_enabled = true
	add_child(sun_light)

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

	player_spawn_transform = Transform3D(Basis(), Vector3(0, 0.4, 0))

	traffic_spawn_data = [
		{"waypoint_idx": 1, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 22.0},
		{"waypoint_idx": 4, "color": ChromaConstants.ChromaColor.CRIMSON, "speed": 25.0},
		{"waypoint_idx": 7, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 21.0},
		{"waypoint_idx": 10, "color": ChromaConstants.ChromaColor.COBALT, "speed": 23.0},
		{"waypoint_idx": 13, "color": ChromaConstants.ChromaColor.MAGENTA, "speed": 20.0}
	]

func build_road_mesh() -> void:
	for i in range(waypoints.size()):
		var p1 = waypoints[i]
		var p2 = waypoints[(i + 1) % waypoints.size()]
		add_road_segment(p1, p2, 13.0)

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

		gate.position = wp
		if dir.length_squared() > 0.001:
			gate.look_at_from_position(wp, wp + dir, Vector3.UP)

		gates_container.add_child(gate)
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
		var mi = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = randf_range(12.0, 20.0)
		cyl.bottom_radius = cyl.top_radius + 4.0
		cyl.height = randf_range(25.0, 45.0)
		mi.mesh = cyl
		mi.material_override = rock_mat
		mi.position = pos
		props_container.add_child(mi)
