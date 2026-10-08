class_name AeroHUD
extends Control

## In-game telemetry HUD for AeroRush: Impossible Circuit.
## Displays speed, nitro boost gauge, race timer, checkpoint progress,
## dynamic stunt trick toasts, and combo multiplier bar.

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

var speed_label: Label
var speed_bar: ProgressBar
var boost_bar: ProgressBar
var time_label: Label
var lap_label: Label
var checkpoint_label: Label
var stunt_toast: Label
var combo_badge: PanelContainer
var combo_mult_label: Label
var combo_score_label: Label
var combo_timer_bar: ProgressBar
var countdown_label: Label

var pause_dialog: PanelContainer
var is_paused: bool = false

signal restart_requested()
signal quit_to_menu_requested()

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

	_build_hud_elements()
	_build_pause_menu()

func _build_hud_elements() -> void:
	# 1. Top Left: Speedometer & Telemetry
	var speed_box = VBoxContainer.new()
	speed_box.name = "SpeedBox"
	speed_box.position = Vector2(24, 20)
	add_child(speed_box)

	speed_label = Label.new()
	speed_label.name = "SpeedLabel"
	speed_label.text = "0 KM/H"
	speed_label.add_theme_font_size_override("font_size", 34)
	speed_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	speed_box.add_child(speed_label)

	speed_bar = ProgressBar.new()
	speed_bar.name = "SpeedBar"
	speed_bar.custom_minimum_size = Vector2(180, 8)
	speed_bar.max_value = 240.0
	speed_bar.value = 0.0
	speed_bar.show_percentage = false
	speed_box.add_child(speed_bar)

	# 2. Bottom Left: Nitro Boost Meter
	var boost_box = VBoxContainer.new()
	boost_box.name = "BoostBox"
	boost_box.set_anchors_preset(PRESET_BOTTOM_LEFT)
	boost_box.position = Vector2(24, -75)
	add_child(boost_box)

	var boost_lbl = Label.new()
	boost_lbl.text = "NITRO BOOST"
	boost_lbl.add_theme_font_size_override("font_size", 13)
	boost_lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	boost_box.add_child(boost_lbl)

	boost_bar = ProgressBar.new()
	boost_bar.name = "BoostBar"
	boost_bar.custom_minimum_size = Vector2(220, 14)
	boost_bar.max_value = 1.0
	boost_bar.value = 1.0
	boost_bar.show_percentage = false
	boost_box.add_child(boost_bar)

	# 3. Top Right: Lap & Race Timer
	var top_right = VBoxContainer.new()
	top_right.name = "TopRightBox"
	top_right.set_anchors_preset(PRESET_TOP_RIGHT)
	top_right.position = Vector2(-220, 20)
	add_child(top_right)

	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "00:00.00"
	time_label.add_theme_font_size_override("font_size", 28)
	time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	top_right.add_child(time_label)

	lap_label = Label.new()
	lap_label.name = "LapLabel"
	lap_label.text = "LAP 1 / 2"
	lap_label.add_theme_font_size_override("font_size", 16)
	lap_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	top_right.add_child(lap_label)

	checkpoint_label = Label.new()
	checkpoint_label.name = "CheckpointLabel"
	checkpoint_label.text = "CHECKPOINT 1 / 4"
	checkpoint_label.add_theme_font_size_override("font_size", 14)
	checkpoint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	top_right.add_child(checkpoint_label)

	# 4. Center Countdown Label (Rock-solid resolution-independent centering)
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_right = 0.5
	countdown_label.anchor_top = 0.35
	countdown_label.anchor_bottom = 0.35
	countdown_label.offset_left = -250
	countdown_label.offset_right = 250
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

	# 5. Stunt Toast (Resolution-independent center-screen notification; eliminates off-screen clipping)
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

	# 6. Bottom Right: Combo Multiplier Badge
	combo_badge = PanelContainer.new()
	combo_badge.name = "ComboBadge"
	combo_badge.anchor_left = 1.0
	combo_badge.anchor_right = 1.0
	combo_badge.anchor_top = 1.0
	combo_badge.anchor_bottom = 1.0
	combo_badge.offset_left = -250
	combo_badge.offset_right = -20
	combo_badge.offset_top = -120
	combo_badge.offset_bottom = -25
	combo_badge.custom_minimum_size = Vector2(210, 85)
	add_child(combo_badge)

	var c_vbox = VBoxContainer.new()
	combo_badge.add_child(c_vbox)

	var c_header = HBoxContainer.new()
	c_vbox.add_child(c_header)

	combo_mult_label = Label.new()
	combo_mult_label.name = "ComboMultLabel"
	combo_mult_label.text = "x1"
	combo_mult_label.add_theme_font_size_override("font_size", 26)
	combo_mult_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	c_header.add_child(combo_mult_label)

	combo_score_label = Label.new()
	combo_score_label.name = "ComboScoreLabel"
	combo_score_label.text = "0 PTS"
	combo_score_label.add_theme_font_size_override("font_size", 18)
	combo_score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	c_header.add_child(combo_score_label)

	combo_timer_bar = ProgressBar.new()
	combo_timer_bar.name = "ComboTimerBar"
	combo_timer_bar.custom_minimum_size = Vector2(190, 6)
	combo_timer_bar.max_value = 1.0
	combo_timer_bar.value = 0.0
	combo_timer_bar.show_percentage = false
	c_vbox.add_child(combo_timer_bar)

	combo_badge.visible = false

func _build_pause_menu() -> void:
	pause_dialog = PanelContainer.new()
	pause_dialog.name = "PauseDialog"
	pause_dialog.set_anchors_preset(PRESET_CENTER)
	pause_dialog.position = Vector2(-150, -120)
	pause_dialog.custom_minimum_size = Vector2(300, 240)
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

func update_speed(speed_kmh: float) -> void:
	if speed_label:
		speed_label.text = "%d KM/H" % int(speed_kmh)
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

func update_checkpoint(current: int, total: int) -> void:
	if checkpoint_label:
		checkpoint_label.text = "CHECKPOINT %d / %d" % [current, total]

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
			combo_score_label.text = "%d PTS" % score
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
