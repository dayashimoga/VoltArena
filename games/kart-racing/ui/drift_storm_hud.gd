class_name DriftStormHUD
extends Control

const PlatformCapabilities = preload("res://shared/platform/platform_capabilities.gd")
const TrackRegistry = preload("res://games/kart-racing/tracks/track_registry.gd")

## DriftStormHUD manages both the In-Race telemetry display and the
## dedicated full-screen pre-race state machine (DriftHome -> ModeSelect -> TrackSelect -> VehicleSelect -> RaceSetup -> Confirm).
## In-race HUD is strictly hidden during menus and only activates upon race start.

enum MenuState {
	HOME,
	MODE_SELECT,
	TRACK_SELECT,
	VEHICLE_SELECT,
	RACE_SETUP,
	CONFIRM
}

var current_menu_state: MenuState = MenuState.TRACK_SELECT

# In-Race HUD components
var in_race_hud_root: Control
var pos_panel: PanelContainer
var position_label: Label
var lap_label: Label
var speed_label: Label
var speed_bar: ProgressBar
var drift_bar: ProgressBar
var drift_label: Label
var powerup_panel: PanelContainer
var powerup_label: Label
var lap_time_label: Label
var best_lap_label: Label
var countdown_panel: PanelContainer
var countdown_label: Label
var gantry_lamps: Array[ColorRect] = []
var wrong_way_panel: PanelContainer
var wrong_way_label: Label
var finish_panel: PanelContainer
var finish_label: Label
var toast_container: VBoxContainer
var touch_controls: TouchControls
var objective_badge: Label
var obj_panel: PanelContainer
var right_panel: PanelContainer
var minimap_panel: PanelContainer
var minimap_canvas: Control

# Dedicated Pre-Race State Machine UI (Onboarding / Pre-Race Hub)
var onboarding_overlay: Control # Root of pre-race menu state machine
var pre_race_tab_bar: HBoxContainer
var pre_race_content_area: Control
var track_select_view: Control
var vehicle_select_view: Control
var mode_select_view: Control
var home_view: Control
var setup_view: Control
var confirm_view: Control

# Track Select Elements
var track_preview_canvas: Control
var track_info_name: Label
var track_info_theme: Label
var track_info_desc: Label
var track_info_stats: Label
var track_info_weather: Label
var track_info_record: Label
var track_info_reward: Label
var track_info_location: Label
var track_info_surface: Label

# Vehicle Select Elements
var veh_info_name: Label
var veh_info_class: Label
var veh_info_desc: Label

# Maps for external test and UI access
var track_btn_map: Dictionary = {}
var veh_btn_map: Dictionary = {}
var stat_bars: Dictionary = {}

var selected_track_id: String = "speedway"
var selected_vehicle_id: String = "speeder"
var selected_mode_id: String = "quick_race"
var selected_ai_count: int = 5
var selected_difficulty: String = "Medium"

const TRACK_METADATA: Dictionary = {
	"speedway": {
		"name": "Volt International Speedway",
		"location": "Volt Metropolis Sports Complex",
		"theme": "Stadium Super-Oval",
		"desc": "Premier floodlit stadium raceway with high-speed banking, safety walls, and packed grandstands.",
		"length": "755 m",
		"laps": "3 Laps",
		"diff": "Easy",
		"surface": "Competition PBR Asphalt & Kerbs",
		"weather": "Clear Floodlit Night",
		"time": "Night",
		"record": "00:42.5",
		"reward": "500 XP • Volt Racing Trophy",
		"accent": Color(0.0, 0.85, 1.0)
	},
	"sunset_coast": {
		"name": "Sunset Coast Highway",
		"location": "Pacific Riviera Coastal Highway",
		"theme": "Seaside Coastal Boulevard",
		"desc": "Sun-drenched coastal highway winding along dramatic ocean cliffs, golden sands, and resort oceanfronts.",
		"length": "820 m",
		"laps": "3 Laps",
		"diff": "Medium",
		"surface": "Coastal Tarmac & Sandy Runoff",
		"weather": "Golden Sunset Twilight",
		"time": "Sunset",
		"record": "00:45.8",
		"reward": "600 XP • Coastal Cruiser Livery",
		"accent": Color(1.0, 0.55, 0.20)
	},
	"canyon": {
		"name": "Redrock Canyon Pass",
		"location": "Mojave Sandstone Gorge",
		"theme": "Desert Sandstone Switchbacks",
		"desc": "High-speed desert canyon pass cut through towering sandstone arches, dusty switchbacks, and rock ravines.",
		"length": "785 m",
		"laps": "3 Laps",
		"diff": "Hard",
		"surface": "Desert Asphalt & Sandstone Rock",
		"weather": "High Noon Desert Heat Haze",
		"time": "Day",
		"record": "00:48.2",
		"reward": "750 XP • Dune Raider Chassis",
		"accent": Color(0.95, 0.35, 0.15)
	},
	"skyline": {
		"name": "Metro Night Expressway",
		"location": "Neo-Shinjuku Metropolitan Overpass",
		"theme": "Neon Cyber Expressway",
		"desc": "Midnight urban expressway threading through neon-lit skyscrapers, illuminated tunnels, and elevated plazas.",
		"length": "855 m",
		"laps": "3 Laps",
		"diff": "Medium",
		"surface": "Polished City Tarmac",
		"weather": "Midnight Neon Cyber Fog",
		"time": "Midnight",
		"record": "00:49.1",
		"reward": "800 XP • Neon Photon Wheel Kit",
		"accent": Color(0.80, 0.20, 1.0)
	},
	"alpine_rush": {
		"name": "Alpine Rush Mountain Pass",
		"location": "Bernese High Alpine Pass",
		"theme": "Alpine Peak Hairpins",
		"desc": "Scenic mountain circuit featuring steep climbs, snow peaks, dense pine forests, and technical hairpins.",
		"length": "830 m",
		"laps": "3 Laps",
		"diff": "Hard",
		"surface": "Alpine Asphalt & Curb Ribbons",
		"weather": "Alpine Frost Daylight",
		"time": "Morning",
		"record": "00:51.3",
		"reward": "900 XP • Icebreaker Titanium Rims",
		"accent": Color(0.30, 0.85, 0.95)
	},
	"storm_harbor": {
		"name": "Storm Harbor Shipyard",
		"location": "North Sea Industrial Container Port",
		"theme": "Industrial Container Docks",
		"desc": "Industrial shipyard raceway between towering cargo cranes, shipping containers, and storm surge tides.",
		"length": "790 m",
		"laps": "3 Laps",
		"diff": "Expert",
		"surface": "Wet Reflective Heavy Dock Tarmac",
		"weather": "Overcast Gale Squall Rain",
		"time": "Storm",
		"record": "00:47.4",
		"reward": "1000 XP • Harbor Master Title",
		"accent": Color(0.25, 0.65, 0.85)
	}
}

