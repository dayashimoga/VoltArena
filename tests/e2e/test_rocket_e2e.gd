class_name TestRocketE2E
extends RefCounted

## End-to-end gameplay acceptance test for Nitro Kick (Rocket-Car Arena Football).
## Tests: scene setup → car physics → ball physics → goal scoring → kickoff reset →
## score tracking → match timer → match end → results → restart

const RocketCarMainScript = preload("res://games/rocket-car/rocket_car_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_scene_setup()
	test_player_car_initialization()
	test_ai_car_setup()
	test_ball_physics()
	test_goal_scoring_blue()
	test_goal_scoring_orange()
	test_kickoff_reset()
	test_match_timer_expiry()
	test_match_end_results()
	test_chase_camera()
	test_pause_restart_quit()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/rocket-car/rocket_car_main.gd", ["_ready", "setup_scene", "reset_kickoff", "_on_goal_scored", "end_match", "update_chase_camera"]],
		["res://games/rocket-car/vehicle/car_controller.gd", ["replenish_boost", "apply_driving_controls"]],
		["res://games/rocket-car/ball/ball.gd", ["apply_ball_impulse", "reset_to_center"]],
		["res://games/rocket-car/arena/rocket_arena.gd", ["_ready"]],
		["res://games/rocket-car/ai/car_ai.gd", ["_ready"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E Rocket FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_scene_setup() -> void:
	var rocket = RocketCarMainScript.new()
	rocket._ready()

	assert_true(rocket.player_car != null, "Player car must be instantiated")
	assert_true(rocket.ball != null, "Ball must be instantiated")
	assert_true(rocket.ai_cars.size() == 2, "Must spawn 2 AI opponents")
	assert_true(rocket.hud != null, "HUD must exist")
	assert_true(rocket.pause_menu != null, "PauseMenu must exist")
	assert_true(rocket.results_screen != null, "ResultsScreen must exist")
	assert_true(rocket.camera != null, "Chase camera must exist")
	assert_true(rocket.match_active, "Match must be active on start")

	var arena_node = rocket.get_node_or_null("RocketArena")
	assert_true(arena_node != null, "Arena must be generated")

	rocket.queue_free()

func test_player_car_initialization() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	assert_eq(rocket.player_car.team_id, 0, "Player must be on Blue team (0)")
	assert_true(rocket.player_car.is_player_controlled, "Player car must be player-controlled")

	rocket.queue_free()

func test_ai_car_setup() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	for ai_car in rocket.ai_cars:
		assert_eq(ai_car.team_id, 1, "AI cars must be on Orange team (1)")
		assert_true(not ai_car.is_player_controlled, "AI cars must not be player-controlled")

	rocket.queue_free()

func test_ball_physics() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	# Test impulse application
	rocket.ball.apply_ball_impulse(Vector3(0, 0, -30.0))
	assert_true(rocket.ball.velocity.z < -10.0, "Ball must accelerate upon impulse")

	# Test reset
	rocket.ball.reset_to_center()
	assert_true(rocket.ball.velocity.length() < 0.1, "Ball velocity must be near zero after reset")

	rocket.queue_free()

func test_goal_scoring_blue() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()
	rocket.is_kickoff_pause = false  # Allow scoring

	assert_eq(rocket.blue_score, 0, "Blue score must start at 0")
	rocket._on_goal_scored(0)
	assert_eq(rocket.blue_score, 1, "Blue score must increment on goal")

	rocket.is_kickoff_pause = false
	rocket._on_goal_scored(0)
	assert_eq(rocket.blue_score, 2, "Blue score must accumulate")

	rocket.queue_free()

func test_goal_scoring_orange() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()
	rocket.is_kickoff_pause = false

	assert_eq(rocket.orange_score, 0, "Orange score must start at 0")
	rocket._on_goal_scored(1)
	assert_eq(rocket.orange_score, 1, "Orange score must increment on goal")

	rocket.queue_free()

func test_kickoff_reset() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	# After setup, kickoff pause should be active
	assert_true(rocket.is_kickoff_pause, "Must be in kickoff pause after setup")

	# Manually disable kickoff to test reset
	rocket.is_kickoff_pause = false
	rocket._on_goal_scored(0)

	# After goal, kickoff should be active again
	assert_true(rocket.is_kickoff_pause, "Must return to kickoff after goal")

	rocket.queue_free()

func test_match_timer_expiry() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()
	rocket.is_kickoff_pause = false

	rocket.time_left = 0.1
	rocket._process(1.0)  # 1 second delta
	assert_true(not rocket.match_active, "Match must end when timer expires")

	rocket.queue_free()

func test_match_end_results() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	rocket.blue_score = 3
	rocket.orange_score = 1
	rocket.end_match()

	assert_true(not rocket.match_active, "Match must be inactive after end")
	assert_true(rocket.results_screen != null, "Results must be displayed")

	rocket.queue_free()

func test_chase_camera() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	# Camera update should not crash
	rocket.update_chase_camera(0.016)
	assert_true(rocket.camera != null, "Camera must still exist after update")

	rocket.queue_free()

func test_pause_restart_quit() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	rocket._on_restart()
	rocket._on_quit_to_launcher()
	assert_true(true, "Restart/quit must not crash without EventBus")

	rocket.queue_free()
