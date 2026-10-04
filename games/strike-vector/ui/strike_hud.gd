class_name StrikeHUD
extends Control

## Cyberpunk Tactical HUD for Strike Vector.
## Features:
## - Top-center Compass Tape with degree ticks, cardinal points, and objective waypoint bearing/distance.
## - Top-center Tactical Directive Banner with dynamic turn guidance and context instructions.
## - Top-right Circular 2D Minimap/Radar with full multi-street city topology, view cone, road bounds,
##   objective beacon, and threat-aware hostile blips.
## - Tactical Operations Map Modal (toggleable via 'M' key or controller) showing full 2D level topology,
##   district sectors, mission progression chain, POIs, and legend.
## - Dynamic Crosshair with spread expansion and hit indicators.
## - Bottom-left HP / Armor status gauges.
## - Bottom-right 6-slot Weapon Arsenal Rack, Fire-mode, Ammo reserve, and Grenade counters.
## - Contextual alerts, interaction prompts, and Boss health bar.

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

# HUD Subsystems
var compass_tape: StrikeCompassTape
var minimap: StrikeMinimap
var tactical_map: StrikeTacticalMap
var crosshair: StrikeCrosshair
var damage_indicator: StrikeDirectionalDamageIndicator

# Bottom-left Status
var health_bar: ProgressBar
var health_label: Label
var armor_bar: ProgressBar
var armor_label: Label

# Bottom-right Weapon
var weapon_name_label: Label
var fire_mode_label: Label
var ammo_label: Label
var grenade_label: Label
var module_badge: PanelContainer
var module_label: Label
var weapon_slots_container: HBoxContainer
var weapon_slot_labels: Array[Label] = []

# Top-center Objective & Directive
var objective_badge: PanelContainer
var objective_label: Label
var objective_dist_label: Label
var directive_label: Label

# Context Alerts
var alert_label: Label
var interact_label: Label

# Boss Bar
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_health_bar: ProgressBar
var boss_phase_label: Label

# Navigation Tracking State
var active_objective_pos: Vector3 = Vector3(0, 0, -160.0)
var active_objective_name: String = "DESTROY JAMMER"
var extraction_pos: Vector3 = Vector3(0, 0, -200.0)
var has_extraction: bool = false
var current_weapon_slot: int = 0

# ==============================================================================
# SUBCOMPONENT 1: DYNAMIC CROSSHAIR
# ==============================================================================
class StrikeCrosshair extends Control:
	var spread: float = 6.0
	var hit_indicator_timer: float = 0.0

	func trigger_hit() -> void:
		hit_indicator_timer = 0.15
		queue_redraw()

	func _process(delta: float) -> void:
		if hit_indicator_timer > 0.0:
			hit_indicator_timer -= delta
			queue_redraw()

	func _draw() -> void:
		var col = Color(0.1, 0.95, 1.0, 0.85)
		var s = spread
		var l = 7.0
		# Reticle crosshair ticks
		draw_line(Vector2(-s - l, 0), Vector2(-s, 0), col, 2.0)
		draw_line(Vector2(s, 0), Vector2(s + l, 0), col, 2.0)
		draw_line(Vector2(0, -s - l), Vector2(0, -s), col, 2.0)
		draw_line(Vector2(0, s), Vector2(0, s + l), col, 2.0)
		draw_circle(Vector2.ZERO, 1.5, col)

		# Hit-confirmation 'X' ticks
		if hit_indicator_timer > 0.0:
			var hit_col = Color(1.0, 0.2, 0.2, 0.9)
			var h_s = 4.0
			var h_l = 8.0
			draw_line(Vector2(-h_l, -h_l), Vector2(-h_s, -h_s), hit_col, 2.0)
			draw_line(Vector2(h_l, -h_l), Vector2(h_s, -h_s), hit_col, 2.0)
			draw_line(Vector2(-h_l, h_l), Vector2(-h_s, h_s), hit_col, 2.0)
			draw_line(Vector2(h_l, h_l), Vector2(h_s, h_s), hit_col, 2.0)

# ==============================================================================
# SUBCOMPONENT 2: DIRECTIONAL DAMAGE INDICATOR
# ==============================================================================
class StrikeDirectionalDamageIndicator extends Control:
	var active_indicators: Array = []

	func add_hit(angle_rad: float) -> void:
		active_indicators.append({
			"angle": angle_rad,
			"alpha": 1.0
		})
		queue_redraw()

	func _process(delta: float) -> void:
		if active_indicators.is_empty():
			return
		var redraw_needed = false
		for ind in active_indicators:
			ind["alpha"] -= delta * 1.8
			redraw_needed = true
		var expired = []
		for ind in active_indicators:
			if ind["alpha"] <= 0.0:
				redraw_needed = true
				expired.append(ind)
		for exp_ind in expired:
			active_indicators.erase(exp_ind)
		if redraw_needed:
			queue_redraw()

	func _draw() -> void:
		var center = size * 0.5
		var radius = minf(size.x, size.y) * 0.32
		for ind in active_indicators:
			var ang = ind["angle"]
			var col = Color(1.0, 0.1, 0.1, ind["alpha"] * 0.85)
			var tip = center + Vector2(cos(ang), sin(ang)) * radius
			var left_pt = center + Vector2(cos(ang - 0.25), sin(ang - 0.25)) * (radius - 22.0)
			var right_pt = center + Vector2(cos(ang + 0.25), sin(ang + 0.25)) * (radius - 22.0)
			draw_colored_polygon(PackedVector2Array([tip, left_pt, right_pt]), col)

