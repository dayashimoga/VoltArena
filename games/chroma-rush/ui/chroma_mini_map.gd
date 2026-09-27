class_name ChromaMiniMap
extends PanelContainer

## Live HUD Minimap for Chroma Rush
## Authoritative radar widget rendering the road spline network, player heading arrow,
## moving traffic/rivals with their respective colors, and the active objective checkpoint/target.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")

signal map_expand_requested()

var waypoints: Array[Vector3] = []
var player_pos: Vector3 = Vector3.ZERO
var player_heading: float = 0.0 # Radians
var traffic_markers: Array[Dictionary] = [] # [{pos: Vector3, color: int, is_rival: bool}]
var target_pos: Vector3 = Vector3.ZERO
var target_color: int = ChromaConstants.ChromaColor.NONE
var has_target: bool = false

var radar_range: float = 120.0 # Meters visible from center
var map_canvas: Control
var expand_btn: Button

func _init() -> void:
	custom_minimum_size = Vector2(170, 170)

func _ready() -> void:
	# Glassmorphism dark radar container style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	style.border_color = Color(0.15, 0.65, 0.95, 0.70)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	map_canvas = Control.new()
	map_canvas.custom_minimum_size = Vector2(158, 158)
	map_canvas.draw.connect(_on_canvas_draw)
	map_canvas.gui_input.connect(_on_canvas_input)
	margin.add_child(map_canvas)

	# Expand Map Button overlay in top-right
	expand_btn = Button.new()
	expand_btn.text = "⛶"
	expand_btn.tooltip_text = "Expand Full Map (M)"
	expand_btn.custom_minimum_size = Vector2(24, 24)
	expand_btn.anchor_left = 1.0
	expand_btn.anchor_right = 1.0
	expand_btn.offset_left = -30
	expand_btn.offset_top = 4
	expand_btn.offset_right = -4
	expand_btn.offset_bottom = 28
	expand_btn.pressed.connect(func(): map_expand_requested.emit())
	add_child(expand_btn)

func set_world_data(road_waypoints: Array[Vector3]) -> void:
	waypoints = road_waypoints
	if is_instance_valid(map_canvas):
		map_canvas.queue_redraw()

func update_radar(p_pos: Vector3, p_rot_y: float, vehicles: Array[Dictionary], tgt_pos: Vector3, tgt_col: int, tgt_active: bool) -> void:
	player_pos = p_pos
	player_heading = p_rot_y
	traffic_markers = vehicles
	target_pos = tgt_pos
	target_color = tgt_col
	has_target = tgt_active

	if is_instance_valid(map_canvas):
		map_canvas.queue_redraw()

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		map_expand_requested.emit()

func _world_to_minimap(w_pos: Vector3, center_pt: Vector2, scale_factor: float) -> Vector2:
	# Local offset relative to player
	var diff = w_pos - player_pos
	# Rotate into player's forward view so Up is always player's direction
	var cos_a = cos(-player_heading)
	var sin_a = sin(-player_heading)
	var rx = diff.x * cos_a - diff.z * sin_a
	var ry = diff.x * sin_a + diff.z * cos_a
	return center_pt + Vector2(rx, ry) * scale_factor

func _on_canvas_draw() -> void:
	if not is_instance_valid(map_canvas):
		return
	var size = map_canvas.size
	var center = size * 0.5
	var radius = minf(size.x, size.y) * 0.48
	var scale_factor = radius / radar_range

	# Draw radar circular grid rings
	map_canvas.draw_circle(center, radius, Color(0.04, 0.08, 0.15, 0.5))
	map_canvas.draw_arc(center, radius * 0.5, 0, TAU, 32, Color(0.2, 0.4, 0.6, 0.25), 1.0)
	map_canvas.draw_arc(center, radius, 0, TAU, 32, Color(0.3, 0.6, 0.9, 0.40), 1.5)

	# Crosshair lines
	map_canvas.draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), Color(0.2, 0.4, 0.6, 0.2), 1.0)
	map_canvas.draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), Color(0.2, 0.4, 0.6, 0.2), 1.0)

	# Draw Authoritative Road Spline Lines
	if waypoints.size() > 1:
		for i in range(waypoints.size()):
			var p1 = waypoints[i]
			var p2 = waypoints[(i + 1) % waypoints.size()]
			var m1 = _world_to_minimap(p1, center, scale_factor)
			var m2 = _world_to_minimap(p2, center, scale_factor)

			# Check if either point is within radar bounds
			if m1.distance_to(center) <= radius * 1.4 or m2.distance_to(center) <= radius * 1.4:
				# Road base line
				map_canvas.draw_line(m1, m2, Color(0.25, 0.32, 0.42, 0.85), 4.5)
				# Road center line
				map_canvas.draw_line(m1, m2, Color(0.45, 0.55, 0.70, 0.9), 1.5)

	# Draw Objective Checkpoint / Target Beacon if active
	if has_target:
		var tgt_m = _world_to_minimap(target_pos, center, scale_factor)
		var dist_to_tgt = tgt_m.distance_to(center)
		# Clamp to border if outside radar range
		if dist_to_tgt > radius - 6.0:
			tgt_m = center + (tgt_m - center).normalized() * (radius - 6.0)

		var t_col = ChromaConstants.get_color_value(target_color) if target_color != ChromaConstants.ChromaColor.NONE else Color(1.0, 0.85, 0.1)
		# Pulsing beacon ring
		map_canvas.draw_circle(tgt_m, 6.0, t_col)
		map_canvas.draw_arc(tgt_m, 9.0, 0, TAU, 16, Color(1, 1, 1, 0.8), 1.5)
		# Symbol badge
		var symbol_str = ChromaConstants.get_color_symbol(target_color) if target_color != ChromaConstants.ChromaColor.NONE else "★"
		map_canvas.draw_string(ThemeDB.fallback_font, tgt_m + Vector2(-4, 4), symbol_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

	# Draw Moving Vehicles (Traffic & Rivals)
	for v in traffic_markers:
		var v_pos = v.get("pos", Vector3.ZERO)
		var v_col_id = v.get("color", ChromaConstants.ChromaColor.NONE)
		var is_rival = v.get("is_rival", false)
		var vm = _world_to_minimap(v_pos, center, scale_factor)

		if vm.distance_to(center) <= radius:
			var dot_color = ChromaConstants.get_color_value(v_col_id) if v_col_id != ChromaConstants.ChromaColor.NONE else Color(0.8, 0.8, 0.8)
			if is_rival:
				# Diamond marker for rivals
				var d_size = 5.0
				var pts = PackedVector2Array([
					vm + Vector2(0, -d_size),
					vm + Vector2(d_size, 0),
					vm + Vector2(0, d_size),
					vm + Vector2(-d_size, 0)
				])
				map_canvas.draw_colored_polygon(pts, Color.RED)
				map_canvas.draw_polyline(pts, dot_color, 1.5)
			else:
				# Circle dot for traffic
				map_canvas.draw_circle(vm, 4.0, dot_color)
				map_canvas.draw_arc(vm, 4.0, 0, TAU, 12, Color.WHITE, 1.0)

	# Draw Player Arrow at Center (always pointing UP in relative view)
	var p_pts = PackedVector2Array([
		center + Vector2(0, -7.0),   # Front tip
		center + Vector2(5.5, 6.0),  # Right rear
		center + Vector2(0, 3.5),    # Inset notch
		center + Vector2(-5.5, 6.0)  # Left rear
	])
	map_canvas.draw_colored_polygon(p_pts, Color(0.0, 1.0, 0.85))
	map_canvas.draw_polyline(p_pts, Color.WHITE, 1.2)
