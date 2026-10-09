class_name AeroWorldForest
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Wild Forest: Dense Realistic Wilderness Stunt Environment.
## Towering deciduous & pine canopies, winding river gorges, mossy granite boulders,
## rich green terrain blending, and atmospheric sun shafts.

const FOREST_GROUND_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float noise = sin(world_pos.x * 0.08) * cos(world_pos.y * 0.08);
	vec3 grass_dark = vec3(0.12, 0.28, 0.14);
	vec3 grass_light = vec3(0.20, 0.42, 0.18);
	vec3 dirt_col = vec3(0.28, 0.22, 0.16);

	vec3 terrain = mix(grass_dark, grass_light, noise * 0.5 + 0.5);
	float dirt_mask = step(0.68, sin(world_pos.x * 0.03 + world_pos.y * 0.04));
	ALBEDO = mix(terrain, dirt_col, dirt_mask * 0.4);
	ROUGHNESS = 0.88;
	METALLIC = 0.02;
}
"""

func build_environment() -> void:
	# 1. Warm Dappled Forest Sunlight with Emerald Sky Dome
	setup_lighting(
		Color(1.0, 0.92, 0.78),                  # Warm Dappled Sun
		2.4,                                     # Energy
		Vector3(-36.0, 48.0, 0.0),               # Sun Angle
		Color(0.14, 0.38, 0.62),                 # Sky Top (Clear Sky)
		Color(0.68, 0.82, 0.60),                 # Sky Horizon (Forest Haze)
		Color(0.62, 0.76, 0.58),                 # Foliage Mist Fog
		0.0013                                   # Fog Density
	)

	# 2. Natural Grass / Dirt Terrain Bed
	var forest_mat = ShaderMaterial.new()
	var s_sh = Shader.new()
	s_sh.code = FOREST_GROUND_SHADER
	forest_mat.shader = s_sh
	create_ground_bed(1600.0, forest_mat, -3.5)

	# 3. Winding River Water Basin
	_build_forest_river()

	# 4. Granite Boulders and Ridge Formations
	_build_granite_cliffs()

	# 5. Dense Realistic Forest Canopies
	_build_dense_forest()

func _build_forest_river() -> void:
	var river_mesh = MeshInstance3D.new()
	river_mesh.name = "ForestRiverWater"
	var plane = PlaneMesh.new()
	plane.size = Vector2(180.0, 1300.0)
	river_mesh.mesh = plane

	var river_mat = StandardMaterial3D.new()
	river_mat.albedo_color = Color(0.08, 0.28, 0.32, 0.90)
	river_mat.roughness = 0.08
	river_mat.metallic = 0.55
	river_mat.specular = 0.90
	river_mesh.material_override = river_mat
	river_mesh.position = Vector3(120.0, -3.3, 0.0)
	add_child(river_mesh)

func _build_granite_cliffs() -> void:
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.32, 0.34, 0.30)
	rock_mat.roughness = 0.92

	var rock_coords = [
		Vector3(-120, -3.5, -90), Vector3(-170, -3.5, -230),
		Vector3(-140, -3.5, -380), Vector3(190, -3.5, -160),
		Vector3(210, -3.5, -320), Vector3(170, -3.5, 70),
		Vector3(-190, -3.5, 110)
	]

	for r_pos in rock_coords:
		var rock = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(randf_range(28.0, 52.0), randf_range(30.0, 65.0), randf_range(35.0, 65.0))
		rock.mesh = box
		rock.material_override = rock_mat
		rock.position = Vector3(r_pos.x, box.size.y * 0.5 - 3.5, r_pos.z)
		rock.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
		add_child(rock)

func _build_dense_forest() -> void:
	var tree_models = [
		"res://assets/models/environment/tree_oak.glb",
		"res://assets/models/environment/tree_detailed.glb",
		"res://assets/models/environment/tree_tall.glb",
		"res://assets/models/environment/tree_pine.glb"
	]

	for t in range(65):
		var ang = randf() * TAU
		var rad = randf_range(40.0, 340.0)
		var t_pos = Vector3(cos(ang) * rad, -3.5, sin(ang) * rad)
		var t_path = tree_models[t % tree_models.size()]
		spawn_tree(t_path, t_pos, Vector2(1.3, 2.4))
