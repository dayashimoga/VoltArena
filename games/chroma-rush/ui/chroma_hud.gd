class_name ChromaHUD
extends CanvasLayer

## In-game HUD for Chroma Rush: The Color Chase
## Unobtrusive, high-contrast, scalable display featuring dual color/symbol badges,
## swap lock-on reticle, speedometer, timer, combo meter, and mobile touch controls.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const MissionDirector = preload("res://games/chroma-rush/core/mission_director.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const ChromaMiniMap = preload("res://games/chroma-rush/ui/chroma_mini_map.gd")

signal swap_button_pressed()
signal pause_requested()
signal swap_requested()
signal target_cycle_requested()
signal map_expand_requested()
signal reset_to_road_requested()


# MiniMap radar
var mini_map: ChromaMiniMap

# Top Objective Badges
var current_color_badge: PanelContainer
var current_color_label: Label
var target_color_badge: PanelContainer
var target_color_label: Label

# Top Right Stats
var score_label: Label
var combo_label: Label
var timer_label: Label
var swaps_left_label: Label

# Center Alignment Reticle
var reticle_container: Control
var alignment_progress_bar: ProgressBar
var swap_prompt_label: Label
var guidance_lbl: Label
var rejection_timer: float = 0.0

# Bottom Left Gauge
var speedometer_label: Label
var speed_bar: ProgressBar
var boost_gauge: ProgressBar

# Real-Time Development Diagnostics (F3 toggle)
var diagnostics_panel: PanelContainer
var diagnostics_label: Label

# Touch Controls Overlay
var touch_controls: Control
var virtual_joystick: Control

var player_vehicle: ChromaVehicle
var mission_director: MissionDirector
var swap_engine: ColorSwapEngine

func _ready() -> void:
	layer = 10
	if not is_instance_valid(mini_map):
		setup_hud_layout()

