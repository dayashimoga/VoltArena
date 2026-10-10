class_name AeroWorldSkyline
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Skyline Rush: Modern Daylight / Golden Hour Architectural Metropolis.
## Varied commercial towers, realistic skyscraper canyons, multi-tier urban road grids,
## rooftop launch decks, and clean horizon composition without miniature toy buildings.

const SKYLINE_GROUND_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 grid = fract(world_pos / 60.0);
	bool is_road = (grid.x < 0.14 || grid.y < 0.14);
	bool is_line = (abs(grid.x - 0.07) < 0.008 || abs(grid.y - 0.07) < 0.008);

	if (is_line && is_road) {
		ALBEDO = vec3(0.96, 0.94, 0.90);
		ROUGHNESS = 0.45;
	} else if (is_road) {
		ALBEDO = vec3(0.18, 0.20, 0.22);
		ROUGHNESS = 0.60;
	} else {
		vec2 block = floor(world_pos / 60.0);
		float h = fract(sin(dot(block, vec2(12.9898, 78.233))) * 43758.5453);
		vec3 plaza = mix(vec3(0.24, 0.26, 0.29), vec3(0.30, 0.32, 0.35), h);
		ALBEDO = plaza;
		ROUGHNESS = 0.75;
	}
}
"""

func build_environment() -> void:
	# 1. Radiant Golden-Hour Daylight Lighting
	setup_lighting(
		Color(1.0, 0.94, 0.85),                  # Golden Sun Key Light
		2.5,                                     # Sun Energy
		Vector3(-38.0, 52.0, 0.0),               # Sun Angle
		Color(0.18, 0.45, 0.82),                 # Sky Top (Clear Azure)
		Color(0.94, 0.72, 0.48),                 # Sky Horizon (Warm Sunset Gold)
		Color(0.85, 0.75, 0.68),                 # Warm Atmospheric Haze
		0.0011                                   # Clear Distance Fog
	)

	# 2. Modern Urban Basin Ground Bed
	var g_mat = ShaderMaterial.new()
	var g_sh = Shader.new()
	g_sh.code = SKYLINE_GROUND_SHADER
	g_mat.shader = g_sh
	create_ground_bed(1800.0, g_mat, -5.0)

	# 3. Flanking Modern Skyscrapers at Authentic Proportions
	_build_modern_skyscrapers()

	# 4. Plaza Vegetation & Street Furniture
	_build_city_plazas()

func _build_modern_skyscrapers() -> void:
	var models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]

	var coords = [
		Vector3(-65.0, -5.0, -80.0), Vector3(-80.0, -5.0, -20.0),
		Vector3(-70.0, -5.0, 50.0), Vector3(-90.0, -5.0, 120.0),
		Vector3(-105.0, -5.0, -170.0), Vector3(-120.0, -5.0, -250.0),
		Vector3(-85.0, -5.0, -330.0), Vector3(-130.0, -5.0, 40.0),
		Vector3(65.0, -5.0, -80.0), Vector3(80.0, -5.0, -20.0),
		Vector3(70.0, -5.0, 50.0), Vector3(90.0, -5.0, 120.0),
		Vector3(105.0, -5.0, -170.0), Vector3(120.0, -5.0, -250.0),
		Vector3(85.0, -5.0, -330.0), Vector3(130.0, -5.0, 40.0)
	]

	for i in range(coords.size()):
		var m = models[i % models.size()]
		var scale_u = randf_range(8.0, 12.0)
		spawn_building(m, coords[i], float((i * 90) % 360), Vector3(scale_u, scale_u, scale_u))

func _build_city_plazas() -> void:
	var comm_models = [
		"res://assets/models/environment/building_comm_a.glb",
		"res://assets/models/environment/building_comm_b.glb",
		"res://assets/models/environment/building_comm_c.glb"
	]
	var comm_coords = [
		Vector3(-55.0, -5.0, -130.0), Vector3(55.0, -5.0, -130.0),
		Vector3(-60.0, -5.0, -290.0), Vector3(60.0, -5.0, -290.0),
		Vector3(-58.0, -5.0, 90.0), Vector3(58.0, -5.0, 90.0)
	]
	for j in range(comm_coords.size()):
		var c_m = comm_models[j % comm_models.size()]
		var c_s = randf_range(3.2, 4.8)
		spawn_building(c_m, comm_coords[j], float((j * 90) % 360), Vector3(c_s, c_s, c_s))

	# Plaza trees
	var palm_path = "res://assets/models/environment/tree_palm.glb"
	var oak_path = "res://assets/models/environment/tree_oak.glb"
	for k in range(-4, 5):
		var pos_l = Vector3(-38.0, -5.0, float(k * 45))
		var pos_r = Vector3(38.0, -5.0, float(k * 45))
		spawn_tree(oak_path, pos_l, Vector2(1.2, 1.8))
		spawn_tree(palm_path, pos_r, Vector2(1.2, 1.8))
