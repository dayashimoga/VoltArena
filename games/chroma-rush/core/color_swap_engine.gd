class_name ColorSwapEngine
extends RefCounted

## Authoritative Color Swap Engine for Chroma Rush
## Independent of rendering and UI. Enforces strict color conservation,
## eligibility criteria, deterministic arbitration, and atomic 2-way exchanges.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")

signal swap_committed(initiator_id: String, target_id: String, initiator_color: int, target_color: int)
signal swap_rejected(initiator_id: String, target_id: String, reason: String)
signal alignment_updated(initiator_id: String, target_id: String, progress_ratio: float, is_eligible: bool)
signal vehicle_registered(vehicle_id: String, initial_color: int)
signal vehicle_unregistered(vehicle_id: String)

# Registry of vehicles: vehicle_id -> Dictionary { "node": Node3D, "color": int, "cooldown": float, "is_ai": bool }
var _vehicles: Dictionary = {}

# Continuous alignment tracking: String(pair_key) -> float (seconds aligned)
var _alignment_timers: Dictionary = {}

# Active swap lock to prevent overlapping / race-condition exchanges
var _locked_vehicles: Dictionary = {}

# Optional driving assist for alignment (0.0 to 1.0)
var alignment_assist_strength: float = 0.0

# Debounce tracker for rapid button tapping: vehicle_id -> float
var _input_debounce: Dictionary = {}

# Total lifetime verified swaps committed
var total_swaps_committed: int = 0

func register_vehicle(id: String, node: Node3D, initial_color: int, is_ai: bool = false) -> void:
	_vehicles[id] = {
		"node": node,
		"color": initial_color,
		"cooldown": 0.0,
		"is_ai": is_ai,
		"last_input_time": 0.0
	}
	vehicle_registered.emit(id, initial_color)

func unregister_vehicle(id: String) -> void:
	if _vehicles.has(id):
		_vehicles.erase(id)
		_clear_pair_timers(id)
		_locked_vehicles.erase(id)
		vehicle_unregistered.emit(id)

func has_vehicle(id: String) -> bool:
	return _vehicles.has(id)

func get_vehicle_color(id: String) -> int:
	if _vehicles.has(id):
		return _vehicles[id]["color"]
	return ChromaConstants.ChromaColor.NONE

func set_vehicle_color_authoritative(id: String, color_id: int) -> void:
	if _vehicles.has(id):
		_vehicles[id]["color"] = color_id

func get_vehicle_node(id: String) -> Node3D:
	if _vehicles.has(id):
		return _vehicles[id]["node"]
	return null

func get_registered_vehicle_ids() -> Array:
	return _vehicles.keys()

func get_vehicle_cooldown(id: String) -> float:
	if _vehicles.has(id):
		return _vehicles[id]["cooldown"]
	return 0.0

func update(delta: float) -> void:
	# Decrement cooldowns
	for id in _vehicles.keys():
		var data = _vehicles[id]
		if data["cooldown"] > 0.0:
			data["cooldown"] = maxf(0.0, data["cooldown"] - delta)
		if _input_debounce.has(id):
			_input_debounce[id] = maxf(0.0, _input_debounce[id] - delta)

	# Discover any newly aligned pairs to begin accumulating duration
	var vehicle_ids = _vehicles.keys()
	var v_count = vehicle_ids.size()
	for i in range(v_count):
		for j in range(i + 1, v_count):
			var id_a = vehicle_ids[i]
			var id_b = vehicle_ids[j]
			var p_key = _make_pair_key(id_a, id_b)
			if not _alignment_timers.has(p_key):
				var chk = evaluate_eligibility(id_a, id_b, false)
				if chk.get("eligible_except_time", false):
					_alignment_timers[p_key] = 0.0

	# Update alignment timers for actively tracking vehicle pairs
	var pairs_to_remove: Array[String] = []
	for pair_key in _alignment_timers.keys():
		var ids = pair_key.split(":")
		if ids.size() != 2 or not _vehicles.has(ids[0]) or not _vehicles.has(ids[1]):
			pairs_to_remove.append(pair_key)
			continue

		var check = evaluate_eligibility(ids[0], ids[1], false)
		if check["eligible_except_time"]:
			_alignment_timers[pair_key] += delta
			var progress = clampf(_alignment_timers[pair_key] / ChromaConstants.REQUIRED_ALIGNMENT_DURATION, 0.0, 1.0)
			alignment_updated.emit(ids[0], ids[1], progress, progress >= 1.0)
		else:
			# Decay alignment when conditions break
			_alignment_timers[pair_key] = maxf(0.0, _alignment_timers[pair_key] - delta * 2.0)
			var progress = clampf(_alignment_timers[pair_key] / ChromaConstants.REQUIRED_ALIGNMENT_DURATION, 0.0, 1.0)
			alignment_updated.emit(ids[0], ids[1], progress, false)
			if _alignment_timers[pair_key] <= 0.0:
				pairs_to_remove.append(pair_key)

	for p in pairs_to_remove:
		_alignment_timers.erase(p)