const VEHICLE_STATS: Dictionary = {
	"speeder": {
		"name": "Speeder (Pro Sprint Kart)",
		"class": "CIK-FIA Sprint Kart",
		"desc": "Ultra-lightweight competition sprint kart with direct steering, razor-sharp response, and explosive agility.",
		"speed": 82, "accel": 80, "handling": 90, "drift": 80, "boost": 80
	},
	"phantom": {
		"name": "Phantom (Street GT Tuner)",
		"class": "Modified Twin-Turbo Coupe",
		"desc": "Rear-wheel drive street tuner built for high-angle power slides, turbo recovery, and drift point multipliers.",
		"speed": 90, "accel": 75, "handling": 82, "drift": 96, "boost": 88
	},
	"enforcer": {
		"name": "Enforcer (Rally Buggy)",
		"class": "Long-Travel Off-Road Trophy",
		"desc": "Heavy-duty tubular spaceframe buggy with long-travel suspension, curb absorption, and brutal torque.",
		"speed": 78, "accel": 88, "handling": 76, "drift": 70, "boost": 75
	},
	"turbo_demon": {
		"name": "Turbo Demon (Hyper EV)",
		"class": "Quad-Motor Electric Prototype",
		"desc": "Torque-vectoring all-electric hypercar with instant throttle pickup and blisteringly fast straightaways.",
		"speed": 100, "accel": 92, "handling": 85, "drift": 75, "boost": 100
	},
	"formula": {
		"name": "Formula Apex (Formula GP)",
		"class": "Open-Wheel Aerodynamic Racer",
		"desc": "High-downforce open-wheel championship formula car with surgical braking, maximum grip, and aero stability.",
		"speed": 96, "accel": 100, "handling": 100, "drift": 85, "boost": 86
	}
}

# ------------------------------------------------------------------------------
# In-Race Minimap Canvas
# ------------------------------------------------------------------------------
class CircuitMinimapCanvas extends Control:
	var player_ref: Node3D = null
	var circuit_waypoints: Array = []

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.08, 0.12, 0.88), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.85, 1.0, 0.5), false, 1.5)

		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if not tree:
			return

		var tg = tree.root.find_child("TrackGenerator", true, false) if tree and tree.root else null
		var spline = tg.get("race_spline") if tg else null

		if spline and spline.samples.size() >= 10:
			if circuit_waypoints.is_empty():
				var n_pts = 64
				for j in range(n_pts):
					var s = (float(j) / float(n_pts)) * spline.track_length
					circuit_waypoints.append(spline.sample_at_distance(s)["pos"])
		elif circuit_waypoints.is_empty() and tg and not tg.waypoints.is_empty():
			circuit_waypoints = tg.waypoints

		if circuit_waypoints.size() < 3:
			return

		var min_x = 99999.0
		var max_x = -99999.0
		var min_z = 99999.0
		var max_z = -99999.0
		for wp in circuit_waypoints:
			min_x = minf(min_x, wp.x)
			max_x = maxf(max_x, wp.x)
			min_z = minf(min_z, wp.z)
			max_z = maxf(max_z, wp.z)

		var margin = 16.0
		var avail_w = size.x - margin * 2.0
		var avail_h = size.y - margin * 2.0
		var span_x = maxf(max_x - min_x, 10.0)
		var span_z = maxf(max_z - min_z, 10.0)
		var scale = minf(avail_w / span_x, avail_h / span_z)

		var center_x = (min_x + max_x) * 0.5
		var center_z = (min_z + max_z) * 0.5
		var canvas_center = size * 0.5

		var to_canvas = func(w_pos: Vector3) -> Vector2:
			var ox = (w_pos.x - center_x) * scale
			var oz = (w_pos.z - center_z) * scale
			return canvas_center + Vector2(ox, oz)

		var num_pts = circuit_waypoints.size()
		for i in range(num_pts):
			var p1 = to_canvas.call(circuit_waypoints[i])
			var p2 = to_canvas.call(circuit_waypoints[(i + 1) % num_pts])
			draw_line(p1, p2, Color(0.20, 0.48, 0.85, 0.95), 4.0)

		# Start/Finish line marker on map
		if num_pts > 0:
			var s_pos = to_canvas.call(circuit_waypoints[0])
			draw_circle(s_pos, 4.5, Color(1.0, 1.0, 1.0))

		# AI opponents
		var ai_colors = [
			Color(1.0, 0.45, 0.05), Color(0.95, 0.15, 0.25),
			Color(0.80, 0.20, 1.0), Color(0.20, 0.95, 0.35), Color(1.0, 0.85, 0.10)
		]
		var ai_list = tree.get_nodes_in_group("ai_racers")
		for idx in range(ai_list.size()):
			var ai = ai_list[idx]
			if is_instance_valid(ai):
				var ai_pos = to_canvas.call(ai.global_position)
				var c = ai_colors[idx % ai_colors.size()]
				draw_circle(ai_pos, 3.5, c)

		if not is_instance_valid(player_ref):
			var p_list = tree.get_nodes_in_group("players")
			if not p_list.is_empty():
				player_ref = p_list[0]

		if is_instance_valid(player_ref):
			var p_pos = to_canvas.call(player_ref.global_position)
			var p_fwd = -player_ref.global_transform.basis.z
			p_fwd.y = 0.0
			p_fwd = p_fwd.normalized()
			var p_arrow = Vector2(p_fwd.x, p_fwd.z) * 9.0
			draw_circle(p_pos, 5.0, Color(0.0, 0.95, 1.0))
			draw_line(p_pos, p_pos + p_arrow, Color(1.0, 1.0, 1.0), 2.5)

