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
var track_info_corners: Label
var track_info_elevation: Label
var track_info_time: Label
var track_info_rec_veh: Label
var track_info_grip: Label
var track_info_style: Label

# 3D Track Preview
var track_3d_container: SubViewportContainer
var track_3d_viewport: SubViewport
var track_3d_camera: Camera3D
var track_3d_root: Node3D
var track_3d_light: DirectionalLight3D
var track_3d_rot_angle: float = 0.0
var track_preview_racer: Node3D
var preview_track_nodes: Array[Vector3] = []
var preview_track_center: Vector3 = Vector3.ZERO
var preview_track_scale: float = 1.0
var preview_racer_s: float = 0.0
var preview_track_len: float = 100.0

# Vehicle Select Elements
var veh_info_name: Label
var veh_info_class: Label
var veh_info_desc: Label
var veh_info_weight: Label
var veh_info_drivetrain: Label
var veh_info_driver: Label

# 3D Vehicle Turntable
var vehicle_3d_container: SubViewportContainer
var vehicle_3d_viewport: SubViewport
var vehicle_3d_camera: Camera3D
var vehicle_3d_turntable: Node3D
var vehicle_3d_model: Node3D
var vehicle_turntable_yaw: float = 0.0
var vehicle_turntable_pitch: float = 0.28
var vehicle_cam_distance: float = 4.2
var is_turntable_dragging: bool = false
var last_drag_pos: Vector2 = Vector2.ZERO
var selected_paint_color: Color = Color(0.0, 0.85, 1.0)
var paint_swatch_buttons: Array[Button] = []
var diff_buttons: Dictionary = {}

# Maps for external test and UI access
var track_btn_map: Dictionary = {}
var veh_btn_map: Dictionary = {}
var stat_bars: Dictionary = {}

var selected_track_id: String = "speedway"
var selected_vehicle_id: String = "speeder"
var selected_mode_id: String = "quick_race"
var selected_ai_count: int = 5
var selected_difficulty: String = "Normal"

const PAINT_SWATCHES: Array[Dictionary] = [
	{"name": "Volt Cyan", "color": Color(0.0, 0.85, 1.0)},
	{"name": "Blaze Orange", "color": Color(1.0, 0.45, 0.05)},
	{"name": "Crimson Red", "color": Color(0.95, 0.12, 0.18)},
	{"name": "Neon Purple", "color": Color(0.75, 0.15, 0.95)},
	{"name": "Solar Gold", "color": Color(1.0, 0.82, 0.10)},
	{"name": "Acid Green", "color": Color(0.25, 0.95, 0.35)},
	{"name": "Titanium Silver", "color": Color(0.78, 0.82, 0.88)},
	{"name": "Stealth Black", "color": Color(0.12, 0.14, 0.18)}
]

const TRACK_METADATA: Dictionary = {
	"speedway": {
		"name": "Volt International Speedway",
		"location": "Volt Metropolis Sports Complex",
		"theme": "Stadium Super-Oval",
		"desc": "Premier floodlit stadium raceway with high-speed banking, safety walls, and packed grandstands.",
		"length": "880 m",
		"laps": "3 Laps",
		"corners": "14 Corners",
		"elevation": "4 m (Banked Turns)",
		"diff": "Easy",
		"surface": "Competition PBR Asphalt & Kerbs",
		"weather": "Clear Floodlit Night",
		"time": "Night (21:00)",
		"record": "00:42.5",
		"reward": "500 XP • Volt Racing Trophy",
		"rec_vehicle": "Formula Apex / Hyper EV (High Downforce)",
		"grip": "100% (Dry Competition Asphalt)",
		"style": "Banked Super-Oval & Technical Infield",
		"marshals": "8 Marshalling Posts",
		"accent": Color(0.0, 0.85, 1.0)
	},
	"sunset_coast": {
		"name": "Sunset Coast Highway",
		"location": "Pacific Riviera Coastal Boulevard",
		"theme": "Seaside Coastal Boulevard",
		"desc": "Sun-drenched coastal highway winding along dramatic ocean cliffs, golden sands, and resort oceanfronts.",
		"length": "960 m",
		"laps": "3 Laps",
		"corners": "11 Corners",
		"elevation": "18 m (Clifftop Rise)",
		"diff": "Medium",
		"surface": "Coastal Marine Asphalt & Blue/White Kerbs",
		"weather": "Golden Sunset Twilight",
		"time": "Sunset (19:45)",
		"record": "00:44.8",
		"reward": "600 XP • Coastal Cruiser Livery",
		"rec_vehicle": "Phantom GT / Speeder (High Drift Agility)",
		"grip": "96% (Coastal Marine Tarmac)",
		"style": "Sweeping Ocean Highway & Suspension Bridge",
		"marshals": "6 Marshalling Posts",
		"accent": Color(1.0, 0.55, 0.20)
	},
	"canyon": {
		"name": "Redrock Canyon Pass",
		"location": "Mojave Sandstone Gorge",
		"theme": "Desert Sandstone Switchbacks",
		"desc": "High-speed desert canyon pass cut through towering sandstone arches, dusty switchbacks, and rock ravines.",
		"length": "850 m",
		"laps": "3 Laps",
		"corners": "16 Corners",
		"elevation": "28 m (Mesa Climb)",
		"diff": "Hard",
		"surface": "Rough Sandstone Tarmac & Runoff Gravel",
		"weather": "High Noon Desert Heat Haze",
		"time": "High Noon (13:15)",
		"record": "00:41.2",
		"reward": "750 XP • Canyon Raider Trophy",
		"rec_vehicle": "Dune Enforcer (Torque & Long Suspension)",
		"grip": "92% (Desert Dust Runoff)",
		"style": "Elevation Switchbacks & Sandstone Arches",
		"marshals": "6 Marshalling Posts",
		"accent": Color(0.95, 0.35, 0.15)
	},
	"skyline": {
		"name": "Metro Night Expressway",
		"location": "Neo-Shinjuku Metropolitan Overpass",
		"theme": "Neon Cyber Expressway",
		"desc": "Midnight urban expressway threading through neon-lit skyscrapers, illuminated tunnels, and elevated plazas.",
		"length": "920 m",
		"laps": "3 Laps",
		"corners": "15 Corners",
		"elevation": "12 m (Viaduct Elevation)",
		"diff": "Medium",
		"surface": "Polished City Tarmac & Neon Curbs",
		"weather": "Midnight Neon Cyber Fog",
		"time": "Midnight (00:00)",
		"record": "00:43.7",
		"reward": "800 XP • Neon Photon Wheel Kit",
		"rec_vehicle": "Hyper EV / Phantom GT (Instant Acceleration)",
		"grip": "95% (Reflective Urban Asphalt)",
		"style": "High-Altitude Viaduct & 90° Corners",
		"marshals": "8 Marshalling Posts",
		"accent": Color(0.80, 0.20, 1.0)
	},
	"alpine_rush": {
		"name": "Alpine Rush Mountain Pass",
		"location": "Bernese High Alpine Pass",
		"theme": "Alpine Peak Hairpins",
		"desc": "Scenic mountain circuit featuring steep climbs, snow peaks, dense pine forests, and technical hairpins.",
		"length": "940 m",
		"laps": "3 Laps",
		"corners": "18 Corners",
		"elevation": "34 m (Alpine Switchbacks)",
		"diff": "Hard",
		"surface": "Alpine Asphalt & Snow Runoff",
		"weather": "Alpine Frost Daylight",
		"time": "Morning (08:30)",
		"record": "00:46.3",
		"reward": "900 XP • Icebreaker Titanium Rims",
		"rec_vehicle": "Formula Apex / Speeder (Maximum Grip & Sharp Turn-in)",
		"grip": "89% (Cold Tarmac & Snow Patches)",
		"style": "Technical Mountain Hairpins & Downhill",
		"marshals": "7 Marshalling Posts",
		"accent": Color(0.30, 0.85, 0.95)
	},
	"storm_harbor": {
		"name": "Storm Harbor Shipyard",
		"location": "North Sea Industrial Container Port",
		"theme": "Industrial Container Docks",
		"desc": "Industrial shipyard raceway between towering cargo cranes, shipping containers, and storm surge tides.",
		"length": "860 m",
		"laps": "3 Laps",
		"corners": "12 Corners",
		"elevation": "2 m (Sea Level Dock)",
		"diff": "Expert",
		"surface": "Wet Reflective Heavy Dock Tarmac & Puddles",
		"weather": "Overcast Gale Squall Rain",
		"time": "Storm Twilight (17:30)",
		"record": "00:44.1",
		"reward": "1000 XP • Harbor Master Title",
		"rec_vehicle": "Dune Enforcer / Phantom GT (Wet Traction & Recovery)",
		"grip": "84% (Standing Puddles & Wet Slick)",
		"style": "Chicanes Through Freight Canyons",
		"marshals": "6 Marshalling Posts",
		"accent": Color(0.25, 0.65, 0.85)
	}
}

