class_name TestUISystems
extends RefCounted

const ThemeGeneratorScript = preload("res://shared/ui/theme_generator.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")
const TouchControlsScript = preload("res://shared/input/touch_controls.gd")
const VirtualJoystickScript = preload("res://shared/input/virtual_joystick.gd")
const ArenaFPSHUDScript = preload("res://games/arena-fps/ui/arena_fps_hud.gd")
const MetroSiegeHUDScript = preload("res://games/subway-survival/ui/metro_siege_hud.gd")
const NitroKickHUDScript = preload("res://games/rocket-car/ui/nitro_kick_hud.gd")
const DriftStormHUDScript = preload("res://games/kart-racing/ui/drift_storm_hud.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_theme_generator()
	test_hud_base()
	test_pause_menu()
	test_results_screen()
	test_touch_controls()
	test_virtual_joystick()
	test_arena_fps_hud()
	test_metro_siege_hud()
	test_nitro_kick_hud()
	test_drift_storm_hud()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://shared/ui/theme_generator.gd",
			["get_theme"]
		],
		[
			"res://shared/ui/hud_base.gd",
			[
				"_ready", "setup_hud_layout", "connect_bus_signals",
				"check_mobile_controls", "set_crosshair_spread",
				"update_health", "update_armor", "update_ammo",
				"update_weapon", "update_score", "update_timer", "show_toast",
				"update_layout_positions"
			]
		],
		[
			"res://shared/ui/pause_menu.gd",
			["_ready", "setup_ui", "show_pause", "hide_pause", "_unhandled_input"]
		],
		[
			"res://shared/ui/results_screen.gd",
			["_ready", "setup_ui", "display_results"]
		],
		[
			"res://shared/input/touch_controls.gd",
			["_ready", "setup_ui", "create_action_button"]
		],
		[
			"res://shared/input/virtual_joystick.gd",
			["_ready", "update_knob", "reset_joystick"]
		],
		[
			"res://games/arena-fps/ui/arena_fps_hud.gd",
			[
				"setup_hud_layout", "update_frags", "update_objective",
				"show_countdown", "setup_onboarding_overlay",
				"dismiss_onboarding", "_unhandled_input",
				"update_layout_positions", "highlight_active_weapon", "_process",
				"add_killfeed_entry", "update_objective_label"
			]
		],
		[
			"res://games/subway-survival/ui/metro_siege_hud.gd",
			[
				"_ready", "setup_hud_layout", "connect_bus_signals", "check_mobile_controls",
				"set_crosshair_spread", "update_health", "update_armor", "update_ammo",
				"update_weapon", "update_wave", "update_threats", "update_scrap",
				"show_intermission", "show_toast", "setup_onboarding_overlay",
				"dismiss_onboarding", "_unhandled_input", "update_layout_positions", "_process"
			]
		],
		[
			"res://games/rocket-car/ui/nitro_kick_hud.gd",
			[
				"_ready", "setup_hud_layout", "connect_bus_signals", "check_mobile_controls",
				"update_score", "update_clock", "update_boost",
				"show_kickoff_countdown", "show_goal_celebration", "show_toast",
				"setup_ball_tracker", "setup_onboarding_overlay",
				"dismiss_onboarding", "_unhandled_input", "_process",
				"set_tracking_targets", "update_ball_tracker"
			]
		],
		[
			"res://games/kart-racing/ui/drift_storm_hud.gd",
			[
				"_ready", "setup_hud_layout", "check_mobile_controls", "update_position",
				"update_lap", "update_speed", "update_drift_charge",
				"update_powerup", "update_lap_times", "show_countdown",
				"show_finish_banner", "show_toast", "setup_onboarding_overlay",
				"dismiss_onboarding", "_unhandled_input",
				"update_layout_positions", "_process", "set_wrong_way"
			]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit UISystems FAIL: " + msg)

func test_theme_generator() -> void:
	var theme = ThemeGeneratorScript.get_theme()
	assert_true(theme != null, "Theme generator must return valid Theme")
	assert_true(theme.has_stylebox("normal", "Button"), "Theme must define normal Button stylebox")

func test_hud_base() -> void:
	var hud = HUDBaseScript.new()
	hud._ready()
	assert_true(hud.health_bar != null, "HUD must have health_bar")
	assert_true(hud.armor_bar != null, "HUD must have armor_bar")

	hud.update_health(80.0, 100.0)
	assert_true(hud.health_bar.value == 80.0, "Health bar value must update to 80")

	hud.update_armor(40.0, 50.0)
	assert_true(hud.armor_bar.value == 40.0, "Armor bar value must update to 40")

	hud.update_ammo(25, 30, 90)
	assert_true(hud.ammo_label.text.contains("25"), "Ammo label must display clip ammo")

	hud.update_weapon("Pulse Rifle", "Standard")
	assert_true(hud.weapon_label.text == "PULSE RIFLE", "Weapon label must update")

	hud.update_score(0, 150)
	assert_true(hud.score_label.text.contains("150"), "Score label must update")

	hud.update_timer(125.0)
	assert_true(hud.timer_label.text.contains(":"), "Timer label must format MM:SS")

	hud.set_crosshair_spread(12.0)
	assert_true(hud.crosshair_spread == 12.0, "Crosshair spread must update")

	hud.show_toast("TEST TOAST", Color.CYAN)
	assert_true(hud.toast_container.get_child_count() > 0, "Toast container must have active child")
	hud.update_layout_positions()
	hud.queue_free()

func test_pause_menu() -> void:
	var pm = PauseMenuScript.new()
	pm._ready()
	assert_true(not pm.visible, "Pause menu must start hidden")

	pm.show_pause()
	assert_true(pm.visible, "Pause menu must become visible on show_pause")

	pm.hide_pause()
	assert_true(not pm.visible, "Pause menu must hide on hide_pause")

	# Test pause unhandled input toggle
	var ev = InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	pm._unhandled_input(ev)
	pm.queue_free()

func test_results_screen() -> void:
	var rs = ResultsScreenScript.new()
	rs._ready()
	assert_true(not rs.visible, "Results screen must start hidden")

	rs.display_results(true, {
		"Score": "1,250",
		"Time": "02:45"
	})
	assert_true(rs.visible, "Results screen must be visible after display")
	assert_true(rs.title_label.text == "VICTORY!", "Title must match")
	rs.queue_free()

func test_touch_controls() -> void:
	var tc = TouchControlsScript.new()
	tc._ready()
	assert_true(tc.move_joystick != null, "Touch controls must instantiate MoveJoystick")
	assert_true(tc.fire_button != null, "Touch controls must instantiate FireButton")
	tc.queue_free()

func test_virtual_joystick() -> void:
	var vj = VirtualJoystickScript.new()
	vj._ready()
	assert_true(vj.current_vector == Vector2.ZERO, "Joystick must start centered")

	vj.update_knob(Vector2(64, 0))
	assert_true(vj.current_vector.x > 0.0, "Joystick must output positive X vector on drag right")

	vj.reset_joystick()
	assert_true(vj.current_vector == Vector2.ZERO, "Joystick must reset to zero")
	vj.queue_free()

func test_arena_fps_hud() -> void:
	var hud = ArenaFPSHUDScript.new()
	hud._ready()
	assert_true(hud.frags_label != null, "ArenaFPSHUD must have frags_label")
	hud.update_frags(5, 20)
	assert_true(hud.frags_label.text.contains("5"), "Frags label must update")
	hud.update_objective(8, 6, 20)
	assert_true(hud.objective_label.text.contains("8"), "Objective label must show player frags")
	hud.show_countdown(3)
	assert_true(hud.countdown_panel.visible, "Countdown panel visible for 3")
	hud.show_countdown(0)
	assert_true(hud.countdown_label.text == "FIGHT!", "Countdown shows FIGHT at 0")
	var key_ev = InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_SPACE
	hud._unhandled_input(key_ev)
	hud.dismiss_onboarding()
	hud.queue_free()

func test_metro_siege_hud() -> void:
	var hud = MetroSiegeHUDScript.new()
	hud._ready()
	assert_true(hud.health_bar != null, "MetroSiegeHUD must have health_bar")
	hud.update_health(75.0, 100.0)
	hud.update_armor(30.0, 50.0)
	hud.update_ammo(20, 30, 80)
	hud.update_weapon("Pulse Rifle")
	hud.update_wave(2, false)
	assert_true(hud.wave_label.text.contains("WAVE 2"), "Wave label must display wave 2")
	hud.update_wave(5, true)
	assert_true(hud.wave_label.text.contains("BOSS"), "Boss wave label must display BOSS")
	hud.update_threats(4)
	assert_true(hud.threats_label.text.contains("4"), "Threats label must display count")
	hud.update_scrap(120)
	assert_true(hud.scrap_label.text.contains("120"), "Scrap label must display count")
	hud.show_intermission(10.0, true)
	assert_true(hud.intermission_panel.visible, "Intermission panel must be visible")
	hud.set_crosshair_spread(10.0)
	hud.show_toast("MUTANT ELIMINATED", Color.RED)
	var key_ev = InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_SPACE
	hud._unhandled_input(key_ev)
	hud.dismiss_onboarding()
	hud.queue_free()

func test_nitro_kick_hud() -> void:
	var hud = NitroKickHUDScript.new()
	hud._ready()
	assert_true(hud.score_label != null, "NitroKickHUD must have score_label")
	hud.update_score(3, 1)
	assert_true(hud.score_label.text.contains("3"), "Score label must update blue score")
	hud.update_clock(120.0)
	assert_true(hud.timer_label.text == "02:00", "Clock must format MM:SS")
	hud.update_boost(80.0, 100.0)
	assert_true(hud.boost_bar.value == 80.0, "Boost bar must update")
	hud.show_kickoff_countdown(3)
	assert_true(hud.kickoff_panel.visible, "Kickoff panel must show countdown")
	hud.show_kickoff_countdown(0)
	hud.show_goal_celebration(0, 95.0)
	assert_true(hud.goal_panel.visible, "Goal panel must show celebration")
	hud.show_toast("SUPER SHOT!", Color.CYAN)
	var cam = Camera3D.new()
	var ball = Node3D.new()
	hud.set_tracking_targets(cam, ball)
	hud.update_ball_tracker()
	hud._process(0.016)
	var key_ev = InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_SPACE
	hud._unhandled_input(key_ev)
	hud.dismiss_onboarding()
	cam.queue_free()
	ball.queue_free()
	hud.queue_free()

func test_drift_storm_hud() -> void:
	var hud = DriftStormHUDScript.new()
	hud._ready()
	assert_true(hud.position_label != null, "DriftStormHUD must have position_label")
	hud.update_position(1, 4)
	assert_true(hud.position_label.text == "1st", "Position label must display 1st")
	hud.update_position(2, 4)
	assert_true(hud.position_label.text == "2nd", "Position label must display 2nd")
	hud.update_lap(2, 3)
	assert_true(hud.lap_label.text.contains("2 / 3"), "Lap label must update")
	hud.update_speed(35.0)
	assert_true(hud.speed_label.text.contains("KM/H"), "Speedometer must display KM/H")
	hud.update_drift_charge(1.5, 2)
	assert_true(hud.drift_bar.value == 1.5, "Drift bar must update")
	hud.update_powerup("Boost")
	assert_true(hud.powerup_label.text.contains("BOOST"), "Powerup label must show BOOST")
	hud.update_powerup("")
	assert_true(hud.powerup_label.text.contains("NO ITEM"), "Powerup label must show NO ITEM")
	hud.update_lap_times(45.2, 42.1)
	hud.show_countdown("2")
	assert_true(hud.countdown_panel.visible, "Countdown panel must show")
	hud.show_countdown("GO!")
	hud.show_finish_banner("1st Place")
	assert_true(hud.finish_panel.visible, "Finish panel must show")
	hud.show_toast("DRIFT BOOST!", Color.GREEN)
	var key_ev = InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_SPACE
	hud._unhandled_input(key_ev)
	hud.dismiss_onboarding()
	hud.queue_free()

