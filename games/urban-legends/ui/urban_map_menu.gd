class_name UrbanMapMenu
extends Control

## Full-screen interactive metropolitan district map and navigation planner for Urban Legends.
## Displays:
## - Contiguous 2000m x 2000m map canvas with road network and 8 color-coded districts
## - Player position arrow & active orientation
## - Stunt ramps, missions, and points of interest
## - District stats inspector (Elevation, Speed Limit, Discovered status)
## - Fast-travel jump requests to discovered district center points

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const ThemeGen = preload("res://shared/ui/theme_generator.gd")

signal fast_travel_requested(destination: Vector3)
signal map_closed()

var save_data: UrbanSaveData = null
var road_network: RefCounted = null
var player_vehicle: Node3D = null

var panel_main: PanelContainer
var map_canvas: MapDrawCanvas
var district_info_panel: PanelContainer
var district_name_lbl: Label
var district_desc_lbl: Label
var district_speed_lbl: Label
var district_elev_lbl: Label
var fast_travel_btn: Button

var selected_district_id: String = UrbanConstants.DISTRICT_DOWNTOWN

class MapDrawCanvas extends Control:
	var menu_ref: UrbanMapMenu = null
	var world_min: Vector2 = Vector2(-1000, -1000)
	var world_max: Vector2 = Vector2(1000, 1000)

	func _init(menu: UrbanMapMenu) -> void:
		menu_ref = menu
		custom_minimum_size = Vector2(500, 500)
		size_flags_horizontal = SIZE_EXPAND_FILL
		size_flags_vertical = SIZE_EXPAND_FILL

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos = _screen_to_world(event.position)
			var d_id = UrbanDistrictDefinitions.get_district_at_position(Vector3(world_pos.x, 0, world_pos.y))
			menu_ref.select_district(d_id)
			queue_redraw()

	func _draw() -> void:
		var c_size = size
		# Background Grid
		draw_rect(Rect2(Vector2.ZERO, c_size), Color(0.04, 0.07, 0.10, 0.95))

		# Draw Districts
		var dist_ids = UrbanDistrictDefinitions.get_district_ids()
		for d_id in dist_ids:
			var meta = UrbanDistrictDefinitions.get_district(d_id)
			var rect: Rect2 = meta.get("bounds", Rect2())
			var tl = _world_to_screen(rect.position)
			var br = _world_to_screen(rect.position + rect.size)
			var screen_rect = Rect2(tl, br - tl)

			var is_sel = (d_id == menu_ref.selected_district_id)
			var col: Color = meta.get("color_accent", Color(0.3, 0.5, 0.7))
			var fill_col = col
			fill_col.a = 0.25 if is_sel else 0.10
			draw_rect(screen_rect, fill_col)
			draw_rect(screen_rect, col if is_sel else Color(col.r, col.g, col.b, 0.4), false, 2.0 if is_sel else 1.0)

		# Draw Roads
		if menu_ref and menu_ref.road_network and "segments" in menu_ref.road_network:
			for seg in menu_ref.road_network.segments:
				var st: Vector3 = seg["start"]
				var en: Vector3 = seg["end"]
				var p1 = _world_to_screen(Vector2(st.x, st.z))
				var p2 = _world_to_screen(Vector2(en.x, en.z))

				var r_col = Color(0.65, 0.7, 0.75, 0.6)
				if seg.get("is_freeway", false):
					r_col = Color(0.1, 0.9, 1.0, 0.85)
				elif seg.get("surface", 0) == 2:
					r_col = Color(0.25, 0.8, 0.35, 0.7)
				draw_line(p1, p2, r_col, 2.0)

		# Draw Player Marker
		if menu_ref and is_instance_valid(menu_ref.player_vehicle):
			var pv_pos = menu_ref.player_vehicle.global_position if menu_ref.player_vehicle.is_inside_tree() else menu_ref.player_vehicle.position
			var p_scr = _world_to_screen(Vector2(pv_pos.x, pv_pos.z))
			var rot = menu_ref.player_vehicle.rotation.y
			var arrow_dir = Vector2(sin(rot), -cos(rot)) * 10.0

			draw_circle(p_scr, 6.0, Color(1.0, 0.3, 0.2))
			draw_line(p_scr, p_scr + arrow_dir, Color(1.0, 1.0, 1.0), 3.0)

	func _world_to_screen(w_pos: Vector2) -> Vector2:
		var norm_x = (w_pos.x - world_min.x) / (world_max.x - world_min.x)
		var norm_y = (w_pos.y - world_min.y) / (world_max.y - world_min.y)
		return Vector2(norm_x * size.x, norm_y * size.y)

	func _screen_to_world(s_pos: Vector2) -> Vector2:
		var norm_x = s_pos.x / maxf(1.0, size.x)
		var norm_y = s_pos.y / maxf(1.0, size.y)
		return Vector2(
			world_min.x + norm_x * (world_max.x - world_min.x),
			world_min.y + norm_y * (world_max.y - world_min.y)
		)

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	theme = ThemeGen.get_theme()
	_setup_ui()
	_update_responsive_layout(size)

	if get_viewport():
		get_viewport().size_changed.connect(func(): _update_responsive_layout(get_viewport().get_visible_rect().size))