const VEHICLE_STATS: Dictionary = {
	"speeder": {
		"name": "Speeder (CIK-FIA Sprint Kart)",
		"class": "CIK-FIA 125cc Shifter Kart",
		"desc": "Ultra-lightweight competition sprint kart with direct steering, razor-sharp response, and explosive agility.",
		"speed": 82, "accel": 80, "braking": 88, "handling": 95, "drift": 80, "boost": 78,
		"weight": "165 kg (Ultralight Spaceframe)",
		"drivetrain": "RWD Direct Single-Gear",
		"driver": "Pro FIA Nomex • Carbon Helmet & Tinted Visor"
	},
	"phantom": {
		"name": "Phantom (Street GT Tuner)",
		"class": "Widebody Twin-Turbo Drift Coupe",
		"desc": "Rear-wheel drive street tuner built for high-angle power slides, turbo recovery, and drift point multipliers.",
		"speed": 90, "accel": 75, "braking": 84, "handling": 82, "drift": 96, "boost": 88,
		"weight": "1,220 kg (Carbon Fiber Widebody)",
		"drivetrain": "RWD Twin-Turbo Mechanical LSD",
		"driver": "FIA Rollcage • Racing Bucket & Harness"
	},
	"enforcer": {
		"name": "Enforcer (Dakar Rally Buggy)",
		"class": "Long-Travel Off-Road Trophy Rail",
		"desc": "Heavy-duty tubular spaceframe buggy with long-travel coilover suspension, curb absorption, and brutal torque.",
		"speed": 78, "accel": 88, "braking": 82, "handling": 76, "drift": 70, "boost": 75,
		"weight": "1,480 kg (Chromoly Steel Cage)",
		"drivetrain": "4WD Dual Locking Differentials",
		"driver": "Dust Goggles • Dual Spare Tire Bed Rack"
	},
	"turbo_demon": {
		"name": "Turbo Demon (Hyper EV)",
		"class": "Le Mans Prototype Cyber Hypercar",
		"desc": "Torque-vectoring all-electric hypercar with instant throttle pickup, active aerodynamics, and blisteringly fast straightaways.",
		"speed": 100, "accel": 96, "braking": 92, "handling": 85, "drift": 75, "boost": 100,
		"weight": "1,650 kg (Low-CG Battery Pack)",
		"drivetrain": "AWD Quad-Motor Torque Vectoring",
		"driver": "Full Teardrop Canopy • HUD Digital Dash"
	},
	"formula": {
		"name": "Formula Apex (Formula GP)",
		"class": "Open-Wheel Aerodynamic Grand Prix",
		"desc": "High-downforce open-wheel championship formula car with surgical braking, maximum grip, and aero stability.",
		"speed": 96, "accel": 100, "braking": 100, "handling": 100, "drift": 85, "boost": 86,
		"weight": "798 kg (Carbon Fiber Monocoque)",
		"drivetrain": "RWD V6 Turbo-Hybrid Paddle Shift",
		"driver": "Titanium Halo • Multi-Function Wheel"
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
			circuit_waypoints.clear()
			var n_pts = 64
			for j in range(n_pts):
				var s = (float(j) / float(n_pts)) * spline.track_length
				circuit_waypoints.append(spline.sample_at_distance(s)["pos"])
		elif tg and not tg.waypoints.is_empty():
			circuit_waypoints = tg.waypoints.duplicate()

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

func _process(delta: float) -> void:
	if in_race_hud_root and in_race_hud_root.visible:
		if minimap_canvas and is_instance_valid(minimap_canvas):
			minimap_canvas.queue_redraw()
	elif is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		# 1. Track Select: Animate 3D fly-through orbital camera and mini racer
		if current_menu_state == MenuState.TRACK_SELECT:
			track_3d_rot_angle += delta * 0.26
			if track_3d_camera:
				var cam_dist = 44.0
				var cam_h = 28.0
				track_3d_camera.position = Vector3(sin(track_3d_rot_angle) * cam_dist, cam_h, cos(track_3d_rot_angle) * cam_dist)
				track_3d_camera.look_at(Vector3.ZERO, Vector3.UP)
			if track_preview_racer and preview_track_nodes.size() > 1:
				preview_racer_s = fposmod(preview_racer_s + delta * 24.0, maxf(preview_track_len, 1.0))
				_update_preview_racer_pos(preview_racer_s)
		# 2. Vehicle Select: Animate 3D showroom turntable and update camera distance/pitch
		elif current_menu_state == MenuState.VEHICLE_SELECT:
			if not is_turntable_dragging:
				vehicle_turntable_yaw += delta * 0.42
			if vehicle_3d_turntable:
				vehicle_3d_turntable.rotation.y = vehicle_turntable_yaw
			if vehicle_3d_camera:
				var h = vehicle_cam_distance * sin(vehicle_turntable_pitch)
				var d = vehicle_cam_distance * cos(vehicle_turntable_pitch)
				vehicle_3d_camera.position = Vector3(0, h + 0.35, d)
				vehicle_3d_camera.look_at(Vector3(0, 0.45, 0), Vector3.UP)

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

	# Main Split Layout: Left = 3D Fly-through Viewport + 2D Vector Map, Right = Comprehensive 14-Parameter Dossier
	var split_box = HBoxContainer.new()
	split_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_box.add_theme_constant_override("separation", 16)
	track_select_view.add_child(split_box)

	# Left Column: 3D Preview + 2D Vector Map
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(330, 0)
	left_col.add_theme_constant_override("separation", 8)
	split_box.add_child(left_col)

	# 3D Viewport Box
	_setup_3d_track_preview(left_col)

	# 2D Vector Map Panel
	var map_panel = PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(330, 115)
	left_col.add_child(map_panel)

	track_preview_canvas = TrackPreviewCanvas.new()
	track_preview_canvas.name = "TrackPreviewCanvas"
	track_preview_canvas.custom_minimum_size = Vector2(320, 105)
	map_panel.add_child(track_preview_canvas)

	# Right Column: Comprehensive 14-Parameter Dossier Card
	var meta_panel = PanelContainer.new()
	meta_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
	card_style.border_color = Color(0.15, 0.50, 0.80, 0.7)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(8)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	meta_panel.add_theme_stylebox_override("panel", card_style)
	split_box.add_child(meta_panel)

	var meta_vbox = VBoxContainer.new()
	meta_vbox.add_theme_constant_override("separation", 5)
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

	var sep_meta = HSeparator.new()
	meta_vbox.add_child(sep_meta)

	# 14-Parameter Grid
	var grid_meta = GridContainer.new()
	grid_meta.columns = 2
	grid_meta.add_theme_constant_override("h_separation", 24)
	grid_meta.add_theme_constant_override("v_separation", 4)
	meta_vbox.add_child(grid_meta)

	track_info_stats = Label.new()
	track_info_stats.text = "Length: 880 m  •  3 Laps  •  Diff: Easy"
	track_info_stats.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_stats)

	track_info_surface = Label.new()
	track_info_surface.text = "Surface: PBR Asphalt & Kerbs"
	track_info_surface.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_surface)

	track_info_corners = Label.new()
	track_info_corners.text = "Corners: 14 Corners"
	track_info_corners.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_corners)

	track_info_elevation = Label.new()
	track_info_elevation.text = "Elevation: 4 m (Banked Turns)"
	track_info_elevation.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_elevation)

	track_info_weather = Label.new()
	track_info_weather.text = "Atmosphere: Clear Floodlit Night"
	track_info_weather.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_weather)

	track_info_time = Label.new()
	track_info_time.text = "Time of Day: Night (21:00)"
	track_info_time.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_time)

	track_info_record = Label.new()
	track_info_record.text = "Track Record: 00:42.5"
	track_info_record.add_theme_font_size_override("font_size", 11)
	track_info_record.modulate = Color(0.4, 1.0, 0.5)
	grid_meta.add_child(track_info_record)

	track_info_grip = Label.new()
	track_info_grip.text = "Traction Index: 100% (High Grip)"
	track_info_grip.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_grip)

	track_info_style = Label.new()
	track_info_style.text = "Layout: Banked Super-Oval & Infield"
	track_info_style.add_theme_font_size_override("font_size", 11)
	grid_meta.add_child(track_info_style)

	track_info_rec_veh = Label.new()
	track_info_rec_veh.text = "Recommended: Formula Apex / Hyper EV"
	track_info_rec_veh.add_theme_font_size_override("font_size", 11)
	track_info_rec_veh.modulate = Color(0.2, 0.9, 1.0)
	grid_meta.add_child(track_info_rec_veh)

	track_info_reward = Label.new()
	track_info_reward.text = "Championship Reward: 500 XP • Volt Racing Trophy"
	track_info_reward.add_theme_font_size_override("font_size", 11)
	track_info_reward.modulate = Color(1.0, 0.8, 0.2)
	meta_vbox.add_child(track_info_reward)

	_select_track_ui("speedway")