# ==============================================================================
# SUBCOMPONENT 3: COMPASS TAPE (TOP-CENTER)
# ==============================================================================
class StrikeCompassTape extends Control:
	var current_heading: float = 0.0 # 0-360 degrees
	var target_bearing: float = 0.0
	var has_target: bool = false
	var span_deg: float = 90.0

	func _draw() -> void:
		var w = size.x
		var h = size.y
		var center_x = w * 0.5

		# Dark metallic background
		draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.06, 0.12, 0.85), true)
		draw_rect(Rect2(0, 0, w, h), Color(0.15, 0.70, 0.95, 0.65), false, 1.5)

		var font = get_theme_default_font()
		var start_deg = int(floor(current_heading - span_deg * 0.5))
		var end_deg = int(ceil(current_heading + span_deg * 0.5))

		for d in range(start_deg, end_deg + 1, 15):
			var norm_d = fposmod(float(d), 360.0)
			var rel = norm_d - current_heading
			if rel > 180.0: rel -= 360.0
			elif rel < -180.0: rel += 360.0

			if abs(rel) > span_deg * 0.5:
				continue

			var x = center_x + (rel / (span_deg * 0.5)) * (w * 0.46)
			var tick_h = 5.0
			var card_str = ""

			if int(round(norm_d)) % 90 == 0:
				tick_h = 9.0
				match int(round(norm_d)):
					0: card_str = "N"
					90: card_str = "E"
					180: card_str = "S"
					270: card_str = "W"
			elif int(round(norm_d)) % 45 == 0:
				tick_h = 7.0
				match int(round(norm_d)):
					45: card_str = "NE"
					135: card_str = "SE"
					225: card_str = "SW"
					315: card_str = "NW"

			var is_card = card_str != ""
			var col = Color(0.2, 0.9, 1.0, 0.9) if is_card else Color(0.4, 0.6, 0.8, 0.4)
			draw_line(Vector2(x, h - tick_h), Vector2(x, h), col, 1.5 if is_card else 1.0)

			if font and is_card:
				draw_string(font, Vector2(x - 8, h - tick_h - 2), card_str, HORIZONTAL_ALIGNMENT_CENTER, 16, 9, col)

		# Active Objective Waypoint Diamond Marker
		if has_target:
			var rel_target = target_bearing - current_heading
			if rel_target > 180.0: rel_target -= 360.0
			elif rel_target < -180.0: rel_target += 360.0

			var clamped_rel = clampf(rel_target, -span_deg * 0.48, span_deg * 0.48)
			var tx = center_x + (clamped_rel / (span_deg * 0.5)) * (w * 0.46)
			var obj_col = Color(1.0, 0.78, 0.15, 0.95)

			var d_pts = PackedVector2Array([
				Vector2(tx, 3),
				Vector2(tx + 4, 8),
				Vector2(tx, 13),
				Vector2(tx - 4, 8)
			])
			draw_colored_polygon(d_pts, obj_col)

