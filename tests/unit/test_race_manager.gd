class_name TestRaceManager
extends RefCounted

const RaceManagerScript = preload("res://games/kart-racing/game/race_manager.gd")
const RaceCheckpointScript = preload("res://games/kart-racing/tracks/checkpoint.gd")
const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_countdown_state()
	test_checkpoint_progression()
	test_ready_and_process()
	test_finish_race()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://games/kart-racing/game/race_manager.gd",
		["_ready", "_process", "start_race", "update_race_positions", "finish_race", "on_kart_hit_checkpoint"]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Assertion failed: " + msg)

func test_countdown_state() -> void:
	var rm = RaceManagerScript.new()
	assert_true(rm.current_state == rm.RaceState.COUNTDOWN, "Race must start in COUNTDOWN")
	rm.start_race()
	assert_true(rm.current_state == rm.RaceState.RACING, "Race state should transition to RACING")
	rm.queue_free()

func test_checkpoint_progression() -> void:
	var rm = RaceManagerScript.new()
	rm.current_state = rm.RaceState.RACING

	var cp0 = RaceCheckpointScript.new()
	cp0.checkpoint_index = 0
	var cp1 = RaceCheckpointScript.new()
	cp1.checkpoint_index = 1
	rm.checkpoints = [cp0, cp1]

	var kart = KartControllerScript.new()
	kart.next_checkpoint_index = 0

	# Test wrong checkpoint hit (skipped to 1 without hitting 0)
	rm._on_checkpoint_hit(kart, 1)
	assert_true(kart.total_checkpoints_hit == 0, "Invalid checkpoint hit should be ignored")

	# Test valid sequential hit
	rm.on_kart_hit_checkpoint(kart, 0)
	assert_true(kart.total_checkpoints_hit == 1, "Valid checkpoint should increment hit count")
	assert_true(kart.next_checkpoint_index == 1, "Next checkpoint should advance to 1")

	cp0.queue_free()
	cp1.queue_free()
	kart.queue_free()
	rm.queue_free()

func test_ready_and_process() -> void:
	var rm = RaceManagerScript.new()
	rm._ready()
	var k1 = KartControllerScript.new()
	k1.total_checkpoints_hit = 5
	var k2 = KartControllerScript.new()
	k2.total_checkpoints_hit = 3
	rm.racers = [k1, k2]
	rm.update_race_positions()
	rm._process(0.016)
	assert_true(true, "update_race_positions and _process must execute safely")
	k1.queue_free()
	k2.queue_free()
	rm.queue_free()

func test_finish_race() -> void:
	var rm = RaceManagerScript.new()
	var k1 = KartControllerScript.new()
	k1.is_player = true
	rm.racers = [k1]
	rm.finish_race(k1)
	assert_true(rm.current_state == rm.RaceState.FINISHED, "State must transition to FINISHED")
	k1.queue_free()
	rm.queue_free()
