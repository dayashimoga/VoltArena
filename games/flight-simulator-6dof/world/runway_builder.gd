class_name RunwayBuilder
extends Node3D

## Procedural builder for the 60m x 3000m precision runway complex.
## Constructs asphalt surface, centerline stripes, threshold piano keys,
## edge lights spaced every 60m, and a 4-unit PAPI glide slope indicator at 3 degrees.

const RUNWAY_WIDTH: float = 60.0
const RUNWAY_LENGTH: float = 3000.0
const EDGE_LIGHT_SPACING: float = 60.0
const GLIDE_SLOPE_DEG: float = 3.0

var runway_mesh_instance: MeshInstance3D
var runway_collision: CollisionShape3D
var papi_lights_container: Node3D
var edge_lights_container: Node3D

func _ready() -> void:
	build_runway_complex()

func build_runway_complex() -> void:
	# Root position is at (0, 0.05, 0)
	position = Vector3(0.0, 0.05, 0.0)

	_build_asphalt_deck()
	_build_runway_markings()
	_build_edge_lights()
	_build_papi_system()

func _build_asphalt_deck() -> void:
	runway_mesh_instance = MeshInstance3D.new()
	runway_mesh_instance.name = "RunwayAsphalt"

	var plane_mesh = BoxMesh.new()
	# Extends from Z = +50 to Z = -2950 (3000m total, aligned with -Z)
	plane_mesh.size = Vector3(RUNWAY_WIDTH, 0.15, RUNWAY_LENGTH)
	runway_mesh_instance.mesh = plane_mesh
	runway_mesh_instance.position = Vector3(0.0, -0.075, -RUNWAY_LENGTH * 0.5 + 50.0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.16, 0.17)
	mat.roughness = 0.88
	mat.metallic = 0.0
	runway_mesh_instance.material_override = mat

	# Add StaticBody3D collision for runway deck
	var static_body = StaticBody3D.new()
	static_body.name = "RunwayCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 2
	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = plane_mesh.size
	col_shape.shape = box_shape
	static_body.add_child(col_shape)
	runway_mesh_instance.add_child(static_body)

	add_child(runway_mesh_instance)

func _build_runway_markings() -> void:
	var markings_node = Node3D.new()
	markings_node.name = "RunwayMarkings"

	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.95, 0.95, 0.96)
	white_mat.roughness = 0.75

	# 1. Dashed Centerline (30m long dashes with 20m gaps)
	var dash_len = 30.0
	var gap_len = 20.0
	var total_step = dash_len + gap_len
	var z_start = 50.0
	var z_end = -RUNWAY_LENGTH + 50.0

	var multimesh_inst = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dash_count = int(RUNWAY_LENGTH / total_step)
	mm.instance_count = dash_count
	var dash_mesh = BoxMesh.new()
	dash_mesh.size = Vector3(1.2, 0.02, dash_len)
	mm.mesh = dash_mesh
	multimesh_inst.material_override = white_mat

	var idx = 0
	var cur_z = z_start - 60.0
	while cur_z > z_end + 60.0 and idx < dash_count:
		var t = Transform3D(Basis(), Vector3(0.0, 0.085, cur_z))
		mm.set_instance_transform(idx, t)
		cur_z -= total_step
		idx += 1
	multimesh_inst.multimesh = mm
	markings_node.add_child(multimesh_inst)

	# 2. Threshold Piano Keys (Approach End at Z = +20)
	for side in [-1, 1]:
		for k in range(6):
			var key = MeshInstance3D.new()
			var km = BoxMesh.new()
			km.size = Vector3(2.2, 0.02, 35.0)
			key.mesh = km
			key.material_override = white_mat
			var x_pos = side * (6.0 + k * 4.0)
			key.position = Vector3(x_pos, 0.085, z_start - 25.0)
			markings_node.add_child(key)

	add_child(markings_node)

func _build_edge_lights() -> void:
	edge_lights_container = Node3D.new()
	edge_lights_container.name = "RunwayEdgeLights"

	var light_mat = StandardMaterial3D.new()
	light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light_mat.albedo_color = Color(1.0, 0.95, 0.85)

	var z_start = 50.0
	var steps = int(RUNWAY_LENGTH / EDGE_LIGHT_SPACING)

	for i in range(steps + 1):
		var z = z_start - i * EDGE_LIGHT_SPACING
		# Left edge light (X = -RUNWAY_WIDTH * 0.5)
		_create_fixture(Vector3(-RUNWAY_WIDTH * 0.5 - 0.6, 0.35, z), light_mat)
		# Right edge light (X = +RUNWAY_WIDTH * 0.5)
		_create_fixture(Vector3(RUNWAY_WIDTH * 0.5 + 0.6, 0.35, z), light_mat)

	add_child(edge_lights_container)

func _create_fixture(pos: Vector3, mat: Material) -> void:
	var post = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.08
	post_mesh.height = 0.5
	post.mesh = post_mesh
	post.position = pos

	var lens = MeshInstance3D.new()
	var lens_mesh = SphereMesh.new()
	lens_mesh.radius = 0.12
	lens_mesh.height = 0.24
	lens.mesh = lens_mesh
	lens.material_override = mat
	lens.position = Vector3(0.0, 0.25, 0.0)
	post.add_child(lens)

	edge_lights_container.add_child(post)

func _build_papi_system() -> void:
	papi_lights_container = Node3D.new()
	papi_lights_container.name = "PAPI_Lights"

	# Located 300m down the runway on the left side (standard touchdown aim point)
	var papi_z = -300.0
	var base_x = -RUNWAY_WIDTH * 0.5 - 16.0 # 16m off left runway edge

	# 4 PAPI light units spaced 9m apart laterally
	for u in range(4):
		var unit_node = Node3D.new()
		unit_node.name = "PAPI_Unit_%d" % (u + 1)
		var ux = base_x - u * 9.0
		unit_node.position = Vector3(ux, 0.5, papi_z)

		var housing = MeshInstance3D.new()
		var hm = BoxMesh.new()
		hm.size = Vector3(1.4, 0.6, 1.2)
		housing.mesh = hm
		var h_mat = StandardMaterial3D.new()
		h_mat.albedo_color = Color(0.85, 0.8, 0.1) # Aviation Yellow housing
		housing.material_override = h_mat
		unit_node.add_child(housing)

		# Light projector
		var projector = MeshInstance3D.new()
		var pm = SphereMesh.new()
		pm.radius = 0.2
		pm.height = 0.4
		projector.mesh = pm
		var p_mat = StandardMaterial3D.new()
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# 2 White / 2 Red at nominal 3.0 deg
		p_mat.albedo_color = Color(1.0, 1.0, 1.0) if u < 2 else Color(1.0, 0.1, 0.05)
		projector.material_override = p_mat
		projector.position = Vector3(0.0, 0.05, 0.6)
		unit_node.add_child(projector)

		papi_lights_container.add_child(unit_node)

	add_child(papi_lights_container)