# ==============================================================================
# SUBCOMPONENT 4: 2D METROPOLITAN MINIMAP / RADAR (TOP-RIGHT)
# ==============================================================================
class StrikeMinimap extends Control:
	var player_pos: Vector3 = Vector3.ZERO
	var player_yaw: float = 0.0 # radians
	var target_pos: Vector3 = Vector3(0, 0, -160.0)
	var extraction_pos: Vector3 = Vector3(0, 0, -200.0)
	var has_extraction: bool = false
	var radar_range: float = 75.0

	var hostile_blips: Array[Dictionary] = []
	var sweep_angle: float = 0.0

	func _process(delta: float) -> void:
		sweep_angle = fposmod(sweep_angle + delta * 2.2, TAU)
		queue_redraw()

	func _draw() -> void:
		var center = size * 0.5
		var radius = minf(size.x, size.y) * 0.48

		# Dark circular radar frame
		draw_circle(center, radius, Color(0.02, 0.05, 0.10, 0.90))
		draw_arc(center, radius, 0, TAU, 48, Color(0.15, 0.80, 1.0, 0.75), 2.0)

		# Range Rings (25m & 50m)
		draw_arc(center, radius * (25.0 / radar_range), 0, TAU, 32, Color(0.15, 0.45, 0.65, 0.35), 1.0)
		draw_arc(center, radius * (50.0 / radar_range), 0, TAU, 32, Color(0.15, 0.45, 0.65, 0.35), 1.0)

		# Crosshairs
		draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), Color(0.15, 0.45, 0.65, 0.25), 1.0)
		draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), Color(0.15, 0.45, 0.65, 0.25), 1.0)

		# 2D Multi-Street City Layout on Minimap
		_draw_city_streets(center, radius)

		# Radar rotating sweep
		var sweep_dir = Vector2(cos(sweep_angle), sin(sweep_angle)) * radius
		draw_line(center, center + sweep_dir, Color(0.2, 0.9, 1.0, 0.30), 1.5)

		# Hostile Blips
		var now = Time.get_ticks_msec() / 1000.0
		var active_blips: Array[Dictionary] = []
		for blip in hostile_blips:
			var age = now - blip["time"]
			if age < 3.0:
				active_blips.append(blip)
				var alpha = clampf(1.0 - (age / 3.0), 0.0, 1.0)
				var rel_3d = blip["pos"] - player_pos
				var rot_x = rel_3d.x * cos(-player_yaw) - rel_3d.z * sin(-player_yaw)
				var rot_z = rel_3d.x * sin(-player_yaw) + rel_3d.z * cos(-player_yaw)
				var b_pos = center + Vector2(rot_x, rot_z) * (radius / radar_range)

				if b_pos.distance_to(center) <= radius - 4.0:
					draw_circle(b_pos, 3.2, Color(1.0, 0.2, 0.2, alpha * 0.95))
					draw_arc(b_pos, 5.0, 0, TAU, 12, Color(1.0, 0.4, 0.3, alpha * 0.5), 1.0)
		hostile_blips = active_blips

		# Objective Waypoint Marker
		var obj_rel = target_pos - player_pos
		var obj_rot_x = obj_rel.x * cos(-player_yaw) - obj_rel.z * sin(-player_yaw)
		var obj_rot_z = obj_rel.x * sin(-player_yaw) + obj_rel.z * cos(-player_yaw)
		var obj_vec = Vector2(obj_rot_x, obj_rot_z)
		var obj_dist = obj_vec.length()

		var obj_screen: Vector2
		if obj_dist <= radar_range:
			obj_screen = center + obj_vec * (radius / radar_range)
		else:
			obj_screen = center + obj_vec.normalized() * (radius - 8.0)

		var d_pts = PackedVector2Array([
			obj_screen + Vector2(0, -6),
			obj_screen + Vector2(6, 0),
			obj_screen + Vector2(0, 6),
			obj_screen + Vector2(-6, 0)
		])
		draw_colored_polygon(d_pts, Color(1.0, 0.78, 0.15, 0.95))
		draw_arc(obj_screen, 8.0, 0, TAU, 16, Color(1.0, 0.85, 0.2, 0.65), 1.2)

		# Extraction LZ Marker
		if has_extraction:
			var ext_rel = extraction_pos - player_pos
			var ext_rot_x = ext_rel.x * cos(-player_yaw) - ext_rel.z * sin(-player_yaw)
			var ext_rot_z = ext_rel.x * sin(-player_yaw) + ext_rel.z * cos(-player_yaw)
			var ext_vec = Vector2(ext_rot_x, ext_rot_z)
			var ext_screen = center + ext_vec.normalized() * minf(radius - 8.0, ext_vec.length() * (radius / radar_range))
			draw_circle(ext_screen, 5.0, Color(0.1, 0.95, 0.5, 0.95))
			draw_arc(ext_screen, 8.0, 0, TAU, 16, Color(0.1, 0.95, 0.5, 0.75), 1.5)

		# Player Vision Cone (60 degrees forward)
		var cone_len = radius * 0.45
		var cone_col = Color(0.1, 0.95, 1.0, 0.08)
		var cone_pts = PackedVector2Array([
			center,
			center + Vector2(-cone_len * 0.5, -cone_len),
			center + Vector2(cone_len * 0.5, -cone_len)
		])
		draw_colored_polygon(cone_pts, cone_col)

		# Player Indicator: Cyan chevron pointing UP
		var chevron = PackedVector2Array([
			center + Vector2(0, -8),
			center + Vector2(6, 6),
			center + Vector2(0, 3),
			center + Vector2(-6, 6)
		])
		draw_colored_polygon(chevron, Color(0.1, 0.95, 1.0, 1.0))
		draw_circle(center, 1.5, Color.WHITE)

	func _draw_city_streets(center: Vector2, radius: float) -> void:
		# Draw continuous arterial boulevard and cross streets relative to player
		var road_w = 16.0
		var r_scale = radius / radar_range
		var col_road = Color(0.2, 0.65, 0.9, 0.35)
		var col_curb = Color(0.3, 0.8, 1.0, 0.6)

		# Arterial Boulevard curbs (-8m and +8m from X=0 in world space)
		for side in [-8.0, 8.0]:
			var p1_w = Vector3(side, 0, player_pos.z - radar_range)
			var p2_w = Vector3(side, 0, player_pos.z + radar_range)
			var s1 = _world_to_minimap(p1_w, center, r_scale)
			var s2 = _world_to_minimap(p2_w, center, r_scale)
			draw_line(s1, s2, col_curb, 1.2)

		# Cross-street intersections at z = 0, -40, -80, -120, -160, -200
		var cross_zs = [0.0, -40.0, -80.0, -120.0, -160.0, -200.0]
		for cz in cross_zs:
			if abs(cz - player_pos.z) < radar_range:
				var c_left = _world_to_minimap(Vector3(-24.0, 0, cz), center, r_scale)
				var c_right = _world_to_minimap(Vector3(24.0, 0, cz), center, r_scale)
				draw_line(c_left, c_right, col_road, 2.0)

	func _world_to_minimap(world_pos: Vector3, center: Vector2, r_scale: float) -> Vector2:
		var rel_3d = world_pos - player_pos
		var rot_x = rel_3d.x * cos(-player_yaw) - rel_3d.z * sin(-player_yaw)
		var rot_z = rel_3d.x * sin(-player_yaw) + rel_3d.z * cos(-player_yaw)
		return center + Vector2(rot_x, rot_z) * r_scale

