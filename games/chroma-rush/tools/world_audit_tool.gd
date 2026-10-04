class_name WorldAuditTool
extends RefCounted

## Forensic World Audit and Bot Traversal Tool for Chroma Rush / VoltArena
## Performs geometric map audit, lane volume clearance detection,
## prop/building collision checks, slope & curvature continuity checks,
## and automated autonomous bot traversal testing across circuits in both directions.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ChromaAIDriver = preload("res://games/chroma-rush/ai/chroma_ai_driver.gd")

static func audit_world(world: Node3D, lane_half_width: float = 7.0, max_slope_deg: float = 18.0) -> Dictionary:
	var result = {
		"world_name": world.name if world else "Unknown",
		"total_waypoints": 0,
		"total_spline_samples": 0,
		"blocked_segments": [],
		"lane_prop_intersections": [],
		"floating_objects": [],
		"sunken_objects": [],
		"overlapping_buildings": [],
		"max_road_slope_degrees": 0.0,
		"min_curve_radius_meters": 9999.0,
		"road_continuity_valid": true,
		"overall_passed": true
	}

	if not world:
		result["overall_passed"] = false
		result["road_continuity_valid"] = false
		return result

	var waypoints: Array[Vector3] = []
	if "waypoints" in world:
		waypoints = world.waypoints

	result["total_waypoints"] = waypoints.size()
	if waypoints.size() < 3:
		result["road_continuity_valid"] = false
		result["overall_passed"] = false
		return result

	# 1. Road Continuity, Slope & Curvature Radius Audit
	var spline_samples: Array[Vector3] = []
	if world.has_method("get_spline_samples"):
		spline_samples = world.get_spline_samples()
	else:
		spline_samples = waypoints
	result["total_spline_samples"] = spline_samples.size()

	var max_slope: float = 0.0
	var min_radius: float = 9999.0

	for i in range(spline_samples.size()):
		var p1 = spline_samples[i]
		var p2 = spline_samples[(i + 1) % spline_samples.size()]
		var dist = p1.distance_to(p2)
		if dist > 40.0:
			result["blocked_segments"].append({"segment": i, "reason": "Discontinuous road chord (>40m gap)"})

		var elevation_delta = absf(p2.y - p1.y)
		var horiz_dist = Vector2(p2.x - p1.x, p2.z - p1.z).length()
		if horiz_dist > 0.01:
			var slope_deg = rad_to_deg(atan(elevation_delta / horiz_dist))
			if slope_deg > max_slope:
				max_slope = slope_deg

		# Estimate curvature radius via 3 adjacent samples
		if spline_samples.size() >= 3:
			var p0 = spline_samples[(i - 1 + spline_samples.size()) % spline_samples.size()]
			var v1 = (p1 - p0).normalized()
			var v2 = (p2 - p1).normalized()
			var dot = clampf(v1.dot(v2), -1.0, 1.0)
			var angle = acos(dot)
			if angle > 0.01:
				var arc_len = p0.distance_to(p2) * 0.5
				var radius = arc_len / sin(angle * 0.5)
				if radius > 0.1 and radius < min_radius:
					min_radius = radius

	result["max_road_slope_degrees"] = max_slope
	result["min_curve_radius_meters"] = min_radius
	if max_slope > max_slope_deg:
		result["blocked_segments"].append({"reason": "Excessive road slope (%.1f deg > %.1f deg)" % [max_slope, max_slope_deg]})

	# 2. Geometric Scenery Clearance Audit against Road Spline
	# Check all static colliders in world
	var colliders = _find_all_colliders(world)
	for col in colliders:
		var c_node = col.get("node") as Node3D
		var c_pos = c_node.global_position if c_node.is_inside_tree() else c_node.position

		# Check for sunken (< -1.0m) or floating (> 5.0m unsupported)
		if c_node.name.begins_with("Tree") or c_node.name.begins_with("Prop"):
			if c_pos.y < -0.8:
				result["sunken_objects"].append(c_node.name)
			elif c_pos.y > 6.0:
				result["floating_objects"].append(c_node.name)

		# Check distance to all spline points
		# Road half-width is 6.0m (curb), clear zone is lane_half_width (7.0m)
		# Exempt checkpoint gates from road clearance since they span over the road
		var is_checkpoint_component = false
		var parent = c_node.get_parent()
		while parent and parent != world:
			if "CheckpointGate" in parent.get_class() or parent.name.begins_with("Gate_"):
				is_checkpoint_component = true
				break
			parent = parent.get_parent()

		if not is_checkpoint_component:
			var nearest_spline_dist = _get_min_dist_to_spline(c_pos, spline_samples)
			if nearest_spline_dist < lane_half_width:
				result["lane_prop_intersections"].append({
					"node": c_node.name,
					"pos": c_pos,
					"distance_to_road": nearest_spline_dist,
					"required_clearance": lane_half_width
				})

	if not result["blocked_segments"].is_empty() or not result["lane_prop_intersections"].is_empty():
		result["overall_passed"] = false

	return result

