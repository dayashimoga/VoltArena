class_name AeroHUD
extends Control

## Modern Telemetry HUD for AeroRush: Impossible Circuit.
## Implements the premium glass-card telemetry interface:
## - Top-Left: Speedometer card (SPEED: 182 km/h + Nitro Gauge)
## - Top-Center: Stunt navigation card (NEXT: MEGA JUMP 240m ahead)
## - Top-Right: Course progression card (COURSE: 4 / 12 + Lap / Timer)
## - Bottom-Left: Stunt combo card (STUNT COMBO: x3.5 · 1,250 + combo timer)
## - Bottom-Right: Checkpoint progress card (NEXT CHECKPOINT: Progress bar + 66% progress)
## - Centered Countdown & Stunt Toasts with zero coordinate clipping.

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

# Top-Left: Speed Card
var speed_card: PanelContainer
var speed_label: Label
var speed_bar: ProgressBar
var boost_bar: ProgressBar

# Top-Center: Next Stunt Card
var next_stunt_card: PanelContainer
var next_stunt_title_label: Label
var next_stunt_dist_label: Label

# Top-Right: Course Card
var course_card: PanelContainer
var course_number_label: Label
var time_label: Label
var lap_label: Label

# Bottom-Left: Combo Card
var combo_badge: PanelContainer
var combo_mult_label: Label
var combo_score_label: Label
var combo_timer_bar: ProgressBar

# Bottom-Right: Checkpoint Card
var checkpoint_card: PanelContainer
var checkpoint_label: Label
var checkpoint_bar: ProgressBar
var checkpoint_pct_label: Label

# Center Overlay Alerts
var countdown_label: Label
var stunt_toast: Label

# Pause Menu
var pause_dialog: PanelContainer
var is_paused: bool = false

# Internal Metrics
var current_course_num: int = 1
var total_courses: int = 12
var current_cp_idx: int = 0
var total_cps: int = 4

signal restart_requested()
signal quit_to_menu_requested()

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	_build_hud_elements()
	_build_pause_menu()

func _make_glass_style(corner_radius: int = 14) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.16, 0.88)
	style.set_corner_radius_all(corner_radius)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.24, 0.32, 0.44, 0.55)
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	return style

