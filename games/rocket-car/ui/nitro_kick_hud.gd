class_name NitroKickHUD
extends Control

var scoreboard_panel: PanelContainer
var score_label: Label
var timer_label: Label
var overtime_label: Label
var boost_bar: ProgressBar
var boost_label: Label
var kickoff_panel: PanelContainer
var kickoff_label: Label
var goal_panel: PanelContainer
var goal_label: Label
var goal_speed_label: Label
var toast_container: VBoxContainer
var touch_controls: TouchControls

var blue_score: int = 0
var orange_score: int = 0

var tracked_camera: Camera3D
var tracked_ball: Node3D
var ball_indicator: Control
var ball_arrow: Label
var ball_dist_label: Label
var onboarding_overlay: PanelContainer
var objective_badge: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGenerator.get_theme()
	setup_hud_layout()
	setup_ball_tracker()
	setup_onboarding_overlay()
	connect_bus_signals()
	check_mobile_controls()

func setup_hud_layout() -> void:
	# Top Center: Scoreboard & Clock
	scoreboard_panel = PanelContainer.new()
	scoreboard_panel.anchor_left = 0.5
	scoreboard_panel.anchor_right = 0.5
	scoreboard_panel.offset_left = -220
	scoreboard_panel.offset_top = 18
	scoreboard_panel.offset_right = 220
	scoreboard_panel.offset_bottom = 104
	add_child(scoreboard_panel)

	var score_vbox = VBoxContainer.new()
	score_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scoreboard_panel.add_child(score_vbox)

	var score_hbox = HBoxContainer.new()
	score_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	score_vbox.add_child(score_hbox)

	var blue_tag = Label.new()
	blue_tag.text = "BLUE "
	blue_tag.modulate = Color(0.0, 0.8, 1.0)
	blue_tag.add_theme_font_size_override("font_size", 20)
	score_hbox.add_child(blue_tag)

	score_label = Label.new()
	score_label.text = "0  -  0"
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.modulate = Color.WHITE
	score_hbox.add_child(score_label)

	var orange_tag = Label.new()
	orange_tag.text = " ORANGE"
	orange_tag.modulate = Color(1.0, 0.5, 0.0)
	orange_tag.add_theme_font_size_override("font_size", 20)
	score_hbox.add_child(orange_tag)

	timer_label = Label.new()
	timer_label.text = "05:00"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.modulate = Color(0.8, 0.9, 1.0)
	score_vbox.add_child(timer_label)

	overtime_label = Label.new()
	overtime_label.text = "GOLDEN GOAL // OVERTIME"
	overtime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overtime_label.add_theme_font_size_override("font_size", 14)
	overtime_label.modulate = Color(1.0, 0.8, 0.1)
	overtime_label.visible = false
	score_vbox.add_child(overtime_label)

	objective_badge = Label.new()
	objective_badge.text = "OBJECTIVE: SCORE 3 GOALS IN ORANGE GOAL"
	objective_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_badge.add_theme_font_size_override("font_size", 12)
	objective_badge.modulate = Color(0.9, 0.95, 1.0, 0.85)
	score_vbox.add_child(objective_badge)

	# Bottom Right: Nitro Boost Gauge
	var boost_panel = PanelContainer.new()
	boost_panel.anchor_left = 1.0
	boost_panel.anchor_top = 1.0
	boost_panel.anchor_right = 1.0
	boost_panel.anchor_bottom = 1.0
	boost_panel.offset_left = -240
	boost_panel.offset_top = -110
	boost_panel.offset_right = -24
	boost_panel.offset_bottom = -24
	add_child(boost_panel)

	var boost_vbox = VBoxContainer.new()
	boost_panel.add_child(boost_vbox)

	var boost_header = HBoxContainer.new()
	boost_vbox.add_child(boost_header)

	var b_title = Label.new()
	b_title.text = "NITRO BOOST"
	b_title.add_theme_font_size_override("font_size", 14)
	b_title.modulate = Color(1.0, 0.6, 0.0)
	boost_header.add_child(b_title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boost_header.add_child(spacer)

	boost_label = Label.new()
	boost_label.text = "100%"
	boost_label.add_theme_font_size_override("font_size", 16)
	boost_label.modulate = Color(1.0, 0.8, 0.2)
	boost_header.add_child(boost_label)

	boost_bar = ProgressBar.new()
	boost_bar.custom_minimum_size = Vector2(190, 20)
	boost_bar.max_value = 100.0
	boost_bar.value = 100.0
	boost_bar.show_percentage = false
	boost_vbox.add_child(boost_bar)

	# Center: Kickoff Countdown Banner
	kickoff_panel = PanelContainer.new()
	kickoff_panel.anchor_left = 0.5
	kickoff_panel.anchor_top = 0.35
	kickoff_panel.anchor_right = 0.5
	kickoff_panel.anchor_bottom = 0.35
	kickoff_panel.offset_left = -150
	kickoff_panel.offset_top = -40
	kickoff_panel.offset_right = 150
	kickoff_panel.offset_bottom = 40
	kickoff_panel.visible = false
	add_child(kickoff_panel)

	kickoff_label = Label.new()
	kickoff_label.text = "3"
	kickoff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kickoff_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kickoff_label.add_theme_font_size_override("font_size", 36)
	kickoff_label.modulate = Color(1.0, 0.9, 0.2)
	kickoff_panel.add_child(kickoff_label)

	# Center: Goal Celebration Banner
	goal_panel = PanelContainer.new()
	goal_panel.anchor_left = 0.5
	goal_panel.anchor_top = 0.3
	goal_panel.anchor_right = 0.5
	goal_panel.anchor_bottom = 0.3
	goal_panel.offset_left = -250
	goal_panel.offset_top = -60
	goal_panel.offset_right = 250
	goal_panel.offset_bottom = 60
	goal_panel.visible = false
	add_child(goal_panel)

	var goal_vbox = VBoxContainer.new()
	goal_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_panel.add_child(goal_vbox)

	goal_label = Label.new()
	goal_label.text = "GOAL!"
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 42)
	goal_label.modulate = Color(1.0, 0.8, 0.0)
	goal_vbox.add_child(goal_label)

	goal_speed_label = Label.new()
	goal_speed_label.text = "SHOT SPEED: 88 KM/H"
	goal_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_speed_label.add_theme_font_size_override("font_size", 16)
	goal_speed_label.modulate = Color(0.9, 0.95, 1.0)
	goal_vbox.add_child(goal_speed_label)

	# Toasts
	toast_container = VBoxContainer.new()
	toast_container.anchor_top = 0.2
	toast_container.anchor_bottom = 0.5
	toast_container.offset_left = 32
	toast_container.offset_right = 320
	toast_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(toast_container)