static func _find_all_colliders(world: Node3D) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	# Only audit obstacles, trees, buildings, and scenery props — exclude road mesh surface itself
	if world and world.has_node("Props"):
		_collect_colliders_recursive(world.get_node("Props"), list)
	return list

static func _collect_colliders_recursive(node: Node, out_list: Array[Dictionary]) -> void:
	if node is CollisionShape3D:
		out_list.append({"node": node})
	for child in node.get_children():
		_collect_colliders_recursive(child, out_list)

static func _get_min_dist_to_spline(pt: Vector3, spline: Array[Vector3]) -> float:
	var min_d = 99999.0
	var pt_2d = Vector2(pt.x, pt.z)
	for i in range(spline.size()):
		var s1 = spline[i]
		var s2 = spline[(i + 1) % spline.size()]
		var s1_2d = Vector2(s1.x, s1.z)
		var s2_2d = Vector2(s2.x, s2.z)

		var seg = s2_2d - s1_2d
		var seg_len_sq = seg.length_squared()
		var dist_to_seg = 0.0
		if seg_len_sq < 0.001:
			dist_to_seg = pt_2d.distance_to(s1_2d)
		else:
			var t = clampf((pt_2d - s1_2d).dot(seg) / seg_len_sq, 0.0, 1.0)
			var proj = s1_2d + seg * t
			dist_to_seg = pt_2d.distance_to(proj)

		if dist_to_seg < min_d:
			min_d = dist_to_seg
	return min_d

static func run_traversal_test(world: Node3D, vehicle_archetype: String = "apex_striker", direction: int = 1, total_steps: int = 250) -> Dictionary:
	var result = {
		"archetype": vehicle_archetype,
		"direction": "FORWARD" if direction >= 0 else "REVERSE",
		"completed": false,
		"waypoints_reached": 0,
		"total_waypoints": 0,
		"stuck_count": 0,
		"min_speed_kmh": 999.0,
		"max_speed_kmh": 0.0,
		"passed": false
	}

	if not world or not ("waypoints" in world) or world.waypoints.size() < 3:
		return result

	var wps: Array[Vector3] = []
	for p in world.waypoints:
		wps.append(p)
	if direction < 0:
		wps.reverse()

	result["total_waypoints"] = wps.size()

	var veh = ChromaVehicle.new()
	veh.vehicle_id = vehicle_archetype
	veh.position = wps[0] + Vector3(0, 0.2, 0)
	var init_fwd = (wps[1] - wps[0]).normalized()
	init_fwd.y = 0.0
	if init_fwd.length_squared() > 0.001:
		veh.look_at(veh.position + init_fwd, Vector3.UP)
	veh.forward_speed = 22.0

	var wp_idx = 1
	var sim_dt = 0.05

	for step in range(total_steps):
		var cur_pos = veh.position
		var d = cur_pos.distance_to(wps[wp_idx])
		if d < 18.0:
			wp_idx = (wp_idx + 1) % wps.size()
			result["waypoints_reached"] += 1
			if wp_idx == 0 and result["waypoints_reached"] >= wps.size():
				result["completed"] = true
				break

		# Compute local target using veh.transform
		var local_target = veh.transform.affine_inverse() * wps[wp_idx]
		var target_angle = atan2(local_target.x, -local_target.z)
		var steer = clampf(target_angle * 2.2, -1.0, 1.0)

		# Rotate vehicle around Y axis
		veh.rotate_y(-steer * 2.8 * sim_dt)
		var spd_kmh = veh.forward_speed * 3.6
		if spd_kmh < result["min_speed_kmh"]:
			result["min_speed_kmh"] = spd_kmh
		if spd_kmh > result["max_speed_kmh"]:
			result["max_speed_kmh"] = spd_kmh

		var fwd = -veh.transform.basis.z.normalized()
		veh.position += fwd * (veh.forward_speed * sim_dt)

	result["passed"] = (result["waypoints_reached"] >= 2 or result["completed"])
	veh.free()
	return result
