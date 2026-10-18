class_name UrbanHUD
extends Control

## Production-grade Cross-Platform Telemetry HUD for Urban Legends.
## Features:
## - Circular Minimap: 200m road vector radar, rotating player arrow, North pointer, and mission blips
## - Digital Speedometer: km/h readout, current gear (R/N/1-6), RPM tachometer bar
## - Vehicle Vitals: Health bar, Armor integrity, Nitro gauge
## - Metropolitan Telemetry: In-game clock (17:30 golden hour), Career Cash wallet, District Banner
## - Dynamic Stunt Combos & Rewards Toasts
## - Mobile Touch Screen Overlay with Steer, Throttle, Brake, Drift, Nitro, and Flip buttons.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")
const ThemeGen = preload("res://shared/ui/theme_generator.gd")

# Top-Left: Circular Minimap Container
var minimap_container: PanelContainer
var minimap_draw: MinimapCanvas
var district_label: Label

# Top-Right: Metropolitan Progression & Clock
var stats_card: PanelContainer
var cash_label: Label
var clock_label: Label
var health_bar: ProgressBar
var armor_bar: ProgressBar

# Bottom-Right: Speedometer & Tachometer
var speed_card: PanelContainer
var speed_label: Label
var gear_label: Label
var rpm_bar: ProgressBar
var nitro_bar: ProgressBar

# Top-Center: District Banner Toast
var district_banner: PanelContainer
var district_banner_label: Label
var district_banner_timer: float = 0.0

# Center: Stunt Combo Popup
var stunt_toast: PanelContainer
var stunt_title_label: Label
var stunt_cash_label: Label
var stunt_toast_timer: float = 0.0

# Desktop Controls Guide
var controls_guide_panel: PanelContainer
var controls_guide_label: Label

# Touch Controls Overlay
var touch_controls_root: Control
var btn_steer_left: Button
var btn_steer_right: Button
var btn_throttle: Button
var btn_brake: Button
var btn_handbrake: Button
var btn_nitro: Button
var btn_flip: Button

# Tracked Targets
var player_vehicle: Node3D = null
var road_network = null
var weather_system: Node = null
var last_reported_district: String = ""

# Virtual Input State
var touch_steer: float = 0.0
var touch_throttle: float = 0.0
var touch_brake: float = 0.0
var touch_handbrake: bool = false
var touch_nitro: bool = false