func _build_hud_elements() -> void:
	# ==============================================================================
	# 1. TOP-LEFT: SPEED CARD (SPEED 182 km/h)
	# ==============================================================================
	speed_card = PanelContainer.new()
	speed_card.name = "SpeedCard"
	speed_card.add_theme_stylebox_override("panel", _make_glass_style())
	speed_card.position = Vector2(24, 20)
	speed_card.custom_minimum_size = Vector2(170, 75)
	add_child(speed_card)

	var speed_vbox = VBoxContainer.new()
	speed_vbox.add_theme_constant_override("separation", 2)
	speed_card.add_child(speed_vbox)

	var speed_hdr = Label.new()
	speed_hdr.text = "SPEED"
	speed_hdr.add_theme_font_size_override("font_size", 12)
	speed_hdr.add_theme_color_override("font_color", Color(0.60, 0.72, 0.88))
	speed_vbox.add_child(speed_hdr)

	speed_label = Label.new()
	speed_label.name = "SpeedLabel"
	speed_label.text = "0 km/h"
	speed_label.add_theme_font_size_override("font_size", 34)
	speed_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	speed_vbox.add_child(speed_label)

	boost_bar = ProgressBar.new()
	boost_bar.name = "BoostBar"
	boost_bar.custom_minimum_size = Vector2(140, 6)
	boost_bar.max_value = 1.0
	boost_bar.value = 1.0
	boost_bar.show_percentage = false
	speed_vbox.add_child(boost_bar)

	# Hidden for compatibility
	speed_bar = ProgressBar.new()
	speed_bar.name = "SpeedBar"
	speed_bar.visible = false
	add_child(speed_bar)

	# ==============================================================================
	# 2. TOP-CENTER: NEXT STUNT / JUMP CARD (NEXT: MEGA JUMP 240 m ahead)
	# ==============================================================================
	next_stunt_card = PanelContainer.new()
	next_stunt_card.name = "NextStuntCard"
	next_stunt_card.add_theme_stylebox_override("panel", _make_glass_style())
	next_stunt_card.anchor_left = 0.5
	next_stunt_card.anchor_right = 0.5
	next_stunt_card.anchor_top = 0.0
	next_stunt_card.anchor_bottom = 0.0
	next_stunt_card.offset_left = -140
	next_stunt_card.offset_right = 140
	next_stunt_card.offset_top = 20
	next_stunt_card.offset_bottom = 85
	next_stunt_card.custom_minimum_size = Vector2(280, 65)
	add_child(next_stunt_card)

	var stunt_vbox = VBoxContainer.new()
	stunt_vbox.add_theme_constant_override("separation", 2)
	next_stunt_card.add_child(stunt_vbox)

	next_stunt_title_label = Label.new()
	next_stunt_title_label.name = "NextStuntTitle"
	next_stunt_title_label.text = "NEXT: MEGA JUMP"
	next_stunt_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_stunt_title_label.add_theme_font_size_override("font_size", 13)
	next_stunt_title_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	stunt_vbox.add_child(next_stunt_title_label)

	next_stunt_dist_label = Label.new()
	next_stunt_dist_label.name = "NextStuntDistance"
	next_stunt_dist_label.text = "240 m ahead"
	next_stunt_dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_stunt_dist_label.add_theme_font_size_override("font_size", 20)
	next_stunt_dist_label.add_theme_color_override("font_color", Color(0.32, 0.82, 1.0))
	stunt_vbox.add_child(next_stunt_dist_label)

	# ==============================================================================
	# 3. TOP-RIGHT: COURSE CARD (COURSE 4 / 12)
	# ==============================================================================
	course_card = PanelContainer.new()
	course_card.name = "CourseCard"
	course_card.add_theme_stylebox_override("panel", _make_glass_style())
	course_card.anchor_left = 1.0
	course_card.anchor_right = 1.0
	course_card.anchor_top = 0.0
	course_card.anchor_bottom = 0.0
	course_card.offset_left = -210
	course_card.offset_right = -24
	course_card.offset_top = 20
	course_card.offset_bottom = 95
	course_card.custom_minimum_size = Vector2(180, 75)
	add_child(course_card)

	var course_vbox = VBoxContainer.new()
	course_vbox.add_theme_constant_override("separation", 2)
	course_card.add_child(course_vbox)

	var course_hdr = Label.new()
	course_hdr.text = "COURSE"
	course_hdr.add_theme_font_size_override("font_size", 12)
	course_hdr.add_theme_color_override("font_color", Color(0.60, 0.72, 0.88))
	course_vbox.add_child(course_hdr)

	course_number_label = Label.new()
	course_number_label.name = "CourseNumberLabel"
	course_number_label.text = "1 / 12"
	course_number_label.add_theme_font_size_override("font_size", 28)
	course_number_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	course_vbox.add_child(course_number_label)

	var time_row = HBoxContainer.new()
	course_vbox.add_child(time_row)

	lap_label = Label.new()
	lap_label.name = "LapLabel"
	lap_label.text = "LAP 1/2"
	lap_label.add_theme_font_size_override("font_size", 11)
	lap_label.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
	time_row.add_child(lap_label)

	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = " · 00:00.00"
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	time_row.add_child(time_label)

	# ==============================================================================
	# 4. BOTTOM-LEFT: STUNT COMBO CARD (STUNT COMBO x3.5 · 1,250)
	# ==============================================================================
	combo_badge = PanelContainer.new()
	combo_badge.name = "ComboBadge"
	combo_badge.add_theme_stylebox_override("panel", _make_glass_style())
	combo_badge.anchor_left = 0.0
	combo_badge.anchor_right = 0.0
	combo_badge.anchor_top = 1.0
	combo_badge.anchor_bottom = 1.0
	combo_badge.offset_left = 24
	combo_badge.offset_right = 230
	combo_badge.offset_top = -90
	combo_badge.offset_bottom = -20
	combo_badge.custom_minimum_size = Vector2(206, 70)
	add_child(combo_badge)

	var combo_vbox = VBoxContainer.new()
	combo_vbox.add_theme_constant_override("separation", 2)
	combo_badge.add_child(combo_vbox)

	var combo_hdr = Label.new()
	combo_hdr.text = "STUNT COMBO"
	combo_hdr.add_theme_font_size_override("font_size", 12)
	combo_hdr.add_theme_color_override("font_color", Color(0.60, 0.72, 0.88))
	combo_vbox.add_child(combo_hdr)

	var combo_val_row = HBoxContainer.new()
	combo_vbox.add_child(combo_val_row)

	combo_mult_label = Label.new()
	combo_mult_label.name = "ComboMultLabel"
	combo_mult_label.text = "x1.0"
	combo_mult_label.add_theme_font_size_override("font_size", 22)
	combo_mult_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.20))
	combo_val_row.add_child(combo_mult_label)

	combo_score_label = Label.new()
	combo_score_label.name = "ComboScoreLabel"
	combo_score_label.text = " · 0"
	combo_score_label.add_theme_font_size_override("font_size", 22)
	combo_score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.20))
	combo_val_row.add_child(combo_score_label)

	combo_timer_bar = ProgressBar.new()
	combo_timer_bar.name = "ComboTimerBar"
	combo_timer_bar.custom_minimum_size = Vector2(170, 5)
	combo_timer_bar.max_value = 1.0
	combo_timer_bar.value = 1.0
	combo_timer_bar.show_percentage = false
	combo_vbox.add_child(combo_timer_bar)

	# ==============================================================================
	# 5. BOTTOM-RIGHT: NEXT CHECKPOINT CARD (NEXT CHECKPOINT 66% progress)
	# ==============================================================================
	checkpoint_card = PanelContainer.new()
	checkpoint_card.name = "CheckpointCard"
	checkpoint_card.add_theme_stylebox_override("panel", _make_glass_style())
	checkpoint_card.anchor_left = 1.0
	checkpoint_card.anchor_right = 1.0
	checkpoint_card.anchor_top = 1.0
	checkpoint_card.anchor_bottom = 1.0
	checkpoint_card.offset_left = -250
	checkpoint_card.offset_right = -24
	checkpoint_card.offset_top = -90
	checkpoint_card.offset_bottom = -20
	checkpoint_card.custom_minimum_size = Vector2(220, 70)
	add_child(checkpoint_card)

	var cp_vbox = VBoxContainer.new()
	cp_vbox.add_theme_constant_override("separation", 4)
	checkpoint_card.add_child(cp_vbox)

	var cp_hdr = Label.new()
	cp_hdr.text = "NEXT CHECKPOINT"
	cp_hdr.add_theme_font_size_override("font_size", 12)
	cp_hdr.add_theme_color_override("font_color", Color(0.60, 0.72, 0.88))
	cp_vbox.add_child(cp_hdr)

	checkpoint_bar = ProgressBar.new()
	checkpoint_bar.name = "CheckpointBar"
	checkpoint_bar.custom_minimum_size = Vector2(188, 8)
	checkpoint_bar.max_value = 100.0
	checkpoint_bar.value = 0.0
	checkpoint_bar.show_percentage = false
	cp_vbox.add_child(checkpoint_bar)

	var cp_foot_row = HBoxContainer.new()
	cp_vbox.add_child(cp_foot_row)

	checkpoint_pct_label = Label.new()
	checkpoint_pct_label.name = "CheckpointPctLabel"
	checkpoint_pct_label.text = "0% progress"
	checkpoint_pct_label.add_theme_font_size_override("font_size", 11)
	checkpoint_pct_label.add_theme_color_override("font_color", Color(0.70, 0.80, 0.90))
	cp_foot_row.add_child(checkpoint_pct_label)

	checkpoint_label = Label.new()
	checkpoint_label.name = "CheckpointLabel"
	checkpoint_label.text = " · 1 / 4"
	checkpoint_label.add_theme_font_size_override("font_size", 11)
	checkpoint_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	cp_foot_row.add_child(checkpoint_label)

	# ==============================================================================
	# 6. CENTER NOTIFICATIONS & ZERO-CLIPPING COUNTDOWN
	# ==============================================================================
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_right = 0.5
	countdown_label.anchor_top = 0.35
	countdown_label.anchor_bottom = 0.35
	countdown_label.offset_left = -300
	countdown_label.offset_right = 300
	countdown_label.offset_top = -60
	countdown_label.offset_bottom = 60
	countdown_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	countdown_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	countdown_label.text = ""
	countdown_label.add_theme_font_size_override("font_size", 64)
	countdown_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(countdown_label)

	stunt_toast = Label.new()
	stunt_toast.name = "StuntToast"
	stunt_toast.anchor_left = 0.5
	stunt_toast.anchor_right = 0.5
	stunt_toast.anchor_top = 0.55
	stunt_toast.anchor_bottom = 0.55
	stunt_toast.offset_left = -300
	stunt_toast.offset_right = 300
	stunt_toast.offset_top = -25
	stunt_toast.offset_bottom = 25
	stunt_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	stunt_toast.grow_vertical = Control.GROW_DIRECTION_BOTH
	stunt_toast.text = ""
	stunt_toast.add_theme_font_size_override("font_size", 26)
	stunt_toast.add_theme_color_override("font_color", Color(0.1, 1.0, 0.7))
	stunt_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stunt_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(stunt_toast)

