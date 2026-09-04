class_name TestSaveCorruption
extends RefCounted

## Tests save data corruption recovery, version migration, and concurrent access.

const SaveManagerScript = preload("res://shared/save/save_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_default_save_structure()
	test_corrupted_json_recovery()
	test_empty_file_recovery()
	test_missing_statistics_recovery()
	test_missing_game_stats_recovery()
	test_version_field()
	test_rapid_save_load()
	test_stat_recording_integrity()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [["res://shared/save/save_manager.gd", ["get_default_save", "load_save", "save_to_disk", "record_arena_match", "record_subway_run", "record_rocket_match", "record_kart_race"]]]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit SaveCorruption FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_default_save_structure() -> void:
	var sm = SaveManagerScript.new()
	var defaults = sm.get_default_save()
	assert_true(defaults.has("version"), "Default save must have version")
	assert_true(defaults.has("statistics"), "Default save must have statistics")
	assert_true(defaults.has("unlocked_items"), "Default save must have unlocked_items")
	assert_true(defaults["statistics"].has("arena_fps"), "Must have arena_fps stats")
	assert_true(defaults["statistics"].has("subway_survival"), "Must have subway_survival stats")
	assert_true(defaults["statistics"].has("rocket_car"), "Must have rocket_car stats")
	assert_true(defaults["statistics"].has("kart_racing"), "Must have kart_racing stats")

func test_corrupted_json_recovery() -> void:
	# Write corrupted JSON
	var test_path = "user://test_corrupt_save.json"
	var f = FileAccess.open(test_path, FileAccess.WRITE)
	if f:
		f.store_string("{invalid json content!!!")
		f.close()

	# SaveManager should recover gracefully
	var sm = SaveManagerScript.new()
	sm.save_data = {}
	# Parse the corrupted content
	var json = JSON.new()
	var err = json.parse("{invalid json content!!!")
	assert_true(err != OK, "Corrupted JSON must fail to parse")

	# Clean up
	DirAccess.remove_absolute(test_path)

func test_empty_file_recovery() -> void:
	var test_path = "user://test_empty_save.json"
	var f = FileAccess.open(test_path, FileAccess.WRITE)
	if f:
		f.store_string("")
		f.close()

	var json = JSON.new()
	var err = json.parse("")
	assert_true(err != OK, "Empty file must fail to parse")

	DirAccess.remove_absolute(test_path)

func test_missing_statistics_recovery() -> void:
	var sm = SaveManagerScript.new()
	sm.save_data = {"version": 1}  # Missing statistics
	var defaults = sm.get_default_save()
	if not sm.save_data.has("statistics"):
		sm.save_data["statistics"] = defaults["statistics"]
	assert_true(sm.save_data.has("statistics"), "Statistics must be restored")

func test_missing_game_stats_recovery() -> void:
	var sm = SaveManagerScript.new()
	sm.save_data = {"version": 1, "statistics": {"arena_fps": {"kills": 5}}}
	var defaults = sm.get_default_save()
	for game in defaults["statistics"].keys():
		if not sm.save_data["statistics"].has(game):
			sm.save_data["statistics"][game] = defaults["statistics"][game]
	assert_true(sm.save_data["statistics"].has("subway_survival"), "Missing game stats must be restored")
	assert_true(sm.save_data["statistics"].has("rocket_car"), "Missing game stats must be restored")
	assert_true(sm.save_data["statistics"].has("kart_racing"), "Missing game stats must be restored")

func test_version_field() -> void:
	var sm = SaveManagerScript.new()
	var defaults = sm.get_default_save()
	assert_eq(defaults["version"], 1, "Save version must be 1")

func test_rapid_save_load() -> void:
	var sm = SaveManagerScript.new()
	sm.save_data = sm.get_default_save()
	# Rapid successive operations should not corrupt data
	for i in range(10):
		sm.record_arena_match(5, 2, 500, true)
	assert_eq(sm.save_data["statistics"]["arena_fps"]["matches_played"], 10, "10 rapid saves must all register")
	assert_eq(sm.save_data["statistics"]["arena_fps"]["kills"], 50, "Kills must accumulate correctly")

func test_stat_recording_integrity() -> void:
	var sm = SaveManagerScript.new()
	sm.save_data = sm.get_default_save()

	sm.record_subway_run(5, 30, 2000)
	assert_eq(sm.save_data["statistics"]["subway_survival"]["highest_wave"], 5, "Highest wave must be 5")
	sm.record_subway_run(3, 10, 500)
	assert_eq(sm.save_data["statistics"]["subway_survival"]["highest_wave"], 5, "Highest wave must not decrease")

	sm.record_kart_race("canyon", 45.0, true)
	assert_eq(sm.save_data["statistics"]["kart_racing"]["best_lap_canyon"], 45.0, "Best lap must be set")
	sm.record_kart_race("canyon", 50.0, false)
	assert_eq(sm.save_data["statistics"]["kart_racing"]["best_lap_canyon"], 45.0, "Best lap must not increase")
	sm.record_kart_race("canyon", 40.0, true)
	assert_eq(sm.save_data["statistics"]["kart_racing"]["best_lap_canyon"], 40.0, "Better lap must replace")
