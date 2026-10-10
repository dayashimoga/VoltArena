class_name SkyCircuit
extends "res://games/chroma-rush/worlds/world_base.gd"

## World 4: Sky Circuit
## Elevated multilevel skyway suspended high above the clouds,
## high-speed banked curves, corkscrew ramps, and multi-tier energy tracks.

func _init() -> void:
	world_id = ChromaConstants.WORLD_SKY_CIRCUIT
	world_name = "Sky Circuit"

func setup_lighting() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12, 0.16, 0.36)       # Twilight upper stratosphere
	sky_mat.sky_horizon_color = Color(0.48, 0.42, 0.65)   # Glowing lavender twilight horizon
	sky_mat.ground_bottom_color = Color(0.18, 0.20, 0.30) # Soft cloud shadow floor
	sky_mat.ground_horizon_color = Color(0.45, 0.40, 0.58)
	sky_mat.sun_angle_max = 20.0
	sky.sky_material = sky_mat
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.15
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_light_color = Color(0.38, 0.36, 0.52)
	env.fog_density = 0.0010
	world_environment.environment = env
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.rotation_degrees = Vector3(-55, 30, 0)
	sun_light.light_color = Color(0.92, 0.94, 1.0)
	sun_light.light_energy = 1.4
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.03
	add_child(sun_light)

func setup_ground_plane() -> void:
	# Vast cloud deck plane beneath the elevated skyway
	var cloud_deck = StaticBody3D.new()
	cloud_deck.name = "CloudDeckPlane"
	cloud_deck.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(2000, 2000)
	mi.mesh = plane_mesh

	var mat_clouds = StandardMaterial3D.new()
	mat_clouds.albedo_color = Color(0.80, 0.82, 0.90) # Volumetric-like silver-white cloud tops
	mat_clouds.roughness = 0.98
	mat_clouds.metallic = 0.0
	mi.material_override = mat_clouds
	cloud_deck.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2000, 2.0, 2000)
	col.shape = shape
	col.position = Vector3(0, -1.0, 0)
	cloud_deck.add_child(col)

	cloud_deck.position = Vector3(0, 5.0, 0) # Cloud tops beneath elevated road
	props_container.add_child(cloud_deck)

func generate_waypoints() -> void:
	waypoints.clear()
	# 16-point floating sky highway with multi-tier overpass
	var raw_points = [
		Vector3(0, 50, 0),         # 0 Cloud Platform Grid
		Vector3(0, 50, -90),       # 1 Zenith Straight
		Vector3(30, 54, -180),     # 2 Incline to High Ribbon
		Vector3(90, 62, -230),     # 3 High Banked Curve
		Vector3(170, 68, -210),    # 4 Apex Overlook (Tier 3)
		Vector3(230, 65, -150),    # 5 Spiral Ramp Descent
		Vector3(250, 58, -70),     # 6 Mid Stratum Curve
		Vector3(230, 50, 20),      # 7 Cloud Chasm Bridge
		Vector3(180, 44, 100),     # 8 Corkscrew Down to Tier 1
		Vector3(110, 40, 140),     # 9 Lower Ribbon Speed Zone
		Vector3(30, 40, 130),      # 10 Energy Conduit Tunnel
		Vector3(-50, 42, 100),     # 11 Under-tier Crossing
		Vector3(-110, 46, 50),     # 12 West Bank Ascent
		Vector3(-130, 50, -20),    # 13 Stratosphere Ridge
		Vector3(-100, 50, -80),    # 14 High Velocity S-Curve
		Vector3(-40, 50, -30)      # 15 Final Approach to Grid
	]
	for p in raw_points:
		waypoints.append(p)

	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var forward = (p1 - p0).normalized()
	player_spawn_transform = Transform3D().looking_at(forward, Vector3.UP)
	player_spawn_transform.origin = p0 + Vector3(0, 0.20, 0)

	traffic_spawn_data = [
		{"waypoint_idx": 2, "color": ChromaConstants.ChromaColor.CYAN, "speed": 26.0},
		{"waypoint_idx": 5, "color": ChromaConstants.ChromaColor.MAGENTA, "speed": 24.0},
		{"waypoint_idx": 8, "color": ChromaConstants.ChromaColor.CRIMSON, "speed": 27.0},
		{"waypoint_idx": 11, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 25.0},
		{"waypoint_idx": 14, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 28.0}
	]

