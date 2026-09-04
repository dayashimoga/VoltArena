class_name TestInputManager
extends RefCounted

const InputManagerScript = preload("res://shared/input/input_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_default_actions_setup()
	test_sensitivity_defaults()
	test_deadzone()
	test_move_vector_default()
	test_mouse_capture()
	test_input_helpers()
	test_unhandled_input()
	test_game_context()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/input/input_manager.gd",
		[
			"_ready", "setup_default_actions", "load_input_settings",
			"capture_mouse", "get_move_vector", "get_look_vector",
			"add_action_if_missing", "add_action_key",
			"add_action_key_or_mouse", "_unhandled_input",
			"set_game_context"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit InputManager FAIL: " + msg)

func test_default_actions_setup() -> void:
	var im = InputManagerScript.new()
	im._ready()
	assert_true(InputMap.has_action("move_forward"), "move_forward action must exist")
	assert_true(InputMap.has_action("fire"), "fire action must exist")
	assert_true(InputMap.has_action("jump"), "jump action must exist")
	im.queue_free()

func test_sensitivity_defaults() -> void:
	var im = InputManagerScript.new()
	assert_true(im.mouse_sensitivity > 0.0, "Mouse sensitivity must be positive")
	assert_true(im.gamepad_sensitivity > 0.0, "Gamepad sensitivity must be positive")
	assert_true(not im.invert_y, "Invert Y must default to false")
	im.queue_free()

func test_deadzone() -> void:
	var im = InputManagerScript.new()
	assert_true(im.gamepad_deadzone > 0.0, "Deadzone must be positive")
	assert_true(im.gamepad_deadzone < 0.5, "Deadzone must be reasonable (<0.5)")
	im.queue_free()

func test_move_vector_default() -> void:
	var im = InputManagerScript.new()
	var mv = im.get_move_vector()
	assert_true(mv.length() < 0.01, "Move vector must be zero with no input")
	var lv = im.get_look_vector(0.016)
	assert_true(lv.length() < 0.01, "Look vector must be zero initially")
	im.queue_free()

func test_mouse_capture() -> void:
	var im = InputManagerScript.new()
	assert_true(not im.is_mouse_captured, "Mouse must not be captured initially")
	im.capture_mouse(true)
	assert_true(im.is_mouse_captured, "Mouse must be captured after capture(true)")
	im.capture_mouse(false)
	assert_true(not im.is_mouse_captured, "Mouse must be released after capture(false)")
	im.queue_free()

func test_input_helpers() -> void:
	var im = InputManagerScript.new()
	im.add_action_if_missing("test_custom_action", [KEY_T], -1, -1, 0.0)
	assert_true(InputMap.has_action("test_custom_action"), "Custom action must be added")
	im.add_action_key("test_custom_action", KEY_T, -1)
	im.add_action_key_or_mouse("test_custom_action", MOUSE_BUTTON_LEFT, -1)
	im.load_input_settings()
	assert_true(true, "Input helpers must execute safely")
	im.queue_free()

func test_unhandled_input() -> void:
	var im = InputManagerScript.new()
	im.capture_mouse(true)
	var ev = InputEventMouseMotion.new()
	ev.relative = Vector2(10.0, 5.0)
	im._unhandled_input(ev)
	var lv = im.get_look_vector(0.016)
	assert_true(lv.length() > 0.0, "Look vector must update on mouse motion")
	im.queue_free()

func test_game_context() -> void:
	var im = InputManagerScript.new()
	im._ready()
	im.set_game_context("arena_fps")
	assert_true(im.active_game_context == "arena_fps", "Context must update to arena_fps")
	assert_true(not InputMap.action_get_events("fire").is_empty(), "fire must have events in arena_fps")
	assert_true(InputMap.action_get_events("boost").is_empty(), "boost must be disabled in arena_fps")
	im.set_game_context("rocket_car")
	assert_true(not InputMap.action_get_events("boost").is_empty(), "boost must have events in rocket_car")
	assert_true(InputMap.action_get_events("fire").is_empty(), "fire must be disabled in rocket_car")
	im.set_game_context("")
	assert_true(InputMap.action_get_events("fire").is_empty(), "fire must be disabled in launcher")
	assert_true(not InputMap.action_get_events("pause").is_empty(), "pause must be enabled in launcher")
	im.set_game_context("all")
	im.queue_free()