func setup(save: UrbanSaveData, roads: RefCounted = null, player: Node3D = null) -> void:
	if not panel_main:
		_setup_ui()
	save_data = save
	road_network = roads
	player_vehicle = player
	select_district(UrbanConstants.DISTRICT_DOWNTOWN)

func _setup_ui() -> void:
	panel_main = PanelContainer.new()
	panel_main.name = "MapPanel"
	add_child(panel_main)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)

	# Header
	var hb = HBoxContainer.new()
	var title = Label.new()
	title.text = "METROPOLITAN TRANSIT & DISTRICT MAP"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.1, 0.95, 1.0))
	hb.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hb.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "CLOSE MAP (M / ESC)"
	close_btn.custom_minimum_size = Vector2(160, 36)
	close_btn.pressed.connect(func(): map_closed.emit())
	hb.add_child(close_btn)
	vb.add_child(hb)

	# Main Area
	var content_hb = HBoxContainer.new()
	content_hb.add_theme_constant_override("separation", 18)
	content_hb.size_flags_vertical = SIZE_EXPAND_FILL

	# Map Canvas
	map_canvas = MapDrawCanvas.new(self)
	content_hb.add_child(map_canvas)

	# District Info Sidebar
	district_info_panel = PanelContainer.new()
	district_info_panel.custom_minimum_size.x = 280
	var d_vb = VBoxContainer.new()
	d_vb.add_theme_constant_override("separation", 10)

	district_name_lbl = Label.new()
	district_name_lbl.text = "DOWNTOWN METRO"
	district_name_lbl.add_theme_font_size_override("font_size", 16)
	district_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	d_vb.add_child(district_name_lbl)

	district_desc_lbl = Label.new()
	district_desc_lbl.text = "High-density commercial core with towering skyscrapers and wide boulevards."
	district_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	district_desc_lbl.add_theme_font_size_override("font_size", 12)
	d_vb.add_child(district_desc_lbl)

	district_speed_lbl = Label.new()
	district_speed_lbl.text = "SPEED LIMIT: 80 KM/H"
	district_speed_lbl.add_theme_font_size_override("font_size", 12)
	d_vb.add_child(district_speed_lbl)

	district_elev_lbl = Label.new()
	district_elev_lbl.text = "ELEVATION: 0m to 15m"
	district_elev_lbl.add_theme_font_size_override("font_size", 12)
	d_vb.add_child(district_elev_lbl)

	var d_spacer = Control.new()
	d_spacer.size_flags_vertical = SIZE_EXPAND_FILL
	d_vb.add_child(d_spacer)

	fast_travel_btn = Button.new()
	fast_travel_btn.text = "FAST TRAVEL HERE"
	fast_travel_btn.custom_minimum_size = Vector2(0, 42)
	fast_travel_btn.pressed.connect(_on_fast_travel_pressed)
	d_vb.add_child(fast_travel_btn)

	district_info_panel.add_child(d_vb)
	content_hb.add_child(district_info_panel)

	vb.add_child(content_hb)
	panel_main.add_child(vb)

func select_district(district_id: String) -> void:
	selected_district_id = district_id
	var meta = UrbanDistrictDefinitions.get_district(district_id)

	district_name_lbl.text = meta.get("name", district_id).to_upper()
	district_desc_lbl.text = meta.get("desc", "")
	district_speed_lbl.text = "SPEED LIMIT: %d KM/H" % int(meta.get("speed_limit_kmh", 80.0))
	var elev: Vector2 = meta.get("elevation_range", Vector2(0, 10))
	district_elev_lbl.text = "ELEVATION: %dm to %dm" % [int(elev.x), int(elev.y)]

	var discovered = save_data.discovered_districts.has(district_id) if save_data else true
	fast_travel_btn.disabled = not discovered
	if not discovered:
		fast_travel_btn.text = "LOCKED (UNDISCOVERED)"
	else:
		fast_travel_btn.text = "FAST TRAVEL HERE"

	if map_canvas:
		map_canvas.queue_redraw()

func _on_fast_travel_pressed() -> void:
	var meta = UrbanDistrictDefinitions.get_district(selected_district_id)
	var spawn: Vector3 = meta.get("spawn_point", Vector3.ZERO)
	fast_travel_requested.emit(spawn)
	map_closed.emit()

func _update_responsive_layout(vp_size: Vector2) -> void:
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	var panel_w = min(vp_size.x - 48, 880.0)
	var panel_h = min(vp_size.y - 48, 600.0)
	panel_main.custom_minimum_size = Vector2(panel_w, panel_h)
	panel_main.position = Vector2((vp_size.x - panel_w) * 0.5, (vp_size.y - panel_h) * 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_M)):
		map_closed.emit()
		get_viewport().set_input_as_handled()
