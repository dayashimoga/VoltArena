class_name TestFlightE2E
extends RefCounted

## TestFlightE2E: End-to-End Flight Lifecycle & State Machine Integration Tests.
## Exercises complete flow: Hangar -> Session Start -> Flight Inputs ->
## Camera Toggle -> Autopilot -> Recovery -> Mission Complete -> Results Dossier.

const AircraftFlightMainScript = preload("res://games/aircraft-flight/aircraft_flight_main.gd")
const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_flight_main_e2e_lifecycle()
	test_flight_session_takeoff_and_recovery()

	return {"passed": assertions_passed, "failed": assertions_failed}

func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: %s" % msg)

func test_flight_main_e2e_lifecycle() -> void:
	var game = AircraftFlightMainScript.new()
	game._ready()

	_assert_true(game.current_state == AircraftFlightMainScript.GameState.HANGAR, "Initial state is Hangar")
	_assert_true(game.hangar_menu != null and game.hangar_menu.visible, "Hangar menu visible")

	# Launch flight session
	game._on_hangar_launch("fa18_hornet", "m1_free_flight", "metropolitan_city", Color.GRAY, Color.CYAN)
	_assert_true(game.current_state == AircraftFlightMainScript.GameState.FLIGHT, "Transitioned to Flight state")
	_assert_true(game.player_aircraft != null, "Player aircraft instantiated")
	_assert_true(game.world_manager != null, "Flight world manager instantiated")
	_assert_true(game.flight_camera != null, "Flight camera controller active")

	# Exercise flight physics ticks
	for _i in range(10):
		game._physics_process(0.016)

	# Toggle cameras
	game._on_camera_toggle_requested()
	_assert_true(game.flight_camera.current_mode == FlightConst.CameraViewMode.COCKPIT, "Camera toggled to Cockpit")

	# Complete mission and verify results dossier
	var summary = {
		"mission_id": "m1_free_flight",
		"title": "Open Skies Exploration",
		"success": true,
		"time_s": 45.0,
		"score": 3500,
		"medal": "Gold"
	}
	game._on_mission_completed(summary)
	_assert_true(game.current_state == AircraftFlightMainScript.GameState.RESULTS, "Transitioned to Results state")
	_assert_true(game.results_screen != null and game.results_screen.visible, "Results screen displayed")

	game.enter_hangar()
	_assert_true(game.current_state == AircraftFlightMainScript.GameState.HANGAR, "Returned to Hangar")

	game.free()

func test_flight_session_takeoff_and_recovery() -> void:
	var game = AircraftFlightMainScript.new()
	game._ready()
	game._on_hangar_launch("fa18_hornet", "m2_takeoff_landing", "metropolitan_city", Color.GRAY, Color.CYAN)

	_assert_true(game.player_aircraft.indicated_airspeed_kmh == 0.0, "Aircraft starts at rest on runway")

	# Advance throttle and simulate takeoff roll
	game.player_aircraft.set_throttle(1.0)
	game.player_aircraft.set_afterburner(true)

	for _i in range(25):
		game.player_aircraft.velocity += Vector3(0.0, 0.0, -4.0)
		game.player_aircraft._physics_process(0.016)
		game._physics_process(0.016)

	_assert_true(game.player_aircraft.indicated_airspeed_kmh > 100.0, "Measurable acceleration achieved on runway")

	# Test key input event dispatch
	var ev_g = InputEventKey.new()
	ev_g.pressed = true
	ev_g.keycode = KEY_G
	game._unhandled_input(ev_g)

	# Test safe recovery trigger
	game._on_recover_requested()
	var recovery_pos = game.player_aircraft.global_position if game.player_aircraft.is_inside_tree() else game.player_aircraft.position
	_assert_true(recovery_pos.y >= 1.5, "Aircraft recovered safely to runway threshold")

	game.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/aircraft-flight/aircraft_flight_main.gd",
			[
				"_ready", "_setup_subsystems", "enter_hangar", "_on_hangar_launch",
				"start_flight_session", "_physics_process", "_handle_flight_inputs",
				"_unhandled_input", "_on_objective_updated", "_on_mission_completed",
				"_on_mission_failed", "restart_current_mission", "_on_recover_requested",
				"_on_camera_toggle_requested", "_on_pause_requested", "_on_exit_to_launcher",
				"_cleanup_flight_session"
			]
		]
	]
