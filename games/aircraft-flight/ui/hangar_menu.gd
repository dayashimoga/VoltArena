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

# Interactive Tactical Mission Preview Components
var mission_map_canvas: Control
var briefing_alt_val: Label
var briefing_time_val: Label
var briefing_weather_val: Label
var briefing_diff_val: Label

# Cinematic Camera Rig
var studio_cam: Camera3D
var target_cam_pos: Vector3 = Vector3(0.0, 2.6, 9.8)
var target_cam_look: Vector3 = Vector3(0.0, 0.65, 0.0)

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

	# Smooth cinematic camera pan toward mission framing
	if is_instance_valid(studio_cam):
		studio_cam.position = studio_cam.position.lerp(target_cam_pos, delta * 3.0)
		var current_look = studio_cam.position - studio_cam.transform.basis.z * 5.0
		var next_look = current_look.lerp(target_cam_look, delta * 3.5)
		studio_cam.look_at(next_look, Vector3.UP)

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

	# --- RIGHT PANEL: INTERACTIVE TACTICAL MISSION PREVIEW & BRIEFING ---
	var right_panel = _create_glass_panel(Vector2(350, 560))
	right_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_panel.offset_left = -374
	root_control.add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	right_panel.add_child(right_vbox)

	var m_hdr = Label.new()
	m_hdr.text = "MISSION SELECTION & BRIEFING"
	m_hdr.add_theme_font_size_override("font_size", 12)
	m_hdr.add_theme_color_override("font_color", Color(0.2, 0.95, 0.4))
	right_vbox.add_child(m_hdr)

	# Mission List Scroll Container (Compact button list)
	var mission_scroll = ScrollContainer.new()
	mission_scroll.custom_minimum_size = Vector2(310, 110)
	mission_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mission_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_vbox.add_child(mission_scroll)

	var m_list_vbox = VBoxContainer.new()
	m_list_vbox.add_theme_constant_override("separation", 3)
	m_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_scroll.add_child(m_list_vbox)

	var all_missions = MissionDefs.get_all_missions()
	for m in all_missions:
		var m_id = m.get("id", "")
		var btn = Button.new()
		btn.text = m.get("title", "")
		btn.custom_minimum_size = Vector2(290, 26)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(func(): _update_selected_mission(m_id))
		m_list_vbox.add_child(btn)

	# Interactive Tactical Route Map Canvas
	var map_hdr = Label.new()
	map_hdr.text = "TACTICAL ROUTE & AIRSPACE"
	map_hdr.add_theme_font_size_override("font_size", 10)
	map_hdr.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	right_vbox.add_child(map_hdr)

	mission_map_canvas = Control.new()
	mission_map_canvas.custom_minimum_size = Vector2(310, 125)
	mission_map_canvas.draw.connect(func(): _draw_tactical_mission_map(mission_map_canvas))
	right_vbox.add_child(mission_map_canvas)

	# Mission Briefing Metrics Grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 3)
	right_vbox.add_child(grid)

	var l_alt = Label.new()
	l_alt.text = "ALTITUDE:"
	l_alt.add_theme_font_size_override("font_size", 10)
	l_alt.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	grid.add_child(l_alt)
	briefing_alt_val = Label.new()
	briefing_alt_val.text = "Open"
	briefing_alt_val.add_theme_font_size_override("font_size", 10)
	briefing_alt_val.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	grid.add_child(briefing_alt_val)

	var l_time = Label.new()
	l_time.text = "EST. TIME:"
	l_time.add_theme_font_size_override("font_size", 10)
	l_time.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	grid.add_child(l_time)
	briefing_time_val = Label.new()
	briefing_time_val.text = "Unlimited"
	briefing_time_val.add_theme_font_size_override("font_size", 10)
	briefing_time_val.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	grid.add_child(briefing_time_val)

	var l_wx = Label.new()
	l_wx.text = "WEATHER:"
	l_wx.add_theme_font_size_override("font_size", 10)
	l_wx.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	grid.add_child(l_wx)
	briefing_weather_val = Label.new()
	briefing_weather_val.text = "VMC Clear"
	briefing_weather_val.add_theme_font_size_override("font_size", 10)
	briefing_weather_val.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	grid.add_child(briefing_weather_val)

	var l_diff = Label.new()
	l_diff.text = "DIFFICULTY:"
	l_diff.add_theme_font_size_override("font_size", 10)
	l_diff.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	grid.add_child(l_diff)
	briefing_diff_val = Label.new()
	briefing_diff_val.text = "★☆☆☆☆"
	briefing_diff_val.add_theme_font_size_override("font_size", 10)
	briefing_diff_val.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	grid.add_child(briefing_diff_val)

	mission_desc_label = Label.new()
	mission_desc_label.text = "Explore the vast 8km open world."
	mission_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mission_desc_label.custom_minimum_size = Vector2(310, 36)
	mission_desc_label.add_theme_font_size_override("font_size", 9)
	right_vbox.add_child(mission_desc_label)

	# Action Buttons
	var btn_fly = Button.new()
	btn_fly.text = "★ FLY MISSION ★"
	btn_fly.custom_minimum_size = Vector2(310, 36)
	btn_fly.add_theme_font_size_override("font_size", 13)
	btn_fly.modulate = Color(0.2, 1.0, 0.4)
	btn_fly.pressed.connect(func():
		launch_requested.emit(selected_aircraft_id, selected_mission_id, selected_world_id, selected_primary_color, selected_accent_color)
	)
	right_vbox.add_child(btn_fly)

	var btn_exit = Button.new()
	btn_exit.text = "EXIT TO LAUNCHER"
	btn_exit.custom_minimum_size = Vector2(310, 26)
	btn_exit.add_theme_font_size_override("font_size", 10)
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
	studio_cam = Camera3D.new()
	studio_cam.position = Vector3(0.0, 2.6, 9.8)
	studio_cam.current = true
	studio_cam.fov = 46.0
	preview_viewport.add_child(studio_cam)
	studio_cam.look_at(Vector3(0.0, 0.65, 0.0), Vector3.UP)

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
	floor_mesh.mesh = _create_box_mesh(Vector3(50.0, 0.4, 50.0))
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.11, 0.13, 0.16)
	f_mat.metallic = 0.65
	f_mat.roughness = 0.32
	floor_mesh.material_override = f_mat
	floor_mesh.position = Vector3(0, -0.2, 0)
	preview_viewport.add_child(floor_mesh)

	# Hangar Rear Wall with Architectural Ribbed Panels & Columns
	var wall_mesh = MeshInstance3D.new()
	wall_mesh.mesh = _create_box_mesh(Vector3(45.0, 20.0, 0.8))
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
			col.mesh = _create_box_mesh(Vector3(1.2, 18.0, 1.2))
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
		truss_beam.mesh = _create_box_mesh(Vector3(38.0, 0.8, 0.8))
		truss_beam.material_override = truss_mat
		truss_beam.position = Vector3(0, 14.0, tz)
		preview_viewport.add_child(truss_beam)

		# Cross struts
		for sx in [-12.0, 0.0, 12.0]:
			var strut = MeshInstance3D.new()
			strut.mesh = _create_box_mesh(Vector3(0.4, 3.0, 0.4))
			strut.material_override = truss_mat
			strut.position = Vector3(sx, 12.5, tz)
			preview_viewport.add_child(strut)

	# Hangar Wall Accent Stripes & LED strip
	var strip_mesh = MeshInstance3D.new()
	strip_mesh.mesh = _create_box_mesh(Vector3(40.0, 0.15, 0.1))
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
			gl.mesh = _create_cyl_mesh(0.08, 0.08, 0.05, 12)
			gl.material_override = guide_mat
			gl.position = Vector3(gx, 0.02, gz)
			preview_viewport.add_child(gl)

	# Pedestal Turntable Base
	var base_mesh = MeshInstance3D.new()
	base_mesh.mesh = _create_cyl_mesh(4.4, 4.8, 0.35, 24)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.16, 0.19, 0.24)
	base_mat.metallic = 0.85
	base_mat.roughness = 0.28
	base_mesh.material_override = base_mat
	base_mesh.position = Vector3(0, -0.15, 0)
	preview_viewport.add_child(base_mesh)

	# Glowing Pedestal Ring
	var ring_mesh = MeshInstance3D.new()
	ring_mesh.mesh = _create_ring_mesh(4.2, 4.42, 0.04, 32)
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
	if mission_desc_label:
		mission_desc_label.text = m.get("desc", "")
	selected_world_id = m.get("world_id", "metropolitan_city")

	# Update Briefing Metrics & Camera Target
	if briefing_alt_val and briefing_time_val and briefing_weather_val and briefing_diff_val:
		match m_id:
			"m1_free_flight":
				briefing_alt_val.text = "Open (0 - 4,000m MSL)"
				briefing_time_val.text = "Unlimited"
				briefing_weather_val.text = "Clear / 090° @ 4 kts"
				briefing_diff_val.text = "★☆☆☆☆ (Beginner)"
				target_cam_pos = Vector3(0.0, 2.6, 9.8)
				target_cam_look = Vector3(0.0, 0.65, 0.0)
			"m2_takeoff_landing":
				briefing_alt_val.text = "600m MSL (Flare < 2.5 m/s)"
				briefing_time_val.text = "180s (ILS Circuit)"
				briefing_weather_val.text = "Crosswind 090° @ 8 kts"
				briefing_diff_val.text = "★★☆☆☆ (Moderate)"
				target_cam_pos = Vector3(2.5, 2.2, 8.5)
				target_cam_look = Vector3(0.0, 0.65, 0.0)
			"m3_urban_corridor":
				briefing_alt_val.text = "< 120m AGL (Downtown Deck)"
				briefing_time_val.text = "120s (Corridor Run)"
				briefing_weather_val.text = "Wind Shear / Gusts 16 kts"
				briefing_diff_val.text = "★★★☆☆ (Advanced)"
				target_cam_pos = Vector3(-3.0, 1.8, 8.2)
				target_cam_look = Vector3(0.0, 0.50, 0.0)
			"m4_checkpoint_race":
				briefing_alt_val.text = "55m - 220m AGL (8 Rings)"
				briefing_time_val.text = "90s (Gold < 45s)"
				briefing_weather_val.text = "Harbor Breeze 12 kts"
				briefing_diff_val.text = "★★★★☆ (Expert)"
				target_cam_pos = Vector3(0.0, 3.2, 9.2)
				target_cam_look = Vector3(0.0, 0.40, 0.0)
			"m5_deadstick":
				briefing_alt_val.text = "2,800m MSL (Deadstick Glide)"
				briefing_time_val.text = "150s (Engine Flameout)"
				briefing_weather_val.text = "Mountain Sink / Turb"
				briefing_diff_val.text = "★★★★☆ (Emergency)"
				target_cam_pos = Vector3(3.2, 3.6, 10.5)
				target_cam_look = Vector3(0.0, 0.70, 0.0)
			"m6_mountain_slalom":
				briefing_alt_val.text = "150m AGL (Ridge Contour)"
				briefing_time_val.text = "110s (Gold < 55s)"
				briefing_weather_val.text = "Alpine Shear / 22 kts"
				briefing_diff_val.text = "★★★★★ (Ace)"
				target_cam_pos = Vector3(-2.8, 2.4, 8.8)
				target_cam_look = Vector3(0.0, 0.60, 0.0)
			_:
				briefing_alt_val.text = "Standard Flight Envelope"
				briefing_time_val.text = "120s"
				briefing_weather_val.text = "VFR Conditions"
				briefing_diff_val.text = "★★★☆☆ (Advanced)"
				target_cam_pos = Vector3(0.0, 2.6, 9.8)
				target_cam_look = Vector3(0.0, 0.65, 0.0)

	if is_instance_valid(mission_map_canvas):
		mission_map_canvas.queue_redraw()