func setup_hud_layout() -> void:
	var root = Control.new()
	root.name = "HUDRoot"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- TOP BAR: OBJECTIVE BADGES ---
	var top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_right = 1.0
	top_bar.offset_top = 16
	top_bar.offset_left = 24
	top_bar.offset_right = -24
	top_bar.offset_bottom = 70
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bar)

	# Left: Current Color
	current_color_badge = _create_badge("CURRENT COLOR", ChromaConstants.ChromaColor.CRIMSON)
	top_bar.add_child(current_color_badge)
	current_color_label = current_color_badge.get_node("VBox/ColorLabel") as Label

	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(spacer1)

	# Center: Target Objective Color
	target_color_badge = _create_badge("TARGET COLOR", ChromaConstants.ChromaColor.EMERALD)
	top_bar.add_child(target_color_badge)
	target_color_label = target_color_badge.get_node("VBox/ColorLabel") as Label

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(spacer2)

	# Right: Stats Panel
	var stats_box = VBoxContainer.new()
	stats_box.alignment = BoxContainer.ALIGNMENT_END

	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.add_theme_font_size_override("font_size", 20)
	stats_box.add_child(score_label)

	combo_label = Label.new()
	combo_label.text = "COMBO: x1.0"
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	stats_box.add_child(combo_label)

	timer_label = Label.new()
	timer_label.text = "TIME: 90.0s"
	stats_box.add_child(timer_label)

	swaps_left_label = Label.new()
	swaps_left_label.text = ""
	stats_box.add_child(swaps_left_label)

	top_bar.add_child(stats_box)

	# --- TOP LEFT: MINI MAP RADAR ---
	mini_map = ChromaMiniMap.new()
	mini_map.name = "MiniMap"
	mini_map.offset_left = 24
	mini_map.offset_top = 96
	mini_map.map_expand_requested.connect(func(): map_expand_requested.emit())
	root.add_child(mini_map)

	# --- TOP CENTER: OBJECTIVE GUIDANCE BANNER ---
	var guidance_box = PanelContainer.new()
	guidance_box.name = "GuidanceBanner"
	guidance_box.anchor_left = 0.5
	guidance_box.anchor_right = 0.5
	guidance_box.offset_left = -260
	guidance_box.offset_top = 76
	guidance_box.offset_right = 260
	guidance_box.offset_bottom = 104
	var g_style = StyleBoxFlat.new()
	g_style.bg_color = Color(0.06, 0.09, 0.16, 0.82)
	g_style.border_color = Color(0.15, 0.65, 0.95, 0.5)
	g_style.set_border_width_all(1)
	g_style.set_corner_radius_all(6)
	guidance_box.add_theme_stylebox_override("panel", g_style)
	root.add_child(guidance_box)

	guidance_lbl = Label.new()
	guidance_lbl.name = "GuidanceLabel"
	guidance_lbl.text = "LOCATE & SWAP TO TARGET COLOR"
	guidance_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guidance_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guidance_lbl.add_theme_font_size_override("font_size", 12)
	guidance_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	guidance_box.add_child(guidance_lbl)

	# --- CENTER: SWAP LOCK RETICLE ---
	reticle_container = Control.new()
	reticle_container.name = "SwapReticle"
	reticle_container.anchor_left = 0.5
	reticle_container.anchor_top = 0.5
	reticle_container.anchor_right = 0.5
	reticle_container.anchor_bottom = 0.5
	reticle_container.offset_left = -120
	reticle_container.offset_top = 40
	reticle_container.offset_right = 120
	reticle_container.offset_bottom = 90
	reticle_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(reticle_container)

	alignment_progress_bar = ProgressBar.new()
	alignment_progress_bar.anchor_right = 1.0
	alignment_progress_bar.offset_bottom = 14
	alignment_progress_bar.max_value = 1.0
	alignment_progress_bar.value = 0.0
	alignment_progress_bar.show_percentage = false
	reticle_container.add_child(alignment_progress_bar)

	swap_prompt_label = Label.new()
	swap_prompt_label.anchor_right = 1.0
	swap_prompt_label.offset_top = 18
	swap_prompt_label.offset_bottom = 44
	swap_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	swap_prompt_label.text = "ALIGN ALONGSIDE TO SWAP"
	swap_prompt_label.add_theme_font_size_override("font_size", 14)
	reticle_container.add_child(swap_prompt_label)

	# --- BOTTOM LEFT: SPEEDOMETER & BOOST ---
	var gauge_box = VBoxContainer.new()
	gauge_box.offset_left = 24
	gauge_box.offset_bottom = -24
	gauge_box.anchor_top = 1.0
	gauge_box.anchor_bottom = 1.0
	gauge_box.offset_top = -110
	root.add_child(gauge_box)

	speedometer_label = Label.new()
	speedometer_label.text = "0 KM/H"
	speedometer_label.add_theme_font_size_override("font_size", 28)
	gauge_box.add_child(speedometer_label)

	speed_bar = ProgressBar.new()
	speed_bar.custom_minimum_size = Vector2(160, 10)
	speed_bar.max_value = 150.0
	speed_bar.value = 0.0
	speed_bar.show_percentage = false
	gauge_box.add_child(speed_bar)

	var boost_lbl = Label.new()
	boost_lbl.text = "NITRO BOOST"
	boost_lbl.add_theme_font_size_override("font_size", 12)
	gauge_box.add_child(boost_lbl)

	boost_gauge = ProgressBar.new()
	boost_gauge.custom_minimum_size = Vector2(160, 8)
	boost_gauge.max_value = 3.0
	boost_gauge.value = 0.0
	boost_gauge.show_percentage = false
	gauge_box.add_child(boost_gauge)

	_setup_mobile_touch_controls(root)

