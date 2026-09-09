class_name RaceSpline
extends RefCounted

## RaceSpline: Single authoritative race-path representation for Drift Storm.
## All systems (track mesh generator, colliders, AI racing line, wrong-way detection,
## minimap, checkpoint sequencing, off-track detection, and respawn) consume this spline.

var curve: Curve3D
var track_width: float = 14.0
var track_length: float = 0.0
var is_closed: bool = true

# Dense pre-baked samples along the circuit (step size ~1.0m to 2.0m)
var samples: Array[Dictionary] = []
var sample_count: int = 0

# Checkpoint milestones: distances along spline
var checkpoint_distances: Array[float] = []
# Safe respawn points spaced along the circuit
var respawn_points: Array[Transform3D] = []

func _init(nodes: Array[Vector3] = [], width: float = 14.0) -> void:
	curve = Curve3D.new()
	track_width = width
	if not nodes.is_empty():
		build_from_nodes(nodes, width)

func build_from_nodes(nodes: Array[Vector3], width: float = 14.0) -> void:
	track_width = width
	curve.clear_points()
	samples.clear()
	checkpoint_distances.clear()
	respawn_points.clear()

	var n = nodes.size()
	if n < 3:
		return

	# Populate Curve3D with automatic smooth Catmull-Rom style tangents
	for i in range(n):
		var prev = nodes[(i - 1 + n) % n]
		var curr = nodes[i]
		var next = nodes[(i + 1) % n]
		var dir_in = (curr - prev).normalized()
		var dir_out = (next - curr).normalized()
		var tangent = (dir_in + dir_out).normalized()
		var handle_len = minf(curr.distance_to(prev), curr.distance_to(next)) * 0.35
		var in_handle = -tangent * handle_len
		var out_handle = tangent * handle_len
		curve.add_point(curr, in_handle, out_handle)

	# Close the loop by connecting end back to start with identical smooth tangents
	var dir_close_in = (nodes[0] - nodes[n - 1]).normalized()
	var dir_close_out = (nodes[1] - nodes[0]).normalized()
	var close_tangent = (dir_close_in + dir_close_out).normalized()
	var close_handle = minf(nodes[0].distance_to(nodes[n - 1]), nodes[0].distance_to(nodes[1])) * 0.35
	curve.set_point_in(0, -close_tangent * close_handle)
	curve.set_point_out(0, close_tangent * close_handle)
	curve.add_point(nodes[0], -close_tangent * close_handle, close_tangent * close_handle)

	curve.bake_interval = 1.0
	track_length = curve.get_baked_length()
	if track_length <= 0.1:
		track_length = 1.0

	# Bake dense samples along the curve
	var step = 1.5 # 1.5m sampling resolution
	sample_count = int(ceil(track_length / step))
	if sample_count < 10:
		sample_count = 10

	var half_w = track_width * 0.5
	for i in range(sample_count):
		var dist = (float(i) / float(sample_count)) * track_length
		var pos = curve.sample_baked(dist)
		var next_dist = fposmod(dist + 0.5, track_length)
		var next_pos = curve.sample_baked(next_dist)
		var tangent = (next_pos - pos).normalized()
		if tangent.length_squared() < 0.001 or dist >= track_length - 0.6:
			tangent = close_tangent

		var up = Vector3.UP
		# Banking/slope calculation: align up with normal if track climbs
		var binormal = tangent.cross(up).normalized()
		var normal = binormal.cross(tangent).normalized()

		var left_bound = pos - binormal * half_w
		var right_bound = pos + binormal * half_w

		var sample_data = {
			"dist": dist,
			"pos": pos,
			"tangent": tangent,
			"normal": normal,
			"binormal": binormal,
			"width": track_width,
			"left": left_bound,
			"right": right_bound
		}
		samples.append(sample_data)

		# Add respawn transform every ~25 meters
		if fmod(dist, 25.0) < step:
			var basis = Basis()
			basis.z = -tangent
			basis.y = normal
			basis.x = binormal
			var respawn_tr = Transform3D(basis.orthonormalized(), pos + normal * 0.35)
			respawn_points.append(respawn_tr)

	# Ensure at least start grid respawn point exists
	if respawn_points.is_empty() and not samples.is_empty():
		var s0 = samples[0]
		var basis0 = Basis()
		basis0.z = -s0["tangent"]
		basis0.y = s0["normal"]
		basis0.x = s0["binormal"]
		respawn_points.append(Transform3D(basis0.orthonormalized(), s0["pos"] + Vector3.UP * 0.35))

	# Pre-bake checkpoint distances at each authored node
	for node in nodes:
		var cp_dist = get_closest_distance(node)
		checkpoint_distances.append(cp_dist)

