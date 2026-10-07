class_name AeroMainMenu
extends Control

## Modern, centered hero menu navigation for AeroRush: Impossible Circuit.
## Delivers streamlined 1-click Quick Play -> 3-2-1-GO flow, visual course preview,
## garage showroom access, and seamless return to VoltArena hub.

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

signal quick_play_requested()
signal courses_menu_requested()
signal garage_menu_requested()
signal return_to_hub_requested()

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# 1. Dark Futuristic Backdrop with Cyan/Magenta Glow Gradient
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.08, 0.96)
	add_child(bg)

	# 2. Perfect CenterContainer ensures flawless framing across all viewport sizes
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center_container)

	# 3. Glassmorphic Hero Panel Card
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 480)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.88)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.08, 0.85, 1.0, 0.6)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", sb)
	center_container.add_child(panel)

	var v_box = VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 14)
	panel.add_child(v_box)

	# Title Banner
	var title = Label.new()
	title.text = "AERORUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.08, 0.88, 1.0))
	v_box.add_child(title)

	var sub = Label.new()
	sub.text = "IMPOSSIBLE CIRCUIT // HIGH-SPEED ARCADE STUNT"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	v_box.add_child(sub)

	# Hero Preview Card: Reference Circuit Info
	var course_card = PanelContainer.new()
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.09, 0.12, 0.20, 0.75)
	card_sb.corner_radius_top_left = 8
	card_sb.corner_radius_top_right = 8
	card_sb.corner_radius_bottom_left = 8
	card_sb.corner_radius_bottom_right = 8
	card_sb.content_margin_left = 16
	card_sb.content_margin_right = 16
	card_sb.content_margin_top = 10
	card_sb.content_margin_bottom = 10
	course_card.add_theme_stylebox_override("panel", card_sb)
	v_box.add_child(course_card)

	var card_v = VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 4)
	course_card.add_child(card_v)

	var c_name = Label.new()
	c_name.text = "REFERENCE CIRCUIT: NEON EXPRESS (APEX HORIZON)"
	c_name.add_theme_font_size_override("font_size", 14)
	c_name.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	card_v.add_child(c_name)

	var c_stats = Label.new()
	c_stats.text = "Features: Banked Highway, Mega Jump, 360° Loop, 68° Wall Ride, Chicanes"
	c_stats.add_theme_font_size_override("font_size", 11)
	c_stats.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	card_v.add_child(c_stats)

	var sep = HSeparator.new()
	sep.modulate = Color(0.08, 0.85, 1.0, 0.3)
	v_box.add_child(sep)

	# 1-Click Quick Play Hero Button
	var qp_btn = _create_hero_btn("QUICK PLAY (3-2-1-GO)", Color(0.08, 0.85, 1.0))
	qp_btn.pressed.connect(func(): quick_play_requested.emit())
	v_box.add_child(qp_btn)

	# Secondary Navigation Buttons
	var courses_btn = _create_menu_btn("COURSES & CAREER")
	courses_btn.pressed.connect(func(): courses_menu_requested.emit())
	v_box.add_child(courses_btn)

	var garage_btn = _create_menu_btn("GARAGE & VEHICLES")
	garage_btn.pressed.connect(func(): garage_menu_requested.emit())
	v_box.add_child(garage_btn)

	var hub_btn = _create_menu_btn("RETURN TO VOLTARENA")
	hub_btn.pressed.connect(func(): return_to_hub_requested.emit())
	v_box.add_child(hub_btn)

func _create_hero_btn(txt: String, accent_col: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_font_size_override("font_size", 16)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.45, 0.75, 0.95)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = accent_col
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h = sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.12, 0.60, 0.95, 1.0)
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

func _create_menu_btn(txt: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 14)
	return btn
