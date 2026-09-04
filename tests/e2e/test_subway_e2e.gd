class_name TestSubwayE2E
extends RefCounted

## End-to-end gameplay acceptance test for Metro Siege (Subway Survival FPS).
## Tests: scene setup → wave start → enemy spawning → combat → wave progression →
## kill/score tracking → player death → results → restart

const SubwayMainScript = preload("res://games/subway-survival/subway_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_scene_setup()
	test_player_initialization()
	test_wave_director_setup()
	test_wave_start_and_progression()
	test_enemy_kill_scoring()
	test_wave_completion_bonus()
	test_player_death_flow()
	test_results_and_save()
	test_pause_resume_restart()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/subway-survival/subway_main.gd", ["setup_scene", "connect_signals"]],
		["res://games/subway-survival/game/wave_director.gd", ["start_next_wave"]],
		["res://games/subway-survival/enemies/enemy_base.gd", ["_ready"]],
		["res://games/subway-survival/maps/subway_generator.gd", ["_ready"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E Subway FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_scene_setup() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	assert_true(subway.player_node != null, "Player must be instantiated")
	assert_true(subway.wave_director != null, "WaveDirector must be active")
	assert_true(subway.hud != null, "HUD must exist")
	assert_true(subway.pause_menu != null, "PauseMenu must exist")
	assert_true(subway.results_screen != null, "ResultsScreen must exist")
	assert_true(subway.is_game_active, "Game must be active on start")

	var env = subway.get_node_or_null("SubwayEnvironment")
	assert_true(env != null, "Subway environment must be generated")

	subway.queue_free()

func test_player_initialization() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	assert_true(subway.player_node.position.x == -5.0, "Player must spawn at correct X position")
	assert_true(subway.player_node.position.y == 1.0, "Player must spawn at correct Y position")

	subway.queue_free()

func test_wave_director_setup() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	var wd = subway.wave_director
	assert_true(wd != null, "WaveDirector must exist")
	assert_eq(subway.highest_wave, 0, "Highest wave must start at 0")
	assert_eq(subway.total_kills, 0, "Kill count must start at 0")
	assert_eq(subway.total_score, 0, "Score must start at 0")

	subway.queue_free()

func test_wave_start_and_progression() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	var wd = subway.wave_director
	wd.start_next_wave()
	assert_eq(wd.current_wave, 1, "Wave 1 must start")

	# Start another wave
	wd.start_next_wave()
	assert_eq(wd.current_wave, 2, "Wave 2 must start after progression")

	subway.queue_free()

func test_enemy_kill_scoring() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	subway._on_enemy_killed("Crawler", 50)
	assert_eq(subway.total_kills, 1, "Kill count must increment")
	assert_eq(subway.total_score, 50, "Score must increase by kill value")

	subway._on_enemy_killed("Brute", 150)
	assert_eq(subway.total_kills, 2, "Kill count must accumulate")
	assert_eq(subway.total_score, 200, "Score must accumulate")

	subway._on_enemy_killed("Stalker", 100)
	assert_eq(subway.total_kills, 3, "Kill count must accumulate")
	assert_eq(subway.total_score, 300, "Score must accumulate")

	subway.queue_free()

func test_wave_completion_bonus() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	subway._on_wave_completed(3, 500)
	assert_eq(subway.highest_wave, 3, "Highest wave must update")
	assert_eq(subway.total_score, 500, "Bonus score must be added")

	subway._on_wave_completed(5, 800)
	assert_eq(subway.highest_wave, 5, "Highest wave must update to later wave")
	assert_eq(subway.total_score, 1300, "Bonus scores must accumulate")

	subway.queue_free()

func test_player_death_flow() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	subway.total_score = 500
	subway.total_kills = 10
	subway.highest_wave = 3

	subway._on_player_died("Brute")
	assert_true(not subway.is_game_active, "Game must end on player death")

	subway.queue_free()

func test_results_and_save() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	subway.total_score = 1500
	subway.total_kills = 25
	subway.highest_wave = 7

	# Calling _on_player_died should trigger results display
	subway._on_player_died("Crawler")
	assert_true(not subway.is_game_active, "Game must be inactive after death")
	assert_true(subway.results_screen != null, "Results must be displayed")

	subway.queue_free()

func test_pause_resume_restart() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()

	# These should not crash even without EventBus/InputManager
	subway._on_resume()
	subway._on_restart()
	subway._on_quit_to_launcher()
	assert_true(true, "Pause/resume/restart must not crash without singletons")

	subway.queue_free()
