class_name AeroGarage
extends Control

## Vehicle garage and tuning showroom for AeroRush: Impossible Circuit.
## Allows browsing, unlocking, inspecting specs, and paint customization.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroVehicleCatalog = preload("res://games/aero-rush/vehicles/aero_vehicle_catalog.gd")
const AeroSaveAdapter = preload("res://games/aero-rush/persistence/aero_save_adapter.gd")

signal vehicle_selected(vehicle_id: String, paint_col: Color)
signal back_to_menu_requested()

var vehicle_list: Array[Dictionary] = []
var selected_idx: int = 0
var current_paint_color: Color = Color(0.08, 0.58, 0.95)

var name_label: Label
var class_label: Label
var desc_label: Label
var speed_bar: ProgressBar
var accel_bar: ProgressBar
var drift_bar: ProgressBar
var air_bar: ProgressBar
var unlock_btn: Button
var credits_label: Label

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	vehicle_list = AeroVehicleCatalog.get_all_definitions()
	_build_ui()
	_refresh_display()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.07, 0.12, 0.95)
	add_child(bg)

	# Header Box
	var header = HBoxContainer.new()
	header.position = Vector2(40, 30)
	header.custom_minimum_size = Vector2(1200, 50)
	add_child(header)

	var title = Label.new()
	title.text = "AERORUSH GARAGE // VEHICLE SELECTION"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	header.add_child(title)

	header.add_spacer(false)

	credits_label = Label.new()
	credits_label.text = "CREDITS: 1,000 CR"
	credits_label.add_theme_font_size_override("font_size", 20)
	credits_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	header.add_child(credits_label)

	# Main Spec Panel (Left Side)
	var spec_panel = PanelContainer.new()
	spec_panel.position = Vector2(40, 110)
	spec_panel.custom_minimum_size = Vector2(420, 520)
	add_child(spec_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	spec_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = "APEX ZEPHYR"
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(name_label)

	class_label = Label.new()
	class_label.text = "HYPER-AERODYNAMIC INTERCEPTOR"
	class_label.add_theme_font_size_override("font_size", 14)
	class_label.add_theme_color_override("font_color", Color(0.1, 0.85, 1.0))
	vbox.add_child(class_label)

	desc_label = Label.new()
	desc_label.text = "Vehicle description and specifications."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(desc_label)

	# Stats Bars
	speed_bar = _add_stat_bar(vbox, "TOP SPEED", 65.0)
	accel_bar = _add_stat_bar(vbox, "ACCELERATION", 45.0)
	drift_bar = _add_stat_bar(vbox, "DRIFT AUTHORITY", 6.0)
	air_bar = _add_stat_bar(vbox, "AIR CONTROL", 6.0)

	vbox.add_spacer(false)

	# Unlock / Select Button
	unlock_btn = Button.new()
	unlock_btn.text = "SELECT VEHICLE"
	unlock_btn.custom_minimum_size = Vector2(0, 46)
	unlock_btn.pressed.connect(_on_unlock_or_select_pressed)
	vbox.add_child(unlock_btn)

	# Vehicle Selector Arrows
	var nav_hbox = HBoxContainer.new()
	nav_hbox.position = Vector2(520, 560)
	nav_hbox.custom_minimum_size = Vector2(400, 50)
	add_child(nav_hbox)

	var prev_btn = Button.new()
	prev_btn.text = "◀ PREVIOUS"
	prev_btn.custom_minimum_size = Vector2(140, 42)
	prev_btn.pressed.connect(func(): _cycle_vehicle(-1))
	nav_hbox.add_child(prev_btn)

	nav_hbox.add_spacer(false)

	var next_btn = Button.new()
	next_btn.text = "NEXT ▶"
	next_btn.custom_minimum_size = Vector2(140, 42)
	next_btn.pressed.connect(func(): _cycle_vehicle(1))
	nav_hbox.add_child(next_btn)

	# Back Button
	var back_btn = Button.new()
	back_btn.text = "RETURN TO MENU"
	back_btn.position = Vector2(40, 650)
	back_btn.custom_minimum_size = Vector2(180, 38)
	back_btn.pressed.connect(func(): back_to_menu_requested.emit())
	add_child(back_btn)

func _add_stat_bar(parent: VBoxContainer, label_text: String, max_val: float) -> ProgressBar:
	var l = Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	parent.add_child(l)

	var bar = ProgressBar.new()
	bar.max_value = max_val
	bar.custom_minimum_size = Vector2(0, 10)
	bar.show_percentage = false
	parent.add_child(bar)
	return bar

func _cycle_vehicle(dir: int) -> void:
	selected_idx = (selected_idx + dir + vehicle_list.size()) % vehicle_list.size()
	_refresh_display()

func _refresh_display() -> void:
	if vehicle_list.is_empty():
		return
	var v = vehicle_list[selected_idx]
	name_label.text = v.get("name", "").to_upper()
	class_label.text = v.get("class_title", "").to_upper()
	desc_label.text = v.get("desc", "")

	speed_bar.value = v.get("top_speed", 0.0)
	accel_bar.value = v.get("acceleration", 0.0)
	drift_bar.value = v.get("drift_factor", 0.0)
	air_bar.value = v.get("air_control_roll", 0.0)

	var data = AeroSaveAdapter.load_aero_data()
	credits_label.text = "CREDITS: %d CR" % data.get("credits", 0)

	var v_id = v.get("id", "")
	var is_unlocked = v_id in data.get("unlocked_vehicles", [])
	var cost = v.get("credit_cost", 0) as int

	if is_unlocked:
		unlock_btn.text = "SELECT VEHICLE"
		unlock_btn.disabled = false
	else:
		unlock_btn.text = "UNLOCK [%d CR]" % cost
		unlock_btn.disabled = data.get("credits", 0) < cost

func _on_unlock_or_select_pressed() -> void:
	var v = vehicle_list[selected_idx]
	var v_id = v.get("id", "")
	var data = AeroSaveAdapter.load_aero_data()

	if v_id in data.get("unlocked_vehicles", []):
		# Select
		data["selected_vehicle"] = v_id
		AeroSaveAdapter.save_aero_data(data)
		vehicle_selected.emit(v_id, current_paint_color)
		back_to_menu_requested.emit()
	else:
		var cost = v.get("credit_cost", 0) as int
		if AeroSaveAdapter.unlock_vehicle(v_id, cost):
			_refresh_display()
