class_name KartAI
extends Node

## KartAI: Autonomous racing driver utilizing authoritative RaceSpline.
## Features lookahead spline targeting, curvature-based speed control,
## dynamic overtaking, and stuck-recovery state machine.

@export var kart: KartController
@export var waypoints: Array[Vector3] = []
@export var current_waypoint_index: int = 1

@export var lane_offset: float = 0.0 # Lateral offset from centerline (-2.8 to +2.8m)
var dynamic_overtake_offset: float = 0.0

var stuck_timer: float = 0.0
var reverse_timer: float = 0.0
var race_active_time: float = 0.0

func _ready() -> void:
	if not kart:
		kart = get_parent() as KartController
	if kart:
		kart.is_player = false

func _physics_process(delta: float) -> void:
	if not kart or not is_instance_valid(kart) or kart.race_finished:
		return

	# Hold at start grid during countdown
	var rm = _get_race_manager()
	if rm and rm.get("current_state") == 0: # RaceState.COUNTDOWN
		kart.apply_kart_controls(0.0, 0.0, false, delta)
		stuck_timer = 0.0
		reverse_timer = 0.0
		race_active_time = 0.0
		return

	race_active_time += delta

	var spline = _get_race_spline()
	if spline and spline.samples.size() >= 3:
		_process_spline_driving(spline, delta)
	else:
		_process_waypoint_driving(delta)

func _process_spline_driving(spline: RefCounted, delta: float) -> void:
	var kart_pos = kart.global_position if kart.is_inside_tree() else kart.position
	var k_basis = kart.global_transform.basis if kart.is_inside_tree() else kart.transform.basis
	var fwd = -k_basis.z; fwd.y = 0.0; fwd = fwd.normalized()
	var right = k_basis.x; right.y = 0.0; right = right.normalized()

	# Current spline progress
	var current_s = spline.get_closest_distance(kart_pos)

	# Dynamic lookahead based on speed (10m to 26m ahead)
	var lookahead = clampf(kart.forward_speed * 0.75 + 11.0, 10.0, 26.0)
	var target_s = current_s + lookahead
	var target_data = spline.sample_at_distance(target_s)

	# Lateral lane offset + dynamic overtaking
	var total_offset = clampf(lane_offset + dynamic_overtake_offset, -3.2, 3.2)
	var target_pos = target_data["pos"] + target_data["binormal"] * total_offset

	var to_target = target_pos - kart_pos
	to_target.y = 0.0
	var dir_to_target = to_target.normalized()
	var dot_right = right.dot(dir_to_target)
	var dot_fwd = fwd.dot(dir_to_target)

	# Multi-tier stuck watchdog unjamming logic:
	if kart.forward_speed < 1.5 and race_active_time >= 1.5:
		stuck_timer += delta
		if stuck_timer > 3.0:
			kart.recover_to_checkpoint()
			stuck_timer = 0.0
			reverse_timer = 0.0
		elif stuck_timer > 0.8 and reverse_timer <= 0.0:
			reverse_timer = 0.6
	else:
		stuck_timer = maxf(0.0, stuck_timer - delta * 2.0)

	if reverse_timer > 0.0:
		reverse_timer -= delta
		kart.apply_kart_controls(-0.85, signf(dot_right) if abs(dot_right) > 0.1 else -1.0, false, delta)
		return

	# Curvature Look-Ahead for speed management
	var near_data = spline.sample_at_distance(current_s + 8.0)
	var far_data = spline.sample_at_distance(current_s + 24.0)
	var corner_angle = absf(near_data["tangent"].angle_to(far_data["tangent"]))

	# Steering: negative steer turns right, positive steer turns left
	var steer_input = -clampf(dot_right * 2.4, -1.0, 1.0)
	var throttle_input = 1.0

	# Cornering target speed
	var corner_target_speed = kart.base_speed
	if corner_angle > 0.30:
		corner_target_speed = kart.base_speed * clampf(1.0 - corner_angle * 0.55, 0.45, 0.90)

	if kart.forward_speed > corner_target_speed + 2.0:
		throttle_input = -0.35 # Trail-braking into sharp corners
	elif absf(dot_right) > 0.45:
		throttle_input = 0.72
	elif absf(dot_right) > 0.25:
		throttle_input = 0.88

	# Overtaking and opponent avoidance
	dynamic_overtake_offset = move_toward(dynamic_overtake_offset, 0.0, delta * 0.8)
	var avoidance_steer = 0.0
	if race_active_time > 2.0 and is_inside_tree():
		var all_karts = get_tree().get_nodes_in_group("karts")
		for other in all_karts:
			if other == kart or not is_instance_valid(other):
				continue
			var o_pos = other.global_position if other.is_inside_tree() else other.position
			var to_other = o_pos - kart_pos
			to_other.y = 0.0
			var other_dist = to_other.length()
			if other_dist < 6.5 and other_dist > 0.4:
				var other_fwd = fwd.dot(to_other.normalized())
				if other_fwd > 0.35: # Vehicle directly in front
					var other_right = right.dot(to_other.normalized())
					if absf(other_right) < 0.45:
						dynamic_overtake_offset = 2.2 if other_right <= 0.0 else -2.2
						avoidance_steer += signf(other_right if abs(other_right) > 0.05 else 1.0) * 0.16

	steer_input = clampf(steer_input + avoidance_steer, -1.0, 1.0)

	# Trigger drift on sharp turns for cornering grip
	var want_drift = (corner_angle > 0.48 or absf(dot_right) > 0.40) and kart.forward_speed > 14.0

	kart.apply_kart_controls(throttle_input, steer_input, want_drift, delta)

