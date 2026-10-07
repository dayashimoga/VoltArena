class_name AeroTrackGenerator
extends RefCounted

## Continuous 3D ribbon track generator for AeroRush: Impossible Circuit.
## Implements continuous Parallel Transport / Rotation Minimizing Frames (RMF/Bishop frame)
## to eliminate coordinate singularities, normal flipping, and inverted geometry across
## 360° vertical loops, corkscrews, wall-rides, and multi-tier elevated stunt highways.
## Constructs solid 3D cross-sections with driving decks, curbs, barriers, and underside slabs.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

const TRACK_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.22, 0.24, 0.28, 1.0);
uniform vec4 curb_color : source_color = vec4(1.0, 0.40, 0.06, 1.0);
uniform vec4 neon_left_color : source_color = vec4(0.05, 0.92, 1.0, 1.0);
uniform vec4 neon_right_color : source_color = vec4(1.0, 0.24, 0.65, 1.0);
uniform float roughness_val = 0.50;

void fragment() {
	float u = UV.x;
	bool is_border_left = (u < 0.05);
	bool is_border_right = (u > 0.95);
	bool is_barrier_face = ((u >= 0.05 && u < 0.10) || (u > 0.90 && u <= 0.95));
	bool is_curb = ((u >= 0.10 && u < 0.16) || (u > 0.84 && u <= 0.90));
	bool is_center_line = (abs(u - 0.5) < 0.016);
	bool is_tire_track = ((u >= 0.27 && u <= 0.37) || (u >= 0.63 && u <= 0.73));

	if (is_border_left) {
		// Glowing Cyan Left Guide Rail
		ALBEDO = neon_left_color.rgb;
		EMISSION = neon_left_color.rgb * 3.6;
		ROUGHNESS = 0.10;
		METALLIC = 0.7;
	} else if (is_border_right) {
		// Glowing Magenta/Amber Right Guide Rail
		ALBEDO = neon_right_color.rgb;
		EMISSION = neon_right_color.rgb * 3.6;
		ROUGHNESS = 0.10;
		METALLIC = 0.7;
	} else if (is_barrier_face) {
		// Reinforced Carbon Barrier Wall
		ALBEDO = vec3(0.18, 0.20, 0.24);
		ROUGHNESS = 0.65;
		METALLIC = 0.45;
	} else if (is_curb) {
		// High-contrast Orange / White Alternating Stunt Curb
		float stripe = mod(UV.y * 6.0, 2.0);
		vec3 c_col = (stripe < 1.0) ? curb_color.rgb : vec3(0.96, 0.96, 0.98);
		ALBEDO = c_col;
		EMISSION = (stripe < 1.0) ? curb_color.rgb * 0.9 : vec3(0.25);
		ROUGHNESS = 0.35;
		METALLIC = 0.15;
	} else if (is_center_line) {
		// High-Speed Dashed Centerline
		float dash = mod(UV.y * 5.0, 2.0);
		if (dash < 1.0) {
			ALBEDO = vec3(1.0, 0.92, 0.15);
			EMISSION = vec3(1.0, 0.92, 0.15) * 2.2;
		} else {
			ALBEDO = asphalt_color.rgb;
		}
		ROUGHNESS = 0.45;
		METALLIC = 0.05;
	} else if (is_tire_track) {
		// High-Speed Rubberized Tire Wear Groove
		ALBEDO = vec3(0.15, 0.16, 0.19);
		ROUGHNESS = 0.42;
		METALLIC = 0.12;
		SPECULAR = 0.45;
	} else {
		// Premium High-Grip Asphalt Track Surface
		ALBEDO = asphalt_color.rgb;
		ROUGHNESS = roughness_val;
		METALLIC = 0.10;
		SPECULAR = 0.35;
	}
}
"""

const UNDERSIDE_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	// Structural Reinforced Steel / Concrete Deck Underside
	ALBEDO = vec3(0.14, 0.16, 0.19);
	ROUGHNESS = 0.85;
	METALLIC = 0.35;
}
"""

