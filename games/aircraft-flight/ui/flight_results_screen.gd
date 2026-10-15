class_name FlightResultsScreen
extends CanvasLayer

## FlightResultsScreen: Mission Debriefing & Flight Performance Dossier.
## Displays flight time, score breakdown, medal awarded, and flight hours.

var root_panel: PanelContainer
var title_label: Label
var mission_label: Label
var time_label: Label
var score_label: Label
var medal_label: Label
var medal_banner: PanelContainer

signal replay_requested()
signal hangar_requested()
signal launcher_requested()

func _ready() -> void:
	layer = 20
	_build_ui()
	visible = false

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.08, 0.82)
	add_child(bg)

	root_panel = PanelContainer.new()
	root_panel.custom_minimum_size = Vector2(440, 360)
	root_panel.set_anchors_preset(Control.PRESET_CENTER)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.11, 0.16, 0.95)
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.95, 0.3, 0.6)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	root_panel.add_theme_stylebox_override("panel", style)
	add_child(root_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	root_panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "MISSION DEBRIEFING"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	vbox.add_child(title_label)

	mission_label = Label.new()
	mission_label.text = "Commercial Runway Certification"
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_size_override("font_size", 14)
	mission_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(mission_label)

	medal_banner = PanelContainer.new()
	medal_banner.custom_minimum_size = Vector2(200, 42)
	var m_style = StyleBoxFlat.new()
	m_style.bg_color = Color(0.85, 0.65, 0.1, 0.25)
	m_style.set_corner_radius_all(8)
	medal_banner.add_theme_stylebox_override("panel", m_style)
	vbox.add_child(medal_banner)

	medal_label = Label.new()
	medal_label.text = "★ GOLD MEDAL AWARDED ★"
	medal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medal_label.add_theme_font_size_override("font_size", 16)
	medal_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	medal_banner.add_child(medal_label)

	time_label = Label.new()
	time_label.text = "Flight Time: 01:45.32"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(time_label)

	score_label = Label.new()
	score_label.text = "Flight Score: 4,850 PTS"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 15)
	score_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3))
	vbox.add_child(score_label)

	var hbox_btns = HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_btns)

	var btn_replay = Button.new()
	btn_replay.text = "RETRY"
	btn_replay.custom_minimum_size = Vector2(90, 36)
	btn_replay.pressed.connect(func(): replay_requested.emit())
	hbox_btns.add_child(btn_replay)

	var btn_hangar = Button.new()
	btn_hangar.text = "HANGAR"
	btn_hangar.custom_minimum_size = Vector2(90, 36)
	btn_hangar.pressed.connect(func(): hangar_requested.emit())
	hbox_btns.add_child(btn_hangar)

	var btn_launcher = Button.new()
	btn_launcher.text = "EXIT"
	btn_launcher.custom_minimum_size = Vector2(90, 36)
	btn_launcher.pressed.connect(func(): launcher_requested.emit())
	hbox_btns.add_child(btn_launcher)

func display_results(summary: Dictionary) -> void:
	visible = true
	var is_success = summary.get("success", false)
	title_label.text = "MISSION CERTIFIED" if is_success else "MISSION FAILED"
	title_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.3) if is_success else Color(1.0, 0.2, 0.2))

	mission_label.text = summary.get("title", "Flight Mission")
	var t_sec = summary.get("time_s", 0.0)
	var mins = int(t_sec) / 60
	var secs = fmod(t_sec, 60.0)
	time_label.text = "Flight Time: %02d:%05.2f" % [mins, secs]
	score_label.text = "Flight Score: %d PTS" % summary.get("score", 0)

	var medal = summary.get("medal", "Bronze")
	medal_label.text = "★ %s MEDAL AWARDED ★" % medal.to_upper()
