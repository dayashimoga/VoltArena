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
	env.background_mode = Environment.BG_SKY

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.48, 0.90)       # Azure ocean sky
	sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.92)   # Marine haze
	sky_mat.ground_bottom_color = Color(0.08, 0.22, 0.35) # Ocean water depth
	sky_mat.ground_horizon_color = Color(0.55, 0.72, 0.85)
	sky.sky_material = sky_mat
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.80, 0.90)
	env.fog_density = 0.0010
	world_environment.environment = env
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.rotation_degrees = Vector3(-50, 40, 0)
	sun_light.light_color = Color(1.0, 0.96, 0.88) # Warm coastal sunlight
	sun_light.light_energy = 1.5
	sun_light.shadow_enabled = true
	add_child(sun_light)

func setup_ground_plane() -> void:
	# Ocean water surface plane
	var ocean = StaticBody3D.new()
	ocean.name = "OceanSurface"
	ocean.collision_layer = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1600, 1600)
	mi.mesh = plane_mesh

	var mat_water = StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.08, 0.28, 0.48)
	mat_water.metallic = 0.85
	mat_water.roughness = 0.12
	mat_water.clearcoat_enabled = true
	mat_water.clearcoat = 1.0
	mi.material_override = mat_water
	mi.position = Vector3(0, -1.5, 0)
	ocean.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1600, 1.0, 1600)
	col.shape = shape
	col.position = Vector3(0, -2.0, 0)
	ocean.add_child(col)

	props_container.add_child(ocean)

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

	# Orient player spawn strictly facing down the promenade (towards waypoints[1])
	var p0 = waypoints[0]
	var p1 = waypoints[1]
	var fwd = (p1 - p0).normalized()
	player_spawn_transform = Transform3D().looking_at(fwd, Vector3.UP)
	player_spawn_transform.origin = p0 + Vector3(0.0, 0.20, 0.0)

	traffic_spawn_data = [
		{"waypoint_idx": 1, "color": ChromaConstants.ChromaColor.CRIMSON, "speed": 24.0},
		{"waypoint_idx": 4, "color": ChromaConstants.ChromaColor.COBALT, "speed": 22.0},
		{"waypoint_idx": 8, "color": ChromaConstants.ChromaColor.SOLAR, "speed": 21.0},
		{"waypoint_idx": 11, "color": ChromaConstants.ChromaColor.EMERALD, "speed": 25.0},
		{"waypoint_idx": 14, "color": ChromaConstants.ChromaColor.CYAN, "speed": 23.0}
	]

func build_road_mesh() -> void:
	var road_w = 14.0
	build_continuous_road_network(waypoints, road_w)

func build_checkpoints() -> void:
	checkpoints.clear()
	var gate_defs = [
		{"id": "gate_1", "wp_idx": 2, "color": ChromaConstants.ChromaColor.CRIMSON},
		{"id": "gate_2", "wp_idx": 4, "color": ChromaConstants.ChromaColor.COBALT},
		{"id": "gate_3", "wp_idx": 7, "color": ChromaConstants.ChromaColor.SOLAR},
		{"id": "gate_4", "wp_idx": 9, "color": ChromaConstants.ChromaColor.EMERALD},
		{"id": "gate_5", "wp_idx": 11, "color": ChromaConstants.ChromaColor.MAGENTA},
		{"id": "gate_6", "wp_idx": 13, "color": ChromaConstants.ChromaColor.CYAN}
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
	# Suspension Bridge Towers along the ocean bridge span (strictly aligned to road heading and outside lanes)
	var wp3 = waypoints[3]
	var dir3 = (waypoints[4] - waypoints[3]).normalized()
	_build_bridge_tower(wp3, dir3)

	var wp4 = waypoints[4]
	var dir4 = (waypoints[5] - waypoints[4]).normalized()
	_build_bridge_tower(wp4, dir4)

	var wp5 = waypoints[5]
	var dir5 = (waypoints[6] - waypoints[5]).normalized()
	_build_bridge_tower(wp5, dir5)

	# Lighthouse on the bluff at waypoint 8
	_build_lighthouse(Vector3(285, 10, 45))

	# Seaside Promenade & Village Buildings (Waypoints 9, 10, 11)
	var village_spots = [
		{"pos": Vector3(230, 8, 110), "rot": 45.0, "type": "a"},
		{"pos": Vector3(180, 7, 125), "rot": 10.0, "type": "b"},
		{"pos": Vector3(140, 5, 140), "rot": 0.0, "type": "c"},
		{"pos": Vector3(110, 4, 130), "rot": -25.0, "type": "d"},
		{"pos": Vector3(60, 2, 125), "rot": -40.0, "type": "e"},
		{"pos": Vector3(-20, 0, 80), "rot": 60.0, "type": "f"}
	]
	for spot in village_spots:
		var bld = _build_coastal_building(spot["type"])
		bld.position = spot["pos"]
		bld.rotation_degrees = Vector3(0, spot["rot"], 0)
		props_container.add_child(bld)

	# Palm trees along the promenade and coastal road
	var palm_positions = [
		Vector3(15, 0, -40), Vector3(45, 0, -110), Vector3(70, 0, -135),
		Vector3(160, 6, 120), Vector3(125, 4, 118), Vector3(90, 3, 112),
		Vector3(40, 1, 90), Vector3(-10, 0, 65), Vector3(-45, 0, 25)
	]
	for pos in palm_positions:
		var palm = _build_palm_tree()
		palm.position = pos
		props_container.add_child(palm)

func _build_coastal_building(variant: String) -> Node3D:
	var path = "res://assets/models/environment/building_comm_%s.glb" % variant
	var model = ModelCache.get_model(path)
	var root = StaticBody3D.new()
	root.name = "CoastalBuilding"
	root.collision_layer = GameConstants.LAYER_WORLD

	if model:
		model.scale = Vector3(4.0, 4.0, 4.0)
		root.add_child(model)
	else:
		var mi = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(12.0, 8.0, 10.0)
		mi.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.92, 0.88, 0.82)
		mat.roughness = 0.75
		mi.material_override = mat
		mi.position = Vector3(0, 4.0, 0)
		root.add_child(mi)

	var col = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(14.0, 10.0, 12.0)
	col.shape = b_shape
	col.position = Vector3(0, 5.0, 0)
	root.add_child(col)

	return root