# ------------------------------------------------------------------------------
# Pre-Race Track Preview Vector Canvas
# ------------------------------------------------------------------------------
class TrackPreviewCanvas extends Control:
	var track_id: String = "speedway"

	func _draw() -> void:
		# Draw preview background card with atmospheric gradient
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.09, 0.95), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.85, 1.0, 0.4), false, 1.5)

		# Fetch track spline control nodes from TrackRegistry
		var t_def = TrackRegistry.get_track(track_id)
		if not t_def or t_def.nodes.is_empty():
			return

		var nodes = t_def.nodes
		var min_x = 99999.0
		var max_x = -99999.0
		var min_z = 99999.0
		var max_z = -99999.0
		for n in nodes:
			min_x = minf(min_x, n.x)
			max_x = maxf(max_x, n.x)
			min_z = minf(min_z, n.z)
			max_z = maxf(max_z, n.z)

		var margin = 28.0
		var avail_w = size.x - margin * 2.0
		var avail_h = size.y - margin * 2.0
		var span_x = maxf(max_x - min_x, 10.0)
		var span_z = maxf(max_z - min_z, 10.0)
		var scale = minf(avail_w / span_x, avail_h / span_z)

		var center_x = (min_x + max_x) * 0.5
		var center_z = (min_z + max_z) * 0.5
		var canvas_center = size * 0.5

		var to_canvas = func(w_pos: Vector3) -> Vector2:
			var ox = (w_pos.x - center_x) * scale
			var oz = (w_pos.z - center_z) * scale
			return canvas_center + Vector2(ox, oz)

		# Draw track circuit outer glow
		var num_nodes = nodes.size()
		for i in range(num_nodes):
			var p1 = to_canvas.call(nodes[i])
			var p2 = to_canvas.call(nodes[(i + 1) % num_nodes])
			draw_line(p1, p2, Color(0.0, 0.85, 1.0, 0.25), 8.0)

		# Draw primary circuit ribbon
		for i in range(num_nodes):
			var p1 = to_canvas.call(nodes[i])
			var p2 = to_canvas.call(nodes[(i + 1) % num_nodes])
			draw_line(p1, p2, Color(0.15, 0.70, 0.95, 0.95), 4.0)
			# Corner apex node markers
			draw_circle(p1, 3.5, Color(0.9, 0.95, 1.0, 0.8))

		# Start/Finish line checkered point
		if num_nodes > 0:
			var sf = to_canvas.call(nodes[0])
			draw_circle(sf, 6.0, Color(1.0, 1.0, 1.0))
			draw_circle(sf, 3.0, Color(0.0, 0.0, 0.0))

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGenerator.get_theme()
	if get_viewport():
		size = get_viewport().get_visible_rect().size
		if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
			get_viewport().size_changed.connect(_on_viewport_size_changed)
	else:
		size = Vector2(1280, 720)

	setup_hud_layout()
	_setup_minimap()
	check_mobile_controls()
	
	# Build the dedicated full-screen pre-race state machine UI
	setup_onboarding_overlay()
	
	# In-race HUD is hidden while in pre-race menus
	set_in_race_hud_visible(false)
	update_layout_positions()

func _on_viewport_size_changed() -> void:
	if get_viewport():
		size = get_viewport().get_visible_rect().size
		update_layout_positions()
		if track_preview_canvas:
			track_preview_canvas.queue_redraw()

func _process(_delta: float) -> void:
	if in_race_hud_root and in_race_hud_root.visible:
		if minimap_canvas and is_instance_valid(minimap_canvas):
			minimap_canvas.queue_redraw()

func set_in_race_hud_visible(p_visible: bool) -> void:
	if in_race_hud_root:
		in_race_hud_root.visible = p_visible
	if minimap_panel:
		minimap_panel.visible = p_visible
	if touch_controls:
		if p_visible:
			touch_controls.apply_platform_visibility()
		else:
			touch_controls.visible = false

# ------------------------------------------------------------------------------
# In-Race HUD Setup
# ------------------------------------------------------------------------------
func setup_hud_layout() -> void:
	in_race_hud_root = Control.new()
	in_race_hud_root.name = "InRaceHUDRoot"
	in_race_hud_root.anchor_right = 1.0
	in_race_hud_root.anchor_bottom = 1.0
	in_race_hud_root.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(in_race_hud_root)

	# Position & Lap Panel (Top-Left)
	pos_panel = PanelContainer.new()
	pos_panel.name = "PositionPanel"
	pos_panel.custom_minimum_size = Vector2(170, 85)
	in_race_hud_root.add_child(pos_panel)

	var pos_vbox = VBoxContainer.new()
	pos_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pos_panel.add_child(pos_vbox)

	var pos_hbox = HBoxContainer.new()
	pos_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pos_vbox.add_child(pos_hbox)

	var pos_prefix = Label.new()
	pos_prefix.text = "POS: "
	pos_prefix.add_theme_font_size_override("font_size", 16)
	pos_prefix.modulate = Color(0.7, 0.75, 0.8)
	pos_hbox.add_child(pos_prefix)

	position_label = Label.new()
	position_label.text = "1st"
	position_label.add_theme_font_size_override("font_size", 28)
	position_label.modulate = Color(1.0, 0.85, 0.1)
	pos_hbox.add_child(position_label)

	lap_label = Label.new()
	lap_label.text = "LAP 1 / 3"
	lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lap_label.add_theme_font_size_override("font_size", 16)
	lap_label.modulate = Color(0.2, 0.85, 1.0)
	pos_vbox.add_child(lap_label)

	# Objective Badge (Top-Center)
	obj_panel = PanelContainer.new()
	obj_panel.name = "ObjectivePanel"
	in_race_hud_root.add_child(obj_panel)

	objective_badge = Label.new()
	objective_badge.text = "OBJECTIVE: COMPLETE 3 LAPS — FINISH 1ST"
	objective_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_badge.add_theme_font_size_override("font_size", 12)
	objective_badge.modulate = Color(0.9, 0.95, 1.0)
	obj_panel.add_child(objective_badge)

	# Timing Panel (Top-Right)
	right_panel = PanelContainer.new()
	right_panel.name = "TimingPanel"
	right_panel.custom_minimum_size = Vector2(170, 75)
	in_race_hud_root.add_child(right_panel)

	var r_vbox = VBoxContainer.new()
	r_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_panel.add_child(r_vbox)

	lap_time_label = Label.new()
	lap_time_label.text = "TIME: 00:00.0"
	lap_time_label.add_theme_font_size_override("font_size", 14)
	lap_time_label.modulate = Color(0.9, 0.95, 1.0)
	r_vbox.add_child(lap_time_label)

	best_lap_label = Label.new()
	best_lap_label.text = "BEST: --:--.-"
	best_lap_label.add_theme_font_size_override("font_size", 13)
	best_lap_label.modulate = Color(0.2, 0.9, 0.4)
	r_vbox.add_child(best_lap_label)

	# Speed & Drift (Bottom-Right)
	var speed_box = VBoxContainer.new()
	speed_box.name = "SpeedBox"
	speed_box.anchor_left = 1.0
	speed_box.anchor_top = 1.0
	speed_box.anchor_right = 1.0
	speed_box.anchor_bottom = 1.0
	speed_box.offset_left = -230
	speed_box.offset_top = -140
	speed_box.offset_right = -24
	speed_box.offset_bottom = -24
	in_race_hud_root.add_child(speed_box)

	speed_label = Label.new()
	speed_label.text = "0 KM/H"
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_label.add_theme_font_size_override("font_size", 28)
	speed_label.modulate = Color(1.0, 1.0, 1.0)
	speed_box.add_child(speed_label)

	speed_bar = ProgressBar.new()
	speed_bar.custom_minimum_size = Vector2(180, 8)
	speed_bar.max_value = 180.0
	speed_bar.value = 0.0
	speed_bar.show_percentage = false
	speed_box.add_child(speed_bar)

	drift_label = Label.new()
	drift_label.text = "DRIFT CHARGE"
	drift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	drift_label.add_theme_font_size_override("font_size", 11)
	drift_label.modulate = Color(0.6, 0.6, 0.6)
	speed_box.add_child(drift_label)

	drift_bar = ProgressBar.new()
	drift_bar.custom_minimum_size = Vector2(180, 6)
	drift_bar.max_value = 3.0
	drift_bar.value = 0.0
	drift_bar.show_percentage = false
	speed_box.add_child(drift_bar)

	# Item/Powerup Box (Bottom-Center)
	powerup_panel = PanelContainer.new()
	powerup_panel.custom_minimum_size = Vector2(140, 48)
	powerup_panel.visible = false
	in_race_hud_root.add_child(powerup_panel)

	powerup_label = Label.new()
	powerup_label.text = "[ NO ITEM ]"
	powerup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	powerup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	powerup_label.add_theme_font_size_override("font_size", 14)
	powerup_panel.add_child(powerup_label)

	# Countdown & Gantry
	countdown_panel = PanelContainer.new()
	countdown_panel.custom_minimum_size = Vector2(280, 80)
	countdown_panel.visible = false
	in_race_hud_root.add_child(countdown_panel)

	var c_vbox = VBoxContainer.new()
	c_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	countdown_panel.add_child(c_vbox)

	var gantry_box = HBoxContainer.new()
	gantry_box.alignment = BoxContainer.ALIGNMENT_CENTER
	gantry_box.add_theme_constant_override("separation", 10)
	c_vbox.add_child(gantry_box)

	gantry_lamps.clear()
	for i in range(5):
		var lamp = ColorRect.new()
		lamp.custom_minimum_size = Vector2(22, 22)
		lamp.color = Color(0.15, 0.15, 0.18)
		gantry_box.add_child(lamp)
		gantry_lamps.append(lamp)

	countdown_label = Label.new()
	countdown_label.text = "READY"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 28)
	countdown_label.modulate = Color(1.0, 0.9, 0.2)
	c_vbox.add_child(countdown_label)

	# Wrong Way Banner
	wrong_way_panel = PanelContainer.new()
	wrong_way_panel.custom_minimum_size = Vector2(320, 60)
	wrong_way_panel.visible = false
	in_race_hud_root.add_child(wrong_way_panel)

	wrong_way_label = Label.new()
	wrong_way_label.text = "⚠️ WRONG WAY! TURN AROUND! ⚠️"
	wrong_way_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrong_way_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrong_way_label.add_theme_font_size_override("font_size", 16)
	wrong_way_label.modulate = Color(1.0, 0.2, 0.2)
	wrong_way_panel.add_child(wrong_way_label)

	# Finish Banner
	finish_panel = PanelContainer.new()
	finish_panel.custom_minimum_size = Vector2(360, 90)
	finish_panel.visible = false
	in_race_hud_root.add_child(finish_panel)

	finish_label = Label.new()
	finish_label.text = "🏁 RACE FINISHED! 🏁"
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_size_override("font_size", 26)
	finish_label.modulate = Color(0.2, 1.0, 0.5)
	finish_panel.add_child(finish_label)

	# Toasts
	toast_container = VBoxContainer.new()
	toast_container.anchor_top = 0.2
	toast_container.anchor_bottom = 0.5
	toast_container.offset_left = 32
	toast_container.offset_right = 320
	toast_container.mouse_filter = MOUSE_FILTER_IGNORE
	in_race_hud_root.add_child(toast_container)

