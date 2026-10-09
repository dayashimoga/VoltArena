class_name AeroCourseSelect
extends Control

## Course selection browser for AeroRush: Impossible Circuit.
## Displays all 12 handcrafted circuits, environment tags, game modes,
## earned medals, and personal records across Tiers 1-4.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroCourseDatabase = preload("res://games/aero-rush/tracks/aero_course_database.gd")
const AeroSaveAdapter = preload("res://games/aero-rush/persistence/aero_save_adapter.gd")

signal course_chosen(course_id: String)
signal back_requested()

var course_list: Array[Dictionary] = []
var selected_idx: int = 0

var name_label: Label
var env_mode_label: Label
var desc_label: Label
var best_time_label: Label
var high_score_label: Label
var medal_label: Label
var start_btn: Button

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	course_list = AeroCourseDatabase.get_all_courses()
	_build_ui()
	_refresh_display()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.11, 0.95)
	add_child(bg)

	# Header
	var title = Label.new()
	title.text = "SELECT STUNT CIRCUIT"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	add_child(title)

	# Left Panel: Course Details
	var detail_panel = PanelContainer.new()
	detail_panel.position = Vector2(40, 95)
	detail_panel.custom_minimum_size = Vector2(440, 500)
	add_child(detail_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	detail_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = "NEON EXPRESS"
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(name_label)

	env_mode_label = Label.new()
	env_mode_label.text = "MEGACITY // CIRCUIT // 2 LAPS"
	env_mode_label.add_theme_font_size_override("font_size", 14)
	env_mode_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vbox.add_child(env_mode_label)

	desc_label = Label.new()
	desc_label.text = "High-speed highway track."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	medal_label = Label.new()
	medal_label.text = "MEDAL: ★ GOLD ★"
	medal_label.add_theme_font_size_override("font_size", 18)
	medal_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vbox.add_child(medal_label)

	best_time_label = Label.new()
	best_time_label.text = "BEST LAP: 01:12.44"
	best_time_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(best_time_label)

	high_score_label = Label.new()
	high_score_label.text = "RECORD SCORE: 14,200 PTS"
	high_score_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(high_score_label)

	vbox.add_spacer(false)

	start_btn = Button.new()
	start_btn.text = "LAUNCH CIRCUIT"
	start_btn.custom_minimum_size = Vector2(0, 46)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	# Right Scroll / List of Courses
	var list_panel = PanelContainer.new()
	list_panel.position = Vector2(510, 95)
	list_panel.custom_minimum_size = Vector2(720, 500)
	add_child(list_panel)

	var scroll = ScrollContainer.new()
	list_panel.add_child(scroll)

	var c_list_vbox = VBoxContainer.new()
	c_list_vbox.custom_minimum_size = Vector2(700, 0)
	c_list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(c_list_vbox)

	for i in range(course_list.size()):
		var c = course_list[i]
		var btn = Button.new()
		btn.text = "%d. %s  [%s]" % [i + 1, c.get("name", ""), c.get("tagline", "")]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(func(idx = i):
			selected_idx = idx
			_refresh_display()
		)
		c_list_vbox.add_child(btn)

	# Back Button
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.position = Vector2(40, 640)
	back_btn.custom_minimum_size = Vector2(160, 38)
	back_btn.pressed.connect(func(): back_requested.emit())
	add_child(back_btn)

func _refresh_display() -> void:
	if course_list.is_empty():
		return
	var c = course_list[selected_idx]
	name_label.text = c.get("name", "").to_upper()
	desc_label.text = c.get("desc", "")

	var env_name = "NEON AFTERDARK"
	match c.get("environment", 0):
		AeroConstants.EnvironmentType.SNOWBOUND_PEAKS: env_name = "SNOWBOUND PEAKS"
		AeroConstants.EnvironmentType.COASTAL_VELOCITY, AeroConstants.EnvironmentType.TROPICAL_COASTAL: env_name = "COASTAL VELOCITY"
		AeroConstants.EnvironmentType.WILD_FOREST: env_name = "WILD FOREST"
		AeroConstants.EnvironmentType.SKYLINE_RUSH, AeroConstants.EnvironmentType.SKY_CIRCUIT: env_name = "SKYLINE RUSH"
		AeroConstants.EnvironmentType.DESERT_EXTREME, AeroConstants.EnvironmentType.MOUNTAIN_CANYON: env_name = "DESERT EXTREME"
		AeroConstants.EnvironmentType.NEON_AFTERDARK, AeroConstants.EnvironmentType.NEON_MEGACITY: env_name = "NEON AFTERDARK"

	var mode_name = "CIRCUIT"
	match c.get("mode", 0):
		AeroConstants.GameMode.SPRINT: mode_name = "SPRINT"
		AeroConstants.GameMode.TIME_ATTACK: mode_name = "TIME ATTACK"
		AeroConstants.GameMode.STUNT_CHALLENGE: mode_name = "STUNT CHALLENGE"
		AeroConstants.GameMode.CHECKPOINT_RUSH: mode_name = "CHECKPOINT RUSH"
		AeroConstants.GameMode.HAZARD_RUN: mode_name = "HAZARD RUN"

	var laps = c.get("laps", 1)
	env_mode_label.text = "%s // %s // %d LAP%s" % [env_name, mode_name, laps, ("S" if laps > 1 else "")]

	var data = AeroSaveAdapter.load_aero_data()
	var c_id = c.get("id", "")
	var best_t = data.get("best_times", {}).get(c_id, 0.0) as float
	var high_s = data.get("highest_scores", {}).get(c_id, 0) as int
	var medal = data.get("course_medals", {}).get(c_id, 0) as int

	if best_t > 0.0:
		var mins = int(best_t) / 60
		var secs = int(best_t) % 60
		var ms = int((best_t - int(best_t)) * 100.0)
		best_time_label.text = "BEST TIME: %02d:%02d.%02d" % [mins, secs, ms]
	else:
		best_time_label.text = "BEST TIME: --:--.--"

	high_score_label.text = "RECORD SCORE: %d PTS" % high_s

	match medal:
		4: medal_label.text = "MEDAL: ★★★ PLATINUM ★★★"
		3: medal_label.text = "MEDAL: ★ GOLD ★"
		2: medal_label.text = "MEDAL: ★ SILVER ★"
		1: medal_label.text = "MEDAL: ★ BRONZE ★"
		_: medal_label.text = "MEDAL: NONE"

	var tier = c.get("tier", 1) as int
	var unlocked_tiers = data.get("unlocked_tiers", [1])
	var is_unlocked = tier in unlocked_tiers

	start_btn.disabled = not is_unlocked
	if not is_unlocked:
		start_btn.text = "LOCKED [TIER %d]" % tier
	else:
		start_btn.text = "LAUNCH CIRCUIT"

func _on_start_pressed() -> void:
	var c = course_list[selected_idx]
	course_chosen.emit(c.get("id", "neon_express"))
