class_name ChromaGarage
extends Control

## 3D Turntable Garage and Customization Suite for Chroma Rush
## Lets players inspect stats, unlock vehicles with credits, and configure paint finishes.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const VehicleCatalog = preload("res://games/chroma-rush/vehicles/vehicle_catalog.gd")
const VehicleVisuals = preload("res://games/chroma-rush/vehicles/vehicle_visuals.gd")
const ChromaSaveAdapter = preload("res://games/chroma-rush/persistence/chroma_save_adapter.gd")

signal back_to_menu_requested()
signal vehicle_selected_for_play(vehicle_id: String)
signal garage_closed()
signal vehicle_selected(vehicle_id: String, color: Color, finish: String)

var save_adapter: Variant = null

var vehicle_display_root: Node3D
var current_preview_vehicle: Node3D
var turntable_yaw: float = 0.0

var selected_vehicle_idx: int = 0
var all_vehicle_ids: Array[String] = []

# UI Elements
var vehicle_name_label: Label
var tagline_label: Label
var stats_container: VBoxContainer
var credits_label: Label
var action_button: Button
var paint_selector: OptionButton
var garage_cam: Camera3D

func _ready() -> void:
	all_vehicle_ids = VehicleCatalog.get_all_vehicle_ids()
	var current_saved = ChromaSaveAdapter.get_selected_vehicle()
	selected_vehicle_idx = maxi(0, all_vehicle_ids.find(current_saved))

	setup_ui_layout()
	setup_3d_turntable()
	refresh_display()

func open_garage() -> void:
	visible = true
	if is_instance_valid(vehicle_display_root):
		vehicle_display_root.visible = true
		for c in vehicle_display_root.get_children():
			if c is DirectionalLight3D:
				c.visible = true
	if is_instance_valid(garage_cam):
		garage_cam.make_current()
	refresh_display()


func setup_ui_layout() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Dark Gradient Background
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.08, 0.10, 0.15, 0.92)
	add_child(bg)

	# Left Sidebar: Vehicle Info & Customization
	var sidebar = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(360, 0)
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = 32
	sidebar.offset_top = 32
	sidebar.offset_bottom = -32
	sidebar.offset_right = 392
	add_child(sidebar)

	var svbox = VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 12)
	sidebar.add_child(svbox)

	var title = Label.new()
	title.text = "CHROMA GARAGE"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	svbox.add_child(title)

	credits_label = Label.new()
	credits_label.text = "CREDITS: 1,000"
	credits_label.add_theme_font_size_override("font_size", 16)
	credits_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	svbox.add_child(credits_label)

	var div1 = HSeparator.new()
	svbox.add_child(div1)

	# Vehicle Selector Buttons (< Prev / Next >)
	var nav_box = HBoxContainer.new()
	var prev_btn = Button.new()
	prev_btn.text = "◀ PREV"
	prev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev_btn.pressed.connect(func(): _navigate_vehicle(-1))
	nav_box.add_child(prev_btn)

	var next_btn = Button.new()
	next_btn.text = "NEXT ▶"
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_btn.pressed.connect(func(): _navigate_vehicle(1))
	nav_box.add_child(next_btn)
	svbox.add_child(nav_box)

	vehicle_name_label = Label.new()
	vehicle_name_label.text = "Apex Striker"
	vehicle_name_label.add_theme_font_size_override("font_size", 22)
	svbox.add_child(vehicle_name_label)

	tagline_label = Label.new()
	tagline_label.text = "Hyper-Aerodynamic Interceptor"
	tagline_label.add_theme_font_size_override("font_size", 13)
	tagline_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	svbox.add_child(tagline_label)

	# Performance Stats Bars
	stats_container = VBoxContainer.new()
	svbox.add_child(stats_container)

	# Paint Finish Selector
	var paint_lbl = Label.new()
	paint_lbl.text = "COSMETIC PAINT FINISH:"
	paint_lbl.add_theme_font_size_override("font_size", 13)
	svbox.add_child(paint_lbl)

	paint_selector = OptionButton.new()
	paint_selector.add_item("Metallic", 0)
	paint_selector.add_item("Gloss", 1)
	paint_selector.add_item("Matte", 2)
	paint_selector.add_item("Iridescent", 3)
	paint_selector.add_item("Carbon", 4)
	paint_selector.item_selected.connect(_on_paint_selected)
	svbox.add_child(paint_selector)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svbox.add_child(spacer)

	# Action Button (Select / Buy)
	action_button = Button.new()
	action_button.text = "SELECT VEHICLE"
	action_button.custom_minimum_size = Vector2(0, 48)
	action_button.pressed.connect(_on_action_pressed)
	svbox.add_child(action_button)

	# Back Button
	var back_btn = Button.new()
	back_btn.text = "BACK TO MENU"
	back_btn.pressed.connect(func():
		if is_instance_valid(garage_cam):
			garage_cam.current = false
		if is_instance_valid(vehicle_display_root):
			vehicle_display_root.visible = false
			for c in vehicle_display_root.get_children():
				if c is DirectionalLight3D:
					c.visible = false
		visible = false
		back_to_menu_requested.emit()
		garage_closed.emit()
	)
	svbox.add_child(back_btn)

