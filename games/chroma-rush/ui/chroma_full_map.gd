class_name ChromaFullMap
extends CanvasLayer

## Expandable Complete Tactical Map for Chroma Rush
## Features interactive pan/zoom, authoritative connected road network,
## player position & heading, landmarks, checkpoints, route guidance polyline,
## distance readout, vehicle markers with filters, and comprehensive map legend.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")

signal map_closed()

# Map Transform state
var zoom_level: float = 1.0 # 0.4 to 2.5
var pan_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_offset: Vector2 = Vector2.ZERO

# World Data
var world_name: String = "Neon City"
var waypoints: Array[Vector3] = []
var checkpoints: Array[Dictionary] = [] # [{pos: Vector3, color: int, cleared: bool, id: String}]
var traffic_markers: Array[Dictionary] = [] # [{pos: Vector3, color: int, is_rival: bool, heading: float}]
var player_pos: Vector3 = Vector3.ZERO
var player_heading: float = 0.0
var target_pos: Vector3 = Vector3.ZERO
var target_color: int = ChromaConstants.ChromaColor.NONE
var has_target: bool = false

# Filter toggles
var filter_show_traffic: bool = true
var filter_show_rivals: bool = true
var filter_show_checkpoints: bool = true

# UI Element references
var map_viewport: Control
var distance_label: Label
var title_label: Label

func _ready() -> void:
	layer = 15
	_build_ui()

