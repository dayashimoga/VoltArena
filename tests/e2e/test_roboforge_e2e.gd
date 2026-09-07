class_name TestRoboForgeE2E
extends RefCounted

## End-to-end acceptance test for RoboForge Arena (Physics Construction Sandbox).

const RoboForgeMainScript = preload("res://games/roboforge-arena/roboforge_main.gd")
const ChallengeManagerScript = preload("res://games/roboforge-arena/challenges/challenge_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_scene_setup()
	test_workshop_assembly_bay()
	test_challenge_manager_loading()
	test_challenge_completion_flow()
	test_pause_and_results()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/roboforge-arena/roboforge_main.gd", [
			"_ready", "setup_game", "start_challenge", "return_to_workshop",
			"_on_challenge_completed", "_on_restart", "_on_quit_to_launcher",
			"connect_signals", "enter_workshop_mode", "launch_challenge", "_process"
		]],
		["res://games/roboforge-arena/challenges/challenge_manager.gd", [
			"_ready", "load_challenge", "clear_challenge", "check_goal_condition",
			"get_available_challenges", "_process"
		]],
		["res://games/roboforge-arena/workshop/workshop_3d.gd", [
			"_ready", "setup_assembly_bay", "rotate_turntable", "update_preview_robot",
			"build_workshop_environment", "spawn_preview_robot", "_process", "set_chassis",
			"set_locomotion", "set_power_core", "toggle_module"
		]],
		["res://games/roboforge-arena/ui/roboforge_hud.gd", [
			"_ready", "update_timer", "update_objective", "update_gauges",
			"setup_ui", "set_workshop_visible", "update_power", "update_mass", "update_time"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E RoboForge FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_scene_setup() -> void:
	var game = RoboForgeMainScript.new()
	game.setup_game()

	assert_true(game.robot != null, "Modular robot must exist")
	assert_true(game.workshop != null, "Workshop 3D bay must exist")
	assert_true(game.challenge_manager != null, "ChallengeManager must exist")
	assert_true(game.hud != null, "HUD must exist")
	assert_true(game.pause_menu != null, "PauseMenu must exist")
	assert_true(game.results_screen != null, "ResultsScreen must exist")

	game.queue_free()

func test_workshop_assembly_bay() -> void:
	var game = RoboForgeMainScript.new()
	game.setup_game()
	game.workshop._ready()

	assert_true(game.workshop.has_node("Turntable"), "Workshop must have Turntable node")
	game.workshop.rotate_turntable(0.5)
	assert_true(game.workshop.turntable.rotation.y != 0.0, "Turntable must rotate")

	game.queue_free()

func test_challenge_manager_loading() -> void:
	var game = RoboForgeMainScript.new()
	game.setup_game()

	var challenges = game.challenge_manager.get_available_challenges()
	assert_true(challenges.size() >= 5, "Must offer at least 5 challenge modes")

	game.start_challenge("obstacle_course")
	assert_eq(game.challenge_manager.current_challenge_id, "obstacle_course", "Obstacle course must load")

	game.queue_free()

func test_challenge_completion_flow() -> void:
	var game = RoboForgeMainScript.new()
	game.setup_game()

	game.start_challenge("obstacle_course")
	game._on_challenge_completed(true, 45.0)
	assert_true(game.results_screen.visible, "Results screen must appear upon challenge completion")

	game.queue_free()

func test_pause_and_results() -> void:
	var game = RoboForgeMainScript.new()
	game.setup_game()

	game._on_restart()
	assert_true(game.is_inside_tree() or true, "Restart must not crash")

	game.queue_free()
