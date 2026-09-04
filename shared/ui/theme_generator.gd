class_name ThemeGenerator
extends RefCounted

static var _cached_theme: Theme = null

static func get_theme() -> Theme:
	if _cached_theme:
		return _cached_theme

	var t = Theme.new()

	# Button Normal Style
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.1, 0.12, 0.18, 0.85)
	btn_normal.set_border_width_all(1)
	btn_normal.border_color = Color(0.0, 0.8, 1.0, 0.5)
	btn_normal.set_corner_radius_all(6)
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10

	# Button Hover Style
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.14, 0.18, 0.28, 0.95)
	btn_hover.set_border_width_all(2)
	btn_hover.border_color = Color(0.0, 1.0, 1.0, 0.9)
	btn_hover.set_corner_radius_all(6)
	btn_hover.content_margin_left = 16
	btn_hover.content_margin_right = 16
	btn_hover.content_margin_top = 10
	btn_hover.content_margin_bottom = 10

	# Button Pressed Style
	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.0, 0.6, 0.8, 0.9)
	btn_pressed.set_border_width_all(2)
	btn_pressed.border_color = Color(1.0, 1.0, 1.0, 1.0)
	btn_pressed.set_corner_radius_all(6)
	btn_pressed.content_margin_left = 16
	btn_pressed.content_margin_right = 16
	btn_pressed.content_margin_top = 10
	btn_pressed.content_margin_bottom = 10

	# Panel / Window Style (Glassmorphism dark background)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.12, 0.92)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.2, 0.3, 0.45, 0.6)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("panel", "PanelContainer", panel_style)
	t.set_stylebox("panel", "Panel", panel_style)

	t.set_color("font_color", "Button", Color(0.95, 0.98, 1.0))
	t.set_color("font_hover_color", "Button", Color(0.0, 1.0, 1.0))
	t.set_color("font_color", "Label", Color(0.92, 0.95, 1.0))

	_cached_theme = t
	return t
