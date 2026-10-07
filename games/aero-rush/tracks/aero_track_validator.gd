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
	# Simulates vehicle traversal across continuous segments and ballistic stunt gaps
	var current_idx = 0
	var default_speed = 32.0

	while current_idx < waypoints.size() - 1:
		var p0 = waypoints[current_idx]["pos"] as Vector3
		var p1 = waypoints[current_idx + 1]["pos"] as Vector3
		var is_gap = waypoints[current_idx].get("is_jump_gap", false) as bool

		var dist = p0.distance_to(p1)
		var height_diff = p1.y - p0.y

		if is_gap:
			# Extract launch direction from incoming segment
			var p_prev = waypoints[maxi(0, current_idx - 1)]["pos"] as Vector3
			var seg_fwd = (p0 - p_prev).normalized()
			if seg_fwd.length_squared() < 0.01:
				seg_fwd = (p1 - p0).normalized()
			# Launch ramp pitch elevation: add kicker only if incoming segment is relatively flat
			var launch_dir = seg_fwd
			if seg_fwd.y < 0.12:
				launch_dir = (seg_fwd + Vector3.UP * 0.22).normalized()
			else:
				launch_dir = seg_fwd.normalized()

			var landing_w = float(waypoints[current_idx + 1].get("width", 20.0))
			var landing_norm = Vector3.UP
			var bank_deg = float(waypoints[current_idx + 1].get("bank_deg", 0.0))
			if absf(bank_deg) > 1.0:
				landing_norm = Basis(Vector3.FORWARD, deg_to_rad(bank_deg)) * Vector3.UP

			var min_spd = float(waypoints[current_idx].get("jump_speed_min", 24.0))
			var tgt_spd = float(waypoints[current_idx].get("jump_speed_target", 34.0))
			var max_spd = float(waypoints[current_idx].get("jump_speed_max", 48.0))

			var jump_val = validate_jump_trajectory(
				p0, launch_dir, p1, landing_norm,
				landing_w, 40.0, min_spd, tgt_spd, max_spd
			)
			if not jump_val.get("reachable", false):
				return {"passed": false, "reason": "Jump gap %d failed trajectory validation: %s" % [current_idx, jump_val.get("reason", "unknown")]}
		else:
			# Verify continuous incline is climbable at speed
			var slope_angle_deg = rad_to_deg(asin(clampf(height_diff / maxf(dist, 1.0), -1.0, 1.0)))
			if slope_angle_deg > 75.0:
				return {"passed": false, "reason": "Slope at waypoint %d too steep (%.1f deg)" % [current_idx, slope_angle_deg]}

		current_idx += 1

	return {"passed": true, "reason": "Successfully traversed entire waypoint chain"}

## Automated Ballistic Trajectory Validator:
## Simulates projectile physics across representative minimum, target, and maximum speeds.
## Certifies launch velocity, trajectory, landing orientation, landing width, and recovery margins.
static func validate_jump_trajectory(
	launch_pos: Vector3,
	launch_dir: Vector3,
	landing_pos: Vector3,
	landing_normal: Vector3,
	landing_width: float,
	landing_length: float,
	min_speed: float = 24.0,
	target_speed: float = 34.0,
	max_speed: float = 48.0
) -> Dictionary:
	var speeds = [min_speed, target_speed, max_speed]
	var gravity = Vector3(0, -28.0, 0)
	var dt = 0.005 # 200 Hz integration step for precision
	var max_sim_time = 4.0

	for spd in speeds:
		var pos = launch_pos
		var vel = launch_dir.normalized() * spd
		var sim_time = 0.0
		var landed = false
		var impact_pos = Vector3.ZERO
		var impact_vel = Vector3.ZERO

		while sim_time < max_sim_time:
			vel += gravity * dt
			vel *= 0.999 # Aerodynamic resistance
			pos += vel * dt
			sim_time += dt

			var to_landing = pos - landing_pos
			var plane_dist = to_landing.dot(landing_normal)
			if plane_dist <= 0.25 and sim_time > 0.12:
				landed = true
				impact_pos = pos
				impact_vel = vel
				break

		if not landed:
			return {
				"reachable": false,
				"reason": "Trajectory at speed %.1f m/s failed to reach landing deck within %.1fs." % [spd, max_sim_time]
			}

		var fwd_landing = (landing_pos - launch_pos).normalized()
		fwd_landing.y = 0.0
		if fwd_landing.length_squared() < 0.01:
			fwd_landing = Vector3.FORWARD
		else:
			fwd_landing = fwd_landing.normalized()

		var right_landing = fwd_landing.cross(landing_normal).normalized()
		var lateral_offset = absf((impact_pos - landing_pos).dot(right_landing))
		var longitudinal_offset = absf((impact_pos - landing_pos).dot(fwd_landing))

		var max_lateral = landing_width * 0.50
		if lateral_offset > max_lateral:
			return {
				"reachable": false,
				"reason": "Trajectory at speed %.1f m/s lateral offset %.1fm exceeds deck half-width %.1fm." % [spd, lateral_offset, max_lateral]
			}

		var fwd_offset = (impact_pos - landing_pos).dot(fwd_landing)
		var max_undershoot = 8.0 # Flared apron catch margin
		var max_overshoot = landing_length * 0.85 # Receiver deck runway
		if fwd_offset < -max_undershoot:
			return {
				"reachable": false,
				"reason": "Trajectory at speed %.1f m/s landed %.1fm short of deck." % [spd, absf(fwd_offset)]
			}
		if fwd_offset > max_overshoot:
			return {
				"reachable": false,
				"reason": "Trajectory at speed %.1f m/s overshot deck by %.1fm." % [spd, fwd_offset - max_overshoot]
			}

	return {
		"reachable": true,
		"reason": "Jump trajectory certified across min (%.1fm/s), target (%.1fm/s), and max (%.1fm/s) speeds." % [min_speed, target_speed, max_speed]
	}

static func validate_before_launch(course_def: Dictionary) -> Dictionary:
	if course_def.is_empty():
		return {"valid": false, "reason": "Empty course definition dictionary."}

	var waypoints = course_def.get("waypoints", []) as Array
	if waypoints.size() < 4:
		return {"valid": false, "reason": "Course has fewer than 4 waypoints (%d provided)." % waypoints.size()}

	if not course_def.has("spawn_pos"):
		return {"valid": false, "reason": "Missing spawn_pos coordinate."}

	var checkpoints = course_def.get("checkpoints", []) as Array
	if checkpoints.size() < 2:
		return {"valid": false, "reason": "Course requires at least start and finish checkpoints."}

	# Verify drivable surface generation produces valid collision geometry
	var track_data = AeroTrackGenerator.generate_track(waypoints, 16.0)
	var sb = track_data.get("static_body") as StaticBody3D
	var has_col = false
	if sb:
		var cs = sb.get_node_or_null("ContinuousConcaveShape") as CollisionShape3D
		if cs and cs.shape is ConcavePolygonShape3D:
			has_col = (cs.shape as ConcavePolygonShape3D).get_faces().size() > 0

	if track_data.has("root") and track_data["root"] is Node:
		track_data["root"].free()

	if not has_col:
		return {"valid": false, "reason": "Track generation failed to produce non-empty collision hull."}

	return {"valid": true, "reason": "Circuit passed all pre-launch physical and structural gates."}