func connect_bus_signals() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if not bus:
		return
	bus.score_updated.connect(_on_score_event)
	bus.round_timer_updated.connect(update_clock)
	bus.show_toast_requested.connect(show_toast)

func _on_score_event(team_id: int, new_score: int) -> void:
	if team_id == 0:
		blue_score = new_score
	else:
		orange_score = new_score
	update_score(blue_score, orange_score)

func check_mobile_controls() -> void:
	var pa = GameConstants.get_autoload(self, "PlatformAdapter")
	if pa and ("has_touchscreen" in pa and pa.has_touchscreen):
		touch_controls = TouchControls.new()
		add_child(touch_controls)

func update_score(blue: int, orange: int) -> void:
	blue_score = blue
	orange_score = orange
	if score_label:
		score_label.text = "%d  -  %d" % [blue, orange]

func update_clock(time_remaining: float) -> void:
	if not timer_label:
		return
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if time_remaining <= 0.0:
		if blue_score == orange_score:
			overtime_label.visible = true
			timer_label.text = "+ OVERTIME +"

func update_boost(current: float, max_boost: float = 100.0) -> void:
	if boost_bar:
		boost_bar.max_value = max_boost
		boost_bar.value = current
	if boost_label:
		var pct = int((current / max_boost) * 100.0) if max_boost > 0 else 0
		boost_label.text = "%d%%" % pct

func show_kickoff_countdown(seconds: int) -> void:
	if not kickoff_panel:
		return
	if seconds > 0:
		kickoff_panel.visible = true
		kickoff_label.text = str(seconds)
	elif seconds == 0:
		kickoff_panel.visible = true
		kickoff_label.text = "KICKOFF!"
		var tween = create_tween()
		tween.tween_property(kickoff_panel, "modulate:a", 0.0, 0.6).set_delay(0.4)
		tween.tween_callback(func():
			kickoff_panel.visible = false
			kickoff_panel.modulate.a = 1.0
		)
	else:
		kickoff_panel.visible = false

func show_goal_celebration(team_id: int, speed: float = 85.0) -> void:
	if not goal_panel:
		return
	var team_name = "BLUE TEAM" if team_id == 0 else "ORANGE TEAM"
	var col = Color(0.0, 0.9, 1.0) if team_id == 0 else Color(1.0, 0.55, 0.1)
	goal_label.text = "%s GOAL!" % team_name
	goal_label.modulate = col
	goal_speed_label.text = "SHOT SPEED: %d KM/H" % int(speed)
	goal_panel.visible = true
	goal_panel.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(goal_panel, "modulate:a", 0.0, 0.8).set_delay(2.2)
	tween.tween_callback(func():
		goal_panel.visible = false
		goal_panel.modulate.a = 1.0
	)

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

func setup_ball_tracker() -> void:
	ball_indicator = Control.new()
	ball_indicator.name = "BallIndicator"
	ball_indicator.mouse_filter = MOUSE_FILTER_IGNORE
	ball_indicator.visible = false
	add_child(ball_indicator)

	var b_icon = PanelContainer.new()
	b_icon.custom_minimum_size = Vector2(90, 32)
	b_icon.mouse_filter = MOUSE_FILTER_IGNORE
	ball_indicator.add_child(b_icon)

	var b_box = HBoxContainer.new()
	b_box.alignment = BoxContainer.ALIGNMENT_CENTER
	b_icon.add_child(b_box)

	ball_arrow = Label.new()
	ball_arrow.text = "▲"
	ball_arrow.add_theme_font_size_override("font_size", 14)
	ball_arrow.modulate = Color(1.0, 0.8, 0.0)
	b_box.add_child(ball_arrow)

	ball_dist_label = Label.new()
	ball_dist_label.text = "BALL 20m"
	ball_dist_label.add_theme_font_size_override("font_size", 12)
	ball_dist_label.modulate = Color.WHITE
	b_box.add_child(ball_dist_label)

