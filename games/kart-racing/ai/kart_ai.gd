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

func _physics_process(delta: float) -> void:
	if not kart or not is_instance_valid(kart) or waypoints.is_empty() or kart.race_finished:
		return

	var target_wp = waypoints[current_waypoint_index]
	var to_wp = target_wp - kart.global_position
	to_wp.y = 0.0
	var dist = to_wp.length()

	# If reached waypoint, advance to next
	if dist < 12.0:
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

	var steer_input = clampf(dot_right * 3.0, -1.0, 1.0)
	var throttle_input = 1.0

	# Drift if sharp turn
	var want_drift = abs(dot_right) > 0.4 and kart.forward_speed > 18.0

	kart.apply_kart_controls(throttle_input, steer_input, want_drift, delta)