func _setup_3d_track_preview(parent: Control) -> void:
	var vp_box = VBoxContainer.new()
	vp_box.custom_minimum_size = Vector2(330, 185)
	vp_box.add_theme_constant_override("separation", 2)
	parent.add_child(vp_box)

	var vp_hdr = Label.new()
	vp_hdr.text = "REAL-TIME 3D CIRCUIT PREVIEW & FLYTHROUGH"
	vp_hdr.add_theme_font_size_override("font_size", 10)
	vp_hdr.modulate = Color(0.2, 0.9, 1.0)
	vp_box.add_child(vp_hdr)

	track_3d_container = SubViewportContainer.new()
	track_3d_container.custom_minimum_size = Vector2(330, 165)
	track_3d_container.stretch = true
	vp_box.add_child(track_3d_container)

	track_3d_viewport = SubViewport.new()
	track_3d_viewport.own_world_3d = true
	track_3d_viewport.size = Vector2i(330, 165)
	track_3d_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	track_3d_container.add_child(track_3d_viewport)

	track_3d_camera = Camera3D.new()
	track_3d_camera.current = true
	track_3d_camera.fov = 50.0
	track_3d_camera.position = Vector3(0, 28, 44)
	track_3d_camera.look_at(Vector3.ZERO, Vector3.UP)
	track_3d_viewport.add_child(track_3d_camera)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.04, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.60, 0.65, 0.75)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	track_3d_viewport.add_child(env_node)

	track_3d_light = DirectionalLight3D.new()
	track_3d_light.position = Vector3(15, 30, 20)
	track_3d_light.look_at_from_position(Vector3(15, 30, 20), Vector3.ZERO, Vector3.UP)
	track_3d_light.light_color = Color(1.0, 0.95, 0.90)
	track_3d_light.light_energy = 1.4
	track_3d_viewport.add_child(track_3d_light)

	track_3d_root = Node3D.new()
	track_3d_root.name = "TrackPreviewScene"
	track_3d_viewport.add_child(track_3d_root)

