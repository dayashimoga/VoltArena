class_name TestWildCircuitE2E
extends RefCounted

## End-to-end acceptance test for WildCircuit (Wildlife Safari & Photography Traversal).

const WildCircuitMainScript = preload("res://games/wildcircuit/wildcircuit_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_scene_setup()
	test_biomes_generation()
	test_wildlife_populations()
	test_atv_vehicle_traversal()
	test_photography_viewfinder_scoring()
	test_expedition_completion()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/wildcircuit/wildcircuit_main.gd", [
			"_ready", "setup_game", "toggle_camera_view", "take_photograph",
			"mount_or_dismount_atv", "_on_expedition_finished", "_on_restart", "_on_quit_to_launcher",
			"connect_signals", "_process", "handle_player_movement", "handle_camera_aim",
			"toggle_camera_mode", "scan_viewport_for_wildlife", "capture_photograph", "complete_expedition"
		]],
		["res://games/wildcircuit/world/wild_biomes.gd", [
			"_ready", "generate_all_biomes", "get_biome_node",
			"build_all_biomes", "build_savannah", "build_rainforest",
			"build_alpine_forest", "build_tropical_coast", "build_wetlands"
		]],
		["res://games/wildcircuit/traversal/explorer_atv.gd", [
			"_ready", "_physics_process", "mount", "dismount",
			"setup_visuals", "handle_driving"
		]],
		["res://games/wildcircuit/ui/wildcircuit_hud.gd", [
			"_ready", "set_viewfinder_active", "update_zoom_display", "show_photo_feedback",
			"setup_ui", "toggle_viewfinder", "update_subject_info", "update_zoom",
			"update_biome", "update_time_display", "show_photo_result"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E WildCircuit FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_scene_setup() -> void:
	var game = WildCircuitMainScript.new()
	game.setup_game()

	assert_true(game.biomes != null, "WildBiomes must exist")
	assert_true(game.camera_mode != null, "CameraMode must exist")
	assert_true(game.field_journal != null, "FieldJournal must exist")
	assert_true(game.hud != null, "HUD must exist")
	assert_true(game.pause_menu != null, "PauseMenu must exist")
	assert_true(game.results_screen != null, "ResultsScreen must exist")

	game.queue_free()

func test_biomes_generation() -> void:
	var game = WildCircuitMainScript.new()
	game.setup_game()

	var expected_biomes = ["savannah", "rainforest", "alpine", "coast", "wetlands"]
	for b_id in expected_biomes:
		var b_node = game.biomes.get_biome_node(b_id)
		assert_true(b_node != null, "Biome node for %s must be present" % b_id)

	game.queue_free()

func test_wildlife_populations() -> void:
	var game = WildCircuitMainScript.new()
	game.setup_game()

	assert_true(game.spawned_animals.size() >= 5, "At least 5 animals must be spawned across biomes")

	game.queue_free()

func test_atv_vehicle_traversal() -> void:
	var game = WildCircuitMainScript.new()
	game.setup_game()

	assert_true(game.atv != null, "Explorer ATV must exist")
	assert_true(not game.atv.is_mounted, "ATV should start unmounted")

	game.atv.mount(game.player_character)
	assert_true(game.atv.is_mounted, "ATV should be mounted")

	game.atv.dismount()
	assert_true(not game.atv.is_mounted, "ATV should be dismounted")

	game.queue_free()

func test_photography_viewfinder_scoring() -> void:
	var game = WildCircuitMainScript.new()
	game.setup_game()

	game.toggle_camera_view()
	assert_true(game.camera_mode.is_active, "Viewfinder mode must be active after toggle")

	game.toggle_camera_view()
	assert_true(not game.camera_mode.is_active, "Viewfinder mode must deactivate on toggle")

	game.queue_free()

func test_expedition_completion() -> void:
	var game = WildCircuitMainScript.new()
	game.setup_game()

	game._on_expedition_finished()
	assert_true(game.results_screen.visible, "Results screen must appear on expedition finish")

	game.queue_free()
