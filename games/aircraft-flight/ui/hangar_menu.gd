class_name FlightHangarMenu
extends CanvasLayer

## FlightHangarMenu: Interactive 3D Turntable Aircraft Selector & Mission Briefer.
## Allows pilots to inspect aircraft specifications, view 3D rotating aircraft models,
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
var preview_viewport: SubViewport

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
	_update_selected_mission(selected_mission_id)

func _physics_process(delta: float) -> void:
	if is_instance_valid(turntable_root):
		turntable_root.rotate_y(delta * 0.45)

func _build_hangar_ui() -> void:
	root_control = Control.new()
	root_control.name = "HangarRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# --- 3D TURNTABLE PREVIEW VIEWPORT ---
	_build_turntable_viewport()

	# --- TOP HEADER: TITLE & EXIT ---
	var top_bar = _create_glass_panel(Vector2(680, 48))
	top_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_bar.offset_top = 14
	root_control.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(top_hbox)

	var header_lbl = Label.new()
	header_lbl.text = "APEX FLIGHT: OPEN SKIES — HANGAR & BRIEFING"
	header_lbl.add_theme_font_size_override("font_size", 15)
	header_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	top_hbox.add_child(header_lbl)

	# --- LEFT PANEL: AIRCRAFT SELECTOR & SPECIFICATIONS ---
	var left_panel = _create_glass_panel(Vector2(320, 500))
	left_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	left_panel.offset_left = 24
	root_control.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 6)
	left_panel.add_child(left_vbox)

	var ac_hdr = Label.new()
	ac_hdr.text = "SELECT AIRCRAFT"
	ac_hdr.add_theme_font_size_override("font_size", 12)
	ac_hdr.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	left_vbox.add_child(ac_hdr)

	# Aircraft Buttons Grid
	var all_aircraft = AircraftCatalog.get_all_aircraft()
	for ac in all_aircraft:
		var ac_id = ac.get("id", "")
		var btn = Button.new()
		btn.text = ac.get("name", "")
		btn.custom_minimum_size = Vector2(280, 28)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func(): _update_selected_aircraft(ac_id))
		left_vbox.add_child(btn)

	title_label = Label.new()
	title_label.text = "F/A-18C Hornet"
	title_label.add_theme_font_size_override("font_size", 15)
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
	desc_label.custom_minimum_size = Vector2(280, 42)
	desc_label.add_theme_font_size_override("font_size", 10)
	left_vbox.add_child(desc_label)

	# Spec Progress Bars
	left_vbox.add_child(_create_spec_row("TOP SPEED", 1000.0, func(bar): speed_bar = bar))
	left_vbox.add_child(_create_spec_row("THRUST RATING", 160000.0, func(bar): thrust_bar = bar))
	left_vbox.add_child(_create_spec_row("AGILITY / ROLL", 8.0, func(bar): agility_bar = bar))
	left_vbox.add_child(_create_spec_row("AIRFRAME G-RATING", 12.0, func(bar): g_bar = bar))

	# --- RIGHT PANEL: MISSION & WORLD SELECTOR ---
	var right_panel = _create_glass_panel(Vector2(320, 500))
	right_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_panel.offset_left = -344
	root_control.add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	right_panel.add_child(right_vbox)

	var m_hdr = Label.new()
	m_hdr.text = "SELECT MISSION"
	m_hdr.add_theme_font_size_override("font_size", 12)
	m_hdr.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	right_vbox.add_child(m_hdr)

	# Mission List Scroll Container (Prevents overflowing viewport)
	var mission_scroll = ScrollContainer.new()
	mission_scroll.custom_minimum_size = Vector2(280, 190)
	mission_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mission_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_vbox.add_child(mission_scroll)

	var m_list_vbox = VBoxContainer.new()
	m_list_vbox.add_theme_constant_override("separation", 4)
	m_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_scroll.add_child(m_list_vbox)

	var all_missions = MissionDefs.get_all_missions()
	for m in all_missions:
		var m_id = m.get("id", "")
		var btn = Button.new()
		btn.text = m.get("title", "")
		btn.custom_minimum_size = Vector2(260, 28)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(func(): _update_selected_mission(m_id))
		m_list_vbox.add_child(btn)

	mission_desc_label = Label.new()
	mission_desc_label.text = "Explore the vast 8km open world."
	mission_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mission_desc_label.custom_minimum_size = Vector2(280, 48)
	mission_desc_label.add_theme_font_size_override("font_size", 10)
	right_vbox.add_child(mission_desc_label)

	# Docked Action Buttons
	var btn_fly = Button.new()
	btn_fly.text = "★ FLY MISSION ★"
	btn_fly.custom_minimum_size = Vector2(280, 40)
	btn_fly.add_theme_font_size_override("font_size", 14)
	btn_fly.modulate = Color(0.2, 1.0, 0.4)
	btn_fly.pressed.connect(func():
		launch_requested.emit(selected_aircraft_id, selected_mission_id, selected_world_id, selected_primary_color, selected_accent_color)
	)
	right_vbox.add_child(btn_fly)

	var btn_exit = Button.new()
	btn_exit.text = "EXIT TO LAUNCHER"
	btn_exit.custom_minimum_size = Vector2(280, 30)
	btn_exit.add_theme_font_size_override("font_size", 11)
	btn_exit.pressed.connect(func(): exit_requested.emit())
	right_vbox.add_child(btn_exit)

