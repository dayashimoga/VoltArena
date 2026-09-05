class_name DriftStormHUD
extends Control

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
var finish_panel: PanelContainer
var finish_label: Label
var toast_container: VBoxContainer
var touch_controls: TouchControls
var objective_badge: Label
var onboarding_overlay: PanelContainer

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGenerator.get_theme()
	setup_hud_layout()
	setup_onboarding_overlay()
	check_mobile_controls()

func setup_hud_layout() -> void:
	# Top Left: Position & Lap
	pos_panel = PanelContainer.new()
	pos_panel.position = Vector2(24, 24)
	pos_panel.custom_minimum_size = Vector2(180, 90)
	add_child(pos_panel)

	var pos_vbox = VBoxContainer.new()
	pos_panel.add_child(pos_vbox)

	var pos_hbox = HBoxContainer.new()
	pos_vbox.add_child(pos_hbox)

	var p_tag = Label.new()
	p_tag.text = "POS: "
	p_tag.modulate = Color(0.6, 0.7, 0.8)
	pos_hbox.add_child(p_tag)

	position_label = Label.new()
	position_label.text = "1st"
	position_label.add_theme_font_size_override("font_size", 32)
	position_label.modulate = Color(1.0, 0.85, 0.1)
	pos_hbox.add_child(position_label)

	lap_label = Label.new()
	lap_label.text = "LAP 1 / 3"
	lap_label.add_theme_font_size_override("font_size", 18)
	lap_label.modulate = Color(0.2, 0.9, 1.0)
	pos_vbox.add_child(lap_label)

	# Top Center: Active Race Objective Badge
	var obj_panel = PanelContainer.new()
	obj_panel.anchor_left = 0.5
	obj_panel.anchor_right = 0.5
	obj_panel.offset_left = -210
	obj_panel.offset_top = 20
	obj_panel.offset_right = 210
	obj_panel.offset_bottom = 58
	add_child(obj_panel)

	objective_badge = Label.new()
	objective_badge.text = "OBJECTIVE: COMPLETE 3 LAPS — FINISH 1ST"
	objective_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_badge.add_theme_font_size_override("font_size", 13)
	objective_badge.modulate = Color(0.9, 0.95, 1.0)
	obj_panel.add_child(objective_badge)

	# Top Right: Times & Powerup
	var right_panel = PanelContainer.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.offset_left = -220
	right_panel.offset_top = 24
	right_panel.offset_right = -24
	right_panel.offset_bottom = 130
	add_child(right_panel)

	var r_vbox = VBoxContainer.new()
	right_panel.add_child(r_vbox)

	lap_time_label = Label.new()
	lap_time_label.text = "TIME: 00:00.0"
	lap_time_label.modulate = Color(0.9, 0.95, 1.0)
	r_vbox.add_child(lap_time_label)

	best_lap_label = Label.new()
	best_lap_label.text = "BEST: --:--.-"
	best_lap_label.modulate = Color(0.4, 1.0, 0.5)
	r_vbox.add_child(best_lap_label)

	var sep = HSeparator.new()
	r_vbox.add_child(sep)

	powerup_panel = PanelContainer.new()
	r_vbox.add_child(powerup_panel)

	powerup_label = Label.new()
	powerup_label.text = "[ NO ITEM ]"
	powerup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	powerup_label.modulate = Color(0.6, 0.65, 0.75)
	powerup_panel.add_child(powerup_label)

	# Bottom Right: Speedometer & Drift Charge
	var speed_panel = PanelContainer.new()
	speed_panel.anchor_left = 1.0
	speed_panel.anchor_top = 1.0
	speed_panel.anchor_right = 1.0
	speed_panel.anchor_bottom = 1.0
	speed_panel.offset_left = -220
	speed_panel.offset_top = -120
	speed_panel.offset_right = -24
	speed_panel.offset_bottom = -24
	add_child(speed_panel)

	var s_vbox = VBoxContainer.new()
	speed_panel.add_child(s_vbox)

	speed_label = Label.new()
	speed_label.text = "0 KM/H"
	speed_label.add_theme_font_size_override("font_size", 28)
	speed_label.modulate = Color(0.2, 1.0, 0.6)
	s_vbox.add_child(speed_label)

	speed_bar = ProgressBar.new()
	speed_bar.custom_minimum_size = Vector2(170, 12)
	speed_bar.max_value = 160.0
	speed_bar.value = 0.0
	speed_bar.show_percentage = false
	s_vbox.add_child(speed_bar)

	var d_hbox = HBoxContainer.new()
	s_vbox.add_child(d_hbox)

	drift_label = Label.new()
	drift_label.text = "DRIFT:"
	drift_label.add_theme_font_size_override("font_size", 12)
	drift_label.modulate = Color(1.0, 0.6, 0.2)
	d_hbox.add_child(drift_label)

	drift_bar = ProgressBar.new()
	drift_bar.custom_minimum_size = Vector2(120, 10)
	drift_bar.max_value = 3.0
	drift_bar.value = 0.0
	drift_bar.show_percentage = false
	d_hbox.add_child(drift_bar)

	# Center Countdown Banner
	countdown_panel = PanelContainer.new()
	countdown_panel.anchor_left = 0.5
	countdown_panel.anchor_top = 0.35
	countdown_panel.anchor_right = 0.5
	countdown_panel.anchor_bottom = 0.35
	countdown_panel.offset_left = -140
	countdown_panel.offset_top = -45
	countdown_panel.offset_right = 140
	countdown_panel.offset_bottom = 45
	countdown_panel.visible = false
	add_child(countdown_panel)

	countdown_label = Label.new()
	countdown_label.text = "3"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 42)
	countdown_label.modulate = Color(1.0, 0.9, 0.2)
	countdown_panel.add_child(countdown_label)

	# Center Finish Banner
	finish_panel = PanelContainer.new()
	finish_panel.anchor_left = 0.5
	finish_panel.anchor_top = 0.3
	finish_panel.anchor_right = 0.5
	finish_panel.anchor_bottom = 0.3
	finish_panel.offset_left = -200
	finish_panel.offset_top = -50
	finish_panel.offset_right = 200
	finish_panel.offset_bottom = 50
	finish_panel.visible = false
	add_child(finish_panel)

	finish_label = Label.new()
	finish_label.text = "FINISH!"
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_size_override("font_size", 38)
	finish_label.modulate = Color(0.2, 1.0, 0.5)
	finish_panel.add_child(finish_label)

	# Toasts
	toast_container = VBoxContainer.new()
	toast_container.anchor_top = 0.2
	toast_container.anchor_bottom = 0.5
	toast_container.offset_left = 32
	toast_container.offset_right = 320
	toast_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(toast_container)

