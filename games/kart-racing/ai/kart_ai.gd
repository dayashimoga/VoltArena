class_name KartAI
extends Node

@export var kart: KartController
@export var waypoints: Array[Vector3] = []
@export var current_waypoint_index: int = 1

func _ready() -> void:
	if not kart:
		kart = get_parent() as KartController
	if kart:
		kart.is_player = false

var stuck_timer: float = 0.0
var reverse_timer: float = 0.0
var race_active_time: float = 0.0

@export var lane_offset: float = 0.0 # Lateral offset from centerline (-2.5 to +2.5m)
var dynamic_overtake_offset: float = 0.0

func _physics_process(delta: float) -> void:
	if not kart or not is_instance_valid(kart) or kart.race_finished:
		return

	# Auto-resolve waypoints if not yet assigned
	if waypoints.is_empty():
		var p = get_parent()
		while p:
			var tg = p.get_node_or_null("TrackGenerator")
			if tg and not tg.waypoints.is_empty():
				for wp in tg.waypoints:
					if wp is Vector3:
						waypoints.append(wp)
				break
			p = p.get_parent()
		if waypoints.is_empty() and get_tree() and get_tree().root:
			var tg = get_tree().root.find_child("TrackGenerator", true, false)
			if tg and not tg.waypoints.is_empty():
				for wp in tg.waypoints:
					if wp is Vector3:
						waypoints.append(wp)

	if waypoints.is_empty():
		return

	# Hold at start grid during countdown
	var rm: Node = null
	var parent_cursor = get_parent()
	while parent_cursor:
		rm = parent_cursor.get_node_or_null("RaceManager")
		if rm:
			break
		parent_cursor = parent_cursor.get_parent()
	if not rm and get_tree() and get_tree().root:
		rm = get_tree().root.find_child("RaceManager", true, false)

	if rm and rm.get("current_state") == 0: # RaceState.COUNTDOWN
		kart.apply_kart_controls(0.0, 0.0, false, delta)
		stuck_timer = 0.0
		reverse_timer = 0.0
		race_active_time = 0.0
		return

	race_active_time += delta

	# Ensure waypoint index is in bounds
	if current_waypoint_index < 0 or current_waypoint_index >= waypoints.size():
		current_waypoint_index = 0

	var n_pts = waypoints.size()
	var raw_wp = waypoints[current_waypoint_index]
	var next_wp = waypoints[(current_waypoint_index + 1) % n_pts]
	var future_wp = waypoints[(current_waypoint_index + 2) % n_pts]

	# Calculate track tangent and lateral normal for racing line offset
	var seg_tangent = (next_wp - raw_wp).normalized()
	var seg_normal = seg_tangent.cross(Vector3.UP).normalized()
	var total_lane_offset = clampf(lane_offset + dynamic_overtake_offset, -3.2, 3.2)
	var target_wp = raw_wp + seg_normal * total_lane_offset

	var kart_pos = kart.global_position if kart.is_inside_tree() else kart.position
	var to_wp = target_wp - kart_pos
	to_wp.y = 0.0
	var dist = to_wp.length()

	# Anticipate turn and advance waypoint
	if dist < 12.0:
		current_waypoint_index = (current_waypoint_index + 1) % n_pts
		raw_wp = waypoints[current_waypoint_index]
		next_wp = waypoints[(current_waypoint_index + 1) % n_pts]
		seg_tangent = (next_wp - raw_wp).normalized()
		seg_normal = seg_tangent.cross(Vector3.UP).normalized()
		target_wp = raw_wp + seg_normal * total_lane_offset
		to_wp = target_wp - kart_pos
		to_wp.y = 0.0

	var k_basis = kart.global_transform.basis if kart.is_inside_tree() else kart.transform.basis
	var fwd = -k_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var right = k_basis.x
	right.y = 0.0
	right = right.normalized()

	var dir_to_wp = to_wp.normalized()
	var dot_right = right.dot(dir_to_wp)
	var dot_fwd = fwd.dot(dir_to_wp)

	# Multi-tier stuck watchdog unjamming logic:
	if kart.forward_speed < 1.2 and race_active_time >= 1.5:
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

	# Curvature Look-Ahead for speed management and drift triggering
	var seg1 = (target_wp - kart_pos).normalized()
	var seg2 = (next_wp - target_wp).normalized()
	var corner_angle = abs(seg1.angle_to(seg2))

	# Negative steer turns right, positive steer turns left in kart_controller
	var steer_input = -clampf(dot_right * 2.4, -1.0, 1.0)
	var throttle_input = 1.0

	# Cornering speed calculation
	var corner_target_speed = kart.base_speed
	if corner_angle > 0.35:
		corner_target_speed = kart.base_speed * clampf(1.0 - corner_angle * 0.50, 0.48, 0.90)

	if kart.forward_speed > corner_target_speed + 2.0:
		throttle_input = -0.4 # Trail-braking into sharp corners
	elif abs(dot_right) > 0.45:
		throttle_input = 0.70
	elif abs(dot_right) > 0.25:
		throttle_input = 0.88

	# Waypoint behind car recovery
	if dot_fwd < 0.0:
		steer_input = -1.0 if dot_right >= 0.0 else 1.0
		throttle_input = 0.60

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
			if other_dist < 6.5 and other_dist > 0.3:
				var other_fwd = fwd.dot(to_other.normalized())
				if other_fwd > 0.35: # Racer in front
					var other_right = right.dot(to_other.normalized())
					# Slipstream & overtake: pull out to open lane
					if abs(other_right) < 0.40:
						dynamic_overtake_offset = 2.0 if other_right <= 0.0 else -2.0
						avoidance_steer += signf(other_right if abs(other_right) > 0.05 else 1.0) * 0.18
	steer_input = clampf(steer_input + avoidance_steer, -1.0, 1.0)

	# Trigger drift on fast sharp corners and release on corner exit for mini-turbo boost!
	var want_drift = (corner_angle > 0.50 or abs(dot_right) > 0.42) and kart.forward_speed > 15.0

	kart.apply_kart_controls(throttle_input, steer_input, want_drift, delta)