# --- Circular Minimap Drawing Node ---
class MinimapCanvas extends Control:
	var hud_ref: UrbanHUD = null
	var radar_radius: float = 75.0
	var world_radius: float = 240.0 # Meters represented in radar

	func _init(hud: UrbanHUD) -> void:
		hud_ref = hud
		custom_minimum_size = Vector2(160, 160)
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center = size * 0.5
		# Glass background with subtle radial grid
		draw_circle(center, radar_radius, Color(0.04, 0.07, 0.12, 0.94))
		draw_arc(center, radar_radius, 0, TAU, 64, Color(0.0, 0.88, 1.0, 0.80), 2.5)
		draw_arc(center, radar_radius * 0.65, 0, TAU, 48, Color(0.2, 0.45, 0.55, 0.30), 1.0)
		draw_arc(center, radar_radius * 0.32, 0, TAU, 32, Color(0.2, 0.45, 0.55, 0.20), 1.0)

		if not hud_ref or not is_instance_valid(hud_ref.player_vehicle):
			_draw_player_icon(center, 0.0)
			return

		var p_pos = hud_ref.player_vehicle.global_position if hud_ref.player_vehicle.is_inside_tree() else hud_ref.player_vehicle.position
		var p_rot = hud_ref.player_vehicle.rotation.y

		# 1. City Block Backdrop & Park Greenery Zones
		var park_zones = [
			Vector3(380, 0, -220), # Central Metropolitan Park
			Vector3(350, 0, 300),  # University Campus Quad
		]
		for pz in park_zones:
			var pz_pt = _world_to_minimap(pz, p_pos, p_rot, center)
			if (pz_pt - center).length() < radar_radius + 45.0:
				draw_circle(pz_pt, 42.0, Color(0.12, 0.45, 0.22, 0.35))

		var block_grid_offsets = [
			Vector2(-45, -45), Vector2(10, -45), Vector2(-45, 10), Vector2(10, 10),
			Vector2(-100, -45), Vector2(65, -45), Vector2(-100, 10), Vector2(65, 10)
		]
		for bo in block_grid_offsets:
			var b_pos = center + bo.rotated(-p_rot)
			if (b_pos - center).length() < radar_radius - 8.0:
				var rect = Rect2(b_pos - Vector2(22, 22), Vector2(44, 44))
				draw_rect(rect, Color(0.08, 0.13, 0.18, 0.65), true)

		# 2. Continuous Vector Road Network with authentic hierarchies
		if hud_ref.road_network and "segments" in hud_ref.road_network:
			for seg in hud_ref.road_network.segments:
				var st: Vector3 = seg["start"]
				var en: Vector3 = seg["end"]

				var p1 = _world_to_minimap(st, p_pos, p_rot, center)
				var p2 = _world_to_minimap(en, p_pos, p_rot, center)

				var clipped = _clip_line_to_circle(p1, p2, center, radar_radius - 1.5)
				if clipped.size() == 2:
					var is_freeway = seg.get("is_freeway", false)
					var surface_type = seg.get("surface", 0)
					var lanes = seg.get("lanes", 2)

					# Road edge casing
					var casing_col = Color(0.02, 0.04, 0.06, 0.95)
					var casing_w = 6.8 if is_freeway else (5.4 if lanes >= 4 else 3.8)
					draw_line(clipped[0], clipped[1], casing_col, casing_w)

					# Road surface fill
					var road_col = Color(0.90, 0.92, 0.95, 0.90)
					if is_freeway:
						road_col = Color(0.0, 0.90, 1.0, 0.95) # Neon cyan for elevated viaducts & bridge
					elif lanes >= 4:
						road_col = Color(0.98, 0.82, 0.22, 0.95) # Warm amber/yellow for Grand Ave arterials
					elif surface_type == UrbanConstants.SURFACE_GRASS:
						road_col = Color(0.35, 0.85, 0.40, 0.75) # Park drift paths
					elif surface_type == UrbanConstants.SURFACE_DIRT:
						road_col = Color(0.85, 0.65, 0.40, 0.75) # Gravel / mountain

					var road_w = 4.8 if is_freeway else (3.6 if lanes >= 4 else 2.4)
					draw_line(clipped[0], clipped[1], road_col, road_w)

		# 3. Railway Corridors & Elevated El-Train Viaduct Lines
		var rail_corridors = [
			[Vector3(-1400, 0, 480), Vector3(-450, 0, 480)],
			[Vector3(-550, 8, 300), Vector3(500, 8, 300)]
		]
		for rc in rail_corridors:
			var rp1 = _world_to_minimap(rc[0], p_pos, p_rot, center)
			var rp2 = _world_to_minimap(rc[1], p_pos, p_rot, center)
			var r_clipped = _clip_line_to_circle(rp1, rp2, center, radar_radius - 1.5)
			if r_clipped.size() == 2:
				draw_line(r_clipped[0], r_clipped[1], Color(0.70, 0.75, 0.82, 0.9), 2.2)

		# 4. GPS Navigation Route Line to Nearest Objective / Stunt Ramp
		var target_dest = Vector3.ZERO
		var has_target = false
		if hud_ref.player_vehicle.is_inside_tree():
			var kickers = hud_ref.player_vehicle.get_tree().get_nodes_in_group("stunt_ramps")
			var min_d = 999999.0
			for k in kickers:
				if is_instance_valid(k):
					var kp = k.global_position if k.is_inside_tree() else k.position
					var d = p_pos.distance_to(kp)
					if d < min_d:
						min_d = d
						target_dest = kp
						has_target = true

		if has_target:
			var target_pt = _world_to_minimap(target_dest, p_pos, p_rot, center)
			var clipped_gps = _clip_line_to_circle(center, target_pt, center, radar_radius - 2.0)
			if clipped_gps.size() == 2:
				var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.006)
				draw_line(clipped_gps[0], clipped_gps[1], Color(1.0, 0.65, 0.1, 0.85 * pulse), 2.2)

		# 5. Draw Stunt Kickers & Objective Blips
		if hud_ref.player_vehicle.is_inside_tree():
			var kickers = hud_ref.player_vehicle.get_tree().get_nodes_in_group("stunt_ramps")
			for k in kickers:
				if is_instance_valid(k):
					var k_pos = k.global_position if k.is_inside_tree() else k.position
					var k_pt = _world_to_minimap(k_pos, p_pos, p_rot, center)
					if (k_pt - center).length() <= radar_radius - 4.0:
						var diamond = PackedVector2Array([
							k_pt + Vector2(0, -4),
							k_pt + Vector2(4, 0),
							k_pt + Vector2(0, 4),
							k_pt + Vector2(-4, 0)
						])
						draw_colored_polygon(diamond, Color(1.0, 0.85, 0.15, 0.95))
						draw_polyline(diamond, Color(0.1, 0.1, 0.1, 1.0), 1.2)

		# 6. Moving AI Traffic Vehicle Dots
		if hud_ref.player_vehicle.is_inside_tree():
			var traffic_nodes = hud_ref.player_vehicle.get_tree().get_nodes_in_group("ai_traffic")
			for tv in traffic_nodes:
				if is_instance_valid(tv) and tv != hud_ref.player_vehicle:
					var tv_pos = tv.global_position if tv.is_inside_tree() else tv.position
					var tv_pt = _world_to_minimap(tv_pos, p_pos, p_rot, center)
					if (tv_pt - center).length() <= radar_radius - 2.5:
						var is_cop = tv.get("is_police") == true
						var tv_col = Color(1.0, 0.68, 0.12) # Warm amber AI traffic dot
						if is_cop:
							var flash_cop = fmod(Time.get_ticks_msec() * 0.006, 2.0) < 1.0
							tv_col = Color(1.0, 0.12, 0.12) if flash_cop else Color(0.15, 0.45, 1.0)
						draw_circle(tv_pt, 3.2, tv_col)
						draw_arc(tv_pt, 3.2, 0, TAU, 16, Color(0.08, 0.08, 0.1, 0.85), 1.0)

		# 7. North Indicator on Compass Ring
		var north_angle = -p_rot - PI * 0.5
		var north_pos = center + Vector2(cos(north_angle), sin(north_angle)) * (radar_radius - 8.0)
		draw_circle(north_pos, 4.5, Color(1.0, 0.25, 0.3, 0.95))

		# 8. Player Vehicle Arrow at Center
		_draw_player_icon(center, 0.0)

	func _clip_line_to_circle(p1: Vector2, p2: Vector2, center: Vector2, radius: float) -> Array[Vector2]:
		var d = p2 - p1
		var seg_len = d.length()
		if seg_len < 0.001:
			if (p1 - center).length() <= radius:
				return [p1, p2]
			return []

		var u = d / seg_len
		var f = p1 - center
		var b = f.dot(u)
		var c = f.length_squared() - radius * radius
		var discriminant = b * b - c

		if discriminant < 0.0:
			return []

		var sqrt_d = sqrt(discriminant)
		var t_enter = -b - sqrt_d
		var t_exit = -b + sqrt_d

		var t0 = clampf(t_enter, 0.0, seg_len)
		var t1 = clampf(t_exit, 0.0, seg_len)

		if t0 >= t1:
			return []

		return [p1 + u * t0, p1 + u * t1]

	func _world_to_minimap(world_pt: Vector3, player_pos: Vector3, player_yaw: float, center: Vector2) -> Vector2:
		var rel_x = world_pt.x - player_pos.x
		var rel_z = world_pt.z - player_pos.z

		# Rotate by negative player yaw so player forward is UP
		var cos_a = cos(-player_yaw)
		var sin_a = sin(-player_yaw)
		var rot_x = rel_x * cos_a - rel_z * sin_a
		var rot_z = rel_x * sin_a + rel_z * cos_a

		var scale_f = radar_radius / world_radius
		return center + Vector2(rot_x * scale_f, rot_z * scale_f)

	func _draw_player_icon(center: Vector2, _heading: float) -> void:
		var chevron_outline = PackedVector2Array([
			center + Vector2(0, -10),
			center + Vector2(-7, 8),
			center + Vector2(0, 3.5),
			center + Vector2(7, 8),
			center + Vector2(0, -10)
		])
		var chevron_fill = PackedVector2Array([
			center + Vector2(0, -9),
			center + Vector2(-6, 7),
			center + Vector2(0, 3),
			center + Vector2(6, 7)
		])
		draw_polyline(chevron_outline, Color(1.0, 1.0, 1.0, 1.0), 2.0)
		draw_colored_polygon(chevron_fill, Color(0.0, 1.0, 0.85, 1.0))

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGen.get_theme()

	_setup_minimap()
	_setup_progression_card()
	_setup_speedometer_card()
	_setup_district_banner()
	_setup_stunt_toast()
	_setup_controls_guide()
	_setup_touch_controls()
	_update_responsive_layout(size)

	if get_viewport():
		get_viewport().size_changed.connect(func(): _update_responsive_layout(get_viewport().get_visible_rect().size))