func check_mobile_controls() -> void:
	var pa = GameConstants.get_autoload(self, "PlatformAdapter")
	if pa and pa.has_touchscreen():
		touch_controls = TouchControls.new()
		add_child(touch_controls)

func update_position(pos: int, _total: int = 4) -> void:
	if not position_label:
		return
	var suffixes = ["st", "nd", "rd", "th"]
	var idx = clampi(pos - 1, 0, suffixes.size() - 1)
	position_label.text = "%d%s" % [pos, suffixes[idx]]
	match pos:
		1:
			position_label.modulate = Color(1.0, 0.85, 0.1) # Gold
		2:
			position_label.modulate = Color(0.85, 0.9, 0.95) # Silver
		3:
			position_label.modulate = Color(0.9, 0.6, 0.3) # Bronze
		_:
			position_label.modulate = Color(0.7, 0.75, 0.8)

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
			1:
				drift_label.modulate = Color(0.0, 0.8, 1.0) # Blue mini-turbo
			2:
				drift_label.modulate = Color(1.0, 0.5, 0.0) # Orange super-turbo
			3:
				drift_label.modulate = Color(0.8, 0.1, 1.0) # Ultra purple turbo
			_:
				drift_label.modulate = Color(0.6, 0.6, 0.6)

func update_powerup(p_name: String) -> void:
	if not powerup_label:
		return
	if p_name.is_empty():
		powerup_label.text = "[ NO ITEM ]"
		powerup_label.modulate = Color(0.6, 0.65, 0.75)
	else:
		powerup_label.text = "[ %s ]" % p_name.to_upper()
		powerup_label.modulate = Color(1.0, 0.9, 0.2)