func _build_ui() -> void:
	var root = Control.new()
	root.name = "FullMapRoot"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	# Dimmed backdrop
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.02, 0.03, 0.06, 0.94)
	root.add_child(bg)

	# Main Map Canvas Area
	map_viewport = Control.new()
	map_viewport.name = "MapViewport"
	map_viewport.anchor_right = 1.0
	map_viewport.anchor_bottom = 1.0
	map_viewport.offset_left = 20
	map_viewport.offset_top = 70
	map_viewport.offset_right = -260 # Leave right flank for Legend & Filters
	map_viewport.offset_bottom = -20
	map_viewport.clip_contents = true
	map_viewport.draw.connect(_on_map_draw)
	map_viewport.gui_input.connect(_on_map_gui_input)
	root.add_child(map_viewport)

	# --- TOP HEADER BAR ---
	var header = PanelContainer.new()
	header.anchor_right = 1.0
	header.offset_bottom = 60
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.06, 0.08, 0.14, 0.95)
	h_style.border_color = Color(0.2, 0.6, 0.9, 0.5)
	h_style.set_border_width_all(1)
	header.add_theme_stylebox_override("panel", h_style)
	root.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.offset_left = 24
	hbox.offset_right = -24
	header.add_child(hbox)

	title_label = Label.new()
	title_label.text = "TACTICAL MAP: " + world_name.to_upper()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.modulate = Color(0.0, 1.0, 0.85)
	hbox.add_child(title_label)

	var h_spacer = Control.new()
	h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(h_spacer)

	distance_label = Label.new()
	distance_label.text = "DISTANCE TO TARGET: --"
	distance_label.add_theme_font_size_override("font_size", 16)
	distance_label.modulate = Color(1.0, 0.85, 0.2)
	hbox.add_child(distance_label)

	var h_spacer2 = Control.new()
	h_spacer2.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(h_spacer2)

	var close_btn = Button.new()
	close_btn.text = "✕ CLOSE (M)"
	close_btn.custom_minimum_size = Vector2(110, 38)
	close_btn.pressed.connect(func(): close_map())
	hbox.add_child(close_btn)

	# --- RIGHT SIDEBAR: LEGEND & CONTROLS ---
	var sidebar = PanelContainer.new()
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -250
	sidebar.offset_top = 70
	sidebar.offset_right = -20
	sidebar.offset_bottom = -20
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.06, 0.09, 0.16, 0.90)
	s_style.border_color = Color(0.2, 0.5, 0.8, 0.4)
	s_style.set_border_width_all(1)
	s_style.set_corner_radius_all(6)
	sidebar.add_theme_stylebox_override("panel", s_style)
	root.add_child(sidebar)

	var s_vbox = VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 12)
	s_vbox.offset_left = 14
	s_vbox.offset_top = 14
	s_vbox.offset_right = -14
	s_vbox.offset_bottom = -14
	sidebar.add_child(s_vbox)

	var zoom_header = Label.new()
	zoom_header.text = "VIEW CONTROLS"
	zoom_header.add_theme_font_size_override("font_size", 14)
	zoom_header.modulate = Color(0.6, 0.8, 1.0)
	s_vbox.add_child(zoom_header)

	var z_hbox = HBoxContainer.new()
	z_hbox.add_theme_constant_override("separation", 8)
	s_vbox.add_child(z_hbox)

	var btn_zin = Button.new()
	btn_zin.text = "ZOOM +"
	btn_zin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_zin.pressed.connect(func(): zoom_map(0.2))
	z_hbox.add_child(btn_zin)

	var btn_zout = Button.new()
	btn_zout.text = "ZOOM -"
	btn_zout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_zout.pressed.connect(func(): zoom_map(-0.2))
	z_hbox.add_child(btn_zout)

	var btn_recenter = Button.new()
	btn_recenter.text = "⊙ RECENTER ON PLAYER"
	btn_recenter.pressed.connect(func(): recenter())
	s_vbox.add_child(btn_recenter)

	var sep1 = HSeparator.new()
	s_vbox.add_child(sep1)

	var filter_hdr = Label.new()
	filter_hdr.text = "MARKER FILTERS"
	filter_hdr.add_theme_font_size_override("font_size", 14)
	filter_hdr.modulate = Color(0.6, 0.8, 1.0)
	s_vbox.add_child(filter_hdr)

	var chk_traffic = CheckBox.new()
	chk_traffic.text = "Show Traffic Vehicles"
	chk_traffic.button_pressed = filter_show_traffic
	chk_traffic.toggled.connect(func(v): filter_show_traffic = v; map_viewport.queue_redraw())
	s_vbox.add_child(chk_traffic)

	var chk_rivals = CheckBox.new()
	chk_rivals.text = "Show Rival Racers"
	chk_rivals.button_pressed = filter_show_rivals
	chk_rivals.toggled.connect(func(v): filter_show_rivals = v; map_viewport.queue_redraw())
	s_vbox.add_child(chk_rivals)

	var chk_gates = CheckBox.new()
	chk_gates.text = "Show Checkpoint Gates"
	chk_gates.button_pressed = filter_show_checkpoints
	chk_gates.toggled.connect(func(v): filter_show_checkpoints = v; map_viewport.queue_redraw())
	s_vbox.add_child(chk_gates)

	var sep2 = HSeparator.new()
	s_vbox.add_child(sep2)

	var leg_hdr = Label.new()
	leg_hdr.text = "MAP LEGEND"
	leg_hdr.add_theme_font_size_override("font_size", 14)
	leg_hdr.modulate = Color(0.6, 0.8, 1.0)
	s_vbox.add_child(leg_hdr)

	_add_legend_item(s_vbox, "▲ Player Vehicle", Color(0.0, 1.0, 0.85))
	_add_legend_item(s_vbox, "★ Objective Target", Color(1.0, 0.85, 0.1))
	_add_legend_item(s_vbox, "◆ Rival Racer", Color.CRIMSON)
	_add_legend_item(s_vbox, "● Traffic Vehicle", Color(0.5, 0.8, 1.0))
	_add_legend_item(s_vbox, "▭ Checkpoint Gate", Color.YELLOW)
	_add_legend_item(s_vbox, "══ Road Network", Color(0.4, 0.5, 0.6))

	var hint_lbl = Label.new()
	hint_lbl.text = "Drag with mouse to pan\nScroll wheel to zoom"
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.modulate = Color(0.5, 0.5, 0.6)
	s_vbox.add_child(hint_lbl)