func _setup_minimap() -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.custom_minimum_size = Vector2(176, 176)
	add_child(minimap_panel)

	minimap_canvas = CircuitMinimapCanvas.new()
	minimap_canvas.custom_minimum_size = Vector2(160, 160)
	minimap_panel.add_child(minimap_canvas)

func check_mobile_controls() -> void:
	touch_controls = TouchControls.new()
	touch_controls.set_genre(TouchControls.Genre.GENRE_RACING)
	add_child(touch_controls)

# ------------------------------------------------------------------------------
# DEDICATED PRE-RACE SCENE STATE MACHINE UI
# ------------------------------------------------------------------------------
func setup_onboarding_overlay() -> void:
	# Full-screen responsive root container
	onboarding_overlay = Control.new()
	onboarding_overlay.name = "OnboardingOverlay"
	onboarding_overlay.anchor_left = 0.0
	onboarding_overlay.anchor_top = 0.0
	onboarding_overlay.anchor_right = 1.0
	onboarding_overlay.anchor_bottom = 1.0
	onboarding_overlay.offset_left = 0
	onboarding_overlay.offset_top = 0
	onboarding_overlay.offset_right = 0
	onboarding_overlay.offset_bottom = 0
	add_child(onboarding_overlay)

	# Dark glassmorphic background filling entire screen
	var bg_panel = Panel.new()
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.03, 0.05, 0.09, 0.98)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	onboarding_overlay.add_child(bg_panel)

	# Main layout vbox with safe margins
	var main_vbox = VBoxContainer.new()
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 20
	main_vbox.offset_top = 16
	main_vbox.offset_right = -20
	main_vbox.offset_bottom = -16
	main_vbox.add_theme_constant_override("separation", 10)
	onboarding_overlay.add_child(main_vbox)

	# 1. Top Header Bar with Championship Title & Step Tabs
	var header_bar = HBoxContainer.new()
	header_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	header_bar.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header_bar)

	var title_lbl = Label.new()
	title_lbl.text = "⚡ DRIFT STORM GRAND PRIX ⚡"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.modulate = Color(0.2, 0.95, 1.0)
	header_bar.add_child(title_lbl)

	var spacer_h = Control.new()
	spacer_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(spacer_h)

	# Step Navigation Pills
	pre_race_tab_bar = HBoxContainer.new()
	pre_race_tab_bar.add_theme_constant_override("separation", 8)
	header_bar.add_child(pre_race_tab_bar)

	var tabs = [
		["1. TRACK", MenuState.TRACK_SELECT],
		["2. VEHICLE", MenuState.VEHICLE_SELECT],
		["3. SETUP", MenuState.RACE_SETUP],
		["4. CONFIRM", MenuState.CONFIRM]
	]
	for tab_info in tabs:
		var btn = Button.new()
		btn.text = tab_info[0]
		btn.custom_minimum_size = Vector2(90, 32)
		btn.add_theme_font_size_override("font_size", 11)
		var state_target: MenuState = tab_info[1]
		btn.pressed.connect(func(): transition_menu_state(state_target))
		pre_race_tab_bar.add_child(btn)

	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# 2. Scrollable Content Area for the active view
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	pre_race_content_area = VBoxContainer.new()
	pre_race_content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pre_race_content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pre_race_content_area.add_theme_constant_override("separation", 12)
	scroll.add_child(pre_race_content_area)

	# Build Individual Views
	_build_track_select_view()
	_build_vehicle_select_view()
	_build_race_setup_view()
	_build_confirm_view()

	# 3. Always-Visible Bottom Navigation Bar
	var bottom_bar = HBoxContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 48)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 24)
	main_vbox.add_child(bottom_bar)

	var launcher_btn = Button.new()
	launcher_btn.text = "⮌ RETURN TO LAUNCHER"
	launcher_btn.custom_minimum_size = PlatformCapabilities.get_min_touch_target_size()
	launcher_btn.custom_minimum_size.x = maxf(180.0, launcher_btn.custom_minimum_size.x)
	launcher_btn.add_theme_font_size_override("font_size", 12)
	launcher_btn.pressed.connect(func():
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus and bus.has_signal("return_to_launcher_requested"):
			bus.return_to_launcher_requested.emit()
	)
	bottom_bar.add_child(launcher_btn)

	var spacer_b = Control.new()
	spacer_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(spacer_b)

	var prev_btn = Button.new()
	prev_btn.text = "◀ PREVIOUS"
	prev_btn.custom_minimum_size = Vector2(130, 44)
	prev_btn.add_theme_font_size_override("font_size", 12)
	prev_btn.pressed.connect(_on_prev_step_pressed)
	bottom_bar.add_child(prev_btn)

	var continue_btn = Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "CONTINUE ▶"
	continue_btn.custom_minimum_size = Vector2(220, 44)
	continue_btn.add_theme_font_size_override("font_size", 13)
	continue_btn.modulate = Color(0.2, 0.95, 0.5)
	continue_btn.pressed.connect(_on_continue_step_pressed)
	bottom_bar.add_child(continue_btn)

	# Set initial view to Track Selection
	transition_menu_state(MenuState.TRACK_SELECT)

