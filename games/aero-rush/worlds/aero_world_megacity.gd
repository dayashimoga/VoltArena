class_name AeroWorldMegacity
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Neo-Cascade Metropolis: Authoritative Stunt-Racing Megacity Environment.
## Replaces prototype geometry with high-speed arcade racing spectacle:
## - Radiant golden-hour / cyberpunk dusk sky and warm directional sunlight
## - Elevated stunt highway suspended above an illuminated urban basin
## - Covered racing grandstands, floodlight towers, and high-visibility digital billboards
## - Grand mega-skyscrapers (80m - 240m tall) with illuminated window grids
## - High-altitude transit sky-bridges spanning above the circuit
## - 360-degree perimeter skyline guaranteeing depth and scale cues from every angle.

func build_environment() -> void:
	# 1. Atmospheric Golden Dusk / Cyberpunk Twilight Lighting
	setup_lighting(
		Color(1.0, 0.88, 0.74),                  # Warm Golden Sun Key Light
		2.5,                                     # Sunlight Energy
		Vector3(-26.0, 50.0, 0.0),               # Cinematic 3D Shadow Cast Angle
		Color(0.06, 0.12, 0.30),                 # Sky Top (Sapphire Twilight)
		Color(0.94, 0.52, 0.26),                 # Sky Horizon (Radiant Amber Sunset)
		Color(0.48, 0.36, 0.44),                 # Volumetric Atmospheric Haze
		0.0010                                   # Fog Density (Clear Visibility + Distance Depth)
	)

	# 2. Elevated Urban Basin Foundation (Track is suspended 6.5m above ground)
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.13, 0.15, 0.18)
	ground_mat.roughness = 0.82
	ground_mat.metallic = 0.25
	create_ground_bed(1600.0, ground_mat, -6.5)

	# 3. Urban Canal / Reflecting River Basin
	_build_urban_waterway()

	# 4. Racing Stadium Sector (Near Ground: Grandstands & Floodlights along Main Straight)
	_build_stadium_starting_sector()

	# 5. Flanking Mega-Skyscrapers (Mid Ground: 80m - 220m tall corporate monoliths)
	_build_flanking_skyscrapers()

	# 6. Overhead Transit Sky-Bridges Spanning the Circuit
	_build_overhead_skybridges()

	# 7. 360-Degree Continuous Perimeter Skyline (Far Ground: 160m - 320m spires)
	_build_perimeter_skyline()

func _build_urban_waterway() -> void:
	var water_mesh = MeshInstance3D.new()
	water_mesh.name = "UrbanCanalReflectingWater"
	var plane = PlaneMesh.new()
	plane.size = Vector2(140.0, 1200.0)
	water_mesh.mesh = plane

	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.04, 0.12, 0.22)
	water_mat.roughness = 0.10
	water_mat.metallic = 0.80
	water_mesh.material_override = water_mat
	water_mesh.position = Vector3(180.0, -6.35, 0.0)
	add_child(water_mesh)

func _build_stadium_starting_sector() -> void:
	var grandstand_path = "res://assets/models/environment/stadium/grandstand_covered.glb"
	var floodlight_path = "res://assets/models/environment/stadium/floodlight_tower.glb"
	var billboard_path = "res://assets/models/environment/stadium/billboard.glb"

	# Covered Grandstands flanking the starting boulevard
	var gs_positions = [
		{"pos": Vector3(-26.0, 0.0, -35.0), "rot": 90.0},
		{"pos": Vector3(-26.0, 0.0, 15.0), "rot": 90.0},
		{"pos": Vector3(-26.0, 0.0, 65.0), "rot": 90.0},
		{"pos": Vector3(26.0, 0.0, -35.0), "rot": -90.0},
		{"pos": Vector3(26.0, 0.0, 15.0), "rot": -90.0},
		{"pos": Vector3(26.0, 0.0, 65.0), "rot": -90.0}
	]
	for g in gs_positions:
		spawn_building(grandstand_path, g["pos"], g["rot"], Vector3(2.4, 2.4, 2.4))

	# High Stadium Floodlight Towers
	var fl_positions = [
		Vector3(-34.0, 0.0, -50.0),
		Vector3(-34.0, 0.0, 90.0),
		Vector3(34.0, 0.0, -50.0),
		Vector3(34.0, 0.0, 90.0),
		Vector3(-65.0, 0.0, -180.0),
		Vector3(65.0, 0.0, -180.0)
	]
	for fl_pos in fl_positions:
		spawn_building(floodlight_path, fl_pos, 0.0, Vector3(2.6, 2.6, 2.6))

	# High-Speed Racing Billboards on the start and approach corners
	var bb_positions = [
		{"pos": Vector3(-28.0, 3.5, 120.0), "rot": 35.0},
		{"pos": Vector3(28.0, 3.5, 120.0), "rot": -35.0},
		{"pos": Vector3(0.0, 8.5, -95.0), "rot": 180.0}
	]
	for b in bb_positions:
		spawn_building(billboard_path, b["pos"], b["rot"], Vector3(2.0, 2.0, 2.0))

