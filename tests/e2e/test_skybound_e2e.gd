class_name TestSkyboundE2E
extends RefCounted

## End-to-end gameplay acceptance test for Skybound Odyssey (Open-Air 3D Platformer).

const SkyboundMainScript = preload("res://games/skybound-odyssey/skybound_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_scene_setup()
	test_player_character_setup()
	test_world_regions_and_landmarks()
	test_puzzle_elements()
	test_quest_progression()
	test_pause_and_results_screens()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/skybound-odyssey/skybound_main.gd", [
			"_ready", "setup_game", "initialize_quest_lines",
			"_on_shard_collected", "_on_quest_completed",
			"_on_all_quests_finished", "_on_restart", "_on_quit_to_launcher",
			"connect_signals", "complete_odyssey"
		]],
		["res://games/skybound-odyssey/world/skybound_world.gd", [
			"_ready", "build_world", "unlock_region", "get_region_node",
			"build_emerald_isles", "build_crystal_caverns", "build_sky_temple",
			"build_frost_peaks", "build_storm_citadel"
		]],
		["res://games/skybound-odyssey/ui/skybound_hud.gd", [
			"_ready", "update_shards", "update_stamina", "set_active_quest", "show_region_banner",
			"setup_ui", "update_region", "update_quest"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E Skybound FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_scene_setup() -> void:
	var game = SkyboundMainScript.new()
	game.setup_game()

	assert_true(game.player != null, "Player character must be instantiated")
	assert_true(game.world != null, "SkyboundWorld must be instantiated")
	assert_true(game.hud != null, "HUD must be instantiated")
	assert_true(game.orbit_camera != null, "Orbit camera must exist")
	assert_true(game.quest_manager != null, "Quest manager must exist")
	assert_true(game.pause_menu != null, "Pause menu must exist")
	assert_true(game.results_screen != null, "Results screen must exist")

	game.queue_free()

func test_player_character_setup() -> void:
	var game = SkyboundMainScript.new()
	game.setup_game()

	assert_true(game.player.max_stamina > 50.0, "Player must have positive stamina")
	assert_true(game.player.position.y >= 0.0, "Player must spawn at ground level")

	game.queue_free()

func test_world_regions_and_landmarks() -> void:
	var game = SkyboundMainScript.new()
	game.setup_game()

	var expected_regions = [
		"Emerald Isles", "Crystal Caverns", "Sunken Sky Temple",
		"Frost Peaks", "Storm Citadel"
	]
	for region_name in expected_regions:
		var node = game.world.get_region_node(region_name)
		assert_true(node != null, "Region node %s must exist in world" % region_name)

	game.queue_free()

func test_puzzle_elements() -> void:
	var game = SkyboundMainScript.new()
	game.setup_game()

	var PuzzleElementsScript = preload("res://shared/gameplay/puzzle_elements.gd")
	var plate = PuzzleElementsScript.PressurePlate.new()
	var door = PuzzleElementsScript.PuzzleDoor.new()
	door.register_trigger(plate.state_changed)
	assert_true(not door.is_open, "Door must start closed")

	plate._on_body_entered(game.player)
	assert_true(door.is_open, "Door must open when plate is pressed")

	plate._on_body_exited(game.player)
	assert_true(not door.is_open, "Door must close when plate is released")

	plate.queue_free()
	door.queue_free()
	game.queue_free()

func test_quest_progression() -> void:
	var game = SkyboundMainScript.new()
	game.setup_game()

	var active_quests = game.quest_manager.get_active_quests()
	assert_true(active_quests.size() > 0, "Must have active starter quest")
	assert_true(active_quests[0].id == "quest_emerald", "Starter quest quest_emerald must be active")

	# Collect shards
	game._on_shard_collected("shard_test_1")
	assert_true(game.collected_shards_count == 1, "Collected shards count must increment")

	game.queue_free()

func test_pause_and_results_screens() -> void:
	var game = SkyboundMainScript.new()
	game.setup_game()

	game._on_all_quests_finished()
	assert_true(game.results_screen.visible, "Results screen must display on finish")

	game.queue_free()
