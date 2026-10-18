class_name CockpitHUD
extends Control

## Custom vector-drawn glass cockpit Head-Up Display (HUD).
## Renders unprojected flight-path marker, roll-corrected pitch ladder (5 deg increments),
## KIAS airspeed tape, MSL altitude tape, FPM vertical speed, G-meter, and AoA bracket.

const HUD_GREEN: Color = Color(0.25, 1.0, 0.45, 0.92)
const HUD_WARN: Color = Color(1.0, 0.8, 0.2, 0.95)
const HUD_DANGER: Color = Color(1.0, 0.25, 0.2, 0.98)
const METERS_TO_FEET: float = 3.28084

var aircraft: AircraftController
var camera: Camera3D

# Telemetry Cache
var airspeed_kias: float = 0.0
var altitude_feet_msl: float = 0.0
var vertical_speed_fpm: float = 0.0
var g_force: float = 1.0
var aoa_deg: float = 0.0
var stall_warning: bool = false
var gear_down: bool = true
var flaps_deg: float = 0.0
var brakes_on: bool = false
var heading_deg: float = 0.0
var roll_rad: float = 0.0
var pitch_rad: float = 0.0

var is_crashed: bool = false
var crash_reason: String = ""
var ghost_director_active: bool = false
var ghost_target_pitch_deg: float = 0.0
var ghost_target_roll_deg: float = 0.0

var _font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font

func update_telemetry(data: Dictionary) -> void:
	airspeed_kias = data.get("airspeed_kias", 0.0)
	altitude_feet_msl = data.get("altitude_msl", 0.0) * METERS_TO_FEET
	vertical_speed_fpm = data.get("vertical_speed_fpm", 0.0)
	g_force = data.get("g_force", 1.0)
	aoa_deg = data.get("aoa_deg", 0.0)
	stall_warning = data.get("stall_warning", false)
	gear_down = data.get("gear_down", true)
	flaps_deg = data.get("flaps_deg", 0.0)
	brakes_on = data.get("brakes_on", false)

	if is_nan(airspeed_kias) or is_inf(airspeed_kias): airspeed_kias = 0.0
	if is_nan(altitude_feet_msl) or is_inf(altitude_feet_msl): altitude_feet_msl = 0.0
	if is_nan(vertical_speed_fpm) or is_inf(vertical_speed_fpm): vertical_speed_fpm = 0.0
	if is_nan(g_force) or is_inf(g_force): g_force = 1.0
	if is_nan(aoa_deg) or is_inf(aoa_deg): aoa_deg = 0.0

	if aircraft and is_instance_valid(aircraft):
		var rot = aircraft.global_rotation
		pitch_rad = rot.x if not is_nan(rot.x) and not is_inf(rot.x) else 0.0
		roll_rad = rot.z if not is_nan(rot.z) and not is_inf(rot.z) else 0.0
		var yaw = rot.y if not is_nan(rot.y) and not is_inf(rot.y) else 0.0
		heading_deg = fposmod(rad_to_deg(-yaw), 360.0)
	if is_nan(heading_deg) or is_inf(heading_deg):
		heading_deg = 0.0

	queue_redraw()

func _draw() -> void:
	var screen_size = get_viewport_rect().size
	var center = screen_size * 0.5
	var color = HUD_DANGER if stall_warning else HUD_GREEN

	# 1. Boresight Cross (Waterline symbol at aircraft nose)
	_draw_boresight(center, color)

	# 2. Flight Path Marker (Velocity Vector projected via camera)
	_draw_flight_path_marker(center, color)

	# 3. Roll-Corrected Pitch Ladder (5 degree increments)
	_draw_pitch_ladder(center, color)

	# 4. Airspeed Tape (KIAS) - Left Side
	_draw_airspeed_tape(screen_size, color)

	# 5. Altitude Tape (Feet MSL) - Right Side
	_draw_altitude_tape(screen_size, color)

	# 6. Vertical Speed Indicator (FPM) - Far Right
	_draw_vsi(screen_size, color)

	# 7. G-Meter & Heading Tape
	_draw_telemetry_readouts(screen_size, color)

	# 8. Angle of Attack (AoA) Bracket - Near Airspeed Tape
	_draw_aoa_bracket(screen_size, color)

	# 9. Annunciator Flags (STALL, GEAR, FLAPS, BRAKES)
	_draw_annunciators(screen_size)