func _build_flanking_skyscrapers() -> void:
	var skyscraper_models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var comm_models = [
		"res://assets/models/environment/building_comm_a.glb",
		"res://assets/models/environment/building_comm_b.glb",
		"res://assets/models/environment/building_comm_c.glb",
		"res://assets/models/environment/building_comm_d.glb",
		"res://assets/models/environment/building_comm_e.glb",
		"res://assets/models/environment/building_comm_f.glb"
	]

	# Boulevard Towers flanking track (scaled to realistic 70m - 180m height)
	var tower_coords = [
		# Left side boulevard
		Vector3(-62.0, -6.5, -70.0), Vector3(-75.0, -6.5, -15.0),
		Vector3(-65.0, -6.5, 45.0), Vector3(-85.0, -6.5, 110.0),
		Vector3(-105.0, -6.5, -160.0), Vector3(-120.0, -6.5, -240.0),
		Vector3(-80.0, -6.5, -320.0), Vector3(-140.0, -6.5, 30.0),
		# Right side boulevard
		Vector3(62.0, -6.5, -70.0), Vector3(75.0, -6.5, -15.0),
		Vector3(65.0, -6.5, 45.0), Vector3(85.0, -6.5, 110.0),
		Vector3(105.0, -6.5, -160.0), Vector3(120.0, -6.5, -240.0),
		Vector3(80.0, -6.5, -320.0), Vector3(140.0, -6.5, 30.0)
	]

	for i in range(tower_coords.size()):
		var pos = tower_coords[i]
		var model = skyscraper_models[i % skyscraper_models.size()]
		var scale_y = randf_range(7.5, 14.0)
		var scale_xz = randf_range(3.8, 5.2)
		spawn_building(model, pos, float((i * 47) % 360), Vector3(scale_xz, scale_y, scale_xz))

	# Secondary Commercial Plazas and Mid-Tier Complexes
	var comm_coords = [
		Vector3(-110.0, -6.5, -60.0), Vector3(110.0, -6.5, -60.0),
		Vector3(-125.0, -6.5, 80.0), Vector3(125.0, -6.5, 80.0),
		Vector3(-50.0, -6.5, -220.0), Vector3(50.0, -6.5, -220.0)
	]
	for j in range(comm_coords.size()):
		var c_pos = comm_coords[j]
		var c_model = comm_models[j % comm_models.size()]
		spawn_building(c_model, c_pos, float(j * 90), Vector3(2.8, 4.2, 2.8))

	# Procedural Illuminated High-Tech Monolith Towers with Emissive Windows
	_spawn_procedural_monolith(Vector3(-105.0, -6.5, -290.0), Vector3(32.0, 160.0, 32.0), Color(0.08, 0.85, 1.0))
	_spawn_procedural_monolith(Vector3(105.0, -6.5, -290.0), Vector3(32.0, 180.0, 32.0), Color(1.0, 0.45, 0.08))
	_spawn_procedural_monolith(Vector3(0.0, -6.5, -420.0), Vector3(45.0, 210.0, 45.0), Color(0.12, 0.95, 0.55))

