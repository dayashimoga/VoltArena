class_name AeroTrackGenerator
extends RefCounted

## High-Performance Stunt Track & Disconnected Island Generator for AeroRush.
## Implements continuous Parallel Transport / Rotation Minimizing Frames (RMF/Bishop frame)
## to eliminate coordinate singularities across loops, corkscrews, and 75° wall rides.
## Generates genuinely disconnected physical platform islands with calculated ballistic air gaps,
## upward-curved launch kickers with glowing chevron arrows, wide landing aprons with hazard markings,
## speed boost pads, and structural concrete/steel support bents connecting to the ground basin.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroMovingPlatform = preload("res://games/aero-rush/tracks/aero_moving_platform.gd")

const TRACK_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 asphalt_color : source_color = vec4(0.24, 0.26, 0.30, 1.0);
uniform vec4 curb_color : source_color = vec4(1.0, 0.44, 0.08, 1.0);
uniform vec4 neon_left_color : source_color = vec4(0.05, 0.95, 1.0, 1.0);
uniform vec4 neon_right_color : source_color = vec4(1.0, 0.22, 0.70, 1.0);
uniform float roughness_val = 0.42;

void fragment() {
	float u = UV.x;
	bool is_border_left = (u < 0.045);
	bool is_border_right = (u > 0.955);
	bool is_barrier_face = ((u >= 0.045 && u < 0.095) || (u > 0.905 && u <= 0.955));
	bool is_curb = ((u >= 0.095 && u < 0.155) || (u > 0.845 && u <= 0.905));
	bool is_center_line = (abs(u - 0.5) < 0.016);
	bool is_tire_track = ((u >= 0.27 && u <= 0.37) || (u >= 0.63 && u <= 0.73));

	if (is_border_left) {
		// Glowing Cyan Left Guide Rail
		ALBEDO = neon_left_color.rgb;
		EMISSION = neon_left_color.rgb * 1.8;
		ROUGHNESS = 0.08;
		METALLIC = 0.75;
	} else if (is_border_right) {
		// Glowing Magenta Right Guide Rail
		ALBEDO = neon_right_color.rgb;
		EMISSION = neon_right_color.rgb * 1.8;
		ROUGHNESS = 0.08;
		METALLIC = 0.75;
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
		EMISSION = (stripe < 1.0) ? curb_color.rgb * 0.9 : vec3(0.20);
		ROUGHNESS = 0.32;
		METALLIC = 0.15;
	} else if (is_center_line) {
		// High-Speed Dashed Centerline
		float dash = mod(UV.y * 5.0, 2.0);
		if (dash < 1.0) {
			ALBEDO = vec3(1.0, 0.92, 0.15);
			EMISSION = vec3(1.0, 0.92, 0.15) * 1.2;
		} else {
			ALBEDO = asphalt_color.rgb;
		}
		ROUGHNESS = 0.42;
		METALLIC = 0.05;
	} else if (is_tire_track) {
		// High-Speed Rubberized Tire Wear Groove
		ALBEDO = vec3(0.16, 0.18, 0.21);
		ROUGHNESS = 0.38;
		METALLIC = 0.15;
		SPECULAR = 0.45;
	} else {
		// Premium High-Grip Asphalt Track Surface
		ALBEDO = asphalt_color.rgb;
		ROUGHNESS = roughness_val;
		METALLIC = 0.08;
		SPECULAR = 0.40;
	}
}
"""

const UNDERSIDE_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert;

void fragment() {
	// Structural Reinforced Steel / Concrete Deck Underside (Double-sided to prevent inverted black sky shards)
	ALBEDO = vec3(0.18, 0.20, 0.24);
	ROUGHNESS = 0.75;
	METALLIC = 0.45;
}
"""

const KICKER_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

uniform vec4 chevron_color : source_color = vec4(0.05, 0.95, 1.0, 1.0);

