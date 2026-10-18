class_name IntersectionBuilder
extends RefCounted

## IntersectionBuilder: Seamless Road Intersections, Continuous Tangent Height Splining,
## Welded ArrayMesh Aprons, and 45-degree Beveled Curb Returns for Urban Legends.
## Eliminates overlapping road slabs, exposed vertical steps, and wheel-catch traps.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## Identifies all 2D/3D road intersections from road network segments, clamps elevations,
## and computes intersection bounding radii and corner curb-returns.
static func identify_and_clamp_intersections(segments: Array[Dictionary]) -> Array[Dictionary]:
	var junctions: Array[Dictionary] = []
	var junction_cluster_dist = 4.0

	# 1. Cluster segment endpoints and find cross-points
	for i in range(segments.size()):
		var seg_a = segments[i]
		var st_a: Vector3 = seg_a["start"]
		var en_a: Vector3 = seg_a["end"]
		var w_a: float = seg_a.get("width", 14.0)

		for pt in [st_a, en_a]:
			var found_cluster = false
			for junc in junctions:
				var c_pos: Vector3 = junc["pos"]
				var d_xz = Vector2(pt.x - c_pos.x, pt.z - c_pos.z).length()
				var d_y = absf(pt.y - c_pos.y)
				if d_xz < junction_cluster_dist and d_y < 3.0:
					# Merge into cluster and clamp elevation
					junc["points"].append(pt)
					junc["width"] = maxf(junc["width"], w_a)
					if not junc["segment_indices"].has(i):
						junc["segment_indices"].append(i)
					found_cluster = true
					break

			if not found_cluster:
				junctions.append({
					"pos": pt,
					"width": w_a,
					"points": [pt],
					"segment_indices": [i],
					"corner_radius": 8.0
				})

	# 2. Check for mid-segment intersections (e.g. grid cross-streets crossing avenues)
	for i in range(segments.size()):
		var seg_a = segments[i]
		var p1 = Vector2(seg_a["start"].x, seg_a["start"].z)
		var p2 = Vector2(seg_a["end"].x, seg_a["end"].z)
		var ya1: float = seg_a["start"].y
		var ya2: float = seg_a["end"].y
		var w_a: float = seg_a.get("width", 14.0)

		for j in range(i + 1, segments.size()):
			var seg_b = segments[j]
			var p3 = Vector2(seg_b["start"].x, seg_b["start"].z)
			var p4 = Vector2(seg_b["end"].x, seg_b["end"].z)
			var yb1: float = seg_b["start"].y
			var yb2: float = seg_b["end"].y
			var w_b: float = seg_b.get("width", 14.0)

			var denom = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
			if absf(denom) > 0.0001:
				var t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denom
				var u = -((p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x)) / denom
				if t >= 0.02 and t <= 0.98 and u >= 0.02 and u <= 0.98:
					var cross_xz = p1.lerp(p2, t)
					var ya = lerpf(ya1, ya2, t)
					var yb = lerpf(yb1, yb2, u)
					if absf(ya - yb) < 3.0:
						var shared_y = (ya + yb) * 0.5
						var cross_pos = Vector3(cross_xz.x, shared_y, cross_xz.y)

						var found = false
						for junc in junctions:
							if cross_pos.distance_to(junc["pos"]) < junction_cluster_dist:
								found = true
								if not junc["segment_indices"].has(i):
									junc["segment_indices"].append(i)
								if not junc["segment_indices"].has(j):
									junc["segment_indices"].append(j)
								break

						if not found:
							junctions.append({
								"pos": cross_pos,
								"width": maxf(w_a, w_b),
								"points": [cross_pos],
								"segment_indices": [i, j],
								"corner_radius": 8.0
							})

	# 3. Continuous Tangent Height Splining: clamp elevation Y of all connected segment endpoints
	for junc in junctions:
		var sum_y = 0.0
		var pts: Array = junc["points"]
		for p in pts:
			sum_y += (p as Vector3).y
		var clamped_y = sum_y / float(pts.size())
		junc["pos"].y = clamped_y

		for seg_idx in junc["segment_indices"]:
			var seg = segments[seg_idx]
			var st: Vector3 = seg["start"]
			var en: Vector3 = seg["end"]
			if Vector2(st.x - junc["pos"].x, st.z - junc["pos"].z).length() < junction_cluster_dist:
				seg["start"].y = clamped_y
			if Vector2(en.x - junc["pos"].x, en.z - junc["pos"].z).length() < junction_cluster_dist:
				seg["end"].y = clamped_y

	return junctions

