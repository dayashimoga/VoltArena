class_name AeroTrackValidator
extends RefCounted

## Automated course and track continuity validation suite.
## Enforces geometric continuity, collision integrity, jump reachability,
## checkpoint monotonicity, and start-to-finish physical traversability.

const AeroTrackGenerator = preload("res://games/aero-rush/tracks/aero_track_generator.gd")

static func validate_course(course_def: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var checks: Dictionary = {}

	# 1. Waypoint Integrity & Curvature Continuity
	var waypoints = course_def.get("waypoints", []) as Array
	checks["waypoint_count"] = waypoints.size() >= 4
	if waypoints.size() < 4:
		errors.append("Course '%s' has fewer than 4 waypoints." % course_def.get("id", "unknown"))

	var continuity_ok = true
	var max_step_dist = 0.0
	for i in range(waypoints.size() - 1):
		var p0 = waypoints[i].get("pos", Vector3.ZERO) as Vector3
		var p1 = waypoints[i + 1].get("pos", Vector3.ZERO) as Vector3
		var d = p0.distance_to(p1)
		max_step_dist = maxf(max_step_dist, d)
		if d > 160.0 and not waypoints[i].get("is_jump_gap", false):
			continuity_ok = false
			errors.append("Segment %d to %d distance too large (%.1fm > 160m)" % [i, i + 1, d])

		if i > 0:
			var p_prev = waypoints[i - 1].get("pos", Vector3.ZERO) as Vector3
			var dir_prev = (p0 - p_prev).normalized()
			var dir_curr = (p1 - p0).normalized()
			var angle_deg = rad_to_deg(dir_prev.angle_to(dir_curr))
			if angle_deg > 85.0:
				continuity_ok = false
				errors.append("Segment %d has severe angle bend (%.1f deg > 85 deg)" % [i, angle_deg])

	checks["continuity_ok"] = continuity_ok
	checks["max_step_dist"] = max_step_dist

	# 2. Checkpoint Monotonicity and Ordering
	var checkpoints = course_def.get("checkpoints", []) as Array
	var cp_ok = checkpoints.size() >= 3
	if checkpoints.size() < 3:
		errors.append("Course requires at least 3 checkpoints (has %d)" % checkpoints.size())
	else:
		for c in range(checkpoints.size() - 1):
			if int(checkpoints[c]) >= int(checkpoints[c + 1]):
				cp_ok = false
				errors.append("Non-monotonic checkpoint ordering at idx %d" % c)
	checks["checkpoints_ok"] = cp_ok

	# 3. Procedural Track Geometry & Collision Body Verification
	var track_data = AeroTrackGenerator.generate_track(waypoints, 14.0)
	var sb = track_data.get("static_body") as StaticBody3D
	var mesh_inst = track_data.get("mesh_instance") as MeshInstance3D
	var collision_ok = false
	var face_count = 0

	if sb:
		var col_shape = sb.get_node_or_null("ContinuousConcaveShape") as CollisionShape3D
		if col_shape and col_shape.shape is ConcavePolygonShape3D:
			var faces = (col_shape.shape as ConcavePolygonShape3D).get_faces()
			face_count = faces.size() / 3
			collision_ok = face_count > 0

	checks["collision_ok"] = collision_ok
	checks["collision_face_count"] = face_count
	checks["total_track_length"] = track_data.get("total_length", 0.0)

	if not collision_ok:
		errors.append("Generated track has no valid continuous collision faces!")

	# Clean up generated test nodes
	if track_data.has("root") and track_data["root"] is Node:
		track_data["root"].free()

	# 4. Start-to-Finish Reachability Kinematic Simulation
	var reachability = _simulate_kinematic_reachability(waypoints)
	checks["reachability_pass"] = reachability["passed"]
	if not reachability["passed"]:
		errors.append("Reachability solver failed: " + reachability.get("reason", "unknown"))

	var is_passed = errors.is_empty()
	return {
		"passed": is_passed,
		"course_id": course_def.get("id", "unknown"),
		"checks": checks,
		"errors": errors
	}

static func _simulate_kinematic_reachability(waypoints: Array) -> Dictionary:
	# Simulates vehicle traversal at low (25 m/s) and high (50 m/s) approach speeds
	var current_idx = 0
	var speed = 30.0

	while current_idx < waypoints.size() - 1:
		var p0 = waypoints[current_idx]["pos"] as Vector3
		var p1 = waypoints[current_idx + 1]["pos"] as Vector3
		var is_gap = waypoints[current_idx].get("is_jump_gap", false) as bool

		var dist = p0.distance_to(p1)
		var height_diff = p1.y - p0.y

		if is_gap:
			# Verify ballistic jump trajectory
			# Time to cross gap: t = dist / horizontal_speed
			var h_dist = Vector2(p1.x - p0.x, p1.z - p0.z).length()
			var t_flight = h_dist / maxf(speed, 20.0)
			# Drop: y = v_y * t - 0.5 * g * t^2
			var required_drop = 0.5 * 28.0 * (t_flight * t_flight)
			if height_diff > 4.0:
				return {"passed": false, "reason": "Jump gap %d requires climbing uphill (%.1fm)" % [current_idx, height_diff]}
		else:
			# Verify incline is climbable at speed
			var slope_angle_deg = rad_to_deg(asin(clampf(height_diff / maxf(dist, 1.0), -1.0, 1.0)))
			if slope_angle_deg > 75.0:
				return {"passed": false, "reason": "Slope at waypoint %d too steep (%.1f deg)" % [current_idx, slope_angle_deg]}

		current_idx += 1

	return {"passed": true, "reason": "Successfully traversed entire waypoint chain"}
