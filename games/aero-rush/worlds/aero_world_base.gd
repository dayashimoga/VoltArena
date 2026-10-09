class_name AeroWorldBase
extends Node3D

## Base environment coordinator for AeroRush: Impossible Circuit.
## Manages atmospheric lighting, sky, directional sun, fog, terrain bed,
## and instancing of high-fidelity architectural structures and realistic vegetation.

const ModelCache = preload("res://shared/graphics/model_cache.gd")
const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")


var sun_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null

func setup_lighting(sun_color: Color, sun_energy: float, sun_rot: Vector3, sky_top: Color, sky_horizon: Color, fog_col: Color, fog_density: float = 0.0012) -> void:
	# 1. Directional Sun (Key Light)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "AeroSunLight"
	sun_light.light_color = sun_color
	sun_light.light_energy = sun_energy
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.03
	sun_light.shadow_normal_bias = 1.2
	sun_light.shadow_blur = 1.5
	sun_light.rotation_degrees = sun_rot
	add_child(sun_light)

	# 2. Upward Ground Fill Light (Eliminates crushed pitch-black shadows on track undersides)
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "AeroGroundFillLight"
	fill_light.light_color = sky_horizon.lerp(Color(0.85, 0.90, 1.0), 0.5)
	fill_light.light_energy = 0.55
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(55.0, sun_rot.y + 180.0, 0.0)
	add_child(fill_light)

	# 3. World Environment with Rich Ambient Sky Lighting
	world_env = WorldEnvironment.new()
	world_env.name = "AeroWorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = sky_horizon
	sky_mat.ground_bottom_color = sky_horizon.lerp(Color(0.2, 0.22, 0.25), 0.5)
	sky_mat.ground_horizon_color = sky_horizon
	sky_mat.sun_angle_max = 35.0
	sky.sky_material = sky_mat
	env.sky = sky

	# Ambient Sky Light: Guarantees visible surface details even in deep shadows
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.70, 0.74, 0.82)
	env.ambient_light_energy = 1.15
	env.ambient_light_sky_contribution = 0.80

	# Volumetric Fog & Atmospheric Depth
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_density = fog_density
	env.fog_aerial_perspective = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.03

	world_env.environment = env
	add_child(world_env)

func create_ground_bed(size: float, mat: Material, elevation: float = -0.5) -> MeshInstance3D:
	var ground = MeshInstance3D.new()
	ground.name = "ContinuousTerrainBed"
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(0, elevation, 0)
	add_child(ground)

	var sb = StaticBody3D.new()
	sb.name = "GroundCollisionBody"
	sb.collision_layer = AeroConstants.LAYER_WORLD
	sb.collision_mask = 0
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(size, 1.0, size)
	col.shape = box
	col.position = Vector3(0, -0.5, 0)
	sb.add_child(col)
	ground.add_child(sb)

	return ground

func spawn_tree(tree_model_path: String, pos: Vector3, scale_range: Vector2 = Vector2(0.85, 1.35)) -> Node3D:
	var tree = ModelCache.get_model(tree_model_path)
	if not tree:
		return null
	var s = randf_range(scale_range.x, scale_range.y)
	tree.scale = Vector3(s, s, s)
	tree.rotation_degrees.y = randf_range(0.0, 360.0)
	tree.position = pos
	add_child(tree)
	return tree

func spawn_building(model_path: String, pos: Vector3, rot_y: float = 0.0, scale_mult: Vector3 = Vector3.ONE) -> Node3D:
	var bld = ModelCache.get_model(model_path)
	if not bld:
		return null
	bld.position = pos
	bld.rotation_degrees.y = rot_y
	bld.scale = scale_mult
	add_child(bld)
	return bld