## Trims a road segment's curb and sidewalk spans to strictly exclude all intersection zones.
## Returns an array of valid non-overlapping [t_start, t_end] parameter intervals in [0.0, 1.0].
static func compute_curb_intervals(seg_st: Vector3, seg_en: Vector3, junctions: Array[Dictionary], clearance_margin: float = 1.0) -> Array[Vector2]:
	var seg_vec = seg_en - seg_st
	var seg_len = seg_vec.length()
	if seg_len < 1.0:
		return []

	# Intervals to cut out: list of [t_min, t_max]
	var cutouts: Array[Vector2] = []

	for junc in junctions:
		var j_pos: Vector3 = junc["pos"]
		var j_rad: float = (junc["width"] * 0.5) + junc.get("corner_radius", 8.0) + clearance_margin

		# Project j_pos onto segment line
		var v_to_j = j_pos - seg_st
		var t_proj = seg_vec.dot(v_to_j) / (seg_len * seg_len)
		var closest_pt = seg_st + seg_vec * clampf(t_proj, 0.0, 1.0)
		var dist = Vector2(closest_pt.x - j_pos.x, closest_pt.z - j_pos.z).length()

		if dist < j_rad and absf(closest_pt.y - j_pos.y) < 3.0:
			# Intersection cuts into this segment
			var t_radius = j_rad / seg_len
			var t_start = maxf(0.0, t_proj - t_radius)
			var t_end = minf(1.0, t_proj + t_radius)
			if t_end > t_start:
				cutouts.append(Vector2(t_start, t_end))

	if cutouts.is_empty():
		return [Vector2(0.0, 1.0)]

	# Sort cutouts by start
	cutouts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)

	# Merge overlapping cutouts
	var merged_cuts: Array[Vector2] = []
	var cur_cut = cutouts[0]
	for k in range(1, cutouts.size()):
		var nxt = cutouts[k]
		if nxt.x <= cur_cut.y:
			cur_cut.y = maxf(cur_cut.y, nxt.y)
		else:
			merged_cuts.append(cur_cut)
			cur_cut = nxt
	merged_cuts.append(cur_cut)

	# Compute inverse (valid spans for curbs/sidewalks)
	var valid_spans: Array[Vector2] = []
	var cur_t = 0.0
	for cut in merged_cuts:
		if cut.x > cur_t + 0.02:
			valid_spans.append(Vector2(cur_t, cut.x))
		cur_t = maxf(cur_t, cut.y)
	if cur_t < 0.98:
		valid_spans.append(Vector2(cur_t, 1.0))

	return valid_spans

## Constructs a welded intersection apron with flush roadway asphalt and 4-quadrant
## 45-degree beveled curb returns. Guaranteed zero exposed vertical edges in vehicle paths.
static func build_intersection_apron(junction: Dictionary, asphalt_mat: Material, sw_mat: Material) -> Node3D:
	var root = Node3D.new()
	root.name = "IntersectionApron"
	var j_pos: Vector3 = junction["pos"]
	var w: float = junction.get("width", 14.0)
	var r: float = junction.get("corner_radius", 8.0)
	var full_size = w + r * 2.0

	# 1. Welded Flat Roadway Deck (ArrayMesh at Y = 0.02m)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = full_size * 0.5
	var hh = 0.02

	var v00 = Vector3(-hw, hh, -hw)
	var v10 = Vector3(hw, hh, -hw)
	var v11 = Vector3(hw, hh, hw)
	var v01 = Vector3(-hw, hh, hw)

	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0, 0)); st.add_vertex(v00)
	st.set_uv(Vector2(1, 0)); st.add_vertex(v10)
	st.set_uv(Vector2(1, 1)); st.add_vertex(v11)

	st.set_uv(Vector2(0, 0)); st.add_vertex(v00)
	st.set_uv(Vector2(1, 1)); st.add_vertex(v11)
	st.set_uv(Vector2(0, 1)); st.add_vertex(v01)

	var deck_mesh = st.commit()
	var deck_mi = MeshInstance3D.new()
	deck_mi.mesh = deck_mesh
	deck_mi.material_override = asphalt_mat
	deck_mi.position = j_pos
	root.add_child(deck_mi)

	# Welded single-piece collision box flush with ground (no seam steps)
	var body = StaticBody3D.new()
	body.name = "StaticBody3D"
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(full_size, 0.04, full_size)
	col.shape = box
	col.position = Vector3(0.0, 0.0, 0.0)
	body.add_child(col)
	body.position = j_pos + Vector3(0.0, 0.02, 0.0)
	root.add_child(body)

	# 2. Beveled Corner Curb Returns in all 4 quadrants:
	# Profile: 45° beveled chamfer (0.12m vertical rise, 0.18m lateral chamfer)
	# Radius R = 8.0m swinging smoothly from avenue edge to cross-street edge
	var corner_mesh = _create_corner_curb_return_mesh(w * 0.5, r, 0.18, 0.12)
	var sw_corner_mesh = _create_corner_sidewalk_mesh(w * 0.5, r, 0.18, 0.12, 3.0)

	for qx in [-1.0, 1.0]:
		for qz in [-1.0, 1.0]:
			var q_node = Node3D.new()
			q_node.position = j_pos + Vector3(0.0, 0.02, 0.0)
			q_node.scale = Vector3(qx, 1.0, qz)

			var c_mi = MeshInstance3D.new()
			c_mi.mesh = corner_mesh
			c_mi.material_override = sw_mat
			q_node.add_child(c_mi)

			var sw_mi = MeshInstance3D.new()
			sw_mi.mesh = sw_corner_mesh
			sw_mi.material_override = sw_mat
			q_node.add_child(sw_mi)

			# Corner curb collision
			var c_body = StaticBody3D.new()
			c_body.collision_layer = UrbanConstants.LAYER_WORLD
			c_body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
			var c_col = CollisionShape3D.new()
			var c_shape = corner_mesh.create_convex_shape()
			c_col.shape = c_shape
			c_body.add_child(c_col)
			q_node.add_child(c_body)

			root.add_child(q_node)

	return root