func setup(player: Node3D, roads = null, weather: Node = null) -> void:
	player_vehicle = player
	road_network = roads
	weather_system = weather

func _setup_minimap() -> void:
	minimap_container = PanelContainer.new()
	minimap_container.name = "MinimapContainer"
	minimap_container.mouse_filter = MOUSE_FILTER_IGNORE

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)

	minimap_draw = MinimapCanvas.new(self)
	vb.add_child(minimap_draw)

	district_label = Label.new()
	district_label.text = "DOWNTOWN METRO"
	district_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	district_label.add_theme_font_size_override("font_size", 12)
	district_label.add_theme_color_override("font_color", Color(0.1, 0.95, 1.0))
	vb.add_child(district_label)

	minimap_container.add_child(vb)
	add_child(minimap_container)

func _setup_progression_card() -> void:
	stats_card = PanelContainer.new()
	stats_card.name = "StatsCard"
	stats_card.mouse_filter = MOUSE_FILTER_IGNORE

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)

	var hb = HBoxContainer.new()
	cash_label = Label.new()
	cash_label.text = "💵 $25,000"
	cash_label.add_theme_font_size_override("font_size", 16)
	cash_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	hb.add_child(cash_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hb.add_child(spacer)

	clock_label = Label.new()
	clock_label.text = "17:30"
	clock_label.add_theme_font_size_override("font_size", 14)
	clock_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	hb.add_child(clock_label)
	vb.add_child(hb)

	# Health Bar
	var h_hb = HBoxContainer.new()
	var hl = Label.new()
	hl.text = "HP"
	hl.add_theme_font_size_override("font_size", 11)
	h_hb.add_child(hl)
	health_bar = ProgressBar.new()
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	health_bar.custom_minimum_size.y = 8
	h_hb.add_child(health_bar)
	vb.add_child(h_hb)

	# Armor Bar
	var a_hb = HBoxContainer.new()
	var al = Label.new()
	al.text = "ARM"
	al.add_theme_font_size_override("font_size", 11)
	a_hb.add_child(al)
	armor_bar = ProgressBar.new()
	armor_bar.min_value = 0.0
	armor_bar.max_value = 100.0
	armor_bar.value = 100.0
	armor_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	armor_bar.custom_minimum_size.y = 8
	a_hb.add_child(armor_bar)
	vb.add_child(a_hb)

	stats_card.add_child(vb)
	add_child(stats_card)

func _setup_speedometer_card() -> void:
	speed_card = PanelContainer.new()
	speed_card.name = "SpeedCard"
	speed_card.mouse_filter = MOUSE_FILTER_IGNORE

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)

	var hb = HBoxContainer.new()
	speed_label = Label.new()
	speed_label.text = "000 KM/H"
	speed_label.add_theme_font_size_override("font_size", 24)
	speed_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	hb.add_child(speed_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hb.add_child(spacer)

	gear_label = Label.new()
	gear_label.text = "N"
	gear_label.add_theme_font_size_override("font_size", 22)
	gear_label.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	hb.add_child(gear_label)
	vb.add_child(hb)

	# RPM Tachometer
	rpm_bar = ProgressBar.new()
	rpm_bar.min_value = 800.0
	rpm_bar.max_value = 8000.0
	rpm_bar.value = 1000.0
	rpm_bar.custom_minimum_size = Vector2(180, 7)
	vb.add_child(rpm_bar)

	# Nitro Gauge
	var n_hb = HBoxContainer.new()
	var nl = Label.new()
	nl.text = "NITRO"
	nl.add_theme_font_size_override("font_size", 10)
	nl.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
	n_hb.add_child(nl)
	nitro_bar = ProgressBar.new()
	nitro_bar.min_value = 0.0
	nitro_bar.max_value = 100.0
	nitro_bar.value = 100.0
	nitro_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	nitro_bar.custom_minimum_size.y = 7
	n_hb.add_child(nitro_bar)
	vb.add_child(n_hb)

	speed_card.add_child(vb)
	add_child(speed_card)

func _setup_district_banner() -> void:
	district_banner = PanelContainer.new()
	district_banner.name = "DistrictBanner"
	district_banner.mouse_filter = MOUSE_FILTER_IGNORE
	district_banner.visible = false

	var vb = VBoxContainer.new()
	district_banner_label = Label.new()
	district_banner_label.text = "DISTRICT ENTERED"
	district_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	district_banner_label.add_theme_font_size_override("font_size", 18)
	district_banner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vb.add_child(district_banner_label)

	district_banner.add_child(vb)
	add_child(district_banner)

func _setup_stunt_toast() -> void:
	stunt_toast = PanelContainer.new()
	stunt_toast.name = "StuntToast"
	stunt_toast.mouse_filter = MOUSE_FILTER_IGNORE
	stunt_toast.visible = false

	var vb = VBoxContainer.new()
	stunt_title_label = Label.new()
	stunt_title_label.text = "MEGA AIR 45.2m"
	stunt_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stunt_title_label.add_theme_font_size_override("font_size", 20)
	stunt_title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.8))
	vb.add_child(stunt_title_label)

	stunt_cash_label = Label.new()
	stunt_cash_label.text = "+$450"
	stunt_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stunt_cash_label.add_theme_font_size_override("font_size", 16)
	stunt_cash_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	vb.add_child(stunt_cash_label)

	stunt_toast.add_child(vb)
	add_child(stunt_toast)