func _update_3d_track_preview(track_id: String) -> void:
	if not track_3d_root or not is_instance_valid(track_3d_root):
		return
	for c in track_3d_root.get_children():
		c.queue_free()

	var t_def = TrackRegistry.get_track(track_id)
	if not t_def or t_def.nodes.is_empty():
		return

	var nodes = t_def.nodes
	var min_x = 99999.0; var max_x = -99999.0
	var min_z = 99999.0; var max_z = -99999.0
	for p in nodes:
		min_x = minf(min_x, p.x); max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.z); max_z = maxf(max_z, p.z)

	preview_track_center = Vector3((min_x + max_x) * 0.5, 0, (min_z + max_z) * 0.5)
	var span = maxf(max_x - min_x, max_z - min_z)
	preview_track_scale = 46.0 / maxf(span, 1.0)

	preview_track_nodes.clear()
	for p in nodes:
		var sp = (p - preview_track_center) * preview_track_scale
		sp.y = p.y * preview_track_scale * 0.4
		preview_track_nodes.append(sp)

	# Build track mesh ribbon
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_pts = preview_track_nodes.size()
	var road_w = 1.7
	var curb_w = 0.4

	preview_track_len = 0.0
	for i in range(n_pts):
		preview_track_len += preview_track_nodes[i].distance_to(preview_track_nodes[(i + 1) % n_pts])

	# 1. Road ribbon & Curbs
	for i in range(n_pts):
		var p1 = preview_track_nodes[i]
		var p2 = preview_track_nodes[(i + 1) % n_pts]
		var tan_dir = (p2 - p1).normalized()
		var bin_dir = tan_dir.cross(Vector3.UP).normalized()

		var p1_l = p1 - bin_dir * road_w
		var p1_r = p1 + bin_dir * road_w
		var p2_l = p2 - bin_dir * road_w
		var p2_r = p2 + bin_dir * road_w

		# Road surface
		st.set_color(Color(0.12, 0.13, 0.15))
		st.set_normal(Vector3.UP)
		st.add_vertex(p1_l); st.add_vertex(p1_r); st.add_vertex(p2_l)
		st.add_vertex(p1_r); st.add_vertex(p2_r); st.add_vertex(p2_l)

		# Left Kerb
		var curb_col = Color(0.9, 0.2, 0.2) if (i % 2 == 0) else Color(0.95, 0.95, 0.95)
		if track_id == "speedway" or track_id == "skyline":
			curb_col = Color(0.1, 0.5, 0.9) if (i % 2 == 0) else Color(0.95, 0.95, 0.95)
		st.set_color(curb_col)
		st.set_normal(Vector3.UP)
		st.add_vertex(p1_l - bin_dir * curb_w); st.add_vertex(p1_l); st.add_vertex(p2_l - bin_dir * curb_w)
		st.add_vertex(p1_l); st.add_vertex(p2_l); st.add_vertex(p2_l - bin_dir * curb_w)

		# Right Kerb
		st.set_color(curb_col)
		st.set_normal(Vector3.UP)
		st.add_vertex(p1_r); st.add_vertex(p1_r + bin_dir * curb_w); st.add_vertex(p2_r)
		st.add_vertex(p1_r + bin_dir * curb_w); st.add_vertex(p2_r + bin_dir * curb_w); st.add_vertex(p2_r)

	st.generate_normals()
	var track_mesh = st.commit()
	var track_inst = MeshInstance3D.new()
	track_inst.mesh = track_mesh
	var mat_track = StandardMaterial3D.new()
	mat_track.vertex_color_use_as_albedo = true
	mat_track.roughness = 0.85
	track_inst.material_override = mat_track
	track_3d_root.add_child(track_inst)

	# 2. Start/Finish Line
	if n_pts > 0:
		var sf_quad = MeshInstance3D.new()
		var sf_mesh = QuadMesh.new()
		sf_mesh.size = Vector2(road_w * 2.0, 0.8)
		sf_mesh.orientation = PlaneMesh.FACE_Y
		sf_quad.mesh = sf_mesh
		sf_quad.position = preview_track_nodes[0] + Vector3(0, 0.04, 0)
		sf_quad.material_override = MaterialGenerator.get_material("checkered_flag")
		track_3d_root.add_child(sf_quad)

	# 3. Thematic Scenery & Terrain
	_build_preview_thematic_scenery(track_id)

	# 4. Animated mini racer on track
	track_preview_racer = Node3D.new()
	var r_mesh_inst = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.6, 0.35, 1.1)
	r_mesh_inst.mesh = r_box
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.0, 0.9, 1.0)
	r_mat.emission_enabled = true
	r_mat.emission = Color(0.0, 0.85, 1.0)
	r_mat.emission_energy_multiplier = 2.0
	r_mesh_inst.material_override = r_mat
	track_preview_racer.add_child(r_mesh_inst)
	track_3d_root.add_child(track_preview_racer)
	preview_racer_s = 0.0
	_update_preview_racer_pos(0.0)