## Project a 3D position onto the spline and return cumulative distance s in [0, track_length]
func get_closest_distance(pos: Vector3) -> float:
	if samples.is_empty():
		return 0.0

	var best_dist = 0.0
	var min_sq = INF
	var best_idx = 0

	# Fast grid search
	for i in range(sample_count):
		var d_sq = (samples[i]["pos"] - pos).length_squared()
		if d_sq < min_sq:
			min_sq = d_sq
			best_idx = i
			best_dist = samples[i]["dist"]

	# Fine-tune between best_idx and neighbors with proper circular wrapping
	var prev_idx = posmod(best_idx - 1, sample_count)
	var next_idx = posmod(best_idx + 1, sample_count)
	var p_prev = samples[prev_idx]["pos"]
	var p_curr = samples[best_idx]["pos"]
	var p_next = samples[next_idx]["pos"]

	# Local line-segment projection
	var seg1 = p_curr - p_prev
	var seg2 = p_next - p_curr
	var l1_sq = seg1.length_squared()
	var l2_sq = seg2.length_squared()

	if l2_sq > 0.001:
		var t2 = clampf((pos - p_curr).dot(seg2) / l2_sq, 0.0, 1.0)
		var proj2 = p_curr + seg2 * t2
		if (pos - proj2).length_squared() < min_sq:
			var d_curr = samples[best_idx]["dist"]
			var d_next = samples[next_idx]["dist"]
			var delta_d = d_next - d_curr
			if delta_d < -track_length * 0.5:
				delta_d += track_length
			elif delta_d > track_length * 0.5:
				delta_d -= track_length
			return fposmod(d_curr + t2 * delta_d, track_length)

	if l1_sq > 0.001:
		var t1 = clampf((pos - p_prev).dot(seg1) / l1_sq, 0.0, 1.0)
		var proj1 = p_prev + seg1 * t1
		if (pos - proj1).length_squared() < min_sq:
			var d_prev = samples[prev_idx]["dist"]
			var d_curr = samples[best_idx]["dist"]
			var delta_d = d_curr - d_prev
			if delta_d < -track_length * 0.5:
				delta_d += track_length
			elif delta_d > track_length * 0.5:
				delta_d -= track_length
			return fposmod(d_prev + t1 * delta_d, track_length)

	return best_dist

## Sample spline at cumulative distance s in [0, track_length]
func sample_at_distance(s: float) -> Dictionary:
	if samples.is_empty():
		return {
			"dist": 0.0,
			"pos": Vector3.ZERO,
			"tangent": Vector3(0, 0, -1),
			"normal": Vector3.UP,
			"binormal": Vector3(1, 0, 0),
			"width": track_width,
			"left": Vector3(-track_width * 0.5, 0, 0),
			"right": Vector3(track_width * 0.5, 0, 0)
		}

	var wrapped_s = fposmod(s, track_length)
	var norm_idx = (wrapped_s / track_length) * float(sample_count)
	var idx0 = int(floor(norm_idx)) % sample_count
	var idx1 = (idx0 + 1) % sample_count
	var frac = norm_idx - float(idx0)

	var s0 = samples[idx0]
	var s1 = samples[idx1]

	var pos = s0["pos"].lerp(s1["pos"], frac)
	var tangent = (s0["tangent"].lerp(s1["tangent"], frac)).normalized()
	var normal = (s0["normal"].lerp(s1["normal"], frac)).normalized()
	var binormal = tangent.cross(normal).normalized()
	var half_w = track_width * 0.5

	return {
		"dist": wrapped_s,
		"pos": pos,
		"tangent": tangent,
		"normal": normal,
		"binormal": binormal,
		"width": track_width,
		"left": pos - binormal * half_w,
		"right": pos + binormal * half_w
	}

## Get the authoritative forward tangent vector at any 3D position
func get_tangent_at_pos(pos: Vector3) -> Vector3:
	var s = get_closest_distance(pos)
	return sample_at_distance(s)["tangent"]

## Get signed lateral offset from track centerline (+ = right, - = left)
func get_lateral_offset(pos: Vector3) -> float:
	var s = get_closest_distance(pos)
	var sample = sample_at_distance(s)
	var to_pos = pos - sample["pos"]
	to_pos.y = 0.0
	return to_pos.dot(sample["binormal"])

## Return true if 3D position is within valid track corridor (including optional runoff margin)
func is_point_on_track(pos: Vector3, extra_margin: float = 2.5) -> bool:
	var lat = absf(get_lateral_offset(pos))
	return lat <= (track_width * 0.5 + extra_margin)

## Get normalized lap progress [0.0, 1.0)
func get_progress(pos: Vector3) -> float:
	var s = get_closest_distance(pos)
	return s / track_length if track_length > 0.0 else 0.0

## Sample forward along the spline guaranteeing lookahead distance is strictly ahead in track flow
func sample_lookahead_forward(current_s: float, lookahead: float) -> Dictionary:
	var forward_s = current_s + maxf(lookahead, 1.0)
	return sample_at_distance(forward_s)

## Compute signed forward distance along closed track from s1 to s2 (positive = s2 is ahead)
func get_forward_delta(s1: float, s2: float) -> float:
	var delta = s2 - s1
	if delta < -track_length * 0.5:
		delta += track_length
	elif delta > track_length * 0.5:
		delta -= track_length
	return delta

## Generate authoritative 2D points for minimap display matching the exact racing line
func get_minimap_points(point_count: int = 64) -> PackedVector2Array:
	var pts = PackedVector2Array()
	if track_length <= 0.0 or sample_count == 0:
		return pts
	var step_d = track_length / float(point_count)
	for i in range(point_count):
		var d = float(i) * step_d
		var s_data = sample_at_distance(d)
		pts.append(Vector2(s_data["pos"].x, s_data["pos"].z))
	return pts

## Get closest safe respawn transform facing strictly forward along track flow
func get_safe_respawn_transform(pos: Vector3) -> Transform3D:
	if respawn_points.is_empty():
		var fallback_s = get_closest_distance(pos)
		var s_data = sample_at_distance(fallback_s)
		var basis = Basis()
		basis.z = -s_data["tangent"]
		basis.y = s_data["normal"]
		basis.x = s_data["binormal"]
		return Transform3D(basis.orthonormalized(), s_data["pos"] + Vector3.UP * 0.35)

	var best_tr = respawn_points[0]
	var min_d = INF
	for tr in respawn_points:
		var d = (tr.origin - pos).length_squared()
		if d < min_d:
			min_d = d
			best_tr = tr
	return best_tr

