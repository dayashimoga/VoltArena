class_name TestMissionSolvability
extends RefCounted

## Unit tests for Chroma Rush mission definitions, solvability validation, and MissionDirector

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const MissionDirector = preload("res://games/chroma-rush/core/mission_director.gd")
const MissionDatabase = preload("res://games/chroma-rush/content/mission_database.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_all_24_missions_static_validation()
	test_mode_distribution()
	test_world_distribution()
	test_mission_director_lifecycle_success()
	test_puzzle_mode_swap_limit_failure()
	test_mission_director_time_expiration_failure()
	test_sprint_mode_time_bonus()
	test_mission_retry()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestMissionSolvability FAIL] " + msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		push_error("[TestMissionSolvability FAIL] %s (Expected %s, got %s)" % [msg, str(b), str(a)])

func test_all_24_missions_static_validation() -> void:
	var result = MissionDatabase.validate_all_missions()
	assert_true(result["is_valid"], "All 24 handcrafted missions must pass static validation with zero errors")
	assert_eq(result["total_missions"], 24, "Must define exactly 24 distinct handcrafted missions")
	assert_eq(result["errors"].size(), 0, "No validation errors allowed: " + ", ".join(result["errors"]))

func test_mode_distribution() -> void:
	var hunt = MissionDatabase.get_missions_for_mode(ChromaConstants.GameMode.COLOR_HUNT)
	var sprint = MissionDatabase.get_missions_for_mode(ChromaConstants.GameMode.CHROMA_SPRINT)
	var puzzle = MissionDatabase.get_missions_for_mode(ChromaConstants.GameMode.PUZZLE_DRIVE)
	var champ = MissionDatabase.get_missions_for_mode(ChromaConstants.GameMode.CHAMPIONSHIP)

	assert_eq(hunt.size(), 6, "Must have 6 Color Hunt missions")
	assert_eq(sprint.size(), 6, "Must have 6 Chroma Sprint missions")
	assert_eq(puzzle.size(), 6, "Must have 6 Puzzle Drive missions")
	assert_eq(champ.size(), 6, "Must have 6 Championship missions")

func test_world_distribution() -> void:
	var all_m = MissionDatabase.get_all_missions()
	var worlds: Dictionary = {}
	for m in all_m:
		var w = m["world_id"]
		worlds[w] = worlds.get(w, 0) + 1

	for w in ChromaConstants.ALL_WORLDS:
		assert_true(worlds.has(w) and worlds[w] >= 4, "World %s must feature at least 4 missions" % w)

func test_mission_director_lifecycle_success() -> void:
	var engine = ColorSwapEngine.new()
	var director = MissionDirector.new(engine)
	var mission = MissionDatabase.get_mission_by_id("hunt_neon_01")

	var start_data = {"fired": false}
	director.mission_started.connect(func(data): start_data["fired"] = true)

	var ok = director.start_mission(mission)
	assert_true(ok, "Mission should start cleanly")
	assert_true(start_data["fired"], "mission_started signal fired")
	assert_eq(director.get_current_target_color(), ChromaConstants.ChromaColor.EMERALD, "Target color is emerald")
	assert_eq(director.get_current_target_gate_id(), "gate_4", "Target gate is gate_4")

	# Create dummy vehicle and gate
	var v = ChromaVehicle.new()
	v.vehicle_owner_id = "player"
	v.initial_color = ChromaConstants.ChromaColor.EMERALD
	v._ready()

	var gate = CheckpointGate.new()
	gate.gate_id = "gate_4"
	gate.target_color = ChromaConstants.ChromaColor.EMERALD
	gate._ready()

	var vic_data = {"fired": false, "results": {}}
	director.mission_completed.connect(func(vic, res):
		vic_data["fired"] = true
		vic_data["results"] = res
	)

	# Deliver to checkpoint
	director.handle_checkpoint_reached(v, gate)

	assert_true(vic_data["fired"], "mission_completed signal should fire on final delivery")
	assert_true(vic_data["results"]["victory"], "Results must indicate victory")
	assert_true(vic_data["results"]["score"] >= 1000, "Score awarded")
	assert_true(vic_data["results"]["credits_earned"] >= 500, "Credits awarded")

	v.free()
	gate.free()

func test_puzzle_mode_swap_limit_failure() -> void:
	var engine = ColorSwapEngine.new()
	var director = MissionDirector.new(engine)
	var mission = MissionDatabase.get_mission_by_id("puzzle_neon_13") # swap_limit = 1

	director.start_mission(mission)

	var puzzle_cb = {"fired": false, "victory": true}
	director.mission_completed.connect(func(vic, res):
		puzzle_cb["fired"] = true
		puzzle_cb["victory"] = vic
	)

	# Simulate 1 swap (allowed)
	director._on_swap_committed("player", "traffic_1", 1, 3)
	assert_false(puzzle_cb["fired"], "1 swap is allowed within limit")

	# Simulate 2nd swap (exceeds swap_limit of 1)
	director._on_swap_committed("player", "traffic_2", 3, 2)
	assert_true(puzzle_cb["fired"], "Exceeding swap limit must immediately terminate mission")
	assert_false(puzzle_cb["victory"], "Must fail with defeat")

func test_mission_director_time_expiration_failure() -> void:
	var engine = ColorSwapEngine.new()
	var director = MissionDirector.new(engine)
	var mission = MissionDatabase.get_mission_by_id("hunt_neon_01") # time_limit = 90.0

	director.start_mission(mission)
	var timeout_cb = {"fired": false, "victory": true}
	director.mission_completed.connect(func(vic, res):
		timeout_cb["fired"] = true
		timeout_cb["victory"] = vic
	)

	# Advance time past limit
	director.update(95.0)
	assert_true(timeout_cb["fired"], "Time expiration terminates mission")
	assert_false(timeout_cb["victory"], "Must fail on timeout")

func test_sprint_mode_time_bonus() -> void:
	var engine = ColorSwapEngine.new()
	var director = MissionDirector.new(engine)
	var mission = MissionDatabase.get_mission_by_id("sprint_neon_07") # Sprint mode

	director.start_mission(mission)
	var initial_time = director.time_remaining

	var v = ChromaVehicle.new()
	v.vehicle_owner_id = "player"
	v.initial_color = ChromaConstants.ChromaColor.COBALT
	v._ready()

	var gate = CheckpointGate.new()
	gate.gate_id = "gate_2"
	gate.target_color = ChromaConstants.ChromaColor.COBALT
	gate._ready()

	# Delivery in sprint mode should add +15s bonus time
	director.handle_checkpoint_reached(v, gate)
	assert_true(director.time_remaining > initial_time, "Checkpoint delivery in Sprint adds bonus time")

	v.free()
	gate.free()

func test_mission_retry() -> void:
	var engine = ColorSwapEngine.new()
	var director = MissionDirector.new(engine)
	var mission = MissionDatabase.get_mission_by_id("hunt_neon_01")

	director.start_mission(mission)
	director.score = 5000
	director.swaps_used = 4

	director.retry_mission()
	assert_eq(director.score, 0, "Score reset to 0 on retry")
	assert_eq(director.swaps_used, 0, "Swaps used reset to 0 on retry")
	assert_eq(director.current_objective_idx, 0, "Objective index reset to 0 on retry")

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/content/mission_database.gd", [
			"get_all_missions", "get_mission_by_id", "get_missions_for_mode",
			"validate_mission", "validate_all_missions"
		]],
		["res://games/chroma-rush/core/mission_director.gd", [
			"start_mission", "update", "handle_checkpoint_reached", "retry_mission",
			"get_current_target_color", "get_current_target_gate_id"
		]]
	]
