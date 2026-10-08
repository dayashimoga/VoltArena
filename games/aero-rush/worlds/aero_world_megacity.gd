class_name AeroWorldMegacity
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Neo-Cascade Metropolis: Authoritative Stunt-Racing Megacity Environment.
## Replaces prototype geometry with high-speed arcade racing spectacle:
## - Radiant golden-hour / cyberpunk dusk sky and warm directional sunlight
## - Elevated stunt highway suspended above an illuminated urban basin
## - Covered racing grandstands, floodlight towers, and high-visibility digital billboards
## - Authored skyscraper complexes and commercial plazas at realistic proportions
## - Overhead transit sky-bridges spanning above the circuit
## - 360-degree layered perimeter skyline guaranteeing depth and scale cues from every angle.

const URBAN_GROUND_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 grid80 = fract(world_pos / 80.0);
	vec2 grid20 = fract(world_pos / 20.0);

	bool is_arterial = (grid80.x < 0.12 || grid80.y < 0.12);
	bool is_street = (grid20.x < 0.14 || grid20.y < 0.14);
	bool is_centerline = (abs(grid80.x - 0.06) < 0.008 || abs(grid80.y - 0.06) < 0.008);

	if (is_centerline && is_arterial) {
		ALBEDO = vec3(1.0, 0.85, 0.2);
		EMISSION = vec3(1.0, 0.85, 0.2) * 1.5;
		ROUGHNESS = 0.3;
		METALLIC = 0.2;
	} else if (is_arterial) {
		ALBEDO = vec3(0.08, 0.09, 0.11);
		ROUGHNESS = 0.55;
		METALLIC = 0.15;
	} else if (is_street) {
		ALBEDO = vec3(0.12, 0.13, 0.15);
		ROUGHNESS = 0.65;
		METALLIC = 0.1;
	} else {
		vec2 block_uv = floor(world_pos / 20.0);
		float block_hash = fract(sin(dot(block_uv, vec2(12.9898, 78.233))) * 43758.5453);
		vec3 block_tone = mix(vec3(0.16, 0.18, 0.21), vec3(0.20, 0.22, 0.26), block_hash);
		vec2 micro_uv = fract(world_pos / 2.5);
		bool is_light_node = (block_hash > 0.65 && micro_uv.x < 0.12 && micro_uv.y < 0.12);

		if (is_light_node) {
			ALBEDO = vec3(0.1, 0.7, 1.0);
			EMISSION = vec3(0.1, 0.7, 1.0) * 1.2;
		} else {
			ALBEDO = block_tone;
		}
		ROUGHNESS = 0.75;
		METALLIC = 0.25;
	}
}
"""

func build_environment() -> void:
	# 1. Atmospheric Golden Dusk / Cyberpunk Twilight Lighting
	setup_lighting(
		Color(1.0, 0.88, 0.74),                  # Warm Golden Sun Key Light
		2.4,                                     # Sunlight Energy
		Vector3(-28.0, 48.0, 0.0),               # Cinematic 3D Shadow Cast Angle
		Color(0.06, 0.12, 0.32),                 # Sky Top (Sapphire Twilight)
		Color(0.96, 0.54, 0.28),                 # Sky Horizon (Radiant Amber Sunset)
		Color(0.46, 0.38, 0.45),                 # Volumetric Atmospheric Haze
		0.0012                                   # Fog Density (Clear Visibility + Distance Depth)
	)

	# 2. Elevated Urban Basin Ground Bed with Multi-Tier Street Grid Shader
	var ground_mat = ShaderMaterial.new()
	var g_shader = Shader.new()
	g_shader.code = URBAN_GROUND_SHADER
	ground_mat.shader = g_shader
	create_ground_bed(1800.0, ground_mat, -6.5)

	# 3. Urban Canal / Reflecting River Basin
	_build_urban_waterway()

	# 4. Racing Stadium Sector (Near Ground: Grandstands & Floodlights along Main Straight)
	_build_stadium_starting_sector()

	# 5. Authored Skyscraper City Blocks (Mid Ground: Proportional 50m - 140m towers)
	_build_flanking_skyscrapers()

	# 6. Overhead Transit Sky-Bridges Spanning the Circuit
	_build_overhead_skybridges()

	# 7. Street Infrastructure and Foliage in Plazas
	_build_street_amenities()

	# 8. 360-Degree Continuous Layered Perimeter Skyline
	_build_perimeter_skyline()

func _build_urban_waterway() -> void:
	var water_mesh = MeshInstance3D.new()
	water_mesh.name = "UrbanCanalReflectingWater"
	var plane = PlaneMesh.new()
	plane.size = Vector2(160.0, 1400.0)
	water_mesh.mesh = plane

	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.05, 0.14, 0.24)
	water_mat.roughness = 0.08
	water_mat.metallic = 0.85
	water_mesh.material_override = water_mat
	water_mesh.position = Vector3(160.0, -6.35, 0.0)
	add_child(water_mesh)

func _build_stadium_starting_sector() -> void:
	var grandstand_path = "res://assets/models/environment/stadium/grandstand_covered.glb"
	var floodlight_path = "res://assets/models/environment/stadium/floodlight_tower.glb"
	var billboard_path = "res://assets/models/environment/stadium/billboard.glb"
	var barrier_red = "res://assets/models/environment/racing/barrier_red.glb"
	var barrier_white = "res://assets/models/environment/racing/barrier_white.glb"

	# Covered Grandstands flanking the starting boulevard
	var gs_positions = [
		{"pos": Vector3(-24.0, 0.0, -35.0), "rot": 90.0},
		{"pos": Vector3(-24.0, 0.0, 15.0), "rot": 90.0},
		{"pos": Vector3(-24.0, 0.0, 65.0), "rot": 90.0},
		{"pos": Vector3(24.0, 0.0, -35.0), "rot": -90.0},
		{"pos": Vector3(24.0, 0.0, 15.0), "rot": -90.0},
		{"pos": Vector3(24.0, 0.0, 65.0), "rot": -90.0}
	]
	for g in gs_positions:
		spawn_building(grandstand_path, g["pos"], g["rot"], Vector3(2.2, 2.2, 2.2))

	# High Stadium Floodlight Towers
	var fl_positions = [
		Vector3(-32.0, 0.0, -50.0),
		Vector3(-32.0, 0.0, 90.0),
		Vector3(32.0, 0.0, -50.0),
		Vector3(32.0, 0.0, 90.0),
		Vector3(-55.0, 0.0, -170.0),
		Vector3(55.0, 0.0, -170.0)
	]
	for fl_pos in fl_positions:
		spawn_building(floodlight_path, fl_pos, 0.0, Vector3(2.4, 2.4, 2.4))

	# High-Speed Racing Billboards on the start and approach corners
	var bb_positions = [
		{"pos": Vector3(-26.0, 3.5, 110.0), "rot": 35.0},
		{"pos": Vector3(26.0, 3.5, 110.0), "rot": -35.0},
		{"pos": Vector3(0.0, 8.5, -95.0), "rot": 180.0}
	]
	for b in bb_positions:
		spawn_building(billboard_path, b["pos"], b["rot"], Vector3(2.0, 2.0, 2.0))

	# Safety Racing Barriers along ground boulevard shoulders
	for z_pos in range(-60, 80, 10):
		var b_path = barrier_red if ((z_pos / 10) % 2 == 0) else barrier_white
		spawn_building(b_path, Vector3(-16.5, 0.0, float(z_pos)), 0.0, Vector3(1.8, 1.8, 1.8))
		spawn_building(b_path, Vector3(16.5, 0.0, float(z_pos)), 180.0, Vector3(1.8, 1.8, 1.8))

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

	# Realistic boulevard towers flanking track (proportional scale: 2.5x to 3.8x uniform scale)
	var tower_coords = [
		# West side city blocks
		Vector3(-55.0, -6.5, -70.0), Vector3(-68.0, -6.5, -15.0),
		Vector3(-58.0, -6.5, 45.0), Vector3(-75.0, -6.5, 110.0),
		Vector3(-95.0, -6.5, -150.0), Vector3(-110.0, -6.5, -230.0),
		Vector3(-75.0, -6.5, -310.0), Vector3(-120.0, -6.5, 30.0),
		Vector3(-60.0, -6.5, -190.0), Vector3(-85.0, -6.5, -270.0),
		Vector3(-105.0, -6.5, -360.0), Vector3(-65.0, -6.5, -410.0),
		Vector3(-135.0, -6.5, -90.0), Vector3(-140.0, -6.5, -200.0),
		# East side city blocks
		Vector3(55.0, -6.5, -70.0), Vector3(68.0, -6.5, -15.0),
		Vector3(58.0, -6.5, 45.0), Vector3(75.0, -6.5, 110.0),
		Vector3(95.0, -6.5, -150.0), Vector3(110.0, -6.5, -230.0),
		Vector3(75.0, -6.5, -310.0), Vector3(120.0, -6.5, 30.0),
		Vector3(60.0, -6.5, -190.0), Vector3(135.0, -6.5, -270.0),
		Vector3(145.0, -6.5, -360.0), Vector3(85.0, -6.5, -430.0),
		Vector3(135.0, -6.5, -90.0), Vector3(150.0, -6.5, -200.0)
	]

	for i in range(tower_coords.size()):
		var pos = tower_coords[i]
		var model = skyscraper_models[i % skyscraper_models.size()]
		var uniform_scale = randf_range(2.6, 3.8)
		# Proportional scaling preserves window, door, and floor proportions
		spawn_building(model, pos, float((i * 90) % 360), Vector3(uniform_scale, uniform_scale, uniform_scale))

	# Secondary Commercial Plazas and Mid-Tier Complexes
	var comm_coords = [
		Vector3(-90.0, -6.5, -60.0), Vector3(90.0, -6.5, -60.0),
		Vector3(-105.0, -6.5, 80.0), Vector3(105.0, -6.5, 80.0),
		Vector3(-45.0, -6.5, -220.0), Vector3(45.0, -6.5, -220.0),
		Vector3(-80.0, -6.5, -280.0), Vector3(80.0, -6.5, -280.0),
		Vector3(-45.0, -6.5, -350.0), Vector3(45.0, -6.5, -350.0),
		Vector3(-35.0, -6.5, -120.0), Vector3(35.0, -6.5, -120.0),
		Vector3(-115.0, -6.5, -20.0), Vector3(115.0, -6.5, -20.0)
	]
	for j in range(comm_coords.size()):
		var c_pos = comm_coords[j]
		var c_model = comm_models[j % comm_models.size()]
		var c_scale = randf_range(2.2, 3.2)
		spawn_building(c_model, c_pos, float((j * 90) % 360), Vector3(c_scale, c_scale, c_scale))

func _build_overhead_skybridges() -> void:
	# Skybridges crossing the circuit at altitude between skyscraper clusters
	var bridge_z_coords = [-130.0, 70.0, -280.0]
	for z in bridge_z_coords:
		var bridge = MeshInstance3D.new()
		bridge.name = "TransMetropolitanSkybridge_Z%d" % int(z)
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(140.0, 4.5, 8.0)
		bridge.mesh = b_mesh

		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.14, 0.16, 0.20)
		b_mat.metallic = 0.85
		b_mat.roughness = 0.30
		bridge.material_override = b_mat
		bridge.position = Vector3(0.0, 24.0, z)
		add_child(bridge)

		# Neon Transit Window Stripe across Skybridge
		var win = MeshInstance3D.new()
		var w_mesh = BoxMesh.new()
		w_mesh.size = Vector3(140.0, 1.2, 8.2)
		win.mesh = w_mesh
		var win_mat = StandardMaterial3D.new()
		win_mat.albedo_color = Color(0.08, 0.90, 1.0)
		win_mat.emission_enabled = true
		win_mat.emission = Color(0.08, 0.90, 1.0) * 2.8
		win.material_override = win_mat
		win.position = Vector3(0.0, 24.0, z)
		add_child(win)

func _build_street_amenities() -> void:
	var lightpost_path = "res://assets/models/environment/road_lightposts.glb"
	var palm_path = "res://assets/models/environment/tree_palm.glb"
	var oak_path = "res://assets/models/environment/tree_oak.glb"

	# Street Lightposts along urban basin roads
	for z_coord in range(-120, 140, 35):
		for x_side in [-38.0, 38.0]:
			spawn_building(lightpost_path, Vector3(x_side, -6.5, float(z_coord)), 90.0 if x_side < 0 else -90.0, Vector3(2.0, 2.0, 2.0))

	# Landscaped Plaza Palms & Trees around commercial plazas
	var tree_plazas = [
		Vector3(-42.0, -6.5, -45.0), Vector3(42.0, -6.5, -45.0),
		Vector3(-42.0, -6.5, 30.0), Vector3(42.0, -6.5, 30.0),
		Vector3(-70.0, -6.5, 95.0), Vector3(70.0, -6.5, 95.0)
	]
	for t_pos in tree_plazas:
		spawn_tree(palm_path, t_pos, Vector2(1.2, 1.6))
		spawn_tree(oak_path, t_pos + Vector3(6.0, 0, 6.0), Vector2(1.0, 1.4))

func _build_perimeter_skyline() -> void:
	# 360-degree monumental skyline silhouette instanced from real skyscraper models
	var skyscraper_models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var tower_count = 20
	var radius = 340.0

	for i in range(tower_count):
		var angle = (float(i) / float(tower_count)) * TAU
		var x = cos(angle) * (radius + randf_range(-30.0, 45.0))
		var z = sin(angle) * (radius + randf_range(-30.0, 45.0))
		var model = skyscraper_models[i % skyscraper_models.size()]
		var scale_val = randf_range(4.5, 6.5)

		var bld = spawn_building(model, Vector3(x, -6.5, z), float((i * 47) % 360), Vector3(scale_val, scale_val, scale_val))
		if bld:
			# Rooftop Aviation Beacon Light
			var beacon = MeshInstance3D.new()
			var b_sphere = SphereMesh.new()
			b_sphere.radius = 1.4
			b_sphere.height = 2.8
			beacon.mesh = b_sphere
			var b_mat = StandardMaterial3D.new()
			var b_col = Color(1.0, 0.20, 0.15) if (i % 2 == 0) else Color(0.05, 0.85, 1.0)
			b_mat.albedo_color = b_col
			b_mat.emission_enabled = true
			b_mat.emission = b_col * 3.5
			beacon.material_override = b_mat
			beacon.position = Vector3(0, 45.0, 0)
			bld.add_child(beacon)