# ==============================================================================
# SUBCOMPONENT 5: FULL-SCREEN TACTICAL OPERATIONS MAP ('M' KEY OVERLAY)
# ==============================================================================
class StrikeTacticalMap extends PanelContainer:
	var player_z: float = 0.0
	var player_x: float = 0.0
	var target_z: float = -160.0
	var max_mission_z: float = -200.0

	var sectors = [
		{"name": "SECTOR 1: CITY CENTRE & ENTRY PLAZA", "z": 0.0, "type": "entry"},
		{"name": "SECTOR 2: COMMERCIAL DISTRICT & 4-WAY INTERSECTION", "z": -40.0, "type": "checkpoint"},
		{"name": "SECTOR 3: METRO STATION & CENTRAL PARK PROMENADE", "z": -80.0, "type": "metro"},
		{"name": "SECTOR 4: INDUSTRIAL LOGISTICS & WAREHOUSES", "z": -120.0, "type": "industrial"},
		{"name": "SECTOR 5: ROOFTOP EXTRACTION HELIPAD LZ", "z": -160.0, "type": "extraction"}
	]

	func _init() -> void:
		visible = false
		anchor_left = 0.5
		anchor_top = 0.5
		anchor_right = 0.5
		anchor_bottom = 0.5
		offset_left = -380
		offset_top = -250
		offset_right = 380
		offset_bottom = 250

	func _draw() -> void:
		var w = size.x
		var h = size.y

		# Tactical Blueprint Panel Background
		draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.06, 0.12, 0.96), true)
		draw_rect(Rect2(0, 0, w, h), Color(0.15, 0.80, 1.0, 0.85), false, 2.0)

		# Tactical Coordinate Grid lines
		var grid_col = Color(0.15, 0.45, 0.70, 0.18)
		for gx in range(40, int(w), 50):
			draw_line(Vector2(float(gx), 40), Vector2(float(gx), h - 35), grid_col, 1.0)
		for gy in range(50, int(h) - 30, 45):
			draw_line(Vector2(20, float(gy)), Vector2(w - 20, float(gy)), grid_col, 1.0)

		var font = get_theme_default_font()
		if font:
			# Header
			draw_string(font, Vector2(24, 28), "TACTICAL OPERATIONS MAP // SECTOR METROPOLITAN GRID", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.2, 0.95, 1.0))
			draw_string(font, Vector2(w - 240, 28), "SATELLITE UPLINK: ACTIVE", HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.2, 1.0, 0.4))
			# Footer
			draw_string(font, Vector2(24, h - 14), "[M / ESC] CLOSE TACTICAL UPLINK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.75, 0.9))

		# 2D Road Network Layout (Arterial Boulevard along center-left)
		var road_cx = 240.0
		var map_top_y = 65.0
		var map_bottom_y = h - 55.0
		var road_h = map_bottom_y - map_top_y

		# Boulevard Main Road (dual lane)
		draw_rect(Rect2(road_cx - 24, map_top_y, 48, road_h), Color(0.08, 0.16, 0.26, 0.8), true)
		draw_rect(Rect2(road_cx - 24, map_top_y, 48, road_h), Color(0.2, 0.7, 0.95, 0.6), false, 1.5)
		# Dividing center dashed line
		for ly in range(int(map_top_y), int(map_bottom_y), 16):
			draw_line(Vector2(road_cx, float(ly)), Vector2(road_cx, float(ly + 8)), Color(1.0, 0.8, 0.2, 0.6), 1.5)

		# Cross-streets branching into districts
		for i in range(sectors.size()):
			var s = sectors[i]
			var ratio = float(i) / float(sectors.size() - 1)
			var sy = map_top_y + ratio * road_h

			# Branching cross-streets left & right
			draw_line(Vector2(road_cx - 95, sy), Vector2(road_cx + 95, sy), Color(0.2, 0.7, 0.95, 0.45), 2.5)

			# Sector Node Indicator
			var is_cleared = player_z <= s["z"]
			var is_target = abs(s["z"] - target_z) < 20.0
			var node_col = Color(0.2, 1.0, 0.4) if is_cleared else (Color(1.0, 0.75, 0.2) if is_target else Color(0.4, 0.6, 0.7, 0.6))

			draw_circle(Vector2(road_cx, sy), 6.5, node_col)
			draw_arc(Vector2(road_cx, sy), 9.5, 0, TAU, 16, node_col, 1.2)

			# Sector Label & Status on right side
			if font:
				var tag = "[SECURED]" if is_cleared else ("[PRIMARY OBJECTIVE]" if is_target else "[EN ROUTE]")
				var label_text = s["name"] + "  " + tag
				draw_string(font, Vector2(road_cx + 115, sy + 4), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, node_col)

		# Operative Live Position Indicator
		var p_ratio = clampf(player_z / max_mission_z, 0.0, 1.0)
		var py = map_top_y + p_ratio * road_h
		var p_marker = PackedVector2Array([
			Vector2(road_cx - 16, py - 6),
			Vector2(road_cx - 6, py),
			Vector2(road_cx - 16, py + 6)
		])
		draw_colored_polygon(p_marker, Color(0.1, 0.95, 1.0, 1.0))
		draw_circle(Vector2(road_cx, py), 3.5, Color(0.1, 0.95, 1.0))
		draw_arc(Vector2(road_cx, py), 12.0, 0, TAU, 16, Color(0.1, 0.95, 1.0, 0.5), 1.0)

		if font:
			draw_string(font, Vector2(road_cx - 140, py + 4), "OPERATIVE [LOC: Z=%.0fm]" % player_z, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(0.1, 0.95, 1.0))

		# Tactical Map Legend in Bottom-Right
		if font:
			var leg_x = w - 310
			var leg_y = h - 65
			draw_rect(Rect2(leg_x - 10, leg_y - 18, 300, 48), Color(0.04, 0.08, 0.14, 0.85), true)
			draw_rect(Rect2(leg_x - 10, leg_y - 18, 300, 48), Color(0.2, 0.6, 0.8, 0.4), false, 1.0)
			draw_string(font, Vector2(leg_x, leg_y), "LEGEND: [GREEN] SECURED  [AMBER] OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.85, 0.95))
			draw_string(font, Vector2(leg_x, leg_y + 16), "        [CYAN] OPERATIVE  [BLUE] EN ROUTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.85, 0.95))

# ==============================================================================
# MAIN HUD SETUP
# ==============================================================================
func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGen.get_theme()
	setup_hud()

func setup_hud() -> void:
	_setup_damage_indicator()
	_setup_crosshair()
	_setup_compass_tape()
	_setup_minimap()
	_setup_tactical_map()
	_setup_bottom_left_status()
	_setup_bottom_right_weapon()
	_setup_context_alert()
	_setup_boss_health_bar()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_tactical_map()

func toggle_tactical_map() -> void:
	if is_instance_valid(tactical_map):
		tactical_map.visible = not tactical_map.visible
		tactical_map.queue_redraw()

func _setup_crosshair() -> void:
	crosshair = StrikeCrosshair.new()
	crosshair.name = "Crosshair"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(crosshair)

func _setup_compass_tape() -> void:
	compass_tape = StrikeCompassTape.new()
	compass_tape.name = "CompassTape"
	compass_tape.anchor_left = 0.5
	compass_tape.anchor_top = 0.0
	compass_tape.anchor_right = 0.5
	compass_tape.anchor_bottom = 0.0
	compass_tape.offset_left = -160
	compass_tape.offset_top = 10
	compass_tape.offset_right = 160
	compass_tape.offset_bottom = 42
	compass_tape.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(compass_tape)

	# Objective Badge immediately below compass tape
	objective_badge = PanelContainer.new()
	objective_badge.anchor_left = 0.5
	objective_badge.anchor_top = 0.0
	objective_badge.anchor_right = 0.5
	objective_badge.anchor_bottom = 0.0
	objective_badge.offset_left = -260
	objective_badge.offset_top = 46
	objective_badge.offset_right = 260
	objective_badge.offset_bottom = 96
	objective_badge.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(objective_badge)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	objective_badge.add_child(vbox)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	objective_label = Label.new()
	objective_label.text = "OBJECTIVE: INFILTRATE COMMERCIAL SECTOR"
	objective_label.size_flags_horizontal = SIZE_EXPAND_FILL
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.modulate = Color(0.2, 0.95, 1.0)
	hbox.add_child(objective_label)

	objective_dist_label = Label.new()
	objective_dist_label.text = "160m"
	objective_dist_label.modulate = Color(1.0, 0.78, 0.2)
	hbox.add_child(objective_dist_label)

	directive_label = Label.new()
	directive_label.text = "[^] PROCEED DOWN ARTERIAL BOULEVARD"
	directive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	directive_label.add_theme_font_size_override("font_size", 11)
	directive_label.modulate = Color(0.7, 0.85, 1.0)
	vbox.add_child(directive_label)

func _setup_minimap() -> void:
	minimap = StrikeMinimap.new()
	minimap.name = "Minimap"
	minimap.anchor_left = 1.0
	minimap.anchor_top = 0.0
	minimap.anchor_right = 1.0
	minimap.anchor_bottom = 0.0
	minimap.offset_left = -175
	minimap.offset_top = 15
	minimap.offset_right = -15
	minimap.offset_bottom = 175
	minimap.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(minimap)

func _setup_tactical_map() -> void:
	tactical_map = StrikeTacticalMap.new()
	tactical_map.name = "TacticalMap"
	add_child(tactical_map)

func _setup_bottom_left_status() -> void:
	var panel = PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24
	panel.offset_top = -100
	panel.offset_right = 230
	panel.offset_bottom = -20
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Health row
	var h_box = HBoxContainer.new()
	vbox.add_child(h_box)
	var h_title = Label.new()
	h_title.text = "HP"
	h_title.modulate = Color(0.2, 1.0, 0.4)
	h_title.custom_minimum_size = Vector2(30, 0)
	h_box.add_child(h_title)

	health_bar = ProgressBar.new()
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.custom_minimum_size = Vector2(110, 12)
	health_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	health_bar.show_percentage = false
	h_box.add_child(health_bar)

	health_label = Label.new()
	health_label.text = "100"
	health_label.modulate = Color(0.2, 1.0, 0.4)
	h_box.add_child(health_label)

	# Armor row
	var a_box = HBoxContainer.new()
	vbox.add_child(a_box)
	var a_title = Label.new()
	a_title.text = "SHD"
	a_title.modulate = Color(0.1, 0.8, 1.0)
	a_title.custom_minimum_size = Vector2(30, 0)
	a_box.add_child(a_title)

	armor_bar = ProgressBar.new()
	armor_bar.max_value = 100.0
	armor_bar.value = 50.0
	armor_bar.custom_minimum_size = Vector2(110, 12)
	armor_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	armor_bar.show_percentage = false
	a_box.add_child(armor_bar)

	armor_label = Label.new()
	armor_label.text = "50"
	armor_label.modulate = Color(0.1, 0.8, 1.0)
	a_box.add_child(armor_label)

func _setup_bottom_right_weapon() -> void:
	var panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -280
	panel.offset_top = -125
	panel.offset_right = -20
	panel.offset_bottom = -20
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	# 6-Slot Tactical Weapon Selector Rack
	weapon_slots_container = HBoxContainer.new()
	weapon_slots_container.add_theme_constant_override("separation", 4)
	vbox.add_child(weapon_slots_container)

	var slot_names = ["1:AR", "2:SMG", "3:SG", "4:DMR", "5:LMG", "6:PST"]
	weapon_slot_labels.clear()
	for i in range(slot_names.size()):
		var s_lbl = Label.new()
		s_lbl.text = "[" + slot_names[i] + "]"
		s_lbl.add_theme_font_size_override("font_size", 9)
		s_lbl.modulate = Color(0.1, 0.95, 1.0) if i == 0 else Color(0.4, 0.55, 0.65)
		weapon_slots_container.add_child(s_lbl)
		weapon_slot_labels.append(s_lbl)

	var header_box = HBoxContainer.new()
	vbox.add_child(header_box)

	weapon_name_label = Label.new()
	weapon_name_label.text = "VX-7 ASSAULT RIFLE"
	weapon_name_label.modulate = Color(1.0, 0.85, 0.2)
	weapon_name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	header_box.add_child(weapon_name_label)

	fire_mode_label = Label.new()
	fire_mode_label.text = "[AUTO]"
	fire_mode_label.modulate = Color(0.2, 0.9, 1.0)
	header_box.add_child(fire_mode_label)

	ammo_label = Label.new()
	ammo_label.text = "30 / 150"
	ammo_label.add_theme_font_size_override("font_size", 20)
	ammo_label.modulate = Color(0.1, 0.95, 1.0)
	vbox.add_child(ammo_label)

	var footer_box = HBoxContainer.new()
	vbox.add_child(footer_box)

	grenade_label = Label.new()
	grenade_label.text = "FRAG: 3 [G]"
	grenade_label.modulate = Color(1.0, 0.5, 0.2)
	footer_box.add_child(grenade_label)

	module_badge = PanelContainer.new()
	module_badge.visible = false
	footer_box.add_child(module_badge)
	module_label = Label.new()
	module_label.text = "RAPID FIRE"
	module_label.modulate = Color(1.0, 0.2, 0.9)
	module_badge.add_child(module_label)

func _setup_context_alert() -> void:
	alert_label = Label.new()
	alert_label.anchor_left = 0.5
	alert_label.anchor_top = 0.5
	alert_label.anchor_right = 0.5
	alert_label.anchor_bottom = 0.5
	alert_label.offset_left = -250
	alert_label.offset_top = -120
	alert_label.offset_right = 250
	alert_label.offset_bottom = -80
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_size_override("font_size", 22)
	alert_label.visible = false
	alert_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(alert_label)

	interact_label = Label.new()
	interact_label.anchor_left = 0.5
	interact_label.anchor_top = 0.6
	interact_label.anchor_right = 0.5
	interact_label.anchor_bottom = 0.6
	interact_label.offset_left = -180
	interact_label.offset_top = -20
	interact_label.offset_right = 180
	interact_label.offset_bottom = 20
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interact_label.visible = false
	interact_label.mouse_filter = MOUSE_FILTER_IGNORE
	interact_label.modulate = Color(1.0, 0.9, 0.2)
	add_child(interact_label)

func _setup_boss_health_bar() -> void:
	boss_panel = PanelContainer.new()
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_top = 0.0
	boss_panel.anchor_right = 0.5
	boss_panel.anchor_bottom = 0.0
	boss_panel.offset_left = -240
	boss_panel.offset_top = 80
	boss_panel.offset_right = 240
	boss_panel.offset_bottom = 120
	boss_panel.visible = false
	boss_panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(boss_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	boss_panel.add_child(vbox)

	var h_box = HBoxContainer.new()
	vbox.add_child(h_box)

	boss_name_label = Label.new()
	boss_name_label.text = "BOSS: ASSAULT VTOL"
	boss_name_label.modulate = Color(1.0, 0.3, 0.3)
	boss_name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	h_box.add_child(boss_name_label)

	boss_phase_label = Label.new()
	boss_phase_label.text = "PHASE 1"
	boss_phase_label.modulate = Color(1.0, 0.8, 0.2)
	h_box.add_child(boss_phase_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.max_value = 1000.0
	boss_health_bar.value = 1000.0
	boss_health_bar.custom_minimum_size = Vector2(0, 12)
	boss_health_bar.show_percentage = false
	vbox.add_child(boss_health_bar)

# ==============================================================================
# PUBLIC UPDATE API
# ==============================================================================

func update_navigation_state(p_pos: Vector3, p_heading_rad: float, obj_pos: Vector3, obj_name: String, threat_positions: Array = []) -> void:
	active_objective_pos = obj_pos
	active_objective_name = obj_name

	var p_yaw_deg = fposmod(rad_to_deg(-p_heading_rad), 360.0)

	# Calculate bearing to objective in degrees
	var to_obj = obj_pos - p_pos
	var obj_bearing_deg = fposmod(rad_to_deg(atan2(to_obj.x, -to_obj.z)), 360.0)
	var dist_m = to_obj.length()

	# Update Compass Tape
	if is_instance_valid(compass_tape):
		compass_tape.current_heading = p_yaw_deg
		compass_tape.target_bearing = obj_bearing_deg
		compass_tape.has_target = true
		compass_tape.queue_redraw()

	# Update Objective badge readout & directive
	if is_instance_valid(objective_label):
		objective_label.text = "OBJECTIVE: " + obj_name.to_upper()
	if is_instance_valid(objective_dist_label):
		objective_dist_label.text = "%dm" % int(dist_m)
	if is_instance_valid(directive_label):
		# Context-sensitive directive
		if has_extraction:
			directive_label.text = "[*] BOARD EXTRACTION SHUTTLE // LZ ACTIVE"
			directive_label.modulate = Color(0.1, 1.0, 0.5)
		elif dist_m <= 15.0:
			directive_label.text = "[!] OBJECTIVE PROXIMITY // SECURE POSITION"
			directive_label.modulate = Color(1.0, 0.85, 0.2)
		elif abs(to_obj.x) > 12.0 and to_obj.x > 0:
			directive_label.text = "[>] TURN RIGHT AT INTERSECTION"
			directive_label.modulate = Color(0.2, 0.95, 1.0)
		elif abs(to_obj.x) > 12.0 and to_obj.x < 0:
			directive_label.text = "[<] TURN LEFT AT INTERSECTION"
			directive_label.modulate = Color(0.2, 0.95, 1.0)
		else:
			directive_label.text = "[^] ADVANCE DOWN ARTERIAL BOULEVARD"
			directive_label.modulate = Color(0.7, 0.85, 1.0)

	# Update Minimap
	if is_instance_valid(minimap):
		minimap.player_pos = p_pos
		minimap.player_yaw = p_heading_rad
		minimap.target_pos = obj_pos
		minimap.extraction_pos = extraction_pos
		minimap.has_extraction = has_extraction

		# Threat awareness blips
		var now = Time.get_ticks_msec() / 1000.0
		for t_pos in threat_positions:
			if t_pos is Vector3 and p_pos.distance_to(t_pos) <= minimap.radar_range:
				minimap.hostile_blips.append({"pos": t_pos, "time": now})

		minimap.queue_redraw()

	# Update Tactical Map
	if is_instance_valid(tactical_map):
		tactical_map.player_z = p_pos.z
		tactical_map.player_x = p_pos.x
		tactical_map.target_z = obj_pos.z
		if tactical_map.visible:
			tactical_map.queue_redraw()

func update_health(current: float, max_val: float) -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_val
		health_bar.value = current
	if is_instance_valid(health_label):
		health_label.text = str(int(maxf(0.0, current)))

func update_armor(current: float, max_val: float) -> void:
	if is_instance_valid(armor_bar):
		armor_bar.max_value = max_val
		armor_bar.value = current
	if is_instance_valid(armor_label):
		armor_label.text = str(int(maxf(0.0, current)))

func update_weapon(w_name: String, ammo: int, reserve: int, f_mode: String = "AUTO") -> void:
	if is_instance_valid(weapon_name_label):
		weapon_name_label.text = w_name.to_upper()
	if is_instance_valid(ammo_label):
		ammo_label.text = "%d / %d" % [ammo, reserve]
	if is_instance_valid(fire_mode_label):
		fire_mode_label.text = "[%s]" % f_mode.to_upper()

	# Highlight active weapon slot in rack
	_update_slot_highlight(w_name)

func _update_slot_highlight(w_name: String) -> void:
	var active_slot = 0
	var lower = w_name.to_lower()
	if "smg" in lower or "tempest" in lower: active_slot = 1
	elif "shotgun" in lower or "breach" in lower: active_slot = 2
	elif "marksman" in lower or "longshot" in lower: active_slot = 3
	elif "lmg" in lower or "cyclone" in lower or "pulse cannon" in lower or "arc" in lower: active_slot = 4
	elif "sidearm" in lower or "pistol" in lower: active_slot = 5
	else: active_slot = 0

	current_weapon_slot = active_slot
	for i in range(weapon_slot_labels.size()):
		if i == active_slot:
			weapon_slot_labels[i].modulate = Color(0.1, 0.95, 1.0) # Active Cyan
		else:
			weapon_slot_labels[i].modulate = Color(0.4, 0.55, 0.65) # Inactive

func update_objective(text: String) -> void:
	active_objective_name = text
	if is_instance_valid(objective_label):
		objective_label.text = "OBJECTIVE: " + text.to_upper()

func show_context_alert(message: String, col: Color = Color(0.2, 1.0, 1.0)) -> void:
	if not is_instance_valid(alert_label):
		return
	alert_label.text = message
	alert_label.modulate = col
	alert_label.visible = true

	var tw = create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func(): alert_label.visible = false)

func show_interaction_prompt(prompt: String) -> void:
	if not is_instance_valid(interact_label):
		return
	interact_label.text = prompt
	interact_label.visible = true

func hide_interaction_prompt() -> void:
	if is_instance_valid(interact_label):
		interact_label.visible = false

func show_boss_bar(boss_name: String, max_hp: float, phase: int = 1) -> void:
	if is_instance_valid(boss_panel):
		boss_panel.visible = true
	if is_instance_valid(boss_name_label):
		boss_name_label.text = "BOSS: " + boss_name.to_upper()
	if is_instance_valid(boss_health_bar):
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = max_hp
	if is_instance_valid(boss_phase_label):
		boss_phase_label.text = "PHASE %d" % phase

func update_boss_health(current: float, phase: int) -> void:
	if is_instance_valid(boss_health_bar):
		boss_health_bar.value = current
	if is_instance_valid(boss_phase_label):
		boss_phase_label.text = "PHASE %d" % phase

func hide_boss_bar() -> void:
	if is_instance_valid(boss_panel):
		boss_panel.visible = false

func _setup_damage_indicator() -> void:
	damage_indicator = StrikeDirectionalDamageIndicator.new()
	damage_indicator.name = "DamageIndicator"
	damage_indicator.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	damage_indicator.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(damage_indicator)

func trigger_damage_feedback(attacker_pos: Vector3, player_pos: Vector3, cam_yaw: float) -> void:
	if not is_instance_valid(damage_indicator):
		_setup_damage_indicator()
	if is_instance_valid(damage_indicator):
		var rel = attacker_pos - player_pos
		var forward = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
		var right = Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
		var dot_fwd = rel.dot(forward)
		var dot_right = rel.dot(right)
		var screen_angle = atan2(dot_right, -dot_fwd) - PI * 0.5
		damage_indicator.add_hit(screen_angle)