void fragment() {
	// Emissive directional launch chevrons (>>>)
	float v = mod(UV.y * 4.0 - TIME * 3.5, 1.0);
	float u_dist = abs(UV.x - 0.5) * 2.0;
	bool is_chevron = (v > 0.35 && v < 0.65 && u_dist < 0.85);

	if (is_chevron) {
		ALBEDO = chevron_color.rgb;
		EMISSION = chevron_color.rgb * 1.8;
		ROUGHNESS = 0.10;
		METALLIC = 0.80;
	} else {
		ALBEDO = vec3(0.14, 0.16, 0.20);
		ROUGHNESS = 0.55;
		METALLIC = 0.35;
	}
}
"""

const APRON_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	// Diagonal black/yellow landing hazard stripes
	float stripe = mod((UV.x + UV.y * 2.0) * 8.0, 2.0);
	if (stripe < 1.0) {
		ALBEDO = vec3(1.0, 0.85, 0.05);
		EMISSION = vec3(1.0, 0.85, 0.05) * 1.0;
	} else {
		ALBEDO = vec3(0.10, 0.11, 0.13);
	}
	ROUGHNESS = 0.45;
	METALLIC = 0.10;
}
"""

const BOOST_PAD_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	// High-tech animated directional energy chevrons pointing along driving direction
	vec2 uv_anim = vec2(UV.x, fract(UV.y * 3.0 - TIME * 3.5));
	float chevron = abs(uv_anim.x - 0.5) * 2.0;
	float arrow = step(chevron, 1.0 - uv_anim.y * 0.8) * step(0.15, uv_anim.y);

	float pulse = 0.5 + 0.5 * sin(TIME * 5.0 - UV.y * 10.0);
	vec3 base_col = vec3(0.04, 0.08, 0.16);
	vec3 neon_cyan = vec3(0.08, 0.85, 1.0);
	vec3 neon_gold = vec3(1.0, 0.82, 0.15);
	vec3 energy_col = mix(neon_cyan, neon_gold, pulse);

	vec3 col = mix(base_col, energy_col, arrow * 0.9 + 0.1);
	ALBEDO = col;
	// Controlled emission: crisp and luminous without blinding bloom blowout
	EMISSION = energy_col * (arrow * (1.6 + pulse * 0.6) + 0.25);
	ROUGHNESS = 0.25;
	METALLIC = 0.60;
}
"""

## Master track generator.
## Accepts an Array of waypoints OR a Course Definition Dictionary containing islands.
## Builds genuinely disconnected physical platform islands across 3D space with zero collision in air gaps.
static func generate_track(course_data: Variant, default_width: float = 16.0) -> Dictionary:
	var root = Node3D.new()
	root.name = "AeroTrackNetwork"

	var waypoints: Array = []
	var islands_spec: Array = []

	if course_data is Dictionary:
		if course_data.has("islands") and course_data["islands"] is Array and not course_data["islands"].is_empty():
			islands_spec = course_data["islands"]
		if course_data.has("waypoints") and course_data["waypoints"] is Array:
			waypoints = course_data["waypoints"]
	elif course_data is Array:
		waypoints = course_data

	# If no explicit islands spec provided, partition waypoints by is_jump_gap
	if islands_spec.is_empty():
		islands_spec = _partition_waypoints_into_islands(waypoints)

	if islands_spec.is_empty():
		return {"root": root, "dense_points": [], "total_length": 0.0, "islands": []}

	var all_dense_points: Array[Dictionary] = []
	var all_col_faces: PackedVector3Array = PackedVector3Array()
	var total_course_length: float = 0.0
	var island_nodes: Array[Node3D] = []
	var jump_gaps: Array[Dictionary] = []

	var track_mat = ShaderMaterial.new()
	var s_main = Shader.new()
	s_main.code = TRACK_SHADER_CODE
	track_mat.shader = s_main

	var under_mat = ShaderMaterial.new()
	var s_under = Shader.new()
	s_under.code = UNDERSIDE_SHADER_CODE
	under_mat.shader = s_under

	var kicker_mat = ShaderMaterial.new()
	var s_kick = Shader.new()
	s_kick.code = KICKER_SHADER_CODE
	kicker_mat.shader = s_kick

	var apron_mat = ShaderMaterial.new()
	var s_apr = Shader.new()
	s_apr.code = APRON_SHADER_CODE
	apron_mat.shader = s_apr

	var boost_mat = ShaderMaterial.new()
	var s_boost = Shader.new()
	s_boost.code = BOOST_PAD_SHADER_CODE
	boost_mat.shader = s_boost

	# Build each disconnected island as an independent physical entity
	for idx in range(islands_spec.size()):
		var island_def = islands_spec[idx] as Dictionary
		var i_wps = island_def.get("waypoints", []) as Array
		if i_wps.size() < 2:
			continue

		var island_root = Node3D.new()
		island_root.name = "TrackIsland_%d_%s" % [idx, island_def.get("id", "island")]
		root.add_child(island_root)
		island_nodes.append(island_root)

		# 1. Continuous RMF Spline Interpolation for THIS Island
		var dense = _interpolate_spline_points_rmf(i_wps, 2.5, default_width)
		if dense.size() < 2:
			continue

		# 2. Build 3D Mesh and Collision Faces for Island Driving Deck
		var surf_tool = SurfaceTool.new()
		surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

		var under_tool = SurfaceTool.new()
		under_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

		var island_col_faces = PackedVector3Array()
		var island_length = 0.0

		for s in range(dense.size() - 1):
			var p0 = dense[s]
			var p1 = dense[s + 1]

			var pos0: Vector3 = p0["pos"]
			var pos1: Vector3 = p1["pos"]
			var norm0: Vector3 = p0["normal"]
			var norm1: Vector3 = p1["normal"]
			var right0: Vector3 = p0["right"]
			var right1: Vector3 = p1["right"]
			var w0: float = p0.get("width", default_width) * 0.5
			var w1: float = p1.get("width", default_width) * 0.5

			var d_len = pos0.distance_to(pos1)
			island_length += d_len

			var v0_coord = (total_course_length + island_length) / 12.0
			var v1_coord = (total_course_length + island_length + d_len) / 12.0

			var b_height = 1.35
			var b_thick = 0.70
			var slab_depth = 0.65

			# Cross-Section Profile Slice 0:
			var v0_l_b_top = pos0 - right0 * (w0 + b_thick) + norm0 * b_height
			var v0_l_b_inner = pos0 - right0 * w0 + norm0 * (b_height * 0.85)
			var v0_l_curb = pos0 - right0 * (w0 * 0.86) + norm0 * 0.08
			var v0_center = pos0
			var v0_r_curb = pos0 + right0 * (w0 * 0.86) + norm0 * 0.08
			var v0_r_b_inner = pos0 + right0 * w0 + norm0 * (b_height * 0.85)
			var v0_r_b_top = pos0 + right0 * (w0 + b_thick) + norm0 * b_height

			# Cross-Section Profile Slice 1:
			var v1_l_b_top = pos1 - right1 * (w1 + b_thick) + norm1 * b_height
			var v1_l_b_inner = pos1 - right1 * w1 + norm1 * (b_height * 0.85)
			var v1_l_curb = pos1 - right1 * (w1 * 0.86) + norm1 * 0.08
			var v1_center = pos1
			var v1_r_curb = pos1 + right1 * (w1 * 0.86) + norm1 * 0.08
			var v1_r_b_inner = pos1 + right1 * w1 + norm1 * (b_height * 0.85)
			var v1_r_b_top = pos1 + right1 * (w1 + b_thick) + norm1 * b_height

			# Top Driving Surface Quads
			_add_quad(surf_tool, island_col_faces, v0_l_b_top, v0_l_b_inner, v1_l_b_inner, v1_l_b_top, 0.0, 0.08, v0_coord, v1_coord, norm0, norm1, true)
			_add_quad(surf_tool, island_col_faces, v0_l_b_inner, v0_l_curb, v1_l_curb, v1_l_b_inner, 0.08, 0.16, v0_coord, v1_coord, norm0, norm1, true)
			_add_quad(surf_tool, island_col_faces, v0_l_curb, v0_center, v1_center, v1_l_curb, 0.16, 0.50, v0_coord, v1_coord, norm0, norm1, true)
			_add_quad(surf_tool, island_col_faces, v0_center, v0_r_curb, v1_r_curb, v1_center, 0.50, 0.84, v0_coord, v1_coord, norm0, norm1, true)
			_add_quad(surf_tool, island_col_faces, v0_r_curb, v0_r_b_inner, v1_r_b_inner, v1_r_curb, 0.84, 0.92, v0_coord, v1_coord, norm0, norm1, true)
			_add_quad(surf_tool, island_col_faces, v0_r_b_inner, v0_r_b_top, v1_r_b_top, v1_r_b_inner, 0.92, 1.0, v0_coord, v1_coord, norm0, norm1, true)

			# Underside Slabs
			var v0_under_l = pos0 - right0 * (w0 + b_thick) - norm0 * slab_depth
			var v0_under_r = pos0 + right0 * (w0 + b_thick) - norm0 * slab_depth
			var v1_under_l = pos1 - right1 * (w1 + b_thick) - norm1 * slab_depth
			var v1_under_r = pos1 + right1 * (w1 + b_thick) - norm1 * slab_depth

			_add_quad(under_tool, null, v0_under_r, v0_under_l, v1_under_l, v1_under_r, 0.0, 1.0, v0_coord, v1_coord, -norm0, -norm1, false)
			_add_quad(under_tool, null, v0_l_b_top, v0_under_l, v1_under_l, v1_l_b_top, 0.0, 1.0, v0_coord, v1_coord, -right0, -right1, false)
			_add_quad(under_tool, null, v0_under_r, v0_r_b_top, v1_r_b_top, v1_under_r, 0.0, 1.0, v0_coord, v1_coord, right0, right1, false)

		total_course_length += island_length
		all_dense_points.append_array(dense)
		var is_moving = island_def.get("is_moving_platform", false)

		surf_tool.generate_normals()
		surf_tool.generate_tangents()
		var deck_mesh = surf_tool.commit()
		if deck_mesh and deck_mesh.get_surface_count() > 0:
			deck_mesh.surface_set_material(0, track_mat)

		var deck_inst = MeshInstance3D.new()
		deck_inst.name = "DeckMesh"
		deck_inst.mesh = deck_mesh

		under_tool.generate_normals()
		var u_mesh = under_tool.commit()
		if u_mesh and u_mesh.get_surface_count() > 0:
			u_mesh.surface_set_material(0, under_mat)

		var under_inst = MeshInstance3D.new()
		under_inst.name = "UndersideMesh"
		under_inst.mesh = u_mesh

		if is_moving:
			# Kinetic platform with active AnimatableBody3D physics
			var moving_body = AeroMovingPlatform.new()
			moving_body.name = "MovingPlatformBody"
			moving_body.movement_axis = island_def.get("movement_axis", Vector3(1.0, 0.0, 0.0))
			moving_body.movement_distance = float(island_def.get("movement_distance", 24.0))
			moving_body.movement_speed = float(island_def.get("movement_speed", 1.2))
			moving_body.is_rotating = island_def.get("is_rotating", false)
			moving_body.rotation_axis = island_def.get("rotation_axis", Vector3(0.0, 1.0, 0.0))
			moving_body.rotation_speed_deg = float(island_def.get("rotation_speed_deg", 18.0))
			island_root.add_child(moving_body)

			moving_body.add_child(deck_inst)
			moving_body.add_child(under_inst)

			var m_col_shape = CollisionShape3D.new()
			m_col_shape.name = "MovingIslandShape"
			var m_concave = ConcavePolygonShape3D.new()
			m_concave.set_faces(island_col_faces)
			m_col_shape.shape = m_concave
			moving_body.add_child(m_col_shape)
		else:
			all_col_faces.append_array(island_col_faces)
			island_root.add_child(deck_inst)
			island_root.add_child(under_inst)

			# Island-Specific Collision Body (Hierarchy representation; master_sb handles unified physics)
			var island_sb = StaticBody3D.new()
			island_sb.name = "IslandCollisionBody"
			island_sb.collision_layer = 0
			island_sb.collision_mask = 0

			var col_shape = CollisionShape3D.new()
			col_shape.name = "IslandShape"
			var concave_poly = ConcavePolygonShape3D.new()
			concave_poly.set_faces(island_col_faces)
			col_shape.shape = concave_poly
			island_sb.add_child(col_shape)
			island_root.add_child(island_sb)

		# 4. Optional Launch Ramp Kicker at Island Exit
		if island_def.get("has_launch_ramp", false) or (idx < islands_spec.size() - 1 and island_def.get("is_gap_exit", true)):
			var last_pt = dense[dense.size() - 1]
			var kicker_angle = float(island_def.get("launch_kicker_angle_deg", 18.0))
			var kicker_length = float(island_def.get("launch_kicker_length", 16.0))
			var kicker_node = _build_launch_kicker(last_pt, kicker_angle, kicker_length, kicker_mat)
			island_root.add_child(kicker_node)

			# Record gap data for validation
			if idx < islands_spec.size() - 1:
				var next_island_def = islands_spec[idx + 1] as Dictionary
				var next_wps = next_island_def.get("waypoints", []) as Array
				if not next_wps.is_empty():
					jump_gaps.append({
						"from_island_idx": idx,
						"to_island_idx": idx + 1,
						"launch_pos": last_pt["pos"],
						"launch_forward": last_pt["forward"],
						"launch_kicker_angle_deg": kicker_angle,
						"landing_pos": next_wps[0]["pos"],
						"landing_width": float(next_wps[0].get("width", default_width)),
						"jump_speed_min": float(island_def.get("jump_speed_min", 26.0)),
						"jump_speed_target": float(island_def.get("jump_speed_target", 36.0)),
						"jump_speed_max": float(island_def.get("jump_speed_max", 48.0))
					})

		# 5. Optional Landing Catch Apron at Island Entrance
		if island_def.get("has_landing_apron", false) or (idx > 0 and island_def.get("is_gap_entry", true)):
			var first_pt = dense[0]
			var apron_w = float(island_def.get("landing_apron_width", default_width * 1.35))
			var apron_node = _build_landing_apron(first_pt, apron_w, apron_mat)
			island_root.add_child(apron_node)

		# 6. Structural Pylons connecting elevated sections to ground
		if island_def.get("support_pillars", true):
			var pylons_container = Node3D.new()
			pylons_container.name = "SupportPylons"
			island_root.add_child(pylons_container)
			_generate_support_pylons(dense, pylons_container)

		# 7. Speed Boost Pads
		var boost_indices = island_def.get("speed_boost_pads", []) as Array
		for b_idx in boost_indices:
			var s_i: int
			if i_wps.size() > 1 and int(b_idx) < i_wps.size():
				s_i = int(round(float(b_idx) / float(i_wps.size() - 1) * float(dense.size() - 1)))
			else:
				s_i = mini(int(b_idx), dense.size() - 1)
			s_i = clampi(s_i, 0, dense.size() - 1)
			# Never place a boost pad on the starting grid (keep at least 15m / 6 samples clear of spawn)
			if idx == 0 and s_i < 6:
				s_i = mini(6, dense.size() - 1)
			if s_i >= 0 and s_i < dense.size():
				var b_node = _build_speed_boost_pad(dense[s_i], boost_mat)
				island_root.add_child(b_node)

	# Aggregate reference StaticBody and MeshInstance for legacy callers
	var master_sb = StaticBody3D.new()
	master_sb.name = "ContinuousConcaveShape"
	master_sb.collision_layer = AeroConstants.LAYER_WORLD
	master_sb.collision_mask = 0
	var master_shape = CollisionShape3D.new()
	master_shape.name = "ContinuousConcaveShape"
	var master_poly = ConcavePolygonShape3D.new()
	master_poly.set_faces(all_col_faces)
	master_shape.shape = master_poly
	master_sb.add_child(master_shape)
	root.add_child(master_sb)

	var master_mi = MeshInstance3D.new()
	master_mi.name = "TrackSurfaceMesh"
	if not island_nodes.is_empty():
		var first_deck = island_nodes[0].get_node_or_null("DeckMesh") as MeshInstance3D
		if first_deck and first_deck.mesh:
			master_mi.mesh = first_deck.mesh
		else:
			master_mi.mesh = ArrayMesh.new()
	else:
		master_mi.mesh = ArrayMesh.new()
	master_mi.visible = false
	root.add_child(master_mi)

	return {
		"root": root,
		"mesh_instance": master_mi,
		"static_body": master_sb,
		"dense_points": all_dense_points,
		"total_length": total_course_length,
		"islands": islands_spec,
		"island_nodes": island_nodes,
		"jump_gaps": jump_gaps
	}

## Launch Ramp Kicker with smooth upward curvature, emissive directional chevrons, and solid trimesh collision
static func _build_launch_kicker(last_pt: Dictionary, kicker_angle_deg: float, kicker_len: float, mat: Material) -> Node3D:
	var kicker = Node3D.new()
	kicker.name = "LaunchKickerRamp"

	var pos: Vector3 = last_pt["pos"]
	var fwd: Vector3 = last_pt["forward"]
	var right: Vector3 = last_pt["right"]
	var norm: Vector3 = last_pt["normal"]
	var w: float = float(last_pt.get("width", 18.0)) * 0.5

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var steps = 6
	var prev_p_l = pos - right * w
	var prev_p_r = pos + right * w
	var prev_norm = norm

	for s in range(1, steps + 1):
		var t = float(s) / float(steps)
		var angle_t = deg_to_rad(kicker_angle_deg) * (t * t) # Progressive quadratic curvature
		var lift = sin(angle_t) * (kicker_len * t)
		var step_pos = pos + fwd * (kicker_len * t) + norm * lift
		var cur_norm = (norm * cos(angle_t) + fwd * sin(angle_t)).normalized()

		var p_l = step_pos - right * w
		var p_r = step_pos + right * w

		# Quad
		st.set_uv(Vector2(0.0, float(s - 1) / float(steps)))
		st.set_normal(prev_norm)
		st.add_vertex(prev_p_l)

		st.set_uv(Vector2(1.0, float(s - 1) / float(steps)))
		st.set_normal(prev_norm)
		st.add_vertex(prev_p_r)

		st.set_uv(Vector2(1.0, float(s) / float(steps)))
		st.set_normal(cur_norm)
		st.add_vertex(p_r)

		st.set_uv(Vector2(0.0, float(s - 1) / float(steps)))
		st.set_normal(prev_norm)
		st.add_vertex(prev_p_l)

		st.set_uv(Vector2(1.0, float(s) / float(steps)))
		st.set_normal(cur_norm)
		st.add_vertex(p_r)

		st.set_uv(Vector2(0.0, float(s) / float(steps)))
		st.set_normal(cur_norm)
		st.add_vertex(p_l)

		prev_p_l = p_l
		prev_p_r = p_r
		prev_norm = cur_norm

	st.generate_normals()
	var mesh = st.commit()
	if mesh and mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, mat)

	var mi = MeshInstance3D.new()
	mi.name = "KickerMesh"
	mi.mesh = mesh
	kicker.add_child(mi)

	# Physical StaticBody3D collision surface for the launch kicker
	if mesh and mesh.get_surface_count() > 0:
		var kicker_sb = StaticBody3D.new()
		kicker_sb.name = "KickerCollisionBody"
		kicker_sb.collision_layer = AeroConstants.LAYER_WORLD
		kicker_sb.collision_mask = 0
		var k_col = CollisionShape3D.new()
		k_col.name = "KickerShape"
		var trimesh_s = mesh.create_trimesh_shape()
		if trimesh_s:
			k_col.shape = trimesh_s
			kicker_sb.add_child(k_col)
			kicker.add_child(kicker_sb)

	return kicker

## Landing Catch Apron with wide entrance, hazard striping, and solid trimesh collision
static func _build_landing_apron(first_pt: Dictionary, apron_w: float, mat: Material) -> Node3D:
	var apron = Node3D.new()
	apron.name = "LandingCatchApron"

	var pos: Vector3 = first_pt["pos"]
	var fwd: Vector3 = first_pt["forward"]
	var right: Vector3 = first_pt["right"]
	var norm: Vector3 = first_pt["normal"]
	var half_w = apron_w * 0.5
	var apron_len = 22.0

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Build a catch apron extending 22m back from entrance to safely catch incoming vehicles
	var entry_pos = pos - fwd * apron_len - norm * 1.5 # slight downward slant
	var p0_l = entry_pos - right * (half_w * 1.25)
	var p0_r = entry_pos + right * (half_w * 1.25)
	var p1_l = pos - right * half_w
	var p1_r = pos + right * half_w

	# Quad
	st.set_uv(Vector2(0, 0))
	st.set_normal(norm)
	st.add_vertex(p0_l)

	st.set_uv(Vector2(1, 0))
	st.set_normal(norm)
	st.add_vertex(p0_r)

	st.set_uv(Vector2(1, 1))
	st.set_normal(norm)
	st.add_vertex(p1_r)

	st.set_uv(Vector2(0, 0))
	st.set_normal(norm)
	st.add_vertex(p0_l)

	st.set_uv(Vector2(1, 1))
	st.set_normal(norm)
	st.add_vertex(p1_r)

	st.set_uv(Vector2(0, 1))
	st.set_normal(norm)
	st.add_vertex(p1_l)

	st.generate_normals()
	var mesh = st.commit()
	if mesh and mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, mat)

	var mi = MeshInstance3D.new()
	mi.name = "ApronMesh"
	mi.mesh = mesh
	apron.add_child(mi)

	# Physical StaticBody3D collision surface for the landing catch apron
	if mesh and mesh.get_surface_count() > 0:
		var apron_sb = StaticBody3D.new()
		apron_sb.name = "ApronCollisionBody"
		apron_sb.collision_layer = AeroConstants.LAYER_WORLD
		apron_sb.collision_mask = 0
		var a_col = CollisionShape3D.new()
		a_col.name = "ApronShape"
		var trimesh_s = mesh.create_trimesh_shape()
		if trimesh_s:
			a_col.shape = trimesh_s
			apron_sb.add_child(a_col)
			apron.add_child(apron_sb)

	# Catch barriers flanking apron with BoxShape3D collisions
	var barrier_mat = StandardMaterial3D.new()
	barrier_mat.albedo_color = Color(1.0, 0.45, 0.1)
	barrier_mat.metallic = 0.8
	barrier_mat.roughness = 0.2

	for b_side in [-1.0, 1.0]:
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.6, 2.2, apron_len)
		var b_mi = MeshInstance3D.new()
		b_mi.mesh = b_box
		b_mi.material_override = barrier_mat
		var b_pos = pos - fwd * (apron_len * 0.5) + right * (b_side * half_w * 1.1) + norm * 1.1
		b_mi.position = b_pos
		apron.add_child(b_mi)

		var b_sb = StaticBody3D.new()
		b_sb.name = "BarrierCol_%s" % ("L" if b_side < 0.0 else "R")
		b_sb.collision_layer = AeroConstants.LAYER_WORLD
		b_sb.collision_mask = 0
		b_sb.position = b_pos
		var b_col = CollisionShape3D.new()
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(0.6, 2.2, apron_len)
		b_col.shape = b_shape
		b_sb.add_child(b_col)
		apron.add_child(b_sb)

	return apron

## Speed Boost Pad emitting high-energy light pulse
static func _build_speed_boost_pad(pt: Dictionary, mat: Material) -> Node3D:
	var pad = Node3D.new()
	pad.name = "SpeedBoostPad"
	pad.position = pt["pos"] + pt["normal"] * 0.04

	var fwd: Vector3 = (pt["forward"] as Vector3).normalized()
	var right: Vector3 = (pt["right"] as Vector3).normalized()
	var norm: Vector3 = (pt["normal"] as Vector3).normalized()

	# PlaneMesh lies in XZ plane with normal +Y
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(6.5, 8.5)
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat

	# Orient flush on track deck facing along driving forward
	# Local X is across track (right), local Y is normal (up from road), local Z is -fwd
	mi.transform.basis = Basis(right, norm, -fwd)
	pad.add_child(mi)

	# Active Trigger Area for vehicle turbo propulsion
	var area = Area3D.new()
	area.name = "BoostTriggerArea"
	area.collision_layer = 0
	area.collision_mask = AeroConstants.LAYER_PLAYER | AeroConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(6.5, 1.4, 8.5)
	col.shape = b_shape
	col.position = Vector3(0, 0.7, 0)
	area.add_child(col)
	area.transform.basis = Basis(right, norm, -fwd)

	area.body_entered.connect(func(body: Node3D):
		if body.has_method("apply_boost_pad_impulse"):
			body.apply_boost_pad_impulse(22.0)
	)
	pad.add_child(area)

	return pad

static func _partition_waypoints_into_islands(wps: Array) -> Array[Dictionary]:
	var islands: Array[Dictionary] = []
	if wps.size() < 2:
		return islands

	var current_island_wps: Array = []
	var island_counter = 0

	for i in range(wps.size()):
		var wp = wps[i]
		current_island_wps.append(wp)
		var is_gap = bool(wp.get("is_jump_gap", false))

		if is_gap or i == wps.size() - 1:
			islands.append({
				"id": "island_%d" % island_counter,
				"name": "Stunt Island %d" % (island_counter + 1),
				"waypoints": current_island_wps.duplicate(),
				"has_launch_ramp": is_gap,
				"launch_kicker_angle_deg": float(wp.get("launch_kicker_angle_deg", 18.0)),
				"has_landing_apron": (island_counter > 0),
				"landing_apron_width": float(current_island_wps[0].get("width", 18.0)) * 1.35,
				"support_pillars": true
			})
			island_counter += 1
			current_island_wps.clear()

	return islands

static func _add_quad(
	st: SurfaceTool,
	col_faces: Variant,
	p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
	u0: float, u1: float, v0: float, v1: float,
	norm0: Vector3, norm1: Vector3,
	add_collision: bool = false
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

	# Robust Two-Sided Collision Triangles
	if add_collision and col_faces != null and col_faces is PackedVector3Array:
		col_faces.append(p0)
		col_faces.append(p1)
		col_faces.append(p2)
		col_faces.append(p0)
		col_faces.append(p2)
		col_faces.append(p3)

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
				"width": width
			})

	# Append final waypoint
	var last_wp = waypoints[count - 1]
	var l_pos = last_wp["pos"] as Vector3
	var l_fwd = (l_pos - waypoints[count - 2]["pos"] as Vector3).normalized()
	raw_samples.append({
		"pos": l_pos,
		"forward": l_fwd,
		"bank_deg": float(last_wp.get("bank_deg", 0.0)),
		"width": float(last_wp.get("width", default_width))
	})

	if raw_samples.is_empty():
		return result

	# Second pass: Compute Rotation Minimizing Frame (Bishop Frame) via parallel transport
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

		# Apply intentional banking rotation around forward tangent
		var final_right = current_right
		var final_norm = current_norm
		if absf(bank_deg) > 0.1:
			var bank_rad = deg_to_rad(bank_deg)
			var bank_quat = Quaternion(current_fwd, bank_rad)
			final_right = (bank_quat * current_right).normalized()
			final_norm = (bank_quat * current_norm).normalized()

		result.append({
			"pos": pos,
			"forward": current_fwd,
			"right": final_right,
			"normal": final_norm,
			"width": sample["width"]
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
		(2.0 * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3)) * t +
		(3.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3)) * t2
	)

static func _generate_support_pylons(dense_points: Array[Dictionary], parent: Node3D) -> void:
	if dense_points.size() < 6:
		return

	var pylon_spacing = 52.0
	var dist_accum = 0.0

	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.38, 0.40, 0.44)
	concrete_mat.metallic = 0.15
	concrete_mat.roughness = 0.85

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.20, 0.22, 0.26)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.30

	for i in range(2, dense_points.size() - 2):
		var p_prev = dense_points[i - 1]["pos"] as Vector3
		var p_curr = dense_points[i]["pos"] as Vector3
		var norm = (dense_points[i].get("normal", Vector3.UP) as Vector3).normalized()
		var fwd_dir = (dense_points[i].get("forward", Vector3.FORWARD) as Vector3).normalized()
		var w = float(dense_points[i].get("width", 16.0)) * 0.5
		dist_accum += p_prev.distance_to(p_curr)

		if dist_accum >= pylon_spacing:
			dist_accum = 0.0
			# Strictly omit pylons on wall-rides, inverted loops, steep banking, and kickers.
			# High-stunt zones are suspended magnetic platforms and must remain 100% collision-free.
			if norm.dot(Vector3.UP) < 0.82:
				continue

			var ground_basin_y = -6.5
			# Underside of road bed: 1.2m below driving deck surface along surface normal
			var deck_under_pos = p_curr - norm * 1.2
			var col_height = deck_under_pos.y - ground_basin_y

			# Only instantiate pylons if elevated between 2.5m and 45.0m above ground basin
			if col_height < 2.5 or col_height > 45.0:
				continue

			var bent = Node3D.new()
			bent.position = Vector3(p_curr.x, ground_basin_y, p_curr.z)
			parent.add_child(bent)

			# Horizontal steel cradle beam hugging the deck underside (below track surface)
			var beam = MeshInstance3D.new()
			var beam_box = BoxMesh.new()
			beam_box.size = Vector3(w * 1.85, 1.1, 2.2)
			beam.mesh = beam_box
			beam.material_override = steel_mat
			beam.position = Vector3(0, col_height - 0.55, 0)

			var fwd_h = Vector3(fwd_dir.x, 0, fwd_dir.z).normalized()
			if fwd_h.length_squared() > 0.01:
				var z_ax = -fwd_h
				var x_ax = Vector3.UP.cross(z_ax).normalized()
				var y_ax = z_ax.cross(x_ax).normalized()
				bent.transform.basis = Basis(x_ax, y_ax, z_ax)
			bent.add_child(beam)

			# Concrete support columns descending to the ground basin
			for col_side in [-1.0, 1.0]:
				var col = MeshInstance3D.new()
				var c_box = BoxMesh.new()
				var col_len = col_height - 1.1
				if col_len > 0.5:
					c_box.size = Vector3(1.4, col_len, 1.8)
					col.mesh = c_box
					col.material_override = concrete_mat
					col.position = Vector3(col_side * (w * 0.58), col_len * 0.5, 0)
					bent.add_child(col)