func _draw_tactical_mission_map(canvas: Control) -> void:
	var sz = canvas.size
	if sz.x <= 10.0 or sz.y <= 10.0:
		return
	var center = sz * 0.5
	var bg_col = Color(0.04, 0.08, 0.12, 0.95)
	var border_col = Color(0.15, 0.85, 0.45, 0.7)
	var grid_col = Color(0.12, 0.28, 0.35, 0.5)
	var waypoint_col = Color(0.2, 0.95, 1.0)
	var line_col = Color(0.2, 0.95, 0.5, 0.85)

	# 1. Background and border
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), bg_col, true)
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), border_col, false, 1.5)

	# 2. Concentric radar range rings
	for r in [22.0, 44.0, 64.0]:
		canvas.draw_arc(center, r, 0.0, TAU, 32, grid_col, 1.0)

	# Crosshairs
	canvas.draw_line(Vector2(center.x, 6), Vector2(center.x, sz.y - 6), grid_col, 1.0)
	canvas.draw_line(Vector2(6, center.y), Vector2(sz.x - 6, center.y), grid_col, 1.0)

	# Compass marks
	var font = ThemeDB.fallback_font
	canvas.draw_string(font, Vector2(center.x - 4, 12), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.6, 0.8, 0.9))
	canvas.draw_string(font, Vector2(center.x - 4, sz.y - 3), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.6, 0.8, 0.9))
	canvas.draw_string(font, Vector2(5, center.y + 3), "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.8, 0.9))
	canvas.draw_string(font, Vector2(sz.x - 12, center.y + 3), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.8, 0.9))

	# 3. Draw Runway Strip
	var rwy_rect = Rect2(center.x - 16, center.y + 18, 32, 6)
	canvas.draw_rect(rwy_rect, Color(0.2, 0.25, 0.3), true)
	canvas.draw_line(Vector2(rwy_rect.position.x, rwy_rect.position.y + 3), Vector2(rwy_rect.end.x, rwy_rect.position.y + 3), Color.WHITE, 1.0)
	canvas.draw_string(font, Vector2(rwy_rect.position.x - 20, rwy_rect.position.y + 6), "09L", HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, Color(0.8, 0.9, 1.0))

	# 4. Waypoint Trajectory or Circuit Pattern
	var m = MissionDefs.get_mission(selected_mission_id)
	var waypoints: Array = m.get("ring_waypoints", [])
	if not waypoints.is_empty():
		var pts: Array[Vector2] = []
		for wp in waypoints:
			var px = center.x + (wp.x / 2500.0) * (sz.x * 0.40)
			var py = center.y + (wp.z / 2500.0) * (sz.y * 0.40)
			pts.append(Vector2(clampf(px, 12, sz.x - 12), clampf(py, 12, sz.y - 12)))

		for i in range(pts.size() - 1):
			canvas.draw_line(pts[i], pts[i + 1], line_col, 2.0)

		for i in range(pts.size()):
			canvas.draw_circle(pts[i], 4.5, Color(0.04, 0.08, 0.12))
			canvas.draw_arc(pts[i], 4.5, 0.0, TAU, 16, waypoint_col, 1.8)
			canvas.draw_string(font, pts[i] + Vector2(5, -3), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	else:
		var circuit_pts = [
			Vector2(center.x - 25, center.y + 18),
			Vector2(center.x + 30, center.y + 18),
			Vector2(center.x + 45, center.y - 20),
			Vector2(center.x - 40, center.y - 20),
			Vector2(center.x - 25, center.y + 18)
		]
		for i in range(circuit_pts.size() - 1):
			canvas.draw_line(circuit_pts[i], circuit_pts[i + 1], Color(0.2, 0.9, 0.5, 0.65), 1.5)

	# Start Aircraft Indicator
	var start_pos = Vector2(center.x - 14, center.y + 21)
	canvas.draw_circle(start_pos, 3.5, Color(0.2, 1.0, 0.4))

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

static func _create_box_mesh(size: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var faces = [
		[Vector3(0, 0, 1), [Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]],
		[Vector3(0, 0, -1), [Vector3(hx, -hy, -hz), Vector3(-hx, -hy, -hz), Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz)]],
		[Vector3(1, 0, 0), [Vector3(hx, -hy, hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz)]],
		[Vector3(-1, 0, 0), [Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(-hx, hy, hz), Vector3(-hx, hy, -hz)]],
		[Vector3(0, 1, 0), [Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz)]],
		[Vector3(0, -1, 0), [Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz)]]
	]
	for f in faces:
		var norm: Vector3 = f[0]
		var v: Array = f[1]
		st.set_normal(norm)
		st.add_vertex(v[0])
		st.add_vertex(v[1])
		st.add_vertex(v[2])
		st.add_vertex(v[0])
		st.add_vertex(v[2])
		st.add_vertex(v[3])
	return st.commit()