func _setup_mobile_touch_controls(root: Control) -> void:
	touch_controls = Control.new()
	touch_controls.name = "TouchControls"
	touch_controls.anchor_right = 1.0
	touch_controls.anchor_bottom = 1.0
	touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(touch_controls)

	# Big Action Swap Button (bottom right)
	var swap_btn = Button.new()
	swap_btn.name = "TouchSwapBtn"
	swap_btn.text = "⚡ SWAP"
	swap_btn.custom_minimum_size = Vector2(100, 70)
	swap_btn.anchor_left = 1.0
	swap_btn.anchor_top = 1.0
	swap_btn.anchor_right = 1.0
	swap_btn.anchor_bottom = 1.0
	swap_btn.offset_left = -130
	swap_btn.offset_top = -100
	swap_btn.offset_right = -30
	swap_btn.offset_bottom = -30
	swap_btn.pressed.connect(func(): swap_button_pressed.emit())
	touch_controls.add_child(swap_btn)

	# Visible "Reset to Road" action button (accessible via UI and [R] key)

	var reset_btn = Button.new()
	reset_btn.name = "ResetRoadBtn"
	reset_btn.text = "↺ RESET TO ROAD [R]"
	reset_btn.custom_minimum_size = Vector2(160, 36)
	reset_btn.anchor_left = 1.0
	reset_btn.anchor_top = 1.0
	reset_btn.anchor_right = 1.0
	reset_btn.anchor_bottom = 1.0
	reset_btn.offset_left = -310
	reset_btn.offset_top = -78
	reset_btn.offset_right = -150
	reset_btn.offset_bottom = -42
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.pressed.connect(func(): reset_to_road_requested.emit())
	root.add_child(reset_btn)

	# Automatically detect if touch screen or mobile is active
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()
	touch_controls.visible = is_mobile


	# --- DEVELOPMENT DIAGNOSTICS OVERLAY (F3) ---
	diagnostics_panel = PanelContainer.new()
	diagnostics_panel.name = "DiagnosticsPanel"
	diagnostics_panel.anchor_left = 1.0
	diagnostics_panel.anchor_top = 0.0
	diagnostics_panel.anchor_right = 1.0
	diagnostics_panel.offset_left = -340
	diagnostics_panel.offset_top = 80
	diagnostics_panel.offset_right = -20
	diagnostics_panel.offset_bottom = 370
	diagnostics_panel.visible = false
	var diag_style = StyleBoxFlat.new()
	diag_style.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	diag_style.border_color = Color(0.2, 0.8, 1.0, 0.6)
	diag_style.set_border_width_all(1)
	diagnostics_panel.add_theme_stylebox_override("panel", diag_style)
	root.add_child(diagnostics_panel)

	diagnostics_label = Label.new()
	diagnostics_label.name = "DiagnosticsLabel"
	diagnostics_label.add_theme_font_size_override("font_size", 12)
	diagnostics_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	diagnostics_panel.add_child(diagnostics_label)

func _create_badge(title: String, col_id: int) -> PanelContainer:
	var pc = PanelContainer.new()
	pc.custom_minimum_size = Vector2(160, 50)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	pc.add_child(vbox)

	var t_lbl = Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(t_lbl)

	var c_lbl = Label.new()
	c_lbl.name = "ColorLabel"
	c_lbl.text = ChromaConstants.format_color_label(col_id)
	c_lbl.add_theme_font_size_override("font_size", 16)
	c_lbl.add_theme_color_override("font_color", ChromaConstants.get_color_value(col_id))
	vbox.add_child(c_lbl)

	return pc

func connect_systems(p_vehicle: ChromaVehicle, p_director: MissionDirector, p_engine: ColorSwapEngine) -> void:
	player_vehicle = p_vehicle
	mission_director = p_director
	swap_engine = p_engine

	if player_vehicle:
		player_vehicle.color_changed.connect(func(c): update_player_color(c))
		update_player_color(player_vehicle.current_color)

	if mission_director:
		mission_director.time_updated.connect(func(rem, el): update_timer(rem))
		mission_director.score_updated.connect(func(sc, combo): update_score_and_combo(sc, combo))
		mission_director.objective_progress_updated.connect(func(idx, tot, c, gate):
			update_target_objective(c, gate)
		)
		update_target_objective(mission_director.get_current_target_color(), mission_director.get_current_target_gate_id())

func _process(delta: float) -> void:
	if rejection_timer > 0.0:
		rejection_timer -= delta

	if player_vehicle and is_instance_valid(player_vehicle):
		var kph = int(player_vehicle.speed_kph)
		speedometer_label.text = "%d KM/H" % kph
		speed_bar.value = kph
		boost_gauge.value = player_vehicle.drift_charge

		# Update top guidance banner based on mission state
		if mission_director and is_instance_valid(mission_director) and guidance_lbl:
			var req_col = mission_director.get_current_target_color()
			var gate_id = mission_director.get_current_target_gate_id()
			if req_col != ChromaConstants.ChromaColor.NONE:
				var col_name = ChromaConstants.get_color_name(req_col)
				if player_vehicle.current_color == req_col:
					guidance_lbl.text = "✓ COLOR MATCHED: Follow route ribbon to Checkpoint %s" % gate_id.to_upper()
					guidance_lbl.modulate = Color(0.2, 1.0, 0.4)
				else:
					guidance_lbl.text = "STEP 1: Pursue & align with %s vehicle to swap [E / 🎮X]" % col_name.to_upper()
					guidance_lbl.modulate = Color(0.85, 0.92, 1.0)
			else:
				guidance_lbl.text = "FREE DRIVE: Cruise and swap colors freely"
				guidance_lbl.modulate = Color(0.7, 0.85, 1.0)

	if swap_engine and player_vehicle and is_instance_valid(player_vehicle) and rejection_timer <= 0.0:
		_update_swap_reticle()