func _spawn_procedural_monolith(pos: Vector3, size: Vector3, accent_color: Color) -> void:
	var tower = MeshInstance3D.new()
	tower.name = "HighTechMonolithTower"
	var box = BoxMesh.new()
	box.size = size
	tower.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.12, 0.16)
	mat.roughness = 0.25
	mat.metallic = 0.85
	mat.emission_enabled = true
	mat.emission = accent_color * 0.45
	tower.material_override = mat
	tower.position = pos + Vector3(0, size.y * 0.5, 0)
	add_child(tower)

	# Spire Antenna on Roof
	var spire = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 1.2
	cyl.height = 35.0
	spire.mesh = cyl
	var spire_mat = StandardMaterial3D.new()
	spire_mat.albedo_color = accent_color
	spire_mat.emission_enabled = true
	spire_mat.emission = accent_color * 2.5
	spire.material_override = spire_mat
	spire.position = Vector3(pos.x, pos.y + size.y + 17.5, pos.z)
	add_child(spire)

func _build_overhead_skybridges() -> void:
	# Skybridges crossing the circuit at altitude
	var bridge_z_coords = [-130.0, 70.0, -280.0]
	for z in bridge_z_coords:
		var bridge = MeshInstance3D.new()
		bridge.name = "TransMetropolitanSkybridge_Z%d" % int(z)
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(140.0, 5.0, 8.5)
		bridge.mesh = b_mesh

		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.12, 0.14, 0.18)
		b_mat.metallic = 0.8
		b_mat.roughness = 0.3
		bridge.material_override = b_mat
		bridge.position = Vector3(0.0, 24.0, z)
		add_child(bridge)

		# Neon Transit Window Stripe across Skybridge
		var win = MeshInstance3D.new()
		var w_mesh = BoxMesh.new()
		w_mesh.size = Vector3(140.0, 1.2, 8.7)
		win.mesh = w_mesh
		var win_mat = StandardMaterial3D.new()
		win_mat.albedo_color = Color(0.08, 0.90, 1.0)
		win_mat.emission_enabled = true
		win_mat.emission = Color(0.08, 0.90, 1.0) * 2.8
		win.material_override = win_mat
		win.position = Vector3(0.0, 24.0, z)
		add_child(win)

func _build_perimeter_skyline() -> void:
	# 360-degree monumental skyline silhouette framing the horizon
	var tower_count = 24
	var radius = 380.0

	var tower_mat = StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.08, 0.10, 0.14)
	tower_mat.roughness = 0.35
	tower_mat.metallic = 0.70

	for i in range(tower_count):
		var angle = (float(i) / float(tower_count)) * TAU
		var x = cos(angle) * (radius + randf_range(-40.0, 60.0))
		var z = sin(angle) * (radius + randf_range(-40.0, 60.0))
		var height = randf_range(160.0, 280.0)
		var width = randf_range(30.0, 50.0)

		var tower = MeshInstance3D.new()
		tower.name = "PerimeterSkylineTower_%d" % i
		var box = BoxMesh.new()
		box.size = Vector3(width, height, width)
		tower.mesh = box
		tower.material_override = tower_mat
		tower.position = Vector3(x, -6.5 + height * 0.5, z)
		add_child(tower)

		# Rooftop Beacon Light
		var beacon = MeshInstance3D.new()
		var b_sphere = SphereMesh.new()
		b_sphere.radius = 1.8
		b_sphere.height = 3.6
		beacon.mesh = b_sphere
		var b_mat = StandardMaterial3D.new()
		var b_col = Color(1.0, 0.20, 0.15) if (i % 2 == 0) else Color(0.05, 0.85, 1.0)
		b_mat.albedo_color = b_col
		b_mat.emission_enabled = true
		b_mat.emission = b_col * 3.5
		beacon.material_override = b_mat
		beacon.position = Vector3(x, -6.5 + height + 2.0, z)
		add_child(beacon)
