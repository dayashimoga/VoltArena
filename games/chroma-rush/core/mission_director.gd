class_name MissionDirector
extends RefCounted

## Orchestrates mission lifecycle, mode rules, scoring, success/failure conditions, and rewards
## Supports Color Hunt, Chroma Sprint, Puzzle Drive, and Chroma Championship.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const MissionDatabase = preload("res://games/chroma-rush/content/mission_database.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const WorldBase = preload("res://games/chroma-rush/worlds/world_base.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

signal mission_started(mission_data: Dictionary)
signal objective_progress_updated(current_obj_idx: int, total_objs: int, needed_color: int, gate_id: String)
signal mission_completed(victory: bool, results: Dictionary)
signal time_updated(time_left: float, time_elapsed: float)
signal score_updated(current_score: int, combo_multiplier: float)

var active_mission: Dictionary = {}
var current_objective_idx: int = 0
var time_remaining: float = 0.0
var time_elapsed: float = 0.0
var swaps_used: int = 0
var score: int = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
var is_active: bool = false
var is_finished: bool = false

var swap_engine: ColorSwapEngine
var active_world: WorldBase

func _init(p_engine: ColorSwapEngine = null) -> void:
	swap_engine = p_engine

func start_mission(mission_data: Dictionary, world: WorldBase = null) -> bool:
	# Validate mission schema before starting
	var val = MissionDatabase.validate_mission(mission_data)
	if not val["is_valid"]:
		push_error("[MissionDirector] Cannot start invalid mission: " + ", ".join(val["errors"]))
		return false

	active_mission = mission_data
	active_world = world
	current_objective_idx = 0
	time_remaining = active_mission.get("time_limit", 90.0)
	time_elapsed = 0.0
	swaps_used = 0
	score = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	is_active = true
	is_finished = false

	# Connect swap engine listener to count swaps
	if swap_engine and not swap_engine.swap_committed.is_connected(_on_swap_committed):
		swap_engine.swap_committed.connect(_on_swap_committed)

	mission_started.emit(active_mission)
	_emit_current_objective()
	return true

func update(delta: float) -> void:
	if not is_active or is_finished:
		return

	time_elapsed += delta

	# Mode-specific timer logic
	var mode = active_mission.get("mode", ChromaConstants.GameMode.COLOR_HUNT)
	if mode == ChromaConstants.GameMode.CHROMA_SPRINT or active_mission.get("time_limit", 0.0) > 0.0:
		time_remaining = maxf(0.0, time_remaining - delta)
		time_updated.emit(time_remaining, time_elapsed)

		if time_remaining <= 0.0:
			if mode == ChromaConstants.GameMode.CHROMA_SPRINT:
				# In Sprint, time running out completes the run with tally of objectives achieved
				_finish_mission(current_objective_idx > 0)
			else:
				# In timed Hunt, Puzzle, or Championship, running out of time is a failure
				_finish_mission(false, "TIME_EXPIRED")
			return

	# Update combo multiplier decay
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_multiplier = 1.0
			score_updated.emit(score, combo_multiplier)

func handle_checkpoint_reached(vehicle: ChromaVehicle, gate: CheckpointGate) -> void:
	if not is_active or is_finished:
		return

	var objectives: Array = active_mission.get("objectives", [])
	if current_objective_idx >= objectives.size():
		return

	var cur_obj = objectives[current_objective_idx]
	var needed_color = cur_obj["target_color"]
	var target_gate_id = cur_obj["gate_id"]

	# Check if this gate matches current target objective and vehicle color is correct
	if gate.gate_id == target_gate_id and vehicle.current_color == needed_color:
		var base_points = cur_obj.get("points", 1000)
		var awarded_points = int(base_points * combo_multiplier)
		score += awarded_points

		# Combo bonus
		combo_multiplier = minf(combo_multiplier + 0.5, 4.0)
		combo_timer = 6.0
		score_updated.emit(score, combo_multiplier)

		# Chroma Sprint time bonus
		if active_mission.get("mode", -1) == ChromaConstants.GameMode.CHROMA_SPRINT:
			time_remaining += 15.0

		current_objective_idx += 1

		if current_objective_idx >= objectives.size():
			# All mission objectives accomplished!
			_finish_mission(true)
		else:
			_emit_current_objective()

func _on_swap_committed(init_id: String, target_id: String, c1: int, c2: int) -> void:
	if not is_active or is_finished:
		return

	if init_id == "player" or target_id == "player":
		swaps_used += 1

		# In Puzzle Drive, strictly enforce swap limits
		var max_swaps = active_mission.get("swap_limit", 0)
		if max_swaps > 0 and swaps_used > max_swaps:
			_finish_mission(false, "SWAP_LIMIT_EXCEEDED")

func _emit_current_objective() -> void:
	var objectives: Array = active_mission.get("objectives", [])
	if current_objective_idx < objectives.size():
		var obj = objectives[current_objective_idx]
		objective_progress_updated.emit(
			current_objective_idx,
			objectives.size(),
			obj["target_color"],
			obj["gate_id"]
		)

func _finish_mission(victory: bool, failure_reason: String = "") -> void:
	is_finished = true
	is_active = false

	# Disconnect swap listener
	if swap_engine and swap_engine.swap_committed.is_connected(_on_swap_committed):
		swap_engine.swap_committed.disconnect(_on_swap_committed)

	# Calculate stars (1 - 3)
	var stars = 0
	if victory:
		stars = 1
		var time_limit = active_mission.get("time_limit", 90.0)
		if time_limit > 0.0 and time_remaining > time_limit * 0.4:
			stars += 1 # Speed star
		if swaps_used <= active_mission.get("objectives", []).size():
			stars += 1 # Efficiency star

	var credit_grant = active_mission.get("credit_reward", 500) if victory else int(score * 0.1)

	var results = {
		"mission_id": active_mission.get("id", ""),
		"title": active_mission.get("title", ""),
		"victory": victory,
		"failure_reason": failure_reason,
		"score": score,
		"stars": stars,
		"credits_earned": credit_grant,
		"time_elapsed": time_elapsed,
		"swaps_used": swaps_used,
		"objectives_completed": current_objective_idx,
		"total_objectives": active_mission.get("objectives", []).size()
	}

	mission_completed.emit(victory, results)

func retry_mission() -> void:
	if not active_mission.is_empty():
		start_mission(active_mission, active_world)

func get_current_target_color() -> int:
	var objectives: Array = active_mission.get("objectives", [])
	if current_objective_idx < objectives.size():
		return objectives[current_objective_idx]["target_color"]
	return ChromaConstants.ChromaColor.NONE

func get_current_target_gate_id() -> String:
	var objectives: Array = active_mission.get("objectives", [])
	if current_objective_idx < objectives.size():
		return objectives[current_objective_idx]["gate_id"]
	return ""
