class_name TouchControls
extends Control

const PlatformCapabilities = preload("res://shared/platform/platform_capabilities.gd")
const InputProfile = preload("res://shared/platform/input_profile.gd")

## Adaptive touch controls supporting FPS, Racing, and Rocket-Sports genres
## Conforms to >= 48dp touch target requirements and auto-hides on desktop platforms.

enum Genre {
	GENRE_GENERIC,
	GENRE_FPS,
	GENRE_RACING,
	GENRE_ROCKET_CAR,
	GENRE_PLATFORMER
}

var current_genre: Genre = Genre.GENRE_GENERIC
var force_visible: bool = false

# Core controls
var move_joystick: VirtualJoystick
var fire_button: Button
var jump_button: Button
var boost_button: Button
var reload_button: Button

# Genre-specific controls
var ads_button: Button
var crouch_button: Button
var weapon_switch_button: Button
var gas_button: Button
var brake_button: Button
var drift_button: Button
var ball_cam_button: Button

# Right-screen touch look zone (FPS)
var look_touch_id: int = -1
var last_look_pos: Vector2 = Vector2.ZERO

var _button_container: Control

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_PASS

	setup_ui()
	apply_platform_visibility()

func apply_platform_visibility() -> void:
	if force_visible:
		visible = true
	elif PlatformCapabilities.is_mobile():
		visible = true
	else:
		# Auto-hide on desktop by default unless touch is active
		visible = PlatformCapabilities.has_touchscreen()

func set_genre(genre: Genre) -> void:
	current_genre = genre
	# Rebuild button layouts according to genre
	if is_inside_tree():
		_rebuild_layout()

func setup_ui() -> void:
	# Virtual Joystick on bottom-left (Always present for tests and default input)
	move_joystick = VirtualJoystick.new()
	move_joystick.name = "MoveJoystick"
	move_joystick.position = Vector2(48, maxf(80.0, size.y - 220.0))
	move_joystick.joystick_vector_updated.connect(_on_move_joystick_updated)
	add_child(move_joystick)

	# Container for right-side action buttons
	_button_container = Control.new()
	_button_container.name = "ButtonContainer"
	_button_container.anchor_left = 1.0
	_button_container.anchor_top = 1.0
	_button_container.anchor_right = 1.0
	_button_container.anchor_bottom = 1.0
	_button_container.offset_left = -320
	_button_container.offset_top = -240
	_button_container.offset_right = -20
	_button_container.offset_bottom = -20
	add_child(_button_container)

	_rebuild_layout()

