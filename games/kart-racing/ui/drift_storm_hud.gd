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

var minimap_panel: PanelContainer
var minimap_canvas: Control
var circuit_waypoints: Array = []
var player_ref: Node3D = null
var obj_panel: PanelContainer
var right_panel: PanelContainer

class CircuitMinimapCanvas extends Control:
	var player_ref: Node3D = null
	var circuit_waypoints: Array = []
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.08, 0.12, 0.88), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.85, 1.0, 0.5), false, 1.5)

		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if not tree:
			return

		if circuit_waypoints.is_empty():
			var tg = tree.root.find_child("TrackGenerator", true, false)
			if tg and not tg.waypoints.is_empty():
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
			draw_line(p1, p2, Color(0.18, 0.45, 0.75, 0.9), 3.5)

		if num_pts > 0:
			var s_pos = to_canvas.call(circuit_waypoints[0])
			draw_circle(s_pos, 4.0, Color(1.0, 1.0, 1.0))

		var ai_list = tree.get_nodes_in_group("ai_racers")
		for ai in ai_list:
			if is_instance_valid(ai):
				var ai_pos = to_canvas.call(ai.global_position)
				draw_circle(ai_pos, 3.5, Color(1.0, 0.35, 0.15))

		if not is_instance_valid(player_ref):
			var p_list = tree.get_nodes_in_group("players")
			if not p_list.is_empty():
				player_ref = p_list[0]

		if is_instance_valid(player_ref):
			var p_pos = to_canvas.call(player_ref.global_position)
			var p_fwd = -player_ref.global_transform.basis.z
			p_fwd.y = 0.0
			p_fwd = p_fwd.normalized()
			var p_arrow = Vector2(p_fwd.x, p_fwd.z) * 8.0
			draw_circle(p_pos, 5.0, Color(0.2, 1.0, 0.4))
			draw_line(p_pos, p_pos + p_arrow, Color(0.2, 1.0, 0.4), 2.0)

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
	setup_onboarding_overlay()
	check_mobile_controls()
	update_layout_positions()

func _on_viewport_size_changed() -> void:
	if get_viewport():
		size = get_viewport().get_visible_rect().size
		update_layout_positions()

func update_layout_positions() -> void:
	var vp = size
	if pos_panel and is_instance_valid(pos_panel):
		pos_panel.position = Vector2(24, 24)
	if obj_panel and is_instance_valid(obj_panel):
		obj_panel.position = Vector2((vp.x - 420) * 0.5, 20)
	if right_panel and is_instance_valid(right_panel):
		right_panel.position = Vector2(maxf(vp.x - 220, 24), 24)
	if minimap_panel and is_instance_valid(minimap_panel):
		minimap_panel.position = Vector2(24, maxf(vp.y - 200, 24))
	if countdown_panel and is_instance_valid(countdown_panel):
		countdown_panel.position = Vector2((vp.x - 280) * 0.5, (vp.y - 90) * 0.35)
	if finish_panel and is_instance_valid(finish_panel):
		finish_panel.position = Vector2((vp.x - 360) * 0.5, (vp.y - 100) * 0.4)
	if onboarding_overlay and is_instance_valid(onboarding_overlay):
		onboarding_overlay.position = Vector2((vp.x - 440) * 0.5, vp.y * 0.72 - 40)

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
	obj_panel = PanelContainer.new()
	obj_panel.custom_minimum_size = Vector2(420, 38)
	add_child(obj_panel)

	objective_badge = Label.new()
	objective_badge.text = "OBJECTIVE: COMPLETE 3 LAPS — FINISH 1ST"
	objective_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_badge.add_theme_font_size_override("font_size", 13)
	objective_badge.modulate = Color(0.9, 0.95, 1.0)
	obj_panel.add_child(objective_badge)

	# Top Right: Times & Powerup
	right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(196, 106)
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

func _setup_minimap() -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.custom_minimum_size = Vector2(176, 176)
	add_child(minimap_panel)

	minimap_canvas = CircuitMinimapCanvas.new()
	minimap_canvas.custom_minimum_size = Vector2(160, 160)
	minimap_panel.add_child(minimap_canvas)

