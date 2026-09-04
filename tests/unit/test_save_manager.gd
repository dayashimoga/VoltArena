class_name TestSaveManager
extends RefCounted

const SaveManagerScript = preload("res://shared/save/save_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_default_structure()
	test_record_stats()
	test_all_game_records()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/save/save_manager.gd",
		[
			"_ready", "get_default_save", "load_save", "save_game",
			"record_arena_match", "record_subway_run",
			"record_rocket_match", "record_kart_race"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Assertion failed: " + msg)

func test_default_structure() -> void:
	var sm = SaveManagerScript.new()
	var def = sm.get_default_save()
	assert_true(def.has("statistics"), "Save must contain statistics section")
	assert_true(def["statistics"].has("arena_fps"), "Must contain arena_fps stats")
	assert_true(def["statistics"].has("subway_survival"), "Must contain subway_survival stats")
	assert_true(def["statistics"].has("rocket_car"), "Must contain rocket_car stats")
	assert_true(def["statistics"].has("kart_racing"), "Must contain kart_racing stats")

func test_record_stats() -> void:
	var sm = SaveManagerScript.new()
	sm.save_data = sm.get_default_save()
	sm.record_arena_match(12, 3, 1200, true)

	var arena_stats = sm.save_data["statistics"]["arena_fps"]
	assert_true(arena_stats["matches_played"] == 1, "Matches played should be 1")
	assert_true(arena_stats["kills"] == 12, "Kills should be 12")
	assert_true(arena_stats["highest_score"] == 1200, "High score should be 1200")
	assert_true(arena_stats["wins"] == 1, "Wins should be 1")

func test_all_game_records() -> void:
	var sm = SaveManagerScript.new()
	sm.save_data = sm.get_default_save()
	sm.record_subway_run(5, 45, 2300)
	assert_true(sm.save_data["statistics"]["subway_survival"]["highest_wave"] == 5, "Subway highest wave must be 5")

	sm.record_rocket_match(4, 2, true)
	assert_true(sm.save_data["statistics"]["rocket_car"]["goals_scored"] == 4, "Rocket goals scored must be 4")

	sm.record_kart_race("track_1", 45.2, true)
	assert_true(sm.save_data["statistics"]["kart_racing"]["podiums"] == 1, "Kart podiums must be 1")