func _draw_boresight(center: Vector2, color: Color) -> void:
	var wing_len = 24.0
	var drop_len = 8.0
	# Center dot
	draw_circle(center, 2.5, color)
	# Left wing
	draw_line(center - Vector2(12, 0), center - Vector2(12 + wing_len, 0), color, 2.0)
	draw_line(center - Vector2(12 + wing_len, 0), center - Vector2(12 + wing_len, drop_len), color, 2.0)
	# Right wing
	draw_line(center + Vector2(12, 0), center + Vector2(12 + wing_len, 0), color, 2.0)
	draw_line(center + Vector2(12 + wing_len, 0), center + Vector2(12 + wing_len, drop_len), color, 2.0)

func _draw_flight_path_marker(center: Vector2, color: Color) -> void:
	var fpm_pos = center
	if camera and aircraft and is_instance_valid(aircraft) and is_instance_valid(camera):
		var vel = aircraft.linear_velocity
		if vel.length_squared() > 1.0:
			var target_3d = aircraft.global_position + vel.normalized() * 50.0
			if not camera.is_position_behind(target_3d):
				fpm_pos = camera.unproject_position(target_3d)

	# Clamp to reasonable screen bounds
	fpm_pos.x = clamp(fpm_pos.x, center.x - 320.0, center.x + 320.0)
	fpm_pos.y = clamp(fpm_pos.y, center.y - 240.0, center.y + 240.0)

	# Circle with wings and top fin
	var radius = 9.0
	draw_arc(fpm_pos, radius, 0.0, TAU, 16, color, 2.0)
	# Left wing
	draw_line(fpm_pos - Vector2(radius, 0), fpm_pos - Vector2(radius + 12.0, 0), color, 2.0)
	# Right wing
	draw_line(fpm_pos + Vector2(radius, 0), fpm_pos + Vector2(radius + 12.0, 0), color, 2.0)
	# Top rudder fin
	draw_line(fpm_pos - Vector2(0, radius), fpm_pos - Vector2(0, radius + 8.0), color, 2.0)

