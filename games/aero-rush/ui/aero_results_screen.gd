class_name AeroResultsScreen
extends Control

## Victory, results, and rewards screen for AeroRush: Impossible Circuit.
## Displays final times, stunt scores, awarded medals, credit payouts, and next-stage navigation.

signal next_course_requested()
signal retry_requested()
signal return_to_menu_requested()
signal return_to_hub_requested()

var title_label: Label
var medal_label: Label
var time_stat_label: Label
var stunt_stat_label: Label
var total_score_label: Label
var credits_label: Label
var next_btn: Button

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false

	_build_ui()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.10, 0.88)
	add_child(bg)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.position = Vector2(-240, -220)
	panel.custom_minimum_size = Vector2(480, 440)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "COURSE COMPLETED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	vbox.add_child(title_label)

	medal_label = Label.new()
	medal_label.name = "MedalLabel"
	medal_label.text = "★ GOLD MEDAL ★"
	medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medal_label.add_theme_font_size_override("font_size", 24)
	medal_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vbox.add_child(medal_label)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(stats_grid)

	_add_stat_row(stats_grid, "TIME ELAPSED:", "01:14.22", "TimeStat")
	_add_stat_row(stats_grid, "STUNT POINTS:", "14,500 PTS", "StuntStat")
	_add_stat_row(stats_grid, "TOTAL SCORE:", "18,200 PTS", "TotalStat")
	_add_stat_row(stats_grid, "CREDITS REWARD:", "+1,200 CR", "CreditsStat")

	vbox.add_spacer(false)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_vbox)

	next_btn = Button.new()
	next_btn.text = "NEXT COURSE"
	next_btn.custom_minimum_size = Vector2(0, 42)
	next_btn.pressed.connect(func(): next_course_requested.emit())
	btn_vbox.add_child(next_btn)

	var retry_btn = Button.new()
	retry_btn.text = "RETRY"
	retry_btn.custom_minimum_size = Vector2(0, 36)
	retry_btn.pressed.connect(func(): retry_requested.emit())
	btn_vbox.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.text = "AERORUSH MENU"
	menu_btn.custom_minimum_size = Vector2(0, 36)
	menu_btn.pressed.connect(func(): return_to_menu_requested.emit())
	btn_vbox.add_child(menu_btn)

	var hub_btn = Button.new()
	hub_btn.text = "RETURN TO VOLTARENA"
	hub_btn.custom_minimum_size = Vector2(0, 36)
	hub_btn.pressed.connect(func(): return_to_hub_requested.emit())
	btn_vbox.add_child(hub_btn)

func _add_stat_row(grid: GridContainer, label_text: String, val_text: String, val_name: String) -> void:
	var l = Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	grid.add_child(l)

	var v = Label.new()
	v.name = val_name
	v.text = val_text
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	grid.add_child(v)

	match val_name:
		"TimeStat": time_stat_label = v
		"StuntStat": stunt_stat_label = v
		"TotalStat": total_score_label = v
		"CreditsStat": credits_label = v

func display_results(results: Dictionary) -> void:
	if not title_label:
		_build_ui()
	var course_name = results.get("course_name", "CIRCUIT")
	var time_taken = results.get("time_taken", 0.0) as float
	var stunt_score = results.get("stunt_score", 0) as int
	var total_score = results.get("total_score", 0) as int
	var credits = results.get("credits_earned", 500) as int
	var medal = results.get("medal", 3) as int

	title_label.text = "%s CLEARED" % course_name.to_upper()

	var mins = int(time_taken) / 60
	var secs = int(time_taken) % 60
	var ms = int((time_taken - int(time_taken)) * 100.0)
	time_stat_label.text = "%02d:%02d.%02d" % [mins, secs, ms]
	stunt_stat_label.text = "%d PTS" % stunt_score
	total_score_label.text = "%d PTS" % total_score
	credits_label.text = "+%d CR" % credits

	match medal:
		4:
			medal_label.text = "★★★ PLATINUM TROPHY ★★★"
			medal_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		3:
			medal_label.text = "★ GOLD MEDAL ★"
			medal_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		2:
			medal_label.text = "★ SILVER MEDAL ★"
			medal_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		1:
			medal_label.text = "★ BRONZE MEDAL ★"
			medal_label.add_theme_color_override("font_color", Color(0.85, 0.55, 0.25))
		_:
			medal_label.text = "COURSE COMPLETED"
			medal_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	visible = true