func _setup_controls_guide() -> void:
	controls_guide_panel = PanelContainer.new()
	controls_guide_panel.name = "ControlsGuidePanel"
	controls_guide_panel.mouse_filter = MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.12, 0.75)
	style.set_corner_radius_all(8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.0, 0.88, 1.0, 0.35)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	controls_guide_panel.add_theme_stylebox_override("panel", style)

	controls_guide_label = Label.new()
	controls_guide_label.text = "[W/S] Throttle/Reverse  •  [A/D] Steer  •  [Space] Drift  •  [Shift] Boost  •  [R] Reset"
	controls_guide_label.add_theme_font_size_override("font_size", 11)
	controls_guide_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.85))
	controls_guide_panel.add_child(controls_guide_label)
	add_child(controls_guide_panel)

func _setup_touch_controls() -> void:
	touch_controls_root = Control.new()
	touch_controls_root.name = "TouchControls"
	touch_controls_root.anchor_right = 1.0
	touch_controls_root.anchor_bottom = 1.0
	touch_controls_root.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(touch_controls_root)

	# Steer Buttons (Bottom-Left)
	btn_steer_left = Button.new()
	btn_steer_left.text = "◀"
	btn_steer_left.custom_minimum_size = Vector2(70, 70)
	btn_steer_left.button_down.connect(func(): touch_steer = -1.0)
	btn_steer_left.button_up.connect(func(): touch_steer = 0.0)
	touch_controls_root.add_child(btn_steer_left)

	btn_steer_right = Button.new()
	btn_steer_right.text = "▶"
	btn_steer_right.custom_minimum_size = Vector2(70, 70)
	btn_steer_right.button_down.connect(func(): touch_steer = 1.0)
	btn_steer_right.button_up.connect(func(): touch_steer = 0.0)
	touch_controls_root.add_child(btn_steer_right)

	# Gas, Brake, Handbrake, Nitro (Bottom-Right)
	btn_throttle = Button.new()
	btn_throttle.text = "GAS"
	btn_throttle.custom_minimum_size = Vector2(70, 70)
	btn_throttle.button_down.connect(func(): touch_throttle = 1.0)
	btn_throttle.button_up.connect(func(): touch_throttle = 0.0)
	touch_controls_root.add_child(btn_throttle)

	btn_brake = Button.new()
	btn_brake.text = "BRAKE"
	btn_brake.custom_minimum_size = Vector2(70, 60)
	btn_brake.button_down.connect(func(): touch_brake = 1.0)
	btn_brake.button_up.connect(func(): touch_brake = 0.0)
	touch_controls_root.add_child(btn_brake)

	btn_handbrake = Button.new()
	btn_handbrake.text = "DRIFT"
	btn_handbrake.custom_minimum_size = Vector2(65, 50)
	btn_handbrake.button_down.connect(func(): touch_handbrake = true)
	btn_handbrake.button_up.connect(func(): touch_handbrake = false)
	touch_controls_root.add_child(btn_handbrake)

	btn_nitro = Button.new()
	btn_nitro.text = "BOOST"
	btn_nitro.custom_minimum_size = Vector2(65, 50)
	btn_nitro.button_down.connect(func(): touch_nitro = true)
	btn_nitro.button_up.connect(func(): touch_nitro = false)
	touch_controls_root.add_child(btn_nitro)

	btn_flip = Button.new()
	btn_flip.text = "RESET"
	btn_flip.custom_minimum_size = Vector2(60, 40)
	btn_flip.pressed.connect(func():
		if is_instance_valid(player_vehicle) and player_vehicle.has_method("recover_vehicle"):
			player_vehicle.recover_vehicle()
	)
	touch_controls_root.add_child(btn_flip)

	# Only visible on mobile/touchscreen platforms
	var is_touch = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	touch_controls_root.visible = is_touch