func _build_palm_tree() -> Node3D:
	var root = StaticBody3D.new()
	root.name = "PalmTree"
	root.collision_layer = GameConstants.LAYER_WORLD

	var col = CollisionShape3D.new()
	var c_shape = CylinderShape3D.new()
	c_shape.height = 6.0
	c_shape.radius = 0.40
	col.shape = c_shape
	col.position = Vector3(0, 3.0, 0)
	root.add_child(col)

	var model = ModelCache.get_model("res://assets/models/environment/tree_palm.glb")
	if model:
		model.scale = Vector3(4.8, 4.8, 4.8)
		root.add_child(model)
		return root

	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.35
	cyl.height = 6.0
	trunk.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.30, 0.20)
	trunk.material_override = mat
	trunk.position = Vector3(0, 3.0, 0)
	root.add_child(trunk)
	return root

func _build_bridge_tower(pos: Vector3, dir: Vector3 = Vector3.ZERO) -> void:
	var tower = StaticBody3D.new()
	tower.name = "SuspensionBridgeTower"
	tower.collision_layer = GameConstants.LAYER_WORLD

	var mat_cable = StandardMaterial3D.new()
	mat_cable.albedo_color = Color(0.88, 0.25, 0.20) # Red suspension bridge tower
	mat_cable.metallic = 0.80
	mat_cable.roughness = 0.35

	# Pylons strictly outside roadway (+/-12.0m from centerline; road half-width is 8.85m)
	for side in [-12.0, 12.0]:
		var pylon = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.8
		cyl.bottom_radius = 1.2
		cyl.height = 32.0
		pylon.mesh = cyl
		pylon.material_override = mat_cable
		pylon.position = Vector3(side, 14.0, 0.0)
		tower.add_child(pylon)

		var col = CollisionShape3D.new()
		var col_shape = CylinderShape3D.new()
		col_shape.height = 32.0
		col_shape.radius = 1.2
		col.shape = col_shape
		col.position = Vector3(side, 14.0, 0.0)
		tower.add_child(col)

	# Overhead Crossbeam
	var beam = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(26.0, 1.8, 2.2)
	beam.mesh = box
	beam.material_override = mat_cable
	beam.position = Vector3(0.0, 26.0, 0.0)
	tower.add_child(beam)

	tower.position = pos
	if dir.length_squared() > 0.001:
		tower.look_at_from_position(pos, pos + dir, Vector3.UP)
	props_container.add_child(tower)


func _build_lighthouse(pos: Vector3) -> void:
	var root = Node3D.new()
	var mat_stone = StandardMaterial3D.new()
	mat_stone.albedo_color = Color(0.92, 0.90, 0.88)
	mat_stone.roughness = 0.8

	var tower = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 3.8
	cyl.height = 24.0
	tower.mesh = cyl
	tower.material_override = mat_stone
	tower.position = Vector3(0, 12.0, 0)
	root.add_child(tower)

	# Lantern Room Glass & Beacon
	var lantern = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 2.4
	l_cyl.bottom_radius = 2.4
	l_cyl.height = 4.0
	lantern.mesh = l_cyl
	var mat_beacon = StandardMaterial3D.new()
	mat_beacon.albedo_color = Color(1.0, 0.95, 0.70)
	mat_beacon.emission_enabled = true
	mat_beacon.emission = Color(1.0, 0.92, 0.60)
	mat_beacon.emission_energy_multiplier = 4.0
	lantern.material_override = mat_beacon
	lantern.position = Vector3(0, 25.0, 0)
	root.add_child(lantern)

	root.position = pos
	props_container.add_child(root)
