class_name StrikeResultsScreen
extends CanvasLayer

## End-of-mission results and S/A/B/C grading screen for Strike Vector.

signal next_mission_requested()
signal restart_requested()
signal launcher_requested()

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

var panel: PanelContainer
var title_label: Label
var grade_label: Label
var stats_vbox: VBoxContainer
var btn_next: Button

func _ready() -> void:
	layer = 10
	setup_ui()
	hide_results()

func setup_ui() -> void:
	var control = Control.new()
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.theme = ThemeGen.get_theme()
	add_child(control)

	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.05, 0.07, 0.12, 0.88)
	control.add_child(bg)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_top = -220
	panel.offset_right = 250
	panel.offset_bottom = 220
	control.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "MISSION COMPLETE"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.modulate = Color(0.0, 1.0, 1.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	grade_label = Label.new()
	grade_label.text = "RANK S"
	grade_label.add_theme_font_size_override("font_size", 48)
	grade_label.modulate = Color(1.0, 0.85, 0.1)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(grade_label)

	stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_vbox)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_hbox)

	var btn_restart = Button.new()
	btn_restart.text = "REPLAY"
	btn_restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_restart.pressed.connect(func(): restart_requested.emit())
	btn_hbox.add_child(btn_restart)

	btn_next = Button.new()
	btn_next.text = "NEXT MISSION"
	btn_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_next.pressed.connect(func(): next_mission_requested.emit())
	btn_hbox.add_child(btn_next)

	var btn_launcher = Button.new()
	btn_launcher.text = "LAUNCHER"
	btn_launcher.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_launcher.pressed.connect(func(): launcher_requested.emit())
	btn_hbox.add_child(btn_launcher)

func display_results(results: Dictionary) -> void:
	for child in stats_vbox.get_children():
		child.queue_free()

	var m_name = results.get("mission_name", "Mission")
	var grade = results.get("grade", "A")
	var score = results.get("score", 0)
	var time_sec = results.get("time", 0.0)
	var kills = results.get("kills", 0)
	var deaths = results.get("deaths", 0)

	title_label.text = m_name.to_upper() + " // COMPLETED"
	grade_label.text = "RANK " + grade

	match grade:
		"S": grade_label.modulate = Color(1.0, 0.85, 0.1) # Gold
		"A": grade_label.modulate = Color(0.2, 1.0, 0.4) # Green
		"B": grade_label.modulate = Color(0.1, 0.7, 1.0) # Blue
		_: grade_label.modulate = Color(0.8, 0.8, 0.8) # Silver

	_add_stat_row("Final Score", str(score))
	_add_stat_row("Clear Time", "%02d:%02d" % [int(time_sec) / 60, int(time_sec) % 60])
	_add_stat_row("Hostiles Neutralized", str(kills))
	_add_stat_row("Casualties", str(deaths))

	visible = true

	# Release mouse capture for UI
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and im.has_method("capture_mouse"):
		im.capture_mouse(false)

func _add_stat_row(label_text: String, val_text: String) -> void:
	var row = HBoxContainer.new()
	stats_vbox.add_child(row)

	var l = Label.new()
	l.text = label_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.modulate = Color(0.7, 0.8, 0.9)
	row.add_child(l)

	var v = Label.new()
	v.text = val_text
	v.modulate = Color(1.0, 1.0, 1.0)
	row.add_child(v)

func hide_results() -> void:
	visible = false