static func _create_cyl_mesh(top_r: float, bot_r: float, height: float, seg: int = 16) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hy: float = height * 0.5
	for i in range(seg):
		var a0: float = float(i) / float(seg) * TAU
		var a1: float = float(i + 1) / float(seg) * TAU
		var p_b0 = Vector3(cos(a0) * bot_r, -hy, sin(a0) * bot_r)
		var p_b1 = Vector3(cos(a1) * bot_r, -hy, sin(a1) * bot_r)
		var p_t0 = Vector3(cos(a0) * top_r, hy, sin(a0) * top_r)
		var p_t1 = Vector3(cos(a1) * top_r, hy, sin(a1) * top_r)
		var n0 = Vector3(cos(a0), 0, sin(a0)).normalized()
		var n1 = Vector3(cos(a1), 0, sin(a1)).normalized()
		st.set_normal(n0)
		st.add_vertex(p_b0)
		st.set_normal(n1)
		st.add_vertex(p_b1)
		st.set_normal(n1)
		st.add_vertex(p_t1)
		st.set_normal(n0)
		st.add_vertex(p_b0)
		st.set_normal(n1)
		st.add_vertex(p_t1)
		st.set_normal(n0)
		st.add_vertex(p_t0)
		st.set_normal(Vector3(0, 1, 0))
		st.add_vertex(Vector3(0, hy, 0))
		st.add_vertex(p_t0)
		st.add_vertex(p_t1)
		st.set_normal(Vector3(0, -1, 0))
		st.add_vertex(Vector3(0, -hy, 0))
		st.add_vertex(p_b1)
		st.add_vertex(p_b0)
	return st.commit()

static func _create_ring_mesh(inner_r: float, outer_r: float, height: float = 0.04, seg: int = 32) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hy: float = height * 0.5
	for i in range(seg):
		var a0: float = float(i) / float(seg) * TAU
		var a1: float = float(i + 1) / float(seg) * TAU
		var c0: float = cos(a0)
		var s0: float = sin(a0)
		var c1: float = cos(a1)
		var s1: float = sin(a1)
		var p_in0 = Vector3(c0 * inner_r, hy, s0 * inner_r)
		var p_out0 = Vector3(c0 * outer_r, hy, s0 * outer_r)
		var p_in1 = Vector3(c1 * inner_r, hy, s1 * inner_r)
		var p_out1 = Vector3(c1 * outer_r, hy, s1 * outer_r)
		st.set_normal(Vector3(0, 1, 0))
		st.add_vertex(p_in0)
		st.add_vertex(p_out0)
		st.add_vertex(p_out1)
		st.add_vertex(p_in0)
		st.add_vertex(p_out1)
		st.add_vertex(p_in1)
	return st.commit()