func _update_swap_reticle() -> void:
	if rejection_timer > 0.0:
		return

	# If player vehicle already has the required target color, prompt delivery
	if mission_director and is_instance_valid(mission_director):
		var req_col = mission_director.get_current_target_color()
		if req_col != ChromaConstants.ChromaColor.NONE and player_vehicle.current_color == req_col:
			alignment_progress_bar.value = 1.0
			alignment_progress_bar.modulate = Color(0.2, 1.0, 0.4)
			var gate_id = mission_director.get_current_target_gate_id()
			swap_prompt_label.text = "✓ COLOR MATCHED: Drive through Checkpoint %s" % gate_id.to_upper()
			swap_prompt_label.modulate = Color(0.2, 1.0, 0.4)
			return

	var tgt_id: String = ""
	var is_eligible: bool = false
	var eval_reason: String = ""

	# Objective-guided prioritization: find vehicle carrying required color
	if mission_director and is_instance_valid(mission_director):
		var req_col = mission_director.get_current_target_color()
		if req_col != ChromaConstants.ChromaColor.NONE and player_vehicle.current_color != req_col:
			var match_id = swap_engine.find_target_with_color("player", req_col)
			if not match_id.is_empty():
				var node_b = swap_engine.get_vehicle_node(match_id)
				if is_instance_valid(node_b):
					var d = player_vehicle.global_position.distance_to(node_b.global_position)
					if d < 45.0:
						tgt_id = match_id
						var check = swap_engine.evaluate_eligibility("player", tgt_id, false)
						is_eligible = check.get("eligible", false)
						eval_reason = check.get("reason", "")

	if tgt_id.is_empty():
		var target_info = swap_engine.find_nearest_eligible_target("player", 18.0)
		tgt_id = target_info.get("target_id", "")
		is_eligible = target_info.get("eligible", false)
		if not tgt_id.is_empty():
			var check = swap_engine.evaluate_eligibility("player", tgt_id, false)
			eval_reason = check.get("reason", "")

	if tgt_id != "":
		var progress = swap_engine.get_alignment_progress("player", tgt_id)
		alignment_progress_bar.value = progress

		var tgt_color = swap_engine.get_vehicle_color(tgt_id)
		var color_label = ChromaConstants.format_color_label(tgt_color)

		if is_eligible:
			alignment_progress_bar.modulate = Color(0.1, 1.0, 0.3)
			swap_prompt_label.text = "⚡ SWAP READY! [%s] [E / 🎮X]" % color_label
			swap_prompt_label.modulate = Color(0.1, 1.0, 0.3)
		elif eval_reason == ChromaConstants.REJECT_OBSTRUCTED:
			alignment_progress_bar.modulate = Color(1.0, 0.45, 0.2)
			swap_prompt_label.text = "TARGET SEPARATED BY BARRIER / OBSTACLE"
			swap_prompt_label.modulate = Color(1.0, 0.45, 0.2)
		elif eval_reason == ChromaConstants.REJECT_ELEVATION:
			alignment_progress_bar.modulate = Color(1.0, 0.45, 0.2)
			swap_prompt_label.text = "TARGET ON DIFFERENT ROAD LEVEL"
			swap_prompt_label.modulate = Color(1.0, 0.45, 0.2)
		elif eval_reason == ChromaConstants.REJECT_SPEED:
			alignment_progress_bar.modulate = Color(1.0, 0.8, 0.2)
			swap_prompt_label.text = "MATCH SPEED WITH TARGET [%s]" % color_label
			swap_prompt_label.modulate = Color(1.0, 0.8, 0.2)
		elif eval_reason == ChromaConstants.REJECT_ANGLE:
			alignment_progress_bar.modulate = Color(1.0, 0.8, 0.2)
			swap_prompt_label.text = "ALIGN PARALLEL TO [%s]" % color_label
			swap_prompt_label.modulate = Color(1.0, 0.8, 0.2)
		elif progress > 0.05:
			alignment_progress_bar.modulate = Color(1.0, 0.8, 0.1)
			swap_prompt_label.text = "HOLD ALIGNMENT [%s] %d%%" % [color_label, int(progress * 100)]
			swap_prompt_label.modulate = Color(1.0, 0.8, 0.1)
		else:
			alignment_progress_bar.modulate = Color(0.7, 0.7, 0.7)
			swap_prompt_label.text = "PULL ALONGSIDE [%s] (<8m) TO SWAP" % color_label
			swap_prompt_label.modulate = Color(0.85, 0.85, 0.85)
	else:
		alignment_progress_bar.value = 0.0
		if mission_director and is_instance_valid(mission_director):
			var req_col = mission_director.get_current_target_color()
			if req_col != ChromaConstants.ChromaColor.NONE and player_vehicle.current_color != req_col:
				var c_name = ChromaConstants.get_color_name(req_col)
				swap_prompt_label.text = "PURSUE & INTERCEPT %s VEHICLE" % c_name.to_upper()
			else:
				swap_prompt_label.text = "APPROACH VEHICLE (<8m) TO SWAP"
		else:
			swap_prompt_label.text = "APPROACH VEHICLE (<8m) TO SWAP"
		swap_prompt_label.modulate = Color(0.6, 0.7, 0.8)

