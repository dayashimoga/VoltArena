class_name UrbanGarageMenu
extends Control

## Full-featured vehicle customization, performance upgrades, and archetype
## unlock kiosk for Urban Legends.
## Supports:
## - 5 Vehicle Archetypes (Vortex GT, Thunderbolt V8, Specter R, Ridgeback 4x4, Valiant Coupe)
## - 5 Performance Upgrade tracks (Engine, Tires, Nitro, Suspension, Armor, Levels 1-5)
## - 8 High-Gloss Exterior Paint Colors
## - Career Cash wallet balance and transactional feedback
## - Controller / keyboard / mouse / touch responsive layout

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicleCatalog = preload("res://games/urban-legends/vehicles/urban_vehicle_catalog.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const ProgressionManager = preload("res://games/urban-legends/gameplay/progression_manager.gd")
const ThemeGen = preload("res://shared/ui/theme_generator.gd")

signal vehicle_selected(vehicle_id: String)
signal vehicle_customized(vehicle_id: String)
signal garage_closed()

var save_data: UrbanSaveData = null
var progression_mgr: ProgressionManager = null

var current_vehicle_id: String = UrbanConstants.VEHICLE_VORTEX_GT
var vehicle_ids: Array = []
var selected_index: int = 0

# UI Controls
var panel_main: PanelContainer
var header_title: Label
var cash_label: Label

# Vehicle Showcase
var car_name_label: Label
var car_class_label: Label
var car_desc_label: Label
var unlock_btn: Button

# Stat Bars
var stat_speed_bar: ProgressBar
var stat_accel_bar: ProgressBar
var stat_handling_bar: ProgressBar
var stat_armor_bar: ProgressBar

# Upgrades Container
var upgrades_vbox: VBoxContainer
var upgrade_rows: Dictionary = {}

# Paint Color Swatches
var colors_grid: GridContainer

const PAINT_PALETTE: Array[Color] = [
	Color(0.85, 0.12, 0.15), # Crimson Sunset
	Color(0.12, 0.12, 0.14), # Obsidian Black
	Color(0.08, 0.55, 0.95), # Electric Cyan
	Color(0.95, 0.78, 0.12), # Racing Yellow
	Color(0.92, 0.92, 0.95), # Ghost White
	Color(0.15, 0.28, 0.65), # Metallic Cobalt
	Color(0.15, 0.55, 0.28), # Emerald Green
	Color(0.55, 0.55, 0.60)  # Titanium Gray
]

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	theme = ThemeGen.get_theme()
	vehicle_ids = UrbanVehicleCatalog.get_vehicle_ids()
	_setup_ui()
	_update_responsive_layout(size)

	if get_viewport():
		get_viewport().size_changed.connect(func(): _update_responsive_layout(get_viewport().get_visible_rect().size))

func setup(save: UrbanSaveData, prog: ProgressionManager = null) -> void:
	if not panel_main:
		vehicle_ids = UrbanVehicleCatalog.get_vehicle_ids()
		_setup_ui()
	save_data = save
	if prog:
		progression_mgr = prog
	elif save_data:
		progression_mgr = ProgressionManager.new(save_data)

	if save_data and not save_data.current_vehicle_id.is_empty():
		current_vehicle_id = save_data.current_vehicle_id
		selected_index = vehicle_ids.find(current_vehicle_id)
		if selected_index == -1:
			selected_index = 0

	_refresh_display()

func _setup_ui() -> void:
	panel_main = PanelContainer.new()
	panel_main.name = "GaragePanel"
	add_child(panel_main)

	var root_vb = VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 14)

	# --- Header Bar ---
	var header_hb = HBoxContainer.new()
	header_title = Label.new()
	header_title.text = "URBAN LEGENDS — CUSTOMS & PERFORMANCE"
	header_title.add_theme_font_size_override("font_size", 20)
	header_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	header_hb.add_child(header_title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header_hb.add_child(spacer)

	cash_label = Label.new()
	cash_label.text = "💵 $0"
	cash_label.add_theme_font_size_override("font_size", 18)
	cash_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	header_hb.add_child(cash_label)

	var close_btn = Button.new()
	close_btn.text = "EXIT GARAGE (ESC)"
	close_btn.custom_minimum_size = Vector2(140, 36)
	close_btn.pressed.connect(func(): garage_closed.emit())
	header_hb.add_child(close_btn)
	root_vb.add_child(header_hb)

	# --- Content Horizontal Split ---
	var content_hb = HBoxContainer.new()
	content_hb.add_theme_constant_override("separation", 24)
	content_hb.size_flags_vertical = SIZE_EXPAND_FILL

	# Left Column: Vehicle Archetype Selector & Stats
	var left_vb = VBoxContainer.new()
	left_vb.custom_minimum_size.x = 360
	left_vb.add_theme_constant_override("separation", 10)

	var selector_hb = HBoxContainer.new()
	var prev_btn = Button.new()
	prev_btn.text = "◀ PREV"
	prev_btn.custom_minimum_size = Vector2(80, 40)
	prev_btn.pressed.connect(_on_prev_vehicle)
	selector_hb.add_child(prev_btn)

	var sel_spacer = Control.new()
	sel_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	selector_hb.add_child(sel_spacer)

	car_name_label = Label.new()
	car_name_label.text = "VORTEX GT"
	car_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	car_name_label.add_theme_font_size_override("font_size", 18)
	car_name_label.add_theme_color_override("font_color", Color(0.1, 0.95, 1.0))
	selector_hb.add_child(car_name_label)

	var sel_spacer2 = Control.new()
	sel_spacer2.size_flags_horizontal = SIZE_EXPAND_FILL
	selector_hb.add_child(sel_spacer2)

	var next_btn = Button.new()
	next_btn.text = "NEXT ▶"
	next_btn.custom_minimum_size = Vector2(80, 40)
	next_btn.pressed.connect(_on_next_vehicle)
	selector_hb.add_child(next_btn)
	left_vb.add_child(selector_hb)

	car_class_label = Label.new()
	car_class_label.text = "EXOTIC SUPERCAR"
	car_class_label.add_theme_font_size_override("font_size", 12)
	car_class_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	left_vb.add_child(car_class_label)

	car_desc_label = Label.new()
	car_desc_label.text = "High-revving twin-turbo V8 with active aero and rear-wheel bias."
	car_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	car_desc_label.add_theme_font_size_override("font_size", 12)
	left_vb.add_child(car_desc_label)

	# Stats
	stat_speed_bar = _create_stat_row(left_vb, "TOP SPEED")
	stat_accel_bar = _create_stat_row(left_vb, "ACCELERATION")
	stat_handling_bar = _create_stat_row(left_vb, "DRIFT & HANDLING")
	stat_armor_bar = _create_stat_row(left_vb, "CHASSIS ARMOR")

	# Unlock / Select Button
	unlock_btn = Button.new()
	unlock_btn.text = "SELECT VEHICLE"
	unlock_btn.custom_minimum_size = Vector2(0, 44)
	unlock_btn.pressed.connect(_on_unlock_or_select_pressed)
	left_vb.add_child(unlock_btn)

	# Color Palette Swatches
	var color_header = Label.new()
	color_header.text = "CUSTOM BODY PAINT"
	color_header.add_theme_font_size_override("font_size", 13)
	color_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	left_vb.add_child(color_header)

	colors_grid = GridContainer.new()
	colors_grid.columns = 4
	colors_grid.add_theme_constant_override("h_separation", 8)
	colors_grid.add_theme_constant_override("v_separation", 8)
	for i in range(PAINT_PALETTE.size()):
		var c_val = PAINT_PALETTE[i]
		var cb = Button.new()
		cb.custom_minimum_size = Vector2(40, 32)
		cb.modulate = c_val
		cb.pressed.connect(func(): _on_color_chosen(c_val))
		colors_grid.add_child(cb)
	left_vb.add_child(colors_grid)

	content_hb.add_child(left_vb)

	# Right Column: Performance Upgrades Kiosk
	var right_vb = VBoxContainer.new()
	right_vb.size_flags_horizontal = SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)

	var upg_title = Label.new()
	upg_title.text = "PERFORMANCE TUNING (STAGE 1 - 5)"
	upg_title.add_theme_font_size_override("font_size", 15)
	upg_title.add_theme_color_override("font_color", Color(0.1, 0.95, 1.0))
	right_vb.add_child(upg_title)

	upgrades_vbox = VBoxContainer.new()
	upgrades_vbox.add_theme_constant_override("separation", 10)
	_setup_upgrade_track(upgrades_vbox, "engine", "ENGINE TUNING (HORSEPOWER)")
	_setup_upgrade_track(upgrades_vbox, "tires", "SPORT TIRES (LATERAL GRIP)")
	_setup_upgrade_track(upgrades_vbox, "nitro", "NITROUS SYSTEM (BURST ACCELERATION)")
	_setup_upgrade_track(upgrades_vbox, "suspension", "RACING SUSPENSION (BODY ROLL STIFFNESS)")
	_setup_upgrade_track(upgrades_vbox, "armor", "REINFORCED CHASSIS (IMPACT RESISTANCE)")
	right_vb.add_child(upgrades_vbox)

	content_hb.add_child(right_vb)
	root_vb.add_child(content_hb)

	panel_main.add_child(root_vb)