func _process_waypoint_driving(delta: float) -> void:
	if waypoints.is_empty():
		return

	if current_waypoint_index < 0 or current_waypoint_index >= waypoints.size():
		current_waypoint_index = 0

	var n_pts = waypoints.size()
	var raw_wp = waypoints[current_waypoint_index]
	var next_wp = waypoints[(current_waypoint_index + 1) % n_pts]

	var seg_tangent = (next_wp - raw_wp).normalized()
	var seg_normal = seg_tangent.cross(Vector3.UP).normalized()
	var total_offset = clampf(lane_offset + dynamic_overtake_offset, -3.2, 3.2)
	var target_wp = raw_wp + seg_normal * total_offset

	var kart_pos = kart.global_position if kart.is_inside_tree() else kart.position
	var to_wp = target_wp - kart_pos
	to_wp.y = 0.0
	var dist = to_wp.length()

	if dist < 14.0:
		current_waypoint_index = (current_waypoint_index + 1) % n_pts

	var k_basis = kart.global_transform.basis if kart.is_inside_tree() else kart.transform.basis
	var fwd = -k_basis.z; fwd.y = 0.0; fwd = fwd.normalized()
	var right = k_basis.x; right.y = 0.0; right = right.normalized()

	var dir_to_wp = to_wp.normalized()
	var dot_right = right.dot(dir_to_wp)

	var steer_input = -clampf(dot_right * 2.4, -1.0, 1.0)
	var throttle_input = 1.0
	kart.apply_kart_controls(throttle_input, steer_input, false, delta)

func _get_race_spline() -> RefCounted:
	var p = get_parent()
	while p:
		var tg = p.get_node_or_null("TrackGenerator")
		if tg and tg.get("race_spline"):
			return tg.race_spline
		p = p.get_parent()
	if get_tree() and get_tree().root:
		var tg = get_tree().root.find_child("TrackGenerator", true, false)
		if tg and tg.get("race_spline"):
			return tg.race_spline
	return null

func _get_race_manager() -> Node:
	var p = get_parent()
	while p:
		var rm = p.get_node_or_null("RaceManager")
		if rm:
			return rm
		p = p.get_parent()
	if get_tree() and get_tree().root:
		return get_tree().root.find_child("RaceManager", true, false)
	return null