# ------------------------------------------------------------------------------
# VIEW 1: Track Selection View (Persists indefinitely until explicit user action)
# ------------------------------------------------------------------------------
func _build_track_select_view() -> void:
	track_select_view = VBoxContainer.new()
	track_select_view.name = "TrackSelectView"
	track_select_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_select_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_select_view.add_theme_constant_override("separation", 10)
	pre_race_content_area.add_child(track_select_view)

	# Track Selector Buttons Row (All 6 Circuits)
	var trk_hdr = Label.new()
	trk_hdr.text = "SELECT CHAMPIONSHIP CIRCUIT (6 AUTHENTIC ENVIRONMENTS)"
	trk_hdr.add_theme_font_size_override("font_size", 13)
	trk_hdr.modulate = Color(0.2, 0.9, 1.0)
	track_select_view.add_child(trk_hdr)

	var trk_box = HBoxContainer.new()
	trk_box.alignment = BoxContainer.ALIGNMENT_CENTER
	trk_box.add_theme_constant_override("separation", 8)
	track_select_view.add_child(trk_box)

	var tracks = [
		["VOLT SPEEDWAY", "speedway"],
		["SUNSET COAST", "sunset_coast"],
		["REDROCK CANYON", "canyon"],
		["METRO NIGHT", "skyline"],
		["ALPINE RUSH", "alpine_rush"],
		["STORM HARBOR", "storm_harbor"]
	]

	for t in tracks:
		var btn = Button.new()
		btn.text = t[0]
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(135, 36)
		track_btn_map[t[1]] = btn
		var t_id = t[1]
		btn.pressed.connect(func():
			_select_track_ui(t_id)
			var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree:
				var km = tree.root.find_child("KartRacingMain", true, false)
				if km and km.has_method("select_track"):
					km.select_track(t_id)
		)
		trk_box.add_child(btn)

	# Main Split Layout: Left = Large Vector Preview, Right = Comprehensive Metadata
	var split_box = HBoxContainer.new()
	split_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_box.add_theme_constant_override("separation", 16)
	track_select_view.add_child(split_box)

	# Left: Large Circuit Vector Map
	var map_panel = PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(280, 240)
	split_box.add_child(map_panel)

	track_preview_canvas = TrackPreviewCanvas.new()
	track_preview_canvas.name = "TrackPreviewCanvas"
	track_preview_canvas.custom_minimum_size = Vector2(270, 230)
	map_panel.add_child(track_preview_canvas)

	# Right: Metadata Card
	var meta_panel = PanelContainer.new()
	meta_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
	card_style.border_color = Color(0.15, 0.50, 0.80, 0.7)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(8)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	meta_panel.add_theme_stylebox_override("panel", card_style)
	split_box.add_child(meta_panel)

	var meta_vbox = VBoxContainer.new()
	meta_vbox.add_theme_constant_override("separation", 6)
	meta_panel.add_child(meta_vbox)

	var title_row = HBoxContainer.new()
	meta_vbox.add_child(title_row)

	track_info_name = Label.new()
	track_info_name.text = "Volt International Speedway"
	track_info_name.add_theme_font_size_override("font_size", 16)
	track_info_name.modulate = Color(1.0, 0.85, 0.2)
	title_row.add_child(track_info_name)

	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(sp)

	track_info_theme = Label.new()
	track_info_theme.text = "[Stadium Super-Oval]"
	track_info_theme.add_theme_font_size_override("font_size", 12)
	track_info_theme.modulate = Color(0.0, 0.9, 0.8)
	title_row.add_child(track_info_theme)

	track_info_location = Label.new()
	track_info_location.text = "Location: Volt Metropolis Sports Complex"
	track_info_location.add_theme_font_size_override("font_size", 11)
	track_info_location.modulate = Color(0.65, 0.80, 0.95)
	meta_vbox.add_child(track_info_location)

	track_info_desc = Label.new()
	track_info_desc.text = "Premier floodlit stadium raceway with high-speed banking, safety walls, and packed grandstands."
	track_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	track_info_desc.add_theme_font_size_override("font_size", 11)
	track_info_desc.modulate = Color(0.85, 0.90, 0.95)
	meta_vbox.add_child(track_info_desc)

	var grid_meta = GridContainer.new()
	grid_meta.columns = 2
	grid_meta.add_theme_constant_override("h_separation", 24)
	grid_meta.add_theme_constant_override("v_separation", 4)
	meta_vbox.add_child(grid_meta)

	track_info_stats = Label.new()
	track_info_stats.text = "Length: 755 m  •  3 Laps  •  Diff: Easy"
	track_info_stats.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_stats)

	track_info_surface = Label.new()
	track_info_surface.text = "Surface: PBR Asphalt & Kerbs"
	track_info_surface.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_surface)

	track_info_weather = Label.new()
	track_info_weather.text = "Atmosphere: Clear Floodlit Night"
	track_info_weather.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_weather)

	track_info_record = Label.new()
	track_info_record.text = "Track Record: 00:42.5"
	track_info_record.add_theme_font_size_override("font_size", 11)
	track_info_record.modulate = Color(0.4, 1.0, 0.5)
	grid_meta.add_child(track_info_record)

	track_info_reward = Label.new()
	track_info_reward.text = "Championship Reward: 500 XP • Volt Racing Trophy"
	track_info_reward.add_theme_font_size_override("font_size", 11)
	track_info_reward.modulate = Color(1.0, 0.8, 0.2)
	meta_vbox.add_child(track_info_reward)

	_select_track_ui("speedway")