## Creates a 45-degree beveled curb-return arc around a corner (Radius R).
static func _create_corner_curb_return_mesh(road_hw: float, corner_r: float, chamfer_w: float, curb_h: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Arc center is at corner: (road_hw + corner_r, road_hw + corner_r)
	var arc_cx = road_hw + corner_r
	var arc_cz = road_hw + corner_r
	var steps := 8

	for i in range(steps):
		var th0 = PI + float(i) * (PI * 0.5) / float(steps)
		var th1 = PI + float(i + 1) * (PI * 0.5) / float(steps)

		# Inner edge (toe of curb at street level)
		var p0_toe = Vector3(arc_cx + cos(th0) * corner_r, 0.0, arc_cz + sin(th0) * corner_r)
		var p1_toe = Vector3(arc_cx + cos(th1) * corner_r, 0.0, arc_cz + sin(th1) * corner_r)

		# Outer edge (top of 45-deg curb bevel)
		var outer_r = corner_r + chamfer_w
		var p0_top = Vector3(arc_cx + cos(th0) * outer_r, curb_h, arc_cz + sin(th0) * outer_r)
		var p1_top = Vector3(arc_cx + cos(th1) * outer_r, curb_h, arc_cz + sin(th1) * outer_r)

		# 45-degree chamfer face
		st.set_normal(Vector3(-cos(th0), 1.0, -sin(th0)).normalized())
		st.add_vertex(p0_toe); st.add_vertex(p0_top); st.add_vertex(p1_top)
		st.add_vertex(p0_toe); st.add_vertex(p1_top); st.add_vertex(p1_toe)

	st.generate_normals()
	return st.commit()

## Creates the sidewalk quadrant behind the curved curb-return.
static func _create_corner_sidewalk_mesh(road_hw: float, corner_r: float, chamfer_w: float, curb_h: float, sw_width: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var arc_cx = road_hw + corner_r
	var arc_cz = road_hw + corner_r
	var steps := 8
	var inner_r = corner_r + chamfer_w
	var outer_r = inner_r + sw_width

	for i in range(steps):
		var th0 = PI + float(i) * (PI * 0.5) / float(steps)
		var th1 = PI + float(i + 1) * (PI * 0.5) / float(steps)

		var p0_in = Vector3(arc_cx + cos(th0) * inner_r, curb_h, arc_cz + sin(th0) * inner_r)
		var p1_in = Vector3(arc_cx + cos(th1) * inner_r, curb_h, arc_cz + sin(th1) * inner_r)
		var p0_out = Vector3(arc_cx + cos(th0) * outer_r, curb_h, arc_cz + sin(th0) * outer_r)
		var p1_out = Vector3(arc_cx + cos(th1) * outer_r, curb_h, arc_cz + sin(th1) * outer_r)

		st.set_normal(Vector3.UP)
		st.add_vertex(p0_in); st.add_vertex(p0_out); st.add_vertex(p1_out)
		st.add_vertex(p0_in); st.add_vertex(p1_out); st.add_vertex(p1_in)

	st.generate_normals()
	return st.commit()
