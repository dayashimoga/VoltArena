class_name FlightHUD
extends CanvasLayer

## FlightHUD: Collimated Aviation Glass Head-Up Display (HUD) & Flight Telemetry.
## Features a screen-centered collimated artificial horizon with pitch ladder,
## flight path marker (velocity vector), airspeed & altimeter tapes, heading ribbon,
## G-meter, flight mode indicator, stall warning, and adaptive touch controls.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")
const FlightPhysics = preload("res://games/aircraft-flight/core/flight_physics.gd")

var aircraft: CharacterBody3D

# Root canvas controls
var hud_root: Control
var center_hud: Control

# Instrument Readouts
var boresight_marker: Label
var artificial_horizon_line: Line2D
var pitch_ladder_container: Control
var pitch_rungs_container: Control
var flight_path_vector: Control
var airspeed_label: Label
var airspeed_bar: ProgressBar
var altimeter_label: Label
var radar_alt_label: Label
var heading_label: Label
var heading_ribbon: Control
var vsi_label: Label
var g_force_label: Label
var aoa_label: Label
var throttle_bar: ProgressBar
var throttle_label: Label
var gear_indicator: Label
var flap_indicator: Label
var flight_mode_label: Label
var stall_warning_banner: PanelContainer
var objective_label: Label
var tutorial_hint_label: Label
var controls_guide_label: Label
var minimap_panel: PanelContainer

# Touch Controls for Mobile / Tablets
var touch_root: Control
var virtual_stick: Control
var virtual_stick_knob: Control
var virtual_throttle_slider: VSlider
var is_stick_active: bool = false
var stick_center: Vector2 = Vector2.ZERO

# Pixels per degree for pitch ladder translation
const PIXELS_PER_DEGREE: float = 4.5

signal pause_requested()
signal camera_toggle_requested()
signal recover_requested()

func _ready() -> void:
	layer = 15
	_build_hud_layout()
	var vp = get_viewport()
	var init_size = vp.get_visible_rect().size if vp else DisplayServer.window_get_size()
	if init_size.x <= 0 or init_size.y <= 0:
		init_size = Vector2(1920, 1080)
	_update_responsive_layout(init_size)

	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	var vp = get_viewport()
	if vp:
		_update_responsive_layout(vp.get_visible_rect().size)

