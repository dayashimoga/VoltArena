class_name KartAI
extends Node

@export var kart: KartController
@export var waypoints: Array[Vector3] = []
@export var current_waypoint_index: int = 0

func _ready() -> void:
	if not kart:
		kart = get_parent() as KartController
	if kart:
		kart.is_player = false

var stuck_timer: float = 0.0
var reverse_timer: float = 0.0

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
		return

	var target_wp = waypoints[current_waypoint_index]
	var kart_pos = kart.global_position if kart.is_inside_tree() else kart.position
	var to_wp = target_wp - kart_pos
	to_wp.y = 0.0
	var dist = to_wp.length()

	# Anticipate turn and advance waypoint
	if dist < 14.0:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_index]
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
	var _dot_fwd = fwd.dot(dir_to_wp)

	# Multi-tier stuck watchdog unjamming logic:
	# Tier 1: reverse for 0.8s while counter-steering
	# Tier 2: emergency track centerline realignment if stuck > 3.5s
	if kart.forward_speed < 2.5:
		stuck_timer += delta
		if stuck_timer > 3.5:
			if kart.is_inside_tree():
				kart.global_position = target_wp + Vector3(0, 0.4, 0)
			else:
				kart.position = target_wp + Vector3(0, 0.4, 0)
			var next_wp = waypoints[(current_waypoint_index + 1) % waypoints.size()]
			var fwd_dir = (next_wp - target_wp).normalized()
			if fwd_dir.length_squared() > 0.01:
				kart.rotation.y = atan2(-fwd_dir.x, -fwd_dir.z)
			kart.velocity = Vector3.ZERO
			kart.forward_speed = 6.0
			stuck_timer = 0.0
			reverse_timer = 0.0
		elif stuck_timer > 1.2 and reverse_timer <= 0.0:
			reverse_timer = 0.8
	else:
		stuck_timer = maxf(0.0, stuck_timer - delta * 2.0)

	if reverse_timer > 0.0:
		reverse_timer -= delta
		kart.apply_kart_controls(-0.8, -signf(dot_right) if abs(dot_right) > 0.1 else 1.0, false, delta)
		return

	var steer_input = clampf(dot_right * 2.5, -1.0, 1.0)
	var throttle_input = 1.0

	# Smooth throttle modulation into sharp corners
	if abs(dot_right) > 0.5:
		throttle_input = 0.70
	elif abs(dot_right) > 0.3:
		throttle_input = 0.85

	# Drift if fast and sharp
	var want_drift = abs(dot_right) > 0.35 and kart.forward_speed > 16.0

	kart.apply_kart_controls(throttle_input, steer_input, want_drift, delta)