# ------------------------------------------------------------------------------
# VIEW 2: Vehicle Selection View
# ------------------------------------------------------------------------------
func _build_vehicle_select_view() -> void:
	vehicle_select_view = VBoxContainer.new()
	vehicle_select_view.name = "VehicleSelectView"
	vehicle_select_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vehicle_select_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vehicle_select_view.add_theme_constant_override("separation", 10)
	pre_race_content_area.add_child(vehicle_select_view)

	var veh_hdr = Label.new()
	veh_hdr.text = "SELECT VEHICLE ARCHETYPE (5 POLISHED COMPETITION CLASSES)"
	veh_hdr.add_theme_font_size_override("font_size", 13)
	veh_hdr.modulate = Color(1.0, 0.8, 0.2)
	vehicle_select_view.add_child(veh_hdr)

	var veh_box = HBoxContainer.new()
	veh_box.alignment = BoxContainer.ALIGNMENT_CENTER
	veh_box.add_theme_constant_override("separation", 8)
	vehicle_select_view.add_child(veh_box)

	var vehs = [
		["SPEEDER (Pro Kart)", "speeder"],
		["PHANTOM (Tuner)", "phantom"],
		["ENFORCER (Buggy)", "enforcer"],
		["TURBO DEMON (EV)", "turbo_demon"],
		["FORMULA APEX", "formula"]
	]

	for v in vehs:
		var btn = Button.new()
		btn.text = v[0]
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(145, 36)
		veh_btn_map[v[1]] = btn
		var v_id = v[1]
		btn.pressed.connect(func():
			_select_vehicle_ui(v_id)
			var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree:
				var km = tree.root.find_child("KartRacingMain", true, false)
				if km and km.has_method("select_kart"):
					km.select_kart(v_id)
		)
		veh_box.add_child(btn)

	# Vehicle Info Card & Radar Bars
	var v_card = PanelContainer.new()
	v_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v_style = StyleBoxFlat.new()
	v_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
	v_style.border_color = Color(0.8, 0.6, 0.1, 0.7)
	v_style.set_border_width_all(1)
	v_style.set_corner_radius_all(8)
	v_style.content_margin_left = 16
	v_style.content_margin_right = 16
	v_style.content_margin_top = 12
	v_style.content_margin_bottom = 12
	v_card.add_theme_stylebox_override("panel", v_style)
	vehicle_select_view.add_child(v_card)

	var v_vbox = VBoxContainer.new()
	v_vbox.add_theme_constant_override("separation", 8)
	v_card.add_child(v_vbox)

	var v_top = HBoxContainer.new()
	v_vbox.add_child(v_top)

	veh_info_name = Label.new()
	veh_info_name.text = "Speeder (Pro Sprint Kart)"
	veh_info_name.add_theme_font_size_override("font_size", 16)
	veh_info_name.modulate = Color(1.0, 0.85, 0.2)
	v_top.add_child(veh_info_name)

	var sp_v = Control.new()
	sp_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_top.add_child(sp_v)

	veh_info_class = Label.new()
	veh_info_class.text = "[CIK-FIA Sprint Kart]"
	veh_info_class.add_theme_font_size_override("font_size", 12)
	veh_info_class.modulate = Color(0.2, 0.9, 1.0)
	v_top.add_child(veh_info_class)

	veh_info_desc = Label.new()
	veh_info_desc.text = "Ultra-lightweight competition sprint kart with direct steering, razor-sharp response, and explosive agility."
	veh_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	veh_info_desc.add_theme_font_size_override("font_size", 11)
	v_vbox.add_child(veh_info_desc)

	# Radar Performance Bars
	var stats_box = HBoxContainer.new()
	stats_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_box.add_theme_constant_override("separation", 16)
	v_vbox.add_child(stats_box)

	var stat_names = ["SPEED", "ACCEL", "HANDLING", "DRIFT", "BOOST"]
	for sn in stat_names:
		var s_item = VBoxContainer.new()
		s_item.alignment = BoxContainer.ALIGNMENT_CENTER
		var slbl = Label.new()
		slbl.text = sn
		slbl.add_theme_font_size_override("font_size", 10)
		slbl.modulate = Color(0.75, 0.85, 0.95)
		s_item.add_child(slbl)

		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(90, 8)
		bar.max_value = 100.0
		bar.value = 80.0
		bar.show_percentage = false
		s_item.add_child(bar)
		stats_box.add_child(s_item)
		stat_bars[sn.to_lower()] = bar

	_select_vehicle_ui("speeder")