func request_swap(initiator_id: String, target_id: String) -> Dictionary:
	var init_data = _vehicles.get(initiator_id)
	var target_data = _vehicles.get(target_id)
	if init_data and target_data:
		if init_data.get("cooldown", 0.0) > 0.0 or target_data.get("cooldown", 0.0) > 0.0:
			swap_rejected.emit(initiator_id, target_id, ChromaConstants.REJECT_COOLDOWN)
			return {"success": false, "reason": ChromaConstants.REJECT_COOLDOWN}

	# Input debounce check to prevent accidental repeated inputs
	if _input_debounce.get(initiator_id, 0.0) > 0.0:
		return {"success": false, "reason": ChromaConstants.REJECT_BUSY}
	_input_debounce[initiator_id] = ChromaConstants.INPUT_DEBOUNCE_WINDOW

	# Immediate atomic revalidation
	var eval = evaluate_eligibility(initiator_id, target_id, true)
	if not eval["eligible"]:
		swap_rejected.emit(initiator_id, target_id, eval["reason"])
		return {"success": false, "reason": eval["reason"]}

	# Lock both vehicles to prevent simultaneous or interleaved swap execution
	var lock_key_a = initiator_id
	var lock_key_b = target_id
	if _locked_vehicles.has(lock_key_a) or _locked_vehicles.has(lock_key_b):
		swap_rejected.emit(initiator_id, target_id, ChromaConstants.REJECT_BUSY)
		return {"success": false, "reason": ChromaConstants.REJECT_BUSY}

	_locked_vehicles[lock_key_a] = true
	_locked_vehicles[lock_key_b] = true

	# Perform strictly atomic 2-way exchange (Color Conservation Invariant)
	init_data = _vehicles[initiator_id]
	target_data = _vehicles[target_id]

	var color_a = init_data["color"]
	var color_b = target_data["color"]

	# Re-verify color conservation: both must be distinct
	if color_a == color_b:
		_locked_vehicles.erase(lock_key_a)
		_locked_vehicles.erase(lock_key_b)
		swap_rejected.emit(initiator_id, target_id, ChromaConstants.REJECT_SAME_COLOR)
		return {"success": false, "reason": ChromaConstants.REJECT_SAME_COLOR}

	# Atomic commit
	init_data["color"] = color_b
	target_data["color"] = color_a

	# Reset alignment timers & apply cooldowns
	_clear_pair_timers(initiator_id)
	_clear_pair_timers(target_id)
	init_data["cooldown"] = ChromaConstants.SWAP_COOLDOWN
	target_data["cooldown"] = ChromaConstants.SWAP_COOLDOWN

	_locked_vehicles.erase(lock_key_a)
	_locked_vehicles.erase(lock_key_b)

	total_swaps_committed += 1

	# Publish verified swap event
	swap_committed.emit(initiator_id, target_id, color_b, color_a)

	return {
		"success": true,
		"initiator_new_color": color_b,
		"target_new_color": color_a
	}