func build_road_mesh() -> void:
	var road_w = 15.0
	build_continuous_road_network(waypoints, road_w)

func build_checkpoints() -> void:
	checkpoints.clear()
	var gate_defs = [
		{"id": "gate_1", "wp_idx": 1, "color": ChromaConstants.ChromaColor.CYAN},
		{"id": "gate_2", "wp_idx": 4, "color": ChromaConstants.ChromaColor.MAGENTA},
		{"id": "gate_3", "wp_idx": 6, "color": ChromaConstants.ChromaColor.SOLAR},
		{"id": "gate_4", "wp_idx": 8, "color": ChromaConstants.ChromaColor.COBALT},
		{"id": "gate_5", "wp_idx": 10, "color": ChromaConstants.ChromaColor.EMERALD},
		{"id": "gate_6", "wp_idx": 13, "color": ChromaConstants.ChromaColor.CRIMSON}
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
	# Holographic race gantries across the skyway
	var gantry1 = MeshBuilder.build_start_gantry(15.0)
	gantry1.position = Vector3(0, 50.0, 0)
	props_container.add_child(gantry1)

	var gantry2 = MeshBuilder.build_race_gantry_mesh()
	gantry2.position = Vector3(170, 68.0, -210)
	props_container.add_child(gantry2)

	# Massive support pylons anchoring the floating circuit into the clouds below (strictly clamped beneath road underside)
	var pylon_anchors = [
		{"xz": Vector2(0, -90), "road_y": 50.0},
		{"xz": Vector2(90, -230), "road_y": 62.0},
		{"xz": Vector2(250, -70), "road_y": 58.0},
		{"xz": Vector2(110, 140), "road_y": 40.0},
		{"xz": Vector2(-110, 50), "road_y": 46.0}
	]
	var pylon_mat = StandardMaterial3D.new()
	pylon_mat.albedo_color = Color(0.18, 0.20, 0.28)
	pylon_mat.metallic = 0.9

	for anchor in pylon_anchors:
		var xz: Vector2 = anchor["xz"]
		var road_y: float = anchor["road_y"]
		var underside_y = road_y - 0.50
		var cloud_y = 5.0
		var pier_h = maxf(10.0, underside_y - cloud_y)
		var center_y = cloud_y + pier_h * 0.5

		var pier = StaticBody3D.new()
		pier.name = "SkySupportPier"
		pier.collision_layer = GameConstants.LAYER_WORLD

		var mi = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 4.0
		p_mesh.bottom_radius = 7.0
		p_mesh.height = pier_h
		mi.mesh = p_mesh
		mi.material_override = pylon_mat
		pier.add_child(mi)

		var col = CollisionShape3D.new()
		var c_shape = CylinderShape3D.new()
		c_shape.radius = 5.0
		c_shape.height = pier_h
		col.shape = c_shape
		pier.add_child(col)

		pier.position = Vector3(xz.x, center_y, xz.y)
		props_container.add_child(pier)

	# High-altitude mega-skyscrapers rising from the clouds
	var tower_spots = [
		{"pos": Vector3(80, -10, -80), "type": "a"},
		{"pos": Vector3(-80, -15, -120), "type": "b"},
		{"pos": Vector3(160, -20, 50), "type": "c"},
		{"pos": Vector3(-140, -10, 120), "type": "d"},
		{"pos": Vector3(280, -25, -150), "type": "e"}
	]
	for spot in tower_spots:
		var tower = _build_sky_skyscraper(spot["type"])
		tower.position = spot["pos"]
		props_container.add_child(tower)

func _build_sky_skyscraper(variant: String) -> Node3D:
	var path = "res://assets/models/environment/building_skyscraper_%s.glb" % variant
	var model = ModelCache.get_model(path)
	var root = StaticBody3D.new()
	root.name = "SkySkyscraper"
	root.collision_layer = GameConstants.LAYER_WORLD

	if model:
		model.scale = Vector3(14.0, 28.0, 14.0)
		root.add_child(model)
	else:
		var mi = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(28.0, 120.0, 28.0)
		mi.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.18, 0.25)
		mat.metallic = 0.8
		mi.material_override = mat
		mi.position = Vector3(0, 60.0, 0)
		root.add_child(mi)

	var col = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(30.0, 140.0, 30.0)
	col.shape = b_shape
	col.position = Vector3(0, 70.0, 0)
	root.add_child(col)

	return root
