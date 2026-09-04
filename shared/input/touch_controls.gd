class_name TouchControls
extends Control

var move_joystick: VirtualJoystick
var fire_button: Button
var jump_button: Button
var boost_button: Button
var reload_button: Button

# Right-screen touch look zone
var look_touch_id: int = -1
var last_look_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_PASS

	setup_ui()

func setup_ui() -> void:
	# Virtual Joystick on bottom-left
	move_joystick = VirtualJoystick.new()
	move_joystick.name = "MoveJoystick"
	move_joystick.position = Vector2(40, size.y - 200)
	move_joystick.joystick_vector_updated.connect(_on_move_joystick_updated)
	add_child(move_joystick)

	# Action buttons on bottom-right
	var btn_container = VBoxContainer.new()
	btn_container.anchor_left = 1.0
	btn_container.anchor_top = 1.0
	btn_container.anchor_right = 1.0
	btn_container.anchor_bottom = 1.0
	btn_container.offset_left = -220
	btn_container.offset_top = -220
	btn_container.offset_right = -20
	btn_container.offset_bottom = -20
	add_child(btn_container)

	var row1 = HBoxContainer.new()
	btn_container.add_child(row1)
	var row2 = HBoxContainer.new()
	btn_container.add_child(row2)

	fire_button = create_action_button("FIRE", "fire", Color(1.0, 0.2, 0.3, 0.7))
	jump_button = create_action_button("JUMP", "jump", Color(0.2, 0.8, 1.0, 0.7))
	boost_button = create_action_button("BOOST", "boost", Color(1.0, 0.7, 0.1, 0.7))
	reload_button = create_action_button("RELOAD", "reload", Color(0.5, 0.5, 0.5, 0.7))

	row1.add_child(fire_button)
	row1.add_child(jump_button)
	row2.add_child(boost_button)
	row2.add_child(reload_button)

func create_action_button(text: String, action_name: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(90, 80)
	btn.modulate = color
	btn.button_down.connect(func(): Input.action_press(action_name))
	btn.button_up.connect(func(): Input.action_release(action_name))
	return btn

func _on_move_joystick_updated(vec: Vector2) -> void:
	# Map normalized 2D vector to virtual move vector
	var im = GameConstants.get_autoload(self, "InputManager")
	if im:
		im.virtual_move_vector = vec

func _gui_input(event: InputEvent) -> void:
	# Right half screen acts as swipe-to-look touch zone
	if event is InputEventScreenTouch:
		if event.position.x > size.x * 0.4:
			if event.pressed and look_touch_id == -1:
				look_touch_id = event.index
				last_look_pos = event.position
			elif not event.pressed and event.index == look_touch_id:
				look_touch_id = -1
	elif event is InputEventScreenDrag and event.index == look_touch_id:
		var delta = event.position - last_look_pos
		last_look_pos = event.position
		var im = GameConstants.get_autoload(self, "InputManager")
		if im:
			im.virtual_look_vector = delta * 2.0