func _process(delta: float) -> void:
	if is_instance_valid(player_vehicle):
		_update_telemetry(delta)

	if minimap_draw:
		minimap_draw.queue_redraw()

	if weather_system and is_instance_valid(weather_system):
		clock_label.text = weather_system.get_formatted_clock()

	# District banner timer
	if district_banner_timer > 0.0:
		district_banner_timer -= delta
		if district_banner_timer <= 0.0:
			district_banner.visible = false

	# Stunt toast timer
	if stunt_toast_timer > 0.0:
		stunt_toast_timer -= delta
		if stunt_toast_timer <= 0.0:
			stunt_toast.visible = false

func _update_telemetry(_delta: float) -> void:
	var spd_kmh = player_vehicle.get_speed_kmh() if player_vehicle.has_method("get_speed_kmh") else 0.0
	speed_label.text = "%03d KM/H" % int(spd_kmh)

	var gear = player_vehicle.get_gear() if player_vehicle.has_method("get_gear") else 1
	gear_label.text = "R" if gear == -1 else ("N" if gear == 0 else str(gear))

	var rpm = player_vehicle.get_rpm() if player_vehicle.has_method("get_rpm") else 1000.0
	rpm_bar.value = rpm

	var nitro = player_vehicle.get_nitro_gauge() if player_vehicle.has_method("get_nitro_gauge") else 1.0
	nitro_bar.value = nitro * 100.0 if nitro <= 1.0 else nitro

	var hp = player_vehicle.get_health() if player_vehicle.has_method("get_health") else 100.0
	health_bar.value = hp

	# Wrecked / Respawn HUD banner
	if controls_guide_label:
		if ("is_wrecked" in player_vehicle and player_vehicle.is_wrecked) or hp <= 0.0:
			controls_guide_label.text = "⚠️ VEHICLE WRECKED! Press [R] to Repair & Respawn"
			controls_guide_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
		else:
			controls_guide_label.text = "[W/S] Throttle/Reverse  •  [A/D] Steer  •  [Space] Drift  •  [Shift] Boost  •  [R] Reset"
			controls_guide_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.85))

	# Check District Transition
	var p_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position
	var cur_dist = UrbanDistrictDefinitions.get_district_at_position(p_pos)
	if cur_dist != last_reported_district:
		last_reported_district = cur_dist
		var meta = UrbanDistrictDefinitions.get_district(cur_dist)
		district_label.text = meta.get("name", cur_dist).to_upper()
		show_district_banner(meta.get("name", cur_dist), meta.get("speed_limit_kmh", 80.0))