# ------------------------------------------------------------------------------
# VIEW 3: Race Setup View
# ------------------------------------------------------------------------------
func _build_race_setup_view() -> void:
	setup_view = VBoxContainer.new()
	setup_view.name = "RaceSetupView"
	setup_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 12)
	pre_race_content_area.add_child(setup_view)

	var s_hdr = Label.new()
	s_hdr.text = "RACE & OPPONENT CONFIGURATION"
	s_hdr.add_theme_font_size_override("font_size", 13)
	s_hdr.modulate = Color(0.2, 0.9, 1.0)
	setup_view.add_child(s_hdr)

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
	style.border_color = Color(0.2, 0.6, 0.9, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	setup_view.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var row1 = HBoxContainer.new()
	vbox.add_child(row1)
	var lbl_ai = Label.new()
	lbl_ai.text = "AI Opponents Grid:"
	lbl_ai.custom_minimum_size = Vector2(180, 0)
	row1.add_child(lbl_ai)
	var val_ai = Label.new()
	val_ai.text = "5 Competitors (Apex Nova, Blaze Raptor, Viper Strike, Turbo Titan, Cyber Ghost)"
	val_ai.modulate = Color(0.3, 0.9, 1.0)
	row1.add_child(val_ai)

	var row2 = HBoxContainer.new()
	vbox.add_child(row2)
	var lbl_laps = Label.new()
	lbl_laps.text = "Race Distance:"
	lbl_laps.custom_minimum_size = Vector2(180, 0)
	row2.add_child(lbl_laps)
	var val_laps = Label.new()
	val_laps.text = "3 Laps (Regulation Grand Prix Sprint)"
	val_laps.modulate = Color(0.3, 0.9, 1.0)
	row2.add_child(val_laps)

	var row3 = HBoxContainer.new()
	vbox.add_child(row3)
	var lbl_diff = Label.new()
	lbl_diff.text = "AI Skill Level:"
	lbl_diff.custom_minimum_size = Vector2(180, 0)
	row3.add_child(lbl_diff)
	var val_diff = Label.new()
	val_diff.text = "Championship Pro (Dynamic Slipstream, Corner Defend & Recovery)"
	val_diff.modulate = Color(0.3, 0.9, 1.0)
	row3.add_child(val_diff)

# ------------------------------------------------------------------------------
# VIEW 4: Confirmation & Launch View
# ------------------------------------------------------------------------------
func _build_confirm_view() -> void:
	confirm_view = VBoxContainer.new()
	confirm_view.name = "ConfirmView"
	confirm_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	confirm_view.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_view.add_theme_constant_override("separation", 16)
	pre_race_content_area.add_child(confirm_view)

	var c_hdr = Label.new()
	c_hdr.text = "READY FOR KICKOFF — CONFIRM RACE START"
	c_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_hdr.add_theme_font_size_override("font_size", 16)
	c_hdr.modulate = Color(0.2, 0.95, 0.5)
	confirm_view.add_child(c_hdr)

	var summary_card = PanelContainer.new()
	summary_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.04, 0.08, 0.14, 0.96)
	s_style.border_color = Color(0.2, 0.8, 0.4, 0.8)
	s_style.set_border_width_all(2)
	s_style.set_corner_radius_all(10)
	s_style.content_margin_left = 24
	s_style.content_margin_right = 24
	s_style.content_margin_top = 16
	s_style.content_margin_bottom = 16
	summary_card.add_theme_stylebox_override("panel", s_style)
	confirm_view.add_child(summary_card)

	var s_vbox = VBoxContainer.new()
	s_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	s_vbox.add_theme_constant_override("separation", 8)
	summary_card.add_child(s_vbox)

	var sum_title = Label.new()
	sum_title.name = "SummaryTitle"
	sum_title.text = "🏁 VOLT INTERNATIONAL SPEEDWAY — 3 LAPS 🏁"
	sum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_title.add_theme_font_size_override("font_size", 16)
	sum_title.modulate = Color(1.0, 0.9, 0.2)
	s_vbox.add_child(sum_title)

	var sum_sub = Label.new()
	sum_sub.name = "SummarySubtitle"
	sum_sub.text = "Vehicle: Speeder (Pro Sprint Kart) • 5 AI Opponents • Grid Slot 1"
	sum_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_sub.add_theme_font_size_override("font_size", 12)
	sum_sub.modulate = Color(0.8, 0.9, 1.0)
	s_vbox.add_child(sum_sub)

	var start_action_btn = Button.new()
	start_action_btn.name = "StartRaceButton"
	start_action_btn.text = "▶▶ CONFIRM & START RACE ◀◀"
	start_action_btn.custom_minimum_size = Vector2(320, 52)
	start_action_btn.add_theme_font_size_override("font_size", 16)
	start_action_btn.modulate = Color(0.2, 1.0, 0.5)
	start_action_btn.pressed.connect(_on_start_race_clicked)
	confirm_view.add_child(start_action_btn)

# ------------------------------------------------------------------------------
# State Machine Transitions
# ------------------------------------------------------------------------------
func transition_menu_state(new_state: MenuState) -> void:
	current_menu_state = new_state

	if track_select_view: track_select_view.visible = (new_state == MenuState.TRACK_SELECT)
	if vehicle_select_view: vehicle_select_view.visible = (new_state == MenuState.VEHICLE_SELECT)
	if setup_view: setup_view.visible = (new_state == MenuState.RACE_SETUP)
	if confirm_view:
		confirm_view.visible = (new_state == MenuState.CONFIRM)
		_update_confirm_summary()

	# Highlight active tab button
	if pre_race_tab_bar:
		var tabs = [MenuState.TRACK_SELECT, MenuState.VEHICLE_SELECT, MenuState.RACE_SETUP, MenuState.CONFIRM]
		for i in range(min(tabs.size(), pre_race_tab_bar.get_child_count())):
			var btn = pre_race_tab_bar.get_child(i) as Button
			if btn:
				if tabs[i] == new_state:
					btn.modulate = Color(0.2, 1.0, 0.5)
				else:
					btn.modulate = Color(0.8, 0.85, 0.9)

func _on_prev_step_pressed() -> void:
	match current_menu_state:
		MenuState.CONFIRM:
			transition_menu_state(MenuState.RACE_SETUP)
		MenuState.RACE_SETUP:
			transition_menu_state(MenuState.VEHICLE_SELECT)
		MenuState.VEHICLE_SELECT:
			transition_menu_state(MenuState.TRACK_SELECT)
		MenuState.TRACK_SELECT, _:
			pass

func _on_continue_step_pressed() -> void:
	match current_menu_state:
		MenuState.TRACK_SELECT:
			transition_menu_state(MenuState.VEHICLE_SELECT)
		MenuState.VEHICLE_SELECT:
			transition_menu_state(MenuState.RACE_SETUP)
		MenuState.RACE_SETUP:
			transition_menu_state(MenuState.CONFIRM)
		MenuState.CONFIRM:
			_on_start_race_clicked()

func _update_confirm_summary() -> void:
	if not confirm_view:
		return
	var sum_title = confirm_view.find_child("SummaryTitle", true, false) as Label
	var sum_sub = confirm_view.find_child("SummarySubtitle", true, false) as Label
	if sum_title and TRACK_METADATA.has(selected_track_id):
		var t = TRACK_METADATA[selected_track_id]
		sum_title.text = "🏁 %s — %s 🏁" % [t["name"].to_upper(), t["laps"].to_upper()]
	if sum_sub and VEHICLE_STATS.has(selected_vehicle_id):
		var v = VEHICLE_STATS[selected_vehicle_id]
		sum_sub.text = "Vehicle: %s • 5 AI Opponents • Grid Slot 1" % v["name"]

func _on_start_race_clicked() -> void:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		var km = tree.root.find_child("KartRacingMain", true, false)
		if km and km.has_method("start_race"):
			km.start_race()
		else:
			dismiss_onboarding()

func _select_track_ui(track_id: String) -> void:
	selected_track_id = track_id
	for tid in track_btn_map.keys():
		var btn = track_btn_map[tid] as Button
		if tid == track_id:
			btn.modulate = Color(0.2, 1.0, 0.9)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85)

	if TRACK_METADATA.has(track_id):
		var meta = TRACK_METADATA[track_id]
		if track_info_name: track_info_name.text = meta["name"]
		if track_info_theme: track_info_theme.text = "[" + meta["theme"] + "]"
		if track_info_location: track_info_location.text = "Location: " + meta["location"]
		if track_info_desc: track_info_desc.text = meta["desc"]
		if track_info_stats: track_info_stats.text = "Length: %s  •  %s  •  Diff: %s" % [meta["length"], meta["laps"], meta["diff"]]
		if track_info_surface: track_info_surface.text = "Surface: " + meta["surface"]
		if track_info_weather: track_info_weather.text = "Atmosphere: " + meta["weather"]
		if track_info_record: track_info_record.text = "Track Record: " + meta["record"]
		if track_info_reward: track_info_reward.text = "Championship Reward: " + meta["reward"]

	if track_preview_canvas:
		track_preview_canvas.track_id = track_id
		track_preview_canvas.queue_redraw()

