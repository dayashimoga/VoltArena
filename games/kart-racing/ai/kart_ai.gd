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
	if not kart or not is_instance_valid(kart) or waypoints.is_empty() or kart.race_finished:
		return

	# Hold at start grid during countdown
	var rm = get_tree().root.find_child("RaceManager", true, false)
	if rm and rm.get("current_state") == 0: # RaceState.COUNTDOWN
		kart.apply_kart_controls(0.0, 0.0, false, delta)
		return

	var target_wp = waypoints[current_waypoint_index]
	var to_wp = target_wp - kart.global_position
	to_wp.y = 0.0
	var dist = to_wp.length()

	# Anticipate turn and advance waypoint
	if dist < 14.0:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_index]
		to_wp = target_wp - kart.global_position
		to_wp.y = 0.0

	var fwd = -kart.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var right = kart.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var dir_to_wp = to_wp.normalized()
	var dot_right = right.dot(dir_to_wp)
	var dot_fwd = fwd.dot(dir_to_wp)

	# Stuck unjamming logic: if throttle is applied but kart is jammed, reverse out
	if kart.forward_speed < 2.5:
		stuck_timer += delta
		if stuck_timer > 1.2:
			reverse_timer = 0.8
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0

	if reverse_timer > 0.0:
		reverse_timer -= delta
		kart.apply_kart_controls(-1.0, -signf(dot_right) if abs(dot_right) > 0.1 else 1.0, false, delta)
		return

	var steer_input = clampf(dot_right * 2.8, -1.0, 1.0)
	var throttle_input = 1.0

	# Slow down slightly into very sharp 90-degree corners
	if abs(dot_right) > 0.6:
		throttle_input = 0.75

	# Drift if fast and sharp
	var want_drift = abs(dot_right) > 0.35 and kart.forward_speed > 16.0

	kart.apply_kart_controls(throttle_input, steer_input, want_drift, delta)