func _draw_pitch_ladder(center: Vector2, color: Color) -> void:
	var pixels_per_deg = 8.0
	var cur_pitch_deg = rad_to_deg(pitch_rad)
	var ladder_half_width = 55.0

	# Apply roll rotation around center
	draw_set_transform(center, -roll_rad, Vector2.ONE)

	# Horizon Line (Solid extended bar)
	var horizon_y = cur_pitch_deg * pixels_per_deg
	draw_line(Vector2(-120, horizon_y), Vector2(-40, horizon_y), color, 2.5)
	draw_line(Vector2(40, horizon_y), Vector2(120, horizon_y), color, 2.5)

	# Pitch rungs from -45 to +45 deg in 5 deg steps
	for p in range(-45, 50, 5):
		if p == 0:
			continue
		var y = (cur_pitch_deg - p) * pixels_per_deg
		if abs(y) > 220.0:
			continue # Clip outside HUD viewport

		var is_positive = p > 0
		var rung_len = ladder_half_width
		var tab_height = 8.0 if is_positive else -8.0

		if is_positive:
			# Positive pitch: Solid line with downward tabs
			draw_line(Vector2(-rung_len, y), Vector2(-18, y), color, 1.8)
			draw_line(Vector2(-rung_len, y), Vector2(-rung_len, y + tab_height), color, 1.8)

			draw_line(Vector2(18, y), Vector2(rung_len, y), color, 1.8)
			draw_line(Vector2(rung_len, y), Vector2(rung_len, y + tab_height), color, 1.8)
		else:
			# Negative pitch: Dashed line with upward tabs
			_draw_dashed_line(Vector2(-rung_len, y), Vector2(-18, y), color, 1.8, 6.0, 4.0)
			draw_line(Vector2(-rung_len, y), Vector2(-rung_len, y + tab_height), color, 1.8)

			_draw_dashed_line(Vector2(18, y), Vector2(rung_len, y), color, 1.8, 6.0, 4.0)
			draw_line(Vector2(rung_len, y), Vector2(rung_len, y + tab_height), color, 1.8)

		# Degree label
		var text = str(abs(p))
		draw_string(_font, Vector2(rung_len + 4, y + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
		draw_string(_font, Vector2(-rung_len - 22, y + 4), text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var dir = (to - from).normalized()
	var total_len = from.distance_to(to)
	var curr = 0.0
	while curr < total_len:
		var p1 = from + dir * curr
		var p2 = from + dir * min(curr + dash, total_len)
		draw_line(p1, p2, color, width)
		curr += dash + gap

func _draw_airspeed_tape(screen_size: Vector2, color: Color) -> void:
	var x = screen_size.x * 0.5 - 240.0
	var center_y = screen_size.y * 0.5
	var tape_h = 280.0
	var px_per_knot = 4.0

	# Tape background boundary line
	draw_line(Vector2(x, center_y - tape_h * 0.5), Vector2(x, center_y + tape_h * 0.5), color, 2.0)

	# Tick marks every 5 and 10 knots
	var min_speed = int(airspeed_kias - 35)
	var max_speed = int(airspeed_kias + 35)
	for s in range(min_speed, max_speed + 1):
		if s < 0:
			continue
		var y = center_y - (s - airspeed_kias) * px_per_knot
		if abs(y - center_y) > tape_h * 0.5:
			continue

		if s % 10 == 0:
			draw_line(Vector2(x - 14, y), Vector2(x, y), color, 2.0)
			draw_string(_font, Vector2(x - 48, y + 4), str(s), HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, color)
		elif s % 5 == 0:
			draw_line(Vector2(x - 8, y), Vector2(x, y), color, 1.2)

	# Readout Window
	var win_rect = Rect2(x - 62, center_y - 14, 58, 28)
	draw_rect(win_rect, Color(0, 0, 0, 0.65), true)
	draw_rect(win_rect, color, false, 2.0)
	draw_string(_font, Vector2(x - 58, center_y + 6), "%3.0f" % airspeed_kias, HORIZONTAL_ALIGNMENT_CENTER, 50, 16, color)
	draw_string(_font, Vector2(x - 58, center_y - 18), "KIAS", HORIZONTAL_ALIGNMENT_CENTER, 50, 10, color)

func _draw_altitude_tape(screen_size: Vector2, color: Color) -> void:
	var x = screen_size.x * 0.5 + 240.0
	var center_y = screen_size.y * 0.5
	var tape_h = 280.0
	var px_per_foot = 0.55

	# Tape line
	draw_line(Vector2(x, center_y - tape_h * 0.5), Vector2(x, center_y + tape_h * 0.5), color, 2.0)

	# Ticks every 50 and 100 ft
	var min_alt = int((altitude_feet_msl - 250) / 50.0) * 50
	var max_alt = int((altitude_feet_msl + 250) / 50.0) * 50
	for a in range(min_alt, max_alt + 50, 50):
		var y = center_y - (a - altitude_feet_msl) * px_per_foot
		if abs(y - center_y) > tape_h * 0.5:
			continue

		if a % 100 == 0:
			draw_line(Vector2(x, y), Vector2(x + 14, y), color, 2.0)
			draw_string(_font, Vector2(x + 18, y + 4), str(a), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		else:
			draw_line(Vector2(x, y), Vector2(x + 8, y), color, 1.2)

	# Readout Window
	var win_rect = Rect2(x + 4, center_y - 14, 68, 28)
	draw_rect(win_rect, Color(0, 0, 0, 0.65), true)
	draw_rect(win_rect, color, false, 2.0)
	draw_string(_font, Vector2(x + 8, center_y + 6), "%5.0f" % altitude_feet_msl, HORIZONTAL_ALIGNMENT_CENTER, 60, 15, color)
	draw_string(_font, Vector2(x + 8, center_y - 18), "ALT MSL", HORIZONTAL_ALIGNMENT_CENTER, 60, 10, color)

func _draw_vsi(screen_size: Vector2, color: Color) -> void:
	var x = screen_size.x * 0.5 + 330.0
	var center_y = screen_size.y * 0.5
	var tape_h = 200.0

	# Vertical scale bar: -2000 to +2000 FPM
	draw_line(Vector2(x, center_y - tape_h * 0.5), Vector2(x, center_y + tape_h * 0.5), color, 1.5)
	draw_line(Vector2(x - 5, center_y), Vector2(x + 5, center_y), color, 2.0) # 0 FPM marker

	# Pointer based on vertical speed
	var max_fpm = 2000.0
	var norm_vs = clamp(vertical_speed_fpm / max_fpm, -1.0, 1.0)
	var ptr_y = center_y - norm_vs * (tape_h * 0.5)

	draw_line(Vector2(x, center_y), Vector2(x + 10, ptr_y), color, 2.0)
	draw_string(_font, Vector2(x + 14, center_y - 5), "%+.0f" % vertical_speed_fpm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	draw_string(_font, Vector2(x - 10, center_y - tape_h * 0.5 - 6), "VSI", HORIZONTAL_ALIGNMENT_CENTER, 30, 10, color)

func _draw_telemetry_readouts(screen_size: Vector2, color: Color) -> void:
	var bottom_y = screen_size.y - 32.0

	# G-Meter (Bottom Left)
	var g_color = HUD_DANGER if (g_force > 3.0 or g_force < -0.5) else color
	draw_string(_font, Vector2(40, bottom_y), "G: %4.1f" % g_force, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, g_color)

	# Heading Tape (Top Center)
	var top_y = 42.0
	var cx = screen_size.x * 0.5
	draw_rect(Rect2(cx - 70, top_y - 20, 140, 26), Color(0, 0, 0, 0.5), true)
	draw_rect(Rect2(cx - 70, top_y - 20, 140, 26), color, false, 1.5)
	draw_string(_font, Vector2(cx - 65, top_y - 2), "HDG: %03.0f°" % heading_deg, HORIZONTAL_ALIGNMENT_CENTER, 130, 15, color)

func _draw_aoa_bracket(screen_size: Vector2, color: Color) -> void:
	var x = screen_size.x * 0.5 - 170.0
	var center_y = screen_size.y * 0.5

	# AoA bracket indicator
	var aoa_color = color
	if aoa_deg >= 13.5:
		aoa_color = HUD_DANGER
	elif aoa_deg >= 10.0:
		aoa_color = HUD_WARN

	var aoa_px = center_y - (aoa_deg - 5.0) * 8.0
	aoa_px = clamp(aoa_px, center_y - 90.0, center_y + 90.0)

	# Draw AoA bracket symbols [---]
	draw_line(Vector2(x - 8, aoa_px - 10), Vector2(x, aoa_px - 10), aoa_color, 2.0)
	draw_line(Vector2(x, aoa_px - 10), Vector2(x, aoa_px + 10), aoa_color, 2.0)
	draw_line(Vector2(x - 8, aoa_px + 10), Vector2(x, aoa_px + 10), aoa_color, 2.0)

	draw_string(_font, Vector2(x - 55, aoa_px + 5), "α: %4.1f°" % aoa_deg, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, aoa_color)

func _draw_annunciators(screen_size: Vector2) -> void:
	var top_y = 80.0
	var cx = screen_size.x * 0.5

	# Stall Warning Banner
	if stall_warning:
		var stall_rect = Rect2(cx - 100, top_y, 200, 36)
		draw_rect(stall_rect, Color(0.8, 0.1, 0.1, 0.85), true)
		draw_rect(stall_rect, HUD_DANGER, false, 2.5)
		draw_string(_font, Vector2(cx - 95, top_y + 24), "STALL WARNING", HORIZONTAL_ALIGNMENT_CENTER, 190, 18, Color.WHITE)

	# Status flags (bottom right)
	var sx = screen_size.x - 220.0
	var sy = screen_size.y - 32.0

	var gear_str = "GEAR: DOWN" if gear_down else "GEAR: UP"
	var gear_col = HUD_GREEN if gear_down else HUD_WARN
	draw_string(_font, Vector2(sx, sy), gear_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, gear_col)

	var flaps_str = "FLAPS: %2.0f°" % flaps_deg
	draw_string(_font, Vector2(sx + 90, sy), flaps_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, HUD_GREEN)

	if brakes_on:
		draw_string(_font, Vector2(sx + 175, sy), "BRK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, HUD_WARN)

	# Ghost Flight Director Target Brackets
	if ghost_director_active:
		_draw_ghost_flight_director(screen_size * 0.5)

	# Crash Banner
	if is_crashed:
		var banner_w = 420.0
		var banner_h = 90.0
		var r = Rect2(cx - banner_w * 0.5, screen_size.y * 0.42, banner_w, banner_h)
		draw_rect(r, Color(0.1, 0.02, 0.02, 0.92), true)
		draw_rect(r, HUD_DANGER, false, 3.0)
		draw_string(_font, Vector2(cx - 200, screen_size.y * 0.42 + 28), "AIRCRAFT DESTROYED", HORIZONTAL_ALIGNMENT_CENTER, 400, 20, HUD_DANGER)
		draw_string(_font, Vector2(cx - 200, screen_size.y * 0.42 + 52), crash_reason, HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color(1, 0.8, 0.8))
		draw_string(_font, Vector2(cx - 200, screen_size.y * 0.42 + 76), "PRESS [R] TO RESET SIMULATION", HORIZONTAL_ALIGNMENT_CENTER, 400, 14, Color(1, 1, 0.3))

func _draw_ghost_flight_director(center: Vector2) -> void:
	var cue_color = Color(0.15, 0.85, 1.0, 0.85) # Cyan flight director cue
	var pitch_offset_px = (ghost_target_pitch_deg - rad_to_deg(pitch_rad)) * 6.0
	pitch_offset_px = clampf(pitch_offset_px, -120.0, 120.0)

	var cue_y = center.y - pitch_offset_px
	var cue_x = center.x
	var d_roll = deg_to_rad(ghost_target_roll_deg) - roll_rad

	# Flight director inverted-V / wing chevron
	var p_left = Vector2(cue_x - 36, cue_y + 12).rotated(d_roll)
	var p_center = Vector2(cue_x, cue_y).rotated(d_roll)
	var p_right = Vector2(cue_x + 36, cue_y + 12).rotated(d_roll)

	draw_line(p_center + (center - center.rotated(d_roll)), p_left + (center - center.rotated(d_roll)), cue_color, 2.5)
	draw_line(p_center + (center - center.rotated(d_roll)), p_right + (center - center.rotated(d_roll)), cue_color, 2.5)
	draw_string(_font, Vector2(cue_x - 40, cue_y - 8), "FD: TGT", HORIZONTAL_ALIGNMENT_CENTER, 80, 10, cue_color)

func set_ghost_director(active: bool, pitch_deg: float = 0.0, roll_deg: float = 0.0) -> void:
	ghost_director_active = active
	ghost_target_pitch_deg = pitch_deg
	ghost_target_roll_deg = roll_deg
	queue_redraw()

func show_crash_banner(reason: String) -> void:
	is_crashed = true
	crash_reason = reason
	queue_redraw()
