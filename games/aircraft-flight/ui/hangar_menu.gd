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

var is_dragging: bool = false
var last_mouse_x: float = 0.0

func _physics_process(delta: float) -> void:
	if is_instance_valid(turntable_root) and not is_dragging:
		turntable_root.rotate_y(delta * 0.35)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_x = event.position.x
	elif event is InputEventMouseMotion and is_dragging:
		var dx = event.position.x - last_mouse_x
		last_mouse_x = event.position.x
		if is_instance_valid(turntable_root):
			turntable_root.rotate_y(dx * 0.008)

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

	# World environment for aerospace showroom
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.09, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.52, 0.62)
	env.ambient_light_energy = 1.15
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	world_env.environment = env
	preview_viewport.add_child(world_env)

	# Studio Camera: perfectly framed at eye level with slight upward angle
	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 2.6, 9.8)
	cam.look_at(Vector3(0.0, 0.65, 0.0), Vector3.UP)
	cam.current = true
	cam.fov = 46.0
	preview_viewport.add_child(cam)

	# Three-Point Studio Lighting
	# 1. Warm Directional Key Light
	var key_light = DirectionalLight3D.new()
	key_light.position = Vector3(6, 9, 8)
	key_light.rotation_degrees = Vector3(-35, 32, 0)
	key_light.light_color = Color(1.0, 0.98, 0.94)
	key_light.light_energy = 2.4
	preview_viewport.add_child(key_light)

	# 2. Cool Cyan Rim Light (Accentuates aircraft silhouettes)
	var rim_light = DirectionalLight3D.new()
	rim_light.position = Vector3(-7, 6, -6)
	rim_light.rotation_degrees = Vector3(-25, -145, 0)
	rim_light.light_color = Color(0.25, 0.75, 1.0)
	rim_light.light_energy = 1.8
	preview_viewport.add_child(rim_light)

	# 3. Soft Overhead Turntable Downlight
	var top_light = OmniLight3D.new()
	top_light.position = Vector3(0, 7.5, 0)
	top_light.light_color = Color(0.95, 0.98, 1.0)
	top_light.light_energy = 2.0
	top_light.omni_range = 16.0
	preview_viewport.add_child(top_light)

	# --- 3D HANGAR BAY ARCHITECTURE ---
	# Polished Epoxy Hangar Floor
	var floor_mesh = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(50.0, 0.4, 50.0)
	floor_mesh.mesh = f_box
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.11, 0.13, 0.16)
	f_mat.metallic = 0.65
	f_mat.roughness = 0.32
	floor_mesh.material_override = f_mat
	floor_mesh.position = Vector3(0, -0.2, 0)
	preview_viewport.add_child(floor_mesh)

	# Hangar Rear Wall with Architectural Ribbed Panels & Columns
	var wall_mesh = MeshInstance3D.new()
	var w_box = BoxMesh.new()
	w_box.size = Vector3(45.0, 20.0, 0.8)
	wall_mesh.mesh = w_box
	var w_mat = StandardMaterial3D.new()
	w_mat.albedo_color = Color(0.14, 0.17, 0.22)
	w_mat.roughness = 0.75
	wall_mesh.material_override = w_mat
	wall_mesh.position = Vector3(0, 10.0, -14.0)
	preview_viewport.add_child(wall_mesh)

	# Structural Side Columns (Left & Right)
	var col_mat = StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.18, 0.21, 0.26)
	col_mat.metallic = 0.6
	col_mat.roughness = 0.4
	for cx in [-18.0, 18.0]:
		for cz in [-12.0, -4.0, 4.0]:
			var col = MeshInstance3D.new()
			var col_box = BoxMesh.new()
			col_box.size = Vector3(1.2, 18.0, 1.2)
			col.mesh = col_box
			col.material_override = col_mat
			col.position = Vector3(cx, 9.0, cz)
			preview_viewport.add_child(col)

	# Overhead Industrial Steel Roof Trusses
	var truss_mat = StandardMaterial3D.new()
	truss_mat.albedo_color = Color(0.25, 0.28, 0.32)
	truss_mat.metallic = 0.85
	truss_mat.roughness = 0.35
	for tz in [-10.0, -3.0, 4.0]:
		var truss_beam = MeshInstance3D.new()
		var beam_box = BoxMesh.new()
		beam_box.size = Vector3(38.0, 0.8, 0.8)
		truss_beam.mesh = beam_box
		truss_beam.material_override = truss_mat
		truss_beam.position = Vector3(0, 14.0, tz)
		preview_viewport.add_child(truss_beam)

		# Cross struts
		for sx in [-12.0, 0.0, 12.0]:
			var strut = MeshInstance3D.new()
			var s_box = BoxMesh.new()
			s_box.size = Vector3(0.4, 3.0, 0.4)
			strut.mesh = s_box
			strut.material_override = truss_mat
			strut.position = Vector3(sx, 12.5, tz)
			preview_viewport.add_child(strut)

	# Hangar Wall Accent Stripes & LED strip
	var strip_mesh = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(40.0, 0.15, 0.1)
	strip_mesh.mesh = s_box
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.2, 0.9, 0.4)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.2, 0.9, 0.4)
	s_mat.emission_energy_multiplier = 3.0
	strip_mesh.material_override = s_mat
	strip_mesh.position = Vector3(0, 6.0, -13.5)
	preview_viewport.add_child(strip_mesh)

	# Floor Guide Run Lights
	var guide_mat = StandardMaterial3D.new()
	guide_mat.albedo_color = Color(0.2, 0.8, 1.0)
	guide_mat.emission_enabled = true
	guide_mat.emission = Color(0.2, 0.8, 1.0)
	guide_mat.emission_energy_multiplier = 2.5
	for gz in [-10.0, -6.0, -2.0, 2.0, 6.0]:
		for gx in [-6.5, 6.5]:
			var gl = MeshInstance3D.new()
			var g_cyl = CylinderMesh.new()
			g_cyl.top_radius = 0.08
			g_cyl.bottom_radius = 0.08
			g_cyl.height = 0.05
			gl.mesh = g_cyl
			gl.material_override = guide_mat
			gl.position = Vector3(gx, 0.02, gz)
			preview_viewport.add_child(gl)

	# Pedestal Turntable Base
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.4
	cyl.bottom_radius = 4.8
	cyl.height = 0.35
	base_mesh.mesh = cyl
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.16, 0.19, 0.24)
	base_mat.metallic = 0.85
	base_mat.roughness = 0.28
	base_mesh.material_override = base_mat
	base_mesh.position = Vector3(0, -0.15, 0)
	preview_viewport.add_child(base_mesh)

	# Glowing Pedestal Ring
	var ring_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 4.2
	torus.outer_radius = 4.42
	ring_mesh.mesh = torus
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.2, 0.95, 0.4)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.2, 0.95, 0.4)
	ring_mat.emission_energy_multiplier = 3.0
	ring_mesh.material_override = ring_mat
	ring_mesh.position = Vector3(0, 0.04, 0)
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
			# Scale models appropriately to frame turntable center
			if ac_id == "a320_airliner":
				current_preview_model.scale = Vector3(0.24, 0.24, 0.24)
			elif ac_id == "uh60_helicopter":
				current_preview_model.scale = Vector3(0.40, 0.40, 0.40)
				current_preview_model.position = Vector3(0, 0.65, -0.3)
			elif ac_id == "f22_raptor":
				current_preview_model.scale = Vector3(0.44, 0.44, 0.44)
			elif ac_id == "fa18_hornet":
				current_preview_model.scale = Vector3(0.46, 0.46, 0.46)
			else: # Extra 330
				current_preview_model.scale = Vector3(0.60, 0.60, 0.60)
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