func evaluate_eligibility(initiator_id: String, target_id: String, require_full_time: bool = true) -> Dictionary:
	if initiator_id == target_id:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_INVALID}

	if not _vehicles.has(initiator_id) or not _vehicles.has(target_id):
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_INVALID}

	var init_data = _vehicles[initiator_id]
	var target_data = _vehicles[target_id]

	# Check cooldowns
	if init_data["cooldown"] > 0.0 or target_data["cooldown"] > 0.0:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_COOLDOWN}

	# Check colors
	if init_data["color"] == target_data["color"]:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_SAME_COLOR}

	var node_a = init_data["node"] as Node3D
	var node_b = target_data["node"] as Node3D
	if not is_instance_valid(node_a) or not is_instance_valid(node_b):
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_INVALID}

	# Proximity check
	var pos_a = _get_node_pos(node_a)
	var pos_b = _get_node_pos(node_b)
	var dist = pos_a.distance_to(pos_b)
	if dist > ChromaConstants.MAX_SWAP_DISTANCE:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_DISTANCE}

	# Elevation difference check (prevents swapping across elevated flyovers and ground roads)
	if absf(pos_a.y - pos_b.y) > 2.8:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_ELEVATION}

	# Line of sight check (never swap through buildings, walls, curbs, or barriers)
	if node_a.is_inside_tree() and node_b.is_inside_tree():
		var space_state = node_a.get_world_3d().direct_space_state
		if space_state:
			var exclude: Array[RID] = []
			if node_a is CollisionObject3D:
				exclude.append(node_a.get_rid())
			if node_b is CollisionObject3D:
				exclude.append(node_b.get_rid())
			for h_off in [0.25, 0.65]:
				var p_from = node_a.global_position + Vector3(0, h_off, 0)
				var p_to = node_b.global_position + Vector3(0, h_off, 0)
				var query = PhysicsRayQueryParameters3D.create(p_from, p_to, GameConstants.LAYER_WORLD, exclude)
				var hit = space_state.intersect_ray(query)
				if hit and not hit.is_empty():
					return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_OBSTRUCTED}

	# Velocity checks (using CharacterBody3D or velocity property if available)
	var vel_a = _get_velocity(node_a)
	var vel_b = _get_velocity(node_b)
	var rel_speed = (vel_a - vel_b).length()
	if rel_speed > ChromaConstants.MAX_RELATIVE_SPEED:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_SPEED}

	# Forward parallel alignment check
	var forward_a = _get_node_forward(node_a)
	var forward_b = _get_node_forward(node_b)
	var dot = forward_a.dot(forward_b)
	var angle_deg = rad_to_deg(acos(clampf(dot, -1.0, 1.0)))
	if angle_deg > ChromaConstants.MAX_ALIGNMENT_ANGLE_DEG:
		return {"eligible": false, "eligible_except_time": false, "reason": ChromaConstants.REJECT_ANGLE}

	# Continuous alignment duration check
	var pair_key = _make_pair_key(initiator_id, target_id)
	if not _alignment_timers.has(pair_key):
		_alignment_timers[pair_key] = 0.0
	var current_aligned_time = _alignment_timers.get(pair_key, 0.0)

	if require_full_time and current_aligned_time < ChromaConstants.REQUIRED_ALIGNMENT_DURATION:
		return {
			"eligible": false,
			"eligible_except_time": true,
			"reason": ChromaConstants.REJECT_ALIGNMENT_TIME,
			"alignment_progress": current_aligned_time / ChromaConstants.REQUIRED_ALIGNMENT_DURATION
		}

	return {
		"eligible": true,
		"eligible_except_time": true,
		"reason": "",
		"distance": dist,
		"relative_speed": rel_speed,
		"angle_deg": angle_deg,
		"alignment_progress": 1.0
	}