func update_player_color(col: int) -> void:
	if current_color_label:
		current_color_label.text = ChromaConstants.format_color_label(col)
		current_color_label.add_theme_color_override("font_color", ChromaConstants.get_color_value(col))

func update_target_objective(col: int, gate_id: String) -> void:
	if target_color_label:
		target_color_label.text = "%s (%s)" % [ChromaConstants.format_color_label(col), gate_id.to_upper()]
		target_color_label.add_theme_color_override("font_color", ChromaConstants.get_color_value(col))

func update_score_and_combo(p_score: int, p_combo: float) -> void:
	if is_instance_valid(score_label):
		score_label.text = "SCORE: %d" % p_score
	if is_instance_valid(combo_label):
		combo_label.text = "COMBO: x%.1f" % p_combo

func update_timer(time_left: float) -> void:
	if is_instance_valid(timer_label):
		timer_label.text = "TIME: %.1fs" % time_left

func set_swaps_remaining(swaps_left: int) -> void:
	if is_instance_valid(swaps_left_label):
		if swaps_left >= 0:
			swaps_left_label.text = "SWAPS LEFT: %d" % swaps_left
		else:
			swaps_left_label.text = ""

func setup_mission(title: String, time_limit: float) -> void:
	if not is_instance_valid(timer_label):
		setup_hud_layout()
	update_timer(time_limit)
	update_score_and_combo(0, 1.0)

func update_hud(player_col: int, target_col: int, speed_kmh: float, time_left: float, score_val: int, combo_val: float) -> void:
	update_player_color(player_col)
	if target_color_label and not target_color_label.text.contains(ChromaConstants.get_color_name(target_col)):
		update_target_objective(target_col, "checkpoint")
	if speedometer_label:
		var kph = int(speed_kmh)
		speedometer_label.text = "%d KM/H" % kph
		if speed_bar:
			speed_bar.value = kph
	update_timer(time_left)
	update_score_and_combo(score_val, combo_val)

func set_alignment_progress(prog: float) -> void:
	if alignment_progress_bar:
		alignment_progress_bar.value = prog

func show_delivery_prompt(gate_id: String) -> void:
	if rejection_timer > 0.0:
		return
	if alignment_progress_bar:
		alignment_progress_bar.value = 1.0
		alignment_progress_bar.modulate = Color(0.2, 1.0, 0.4)
	if swap_prompt_label:
		swap_prompt_label.visible = true
		swap_prompt_label.text = "✓ COLOR MATCHED: Drive through Checkpoint %s" % gate_id.to_upper()
		swap_prompt_label.modulate = Color(0.2, 1.0, 0.4)