func _build_hud_layout() -> void:
	hud_root = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)

	# --- SCREEN-CENTERED COLLIMATED HUD RETICLE & PITCH LADDER ---
	# CenterHUD is positioned exactly at viewport_size * 0.5 with (0,0) as screen center
	center_hud = Control.new()
	center_hud.name = "CenterHUD"
	center_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_hud.position = Vector2(960, 540) # default until layout update
	hud_root.add_child(center_hud)

	# Boresight Crosshair (Fixed aircraft longitudinal reference at 0,0)
	boresight_marker = _create_label("+", 24, Color(0.2, 0.95, 0.3))
	boresight_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boresight_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boresight_marker.position = Vector2(-15, -16)
	boresight_marker.size = Vector2(30, 30)
	center_hud.add_child(boresight_marker)

	# Flight Path Vector Marker (Velocity Vector —○—)
	flight_path_vector = Control.new()
	flight_path_vector.name = "VelocityVector"
	flight_path_vector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fpv_label = _create_label("—○—", 20, Color(0.2, 0.95, 0.3))
	fpv_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fpv_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fpv_label.position = Vector2(-30, -15)
	fpv_label.size = Vector2(60, 30)
	flight_path_vector.add_child(fpv_label)
	center_hud.add_child(flight_path_vector)

	# Pitch Ladder Container (Rotates around screen center 0,0 by -roll_rad)
	pitch_ladder_container = Control.new()
	pitch_ladder_container.name = "PitchLadder"
	pitch_ladder_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pitch_ladder_container.position = Vector2.ZERO
	pitch_ladder_container.pivot_offset = Vector2.ZERO
	center_hud.add_child(pitch_ladder_container)

	# Pitch Rungs Container (Translates along pitch axis inside roll frame)
	pitch_rungs_container = Control.new()
	pitch_rungs_container.name = "PitchRungs"
	pitch_rungs_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pitch_rungs_container.position = Vector2.ZERO
	pitch_ladder_container.add_child(pitch_rungs_container)

	# Artificial Horizon Center Line (Through 0,0 at 0 deg pitch)
	artificial_horizon_line = Line2D.new()
	artificial_horizon_line.width = 2.0
	artificial_horizon_line.default_color = Color(0.2, 0.95, 0.3, 0.85)
	artificial_horizon_line.points = PackedVector2Array([Vector2(-140, 0), Vector2(-25, 0), Vector2(25, 0), Vector2(140, 0)])
	pitch_rungs_container.add_child(artificial_horizon_line)

	# Calibrated Pitch Rungs (+10, +20, +30 / -10, -20, -30)
	for p_deg in [-30, -20, -10, 10, 20, 30]:
		var rung_y = -p_deg * PIXELS_PER_DEGREE
		var rung_line = Line2D.new()
		rung_line.width = 1.5
		var is_positive = p_deg > 0
		rung_line.default_color = Color(0.2, 0.95, 0.3, 0.70) if is_positive else Color(0.2, 0.85, 0.4, 0.55)

		# Positive pitch: solid hooks down; Negative pitch: dashed hooks up
		if is_positive:
			rung_line.points = PackedVector2Array([
				Vector2(-55, rung_y + 6), Vector2(-55, rung_y),
				Vector2(-20, rung_y), Vector2(20, rung_y),
				Vector2(55, rung_y), Vector2(55, rung_y + 6)
			])
		else:
			rung_line.points = PackedVector2Array([
				Vector2(-55, rung_y - 6), Vector2(-55, rung_y),
				Vector2(-35, rung_y), Vector2(-20, rung_y),
				Vector2(20, rung_y), Vector2(35, rung_y),
				Vector2(55, rung_y), Vector2(55, rung_y - 6)
			])
		pitch_rungs_container.add_child(rung_line)

		var lbl = _create_label(str(abs(p_deg)), 10, Color(0.2, 0.95, 0.3, 0.75))
		lbl.position = Vector2(60, rung_y - 7)
		pitch_rungs_container.add_child(lbl)

		var lbl_l = _create_label(str(abs(p_deg)), 10, Color(0.2, 0.95, 0.3, 0.75))
		lbl_l.position = Vector2(-75, rung_y - 7)
		pitch_rungs_container.add_child(lbl_l)

	# --- LEFT HUD: AIRSPEED TAPE ---
	var speed_card = _create_glass_panel(Vector2(115, 175))
	speed_card.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	speed_card.offset_left = 30
	hud_root.add_child(speed_card)

	var spd_vbox = VBoxContainer.new()
	spd_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_card.add_child(spd_vbox)

	var spd_hdr = _create_label("AIRSPEED", 11, Color(0.7, 0.75, 0.8))
	spd_vbox.add_child(spd_hdr)

	airspeed_label = _create_label("0 KM/H", 22, Color(0.2, 0.95, 0.3))
	spd_vbox.add_child(airspeed_label)

	airspeed_bar = ProgressBar.new()
	airspeed_bar.custom_minimum_size = Vector2(95, 8)
	airspeed_bar.max_value = 1000.0
	airspeed_bar.show_percentage = false
	spd_vbox.add_child(airspeed_bar)

	throttle_label = _create_label("THR: 0%", 13, Color(0.9, 0.92, 0.95))
	spd_vbox.add_child(throttle_label)

	throttle_bar = ProgressBar.new()
	throttle_bar.custom_minimum_size = Vector2(95, 8)
	throttle_bar.max_value = 100.0
	throttle_bar.show_percentage = false
	spd_vbox.add_child(throttle_bar)

	g_force_label = _create_label("1.0 G", 13, Color(0.95, 0.85, 0.2))
	spd_vbox.add_child(g_force_label)

	aoa_label = _create_label("AoA: +0.0°", 12, Color(0.3, 0.9, 1.0))
	spd_vbox.add_child(aoa_label)

	# --- RIGHT HUD: ALTIMETER & VSI TAPE ---
	var alt_card = _create_glass_panel(Vector2(120, 185))
	alt_card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	alt_card.offset_left = -150
	hud_root.add_child(alt_card)

	var alt_vbox = VBoxContainer.new()
	alt_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alt_card.add_child(alt_vbox)

	var alt_hdr = _create_label("ALTITUDE", 11, Color(0.7, 0.75, 0.8))
	alt_vbox.add_child(alt_hdr)

	altimeter_label = _create_label("0 M", 22, Color(0.2, 0.95, 0.3))
	alt_vbox.add_child(altimeter_label)

	radar_alt_label = _create_label("RALT: 0 M (AGL)", 12, Color(0.85, 0.9, 0.95))
	alt_vbox.add_child(radar_alt_label)

	vsi_label = _create_label("VSI: +0.0", 13, Color(0.2, 0.95, 0.3))
	alt_vbox.add_child(vsi_label)

	gear_indicator = _create_label("GEAR: DOWN", 12, Color(0.2, 0.95, 0.3))
	alt_vbox.add_child(gear_indicator)

	flap_indicator = _create_label("FLAPS: UP", 12, Color(0.8, 0.85, 0.9))
	alt_vbox.add_child(flap_indicator)

	flight_mode_label = _create_label("MODE: SIMCADE", 11, Color(0.3, 0.85, 1.0))
	alt_vbox.add_child(flight_mode_label)

	# --- TOP HUD: HEADING COMPASS RIBBON ---
	var heading_card = _create_glass_panel(Vector2(220, 52))
	heading_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	heading_card.offset_top = 18
	hud_root.add_child(heading_card)

	var hdg_vbox = VBoxContainer.new()
	hdg_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	heading_card.add_child(hdg_vbox)

	heading_label = _create_label("HDG: 360° | N", 16, Color(0.2, 0.95, 0.3))
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdg_vbox.add_child(heading_label)

	# --- TOP BANNER: ACTIVE OBJECTIVE & FLIGHT DIRECTOR TUTORIAL ---
	var obj_card = _create_glass_panel(Vector2(540, 64))
	obj_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	obj_card.offset_top = 74
	hud_root.add_child(obj_card)

	var obj_vbox = VBoxContainer.new()
	obj_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_card.add_child(obj_vbox)

	objective_label = _create_label("Takeoff from Runway 09L and explore the open skies.", 13, Color(1.0, 0.9, 0.2))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj_vbox.add_child(objective_label)

	tutorial_hint_label = _create_label("TUTORIAL: Advance throttle to 100% [Hold SHIFT]. Steer runway with [Q/E].", 11, Color(0.3, 0.9, 1.0))
	tutorial_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj_vbox.add_child(tutorial_hint_label)

	# --- BOTTOM HUD: VISIBLE FLIGHT CONTROLS GUIDE PANEL ---
	var guide_panel = _create_glass_panel(Vector2(740, 42))
	guide_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	guide_panel.offset_left = 30
	guide_panel.offset_top = -54
	hud_root.add_child(guide_panel)

	controls_guide_label = _create_label("[W/S] Pitch  [A/D] Roll  [Q/E] Rudder/Taxi  [Shift/Ctrl] Throttle  [Space] Brakes  [G] Gear  [F] Flaps  [M] Mode  [V] Cam  [R] Reset", 11, Color(0.85, 0.95, 0.88, 0.9))
	controls_guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_panel.add_child(controls_guide_label)

	# --- STALL MASTER CAUTION WARNING ---
	stall_warning_banner = _create_glass_panel(Vector2(260, 48))
	stall_warning_banner.set_anchors_preset(Control.PRESET_CENTER)
	stall_warning_banner.offset_top = -140
	stall_warning_banner.visible = false
	hud_root.add_child(stall_warning_banner)

	var stall_lbl = _create_label("⚠ STALL WARNING ⚠", 18, Color(1.0, 0.15, 0.1))
	stall_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stall_warning_banner.add_child(stall_lbl)

	# --- MOBILE TOUCH CONTROLS OVERLAY ---
	_build_touch_controls()

