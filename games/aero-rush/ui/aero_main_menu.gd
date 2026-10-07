class_name AeroMainMenu
extends Control

## Main menu navigation for AeroRush: Impossible Circuit.
## Provides Quick Play, Courses Browser, Garage Showroom, and Return to Hub.

signal quick_play_requested()
signal courses_menu_requested()
signal garage_menu_requested()
signal return_to_hub_requested()

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.09, 0.92)
	add_child(bg)

	var center_box = VBoxContainer.new()
	center_box.set_anchors_preset(PRESET_CENTER)
	center_box.position = Vector2(-220, -180)
	center_box.custom_minimum_size = Vector2(440, 360)
	center_box.add_theme_constant_override("separation", 16)
	add_child(center_box)

	var title = Label.new()
	title.text = "AERORUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	center_box.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "IMPOSSIBLE CIRCUIT // HIGH-SPEED ARCADE STUNT"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	center_box.add_child(subtitle)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	center_box.add_child(spacer)

	var qp_btn = _create_menu_btn("QUICK PLAY")
	qp_btn.pressed.connect(func(): quick_play_requested.emit())
	center_box.add_child(qp_btn)

	var courses_btn = _create_menu_btn("COURSES & CAREER")
	courses_btn.pressed.connect(func(): courses_menu_requested.emit())
	center_box.add_child(courses_btn)

	var garage_btn = _create_menu_btn("GARAGE & VEHICLES")
	garage_btn.pressed.connect(func(): garage_menu_requested.emit())
	center_box.add_child(garage_btn)

	var hub_btn = _create_menu_btn("RETURN TO VOLTARENA")
	hub_btn.pressed.connect(func(): return_to_hub_requested.emit())
	center_box.add_child(hub_btn)

func _create_menu_btn(txt: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 44)
	return btn
