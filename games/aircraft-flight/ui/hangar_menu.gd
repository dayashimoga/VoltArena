class_name FlightHangarMenu
extends CanvasLayer

## FlightHangarMenu: Interactive 3D Turntable Aircraft Selector & Mission Briefer.
## Allows pilots to inspect aircraft specifications, customize liveries,
## select world biomes, and launch into 8 flight missions.

const AircraftCatalog = preload("res://games/aircraft-flight/aircraft/aircraft_catalog.gd")
const MissionDefs = preload("res://games/aircraft-flight/missions/mission_definitions.gd")
const MeshBuilder = preload("res://games/aircraft-flight/aircraft/aircraft_mesh_builder.gd")

var selected_aircraft_id: String = "fa18_hornet"
var selected_mission_id: String = "m1_free_flight"
var selected_world_id: String = "metropolitan_city"
var selected_primary_color: Color = Color(0.45, 0.48, 0.52)
var selected_accent_color: Color = Color(0.1, 0.65, 1.0)

var turntable_root: Node3D
var current_preview_model: Node3D

# UI Components
var root_control: Control
var title_label: Label
var category_label: Label
var desc_label: Label
var speed_bar: ProgressBar
var thrust_bar: ProgressBar
var agility_bar: ProgressBar
var g_bar: ProgressBar
var mission_desc_label: Label

signal launch_requested(aircraft_id: String, mission_id: String, world_id: String, primary_col: Color, accent_col: Color)
signal exit_requested()

func _ready() -> void:
	layer = 12
	_build_hangar_ui()
	_update_selected_aircraft(selected_aircraft_id)

func _build_hangar_ui() -> void:
	root_control = Control.new()
	root_control.name = "HangarRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# --- TOP HEADER: TITLE & EXIT ---
	var top_bar = _create_glass_panel(Vector2(680, 52))
	top_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_bar.offset_top = 18
	root_control.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(top_hbox)

	var header_lbl = Label.new()
	header_lbl.text = "APEX FLIGHT: OPEN SKIES — HANGAR & BRIEFING"
	header_lbl.add_theme_font_size_override("font_size", 16)
	header_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	top_hbox.add_child(header_lbl)

	# --- LEFT PANEL: AIRCRAFT SELECTOR & SPECIFICATIONS ---
	var left_panel = _create_glass_panel(Vector2(320, 520))
	left_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	left_panel.offset_left = 30
	root_control.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_vbox)

	var ac_hdr = Label.new()
	ac_hdr.text = "SELECT AIRCRAFT"
	ac_hdr.add_theme_font_size_override("font_size", 13)
	ac_hdr.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	left_vbox.add_child(ac_hdr)

	# Aircraft Buttons Grid
	var all_aircraft = AircraftCatalog.get_all_aircraft()
	for ac in all_aircraft:
		var ac_id = ac.get("id", "")
		var btn = Button.new()
		btn.text = ac.get("name", "")
		btn.custom_minimum_size = Vector2(280, 32)
		btn.pressed.connect(func(): _update_selected_aircraft(ac_id))
		left_vbox.add_child(btn)

	title_label = Label.new()
	title_label.text = "F/A-18C Hornet"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	left_vbox.add_child(title_label)

	category_label = Label.new()
	category_label.text = "Carrier Strike Fighter"
	category_label.add_theme_font_size_override("font_size", 11)
	category_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	left_vbox.add_child(category_label)

	desc_label = Label.new()
	desc_label.text = "Twin-turbofan supersonic carrier-capable multirole fighter."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(280, 50)
	desc_label.add_theme_font_size_override("font_size", 11)
	left_vbox.add_child(desc_label)

	# Spec Progress Bars
	left_vbox.add_child(_create_spec_row("TOP SPEED", 1000.0, func(bar): speed_bar = bar))
	left_vbox.add_child(_create_spec_row("THRUST RATING", 160000.0, func(bar): thrust_bar = bar))
	left_vbox.add_child(_create_spec_row("AGILITY / ROLL", 8.0, func(bar): agility_bar = bar))
	left_vbox.add_child(_create_spec_row("AIRFRAME G-RATING", 12.0, func(bar): g_bar = bar))

	# --- RIGHT PANEL: MISSION & WORLD SELECTOR ---
	var right_panel = _create_glass_panel(Vector2(320, 520))
	right_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_panel.offset_left = -350
	root_control.add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_panel.add_child(right_vbox)

	var m_hdr = Label.new()
	m_hdr.text = "SELECT MISSION"
	m_hdr.add_theme_font_size_override("font_size", 13)
	m_hdr.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	right_vbox.add_child(m_hdr)

	var all_missions = MissionDefs.get_all_missions()
	for m in all_missions:
		var m_id = m.get("id", "")
		var btn = Button.new()
		btn.text = m.get("title", "")
		btn.custom_minimum_size = Vector2(280, 30)
		btn.pressed.connect(func(): _update_selected_mission(m_id))
		right_vbox.add_child(btn)

	mission_desc_label = Label.new()
	mission_desc_label.text = "Explore the vast 8km open world."
	mission_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mission_desc_label.custom_minimum_size = Vector2(280, 60)
	mission_desc_label.add_theme_font_size_override("font_size", 11)
	right_vbox.add_child(mission_desc_label)

	# Bottom Action Buttons
	var btn_fly = Button.new()
	btn_fly.text = "★ FLY MISSION ★"
	btn_fly.custom_minimum_size = Vector2(280, 44)
	btn_fly.add_theme_font_size_override("font_size", 15)
	btn_fly.pressed.connect(func():
		launch_requested.emit(selected_aircraft_id, selected_mission_id, selected_world_id, selected_primary_color, selected_accent_color)
	)
	right_vbox.add_child(btn_fly)

	var btn_exit = Button.new()
	btn_exit.text = "EXIT TO LAUNCHER"
	btn_exit.custom_minimum_size = Vector2(280, 32)
	btn_exit.pressed.connect(func(): exit_requested.emit())
	right_vbox.add_child(btn_exit)

func _update_selected_aircraft(ac_id: String) -> void:
	selected_aircraft_id = ac_id
	var spec = AircraftCatalog.get_aircraft_spec(ac_id)
	title_label.text = spec.get("name", "")
	category_label.text = spec.get("category", "")
	desc_label.text = spec.get("description", "")

	speed_bar.value = spec.get("max_speed_ms", 100.0) * 3.6
	thrust_bar.value = spec.get("max_thrust_n", 50000.0)
	agility_bar.value = spec.get("roll_authority", 3.0)
	g_bar.value = spec.get("max_g_rating", 7.0)

	selected_primary_color = spec.get("primary_color", Color(0.45, 0.48, 0.52))
	selected_accent_color = spec.get("accent_color", Color(0.1, 0.65, 1.0))

func _update_selected_mission(m_id: String) -> void:
	selected_mission_id = m_id
	var m = MissionDefs.get_mission(m_id)
	mission_desc_label.text = m.get("desc", "")
	selected_world_id = m.get("world_id", "metropolitan_city")

func _create_spec_row(title: String, max_val: float, bar_callback: Callable) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
	vbox.add_child(lbl)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(280, 8)
	bar.max_value = max_val
	bar.show_percentage = false
	vbox.add_child(bar)
	bar_callback.call(bar)
	return vbox

func _create_glass_panel(size: Vector2) -> PanelContainer:
	var pc = PanelContainer.new()
	pc.custom_minimum_size = size
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.88)
	style.set_corner_radius_all(12)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.95, 0.3, 0.5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	pc.add_theme_stylebox_override("panel", style)
	return pc
