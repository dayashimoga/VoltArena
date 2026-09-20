class_name KartAI
extends Node

## KartAI: Autonomous racing driver utilizing authoritative RaceSpline.
## Features lookahead spline targeting, curvature-based speed control,
## dynamic overtaking, and stuck-recovery state machine.

enum Difficulty { EASY, NORMAL, HARD, EXPERT }
@export var difficulty: Difficulty = Difficulty.NORMAL

@export var kart: KartController
@export var waypoints: Array[Vector3] = []
@export var current_waypoint_index: int = 1

@export var lane_offset: float = 0.0 # Lateral offset from centerline (-2.8 to +2.8m)
var dynamic_overtake_offset: float = 0.0

var stuck_timer: float = 0.0
var reverse_timer: float = 0.0
var race_active_time: float = 0.0
var prev_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	if not kart:
		kart = get_parent() as KartController
	if kart:
		kart.is_player = false
		prev_pos = kart.global_position if kart.is_inside_tree() else kart.position

func set_difficulty(tier: Variant) -> void:
	if tier is String:
		match tier.to_lower():
			"easy": difficulty = Difficulty.EASY
			"hard": difficulty = Difficulty.HARD
			"expert": difficulty = Difficulty.EXPERT
			_: difficulty = Difficulty.NORMAL
	elif tier is int:
		difficulty = clampi(tier, 0, 3) as Difficulty