func _build_preview_thematic_scenery(track_id: String) -> void:
	match track_id:
		"sunset_coast":
			var water = MeshInstance3D.new()
			var w_mesh = BoxMesh.new(); w_mesh.size = Vector3(90, 0.5, 90)
			water.mesh = w_mesh
			water.position = Vector3(0, -0.6, 0)
			water.material_override = MaterialGenerator.get_material("ocean_water")
			track_3d_root.add_child(water)
			for i in range(12):
				var angle = i * (TAU / 12.0)
				var tree = MeshBuilder.build_palm_tree(4.0)
				tree.position = Vector3(cos(angle) * 26.0, -0.2, sin(angle) * 26.0)
				track_3d_root.add_child(tree)
			var tower = MeshBuilder.build_suspension_bridge_tower(16.0)
			tower.position = Vector3(15, 0, -20)
			track_3d_root.add_child(tower)
			if track_3d_light:
				track_3d_light.light_color = Color(1.0, 0.65, 0.30)
				track_3d_light.light_energy = 1.6
		"canyon":
			var ground = MeshInstance3D.new()
			var g_mesh = BoxMesh.new(); g_mesh.size = Vector3(90, 0.5, 90)
			ground.mesh = g_mesh
			ground.position = Vector3(0, -0.6, 0)
			ground.material_override = MaterialGenerator.get_material("canyon_rock")
			track_3d_root.add_child(ground)
			var mesa_positions = [Vector3(-18, 0, -15), Vector3(20, 0, -12), Vector3(-15, 0, 18), Vector3(22, 0, 16), Vector3(0, 0, 24)]
			for mp in mesa_positions:
				var mesa = MeshInstance3D.new()
				var mb = BoxMesh.new(); mb.size = Vector3(8, 7, 8)
				mesa.mesh = mb
				mesa.position = mp + Vector3(0, 3.5, 0)
				mesa.material_override = MaterialGenerator.get_material("canyon_rock")
				track_3d_root.add_child(mesa)
			if track_3d_light:
				track_3d_light.light_color = Color(1.0, 0.85, 0.65)
				track_3d_light.light_energy = 1.8
		"skyline":
			var ground = MeshInstance3D.new()
			var g_mesh = BoxMesh.new(); g_mesh.size = Vector3(90, 0.5, 90)
			ground.mesh = g_mesh
			ground.position = Vector3(0, -0.6, 0)
			ground.material_override = MaterialGenerator.create_pbr_material(Color(0.04, 0.05, 0.08), 0.3, 0.5)
			track_3d_root.add_child(ground)
			var bld_positions = [Vector3(-24, 0, -20), Vector3(-26, 0, 0), Vector3(-22, 0, 22), Vector3(24, 0, -18), Vector3(26, 0, 5), Vector3(22, 0, 24), Vector3(0, 0, -28), Vector3(0, 0, 28)]
			for bp in bld_positions:
				var bld = MeshInstance3D.new()
				var bb = BoxMesh.new(); bb.size = Vector3(6, 16.0, 6)
				bld.mesh = bb
				bld.position = bp + Vector3(0, 8.0, 0)
				var b_mat = StandardMaterial3D.new()
				b_mat.albedo_color = Color(0.06, 0.08, 0.14)
				b_mat.emission_enabled = true
				b_mat.emission = Color(0.1, 0.5, 0.9)
				b_mat.emission_energy_multiplier = 0.8
				bld.material_override = b_mat
				track_3d_root.add_child(bld)
			if track_3d_light:
				track_3d_light.light_color = Color(0.4, 0.65, 1.0)
				track_3d_light.light_energy = 0.9
		"alpine_rush":
			var ground = MeshInstance3D.new()
			var g_mesh = BoxMesh.new(); g_mesh.size = Vector3(90, 0.5, 90)
			ground.mesh = g_mesh
			ground.position = Vector3(0, -0.6, 0)
			ground.material_override = MaterialGenerator.get_material("snow_drift")
			track_3d_root.add_child(ground)
			for sp_pos in [Vector3(-28, 0, -24), Vector3(28, 0, -24), Vector3(30, 0, 24), Vector3(-30, 0, 24)]:
				var peak = MeshBuilder.build_mountain_peak(14.0, 9.0)
				peak.position = sp_pos
				track_3d_root.add_child(peak)
			for i in range(16):
				var angle = i * (TAU / 16.0)
				var pine = MeshBuilder.build_pine_tree(3.5)
				pine.position = Vector3(cos(angle) * 23.0, 0, sin(angle) * 23.0)
				track_3d_root.add_child(pine)
			if track_3d_light:
				track_3d_light.light_color = Color(0.95, 0.98, 1.0)
				track_3d_light.light_energy = 1.5
		"storm_harbor":
			var ground = MeshInstance3D.new()
			var g_mesh = BoxMesh.new(); g_mesh.size = Vector3(90, 0.5, 90)
			ground.mesh = g_mesh
			ground.position = Vector3(0, -0.6, 0)
			ground.material_override = MaterialGenerator.get_material("wet_asphalt")
			track_3d_root.add_child(ground)
			var ship = MeshBuilder.build_cargo_ship(35.0)
			ship.position = Vector3(28, -0.2, 0)
			ship.rotation_degrees.y = 90.0
			track_3d_root.add_child(ship)
			for cp in [Vector3(-24, 0, -18), Vector3(-24, 0, 18), Vector3(24, 0, -18)]:
				var crane = MeshBuilder.build_harbor_crane(14.0)
				crane.position = cp
				track_3d_root.add_child(crane)
			if track_3d_light:
				track_3d_light.light_color = Color(0.7, 0.8, 0.9)
				track_3d_light.light_energy = 1.1
		_: # "speedway"
			var turf = MeshInstance3D.new()
			var t_mesh = BoxMesh.new(); t_mesh.size = Vector3(90, 0.5, 90)
			turf.mesh = t_mesh
			turf.position = Vector3(0, -0.6, 0)
			turf.material_override = MaterialGenerator.get_material("grass_green")
			track_3d_root.add_child(turf)
			for fp in [Vector3(-26, 0, -22), Vector3(26, 0, -22), Vector3(26, 0, 22), Vector3(-26, 0, 22)]:
				var light_post = MeshBuilder.build_stadium_floodlight_tower(12.0)
				light_post.position = fp
				track_3d_root.add_child(light_post)
			var gs = MeshBuilder.build_stadium_grandstand(20.0, 5)
			gs.position = Vector3(0, 0, 26)
			track_3d_root.add_child(gs)
			if track_3d_light:
				track_3d_light.light_color = Color(0.9, 0.95, 1.0)
				track_3d_light.light_energy = 1.4