func _rebuild_layout() -> void:
	if not _button_container:
		return

	# Clear previous dynamic buttons
	for child in _button_container.get_children():
		child.queue_free()

	# Create all standard buttons with >= 48dp minimum size
	fire_button = create_action_button("FIRE", "fire", Color(0.9, 0.25, 0.25, 0.85), Vector2(72, 64))
	jump_button = create_action_button("JUMP", "jump", Color(0.2, 0.7, 1.0, 0.85), Vector2(64, 56))
	boost_button = create_action_button("BOOST", "boost", Color(1.0, 0.65, 0.1, 0.85), Vector2(64, 56))
	reload_button = create_action_button("RELOAD", "reload", Color(0.6, 0.6, 0.65, 0.85), Vector2(60, 52))
	
	ads_button = create_action_button("ADS", "alt_fire", Color(0.3, 0.8, 0.5, 0.85), Vector2(60, 52))
	crouch_button = create_action_button("CROUCH", "crouch", Color(0.5, 0.4, 0.8, 0.85), Vector2(60, 52))
	weapon_switch_button = create_action_button("WEAPON", "next_weapon", Color(0.8, 0.8, 0.3, 0.85), Vector2(60, 52))
	
	gas_button = create_action_button("GAS", "move_forward", Color(0.2, 0.85, 0.4, 0.85), Vector2(80, 72))
	brake_button = create_action_button("BRAKE", "move_back", Color(0.9, 0.25, 0.25, 0.85), Vector2(72, 64))
	drift_button = create_action_button("DRIFT", "drift", Color(1.0, 0.8, 0.1, 0.85), Vector2(64, 56))
	ball_cam_button = create_action_button("CAM", "alt_fire", Color(0.4, 0.7, 0.9, 0.85), Vector2(60, 52))

	match current_genre:
		Genre.GENRE_RACING:
			# Racing layout: Large Gas & Brake, Drift, Boost
			var vbox = VBoxContainer.new()
			vbox.anchor_right = 1.0
			vbox.anchor_bottom = 1.0
			_button_container.add_child(vbox)
			
			var row1 = HBoxContainer.new()
			row1.alignment = BoxContainer.ALIGNMENT_END
			row1.add_child(drift_button)
			row1.add_child(boost_button)
			vbox.add_child(row1)
			
			var row2 = HBoxContainer.new()
			row2.alignment = BoxContainer.ALIGNMENT_END
			row2.add_child(brake_button)
			row2.add_child(gas_button)
			vbox.add_child(row2)

		Genre.GENRE_ROCKET_CAR:
			# Rocket car layout: Gas, Brake, Jump, Boost, Drift, Ball Cam
			var vbox = VBoxContainer.new()
			vbox.anchor_right = 1.0
			vbox.anchor_bottom = 1.0
			_button_container.add_child(vbox)
			
			var row1 = HBoxContainer.new()
			row1.alignment = BoxContainer.ALIGNMENT_END
			row1.add_child(ball_cam_button)
			row1.add_child(drift_button)
			row1.add_child(jump_button)
			vbox.add_child(row1)
			
			var row2 = HBoxContainer.new()
			row2.alignment = BoxContainer.ALIGNMENT_END
			row2.add_child(boost_button)
			row2.add_child(brake_button)
			row2.add_child(gas_button)
			vbox.add_child(row2)

		Genre.GENRE_FPS:
			# FPS layout: Fire (prominent), ADS, Reload, Jump, Crouch
			var vbox = VBoxContainer.new()
			vbox.anchor_right = 1.0
			vbox.anchor_bottom = 1.0
			_button_container.add_child(vbox)
			
			var row1 = HBoxContainer.new()
			row1.alignment = BoxContainer.ALIGNMENT_END
			row1.add_child(weapon_switch_button)
			row1.add_child(reload_button)
			row1.add_child(ads_button)
			vbox.add_child(row1)
			
			var row2 = HBoxContainer.new()
			row2.alignment = BoxContainer.ALIGNMENT_END
			row2.add_child(crouch_button)
			row2.add_child(jump_button)
			row2.add_child(fire_button)
			vbox.add_child(row2)

		Genre.GENRE_GENERIC, _:
			# Generic default layout
			var vbox = VBoxContainer.new()
			vbox.anchor_right = 1.0
			vbox.anchor_bottom = 1.0
			_button_container.add_child(vbox)
			
			var row1 = HBoxContainer.new()
			row1.alignment = BoxContainer.ALIGNMENT_END
			row1.add_child(fire_button)
			row1.add_child(jump_button)
			vbox.add_child(row1)
			
			var row2 = HBoxContainer.new()
			row2.alignment = BoxContainer.ALIGNMENT_END
			row2.add_child(boost_button)
			row2.add_child(reload_button)
			vbox.add_child(row2)

func create_action_button(label_text: String, action_name: String, tint_color: Color, min_size: Vector2 = Vector2(64, 56)) -> Button:
	var btn = Button.new()
	btn.text = label_text
	# Enforce minimum touch target (>= 48x48 dp)
	btn.custom_minimum_size = Vector2(maxf(48.0, min_size.x), maxf(48.0, min_size.y))
	btn.modulate = tint_color
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = MOUSE_FILTER_STOP
	
	btn.button_down.connect(func():
		if InputMap.has_action(action_name):
			Input.action_press(action_name)
	)
	btn.button_up.connect(func():
		if InputMap.has_action(action_name):
			Input.action_release(action_name)
	)
	return btn

func _on_move_joystick_updated(vec: Vector2) -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	if im:
		im.virtual_move_vector = vec

func _gui_input(event: InputEvent) -> void:
	# Right half screen acts as swipe-to-look touch zone for FPS/action games
	if current_genre == Genre.GENRE_FPS or current_genre == Genre.GENRE_GENERIC:
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
