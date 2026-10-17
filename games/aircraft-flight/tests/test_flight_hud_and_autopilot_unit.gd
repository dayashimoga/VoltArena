class_name TestFlightHUDAndAutopilotUnit
extends RefCounted

## TestFlightHUDAndAutopilotUnit: Unit tests for autopilot PID systems,
## camera controller modes, glass HUD telemetry, results screen, and hangar menu.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")
const FlightAutopilotScript = preload("res://games/aircraft-flight/core/flight_autopilot.gd")
const FlightCameraScript = preload("res://games/aircraft-flight/core/flight_camera_controller.gd")
const FlightHUDScript = preload("res://games/aircraft-flight/ui/flight_hud.gd")
const FlightResultsScript = preload("res://games/aircraft-flight/ui/flight_results_screen.gd")
const FlightHangarScript = preload("res://games/aircraft-flight/ui/hangar_menu.gd")
const FlightPhysicsScript = preload("res://games/aircraft-flight/core/flight_physics.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_autopilot_pid_commands()
	test_camera_controller_modes()
	test_flight_hud_telemetry_and_responsive()
	test_flight_results_screen_dossier()
	test_hangar_menu_interaction()

	return {"passed": assertions_passed, "failed": assertions_failed}

func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: %s" % msg)

func test_autopilot_pid_commands() -> void:
	var ap = FlightAutopilotScript.new()
	var plane = FlightPhysicsScript.new()
	plane.recover_to_safe_flight(Vector3(0.0, 500.0, 0.0), 0.0, 400.0, true)

	ap.enabled = true
	ap.target_altitude_m = 1200.0
	ap.altitude_hold_enabled = true
	ap.target_heading_deg = 90.0
	ap.heading_hold_enabled = true

	var cmds = ap.update_autopilot(plane, 0.016)
	_assert_true(cmds.has("pitch"), "Autopilot computes pitch command")
	_assert_true(cmds.has("roll"), "Autopilot computes roll command")
	_assert_true(cmds.has("throttle"), "Autopilot computes throttle command")

	ap.set_target_waypoint(Vector3(500.0, 1000.0, -1000.0))
	_assert_true(ap.waypoint_nav_enabled == true, "Waypoint navigation mode engaged")

	plane.free()

func test_camera_controller_modes() -> void:
	var cam_ctrl = FlightCameraScript.new()
	var plane = FlightPhysicsScript.new()
	cam_ctrl.target_aircraft = plane
	cam_ctrl._ready()

	_assert_true(cam_ctrl.current_mode == FlightConst.CameraViewMode.CHASE, "Initial mode is Chase")

	cam_ctrl.toggle_camera_mode()
	_assert_true(cam_ctrl.current_mode == FlightConst.CameraViewMode.COCKPIT, "Toggles to Cockpit mode")

	cam_ctrl.toggle_camera_mode()
	_assert_true(cam_ctrl.current_mode == FlightConst.CameraViewMode.AEROBATIC, "Toggles to Aerobatic mode")

	cam_ctrl.toggle_camera_mode()
	_assert_true(cam_ctrl.current_mode == FlightConst.CameraViewMode.FREE, "Toggles to Free camera mode")

	cam_ctrl.toggle_camera_mode()
	_assert_true(cam_ctrl.current_mode == FlightConst.CameraViewMode.CHASE, "Cycles back to Chase mode")

	cam_ctrl.add_look_input(10.0, -5.0)
	cam_ctrl._physics_process(0.016)

	cam_ctrl.free()
	plane.free()

func test_flight_hud_telemetry_and_responsive() -> void:
	var hud = FlightHUDScript.new()
	var plane = FlightPhysicsScript.new()
	plane.indicated_airspeed_kmh = 480.0
	plane.barometric_altitude_m = 1250.0
	plane.vertical_speed_ms = 8.5
	plane.engine_rpm_pct = 90.0
	plane.g_force_current = 2.4

	hud.aircraft = plane
	hud._ready()
	hud._process(0.016)

	_assert_true(hud.airspeed_label.text.contains("480"), "HUD airspeed reflects aircraft airspeed")
	_assert_true(hud.altimeter_label.text.contains("1250"), "HUD altimeter reflects altitude")
	_assert_true(hud.vsi_label.text.contains("8.5"), "HUD VSI reflects vertical speed")
	_assert_true(hud.g_force_label.text.contains("2.4"), "HUD G-meter reflects current load factor")

	hud.set_objective_text("Test Objective Active")
	_assert_true(hud.objective_label.text == "Test Objective Active", "Objective text update verified")

	# Test Responsive Layout at mobile resolution (360x800)
	hud._update_responsive_layout(Vector2(360, 800))
	_assert_true(hud.touch_root.visible == true, "Touch controls visible on mobile portrait resolution")

	hud.free()
	plane.free()

func test_flight_results_screen_dossier() -> void:
	var results = FlightResultsScript.new()
	results._ready()

	var summary = {
		"title": "Commercial Runway Certification",
		"success": true,
		"time_s": 95.4,
		"score": 4800,
		"medal": "Gold"
	}
	results.display_results(summary)

	_assert_true(results.visible == true, "Results screen becomes visible")
	_assert_true(results.medal_label.text.contains("GOLD"), "Gold medal banner displayed")
	_assert_true(results.score_label.text.contains("4800"), "Final score displayed")
	results.free()

func test_hangar_menu_interaction() -> void:
	var hangar = FlightHangarScript.new()
	hangar._ready()

	hangar._update_selected_aircraft("f22_raptor")
	_assert_true(hangar.selected_aircraft_id == "f22_raptor", "F-22 Raptor selected in hangar")
	_assert_true(hangar.title_label.text.contains("F-22"), "Title updated to F-22")

	hangar._update_selected_mission("m4_checkpoint_race")
	_assert_true(hangar.selected_mission_id == "m4_checkpoint_race", "Air race mission selected")

	hangar.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/aircraft-flight/core/flight_autopilot.gd",
			["set_target_waypoint", "update_autopilot"]
		],
		[
			"res://games/aircraft-flight/core/flight_camera_controller.gd",
			[
				"_ready", "toggle_camera_mode", "set_camera_mode", "_physics_process",
				"_update_chase_camera", "_update_cockpit_camera", "_update_aerobatic_camera",
				"_update_free_camera", "add_look_input"
			]
		],
		[
			"res://games/aircraft-flight/ui/flight_hud.gd",
			[
				"_ready", "_on_viewport_size_changed", "_build_hud_layout", "_build_touch_controls",
				"_process", "set_objective_text", "_update_responsive_layout", "_create_glass_panel",
				"_create_label", "_create_action_button"
			]
		],
		[
			"res://games/aircraft-flight/ui/flight_results_screen.gd",
			["_ready", "_build_ui", "display_results"]
		],
		[
			"res://games/aircraft-flight/ui/hangar_menu.gd",
			[
				"_ready", "_build_hangar_ui", "_update_selected_aircraft", "_update_selected_mission",
				"_create_spec_row", "_create_glass_panel"
			]
		]
	]