func setup_3d_turntable() -> void:
	vehicle_display_root = Node3D.new()
	vehicle_display_root.name = "TurntableRoot"
	vehicle_display_root.visible = false
	add_child(vehicle_display_root)

	# Studio 3-point lighting (active only when garage is open)
	var key_light = DirectionalLight3D.new()
	key_light.name = "GarageKeyLight"
	key_light.rotation_degrees = Vector3(-45, -30, 0)
	key_light.light_energy = 1.3
	key_light.visible = false
	vehicle_display_root.add_child(key_light)

	var fill_light = DirectionalLight3D.new()
	fill_light.name = "GarageFillLight"
	fill_light.rotation_degrees = Vector3(-20, 150, 0)
	fill_light.light_color = Color(0.2, 0.6, 1.0)
	fill_light.light_energy = 0.6
	fill_light.visible = false
	vehicle_display_root.add_child(fill_light)

	garage_cam = Camera3D.new()
	garage_cam.name = "GarageCam"
	garage_cam.current = false
	garage_cam.position = Vector3(2.5, 1.8, 5.0)
	vehicle_display_root.add_child(garage_cam)
	garage_cam.look_at(Vector3(0.5, 0.6, 0), Vector3.UP)


func _process(delta: float) -> void:
	if current_preview_vehicle and is_instance_valid(current_preview_vehicle):
		turntable_yaw += delta * 0.4
		current_preview_vehicle.rotation.y = turntable_yaw

func _navigate_vehicle(dir: int) -> void:
	selected_vehicle_idx = (selected_vehicle_idx + dir + all_vehicle_ids.size()) % all_vehicle_ids.size()
	refresh_display()

func refresh_display() -> void:
	if all_vehicle_ids.is_empty():
		all_vehicle_ids = VehicleCatalog.get_all_vehicle_ids()
	if all_vehicle_ids.is_empty() or selected_vehicle_idx >= all_vehicle_ids.size():
		return
	if not is_instance_valid(vehicle_name_label):
		return

	var v_id = all_vehicle_ids[selected_vehicle_idx]
	var def = VehicleCatalog.get_vehicle_definition(v_id)
	var is_unlocked = ChromaSaveAdapter.is_vehicle_unlocked(v_id)
	var is_selected = (ChromaSaveAdapter.get_selected_vehicle() == v_id)

	var data = ChromaSaveAdapter.load_chroma_data()
	credits_label.text = "CREDITS: %s" % _format_number(data["credits"])

	vehicle_name_label.text = def["name"]
	tagline_label.text = def["tagline"]

	_update_stats_display(def)

	# Paint finish
	var cur_paint = ChromaSaveAdapter.get_vehicle_paint(v_id)
	var paint_idx = ["metallic", "gloss", "matte", "iridescent", "carbon"].find(cur_paint)
	if paint_idx >= 0:
		paint_selector.selected = paint_idx

	if is_selected:
		action_button.text = "✓ CURRENTLY EQUIPPED"
		action_button.disabled = true
	elif is_unlocked:
		action_button.text = "SELECT VEHICLE"
		action_button.disabled = false
	else:
		action_button.text = "UNLOCK FOR %s CR" % _format_number(def["credit_cost"])
		action_button.disabled = (data["credits"] < def["credit_cost"])

	_spawn_preview_vehicle(v_id, cur_paint)

func _update_stats_display(def: Dictionary) -> void:
	for child in stats_container.get_children():
		child.queue_free()

	_add_stat_bar("TOP SPEED", def["top_speed"], 25.0, 42.0)
	_add_stat_bar("ACCELERATION", def["acceleration"], 20.0, 36.0)
	_add_stat_bar("HANDLING", def["steer_speed"], 2.0, 4.5)
	_add_stat_bar("DRIFT RESPONSE", def["drift_factor"], 2.5, 5.5)
	_add_stat_bar("BRAKING", def["brake_force"], 25.0, 45.0)

func _add_stat_bar(stat_name: String, val: float, min_v: float, max_v: float) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = stat_name
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	hbox.add_child(lbl)

	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = min_v
	bar.max_value = max_v
	bar.value = val
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	hbox.add_child(bar)
	stats_container.add_child(hbox)

func _spawn_preview_vehicle(v_id: String, paint: String) -> void:
	if current_preview_vehicle and is_instance_valid(current_preview_vehicle):
		current_preview_vehicle.queue_free()

	current_preview_vehicle = VehicleVisuals.build_vehicle_visual(v_id, ChromaConstants.ChromaColor.CYAN, paint)
	vehicle_display_root.add_child(current_preview_vehicle)

func _on_paint_selected(idx: int) -> void:
	var paints = ["metallic", "gloss", "matte", "iridescent", "carbon"]
	var selected_paint = paints[idx]
	var v_id = all_vehicle_ids[selected_vehicle_idx]
	ChromaSaveAdapter.set_vehicle_paint(v_id, selected_paint)
	_spawn_preview_vehicle(v_id, selected_paint)

func _on_action_pressed() -> void:
	var v_id = all_vehicle_ids[selected_vehicle_idx]
	if ChromaSaveAdapter.is_vehicle_unlocked(v_id):
		ChromaSaveAdapter.select_vehicle(v_id)
		vehicle_selected_for_play.emit(v_id)
		vehicle_selected.emit(v_id, Color.WHITE, "metallic")
		refresh_display()
	else:
		if ChromaSaveAdapter.unlock_vehicle(v_id):
			ChromaSaveAdapter.select_vehicle(v_id)
			vehicle_selected_for_play.emit(v_id)
			vehicle_selected.emit(v_id, Color.WHITE, "metallic")
			refresh_display()

func _format_number(n: int) -> String:
	return str(n)