func show_district_banner(dist_name: String, speed_limit: float) -> void:
	if not district_banner:
		_setup_district_banner()
	if district_banner_label:
		district_banner_label.text = "DISTRICT: %s (LIMIT: %d KM/H)" % [dist_name.to_upper(), int(speed_limit)]
	if district_banner:
		district_banner.visible = true
	district_banner_timer = 3.5

func show_stunt_reward(title: String, cash: int) -> void:
	if not stunt_toast:
		_setup_stunt_toast()
	if stunt_title_label:
		stunt_title_label.text = title.to_upper()
	if stunt_cash_label:
		stunt_cash_label.text = "+$%d" % cash
	if stunt_toast:
		stunt_toast.visible = true
	stunt_toast_timer = 2.8

func update_wallet(cash: int) -> void:
	if not stats_card:
		_setup_progression_card()
	if cash_label:
		cash_label.text = "💵 $%d" % cash

func _update_responsive_layout(vp_size: Vector2) -> void:
	if vp_size.x <= 0 or vp_size.y <= 0:
		return

	# Top-Left: Minimap
	if minimap_container:
		minimap_container.position = Vector2(24, 20)

	# Top-Right: Stats Card
	if stats_card:
		stats_card.position = Vector2(vp_size.x - 220, 20)
		stats_card.custom_minimum_size = Vector2(196, 75)

	# Bottom-Right: Speedometer
	if speed_card:
		speed_card.position = Vector2(vp_size.x - 230, vp_size.y - 120)
		speed_card.custom_minimum_size = Vector2(206, 95)

	# Top-Center: District Banner
	if district_banner:
		district_banner.position = Vector2(vp_size.x * 0.5 - 180, 24)
		district_banner.custom_minimum_size = Vector2(360, 48)

	# Center: Stunt Toast
	if stunt_toast:
		stunt_toast.position = Vector2(vp_size.x * 0.5 - 160, vp_size.y * 0.35)
		stunt_toast.custom_minimum_size = Vector2(320, 60)

	# Controls Guide
	if controls_guide_panel:
		controls_guide_panel.position = Vector2(24, vp_size.y - 42)
		var is_touch = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
		controls_guide_panel.visible = not is_touch

	# Touch Controls Layout
	if touch_controls_root:
		btn_steer_left.position = Vector2(24, vp_size.y - 95)
		btn_steer_right.position = Vector2(104, vp_size.y - 95)

		btn_throttle.position = Vector2(vp_size.x - 95, vp_size.y - 195)
		btn_brake.position = Vector2(vp_size.x - 175, vp_size.y - 185)
		btn_handbrake.position = Vector2(vp_size.x - 175, vp_size.y - 250)
		btn_nitro.position = Vector2(vp_size.x - 95, vp_size.y - 265)
		btn_flip.position = Vector2(24, 210)