func setup_onboarding_overlay() -> void:
	onboarding_overlay = PanelContainer.new()
	onboarding_overlay.name = "OnboardingOverlay"
	onboarding_overlay.anchor_left = 0.5
	onboarding_overlay.anchor_top = 0.5
	onboarding_overlay.anchor_right = 0.5
	onboarding_overlay.anchor_bottom = 0.5
	onboarding_overlay.offset_left = -320
	onboarding_overlay.offset_top = -170
	onboarding_overlay.offset_right = 320
	onboarding_overlay.offset_bottom = 170
	add_child(onboarding_overlay)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	onboarding_overlay.add_child(vbox)

	var title = Label.new()
	title.text = "NITRO KICK — ROCKET-CAR FOOTBALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.0, 0.9, 1.0)
	vbox.add_child(title)

	var team_lbl = Label.new()
	team_lbl.text = "YOU ARE BLUE TEAM  |  ATTACK ORANGE GOAL"
	team_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_lbl.add_theme_font_size_override("font_size", 16)
	team_lbl.modulate = Color(0.2, 0.85, 1.0)
	vbox.add_child(team_lbl)

	var obj_lbl = Label.new()
	obj_lbl.text = "OBJECTIVE: SCORE 3 GOALS IN ORANGE GOAL TO WIN!"
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
		["W / S", "Drive Forward / Reverse"],
		["A / D", "Steer Left / Right"],
		["SPACE", "Jump / Double-Jump Aerial"],
		["SHIFT", "Nitrous Boost Thruster"]
	]
	for c in controls_data:
		var k = Label.new()
		k.text = c[0] + "  "
		k.modulate = Color(0.0, 1.0, 0.8)
		k.add_theme_font_size_override("font_size", 14)
		ctrl_grid.add_child(k)

		var a = Label.new()
		a.text = c[1]
		a.modulate = Color.WHITE
		a.add_theme_font_size_override("font_size", 14)
		ctrl_grid.add_child(a)

	var prompt_lbl = Label.new()
	prompt_lbl.text = "MATCH STARTING (PRESS ANY KEY OR SPACE TO START)"
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 12)
	prompt_lbl.modulate = Color(0.7, 0.85, 0.95)
	vbox.add_child(prompt_lbl)

func dismiss_onboarding() -> void:
	if is_instance_valid(onboarding_overlay):
		onboarding_overlay.visible = false
		onboarding_overlay.modulate.a = 0.0
	if is_instance_valid(kickoff_panel):
		kickoff_panel.visible = false
		kickoff_panel.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_onboarding()

func _process(_delta: float) -> void:
	update_ball_tracker()

func set_tracking_targets(cam: Camera3D, b: Node3D) -> void:
	tracked_camera = cam
	tracked_ball = b

func update_ball_tracker() -> void:
	if not is_instance_valid(tracked_camera) or not is_instance_valid(tracked_ball) or not is_instance_valid(ball_indicator):
		if is_instance_valid(ball_indicator):
			ball_indicator.visible = false
		return

	var ball_pos = tracked_ball.global_position if tracked_ball.is_inside_tree() else tracked_ball.position
	var dist = int(tracked_camera.global_position.distance_to(ball_pos))
	var is_behind = tracked_camera.is_position_behind(ball_pos)
	var screen_pos = tracked_camera.unproject_position(ball_pos)
	var vp = get_viewport_rect().size

	var margin = 50.0
	var is_offscreen = is_behind or screen_pos.x < margin or screen_pos.x > (vp.x - margin) or screen_pos.y < margin or screen_pos.y > (vp.y - margin)

	ball_indicator.visible = true
	ball_dist_label.text = "BALL %dm" % dist

	if not is_offscreen:
		ball_indicator.position = screen_pos - Vector2(45, 52)
		ball_arrow.text = "▼"
		ball_arrow.modulate = Color(0.2, 0.9, 1.0)
	else:
		var center = vp * 0.5
		var dir = (screen_pos - center)
		if is_behind:
			dir = -dir
		if dir.length_squared() > 0.001:
			dir = dir.normalized()
		else:
			dir = Vector2.UP

		var edge_pos = center + dir * minf(center.x - margin, center.y - margin)
		edge_pos.x = clampf(edge_pos.x, margin, vp.x - margin - 90)
		edge_pos.y = clampf(edge_pos.y, margin, vp.y - margin - 34)
		ball_indicator.position = edge_pos

		if absf(dir.x) > absf(dir.y):
			ball_arrow.text = "►" if dir.x > 0 else "◄"
		else:
			ball_arrow.text = "▼" if dir.y > 0 else "▲"
		ball_arrow.modulate = Color(1.0, 0.8, 0.0)