func _update_preview_racer_pos(s_dist: float) -> void:
	if not track_preview_racer or preview_track_nodes.size() < 2:
		return
	var n_pts = preview_track_nodes.size()
	var norm = fposmod(s_dist / maxf(preview_track_len, 0.1), 1.0) * float(n_pts)
	var idx0 = int(floor(norm)) % n_pts
	var idx1 = (idx0 + 1) % n_pts
	var frac = norm - float(int(floor(norm)))
	var p = preview_track_nodes[idx0].lerp(preview_track_nodes[idx1], frac)
	track_preview_racer.position = p + Vector3(0, 0.25, 0)
	var forward_dir = (preview_track_nodes[idx1] - preview_track_nodes[idx0]).normalized()
	if forward_dir.length_squared() > 0.01:
		track_preview_racer.look_at(track_preview_racer.position + forward_dir, Vector3.UP)

# ------------------------------------------------------------------------------
# VIEW 2: Vehicle Selection View (Interactive 3D Showroom & Livery Workshop)
# ------------------------------------------------------------------------------
func _build_vehicle_select_view() -> void:
	vehicle_select_view = VBoxContainer.new()
	vehicle_select_view.name = "VehicleSelectView"
	vehicle_select_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vehicle_select_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vehicle_select_view.add_theme_constant_override("separation", 8)
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

	# Main Split Layout: Left = 3D Showroom Turntable + Paint Swatches, Right = Performance Specs Card
	var v_split = HBoxContainer.new()
	v_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_split.add_theme_constant_override("separation", 16)
	vehicle_select_view.add_child(v_split)

	# Left Column: 3D Showroom Turntable + Customization Swatches
	var v_left_col = VBoxContainer.new()
	v_left_col.custom_minimum_size = Vector2(400, 0)
	v_left_col.add_theme_constant_override("separation", 6)
	v_split.add_child(v_left_col)

	_setup_3d_vehicle_showroom(v_left_col)

	# Livery & Paint Color Workshop (8 colors)
	var paint_box = VBoxContainer.new()
	paint_box.add_theme_constant_override("separation", 4)
	v_left_col.add_child(paint_box)

	var p_lbl = Label.new()
	p_lbl.text = "LIVERY & CUSTOM PAINT FINISH (8 COMPETITION TONES):"
	p_lbl.add_theme_font_size_override("font_size", 10)
	p_lbl.modulate = Color(0.2, 0.9, 1.0)
	paint_box.add_child(p_lbl)

	var swatches_row = HBoxContainer.new()
	swatches_row.add_theme_constant_override("separation", 6)
	paint_box.add_child(swatches_row)

	paint_swatch_buttons.clear()
	for swatch in PAINT_SWATCHES:
		var s_btn = Button.new()
		s_btn.custom_minimum_size = Vector2(42, 28)
		s_btn.tooltip_text = swatch["name"]
		var s_style = StyleBoxFlat.new()
		s_style.bg_color = swatch["color"]
		s_style.set_corner_radius_all(4)
		s_style.border_color = Color(1.0, 1.0, 1.0, 0.4)
		s_style.set_border_width_all(1)
		s_btn.add_theme_stylebox_override("normal", s_style)
		s_btn.add_theme_stylebox_override("hover", s_style)
		s_btn.add_theme_stylebox_override("pressed", s_style)
		var s_col = swatch["color"]
		s_btn.pressed.connect(func():
			selected_paint_color = s_col
			_update_3d_vehicle_showroom()
			_update_swatch_highlights()
		)
		swatches_row.add_child(s_btn)
		paint_swatch_buttons.append(s_btn)

	_update_swatch_highlights()

	# Right Column: Performance Specs & Drivetrain Card
	var v_card = PanelContainer.new()
	v_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v_style = StyleBoxFlat.new()
	v_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
	v_style.border_color = Color(0.8, 0.6, 0.1, 0.7)
	v_style.set_border_width_all(1)
	v_style.set_corner_radius_all(8)
	v_style.content_margin_left = 16
	v_style.content_margin_right = 16
	v_style.content_margin_top = 10
	v_style.content_margin_bottom = 10
	v_card.add_theme_stylebox_override("panel", v_style)
	v_split.add_child(v_card)

	var v_vbox = VBoxContainer.new()
	v_vbox.add_theme_constant_override("separation", 6)
	v_card.add_child(v_vbox)

	var v_top = HBoxContainer.new()
	v_vbox.add_child(v_top)

	veh_info_name = Label.new()
	veh_info_name.text = "Speeder (CIK-FIA Sprint Kart)"
	veh_info_name.add_theme_font_size_override("font_size", 16)
	veh_info_name.modulate = Color(1.0, 0.85, 0.2)
	v_top.add_child(veh_info_name)

	var sp_v = Control.new()
	sp_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_top.add_child(sp_v)

	veh_info_class = Label.new()
	veh_info_class.text = "[CIK-FIA 125cc Shifter Kart]"
	veh_info_class.add_theme_font_size_override("font_size", 12)
	veh_info_class.modulate = Color(0.2, 0.9, 1.0)
	v_top.add_child(veh_info_class)

	veh_info_desc = Label.new()
	veh_info_desc.text = "Ultra-lightweight competition sprint kart with direct steering, razor-sharp response, and explosive agility."
	veh_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	veh_info_desc.add_theme_font_size_override("font_size", 11)
	v_vbox.add_child(veh_info_desc)

	# Chassis & Drivetrain tags
	var tags_box = HBoxContainer.new()
	tags_box.add_theme_constant_override("separation", 12)
	v_vbox.add_child(tags_box)

	veh_info_weight = Label.new()
	veh_info_weight.text = "Weight: 165 kg (Ultralight)"
	veh_info_weight.add_theme_font_size_override("font_size", 11)
	veh_info_weight.modulate = Color(0.4, 0.9, 1.0)
	tags_box.add_child(veh_info_weight)

	veh_info_drivetrain = Label.new()
	veh_info_drivetrain.text = "Drivetrain: RWD Direct Single-Gear"
	veh_info_drivetrain.add_theme_font_size_override("font_size", 11)
	veh_info_drivetrain.modulate = Color(0.9, 0.7, 0.2)
	tags_box.add_child(veh_info_drivetrain)

	veh_info_driver = Label.new()
	veh_info_driver.text = "Driver: Pro FIA Nomex • Carbon Helmet & Visor"
	veh_info_driver.add_theme_font_size_override("font_size", 10)
	veh_info_driver.modulate = Color(0.7, 0.75, 0.85)
	v_vbox.add_child(veh_info_driver)

	var sep_v = HSeparator.new()
	v_vbox.add_child(sep_v)

	# 6 Performance Stat Bars
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 6)
	v_vbox.add_child(stats_grid)

	var stat_names = [
		["SPEED", "speed"],
		["ACCEL", "accel"],
		["BRAKING", "braking"],
		["HANDLING", "handling"],
		["DRIFT", "drift"],
		["BOOST", "boost"]
	]
	for sn in stat_names:
		var s_item = HBoxContainer.new()
		s_item.add_theme_constant_override("separation", 8)
		var slbl = Label.new()
		slbl.text = "%-8s" % sn[0]
		slbl.custom_minimum_size = Vector2(70, 0)
		slbl.add_theme_font_size_override("font_size", 10)
		slbl.modulate = Color(0.75, 0.85, 0.95)
		s_item.add_child(slbl)

		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(110, 8)
		bar.max_value = 100.0
		bar.value = 80.0
		bar.show_percentage = false
		s_item.add_child(bar)
		stats_grid.add_child(s_item)
		stat_bars[sn[1]] = bar

	_select_vehicle_ui("speeder")