func show_swap_prompt(eligible: bool, target_color: int, reason: String = "", progress: float = 0.0, is_optional: bool = false) -> void:
	if rejection_timer > 0.0:
		return
	if swap_prompt_label:
		swap_prompt_label.visible = true
		var prefix = "(OPTIONAL SWAP) " if is_optional else ""
		if eligible:
			var color_name = ChromaConstants.get_color_name(target_color)
			var sym = ChromaConstants.get_color_symbol(target_color)
			swap_prompt_label.text = "⚡ %sSWAP READY! Press [E / 🎮X] for %s %s" % [prefix, sym, color_name]
			swap_prompt_label.modulate = Color(0.1, 1.0, 0.3)
		elif reason == ChromaConstants.REJECT_OBSTRUCTED:
			swap_prompt_label.text = "TARGET SEPARATED BY BARRIER / OBSTACLE"
			swap_prompt_label.modulate = Color(1.0, 0.45, 0.2)
		elif reason == ChromaConstants.REJECT_ELEVATION:
			swap_prompt_label.text = "TARGET ON DIFFERENT ROAD LEVEL"
			swap_prompt_label.modulate = Color(1.0, 0.45, 0.2)
		elif reason == ChromaConstants.REJECT_SPEED:
			swap_prompt_label.text = "MATCH SPEED WITH TARGET VEHICLE"
			swap_prompt_label.modulate = Color(1.0, 0.8, 0.2)
		elif reason == ChromaConstants.REJECT_ANGLE:
			swap_prompt_label.text = "PULL PARALLEL (ALIGN HEADING)"
			swap_prompt_label.modulate = Color(1.0, 0.8, 0.2)
		elif progress > 0.05:
			var color_name = ChromaConstants.get_color_name(target_color)
			swap_prompt_label.text = "%sHOLD ALIGNMENT WITH %s (%d%%)" % [prefix, color_name.to_upper(), int(progress * 100)]
			swap_prompt_label.modulate = Color(1.0, 0.85, 0.1)
		else:
			var color_name = ChromaConstants.get_color_name(target_color)
			swap_prompt_label.text = "%sPULL ALONGSIDE %s (<8m) TO SWAP [E / 🎮X]" % [prefix, color_name.to_upper()]
			swap_prompt_label.modulate = Color(0.85, 0.85, 0.85)

func hide_swap_prompt() -> void:
	if rejection_timer > 0.0:
		return
	if swap_prompt_label:
		swap_prompt_label.text = "APPROACH TARGET VEHICLE (<8m)"
		swap_prompt_label.modulate = Color(0.6, 0.7, 0.8)

func show_swap_rejected(reason: String) -> void:
	rejection_timer = 2.0
	if swap_prompt_label:
		var msg = "SWAP FAILED"
		match reason:
			ChromaConstants.REJECT_DISTANCE, "DISTANCE_TOO_FAR":
				msg = "TOO FAR: Close within 8m"
			ChromaConstants.REJECT_SPEED, "SPEED_DIFFERENCE_TOO_HIGH":
				msg = "SPEED DIFF: Match target speed"
			ChromaConstants.REJECT_ANGLE, "NOT_ALIGNED":
				msg = "NOT ALIGNED: Pull alongside parallel"
			ChromaConstants.REJECT_ALIGNMENT_TIME:
				msg = "HOLD ALIGNMENT: 0.5s to lock"
			ChromaConstants.REJECT_SAME_COLOR, "SAME_COLOR":
				msg = "SAME COLOR: Target already matches"
			ChromaConstants.REJECT_COOLDOWN, "COOLDOWN":
				msg = "COOLDOWN: System recharging"
			ChromaConstants.REJECT_ELEVATION:
				msg = "ELEVATION: Different road level"
			ChromaConstants.REJECT_OBSTRUCTED:
				msg = "OBSTRUCTED: Line of sight blocked"
			ChromaConstants.REJECT_BUSY:
				msg = "BUSY: Exchange in progress"
			_:
				msg = reason.replace("_", " ")
		swap_prompt_label.text = "✕ " + msg
		swap_prompt_label.modulate = Color(1.0, 0.3, 0.3)

func toggle_diagnostics() -> void:
	if diagnostics_panel:
		diagnostics_panel.visible = not diagnostics_panel.visible

func update_diagnostics(info: Dictionary) -> void:
	if not diagnostics_panel or not diagnostics_panel.visible or not diagnostics_label:
		return
	var lines = [
		"=== CHROMA DIAGNOSTICS (F3) ===",
		"FPS: %d (%.2f ms)" % [Engine.get_frames_per_second(), 1000.0 / maxf(1.0, Engine.get_frames_per_second())],
		"Velocity: %.1f km/h | %s" % [info.get("speed_kph", 0.0), str(info.get("vel", Vector3.ZERO))],
		"Grounded: %s | Normal: %s" % [str(info.get("grounded", false)), str(info.get("normal", Vector3.UP))],
		"Contacts: %d" % info.get("contacts", 0),
		"Waypoint: %d / %d" % [info.get("nearest_wp", 0), info.get("total_wps", 0)],
		"Target: %s (%s)" % [info.get("target_id", "NONE"), info.get("target_color", "NONE")],
		"Target Dist: %.1fm | Align: %d%%" % [info.get("target_dist", 0.0), int(info.get("align_pct", 0.0) * 100)],
		"Player Color: %s" % info.get("player_color", "NONE"),
		"Mission: %s [%s]" % [info.get("mission_id", ""), info.get("mission_phase", "")]
	]
	diagnostics_label.text = "\n".join(lines)

func show_notification(msg: String) -> void:
	pass