func _process(_delta: float) -> void:
	if minimap_canvas and is_instance_valid(minimap_canvas):
		minimap_canvas.queue_redraw()

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

func show_countdown(val: Variant) -> void:
	if not countdown_panel or not countdown_label:
		return
	var text: String = str(val)
	if text == "0":
		text = "GO!"
	countdown_panel.visible = true
	countdown_panel.modulate.a = 1.0
	countdown_label.text = text
	if text == "GO!" or text == "GO":
		countdown_label.modulate = Color(0.0, 1.0, 0.5)
		countdown_label.add_theme_font_size_override("font_size", 64)
		var tween = create_tween()
		if tween:
			tween.tween_property(countdown_panel, "modulate:a", 0.0, 0.8).set_delay(0.6)
			tween.tween_callback(func():
				countdown_panel.visible = false
				countdown_panel.modulate.a = 1.0
			)
	else:
		countdown_label.modulate = Color(1.0, 0.85, 0.15)
		countdown_label.add_theme_font_size_override("font_size", 54)
		countdown_label.scale = Vector2(1.2, 1.2)
		countdown_label.pivot_offset = countdown_label.size * 0.5
		var tween = create_tween()
		if tween:
			tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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

	# Track Selection Row
	var trk_box = HBoxContainer.new()
	trk_box.alignment = BoxContainer.ALIGNMENT_CENTER
	trk_box.add_theme_constant_override("separation", 10)
	vbox.add_child(trk_box)

	var trk_lbl = Label.new()
	trk_lbl.text = "TRACK:"
	trk_lbl.modulate = Color(0.2, 0.9, 1.0)
	trk_lbl.add_theme_font_size_override("font_size", 13)
	trk_box.add_child(trk_lbl)

	var tracks = [["NEON CIRCUIT", "neon"], ["CANYON RUN", "canyon"], ["SKYLINE DRIFT", "skyline"]]
	for t in tracks:
		var btn = Button.new()
		btn.text = t[0]
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func():
			var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree:
				var km = tree.root.find_child("KartRacingMain", true, false)
				if km and km.has_method("select_track"):
					km.select_track(t[1])
					show_toast("TRACK SELECTED: " + t[0], Color(0.2, 0.9, 1.0))
		)
		trk_box.add_child(btn)

	# Vehicle Selection Row
	var veh_box = HBoxContainer.new()
	veh_box.alignment = BoxContainer.ALIGNMENT_CENTER
	veh_box.add_theme_constant_override("separation", 10)
	vbox.add_child(veh_box)

	var veh_lbl = Label.new()
	veh_lbl.text = "VEHICLE:"
	veh_lbl.modulate = Color(1.0, 0.8, 0.2)
	veh_lbl.add_theme_font_size_override("font_size", 13)
	veh_box.add_child(veh_lbl)

	var vehs = [["SPEED DEMON (Speeder)", "speeder"], ["TURBO TRUCK (Enforcer)", "enforcer"], ["PHANTOM DRIFT", "phantom"]]
	for v in vehs:
		var btn = Button.new()
		btn.text = v[0]
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func():
			var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree:
				var km = tree.root.find_child("KartRacingMain", true, false)
				if km and km.has_method("select_kart"):
					km.select_kart(v[1])
					show_toast("VEHICLE SELECTED: " + v[0], Color(1.0, 0.85, 0.2))
		)
		veh_box.add_child(btn)

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

	var start_btn = Button.new()
	start_btn.text = "START RACE (CLICK OR PRESS SPACE)"
	start_btn.add_theme_font_size_override("font_size", 14)
	start_btn.modulate = Color(0.2, 1.0, 0.5)
	start_btn.pressed.connect(dismiss_onboarding)
	vbox.add_child(start_btn)

func dismiss_onboarding() -> void:
	if is_instance_valid(onboarding_overlay):
		onboarding_overlay.visible = false
		onboarding_overlay.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_onboarding()

func _format_time(sec: float) -> String:
	var mins = int(sec) / 60
	var s = int(sec) % 60
	var ms = int((sec - int(sec)) * 10.0)
	return "%02d:%02d.%01d" % [mins, s, ms]
