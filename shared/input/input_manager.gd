extends Node

var mouse_sensitivity: float = 0.0025
var gamepad_sensitivity: float = 2.5
var invert_y: bool = false
var gamepad_deadzone: float = 0.15

# Accumulated look delta from mouse or touch
var look_delta: Vector2 = Vector2.ZERO
var virtual_move_vector: Vector2 = Vector2.ZERO
var virtual_look_vector: Vector2 = Vector2.ZERO

var is_mouse_captured: bool = false
var active_game_context: String = "all"
var _action_events_cache: Dictionary = {}

func _ready() -> void:
	setup_default_actions()
	load_input_settings()
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_loaded.connect(func(g_id): set_game_context(g_id))
		bus.return_to_launcher_requested.connect(func(): set_game_context(""))

func setup_default_actions() -> void:
	add_action_if_missing("move_forward", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	add_action_if_missing("move_back", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	add_action_if_missing("move_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	add_action_if_missing("move_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)

	add_action_key_or_mouse("fire", MOUSE_BUTTON_LEFT, JOY_BUTTON_RIGHT_SHOULDER)
	add_action_key_or_mouse("alt_fire", MOUSE_BUTTON_RIGHT, JOY_BUTTON_LEFT_SHOULDER)
	add_action_key("jump", KEY_SPACE, JOY_BUTTON_A)
	add_action_key("sprint", KEY_SHIFT, JOY_BUTTON_LEFT_STICK)
	add_action_key("crouch", KEY_C, JOY_BUTTON_B)
	add_action_key("reload", KEY_R, JOY_BUTTON_X)
	add_action_key("boost", KEY_SPACE, JOY_BUTTON_B)
	add_action_key("drift", KEY_SHIFT, JOY_BUTTON_X)
	add_action_key("pause", KEY_ESCAPE, JOY_BUTTON_START)
	_cache_all_action_events()

func _cache_all_action_events() -> void:
	var standard_actions = [
		"move_forward", "move_back", "move_left", "move_right",
		"fire", "alt_fire", "jump", "sprint", "crouch", "reload",
		"boost", "drift", "pause"
	]
	for a in standard_actions:
		if InputMap.has_action(a):
			_action_events_cache[a] = InputMap.action_get_events(a).duplicate()

func set_game_context(game_id: String) -> void:
	active_game_context = game_id
	if _action_events_cache.is_empty():
		_cache_all_action_events()

	var allowed: Array = []
	match game_id:
		"":
			allowed = ["pause"]
		"arena_fps", "subway_survival":
			allowed = ["move_forward", "move_back", "move_left", "move_right", "fire", "alt_fire", "reload", "jump", "sprint", "crouch", "pause"]
		"rocket_car", "kart_racing":
			allowed = ["move_forward", "move_back", "move_left", "move_right", "boost", "drift", "jump", "pause"]
		_:
			allowed = _action_events_cache.keys()

	for action in _action_events_cache.keys():
		if action in allowed:
			if InputMap.action_get_events(action).is_empty():
				for ev in _action_events_cache[action]:
					InputMap.action_add_event(action, ev)
		else:
			InputMap.action_erase_events(action)


func add_action_if_missing(action_name: String, keys: Array, joy_btn: int, joy_axis: int, axis_dir: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for key in keys:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action_name, ev)

		if joy_btn >= 0:
			var joy_ev = InputEventJoypadButton.new()
			joy_ev.button_index = joy_btn
			InputMap.action_add_event(action_name, joy_ev)

		if joy_axis >= 0:
			var axis_ev = InputEventJoypadMotion.new()
			axis_ev.axis = joy_axis
			axis_ev.axis_value = axis_dir
			InputMap.action_add_event(action_name, axis_ev)

func add_action_key(action_name: String, key_code: int, joy_btn: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev = InputEventKey.new()
		ev.physical_keycode = key_code
		InputMap.action_add_event(action_name, ev)
		if joy_btn >= 0:
			var joy_ev = InputEventJoypadButton.new()
			joy_ev.button_index = joy_btn
			InputMap.action_add_event(action_name, joy_ev)

func add_action_key_or_mouse(action_name: String, mouse_button: int, joy_btn: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev = InputEventMouseButton.new()
		ev.button_index = mouse_button
		InputMap.action_add_event(action_name, ev)
		if joy_btn >= 0:
			var joy_ev = InputEventJoypadButton.new()
			joy_ev.button_index = joy_btn
			InputMap.action_add_event(action_name, joy_ev)

func load_input_settings() -> void:
	# Sensitivities can be adjusted or fetched from settings
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_mouse_captured:
		look_delta.x += event.relative.x * mouse_sensitivity
		look_delta.y += event.relative.y * mouse_sensitivity * (-1.0 if invert_y else 1.0)

func capture_mouse(capture: bool) -> void:
	is_mouse_captured = capture
	if capture:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_move_vector() -> Vector2:
	# Keyboard / Gamepad axis
	var k_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if virtual_move_vector.length_squared() > 0.01:
		return virtual_move_vector
	return k_vec

func get_look_vector(delta: float) -> Vector2:
	# Combine mouse delta + gamepad right stick + virtual look touch
	var out = look_delta
	look_delta = Vector2.ZERO # Consume mouse delta

	# Gamepad right stick
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(joy_x) > gamepad_deadzone:
		out.x += (joy_x - sign(joy_x) * gamepad_deadzone) * gamepad_sensitivity * delta
	if abs(joy_y) > gamepad_deadzone:
		var dir = -1.0 if invert_y else 1.0
		out.y += (joy_y - sign(joy_y) * gamepad_deadzone) * gamepad_sensitivity * delta * dir

	# Virtual look touch on mobile
	if virtual_look_vector.length_squared() > 0.001:
		out += virtual_look_vector * delta
		virtual_look_vector = Vector2.ZERO

	return out