func _physics_process(delta: float) -> void:
	if not kart or not is_instance_valid(kart):
		return

	# Finish Line Traversal: Cool-down lap - keep driving along track and smoothly coast to parking stop
	if kart.race_finished:
		var spline = _get_race_spline()
		if spline and spline.samples.size() >= 3:
			var kart_pos = kart.global_position if kart.is_inside_tree() else kart.position
			var k_basis = kart.global_transform.basis if kart.is_inside_tree() else kart.transform.basis
			var fwd = -k_basis.z; fwd.y = 0.0; fwd = fwd.normalized()
			var current_s = spline.get_closest_distance(kart_pos)
			var target_data = spline.sample_lookahead_forward(current_s, 14.0)
			var to_target = target_data["pos"] - kart_pos
			to_target.y = 0.0
			var angle_to_target = fwd.signed_angle_to(to_target.normalized(), Vector3.UP)
			var steer = clampf(angle_to_target * 1.5, -0.6, 0.6)
			var brake = -0.5 if kart.forward_speed > 3.0 else 0.0
			kart.apply_kart_controls(brake, steer, false, delta)
		else:
			var brake = -0.5 if kart.forward_speed > 2.0 else 0.0
			kart.apply_kart_controls(brake, 0.0, false, delta)
		return

	# Hold at start grid during countdown
	var rm = _get_race_manager()
	if rm and rm.get("current_state") == 0: # RaceState.COUNTDOWN
		kart.apply_kart_controls(0.0, 0.0, false, delta)
		stuck_timer = 0.0
		reverse_timer = 0.0
		race_active_time = 0.0
		prev_pos = kart.global_position if kart.is_inside_tree() else kart.position
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

	# 1. Authoritative spline tangent & Wrong-Way Self-Righting
	var track_tangent = spline.get_tangent_at_pos(kart_pos)
	track_tangent.y = 0.0
	track_tangent = track_tangent.normalized()
	var dot_tangent = fwd.dot(track_tangent)

	# If spun or facing against track flow, prioritize turning 180 degrees back to track forward
	if dot_tangent < -0.20:
		var angle_to_tan = fwd.signed_angle_to(track_tangent, Vector3.UP)
		var spin_steer = signf(angle_to_tan) if absf(angle_to_tan) > 0.05 else 1.0
		var spin_throttle = -1.0 if kart.forward_speed > 2.0 else 0.55
		kart.apply_kart_controls(spin_throttle, spin_steer, false, delta)
		stuck_timer = 0.0
		reverse_timer = 0.0
		prev_pos = kart_pos
		return

	# Difficulty scaling parameters
	var speed_scale = 0.92
	var corner_scale = 0.86
	var lookahead_scale = 1.0
	var overtake_mult = 1.0
	var draft_max = 1.06
	var steer_gain = 2.2
	var can_drift = true

	match difficulty:
		Difficulty.EASY:
			speed_scale = 0.82
			corner_scale = 0.72
			lookahead_scale = 0.85
			overtake_mult = 0.5
			draft_max = 1.02
			steer_gain = 1.8
			can_drift = false
		Difficulty.NORMAL:
			speed_scale = 0.92
			corner_scale = 0.86
			lookahead_scale = 1.0
			overtake_mult = 1.0
			draft_max = 1.06
			steer_gain = 2.2
			can_drift = true
		Difficulty.HARD:
			speed_scale = 1.00
			corner_scale = 0.98
			lookahead_scale = 1.15
			overtake_mult = 1.3
			draft_max = 1.09
			steer_gain = 2.5
			can_drift = true
		Difficulty.EXPERT:
			speed_scale = 1.06
			corner_scale = 1.04
			lookahead_scale = 1.25
			overtake_mult = 1.5
			draft_max = 1.12
			steer_gain = 2.8
			can_drift = true

	# 2. Current spline progress & Lookahead
	var current_s = spline.get_closest_distance(kart_pos)
	var lookahead = clampf((kart.forward_speed * 0.75 + 11.0) * lookahead_scale, 10.0, 32.0)
	var target_data = spline.sample_lookahead_forward(current_s, lookahead)

	# Lateral lane offset + dynamic overtaking
	var total_offset = clampf(lane_offset + dynamic_overtake_offset, -3.2, 3.2)
	var target_pos = target_data["pos"] + target_data["binormal"] * total_offset

	var to_target = target_pos - kart_pos
	to_target.y = 0.0
	var dir_to_target = to_target.normalized() if to_target.length_squared() > 0.01 else fwd

	# 3. Signed Angle Steering: positive angle turns left, negative angle turns right
	var angle_to_target = fwd.signed_angle_to(dir_to_target, Vector3.UP)
	var steer_input = clampf(angle_to_target * steer_gain, -1.0, 1.0)

	# Track boundary / barrier avoidance: steer inward when approaching barrier
	var lat_offset = spline.get_lateral_offset(kart_pos)
	var max_safe_lat = (spline.track_width * 0.5) - 2.0
	var boundary_steer = 0.0
	if lat_offset > max_safe_lat:
		boundary_steer += clampf((lat_offset - max_safe_lat) * 0.65, 0.0, 0.60) # Steer left
	elif lat_offset < -max_safe_lat:
		boundary_steer -= clampf((-lat_offset - max_safe_lat) * 0.65, 0.0, 0.60) # Steer right

	# 4. Stuck Watchdog: true physical displacement tracking
	var actual_speed = (kart_pos - prev_pos).length() / maxf(delta, 0.001) if prev_pos != Vector3.ZERO else 10.0
	prev_pos = kart_pos

	if actual_speed < 1.8 and race_active_time >= 1.5:
		stuck_timer += delta
		if stuck_timer > 2.5:
			kart.recover_to_checkpoint()
			stuck_timer = 0.0
			reverse_timer = 0.0
			prev_pos = kart.global_position if kart.is_inside_tree() else kart.position
			return
		elif stuck_timer > 0.7 and reverse_timer <= 0.0:
			reverse_timer = 0.55
	else:
		stuck_timer = maxf(0.0, stuck_timer - delta * 2.0)

	if reverse_timer > 0.0:
		reverse_timer -= delta
		var rev_steer = signf(lat_offset) * 0.8 if absf(lat_offset) > 1.0 else 0.0
		kart.apply_kart_controls(-0.80, rev_steer, false, delta)
		return

	# 5. Multi-Horizon Curvature Lookahead & Physics-Based Braking Points
	var brake_horizon = clampf(kart.forward_speed * 1.4 + 12.0, 18.0, 42.0)
	var s_mid = spline.sample_at_distance(current_s + brake_horizon * 0.45)
	var s_far = spline.sample_at_distance(current_s + brake_horizon)
	var angle_mid = absf(track_tangent.angle_to(s_mid["tangent"]))
	var angle_far = absf(s_mid["tangent"].angle_to(s_far["tangent"]))
	var max_curvature = maxf(angle_mid, angle_far)

	var target_speed = kart.base_speed * speed_scale
	if max_curvature > 0.60:
		target_speed *= (0.48 * corner_scale) # Very sharp corner / 90-degree turn
	elif max_curvature > 0.40:
		target_speed *= (0.62 * corner_scale) # Sharp corner
	elif max_curvature > 0.22:
		target_speed *= (0.78 * corner_scale) # Medium corner
	elif max_curvature > 0.12:
		target_speed *= (0.90 * corner_scale) # Gentle bend

	var throttle_input = 1.0
	if kart.forward_speed > target_speed + 1.5:
		throttle_input = -0.90 # Strong progressive braking into corner
	elif kart.forward_speed > target_speed:
		throttle_input = 0.20
	elif absf(angle_to_target) > 0.40:
		throttle_input = 0.75

	# Slow down and steer inward if sliding toward outer barrier
	if absf(lat_offset) > max_safe_lat:
		throttle_input = minf(throttle_input, 0.35)

	# 6. Overtaking, Collision Avoidance & Slipstream Drafting
	dynamic_overtake_offset = move_toward(dynamic_overtake_offset, 0.0, delta * 0.6)
	var avoidance_steer = 0.0
	var in_slipstream = false

	if is_inside_tree() and race_active_time > 1.0:
		var all_karts = get_tree().get_nodes_in_group("karts")
		for other in all_karts:
			if other == kart or not is_instance_valid(other):
				continue
			var o_pos = other.global_position if other.is_inside_tree() else other.position
			var to_other = o_pos - kart_pos
			to_other.y = 0.0
			var dist_other = to_other.length()
			if dist_other > 0.4 and dist_other < 15.0:
				var dir_other = to_other.normalized()
				var dot_other_fwd = fwd.dot(dir_other)
				if dot_other_fwd > 0.70: # Directly ahead
					if dist_other < 7.5:
						# Initiate lane shift to overtake
						var dot_other_right = right.dot(dir_other)
						dynamic_overtake_offset = (2.4 if dot_other_right <= 0.0 else -2.4) * overtake_mult
						avoidance_steer += (0.20 if dot_other_right <= 0.0 else -0.20)
					else:
						# Slipstream draft zone (7.5m - 15m)
						in_slipstream = true

	if in_slipstream and throttle_input > 0.0:
		kart.forward_speed = minf(kart.forward_speed + delta * 2.5 * overtake_mult, kart.base_speed * draft_max)

	steer_input = clampf(steer_input + avoidance_steer + boundary_steer, -1.0, 1.0)

	# 7. Drift Initiation on Sharp Turns (only when safe speed and steering angle)
	var want_drift = can_drift and max_curvature > 0.45 and absf(angle_to_target) > 0.35 and kart.forward_speed > 12.0 and kart.forward_speed < 24.0

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
