class_name TrackRibbonBuilder
extends RefCounted

## TrackRibbonBuilder: Continuous Ribbon Extruded Track Generator & Unified Collision
## Implements Catmull-Rom interpolation with Rotation Minimizing Frames (Bishop frames)
## at maximum step length Δs <= 2.0m. Extrudes a welded 15.0m cross-section with 45° safety curbs,
## dual neon boundary glow ribbons (HDR 4.5), underside truss structure, support pylons every 45m,
## and a single unified ConcavePolygonShape3D collision mesh with zero seam catches.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

const ROAD_WIDTH: float = 15.0
const CURB_WIDTH: float = 0.8
const CURB_HEIGHT: float = 0.35
const NEON_WIDTH: float = 0.35
const MAX_STEP_LENGTH: float = 2.0
const PYLON_SPACING: float = 45.0
const HDR_NEON_INTENSITY: float = 4.5

const TRACK_PBR_SHADER: String = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.07, 0.08, 0.09, 1.0);
uniform vec4 neon_left_color : source_color = vec4(0.05, 0.95, 1.0, 1.0);
uniform vec4 neon_right_color : source_color = vec4(1.0, 0.20, 0.75, 1.0);
uniform vec4 chevron_yellow : source_color = vec4(1.0, 0.85, 0.05, 1.0);
uniform vec4 chevron_black : source_color = vec4(0.08, 0.08, 0.10, 1.0);

void fragment() {
	float u = UV.x;
	// Zones across track:
	// 0.000 - 0.025: Left Neon Glow Ribbon
	// 0.025 - 0.075: Left Curb 45° Chamfer (Yellow/Black Chevrons)
	// 0.075 - 0.925: Central Roadway (Dark Grooved Asphalt, 15m)
	// 0.925 - 0.975: Right Curb 45° Chamfer (Yellow/Black Chevrons)
	// 0.975 - 1.000: Right Neon Glow Ribbon

	bool is_neon_l = (u < 0.025);
	bool is_neon_r = (u > 0.975);
	bool is_curb_l = (u >= 0.025 && u < 0.075);
	bool is_curb_r = (u > 0.925 && u <= 0.975);
	bool is_center_line = (abs(u - 0.5) < 0.012);
	bool is_tire_groove = ((u >= 0.28 && u <= 0.38) || (u >= 0.62 && u <= 0.72));

	float groove = sin(u * 320.0) * 0.015;
	float aggregate = fract(sin(dot(floor(UV * vec2(120.0, 400.0)), vec2(12.9898, 78.233))) * 43758.5453) * 0.02;
	vec3 asphalt = asphalt_color.rgb + vec3(groove + aggregate);

	if (is_neon_l) {
		float pulse = 0.85 + 0.15 * sin(TIME * 4.0 - UV.y * 12.0);
		ALBEDO = neon_left_color.rgb;
		EMISSION = neon_left_color.rgb * (4.5 * pulse);
		ROUGHNESS = 0.05;
		METALLIC = 0.90;
	} else if (is_neon_r) {
		float pulse = 0.85 + 0.15 * cos(TIME * 4.0 - UV.y * 12.0);
		ALBEDO = neon_right_color.rgb;
		EMISSION = neon_right_color.rgb * (4.5 * pulse);
		ROUGHNESS = 0.05;
		METALLIC = 0.90;
	} else if (is_curb_l || is_curb_r) {
		// Alternating yellow/black chevron striping along curb
		float chevron = mod((UV.y * 4.0 + (is_curb_l ? u : -u) * 6.0), 2.0);
		if (chevron < 1.0) {
			ALBEDO = chevron_yellow.rgb;
			EMISSION = chevron_yellow.rgb * 1.5;
		} else {
			ALBEDO = chevron_black.rgb;
			EMISSION = vec3(0.0);
		}
		ROUGHNESS = 0.35;
		METALLIC = 0.20;
	} else if (is_center_line) {
		float dash = mod(UV.y * 6.0, 2.0);
		if (dash < 1.0) {
			ALBEDO = vec3(1.0, 0.90, 0.12);
			EMISSION = vec3(1.0, 0.90, 0.12) * 1.8;
		} else {
			ALBEDO = asphalt;
		}
		ROUGHNESS = 0.35;
		METALLIC = 0.05;
	} else if (is_tire_groove) {
		ALBEDO = asphalt * 0.75;
		ROUGHNESS = 0.30;
		METALLIC = 0.18;
		SPECULAR = 0.60;
	} else {
		ALBEDO = asphalt;
		ROUGHNESS = 0.40;
		METALLIC = 0.12;
		SPECULAR = 0.50;
	}
}
"""

const TRUSS_SHADER: String = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert;

void fragment() {
	// Underside steel space-frame truss
	vec2 uv_grid = fract(UV * vec2(8.0, 16.0));
	bool is_strut = (abs(uv_grid.x - uv_grid.y) < 0.12 || abs(uv_grid.x + uv_grid.y - 1.0) < 0.12 || uv_grid.x < 0.08 || uv_grid.y < 0.08);
	if (is_strut) {
		ALBEDO = vec3(0.24, 0.27, 0.32);
		METALLIC = 0.85;
		ROUGHNESS = 0.30;
	} else {
		ALBEDO = vec3(0.10, 0.11, 0.14);
		METALLIC = 0.60;
		ROUGHNESS = 0.70;
	}
}
"""