static func generate_track(waypoints: Array, default_width: float = 16.0) -> Dictionary:
	var root = Node3D.new()
	root.name = "ContinuousRibbonTrack"

	if waypoints.size() < 3:
		return {"root": root, "dense_points": [], "total_length": 0.0}

	# 1. Continuous RMF (Bishop Frame) Spline Interpolation
	var dense_points = _interpolate_spline_points_rmf(waypoints, 2.5, default_width)
	if dense_points.size() < 2:
		return {"root": root, "dense_points": [], "total_length": 0.0}

	# 2. Build Continuous 3D Surface Mesh & Solid Underside
	var surf_tool = SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var under_tool = SurfaceTool.new()
	under_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_faces = PackedVector3Array()
	var total_length = 0.0
	var seg_count = dense_points.size()

	for i in range(seg_count - 1):
		var p0 = dense_points[i]
		var p1 = dense_points[i + 1]

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

		var v0_coord = total_length / 12.0
		var v1_coord = (total_length + d_len) / 12.0

		# Profile Cross-Section Slice 0 (Top Driving Surface & Barriers):
		# Barrier Top Left -> Barrier Inner Left -> Road Left -> Center -> Road Right -> Barrier Inner Right -> Barrier Top Right
		var b_height = 1.35
		var b_thick = 0.70
		var slab_depth = 0.65

		var v0_l_b_top = pos0 - right0 * (w0 + b_thick) + norm0 * b_height
		var v0_l_b_inner = pos0 - right0 * w0 + norm0 * (b_height * 0.85)
		var v0_l_curb = pos0 - right0 * (w0 * 0.86) + norm0 * 0.08
		var v0_center = pos0
		var v0_r_curb = pos0 + right0 * (w0 * 0.86) + norm0 * 0.08
		var v0_r_b_inner = pos0 + right0 * w0 + norm0 * (b_height * 0.85)
		var v0_r_b_top = pos0 + right0 * (w0 + b_thick) + norm0 * b_height

		# Profile Cross-Section Slice 1:
		var v1_l_b_top = pos1 - right1 * (w1 + b_thick) + norm1 * b_height
		var v1_l_b_inner = pos1 - right1 * w1 + norm1 * (b_height * 0.85)
		var v1_l_curb = pos1 - right1 * (w1 * 0.86) + norm1 * 0.08
		var v1_center = pos1
		var v1_r_curb = pos1 + right1 * (w1 * 0.86) + norm1 * 0.08
		var v1_r_b_inner = pos1 + right1 * w1 + norm1 * (b_height * 0.85)
		var v1_r_b_top = pos1 + right1 * (w1 + b_thick) + norm1 * b_height

		# --- TOP DRIVING SURFACE QUADS ---
		# 1. Left Barrier Wall
		_add_quad(surf_tool, col_faces, v0_l_b_top, v0_l_b_inner, v1_l_b_inner, v1_l_b_top, 0.0, 0.08, v0_coord, v1_coord, norm0, norm1, true)
		# 2. Left Curb Strip
		_add_quad(surf_tool, col_faces, v0_l_b_inner, v0_l_curb, v1_l_curb, v1_l_b_inner, 0.08, 0.16, v0_coord, v1_coord, norm0, norm1, true)
		# 3. Left Driving Lane
		_add_quad(surf_tool, col_faces, v0_l_curb, v0_center, v1_center, v1_l_curb, 0.16, 0.50, v0_coord, v1_coord, norm0, norm1, true)
		# 4. Right Driving Lane
		_add_quad(surf_tool, col_faces, v0_center, v0_r_curb, v1_r_curb, v1_center, 0.50, 0.84, v0_coord, v1_coord, norm0, norm1, true)
		# 5. Right Curb Strip
		_add_quad(surf_tool, col_faces, v0_r_curb, v0_r_b_inner, v1_r_b_inner, v1_r_curb, 0.84, 0.92, v0_coord, v1_coord, norm0, norm1, true)
		# 6. Right Barrier Wall
		_add_quad(surf_tool, col_faces, v0_r_b_inner, v0_r_b_top, v1_r_b_top, v1_r_b_inner, 0.92, 1.0, v0_coord, v1_coord, norm0, norm1, true)

		# --- UNDERSIDE SLAB QUADS (Solid Highway Structure) ---
		var v0_under_l = pos0 - right0 * (w0 + b_thick) - norm0 * slab_depth
		var v0_under_r = pos0 + right0 * (w0 + b_thick) - norm0 * slab_depth
		var v1_under_l = pos1 - right1 * (w1 + b_thick) - norm1 * slab_depth
		var v1_under_r = pos1 + right1 * (w1 + b_thick) - norm1 * slab_depth

		# Bottom surface
		_add_quad(under_tool, null, v0_under_r, v0_under_l, v1_under_l, v1_under_r, 0.0, 1.0, v0_coord, v1_coord, -norm0, -norm1, false)
		# Outer left side wall
		_add_quad(under_tool, null, v0_l_b_top, v0_under_l, v1_under_l, v1_l_b_top, 0.0, 1.0, v0_coord, v1_coord, -right0, -right1, false)
		# Outer right side wall
		_add_quad(under_tool, null, v0_under_r, v0_r_b_top, v1_r_b_top, v1_under_r, 0.0, 1.0, v0_coord, v1_coord, right0, right1, false)

	surf_tool.generate_normals()
	surf_tool.generate_tangents()
	var main_mesh = surf_tool.commit()

	var track_mat = ShaderMaterial.new()
	var s_main = Shader.new()
	s_main.code = TRACK_SHADER_CODE
	track_mat.shader = s_main
	if main_mesh and main_mesh.get_surface_count() > 0:
		main_mesh.surface_set_material(0, track_mat)

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "TrackSurfaceMesh"
	mesh_inst.mesh = main_mesh
	root.add_child(mesh_inst)

	# Underside Mesh
	under_tool.generate_normals()
	var under_mesh = under_tool.commit()
	var under_mat = ShaderMaterial.new()
	var s_under = Shader.new()
	s_under.code = UNDERSIDE_SHADER_CODE
	under_mat.shader = s_under
	if under_mesh and under_mesh.get_surface_count() > 0:
		under_mesh.surface_set_material(0, under_mat)

	var under_inst = MeshInstance3D.new()
	under_inst.name = "TrackUndersideMesh"
	under_inst.mesh = under_mesh
	root.add_child(under_inst)

	# 3. Create High-Fidelity Continuous Collision Body (ConcavePolygonShape3D)
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

	# 4. Generate Highway Pylons for elevated sections
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
	col_faces: Variant,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	u0: float, u1: float, v0: float, v1: float,
	norm0: Vector3, norm1: Vector3,
	add_collision: bool = false
) -> void:
	# Triangle 1: p0 -> p1 -> p2 (Counter-clockwise upward facing)
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

	# Robust Two-Sided Collision Triangles to guarantee vehicle NEVER falls through
	if add_collision and col_faces != null and col_faces is PackedVector3Array:
		# Front face
		col_faces.append(p0)
		col_faces.append(p1)
		col_faces.append(p2)
		col_faces.append(p0)
		col_faces.append(p2)
		col_faces.append(p3)
		# Back face (zero-tolerance fall prevention)
		col_faces.append(p0)
		col_faces.append(p2)
		col_faces.append(p1)
		col_faces.append(p0)
		col_faces.append(p3)
		col_faces.append(p2)

