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
	var world_radius: float = 220.0 # Meters represented in radar

	func _init(hud: UrbanHUD) -> void:
		hud_ref = hud
		custom_minimum_size = Vector2(160, 160)
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center = size * 0.5
		# Glass background
		draw_circle(center, radar_radius, Color(0.04, 0.08, 0.12, 0.85))
		draw_arc(center, radar_radius, 0, TAU, 48, Color(0.0, 0.88, 1.0, 0.6), 2.0)
		draw_arc(center, radar_radius * 0.5, 0, TAU, 32, Color(0.2, 0.4, 0.5, 0.25), 1.0)

		if not hud_ref or not is_instance_valid(hud_ref.player_vehicle):
			_draw_player_icon(center, 0.0)
			return

		var p_pos = hud_ref.player_vehicle.global_position if hud_ref.player_vehicle.is_inside_tree() else hud_ref.player_vehicle.position
		var p_rot = hud_ref.player_vehicle.rotation.y

		# Draw Roads
		if hud_ref.road_network and "segments" in hud_ref.road_network:
			for seg in hud_ref.road_network.segments:
				var st: Vector3 = seg["start"]
				var en: Vector3 = seg["end"]

				# Transform world pos to minimap local pos
				var p1 = _world_to_minimap(st, p_pos, p_rot, center)
				var p2 = _world_to_minimap(en, p_pos, p_rot, center)

				# Draw road lines clamped to circle
				if (p1 - center).length() <= radar_radius or (p2 - center).length() <= radar_radius:
					var road_col = Color(0.7, 0.75, 0.82, 0.7)
					if seg.get("is_freeway", false):
						road_col = Color(0.2, 0.9, 1.0, 0.9) # Neon cyan for flyovers
					elif seg.get("surface", 0) == 2:
						road_col = Color(0.3, 0.85, 0.4, 0.6) # Green for grass drift trails
					draw_line(p1, p2, road_col, 2.5)

		# Draw Stunt Kickers
		if hud_ref.player_vehicle.is_inside_tree():
			var kickers = hud_ref.player_vehicle.get_tree().get_nodes_in_group("stunt_ramps")
			for k in kickers:
				if is_instance_valid(k):
					var k_pos = k.global_position if k.is_inside_tree() else k.position
					var k_pt = _world_to_minimap(k_pos, p_pos, p_rot, center)
					if (k_pt - center).length() <= radar_radius - 4.0:
						draw_circle(k_pt, 3.5, Color(1.0, 0.8, 0.1, 0.9))

		# North Indicator on Ring
		var north_angle = -p_rot - PI * 0.5
		var north_pos = center + Vector2(cos(north_angle), sin(north_angle)) * (radar_radius - 8.0)
		draw_circle(north_pos, 4.0, Color(1.0, 0.25, 0.3, 0.95))

		# Player Vehicle Arrow at Center
		_draw_player_icon(center, 0.0)

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
		var arrow_pts = PackedVector2Array([
			center + Vector2(0, -9),
			center + Vector2(-6, 7),
			center + Vector2(0, 3),
			center + Vector2(6, 7)
		])
		draw_colored_polygon(arrow_pts, Color(0.0, 1.0, 0.85, 1.0))
		draw_polyline(arrow_pts, Color(1.0, 1.0, 1.0, 0.9), 1.5)

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

	# Check District Transition
	var p_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position
	var cur_dist = UrbanDistrictDefinitions.get_district_at_position(p_pos)
	if cur_dist != last_reported_district:
		last_reported_district = cur_dist
		var meta = UrbanDistrictDefinitions.get_district(cur_dist)
		district_label.text = meta.get("name", cur_dist).to_upper()
		show_district_banner(meta.get("name", cur_dist), meta.get("speed_limit_kmh", 80.0))

func show_district_banner(dist_name: String, speed_limit: float) -> void:
	district_banner_label.text = "DISTRICT: %s (LIMIT: %d KM/H)" % [dist_name.to_upper(), int(speed_limit)]
	district_banner.visible = true
	district_banner_timer = 3.5

func show_stunt_reward(title: String, cash: int) -> void:
	stunt_title_label.text = title.to_upper()
	stunt_cash_label.text = "+$%d" % cash
	stunt_toast.visible = true
	stunt_toast_timer = 2.8

func update_wallet(cash: int) -> void:
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

	# Touch Controls Layout
	if touch_controls_root:
		btn_steer_left.position = Vector2(24, vp_size.y - 95)
		btn_steer_right.position = Vector2(104, vp_size.y - 95)

		btn_throttle.position = Vector2(vp_size.x - 95, vp_size.y - 195)
		btn_brake.position = Vector2(vp_size.x - 175, vp_size.y - 185)
		btn_handbrake.position = Vector2(vp_size.x - 175, vp_size.y - 250)
		btn_nitro.position = Vector2(vp_size.x - 95, vp_size.y - 265)
		btn_flip.position = Vector2(24, 210)