## Master Bishop frame ribbon generator.
## Takes waypoints, generates continuous Catmull-Rom curve with Bishop parallel transport,
## and extrudes welded roadway mesh, underside truss, support pylons, and unified collision shape.
static func build_track_ribbon(waypoints: Array, road_width: float = ROAD_WIDTH) -> Dictionary:
	var root = Node3D.new()
	root.name = "ContinuousTrackRibbon"

	if waypoints.size() < 2:
		return {"root": root, "collision_faces": PackedVector3Array(), "dense_frames": []}

	# 1. Compute Bishop frames (Rotation Minimizing Frames)
	var dense_frames: Array[Dictionary] = compute_bishop_frames(waypoints, MAX_STEP_LENGTH, road_width)
	if dense_frames.size() < 2:
		return {"root": root, "collision_faces": PackedVector3Array(), "dense_frames": []}

	# 2. Extrude continuous roadway surface and welded collision faces
	var road_surf_tool = SurfaceTool.new()
	road_surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var truss_tool = SurfaceTool.new()
	truss_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var collision_faces = PackedVector3Array()
	var total_length: float = 0.0

	var half_road = road_width * 0.5
	var curb_w = CURB_WIDTH
	var curb_h = CURB_HEIGHT
	var neon_w = NEON_WIDTH
	var half_total = half_road + curb_w + neon_w

	for i in range(dense_frames.size() - 1):
		var f0 = dense_frames[i]
		var f1 = dense_frames[i + 1]

		var p0: Vector3 = f0["pos"]
		var p1: Vector3 = f1["pos"]
		var n0: Vector3 = f0["normal"]
		var n1: Vector3 = f1["normal"]
		var r0: Vector3 = f0["right"]
		var r1: Vector3 = f1["right"]

		var seg_len = p0.distance_to(p1)
		var v0 = total_length / 10.0
		var v1 = (total_length + seg_len) / 10.0
		total_length += seg_len

		# Profile 0 Vertices:
		# Outer left neon edge
		var p0_neon_l = p0 - r0 * half_total
		# Inner left neon / outer curb top
		var p0_curb_l_top = p0 - r0 * (half_road + curb_w) + n0 * curb_h
		# Inner curb chamfer / road edge
		var p0_road_l = p0 - r0 * half_road
		# Centerline
		var p0_center = p0
		# Road right edge
		var p0_road_r = p0 + r0 * half_road
		# Outer curb top right
		var p0_curb_r_top = p0 + r0 * (half_road + curb_w) + n0 * curb_h
		# Outer right neon edge
		var p0_neon_r = p0 + r0 * half_total

		# Profile 1 Vertices:
		var p1_neon_l = p1 - r1 * half_total
		var p1_curb_l_top = p1 - r1 * (half_road + curb_w) + n1 * curb_h
		var p1_road_l = p1 - r1 * half_road
		var p1_center = p1
		var p1_road_r = p1 + r1 * half_road
		var p1_curb_r_top = p1 + r1 * (half_road + curb_w) + n1 * curb_h
		var p1_neon_r = p1 + r1 * half_total

		# Quads across cross-section:
		# 1. Left neon ribbon
		_add_ribbon_quad(road_surf_tool, null, p0_neon_l, p0_curb_l_top, p1_curb_l_top, p1_neon_l, 0.000, 0.025, v0, v1, n0, n1)
		# 2. Left 45° chamfered curb (includes collision)
		_add_ribbon_quad(road_surf_tool, collision_faces, p0_curb_l_top, p0_road_l, p1_road_l, p1_curb_l_top, 0.025, 0.075, v0, v1, n0, n1)
		# 3. Left roadway (includes collision)
		_add_ribbon_quad(road_surf_tool, collision_faces, p0_road_l, p0_center, p1_center, p1_road_l, 0.075, 0.500, v0, v1, n0, n1)
		# 4. Right roadway (includes collision)
		_add_ribbon_quad(road_surf_tool, collision_faces, p0_center, p0_road_r, p1_road_r, p1_center, 0.500, 0.925, v0, v1, n0, n1)
		# 5. Right 45° chamfered curb (includes collision)
		_add_ribbon_quad(road_surf_tool, collision_faces, p0_road_r, p0_curb_r_top, p1_curb_r_top, p1_road_r, 0.925, 0.975, v0, v1, n0, n1)
		# 6. Right neon ribbon
		_add_ribbon_quad(road_surf_tool, null, p0_curb_r_top, p0_neon_r, p1_neon_r, p1_curb_r_top, 0.975, 1.000, v0, v1, n0, n1)

		# Underside Space-Frame Truss Slab (1.2m depth)
		var truss_depth: float = 1.2
		var p0_under_l = p0 - r0 * half_total - n0 * truss_depth
		var p0_under_r = p0 + r0 * half_total - n0 * truss_depth
		var p1_under_l = p1 - r1 * half_total - n1 * truss_depth
		var p1_under_r = p1 + r1 * half_total - n1 * truss_depth

		_add_ribbon_quad(truss_tool, null, p0_under_r, p0_under_l, p1_under_l, p1_under_r, 0.0, 1.0, v0, v1, -n0, -n1)
		_add_ribbon_quad(truss_tool, null, p0_neon_l, p0_under_l, p1_under_l, p1_neon_l, 0.0, 1.0, v0, v1, -r0, -r1)
		_add_ribbon_quad(truss_tool, null, p0_under_r, p0_neon_r, p1_neon_r, p1_under_r, 0.0, 1.0, v0, v1, r0, r1)

	# 3. Create materials and commit meshes
	var road_mat = ShaderMaterial.new()
	var s_road = Shader.new()
	s_road.code = TRACK_PBR_SHADER
	road_mat.shader = s_road

	var truss_mat = ShaderMaterial.new()
	var s_truss = Shader.new()
	s_truss.code = TRUSS_SHADER
	truss_mat.shader = s_truss

	road_surf_tool.generate_normals()
	road_surf_tool.generate_tangents()
	var road_mesh = road_surf_tool.commit()
	if road_mesh and road_mesh.get_surface_count() > 0:
		road_mesh.surface_set_material(0, road_mat)

	var road_inst = MeshInstance3D.new()
	road_inst.name = "WeldedRoadDeckMesh"
	road_inst.mesh = road_mesh
	root.add_child(road_inst)

	truss_tool.generate_normals()
	var truss_mesh = truss_tool.commit()
	if truss_mesh and truss_mesh.get_surface_count() > 0:
		truss_mesh.surface_set_material(0, truss_mat)

	var truss_inst = MeshInstance3D.new()
	truss_inst.name = "SpaceFrameTrussMesh"
	truss_inst.mesh = truss_mesh
	root.add_child(truss_inst)

	# 4. Unified Single-Mesh Collision: zero seam catches, ConcavePolygonShape3D
	var static_body = StaticBody3D.new()
	static_body.name = "TrackUnifiedCollision"
	static_body.collision_layer = AeroConstants.LAYER_WORLD
	static_body.collision_mask = 0

	var col_shape = CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var concave_poly = ConcavePolygonShape3D.new()
	concave_poly.set_faces(collision_faces)
	col_shape.shape = concave_poly
	static_body.add_child(col_shape)
	root.add_child(static_body)

	# 5. Automated Support Pylons Anchored Every 45m
	var pylons_container = Node3D.new()
	pylons_container.name = "SupportPylons"
	root.add_child(pylons_container)
	_generate_support_pylons(dense_frames, pylons_container, half_total)

	return {
		"root": root,
		"collision_body": static_body,
		"collision_faces": collision_faces,
		"dense_frames": dense_frames,
		"total_length": total_length
	}

