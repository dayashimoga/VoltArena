class_name TestUISystems
extends RefCounted

const ThemeGeneratorScript = preload("res://shared/ui/theme_generator.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")
const TouchControlsScript = preload("res://shared/input/touch_controls.gd")
const VirtualJoystickScript = preload("res://shared/input/virtual_joystick.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_theme_generator()
	test_hud_base()
	test_pause_menu()
	test_results_screen()
	test_touch_controls()
	test_virtual_joystick()
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
				"update_weapon", "update_score", "update_timer", "show_toast"
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
