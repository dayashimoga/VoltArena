class_name UrbanPauseMenu
extends Control

## Modern glassmorphism pause menu for Urban Legends.
## Provides options to Resume, Reset Vehicle, Open Garage, View District Map,
## and Return to Launcher.

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

signal resume_requested()
signal reset_vehicle_requested()
signal open_garage_requested()
signal open_map_requested()
signal quit_to_launcher_requested()

var panel_main: PanelContainer
var btn_resume: Button
var btn_reset: Button
var btn_garage: Button
var btn_map: Button
var btn_quit: Button

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	theme = ThemeGen.get_theme()
	_setup_ui()
	_update_responsive_layout(size)

	if get_viewport():
		get_viewport().size_changed.connect(func(): _update_responsive_layout(get_viewport().get_visible_rect().size))

func _setup_ui() -> void:
	# Semi-transparent dark overlay
	var backdrop = ColorRect.new()
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.color = Color(0.02, 0.04, 0.07, 0.75)
	add_child(backdrop)

	panel_main = PanelContainer.new()
	panel_main.name = "PauseCard"
	add_child(panel_main)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var title = Label.new()
	title.text = "URBAN LEGENDS — PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vb.add_child(title)

	var sub_title = Label.new()
	sub_title.text = "Open-World Driving & Stunt Simulator"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_size_override("font_size", 12)
	sub_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vb.add_child(sub_title)

	var div = HSeparator.new()
	vb.add_child(div)

	btn_resume = Button.new()
	btn_resume.text = "RESUME DRIVING (ESC)"
	btn_resume.custom_minimum_size.y = 42
	btn_resume.pressed.connect(func(): resume_requested.emit())
	vb.add_child(btn_resume)

	btn_reset = Button.new()
	btn_reset.text = "RESET / RECOVER VEHICLE (R)"
	btn_reset.custom_minimum_size.y = 38
	btn_reset.pressed.connect(func(): reset_vehicle_requested.emit())
	vb.add_child(btn_reset)

	btn_garage = Button.new()
	btn_garage.text = "PERFORMANCE GARAGE & TUNING"
	btn_garage.custom_minimum_size.y = 38
	btn_garage.pressed.connect(func(): open_garage_requested.emit())
	vb.add_child(btn_garage)

	btn_map = Button.new()
	btn_map.text = "DISTRICT & TRANSIT MAP (M)"
	btn_map.custom_minimum_size.y = 38
	btn_map.pressed.connect(func(): open_map_requested.emit())
	vb.add_child(btn_map)

	var div2 = HSeparator.new()
	vb.add_child(div2)

	btn_quit = Button.new()
	btn_quit.text = "RETURN TO LAUNCHER"
	btn_quit.custom_minimum_size.y = 40
	btn_quit.pressed.connect(func(): quit_to_launcher_requested.emit())
	vb.add_child(btn_quit)

	panel_main.add_child(vb)

func _update_responsive_layout(vp_size: Vector2) -> void:
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	var card_w = min(vp_size.x - 32, 420.0)
	var card_h = 360.0
	panel_main.custom_minimum_size = Vector2(card_w, card_h)
	panel_main.position = Vector2((vp_size.x - card_w) * 0.5, (vp_size.y - card_h) * 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