func _create_stat_row(parent: VBoxContainer, label_text: String) -> ProgressBar:
	var hb = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 130
	lbl.add_theme_font_size_override("font_size", 11)
	hb.add_child(lbl)

	var bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 50.0
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 12
	hb.add_child(bar)
	parent.add_child(hb)
	return bar

func _setup_upgrade_track(parent: VBoxContainer, upg_type: String, display_name: String) -> void:
	var row = PanelContainer.new()
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)

	var title_lbl = Label.new()
	title_lbl.text = display_name
	title_lbl.custom_minimum_size.x = 240
	title_lbl.add_theme_font_size_override("font_size", 12)
	hb.add_child(title_lbl)

	var lvl_lbl = Label.new()
	lvl_lbl.text = "LVL 1 / 5"
	lvl_lbl.custom_minimum_size.x = 70
	lvl_lbl.add_theme_font_size_override("font_size", 12)
	lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	hb.add_child(lvl_lbl)

	var p_bar = ProgressBar.new()
	p_bar.min_value = 1.0
	p_bar.max_value = 5.0
	p_bar.value = 1.0
	p_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	p_bar.custom_minimum_size.y = 10
	hb.add_child(p_bar)

	var buy_btn = Button.new()
	buy_btn.text = "UPGRADE $2,500"
	buy_btn.custom_minimum_size = Vector2(130, 32)
	buy_btn.pressed.connect(func(): _on_buy_upgrade(upg_type))
	hb.add_child(buy_btn)

	row.add_child(hb)
	parent.add_child(row)

	upgrade_rows[upg_type] = {
		"lvl_label": lvl_lbl,
		"bar": p_bar,
		"button": buy_btn
	}