## Computes continuous Rotation Minimizing Frames (Bishop frames) along Catmull-Rom splines.
static func compute_bishop_frames(
	waypoints: Array,
	max_step_dist: float = MAX_STEP_LENGTH,
	default_width: float = ROAD_WIDTH
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count = waypoints.size()
	if count < 2:
		return result

	var raw_samples: Array[Dictionary] = []

	for i in range(count - 1):
		var wp_prev = waypoints[maxi(0, i - 1)]
		var wp_curr = waypoints[i]
		var wp_next = waypoints[i + 1]
		var wp_next2 = waypoints[mini(count - 1, i + 2)]

		var p_prev: Vector3 = wp_prev.get("pos", Vector3.ZERO) if wp_prev is Dictionary else (wp_prev if wp_prev is Vector3 else Vector3.ZERO)
		var p_curr: Vector3 = wp_curr.get("pos", Vector3.ZERO) if wp_curr is Dictionary else (wp_curr if wp_curr is Vector3 else Vector3.ZERO)
		var p_next: Vector3 = wp_next.get("pos", Vector3.ZERO) if wp_next is Dictionary else (wp_next if wp_next is Vector3 else Vector3.ZERO)
		var p_next2: Vector3 = wp_next2.get("pos", Vector3.ZERO) if wp_next2 is Dictionary else (wp_next2 if wp_next2 is Vector3 else Vector3.ZERO)

		var bank0 = float(wp_curr.get("bank_deg", 0.0)) if wp_curr is Dictionary else 0.0
		var bank1 = float(wp_next.get("bank_deg", 0.0)) if wp_next is Dictionary else 0.0
		var w0 = float(wp_curr.get("width", default_width)) if wp_curr is Dictionary else default_width
		var w1 = float(wp_next.get("width", default_width)) if wp_next is Dictionary else default_width

		var seg_len = p_curr.distance_to(p_next)
		var subdivisions = maxi(1, int(ceilf(seg_len / max_step_dist)))

		for s in range(subdivisions):
			var t = float(s) / float(subdivisions)
			var pos = _catmull_rom(p_prev, p_curr, p_next, p_next2, t)
			var forward = _catmull_rom_tangent(p_prev, p_curr, p_next, p_next2, t).normalized()
			if forward.length_squared() < 0.001:
				forward = (p_next - p_curr).normalized()

			raw_samples.append({
				"pos": pos,
				"forward": forward,
				"bank_deg": lerpf(bank0, bank1, t),
				"width": lerpf(w0, w1, t)
			})

	# Append final point
	var last_wp = waypoints[count - 1]
	var prev_to_last = waypoints[count - 2]
	var l_pos: Vector3 = last_wp.get("pos", Vector3.ZERO) if last_wp is Dictionary else (last_wp if last_wp is Vector3 else Vector3.ZERO)
	var prev_l_pos: Vector3 = prev_to_last.get("pos", Vector3.ZERO) if prev_to_last is Dictionary else (prev_to_last if prev_to_last is Vector3 else Vector3.ZERO)
	var l_fwd = (l_pos - prev_l_pos).normalized()
	raw_samples.append({
		"pos": l_pos,
		"forward": l_fwd,
		"bank_deg": float(last_wp.get("bank_deg", 0.0)) if last_wp is Dictionary else 0.0,
		"width": float(last_wp.get("width", default_width)) if last_wp is Dictionary else default_width
	})

	if raw_samples.is_empty():
		return result

	# Parallel Transport (Bishop Frame)
	var current_fwd = raw_samples[0]["forward"] as Vector3
	var current_right = Vector3.RIGHT
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
			var rot_axis = prev_fwd.cross(fwd)
			if rot_axis.length_squared() > 1e-6:
				var angle = prev_fwd.angle_to(fwd)
				var quat = Quaternion(rot_axis.normalized(), angle)
				current_right = (quat * current_right).normalized()
				current_norm = (quat * current_norm).normalized()

		current_fwd = fwd
		current_right = current_norm.cross(current_fwd).normalized()
		current_norm = current_fwd.cross(current_right).normalized()

		var final_right = current_right
		var final_norm = current_norm
		if absf(bank_deg) > 0.1:
			var bank_rad = deg_to_rad(bank_deg)
			var bank_quat = Quaternion(current_fwd, bank_rad)
			final_right = (bank_quat * current_right).normalized()
			final_norm = (bank_quat * current_norm).normalized()

		var frame_basis = Basis(final_right, final_norm, final_right.cross(final_norm)).orthonormalized()
		result.append({
			"pos": pos,
			"forward": current_fwd,
			"right": final_right,
			"normal": final_norm,
			"basis": frame_basis,
			"width": sample["width"]
		})

	return result

static func _add_ribbon_quad(
	st: SurfaceTool,
	col_faces: Variant,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	u0: float, u1: float, v0: float, v1: float,
	norm0: Vector3, norm1: Vector3
) -> void:
	# Triangle 1
	st.set_uv(Vector2(u0, v0))
	st.set_normal(norm0)
	st.add_vertex(p0)

	st.set_uv(Vector2(u1, v0))
	st.set_normal(norm0)
	st.add_vertex(p1)

	st.set_uv(Vector2(u1, v1))
	st.set_normal(norm1)
	st.add_vertex(p2)

	# Triangle 2
	st.set_uv(Vector2(u0, v0))
	st.set_normal(norm0)
	st.add_vertex(p0)

	st.set_uv(Vector2(u1, v1))
	st.set_normal(norm1)
	st.add_vertex(p2)

	st.set_uv(Vector2(u0, v1))
	st.set_normal(norm1)
	st.add_vertex(p3)

	if col_faces != null and col_faces is PackedVector3Array:
		col_faces.append(p0); col_faces.append(p1); col_faces.append(p2)
		col_faces.append(p0); col_faces.append(p2); col_faces.append(p3)
		# Two-sided collision prevents undercarriage snag
		col_faces.append(p0); col_faces.append(p2); col_faces.append(p1)
		col_faces.append(p0); col_faces.append(p3); col_faces.append(p2)

static func _generate_support_pylons(frames: Array[Dictionary], parent: Node3D, half_total_w: float) -> void:
	if frames.size() < 6:
		return

	var dist_accum: float = 0.0
	var ground_basin_y: float = -6.5

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.22, 0.25, 0.30)
	steel_mat.metallic = 0.88
	steel_mat.roughness = 0.28

	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.40, 0.42, 0.45)
	concrete_mat.metallic = 0.15
	concrete_mat.roughness = 0.85

	for i in range(2, frames.size() - 2):
		var p_prev = frames[i - 1]["pos"] as Vector3
		var p_curr = frames[i]["pos"] as Vector3
		var norm = (frames[i]["normal"] as Vector3).normalized()
		var fwd = (frames[i]["forward"] as Vector3).normalized()
		dist_accum += p_prev.distance_to(p_curr)

		if dist_accum >= PYLON_SPACING:
			dist_accum = 0.0
			# Only anchor on non-inverted and non-vertical track sections (upright deck)
			if norm.dot(Vector3.UP) < 0.78:
				continue

			var deck_under_y = p_curr.y - 1.2
			var col_height = deck_under_y - ground_basin_y
			if col_height < 3.0 or col_height > 60.0:
				continue

			var pylon = Node3D.new()
			pylon.position = Vector3(p_curr.x, ground_basin_y, p_curr.z)
			parent.add_child(pylon)

			# Horizontal steel support cradle
			var beam = MeshInstance3D.new()
			var beam_mesh = BoxMesh.new()
			beam_mesh.size = Vector3(half_total_w * 2.1, 1.2, 2.4)
			beam.mesh = beam_mesh
			beam.material_override = steel_mat
			beam.position = Vector3(0.0, col_height - 0.6, 0.0)
			pylon.add_child(beam)

			# Twin concrete support pillars anchored to ground
			for side in [-1.0, 1.0]:
				var col = MeshInstance3D.new()
				var col_mesh = BoxMesh.new()
				var col_len = col_height - 1.2
				col_mesh.size = Vector3(1.6, col_len, 2.0)
				col.mesh = col_mesh
				col.material_override = concrete_mat
				col.position = Vector3(side * (half_total_w * 0.62), col_len * 0.5, 0.0)
				pylon.add_child(col)

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
		(2.0 * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3)) * t +
		(3.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3)) * t2
	)
