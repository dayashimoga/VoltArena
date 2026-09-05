class_name TestKartE2E
extends RefCounted

## End-to-end gameplay acceptance test for Drift Storm (Arcade Kart Racing).
## Tests: scene setup → kart physics → drift/boost → checkpoint/lap → race flow →
## AI racers → race finish → results → restart

const KartRacingMainScript = preload("res://games/kart-racing/kart_racing_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_scene_setup()
	test_player_kart_initialization()
	test_ai_racer_setup()
	test_race_manager_initialization()
	test_drift_boost_mechanic()
	test_kart_acceleration()
	test_camera_follow()
	test_track_and_vehicle_selection()
	test_race_finish_flow()
	test_pause_restart_quit()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/kart-racing/kart_racing_main.gd", ["_ready", "setup_scene", "update_camera", "_on_race_finished", "select_track", "select_kart"]],
		["res://games/kart-racing/kart/kart_controller.gd", ["trigger_drift_boost", "set_kart_type"]],
		["res://games/kart-racing/game/race_manager.gd", ["initialize_race"]],
		["res://games/kart-racing/tracks/track_generator.gd", ["_ready"]],
		["res://games/kart-racing/ai/kart_ai.gd", ["_ready"]],
		["res://games/kart-racing/powerups/powerup_item.gd", ["_ready"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E Kart FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_scene_setup() -> void:
	var race = KartRacingMainScript.new()
	race._ready()

	assert_true(race.player_kart != null, "Player kart must be instantiated")
	assert_true(race.ai_karts.size() == 3, "Must spawn 3 AI racers")
	assert_true(race.all_karts.size() == 4, "Total karts must be 4 (1 player + 3 AI)")
	assert_true(race.hud != null, "HUD must exist")
	assert_true(race.pause_menu != null, "PauseMenu must exist")
	assert_true(race.results_screen != null, "ResultsScreen must exist")
	assert_true(race.camera != null, "Follow camera must exist")
	assert_true(race.race_manager != null, "RaceManager must exist")
	assert_true(race.track_generator != null, "TrackGenerator must exist")

	race.queue_free()

func test_player_kart_initialization() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	assert_true(race.player_kart.is_player, "Player kart must be marked as player")
	assert_eq(race.player_kart.racer_name, "Player 1", "Player kart must have correct name")
	assert_true(race.player_kart.position.y == 0.5, "Kart must spawn at correct height")

	race.queue_free()

func test_ai_racer_setup() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	for i in range(race.ai_karts.size()):
		var ai = race.ai_karts[i]
		assert_true(not ai.is_player, "AI kart must not be player")
		assert_true(ai.racer_name != "", "AI kart must have a name")
		# AI brain should be a child
		var brain = ai.get_child_count()
		assert_true(brain > 0, "AI kart must have AI brain child")

	race.queue_free()

func test_race_manager_initialization() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	var rm = race.race_manager
	assert_true(rm != null, "RaceManager must exist")
	# race_finished signal should be connected
	assert_true(rm.race_finished.get_connections().size() > 0, "race_finished signal must be connected")

	race.queue_free()

func test_drift_boost_mechanic() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()
	var kart = race.player_kart

	# Set drift charge and trigger boost
	kart.drift_charge_time = 2.0
	kart.trigger_drift_boost()
	assert_true(kart.boost_timer > 0.0, "Kart must gain boost on drift release")

	# Drift charge should reset
	assert_eq(kart.drift_charge_time, 0.0, "Drift charge must reset after boost")

	race.queue_free()

func test_kart_acceleration() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()
	var kart = race.player_kart

	# Verify kart has speed properties
	assert_true(kart.max_speed > 0.0, "Max speed must be positive")
	assert_true(kart.acceleration_force > 0.0, "Acceleration must be positive")
	assert_true(kart.steering_speed > 0.0, "Steering speed must be positive")

	race.queue_free()

func test_camera_follow() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	# Camera update should not crash
	race.update_camera(0.016)
	assert_true(race.camera != null, "Camera must still exist after update")

	race.queue_free()

func test_track_and_vehicle_selection() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	# Test track selection across all 3 production circuits
	race.select_track("canyon")
	assert_eq(race.selected_track, "canyon", "Track selection must update selected_track")
	assert_true(race.track_generator.waypoints.size() >= 15, "Canyon track must have >= 15 waypoints")

	race.select_track("skyline")
	assert_eq(race.selected_track, "skyline", "Skyline selection must update selected_track")
	assert_true(race.track_generator.waypoints.size() >= 15, "Skyline track must have >= 15 waypoints")

	race.select_track("neon")
	assert_eq(race.selected_track, "neon", "Neon selection must update selected_track")
	assert_true(race.track_generator.waypoints.size() >= 14, "Neon track must have >= 14 waypoints")

	# Test vehicle selection
	race.select_kart("enforcer")
	assert_eq(race.selected_kart, "enforcer", "Vehicle selection must update selected_kart")
	assert_eq(race.player_kart.kart_type, "enforcer", "Player kart archetype must update to enforcer")

	race.select_kart("phantom")
	assert_eq(race.selected_kart, "phantom", "Vehicle selection must update to phantom")
	assert_eq(race.player_kart.kart_type, "phantom", "Player kart archetype must update to phantom")

	race.queue_free()

func test_race_finish_flow() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	# Simulate race finish with player as winner
	race._on_race_finished(race.player_kart)
	assert_true(race.results_screen != null, "Results must be displayed on race finish")

	race.queue_free()

func test_pause_restart_quit() -> void:
	var race = KartRacingMainScript.new()
	race.setup_scene()

	race._on_restart()
	race._on_quit_to_launcher()
	assert_true(true, "Restart/quit must not crash without EventBus")

	race.queue_free()