func _refresh_display() -> void:
	if not save_data:
		return

	cash_label.text = "💵 $%d" % save_data.career_cash
	current_vehicle_id = vehicle_ids[selected_index]
	var def = UrbanVehicleCatalog.get_vehicle_def(current_vehicle_id)

	car_name_label.text = def.get("name", current_vehicle_id).to_upper()
	car_class_label.text = def.get("class", "VEHICLE").to_upper()
	car_desc_label.text = def.get("desc", "")

	# Base Stats
	var top_spd = def.get("top_speed_kmh", 180.0)
	stat_speed_bar.value = (top_spd / 300.0) * 100.0

	var accel = def.get("engine_power", 2800.0)
	stat_accel_bar.value = (accel / 4500.0) * 100.0

	var handling = def.get("max_steer_angle_deg", 32.0)
	stat_handling_bar.value = (handling / 45.0) * 100.0

	var mass = def.get("mass_kg", 1350.0)
	stat_armor_bar.value = clampf((mass / 2200.0) * 100.0, 30.0, 100.0)

	# Unlock / Select Status
	var is_unlocked = save_data.is_vehicle_unlocked(current_vehicle_id)
	var is_active = (current_vehicle_id == save_data.current_vehicle_id)

	if is_active:
		unlock_btn.text = "ACTIVE VEHICLE"
		unlock_btn.disabled = true
	elif is_unlocked:
		unlock_btn.text = "SELECT VEHICLE"
		unlock_btn.disabled = false
	else:
		var price = def.get("price", 25000)
		unlock_btn.text = "UNLOCK VEHICLE ($%d)" % price
		unlock_btn.disabled = not (progression_mgr and progression_mgr.can_afford(price))

	# Upgrades
	for upg_type in upgrade_rows:
		var row_dict = upgrade_rows[upg_type]
		var cur_lvl = save_data.get_upgrade_level(current_vehicle_id, upg_type)
		row_dict["lvl_label"].text = "LVL %d / 5" % cur_lvl
		row_dict["bar"].value = cur_lvl

		if cur_lvl >= 5:
			row_dict["button"].text = "MAX LEVEL"
			row_dict["button"].disabled = true
		else:
			var cost = progression_mgr.get_upgrade_cost(cur_lvl) if progression_mgr else 2500
			row_dict["button"].text = "UPGRADE ($%d)" % cost
			row_dict["button"].disabled = not (progression_mgr and progression_mgr.can_afford(cost))

func _on_prev_vehicle() -> void:
	selected_index = (selected_index - 1 + vehicle_ids.size()) % vehicle_ids.size()
	_refresh_display()

func _on_next_vehicle() -> void:
	selected_index = (selected_index + 1) % vehicle_ids.size()
	_refresh_display()

func _on_unlock_or_select_pressed() -> void:
	if not save_data:
		return

	if not save_data.is_vehicle_unlocked(current_vehicle_id):
		if progression_mgr and progression_mgr.unlock_vehicle(current_vehicle_id):
			save_data.current_vehicle_id = current_vehicle_id
			vehicle_selected.emit(current_vehicle_id)
	else:
		save_data.current_vehicle_id = current_vehicle_id
		vehicle_selected.emit(current_vehicle_id)

	_refresh_display()

func _on_buy_upgrade(upg_type: String) -> void:
	if progression_mgr and progression_mgr.buy_upgrade(current_vehicle_id, upg_type):
		vehicle_customized.emit(current_vehicle_id)
		_refresh_display()

func _on_color_chosen(col: Color) -> void:
	if save_data:
		save_data.set_vehicle_color(current_vehicle_id, col)
		vehicle_customized.emit(current_vehicle_id)

func _update_responsive_layout(vp_size: Vector2) -> void:
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	var panel_w = min(vp_size.x - 48, 860.0)
	var panel_h = min(vp_size.y - 48, 580.0)
	panel_main.custom_minimum_size = Vector2(panel_w, panel_h)
	panel_main.position = Vector2((vp_size.x - panel_w) * 0.5, (vp_size.y - panel_h) * 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		garage_closed.emit()
		get_viewport().set_input_as_handled()
