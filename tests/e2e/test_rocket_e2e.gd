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
	test_ball_kickoff_to_goal_scoring_flow()
	test_goal_scoring_blue()
	test_goal_scoring_orange()
	test_kickoff_reset()
	test_match_timer_expiry()
	test_match_end_results()
	test_chase_camera()
	test_pause_restart_quit()
	test_modes_and_vehicles()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/rocket-car/rocket_car_main.gd", ["_ready", "setup_scene", "reset_kickoff", "_on_goal_scored", "end_match", "update_chase_camera", "select_game_mode", "select_car_vehicle", "get_available_modes", "get_available_cars"]],
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
	assert_true(rocket.ai_cars.size() >= 2, "Must spawn AI opponents")
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

	for ai_car in rocket.orange_ai_cars:
		assert_eq(ai_car.team_id, 1, "AI opponents must be on Orange team (1)")
		assert_true(not ai_car.is_player_controlled, "AI cars must not be player-controlled")
	for ai_car in rocket.blue_ai_cars:
		assert_eq(ai_car.team_id, 0, "AI teammates must be on Blue team (0)")
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

func test_ball_kickoff_to_goal_scoring_flow() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()
	rocket.is_kickoff_pause = false

	# 1. Kickoff state: Ball at center
	var b_pos = rocket.ball.global_position if rocket.ball.is_inside_tree() else rocket.ball.position
	assert_true(b_pos.distance_to(Vector3(0, rocket.ball.radius + 0.6, 0)) < 1.0, "Ball starts at center kickoff")

	# 2. Player car accelerates towards ball
	rocket.player_car.apply_driving_controls(1.0, 0.0, 0.5)
	rocket.player_car.velocity = Vector3(0, 0, -20.0)

	# 3. Car strikes ball -> simulate collision contact
	rocket.player_car._apply_ball_hit(rocket.ball, Vector3(0, 0, 1.0))

	# 4. Assert ball displacement & velocity
	assert_true(rocket.ball.velocity.length() > 10.0, "Ball must gain >=10 m/s velocity on impact")
	assert_true(rocket.ball.velocity.z < -5.0, "Ball must be driven towards North/Orange goal (-Z)")

	# 5. Push ball into Orange goal trigger (North goal at z = -55.0)
	rocket.ball.global_position = Vector3(0, 3.0, -56.0)
	rocket._on_goal_scored(0) # Blue scores into Orange goal!

	# 6. Goal trigger -> score 0 -> 1
	assert_eq(rocket.blue_score, 1, "Blue score must increment from 0 to 1")

	# 7. Celebration & Kickoff reset
	assert_true(rocket.is_kickoff_pause, "Kickoff pause must activate after goal")
	rocket.reset_kickoff()
	assert_true(rocket.ball.velocity.length() < 0.1, "Ball velocity must be reset to zero at kickoff")

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

func test_modes_and_vehicles() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()

	var modes = rocket.get_available_modes()
	assert_true(modes.size() >= 4, "Must have at least 4 game modes")
	assert_true("1v1" in modes and "2v2" in modes and "3v3" in modes and "target_challenge" in modes, "Must support standard and challenge modes")

	var cars = rocket.get_available_cars()
	assert_true(cars.size() >= 3, "Must have at least 3 vehicles")

	rocket.select_game_mode("1v1")
	assert_eq(rocket.game_mode, "1v1", "Game mode must switch to 1v1")

	rocket.select_car_vehicle("speed_demon")
	assert_eq(rocket.selected_vehicle, "speed_demon", "Vehicle must switch to speed_demon")

	rocket.select_car_vehicle("turbo_truck")
	rocket.select_car_vehicle("phantom")

	rocket.queue_free()