func _setup_3d_vehicle_showroom(parent: Control) -> void:
	var v_box = VBoxContainer.new()
	v_box.custom_minimum_size = Vector2(400, 240)
	v_box.add_theme_constant_override("separation", 2)
	parent.add_child(v_box)

	var v_lbl = Label.new()
	v_lbl.text = "INTERACTIVE 3D SHOWROOM (DRAG TO ROTATE • SCROLL TO ZOOM)"
	v_lbl.add_theme_font_size_override("font_size", 10)
	v_lbl.modulate = Color(1.0, 0.85, 0.2)
	v_box.add_child(v_lbl)

	vehicle_3d_container = SubViewportContainer.new()
	vehicle_3d_container.custom_minimum_size = Vector2(400, 220)
	vehicle_3d_container.stretch = true
	vehicle_3d_container.gui_input.connect(_on_turntable_gui_input)
	v_box.add_child(vehicle_3d_container)

	vehicle_3d_viewport = SubViewport.new()
	vehicle_3d_viewport.own_world_3d = true
	vehicle_3d_viewport.size = Vector2i(400, 220)
	vehicle_3d_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vehicle_3d_container.add_child(vehicle_3d_viewport)

	vehicle_3d_camera = Camera3D.new()
	vehicle_3d_camera.current = true
	vehicle_3d_camera.fov = 46.0
	vehicle_3d_camera.position = Vector3(0, 1.6, 4.2)
	vehicle_3d_camera.look_at(Vector3(0, 0.45, 0), Vector3.UP)
	vehicle_3d_viewport.add_child(vehicle_3d_camera)

	var v_env_node = WorldEnvironment.new()
	var v_env = Environment.new()
	v_env.background_mode = Environment.BG_COLOR
	v_env.background_color = Color(0.04, 0.05, 0.08)
	v_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	v_env.ambient_light_color = Color(0.55, 0.60, 0.70)
	v_env.ambient_light_energy = 0.95
	v_env_node.environment = v_env
	vehicle_3d_viewport.add_child(v_env_node)

	# 3-Point Studio Lights
	var key_light = DirectionalLight3D.new()
	key_light.position = Vector3(5, 7, 6)
	key_light.look_at_from_position(Vector3(5, 7, 6), Vector3(0, 0.4, 0), Vector3.UP)
	key_light.light_color = Color(1.0, 0.96, 0.92)
	key_light.light_energy = 1.5
	key_light.shadow_enabled = true
	vehicle_3d_viewport.add_child(key_light)

	var rim_light = DirectionalLight3D.new()
	rim_light.position = Vector3(-5, 6, -5)
	rim_light.look_at_from_position(Vector3(-5, 6, -5), Vector3(0, 0.4, 0), Vector3.UP)
	rim_light.light_color = Color(0.2, 0.75, 1.0)
	rim_light.light_energy = 1.3
	vehicle_3d_viewport.add_child(rim_light)

	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-6, 3, 4)
	fill_light.look_at_from_position(Vector3(-6, 3, 4), Vector3(0, 0.4, 0), Vector3.UP)
	fill_light.light_color = Color(0.7, 0.75, 0.85)
	fill_light.light_energy = 0.8
	vehicle_3d_viewport.add_child(fill_light)

	# Studio Pedestal
	var pedestal = MeshInstance3D.new()
	var ped_mesh = CylinderMesh.new()
	ped_mesh.top_radius = 2.4
	ped_mesh.bottom_radius = 2.5
	ped_mesh.height = 0.12
	pedestal.mesh = ped_mesh
	pedestal.position = Vector3(0, -0.06, 0)
	pedestal.material_override = MaterialGenerator.create_pbr_material(Color(0.12, 0.14, 0.18), 0.85, 0.25)
	vehicle_3d_viewport.add_child(pedestal)

	# Glowing LED rim ring around turntable
	var rim_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 2.38
	ring_mesh.outer_radius = 2.44
	rim_ring.mesh = ring_mesh
	rim_ring.position = Vector3(0, 0.0, 0)
	rim_ring.material_override = MaterialGenerator.create_pbr_material(Color(0.0, 0.85, 1.0), 0.1, 0.2, Color(0.0, 0.85, 1.0), 2.2)
	vehicle_3d_viewport.add_child(rim_ring)

	vehicle_3d_turntable = Node3D.new()
	vehicle_3d_viewport.add_child(vehicle_3d_turntable)