func _build_touch_controls() -> void:
	touch_root = Control.new()
	touch_root.name = "TouchControls"
	touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(touch_root)

	# Virtual Flight Stick (Right side - Pitch / Roll)
	virtual_stick = Control.new()
	virtual_stick.name = "VirtualStick"
	virtual_stick.custom_minimum_size = Vector2(160, 160)
	virtual_stick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	virtual_stick.offset_left = -190
	virtual_stick.offset_top = -190
	virtual_stick.offset_right = -30
	virtual_stick.offset_bottom = -30
	touch_root.add_child(virtual_stick)

	var stick_bg = Panel.new()
	stick_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	stick_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	virtual_stick.add_child(stick_bg)

	virtual_stick_knob = Control.new()
	virtual_stick_knob.name = "Knob"
	virtual_stick_knob.custom_minimum_size = Vector2(50, 50)
	virtual_stick_knob.set_anchors_preset(Control.PRESET_CENTER)
	virtual_stick.add_child(virtual_stick_knob)

	# Quick Action Buttons (Gear, Flaps, Brakes, Camera)
	var btn_vbox = VBoxContainer.new()
	btn_vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_vbox.offset_left = -110
	btn_vbox.offset_top = 18
	touch_root.add_child(btn_vbox)

	var btn_cam = _create_action_button("CAM", func(): camera_toggle_requested.emit())
	btn_vbox.add_child(btn_cam)
	var btn_gear = _create_action_button("GEAR", func(): if is_instance_valid(aircraft): aircraft.toggle_landing_gear())
	btn_vbox.add_child(btn_gear)
	var btn_flaps = _create_action_button("FLAP", func(): if is_instance_valid(aircraft): aircraft.cycle_flaps())
	btn_vbox.add_child(btn_flaps)
	var btn_rec = _create_action_button("REC [R]", func(): recover_requested.emit())
	btn_vbox.add_child(btn_rec)
	var btn_pause = _create_action_button("PAUSE", func(): pause_requested.emit())
	btn_vbox.add_child(btn_pause)