static func _interpolate_spline_points_rmf(waypoints: Array, step_dist: float, default_width: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count = waypoints.size()
	if count < 2:
		return result

	# First pass: Sample dense spline curve positions and tangent directions
	var raw_samples: Array[Dictionary] = []

	for i in range(count - 1):
		var p_prev = waypoints[maxi(0, i - 1)]["pos"] as Vector3
		var p_curr = waypoints[i]["pos"] as Vector3
		var p_next = waypoints[i + 1]["pos"] as Vector3
		var p_next2 = waypoints[mini(count - 1, i + 2)]["pos"] as Vector3

		var bank0 = float(waypoints[i].get("bank_deg", 0.0))
		var bank1 = float(waypoints[i + 1].get("bank_deg", 0.0))
		var w0 = float(waypoints[i].get("width", default_width))
		var w1 = float(waypoints[i + 1].get("width", default_width))
		var is_gap = bool(waypoints[i].get("is_jump_gap", false))

		var seg_len = p_curr.distance_to(p_next)
		var subdivisions = maxi(1, int(ceilf(seg_len / step_dist)))

		for s in range(subdivisions):
			var t = float(s) / float(subdivisions)
			var pos = _catmull_rom(p_prev, p_curr, p_next, p_next2, t)
			var forward = _catmull_rom_tangent(p_prev, p_curr, p_next, p_next2, t).normalized()
			if forward.length_squared() < 0.001:
				forward = (p_next - p_curr).normalized()

			var bank = lerpf(bank0, bank1, t)
			var width = lerpf(w0, w1, t)

			raw_samples.append({
				"pos": pos,
				"forward": forward,
				"bank_deg": bank,
				"width": width,
				"is_jump_gap": is_gap
			})

	# Append final waypoint
	var last_wp = waypoints[count - 1]
	var l_pos = last_wp["pos"] as Vector3
	var l_fwd = (l_pos - waypoints[count - 2]["pos"] as Vector3).normalized()
	raw_samples.append({
		"pos": l_pos,
		"forward": l_fwd,
		"bank_deg": float(last_wp.get("bank_deg", 0.0)),
		"width": float(last_wp.get("width", default_width)),
		"is_jump_gap": false
	})

	if raw_samples.is_empty():
		return result

	# Second pass: Compute Rotation Minimizing Frame (Bishop Frame) via parallel transport
	var current_fwd = raw_samples[0]["forward"] as Vector3
	var current_right = Vector3.RIGHT

	# Compute initial orthogonal right vector
	if absf(current_fwd.dot(Vector3.UP)) < 0.85:
		current_right = current_fwd.cross(Vector3.UP).normalized()
	else:
		current_right = current_fwd.cross(Vector3.FORWARD).normalized()

	var current_norm = current_right.cross(current_fwd).normalized()

	for k in range(raw_samples.size()):
		var sample = raw_samples[k]
		var fwd = sample["forward"] as Vector3
		var pos = sample["pos"] as Vector3
		var bank_deg = sample["bank_deg"] as float

		if k > 0:
			var prev_fwd = raw_samples[k - 1]["forward"] as Vector3
			# Parallel transport: rotate reference frame by angle between prev_fwd and fwd
			var rot_axis = prev_fwd.cross(fwd)
			if rot_axis.length_squared() > 1e-6:
				var angle = prev_fwd.angle_to(fwd)
				var q_transport = Quaternion(rot_axis.normalized(), angle)
				current_right = q_transport * current_right
				current_norm = q_transport * current_norm

			# Re-orthogonalize against tangent
			current_right = (current_right - fwd * fwd.dot(current_right)).normalized()
			current_norm = current_right.cross(fwd).normalized()

			# Upright relaxation on flat sections: gently align toward world UP if slope is low and bank is 0
			if absf(bank_deg) < 1.0 and absf(fwd.y) < 0.40 and current_norm.dot(Vector3.UP) > 0.40:
				var desired_right = fwd.cross(Vector3.UP).normalized()
				if desired_right.dot(current_right) > 0.0:
					current_right = current_right.slerp(desired_right, 0.08).normalized()
					current_norm = current_right.cross(fwd).normalized()

		# Apply intentional banking around tangent axis
		var q_bank = Quaternion(fwd, deg_to_rad(bank_deg))
		var final_right = q_bank * current_right
		var final_norm = q_bank * current_norm

		result.append({
			"pos": pos,
			"forward": fwd,
			"normal": final_norm,
			"right": final_right,
			"width": sample["width"],
			"is_jump_gap": sample["is_jump_gap"]
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

	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.28, 0.30, 0.34)
	concrete_mat.metallic = 0.35
	concrete_mat.roughness = 0.75

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.16, 0.18, 0.22)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.30

	for i in range(1, dense_points.size() - 1):
		var p_prev = dense_points[i - 1]["pos"] as Vector3
		var p_curr = dense_points[i]["pos"] as Vector3
		var is_gap = dense_points[i].get("is_jump_gap", false) as bool
		dist_accum += p_prev.distance_to(p_curr)

		if is_gap:
			continue

		if dist_accum >= pylon_spacing:
			dist_accum = 0.0
			var ground_basin_y = -6.5
			var col_height = p_curr.y - ground_basin_y
			if col_height > 2.5:
				var fwd_dir = dense_points[i].get("forward", Vector3.FORWARD) as Vector3
				var w = float(dense_points[i].get("width", 16.0)) * 0.5

				var bent = Node3D.new()
				bent.position = Vector3(p_curr.x, ground_basin_y, p_curr.z)
				parent.add_child(bent)

				var beam = MeshInstance3D.new()
				var beam_box = BoxMesh.new()
				beam_box.size = Vector3(w * 2.2, 1.4, 2.6)
				beam.mesh = beam_box
				beam.material_override = steel_mat
				beam.position = Vector3(0, col_height - 0.7, 0)

				var look_target = bent.position + fwd_dir * 10.0
				if (look_target - bent.position).length_squared() > 0.01:
					bent.look_at(look_target, Vector3.UP)
				bent.add_child(beam)

				for col_side in [-1.0, 1.0]:
					var col = MeshInstance3D.new()
					var c_box = BoxMesh.new()
					c_box.size = Vector3(1.6, col_height - 1.4, 2.0)
					col.mesh = c_box
					col.material_override = concrete_mat
					col.position = Vector3(col_side * (w * 0.55), (col_height - 1.4) * 0.5, 0)
					bent.add_child(col)