func _on_turntable_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_turntable_dragging = event.pressed
			last_drag_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			vehicle_cam_distance = clampf(vehicle_cam_distance - 0.25, 2.4, 6.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			vehicle_cam_distance = clampf(vehicle_cam_distance + 0.25, 2.4, 6.0)
	elif event is InputEventMouseMotion and is_turntable_dragging:
		var delta_drag = event.position - last_drag_pos
		last_drag_pos = event.position
		vehicle_turntable_yaw += delta_drag.x * 0.012
		vehicle_turntable_pitch = clampf(vehicle_turntable_pitch + delta_drag.y * 0.008, 0.05, 0.70)
	elif event is InputEventScreenTouch:
		is_turntable_dragging = event.pressed
		last_drag_pos = event.position
	elif event is InputEventScreenDrag and is_turntable_dragging:
		var delta_drag = event.relative
		vehicle_turntable_yaw += delta_drag.x * 0.012
		vehicle_turntable_pitch = clampf(vehicle_turntable_pitch + delta_drag.y * 0.008, 0.05, 0.70)

func _update_3d_vehicle_showroom() -> void:
	if not vehicle_3d_turntable or not is_instance_valid(vehicle_3d_turntable):
		return
	for c in vehicle_3d_turntable.get_children():
		c.queue_free()

	vehicle_3d_model = MeshBuilder.build_drift_kart(selected_paint_color, selected_vehicle_id, 7)
	vehicle_3d_turntable.add_child(vehicle_3d_model)

func _update_swatch_highlights() -> void:
	for idx in range(paint_swatch_buttons.size()):
		var btn = paint_swatch_buttons[idx]
		var swatch_col = PAINT_SWATCHES[idx]["color"]
		var is_selected = swatch_col.is_equal_approx(selected_paint_color)
		var style = StyleBoxFlat.new()
		style.bg_color = swatch_col
		style.set_corner_radius_all(4)
		style.border_color = Color(1.0, 1.0, 1.0) if is_selected else Color(0.2, 0.2, 0.2)
		style.set_border_width_all(2 if is_selected else 1)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

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
	vbox.add_theme_constant_override("separation", 12)
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
	lbl_diff.text = "AI Skill Difficulty:"
	lbl_diff.custom_minimum_size = Vector2(180, 0)
	row3.add_child(lbl_diff)

	var diff_box = HBoxContainer.new()
	diff_box.add_theme_constant_override("separation", 8)
	row3.add_child(diff_box)

	diff_buttons.clear()
	var diff_tiers = ["Easy", "Normal", "Hard", "Expert"]
	for d in diff_tiers:
		var d_btn = Button.new()
		d_btn.text = d.to_upper()
		d_btn.custom_minimum_size = Vector2(90, 32)
		d_btn.add_theme_font_size_override("font_size", 11)
		diff_buttons[d] = d_btn
		var diff_val = d
		d_btn.pressed.connect(func():
			selected_difficulty = diff_val
			_update_difficulty_buttons()
		)
		diff_box.add_child(d_btn)

	_update_difficulty_buttons()

func _update_difficulty_buttons() -> void:
	for d in diff_buttons.keys():
		var btn = diff_buttons[d] as Button
		if d == selected_difficulty:
			btn.modulate = Color(0.2, 1.0, 0.5)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85)

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
		if track_info_corners and meta.has("corners"): track_info_corners.text = "Corners: " + meta["corners"]
		if track_info_elevation and meta.has("elevation"): track_info_elevation.text = "Elevation: " + meta["elevation"]
		if track_info_time and meta.has("time"): track_info_time.text = "Time of Day: " + meta["time"]
		if track_info_rec_veh and meta.has("rec_vehicle"): track_info_rec_veh.text = "Recommended: " + meta["rec_vehicle"]
		if track_info_grip and meta.has("grip"): track_info_grip.text = "Traction Index: " + meta["grip"]
		if track_info_style and meta.has("style"): track_info_style.text = "Layout: " + meta["style"]

	_update_3d_track_preview(track_id)

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
		if veh_info_weight and v.has("weight"): veh_info_weight.text = "Weight: " + v["weight"]
		if veh_info_drivetrain and v.has("drivetrain"): veh_info_drivetrain.text = "Drivetrain: " + v["drivetrain"]
		if veh_info_driver and v.has("driver"): veh_info_driver.text = "Driver: " + v["driver"]
		_update_stat_bars(v)

	_update_3d_vehicle_showroom()

func _update_stat_bars(stats: Dictionary) -> void:
	for k in stats.keys():
		if stat_bars.has(k):
			stat_bars[k].value = stats[k]

func _on_track_card_selected(track_id: String) -> void:
	_select_track_ui(track_id)

func _on_vehicle_card_selected(veh_id: String) -> void:
	_select_vehicle_ui(veh_id)

func _on_paint_swatch_selected(col: Color) -> void:
	selected_paint_color = col
	_update_3d_vehicle_showroom()
	_update_swatch_highlights()

func _show_track_select() -> void:
	transition_menu_state(MenuState.TRACK_SELECT)

func _show_vehicle_select() -> void:
	transition_menu_state(MenuState.VEHICLE_SELECT)

func _show_setup_view() -> void:
	transition_menu_state(MenuState.RACE_SETUP)

func _on_start_race_pressed() -> void:
	_on_start_race_clicked()

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
