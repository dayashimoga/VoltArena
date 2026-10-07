class_name AeroRivalAI
extends Node

## Competent stunt AI racer for AeroRush: Impossible Circuit.
## Steers, brakes, drifts, uses boost, and navigates 3D vertical loops and jumps
## using legitimate vehicle physics without teleportation or fake speed cheats.

var vehicle: CharacterBody3D = null
var waypoints: Array = []
var current_target_idx: int = 1
var lookahead_dist: float = 24.0
var stuck_timer: float = 0.0
var skill_level: float = 0.88 # 0.7 to 1.0

func setup(p_vehicle: CharacterBody3D, p_waypoints: Array, p_skill: float = 0.88) -> void:
	vehicle = p_vehicle
	waypoints = p_waypoints
	skill_level = clampf(p_skill, 0.65, 1.0)
	current_target_idx = 1

func _physics_process(delta: float) -> void:
	if not vehicle or not is_instance_valid(vehicle) or waypoints.is_empty():
		return

	_update_target_waypoint()
	_drive_towards_target(delta)
	_check_stuck_and_recover(delta)

func _update_target_waypoint() -> void:
	var v_pos = vehicle.global_position
	var target_wp = waypoints[current_target_idx]["pos"] as Vector3
	var dist = v_pos.distance_to(target_wp)

	# Dynamic lookahead scaled with forward speed
	var spd = vehicle.get("forward_speed")
	var cur_speed = absf(float(spd)) if spd != null else 20.0
	var threshold = clampf(cur_speed * 0.65, 14.0, 32.0)

	if dist < threshold:
		current_target_idx = (current_target_idx + 1) % waypoints.size()

func _drive_towards_target(delta: float) -> void:
	var v_pos = vehicle.global_position
	var v_basis = vehicle.global_basis
	var target_wp = waypoints[current_target_idx]["pos"] as Vector3

	# Transform target waypoint into vehicle local space
	var to_target = target_wp - v_pos
	var local_target = v_basis.inverse() * to_target

	# Steering
	var steer = clampf(-local_target.x / 14.0, -1.0, 1.0) * skill_level

	# Throttle and Brake evaluation
	var turn_severity = absf(steer)
	var throttle = 1.0
	var brake = 0.0
	var handbrake = false
	var boost = false

	var spd = vehicle.get("forward_speed")
	var cur_speed = absf(float(spd)) if spd != null else 0.0

	# Drift on sharp bends at speed
	if turn_severity > 0.65 and cur_speed > 22.0:
		handbrake = true

	# Brake if carrying excessive speed into severe corners
	if turn_severity > 0.75 and cur_speed > 42.0:
		throttle = 0.2
		brake = 0.8

	# Boost usage on straightaways and jump approaches
	var next_wp = waypoints[current_target_idx]
	var is_jump = next_wp.get("is_jump_gap", false) as bool
	if (turn_severity < 0.2 and cur_speed > 20.0) or is_jump:
		boost = randf() < (skill_level * 0.45)

	# Airborne Leveling
	var is_grounded = vehicle.get("is_grounded")
	if is_grounded != null and not bool(is_grounded):
		# Level vehicle pitch and roll while airborne
		var pitch = -v_basis.z.y
		var roll = v_basis.x.y
		if pitch > 0.2:
			throttle = 0.8 # Pitch nose up
			brake = 0.0
		elif pitch < -0.2:
			throttle = 0.0
			brake = 0.8 # Pitch nose down
		steer = clampf(-roll * 2.0, -1.0, 1.0)
		handbrake = true # Roll leveling

	if vehicle.has_method("set_inputs"):
		vehicle.set_inputs(steer, throttle, brake, handbrake, boost)

func _check_stuck_and_recover(delta: float) -> void:
	var spd = vehicle.get("forward_speed")
	var cur_speed = absf(float(spd)) if spd != null else 0.0

	if cur_speed < 1.5:
		stuck_timer += delta
		if stuck_timer >= 2.2:
			stuck_timer = 0.0
			if vehicle.has_method("recover_to_checkpoint"):
				vehicle.recover_to_checkpoint()
	else:
		stuck_timer = 0.0