func _process(delta: float) -> void:
	if not is_instance_valid(aircraft):
		return

	# Update Readouts
	var kias = int(aircraft.indicated_airspeed_ms * 1.94384)
	airspeed_label.text = "%d KM/H\n%d KIAS" % [int(aircraft.indicated_airspeed_kmh), kias]
	airspeed_bar.value = aircraft.indicated_airspeed_kmh

	altimeter_label.text = "%d M" % int(aircraft.barometric_altitude_m)
	radar_alt_label.text = "RALT: %d M (AGL)" % int(aircraft.radar_altitude_m)
	vsi_label.text = "VSI: %+0.1f" % aircraft.vertical_speed_ms

	if aoa_label:
		aoa_label.text = "AoA: %+0.1f°" % aircraft.angle_of_attack_deg

	var thr_pct = int(aircraft.engine_rpm_pct)
	if aircraft.afterburner_active and aircraft.throttle >= 0.95:
		throttle_label.text = "AB: %d%%" % thr_pct
	else:
		throttle_label.text = "THR: %d%%" % thr_pct
	throttle_bar.value = thr_pct

	g_force_label.text = "%.1f G" % aircraft.g_force_current
	gear_indicator.text = "GEAR: %s" % ("DOWN" if aircraft.gear_position > 0.8 else ("UP" if aircraft.gear_position < 0.2 else "IN TRANS"))
	flap_indicator.text = "FLAPS: %s" % ("UP" if aircraft.flaps_step == 0 else ("TAKEOFF" if aircraft.flaps_step == 1 else "LANDING"))

	if flight_mode_label and aircraft.get("flight_mode") != null:
		var mode_str = "SIMCADE"
		match aircraft.flight_mode:
			FlightConst.FlightMode.ARCADE: mode_str = "ARCADE"
			FlightConst.FlightMode.SIMCADE: mode_str = "SIMCADE"
			FlightConst.FlightMode.SIMULATION: mode_str = "SIMULATION"
		flight_mode_label.text = "MODE: %s" % mode_str

	# Compass Heading Tape
	var fwd = -aircraft.global_transform.basis.z.normalized()
	var heading_deg = rad_to_deg(atan2(fwd.x, -fwd.z))
	if heading_deg < 0.0:
		heading_deg += 360.0
	heading_label.text = "HDG: %03d°" % int(heading_deg)

	# --- PITCH LADDER & ARTIFICIAL HORIZON ATTITUDE COMPUTATION ---
	# Calculate pitch angle relative to world horizontal datum
	# Pitch: -asin(basis.z.y)
	var ac_basis = aircraft.global_transform.basis
	var pitch_rad = -asin(clampf(ac_basis.z.y, -1.0, 1.0))
	var pitch_deg = rad_to_deg(pitch_rad)
	# Roll: atan2(basis.x.y, basis.y.y)
	var roll_rad = atan2(ac_basis.x.y, ac_basis.y.y)

	# Rotate pitch ladder around exact screen center by -roll_rad
	pitch_ladder_container.rotation = -roll_rad

	# Translate horizon line & rungs vertically by pitch_deg * PIXELS_PER_DEGREE
	# When pitch > 0 (nose up), horizon moves DOWN (+Y on screen)
	pitch_rungs_container.position.y = pitch_deg * PIXELS_PER_DEGREE

	# Velocity Vector (Flight Path Marker)
	if aircraft.indicated_airspeed_ms > 4.0:
		var fpv_x = clampf(aircraft.sideslip_angle_deg * PIXELS_PER_DEGREE, -120.0, 120.0)
		var fpv_y = clampf((pitch_deg - aircraft.angle_of_attack_deg) * PIXELS_PER_DEGREE, -120.0, 120.0)
		flight_path_vector.position = Vector2(fpv_x, -fpv_y)
		flight_path_vector.visible = true
	else:
		flight_path_vector.position = Vector2.ZERO
		flight_path_vector.visible = false

	# Stall warning flashing
	stall_warning_banner.visible = aircraft.is_stalling and (fmod(Time.get_ticks_msec(), 400.0) < 200.0)

	# Flight Director / Tutorial Hints
	if tutorial_hint_label:
		if aircraft.is_rotorcraft:
			tutorial_hint_label.text = "ROTORCRAFT: [SHIFT/CTRL] Collective Lift  |  [W/S/A/D] Cyclic Direction  |  [Q/E] Anti-Torque Pedals"
		elif aircraft.is_stalling:
			tutorial_hint_label.text = "⚠ STALL RECOVERY: Push nose down [W] and firewall throttle [Hold SHIFT] immediately!"
		elif not aircraft.is_airborne:
			if aircraft.indicated_airspeed_kmh < 40.0:
				tutorial_hint_label.text = "TAKEOFF ROLL: Advance throttle to 100% [Hold SHIFT]. Maintain centerline with Rudder [Q/E]."
			elif aircraft.indicated_airspeed_kmh < aircraft.stall_speed_ms * 3.6 * 1.15:
				tutorial_hint_label.text = "ACCELERATING: Airspeed alive. Stand by for rotation speed (Vr ~220 KM/H)."
			else:
				tutorial_hint_label.text = "ROTATE: Gently pull back [S] to rotate and climb out cleanly!"
		elif aircraft.is_airborne and aircraft.gear_position > 0.8:
			tutorial_hint_label.text = "POSITIVE CLIMB: Press [G] to retract landing gear and reduce drag."
		elif aircraft.radar_altitude_m < 150.0 and aircraft.indicated_airspeed_kmh < 260.0:
			tutorial_hint_label.text = "APPROACH & LANDING: On final glideslope. Gear [G], flaps [F], flare gently before touchdown."
		else:
			tutorial_hint_label.text = "CRUISE FLIGHT: Bank with [A/D], pitch with [W/S], adjust throttle with [SHIFT/CTRL]."

func set_objective_text(text: String) -> void:
	if objective_label:
		objective_label.text = text

func _update_responsive_layout(viewport_size: Vector2) -> void:
	var is_portrait = viewport_size.y > viewport_size.x
	var is_narrow = viewport_size.x < 720.0

	# Hard lock HUD reticle and pitch ladder strictly to screen center
	if center_hud:
		center_hud.position = viewport_size * 0.5

	if touch_root:
		var pa = GameConstants.get_autoload(self, "PlatformAdapter")
		var show_touch = (pa and pa.is_touch_active()) or is_portrait or is_narrow
		touch_root.visible = show_touch

func _create_glass_panel(size: Vector2) -> PanelContainer:
	var pc = PanelContainer.new()
	pc.custom_minimum_size = size
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.78)
	style.set_corner_radius_all(10)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.95, 0.3, 0.4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	pc.add_theme_stylebox_override("panel", style)
	return pc

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _create_action_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(75, 34)
	btn.pressed.connect(callback)
	return btn
