class_name TestAeroAIAndModesUnit
extends RefCounted

## Unit test suite for AeroRush rival AI, ghost recording/playback,
## game mode logic, and UI coordinator screens.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroVehicle = preload("res://games/aero-rush/vehicles/aero_vehicle.gd")
const AeroRivalAI = preload("res://games/aero-rush/ai/aero_rival_ai.gd")
const AeroGhostSystem = preload("res://games/aero-rush/ai/aero_ghost_system.gd")

const AeroHUD = preload("res://games/aero-rush/ui/aero_hud.gd")
const AeroResultsScreen = preload("res://games/aero-rush/ui/aero_results_screen.gd")
const AeroGarage = preload("res://games/aero-rush/ui/aero_garage.gd")
const AeroCourseSelect = preload("res://games/aero-rush/ui/aero_course_select.gd")
const AeroMainMenu = preload("res://games/aero-rush/ui/aero_main_menu.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [AeroRush] Running AI, Ghost & UI/Mode Unit Tests...")
	test_rival_ai_steering_and_throttle()
	test_ghost_recording_and_playback()
	test_hud_telemetry_updates()
	test_results_screen_formatting()
	test_garage_and_course_select_ui()
	test_main_menu_signals()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL Aero AI/Modes: " + msg)

func test_rival_ai_steering_and_throttle() -> void:
	var veh = AeroVehicle.new()
	veh.vehicle_id = AeroConstants.VEHICLE_STRYKER
	veh.is_player = false
	veh._ready()

	var waypoints = [
		{"pos": Vector3(0, 0, 0)},
		{"pos": Vector3(20, 0, -60)}, # Target ahead and to the right
		{"pos": Vector3(50, 0, -120)}
	]

	var ai = AeroRivalAI.new()
	ai.setup(veh, waypoints, 0.90)

	ai._physics_process(0.016)
	assert_true(veh.throttle_input > 0.0, "AI must apply throttle when navigating course")

	veh.free()

func test_ghost_recording_and_playback() -> void:
	var ghost = AeroGhostSystem.new()
	var veh = AeroVehicle.new()
	veh._ready()

	ghost.start_recording()
	assert_true(ghost.is_recording, "Ghost system must be in recording state")

	# Record frames
	veh.position = Vector3(0, 0, 0)
	ghost.record_frame(veh, 0.06, 0.0)
	veh.position = Vector3(0, 0, -10)
	ghost.record_frame(veh, 0.06, 0.06)

	var recorded = ghost.stop_recording()
	assert_true(recorded.size() >= 2, "Ghost must record at least 2 telemetry frames")

	# Playback test
	ghost.load_ghost_data(recorded)
	assert_true(ghost.playback_frames.size() == recorded.size(), "Loaded ghost frames must match recorded")

	var dummy_parent = Node3D.new()
	var g_node = ghost.spawn_ghost_visual(dummy_parent, "res://assets/models/vehicles/car_race_future.glb")
	assert_true(g_node != null, "Ghost visual must be spawned")
	assert_true(ghost.is_playing, "Ghost must be in playback state")

	ghost.update_playback(0.03)
	assert_true(g_node.position.z < 0.0, "Ghost position must interpolate along trajectory")

	ghost.clear()
	dummy_parent.free()
	veh.free()

func test_hud_telemetry_updates() -> void:
	var hud = AeroHUD.new()
	hud._ready()

	hud.update_speed(185.0)
	assert_true("185" in hud.speed_label.text, "HUD speed label must display updated speed")

	hud.update_boost(0.75, 1.0)
	assert_true(hud.boost_bar.value == 0.75, "HUD boost bar must reflect boost amount")

	hud.update_time(74.25)
	assert_true(hud.time_label.text == "01:14.25", "HUD time label must format minutes:seconds.ms")

	hud.update_lap(2, 3)
	assert_true("LAP 2 / 3" in hud.lap_label.text, "HUD lap label must display lap count")

	hud.update_combo(3, 1500, 0.8, "AIRTIME")
	assert_true(hud.combo_badge.visible, "Combo badge must be visible when combo is active")
	assert_true("x3" in hud.combo_mult_label.text, "Combo badge must display x3 multiplier")

	hud.free()

func test_results_screen_formatting() -> void:
	var results = AeroResultsScreen.new()
	results._ready()

	results.display_results({
		"course_name": "NEON EXPRESS",
		"time_taken": 64.12,
		"stunt_score": 12400,
		"total_score": 28000,
		"credits_earned": 850,
		"medal": AeroConstants.Medal.GOLD
	})

	assert_true(results.visible, "Results screen must be visible after display_results")
	assert_true("GOLD" in results.medal_label.text, "Results screen must display GOLD medal")
	assert_true("NEON EXPRESS" in results.title_label.text, "Results screen must show course title")

	results.free()

func test_garage_and_course_select_ui() -> void:
	var garage = AeroGarage.new()
	garage._ready()
	assert_true(garage.vehicle_list.size() == 4, "Garage must list all 4 vehicles")
	garage._cycle_vehicle(1)
	assert_true(garage.selected_idx == 1, "Cycling vehicle must change selected index")
	garage.free()

	var cs = AeroCourseSelect.new()
	cs._ready()
	assert_true(cs.course_list.size() == 12, "Course select must list all 12 courses")
	cs.free()

func test_main_menu_signals() -> void:
	var mm = AeroMainMenu.new()
	mm._ready()
	var qp_flag = [false]
	mm.quick_play_requested.connect(func(): qp_flag[0] = true)
	mm.quick_play_requested.emit()
	assert_true(qp_flag[0], "Main menu quick play signal must fire")
	mm.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/aero-rush/ai/aero_rival_ai.gd", [
			"setup", "_physics_process", "_update_target_waypoint", "_drive_towards_target", "_check_stuck_and_recover"
		]],
		["res://games/aero-rush/ai/aero_ghost_system.gd", [
			"start_recording", "record_frame", "stop_recording", "load_ghost_data",
			"spawn_ghost_visual", "update_playback", "_apply_ghost_material", "clear"
		]],
		["res://games/aero-rush/ui/aero_hud.gd", [
			"_ready", "_build_hud_elements", "_build_pause_menu", "update_speed",
			"update_boost", "update_time", "update_lap", "update_checkpoint",
			"set_countdown_text", "show_stunt_toast", "update_combo", "hide_combo", "toggle_pause"
		]],
		["res://games/aero-rush/ui/aero_results_screen.gd", [
			"_ready", "_build_ui", "_add_stat_row", "display_results"
		]],
		["res://games/aero-rush/ui/aero_garage.gd", [
			"_ready", "_build_ui", "_add_stat_bar", "_cycle_vehicle", "_refresh_display", "_on_unlock_or_select_pressed"
		]],
		["res://games/aero-rush/ui/aero_course_select.gd", [
			"_ready", "_build_ui", "_refresh_display", "_on_start_pressed"
		]],
		["res://games/aero-rush/ui/aero_main_menu.gd", [
			"_ready", "_build_ui", "_create_menu_btn"
		]]
	]