func find_nearest_eligible_target(initiator_id: String, max_radius: float = 18.0) -> Dictionary:
	if not _vehicles.has(initiator_id):
		return {"target_id": "", "distance": 999.0, "eligible": false}

	var node_a = _vehicles[initiator_id]["node"] as Node3D
	if not is_instance_valid(node_a):
		return {"target_id": "", "distance": 999.0, "eligible": false}

	var best_target: String = ""
	var best_dist: float = max_radius
	var is_fully_eligible: bool = false

	for other_id in _vehicles.keys():
		if other_id == initiator_id:
			continue
		var node_b = _vehicles[other_id]["node"] as Node3D
		if not is_instance_valid(node_b):
			continue
		var d = _get_node_pos(node_a).distance_to(_get_node_pos(node_b))
		if d < best_dist:
			var check = evaluate_eligibility(initiator_id, other_id, true)
			best_dist = d
			best_target = other_id
			is_fully_eligible = check["eligible"]

	return {
		"target_id": best_target,
		"distance": best_dist,
		"eligible": is_fully_eligible
	}

func find_target_with_color(initiator_id: String, needed_color: int) -> String:
	if not _vehicles.has(initiator_id):
		return ""
	var node_a = _vehicles[initiator_id]["node"] as Node3D
	if not is_instance_valid(node_a):
		return ""

	var nearest_id: String = ""
	var nearest_dist: float = 99999.0

	for other_id in _vehicles.keys():
		if other_id == initiator_id:
			continue
		if _vehicles[other_id]["color"] == needed_color:
			var node_b = _vehicles[other_id]["node"] as Node3D
			if is_instance_valid(node_b):
				var d = _get_node_pos(node_a).distance_to(_get_node_pos(node_b))
				if d < nearest_dist:
					nearest_dist = d
					nearest_id = other_id

	return nearest_id

func get_alignment_progress(initiator_id: String, target_id: String) -> float:
	var pair_key = _make_pair_key(initiator_id, target_id)
	var t = _alignment_timers.get(pair_key, 0.0)
	return clampf(t / ChromaConstants.REQUIRED_ALIGNMENT_DURATION, 0.0, 1.0)

func prime_alignment(initiator_id: String, target_id: String, duration_sec: float) -> void:
	# Used by tests or assisted locking
	var pair_key = _make_pair_key(initiator_id, target_id)
	_alignment_timers[pair_key] = duration_sec

func compute_color_conservation_checksum() -> Dictionary:
	# Verifies total counts of each color across all registered vehicles
	var counts: Dictionary = {}
	for c in ChromaConstants.ChromaColor.values():
		counts[c] = 0
	for id in _vehicles.keys():
		var col = _vehicles[id]["color"]
		counts[col] = counts.get(col, 0) + 1
	return counts

func _get_velocity(node: Node3D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO
	if node.has_meta("velocity"):
		var mv = node.get_meta("velocity")
		if mv is Vector3:
			return mv
	var v = node.get("velocity")
	if v != null and v is Vector3:
		return v
	var lv = node.get("linear_velocity")
	if lv != null and lv is Vector3:
		return lv
	return Vector3.ZERO

func _get_node_pos(node: Node3D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO
	return node.global_position if node.is_inside_tree() else node.position

func _get_node_forward(node: Node3D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.FORWARD
	var t = node.global_transform if node.is_inside_tree() else node.transform
	return -t.basis.z.normalized()

func _make_pair_key(id_a: String, id_b: String) -> String:
	# Sorted pair key so order does not duplicate alignment states
	if id_a < id_b:
		return "%s:%s" % [id_a, id_b]
	else:
		return "%s:%s" % [id_b, id_a]

func _clear_pair_timers(id: String) -> void:
	var keys_to_erase: Array[String] = []
	for k in _alignment_timers.keys():
		if k.begins_with(id + ":") or k.ends_with(":" + id):
			keys_to_erase.append(k)
	for k in keys_to_erase:
		_alignment_timers.erase(k)