func _build_pause_menu() -> void:
	pause_dialog = PanelContainer.new()
	pause_dialog.name = "PauseDialog"
	pause_dialog.add_theme_stylebox_override("panel", _make_glass_style(16))
	pause_dialog.anchor_left = 0.5
	pause_dialog.anchor_right = 0.5
	pause_dialog.anchor_top = 0.5
	pause_dialog.anchor_bottom = 0.5
	pause_dialog.offset_left = -160
	pause_dialog.offset_right = 160
	pause_dialog.offset_top = -130
	pause_dialog.offset_bottom = 130
	pause_dialog.custom_minimum_size = Vector2(320, 260)
	pause_dialog.visible = false
	pause_dialog.mouse_filter = MOUSE_FILTER_STOP
	add_child(pause_dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	pause_dialog.add_child(vbox)

	var title = Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "RESUME"
	resume_btn.pressed.connect(toggle_pause)
	vbox.add_child(resume_btn)

	var restart_btn = Button.new()
	restart_btn.text = "RESTART COURSE"
	restart_btn.pressed.connect(func():
		toggle_pause()
		restart_requested.emit()
	)
	vbox.add_child(restart_btn)

	var quit_btn = Button.new()
	quit_btn.text = "EXIT TO MENU"
	quit_btn.pressed.connect(func():
		toggle_pause()
		quit_to_menu_requested.emit()
	)
	vbox.add_child(quit_btn)

# --- Public Telemetry API ---

func update_speed(speed_kmh: float) -> void:
	if speed_label:
		speed_label.text = "%d km/h" % int(speed_kmh)
	if speed_bar:
		speed_bar.value = speed_kmh

func update_boost(current: float, max_val: float) -> void:
	if boost_bar:
		boost_bar.max_value = max_val
		boost_bar.value = current

func update_time(time_seconds: float) -> void:
	if time_label:
		var mins = int(time_seconds) / 60
		var secs = int(time_seconds) % 60
		var ms = int((time_seconds - int(time_seconds)) * 100.0)
		time_label.text = "%02d:%02d.%02d" % [mins, secs, ms]

func update_lap(cur_lap: int, total_laps: int) -> void:
	if lap_label:
		lap_label.text = "LAP %d / %d" % [cur_lap, total_laps]

func update_course(course_index: int, total_count: int = 12) -> void:
	update_course_progression(course_index, total_count)

func update_course_progression(course_index: int, total_count: int = 12) -> void:
	current_course_num = course_index
	total_courses = total_count
	if course_number_label:
		course_number_label.text = "%d / %d" % [course_index, total_count]

func update_checkpoint(current: int, total: int) -> void:
	current_cp_idx = current
	total_cps = max(1, total)
	if checkpoint_label:
		checkpoint_label.text = " · %d / %d" % [current, total]
	var pct = clampf((float(current) / float(total_cps)) * 100.0, 0.0, 100.0)
	if checkpoint_bar:
		checkpoint_bar.value = pct
	if checkpoint_pct_label:
		checkpoint_pct_label.text = "%d%% progress" % int(pct)

func update_next_stunt(title_text: String, distance_meters: float) -> void:
	if next_stunt_title_label:
		next_stunt_title_label.text = title_text.to_upper()
	if next_stunt_dist_label:
		next_stunt_dist_label.text = "%d m ahead" % int(distance_meters)

func set_countdown_text(txt: String) -> void:
	if countdown_label:
		countdown_label.text = txt
		countdown_label.visible = not txt.is_empty()

func show_stunt_toast(label: String, points: int) -> void:
	if stunt_toast:
		stunt_toast.text = ("+%d %s" % [points, label]) if points > 0 else label
		stunt_toast.modulate.a = 1.0
		var tw = create_tween()
		if tw:
			tw.tween_interval(1.2)
			tw.tween_property(stunt_toast, "modulate:a", 0.0, 0.4)

func update_combo(multiplier: int, score: int, time_ratio: float, label: String = "") -> void:
	if combo_badge:
		combo_badge.visible = multiplier > 1 or score > 0
		if combo_mult_label:
			combo_mult_label.text = "x%d" % multiplier
		if combo_score_label:
			combo_score_label.text = " · %s" % _format_number(score)
		if combo_timer_bar:
			combo_timer_bar.value = time_ratio
	if not label.is_empty():
		show_stunt_toast(label, score)

func hide_combo() -> void:
	if combo_badge:
		combo_badge.visible = false

func toggle_pause() -> void:
	is_paused = not is_paused
	pause_dialog.visible = is_paused
	get_tree().paused = is_paused
	mouse_filter = MOUSE_FILTER_STOP if is_paused else MOUSE_FILTER_IGNORE

func _format_number(n: int) -> String:
	var s = str(abs(n))
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res if n >= 0 else "-" + res