func _build_turntable_viewport() -> void:
	var vp_container = SubViewportContainer.new()
	vp_container.name = "HangarTurntableContainer"
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_container.stretch = true
	vp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(vp_container)

	preview_viewport = SubViewport.new()
	preview_viewport.name = "HangarViewport"
	preview_viewport.own_world_3d = true
	preview_viewport.transparent_bg = false
	vp_container.add_child(preview_viewport)

	# World environment for showroom
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.07, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.40, 0.48)
	env.ambient_light_energy = 0.85
	world_env.environment = env
	preview_viewport.add_child(world_env)

	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 3.2, 9.5)
	cam.look_at(Vector3(0, 0.3, 0), Vector3.UP)
	cam.current = true
	cam.fov = 48.0
	preview_viewport.add_child(cam)

	# Showroom Directional Key Light
	var key_light = DirectionalLight3D.new()
	key_light.position = Vector3(5, 8, 7)
	key_light.rotation_degrees = Vector3(-35, 30, 0)
	key_light.light_color = Color(1.0, 0.98, 0.92)
	key_light.light_energy = 1.6
	preview_viewport.add_child(key_light)

	# Showroom Fill Rim Light
	var rim_light = DirectionalLight3D.new()
	rim_light.position = Vector3(-6, 5, -5)
	rim_light.rotation_degrees = Vector3(-25, -140, 0)
	rim_light.light_color = Color(0.2, 0.65, 1.0)
	rim_light.light_energy = 1.0
	preview_viewport.add_child(rim_light)

	# Pedestal Turntable Base
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.2
	cyl.bottom_radius = 4.5
	cyl.height = 0.35
	base_mesh.mesh = cyl
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.12, 0.14, 0.18)
	base_mat.metallic = 0.80
	base_mat.roughness = 0.35
	base_mesh.material_override = base_mat
	base_mesh.position = Vector3(0, -0.18, 0)
	preview_viewport.add_child(base_mesh)

	# Glowing Pedestal Ring
	var ring_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 4.0
	torus.outer_radius = 4.18
	ring_mesh.mesh = torus
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.15, 0.95, 0.35)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.15, 0.95, 0.35)
	ring_mat.emission_energy_multiplier = 2.5
	ring_mesh.material_override = ring_mat
	ring_mesh.position = Vector3(0, 0.01, 0)
	preview_viewport.add_child(ring_mesh)

	turntable_root = Node3D.new()
	turntable_root.name = "TurntableRoot"
	preview_viewport.add_child(turntable_root)

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

	# Update 3D preview model
	if is_instance_valid(turntable_root):
		if is_instance_valid(current_preview_model):
			current_preview_model.queue_free()

		current_preview_model = MeshBuilder.build_aircraft_visuals(ac_id, selected_primary_color, selected_accent_color)
		if current_preview_model:
			current_preview_model.name = "PreviewAircraftModel"
			current_preview_model.position = Vector3(0, 0.65, 0)
			# Scale large airliners down slightly to fit turntable neatly
			if ac_id == "a320_skyliner":
				current_preview_model.scale = Vector3(0.38, 0.38, 0.38)
			elif ac_id == "f22_raptor" or ac_id == "fa18_hornet":
				current_preview_model.scale = Vector3(0.58, 0.58, 0.58)
			else:
				current_preview_model.scale = Vector3(0.65, 0.65, 0.65)
			turntable_root.add_child(current_preview_model)

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
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	pc.add_theme_stylebox_override("panel", style)
	return pc