func _add_legend_item(parent: Control, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = color
	parent.add_child(lbl)

func open_map(w_name: String, road_waypoints: Array[Vector3], gates: Array[Dictionary]) -> void:
	world_name = w_name
	waypoints = road_waypoints
	checkpoints = gates
	visible = true
	if is_instance_valid(title_label):
		title_label.text = "TACTICAL MAP: " + world_name.to_upper()
	recenter()

func close_map() -> void:
	visible = false
	map_closed.emit()

func recenter() -> void:
	pan_offset = -Vector2(player_pos.x, player_pos.z)
	if is_instance_valid(map_viewport):
		map_viewport.queue_redraw()

func zoom_map(delta: float) -> void:
	zoom_level = clampf(zoom_level + delta, 0.4, 2.5)
	if is_instance_valid(map_viewport):
		map_viewport.queue_redraw()

func update_full_map_telemetry(p_pos: Vector3, p_rot_y: float, vehicles: Array[Dictionary], tgt_pos: Vector3, tgt_col: int, tgt_active: bool) -> void:
	player_pos = p_pos
	player_heading = p_rot_y
	traffic_markers = vehicles
	target_pos = tgt_pos
	target_color = tgt_col
	has_target = tgt_active

	if has_target:
		var dist = player_pos.distance_to(target_pos)
		distance_label.text = "DISTANCE TO TARGET: %.0fm" % dist
	else:
		distance_label.text = "FREE DRIVING / NO ACTIVE TARGET"

	if is_instance_valid(map_viewport) and visible:
		map_viewport.queue_redraw()

func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_mouse = event.position
				drag_start_offset = pan_offset
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_map(0.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_map(-0.15)

	elif event is InputEventMouseMotion and is_dragging:
		var delta = event.position - drag_start_mouse
		var world_delta = delta / (1.8 * zoom_level)
		pan_offset = drag_start_offset + Vector2(world_delta.x, world_delta.y)
		map_viewport.queue_redraw()

	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_M):
		close_map()

func _world_to_screen(world_xz: Vector2, center: Vector2) -> Vector2:
	var scale_factor = 1.8 * zoom_level
	var shifted = (world_xz + pan_offset) * scale_factor
	return center + shifted

func _on_map_draw() -> void:
	if not is_instance_valid(map_viewport):
		return
	var size = map_viewport.size
	var center = size * 0.5

	# Grid background lines
	var grid_step = 60.0 * zoom_level
	var grid_col = Color(0.12, 0.16, 0.25, 0.35)
	var x = fmod(pan_offset.x * 1.8 * zoom_level, grid_step)
	while x < size.x:
		map_viewport.draw_line(Vector2(x, 0), Vector2(x, size.y), grid_col, 1.0)
		x += grid_step
	var y = fmod(pan_offset.y * 1.8 * zoom_level, grid_step)
	while y < size.y:
		map_viewport.draw_line(Vector2(0, y), Vector2(size.x, y), grid_col, 1.0)
		y += grid_step

	# 1. Draw Connected Road Spline Network
	if waypoints.size() > 1:
		for i in range(waypoints.size()):
			var p1 = waypoints[i]
			var p2 = waypoints[(i + 1) % waypoints.size()]
			var s1 = _world_to_screen(Vector2(p1.x, p1.z), center)
			var s2 = _world_to_screen(Vector2(p2.x, p2.z), center)

			# Road outer border
			map_viewport.draw_line(s1, s2, Color(0.20, 0.26, 0.35, 0.9), 14.0 * zoom_level)
			# Road asphalt fill
			map_viewport.draw_line(s1, s2, Color(0.12, 0.14, 0.18, 1.0), 10.0 * zoom_level)
			# Centerline
			map_viewport.draw_line(s1, s2, Color(0.9, 0.8, 0.2, 0.7), 2.0 * zoom_level)

	# 2. Draw Route Guidance Polyline if target is active
	if has_target:
		var p_scr = _world_to_screen(Vector2(player_pos.x, player_pos.z), center)
		var t_scr = _world_to_screen(Vector2(target_pos.x, target_pos.z), center)
		# Pulsing cyan dashed guide line
		map_viewport.draw_line(p_scr, t_scr, Color(0.0, 1.0, 0.8, 0.65), 3.0, true)

	# 3. Draw Checkpoint Gates
	if filter_show_checkpoints:
		for gate in checkpoints:
			var g_pos = gate.get("pos", Vector3.ZERO)
			var g_col_id = gate.get("color", ChromaConstants.ChromaColor.NONE)
			var cleared = gate.get("cleared", false)
			var g_scr = _world_to_screen(Vector2(g_pos.x, g_pos.z), center)

			var col = ChromaConstants.get_color_value(g_col_id) if g_col_id != ChromaConstants.ChromaColor.NONE else Color.YELLOW
			if cleared:
				col = Color(0.4, 0.4, 0.4, 0.5)

			var r_size = 12.0 * zoom_level
			var rect = Rect2(g_scr - Vector2(r_size * 0.5, r_size * 0.5), Vector2(r_size, r_size))
			map_viewport.draw_rect(rect, col, false, 2.0)
			if not cleared:
				var sym = ChromaConstants.get_color_symbol(g_col_id)
				map_viewport.draw_string(ThemeDB.fallback_font, g_scr + Vector2(-4, 4), sym, HORIZONTAL_ALIGNMENT_CENTER, -1, int(11 * zoom_level), col)

	# 4. Draw Objective Target Beacon if active
	if has_target:
		var t_scr = _world_to_screen(Vector2(target_pos.x, target_pos.z), center)
		var t_col = ChromaConstants.get_color_value(target_color) if target_color != ChromaConstants.ChromaColor.NONE else Color(1.0, 0.85, 0.1)
		map_viewport.draw_circle(t_scr, 10.0 * zoom_level, t_col)
		map_viewport.draw_arc(t_scr, 15.0 * zoom_level, 0, TAU, 24, Color.WHITE, 2.0)
		map_viewport.draw_string(ThemeDB.fallback_font, t_scr + Vector2(-6, 5), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, int(14 * zoom_level), Color.WHITE)

	# 5. Draw Traffic & Rival Vehicles
	for v in traffic_markers:
		var is_rival = v.get("is_rival", false)
		if is_rival and not filter_show_rivals:
			continue
		if not is_rival and not filter_show_traffic:
			continue

		var v_pos = v.get("pos", Vector3.ZERO)
		var v_col_id = v.get("color", ChromaConstants.ChromaColor.NONE)
		var v_scr = _world_to_screen(Vector2(v_pos.x, v_pos.z), center)
		var dot_col = ChromaConstants.get_color_value(v_col_id) if v_col_id != ChromaConstants.ChromaColor.NONE else Color(0.7, 0.7, 0.7)

		if is_rival:
			var d_size = 7.0 * zoom_level
			var pts = PackedVector2Array([
				v_scr + Vector2(0, -d_size),
				v_scr + Vector2(d_size, 0),
				v_scr + Vector2(0, d_size),
				v_scr + Vector2(-d_size, 0)
			])
			map_viewport.draw_colored_polygon(pts, Color.RED)
			map_viewport.draw_polyline(pts, dot_col, 2.0)
		else:
			map_viewport.draw_circle(v_scr, 5.0 * zoom_level, dot_col)
			map_viewport.draw_arc(v_scr, 5.0 * zoom_level, 0, TAU, 16, Color.WHITE, 1.2)

	# 6. Draw Player Vehicle Marker with Heading Direction
	var p_scr = _world_to_screen(Vector2(player_pos.x, player_pos.z), center)
	var arrow_len = 14.0 * zoom_level
	var forward_vec = Vector2(sin(player_heading), -cos(player_heading))
	var right_vec = Vector2(forward_vec.y, -forward_vec.x)

	var p_pts = PackedVector2Array([
		p_scr + forward_vec * arrow_len,
		p_scr - forward_vec * (arrow_len * 0.7) + right_vec * (arrow_len * 0.6),
		p_scr - forward_vec * (arrow_len * 0.3),
		p_scr - forward_vec * (arrow_len * 0.7) - right_vec * (arrow_len * 0.6)
	])
	map_viewport.draw_colored_polygon(p_pts, Color(0.0, 1.0, 0.85))
	map_viewport.draw_polyline(p_pts, Color.WHITE, 2.0)