func update_lap_times(cur_sec: float, best_sec: float) -> void:
	if lap_time_label:
		lap_time_label.text = "TIME: %s" % _format_time(cur_sec)
	if best_lap_label and best_sec < 900.0:
		best_lap_label.text = "BEST: %s" % _format_time(best_sec)

func show_countdown(text: String) -> void:
	if not countdown_panel:
		return
	countdown_panel.visible = true
	countdown_label.text = text
	if text == "GO!":
		countdown_label.modulate = Color(0.2, 1.0, 0.5)
		var tween = create_tween()
		tween.tween_property(countdown_panel, "modulate:a", 0.0, 0.6).set_delay(0.4)
		tween.tween_callback(func():
			countdown_panel.visible = false
			countdown_panel.modulate.a = 1.0
		)
	else:
		countdown_label.modulate = Color(1.0, 0.9, 0.2)

func show_finish_banner(pos_text: String) -> void:
	if not finish_panel:
		return
	finish_panel.visible = true
	finish_label.text = "FINISHED: %s" % pos_text

func show_toast(msg: String, col: Color = Color.WHITE) -> void:
	if not toast_container:
		return
	var lbl = Label.new()
	lbl.text = msg
	lbl.modulate = col
	toast_container.add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 2.5).set_delay(1.5)
	tween.tween_callback(lbl.queue_free)

func setup_onboarding_overlay() -> void:
	onboarding_overlay = PanelContainer.new()
	onboarding_overlay.name = "OnboardingOverlay"
	onboarding_overlay.anchor_left = 0.5
	onboarding_overlay.anchor_top = 0.5
	onboarding_overlay.anchor_right = 0.5
	onboarding_overlay.anchor_bottom = 0.5
	onboarding_overlay.offset_left = -330
	onboarding_overlay.offset_top = -180
	onboarding_overlay.offset_right = 330
	onboarding_overlay.offset_bottom = 180
	add_child(onboarding_overlay)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	onboarding_overlay.add_child(vbox)

	var title = Label.new()
	title.text = "DRIFT STORM — ARCADE KART RACING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.2, 0.9, 1.0)
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "HIGH-OCTANE DRIFT CIRCUIT"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.modulate = Color(0.8, 0.85, 0.95)
	vbox.add_child(sub)

	var obj_lbl = Label.new()
	obj_lbl.text = "OBJECTIVE: COMPLETE 3 LAPS — CROSS THE FINISH LINE 1ST!"
	obj_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj_lbl.add_theme_font_size_override("font_size", 14)
	obj_lbl.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(obj_lbl)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var ctrl_grid = GridContainer.new()
	ctrl_grid.columns = 2
	ctrl_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(ctrl_grid)

	var controls_data = [
		["W / S", "Accelerate / Reverse & Brake"],
		["A / D", "Steering Left / Right"],
		["SHIFT", "Drift (Hold through turns for Mini-Turbo Sparks)"],
		["SPACE", "Activate Collected PowerUp (Boost/Shield/EMP)"]
	]
	for c in controls_data:
		var k = Label.new()
		k.text = c[0] + "  "
		k.modulate = Color(0.0, 1.0, 0.8)
		k.add_theme_font_size_override("font_size", 13)
		ctrl_grid.add_child(k)

		var a = Label.new()
		a.text = c[1]
		a.modulate = Color.WHITE
		a.add_theme_font_size_override("font_size", 13)
		ctrl_grid.add_child(a)

	var prompt_lbl = Label.new()
	prompt_lbl.text = "RACE STARTING (PRESS ANY KEY OR SPACE TO START)"
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 12)
	prompt_lbl.modulate = Color(0.7, 0.85, 0.95)
	vbox.add_child(prompt_lbl)

func dismiss_onboarding() -> void:
	if not is_instance_valid(onboarding_overlay) or not onboarding_overlay.visible:
		return
	var tween = create_tween()
	tween.tween_property(onboarding_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		onboarding_overlay.visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_onboarding()

func _format_time(sec: float) -> String:
	var mins = int(sec) / 60
	var s = int(sec) % 60
	var ms = int((sec - int(sec)) * 10.0)
	return "%02d:%02d.%01d" % [mins, s, ms]
