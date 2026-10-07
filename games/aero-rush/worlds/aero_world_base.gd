class_name AeroWorldBase
extends Node3D

## Base environment coordinator for AeroRush: Impossible Circuit.
## Manages atmospheric lighting, sky, directional sun, fog, terrain bed,
## and instancing of high-fidelity architectural structures and realistic vegetation.

const ModelCache = preload("res://shared/graphics/model_cache.gd")
const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")


var sun_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null

func setup_lighting(sun_color: Color, sun_energy: float, sun_rot: Vector3, sky_top: Color, sky_horizon: Color, fog_col: Color, fog_density: float = 0.002) -> void:
	# 1. Directional Sun
	sun_light = DirectionalLight3D.new()
	sun_light.name = "AeroSunLight"
	sun_light.light_color = sun_color
	sun_light.light_energy = sun_energy
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.04
	sun_light.rotation_degrees = sun_rot
	add_child(sun_light)

	# 2. World Environment & Sky
	world_env = WorldEnvironment.new()
	world_env.name = "AeroWorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = sky_horizon
	sky_mat.ground_bottom_color = sky_horizon * 0.4
	sky_mat.ground_horizon_color = sky_horizon
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky

	# Volumetric Fog & Atmospheric Depth
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_density = fog_density
	env.fog_aerial_perspective = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05

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
