class_name TerrainBuilder
extends Node3D

## Procedural terrain generator for 6-DoF flight simulator.
## Generates an 8000m x 8000m continuous landscape with flattened airport valley,
## rolling foothills, and rugged mountain massifs (> 1800m) with collision and splat shader.

const TERRAIN_SIZE: float = 8000.0
const GRID_SUBDIVISIONS: int = 128
const RUNWAY_CORRIDOR_WIDTH: float = 400.0
const RUNWAY_CORRIDOR_LENGTH: float = 4500.0

var terrain_mesh_instance: MeshInstance3D
var terrain_collision: CollisionShape3D

func _ready() -> void:
	build_terrain()

func build_terrain() -> void:
	name = "TerrainSystem"

	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(TERRAIN_SIZE, TERRAIN_SIZE)
	plane_mesh.subdivide_width = GRID_SUBDIVISIONS
	plane_mesh.subdivide_depth = GRID_SUBDIVISIONS

	# Apply procedural height displacement
	var st = SurfaceTool.new()
	st.create_from(plane_mesh, 0)
	var array_mesh = st.commit()

	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)

	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		var h = _compute_height(v.x, v.z)
		v.y = h
		mdt.set_vertex(i, v)

	# Recalculate smooth normals for realistic lighting & slope calculations
	for i in range(mdt.get_face_count()):
		var v1_idx = mdt.get_face_vertex(i, 0)
		var v2_idx = mdt.get_face_vertex(i, 1)
		var v3_idx = mdt.get_face_vertex(i, 2)
		var p1 = mdt.get_vertex(v1_idx)
		var p2 = mdt.get_vertex(v2_idx)
		var p3 = mdt.get_vertex(v3_idx)
		var normal = (p2 - p1).cross(p3 - p1).normalized()
		mdt.set_vertex_normal(v1_idx, normal)
		mdt.set_vertex_normal(v2_idx, normal)
		mdt.set_vertex_normal(v3_idx, normal)

	var displaced_mesh = ArrayMesh.new()
	mdt.commit_to_surface(displaced_mesh)

	# Mesh Instance
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "TerrainMesh"
	terrain_mesh_instance.mesh = displaced_mesh

	# Material: terrain_splat shader
	var shader = load("res://games/flight-simulator-6dof/shaders/terrain_splat.gdshader")
	if shader:
		var s_mat = ShaderMaterial.new()
		s_mat.shader = shader
		s_mat.set_shader_parameter("snow_altitude_min", 1750.0)
		s_mat.set_shader_parameter("snow_altitude_full", 1950.0)
		s_mat.set_shader_parameter("rock_slope_threshold", 0.65)
		terrain_mesh_instance.material_override = s_mat

	add_child(terrain_mesh_instance)

	# Collision Shape
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 2

	var shape = CollisionShape3D.new()
	var trimesh_shape = displaced_mesh.create_trimesh_shape()
	shape.shape = trimesh_shape
	static_body.add_child(shape)
	add_child(static_body)

## Computes procedural elevation: flattens airport valley, rises into mountain ridges > 1800m
func _compute_height(x: float, z: float) -> float:
	# Airport valley mask (runway corridor around X = 0, Z between +200 and -3200)
	var z_dist_to_runway = 0.0
	if z > 200.0:
		z_dist_to_runway = z - 200.0
	elif z < -3200.0:
		z_dist_to_runway = -3200.0 - z

	var valley_dist = sqrt(x * x + z_dist_to_runway * z_dist_to_runway)
	var valley_blend = clamp((valley_dist - RUNWAY_CORRIDOR_WIDTH * 0.5) / 1200.0, 0.0, 1.0)
	valley_blend = smoothstep(0.0, 1.0, valley_blend)

	# Macro mountain ridges
	var scale_macro = 0.0006
	var scale_ridge = 0.0018
	var macro_elevation = sin(x * scale_macro * 2.1) * cos(z * scale_macro * 1.8) * 900.0
	macro_elevation += sin((x + z) * scale_ridge * 3.1) * 650.0

	# Distant alpine mountain peaks (reaches up to 2200m MSL)
	var dist_from_center = sqrt(x * x + z * z)
	var alpine_boost = clamp((dist_from_center - 2200.0) / 1500.0, 0.0, 1.0) * 1100.0

	var raw_height = max(0.0, (macro_elevation + alpine_boost + 450.0))
	return raw_height * valley_blend