func _select_vehicle_ui(veh_id: String) -> void:
	selected_vehicle_id = veh_id
	for vid in veh_btn_map.keys():
		var btn = veh_btn_map[vid] as Button
		if vid == veh_id:
			btn.modulate = Color(1.0, 0.85, 0.2)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85)

	if VEHICLE_STATS.has(veh_id):
		var v = VEHICLE_STATS[veh_id]
		if veh_info_name: veh_info_name.text = v["name"]
		if veh_info_class: veh_info_class.text = "[" + v["class"] + "]"
		if veh_info_desc: veh_info_desc.text = v["desc"]
		_update_stat_bars(v)

func _update_stat_bars(stats: Dictionary) -> void:
	for k in stats.keys():
		if stat_bars.has(k):
			stat_bars[k].value = stats[k]

func dismiss_onboarding() -> void:
	if is_instance_valid(onboarding_overlay):
		onboarding_overlay.visible = false

func update_layout_positions() -> void:
	var vp_w = size.x
	var vp_h = size.y

	if pos_panel:
		pos_panel.position = Vector2(24, 24)
	if obj_panel:
		obj_panel.position = Vector2((vp_w - obj_panel.size.x) * 0.5, 24)
	if right_panel:
		right_panel.position = Vector2(vp_w - right_panel.size.x - 24, 24)
	if minimap_panel:
		minimap_panel.position = Vector2(24, vp_h - minimap_panel.size.y - 24)
	if powerup_panel:
		powerup_panel.position = Vector2((vp_w - powerup_panel.size.x) * 0.5, vp_h - powerup_panel.size.y - 30)
	if countdown_panel:
		countdown_panel.position = Vector2((vp_w - countdown_panel.size.x) * 0.5, vp_h * 0.28)
	if wrong_way_panel:
		wrong_way_panel.position = Vector2((vp_w - wrong_way_panel.size.x) * 0.5, vp_h * 0.42)
	if finish_panel:
		finish_panel.position = Vector2((vp_w - finish_panel.size.x) * 0.5, vp_h * 0.35)

# ------------------------------------------------------------------------------
# In-Race Telemetry Updates
# ------------------------------------------------------------------------------
func update_position(pos: int, _total: int = 4) -> void:
	if not position_label:
		return
	var suffixes = ["st", "nd", "rd", "th"]
	var idx = clampi(pos - 1, 0, suffixes.size() - 1)
	position_label.text = "%d%s" % [pos, suffixes[idx]]
	match pos:
		1: position_label.modulate = Color(1.0, 0.85, 0.1)
		2: position_label.modulate = Color(0.85, 0.9, 0.95)
		3: position_label.modulate = Color(0.9, 0.6, 0.3)
		_: position_label.modulate = Color(0.7, 0.75, 0.8)

func update_lap(cur_lap: int, max_laps: int = 3) -> void:
	if lap_label:
		lap_label.text = "LAP %d / %d" % [cur_lap, max_laps]

func update_speed(speed: float) -> void:
	var kmh = int(speed * 3.6)
	if speed_label:
		speed_label.text = "%d KM/H" % kmh
	if speed_bar:
		speed_bar.value = kmh

func update_drift_charge(charge: float, tier: int) -> void:
	if drift_bar:
		drift_bar.value = charge
	if drift_label:
		match tier:
			1: drift_label.modulate = Color(0.0, 0.8, 1.0)
			2: drift_label.modulate = Color(1.0, 0.5, 0.0)
			3: drift_label.modulate = Color(0.8, 0.1, 1.0)
			_: drift_label.modulate = Color(0.6, 0.6, 0.6)

func update_powerup(p_name: String) -> void:
	if not powerup_label or not powerup_panel:
		return
	if p_name.is_empty():
		powerup_panel.visible = false
		powerup_label.text = "[ NO ITEM ]"
		powerup_label.modulate = Color(0.6, 0.65, 0.75)
	else:
		powerup_panel.visible = true
		powerup_label.text = "[ %s ]" % p_name.to_upper()

func update_lap_times(cur_sec: float, best_sec: float) -> void:
	if lap_time_label:
		lap_time_label.text = "TIME: %s" % _format_time(cur_sec)
	if best_lap_label and best_sec < 900.0:
		best_lap_label.text = "BEST: %s" % _format_time(best_sec)

func set_wrong_way(wrong: bool) -> void:
	if wrong_way_panel and wrong_way_panel.visible != wrong:
		wrong_way_panel.visible = wrong

func show_countdown(val: Variant) -> void:
	if not countdown_panel or not countdown_label:
		return
	var text_val = str(val)
	countdown_label.text = text_val
	countdown_panel.visible = true

	var count_num = -1
	if text_val.is_valid_int():
		count_num = text_val.to_int()

	for idx in range(gantry_lamps.size()):
		var lamp = gantry_lamps[idx]
		if text_val == "GO!":
			lamp.color = Color(0.1, 1.0, 0.3)
		elif count_num > 0 and idx < (5 - count_num + 1):
			lamp.color = Color(1.0, 0.15, 0.15)
		else:
			lamp.color = Color(0.15, 0.15, 0.18)

	if text_val == "GO!":
		countdown_label.modulate = Color(0.2, 1.0, 0.4)
		var t = create_tween()
		t.tween_property(countdown_panel, "modulate:a", 0.0, 0.8).set_delay(0.6)
		t.tween_callback(func():
			countdown_panel.visible = false
			countdown_panel.modulate.a = 1.0
		)
	else:
		countdown_label.modulate = Color(1.0, 0.9, 0.2)

func show_finish(pos_text: String) -> void:
	if not finish_panel or not finish_label:
		return
	finish_label.text = "🏁 RACE FINISHED — %s! 🏁" % pos_text
	finish_panel.visible = true

func show_finish_banner(pos_text: String) -> void:
	show_finish(pos_text)

func _unhandled_input(_event: InputEvent) -> void:
	pass

func show_toast(msg: String, color: Color = Color.WHITE) -> void:
	if not toast_container:
		return
	var lbl = Label.new()
	lbl.text = msg
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 14)
	toast_container.add_child(lbl)
	var t = create_tween()
	t.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(2.0)
	t.tween_callback(lbl.queue_free)

func _format_time(sec: float) -> String:
	var mins = int(sec) / 60
	var s = int(sec) % 60
	var ms = int((sec - int(sec)) * 10.0)
	return "%02d:%02d.%01d" % [mins, s, ms]
