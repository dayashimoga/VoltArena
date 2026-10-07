class_name AeroTrackGenerator
extends RefCounted

## Continuous 3D ribbon track generator for AeroRush: Impossible Circuit.
## Extrudes seamless banked curves, 360° vertical loops, corkscrews, wall-rides,
## elevated highway pylons, and collision hulls with zero joint seams.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

const TRACK_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.12, 0.13, 0.15, 1.0);
uniform vec4 curb_color : source_color = vec4(0.95, 0.25, 0.08, 1.0);
uniform vec4 neon_border_color : source_color = vec4(0.08, 0.85, 1.0, 1.0);
uniform float roughness_val = 0.65;

void fragment() {
	// UV.x maps from 0.0 (left barrier) to 1.0 (right barrier)
	float u = UV.x;
	bool is_border = (u < 0.08 || u > 0.92);
	bool is_curb = ((u >= 0.08 && u < 0.14) || (u > 0.86 && u <= 0.92));
	bool is_center_line = (abs(u - 0.5) < 0.015);

	if (is_border) {
		// Glowing Neon Track Boundary
		ALBEDO = neon_border_color.rgb;
		EMISSION = neon_border_color.rgb * 2.8;
		ROUGHNESS = 0.15;
		METALLIC = 0.5;
	} else if (is_curb) {
		// High-contrast Red/White or Orange Stunt Curb
		float stripe = mod(UV.y * 8.0, 2.0);
		vec3 c_col = (stripe < 1.0) ? curb_color.rgb : vec3(0.92, 0.92, 0.92);
		ALBEDO = c_col;
		EMISSION = c_col * 0.4;
		ROUGHNESS = 0.45;
		METALLIC = 0.1;
	} else if (is_center_line) {
		// Dashed White High-Speed Centerline
		float dash = mod(UV.y * 6.0, 2.0);
		if (dash < 1.0) {
			ALBEDO = vec3(0.95, 0.95, 0.95);
			EMISSION = vec3(0.95, 0.95, 0.95) * 1.2;
		} else {
			ALBEDO = asphalt_color.rgb;
		}
		ROUGHNESS = 0.65;
		METALLIC = 0.05;
	} else {
		// Premium High-Grip Track Surface
		ALBEDO = asphalt_color.rgb;
		ROUGHNESS = roughness_val;
		METALLIC = 0.08;
		SPECULAR = 0.35;
	}
}
"""

static func generate_track(waypoints: Array, default_width: float = 14.0) -> Dictionary:
	var root = Node3D.new()
	root.name = "ContinuousRibbonTrack"

	if waypoints.size() < 3:
		return {"root": root, "checkpoints": [], "total_length": 0.0}

	# 1. Catmull-Rom Spline Interpolation for high spatial continuity
	var dense_points = _interpolate_spline_points(waypoints, 2.0)
	if dense_points.is_empty():
		return {"root": root, "checkpoints": [], "total_length": 0.0}

	# 2. Build Continuous Ribbon Surface Mesh and Collision Arrays
	var surf_tool = SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_faces = PackedVector3Array()
	var total_length = 0.0

	var seg_count = dense_points.size()
	for i in range(seg_count - 1):
		var p0 = dense_points[i]
		var p1 = dense_points[i + 1]

		# Check if segment is marked as jump gap
		if p0.get("is_jump_gap", false):
			continue

		var pos0: Vector3 = p0["pos"]
		var pos1: Vector3 = p1["pos"]
		var norm0: Vector3 = p0["normal"]
		var norm1: Vector3 = p1["normal"]
		var right0: Vector3 = p0["right"]
		var right1: Vector3 = p1["right"]
		var w0: float = p0.get("width", default_width) * 0.5
		var w1: float = p1.get("width", default_width) * 0.5

		var d_len = pos0.distance_to(pos1)
		total_length += d_len

		# 6 Profile Cross-section points per slice:
		# 0: Left barrier top, 1: Left track edge, 2: Center, 3: Right track edge, 4: Right barrier top
		var v0_l_wall = pos0 - right0 * (w0 + 0.6) + norm0 * 0.75
		var v0_l_edge = pos0 - right0 * w0 + norm0 * 0.12
		var v0_center = pos0
		var v0_r_edge = pos0 + right0 * w0 + norm0 * 0.12
		var v0_r_wall = pos0 + right0 * (w0 + 0.6) + norm0 * 0.75

		var v1_l_wall = pos1 - right1 * (w1 + 0.6) + norm1 * 0.75
		var v1_l_edge = pos1 - right1 * w1 + norm1 * 0.12
		var v1_center = pos1
		var v1_r_edge = pos1 + right1 * w1 + norm1 * 0.12
		var v1_r_wall = pos1 + right1 * (w1 + 0.6) + norm1 * 0.75

		var v_coord0 = total_length / 10.0
		var v_coord1 = (total_length + d_len) / 10.0

		# Add Quad Strips:
		# Left Wall
		_add_quad(surf_tool, col_faces, v0_l_wall, v0_l_edge, v1_l_edge, v1_l_wall, 0.0, 0.12, v_coord0, v_coord1, norm0, norm1)
		# Left Half
		_add_quad(surf_tool, col_faces, v0_l_edge, v0_center, v1_center, v1_l_edge, 0.12, 0.50, v_coord0, v_coord1, norm0, norm1)
		# Right Half
		_add_quad(surf_tool, col_faces, v0_center, v0_r_edge, v1_r_edge, v1_center, 0.50, 0.88, v_coord0, v_coord1, norm0, norm1)
		# Right Wall
		_add_quad(surf_tool, col_faces, v0_r_edge, v0_r_wall, v1_r_wall, v1_r_edge, 0.88, 1.0, v_coord0, v_coord1, norm0, norm1)

	surf_tool.generate_normals()
	surf_tool.generate_tangents()
	var mesh = surf_tool.commit()

	# Apply Track Shader Material
	var track_mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = TRACK_SHADER_CODE
	track_mat.shader = shader
	if mesh and mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, track_mat)

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "TrackSurfaceMesh"
	mesh_inst.mesh = mesh
	root.add_child(mesh_inst)

	# 3. Create Seamless Continuous Collision Body (ConcavePolygonShape3D)
	var static_body = StaticBody3D.new()
	static_body.name = "TrackCollisionBody"
	static_body.collision_layer = AeroConstants.LAYER_WORLD
	static_body.collision_mask = 0

	var col_shape = CollisionShape3D.new()
	col_shape.name = "ContinuousConcaveShape"
	var concave_poly = ConcavePolygonShape3D.new()
	concave_poly.set_faces(col_faces)
	col_shape.shape = concave_poly
	static_body.add_child(col_shape)
	root.add_child(static_body)

	# 4. Generate Structural Support Pylons for elevated sections
	var pylons_container = Node3D.new()
	pylons_container.name = "StructuralPylons"
	root.add_child(pylons_container)
	_generate_support_pylons(dense_points, pylons_container)

	return {
		"root": root,
		"mesh_instance": mesh_inst,
		"static_body": static_body,
		"dense_points": dense_points,
		"total_length": total_length
	}

static func _add_quad(
	st: SurfaceTool,
	col_faces: PackedVector3Array,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	u0: float, u1: float, v0: float, v1: float,
	norm0: Vector3, norm1: Vector3
) -> void:
	# Triangle 1: p0 -> p1 -> p2
	st.set_uv(Vector2(u0, v0))
	st.set_normal(norm0)
	st.add_vertex(p0)

	st.set_uv(Vector2(u1, v0))
	st.set_normal(norm0)
	st.add_vertex(p1)

	st.set_uv(Vector2(u1, v1))
	st.set_normal(norm1)
	st.add_vertex(p2)

	# Triangle 2: p0 -> p2 -> p3
	st.set_uv(Vector2(u0, v0))
	st.set_normal(norm0)
	st.add_vertex(p0)

	st.set_uv(Vector2(u1, v1))
	st.set_normal(norm1)
	st.add_vertex(p2)

	st.set_uv(Vector2(u0, v1))
	st.set_normal(norm1)
	st.add_vertex(p3)

	# Collision triangles
	col_faces.append(p0)
	col_faces.append(p1)
	col_faces.append(p2)
	col_faces.append(p0)
	col_faces.append(p2)
	col_faces.append(p3)

static func _interpolate_spline_points(waypoints: Array, step_dist: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count = waypoints.size()

	for i in range(count - 1):
		var p_prev = waypoints[maxi(0, i - 1)]["pos"] as Vector3
		var p_curr = waypoints[i]["pos"] as Vector3
		var p_next = waypoints[i + 1]["pos"] as Vector3
		var p_next2 = waypoints[mini(count - 1, i + 2)]["pos"] as Vector3

		var bank0 = waypoints[i].get("bank_deg", 0.0) as float
		var bank1 = waypoints[i + 1].get("bank_deg", 0.0) as float
		var w0 = waypoints[i].get("width", 14.0) as float
		var w1 = waypoints[i + 1].get("width", 14.0) as float
		var is_gap = waypoints[i].get("is_jump_gap", false) as bool

		var seg_len = p_curr.distance_to(p_next)
		var subdivisions = maxi(1, int(seg_len / step_dist))

		for s in range(subdivisions):
			var t = float(s) / float(subdivisions)
			var pos = _catmull_rom(p_prev, p_curr, p_next, p_next2, t)
			var forward = _catmull_rom_tangent(p_prev, p_curr, p_next, p_next2, t).normalized()
			if forward.length_squared() < 0.001:
				forward = (p_next - p_curr).normalized()

			var bank = lerpf(bank0, bank1, t)
			var width = lerpf(w0, w1, t)

			# Compute oriented normal and right vector taking banking into account
			var up_ref = Vector3.UP
			# Handle vertical or near-vertical loops
			if absf(forward.dot(Vector3.UP)) > 0.95:
				up_ref = Vector3.FORWARD

			var base_right = forward.cross(up_ref).normalized()
			var base_normal = base_right.cross(forward).normalized()

			# Apply banking rotation around forward axis
			var q_bank = Quaternion(forward, deg_to_rad(bank))
			var final_normal = q_bank * base_normal
			var final_right = q_bank * base_right

			result.append({
				"pos": pos,
				"forward": forward,
				"normal": final_normal,
				"right": final_right,
				"width": width,
				"is_jump_gap": is_gap
			})

	# Append final point
	var last_wp = waypoints[count - 1]
	var l_pos = last_wp["pos"] as Vector3
	var l_fwd = (l_pos - waypoints[count - 2]["pos"]).normalized()
	var l_right = l_fwd.cross(Vector3.UP).normalized()
	var l_norm = l_right.cross(l_fwd).normalized()
	result.append({
		"pos": l_pos,
		"forward": l_fwd,
		"normal": l_norm,
		"right": l_right,
		"width": last_wp.get("width", 14.0),
		"is_jump_gap": false
	})

	return result

static func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 = t * t
	var t3 = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

static func _catmull_rom_tangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 = t * t
	return 0.5 * (
		(-p0 + p2) +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * (2.0 * t) +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * (3.0 * t2)
	)

static func _generate_support_pylons(dense_points: Array[Dictionary], parent: Node3D) -> void:
	var pylon_spacing = 38.0
	var dist_accum = 0.0

	var pylon_mat = StandardMaterial3D.new()
	pylon_mat.albedo_color = Color(0.22, 0.24, 0.28)
	pylon_mat.metallic = 0.8
	pylon_mat.roughness = 0.35

	for i in range(1, dense_points.size() - 1):
		var p_prev = dense_points[i - 1]["pos"] as Vector3
		var p_curr = dense_points[i]["pos"] as Vector3
		dist_accum += p_prev.distance_to(p_curr)

		if dist_accum >= pylon_spacing:
			dist_accum = 0.0
			var height = p_curr.y
			if height > 4.5:
				var pylon = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = 1.1
				cyl.bottom_radius = 1.4
				cyl.height = height
				pylon.mesh = cyl
				pylon.material_override = pylon_mat
				pylon.position = Vector3(p_curr.x, height * 0.5, p_curr.z)
				parent.add_child(pylon)
