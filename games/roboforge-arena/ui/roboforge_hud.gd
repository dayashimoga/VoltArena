class_name RoboForgeHUD
extends Control

## RoboForgeHUD: Production-quality responsive UI for RoboForge Arena.
## Provides Workshop Assembly Controls, Live Stat Gauges, Power Bar, and Challenge Tracker.

signal chassis_selected(id: String)
signal locomotion_selected(id: String)
signal module_toggled(id: String)
signal challenge_selected(id: String)
signal test_dyno_pressed()

var workshop_panel: PanelContainer
var in_game_hud: Control
var power_bar: ProgressBar
var mass_label: Label
var speed_label: Label
var timer_label: Label
var objective_label: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_ui()

func setup_ui() -> void:
	# 1. In-Game HUD overlay (Visible ONLY during challenges)
	in_game_hud = Control.new()
	in_game_hud.name = "InGameHUD"
	in_game_hud.anchor_right = 1.0
	in_game_hud.anchor_bottom = 1.0
	in_game_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	in_game_hud.visible = false
	add_child(in_game_hud)

	# Top-Left Telemetry
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(24, 20)
	top_left.add_theme_constant_override("separation", 6)
	in_game_hud.add_child(top_left)

	var p_title = Label.new()
	p_title.text = "ROBOT POWER"
	p_title.modulate = Color(0.2, 0.9, 1.0)
	p_title.add_theme_font_size_override("font_size", 14)
	top_left.add_child(p_title)

	power_bar = ProgressBar.new()
	power_bar.custom_minimum_size = Vector2(220, 12)
	power_bar.max_value = 100.0
	power_bar.value = 100.0
	power_bar.show_percentage = false
	top_left.add_child(power_bar)

	mass_label = Label.new()
	mass_label.text = "MASS: 320 KG"
	mass_label.add_theme_font_size_override("font_size", 13)
	top_left.add_child(mass_label)

	speed_label = Label.new()
	speed_label.text = "SPEED: 0.0 M/S"
	speed_label.add_theme_font_size_override("font_size", 13)
	top_left.add_child(speed_label)

	# Top-Right Challenge Tracker
	var top_right = PanelContainer.new()
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -260
	top_right.offset_top = 20
	top_right.offset_right = -24
	top_right.offset_bottom = 100

	var tr_vbox = VBoxContainer.new()
	top_right.add_child(tr_vbox)

	timer_label = Label.new()
	timer_label.text = "TIME: 00:00.0"
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.modulate = Color(1.0, 0.85, 0.2)
	tr_vbox.add_child(timer_label)

	objective_label = Label.new()
	objective_label.text = "Objective: Complete Course"
	objective_label.add_theme_font_size_override("font_size", 13)
	tr_vbox.add_child(objective_label)

	in_game_hud.add_child(top_right)

	# 2. Sleek Side-Docked Workshop Configuration Panel (Leaves turntable unobstructed)
	workshop_panel = PanelContainer.new()
	workshop_panel.name = "WorkshopPanel"
	workshop_panel.anchor_left = 1.0
	workshop_panel.anchor_right = 1.0
	workshop_panel.anchor_bottom = 1.0
	workshop_panel.offset_left = -340
	workshop_panel.offset_top = 24
	workshop_panel.offset_right = -24
	workshop_panel.offset_bottom = -24
	workshop_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var wb_vbox = VBoxContainer.new()
	wb_vbox.add_theme_constant_override("separation", 10)
	workshop_panel.add_child(wb_vbox)

	var w_title = Label.new()
	w_title.text = "ROBOFORGE // HANGAR"
	w_title.modulate = Color(1.0, 0.85, 0.2)
	w_title.add_theme_font_size_override("font_size", 16)
	wb_vbox.add_child(w_title)

	var sub_title = Label.new()
	sub_title.text = "Configure Chassis & Test Contracts"
	sub_title.modulate = Color(0.7, 0.75, 0.8)
	sub_title.add_theme_font_size_override("font_size", 12)
	wb_vbox.add_child(sub_title)

	# Chassis selection
	var ch_header = Label.new()
	ch_header.text = "CHASSIS FRAME"
	ch_header.modulate = Color(0.2, 0.9, 1.0)
	ch_header.add_theme_font_size_override("font_size", 13)
	wb_vbox.add_child(ch_header)

	var ch_row = HBoxContainer.new()
	for ch_id in ["scout", "combat", "titan"]:
		var btn = Button.new()
		btn.text = ch_id.capitalize()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): chassis_selected.emit(ch_id))
		ch_row.add_child(btn)
	wb_vbox.add_child(ch_row)

	# Locomotion selection
	var loc_header = Label.new()
	loc_header.text = "LOCOMOTION SYSTEM"
	loc_header.modulate = Color(0.2, 0.9, 1.0)
	loc_header.add_theme_font_size_override("font_size", 13)
	wb_vbox.add_child(loc_header)

	var loc_row = HBoxContainer.new()
	for loc_id in ["wheels", "tracks", "legs"]:
		var btn = Button.new()
		btn.text = loc_id.capitalize()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): locomotion_selected.emit(loc_id))
		loc_row.add_child(btn)
	wb_vbox.add_child(loc_row)

	# Engineering Contracts & Challenges
	var c_header = Label.new()
	c_header.text = "ENGINEERING CHALLENGES"
	c_header.modulate = Color(1.0, 0.85, 0.2)
	c_header.add_theme_font_size_override("font_size", 13)
	wb_vbox.add_child(c_header)

	var test_btn = Button.new()
	test_btn.text = "▶ TEST DYNO (Obstacle Course)"
	test_btn.pressed.connect(func(): test_dyno_pressed.emit())
	wb_vbox.add_child(test_btn)

	var contracts_scroll = ScrollContainer.new()
	contracts_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var contracts_vbox = VBoxContainer.new()
	contracts_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contracts_vbox.add_theme_constant_override("separation", 6)

	var challenge_keys = [
		"cargo_delivery", "energy_competition", "maze_escape",
		"physics_puzzle", "precision_platform", "machine_repair"
	]
	for ch_key in challenge_keys:
		var btn = Button.new()
		btn.text = ch_key.replace("_", " ").capitalize()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): challenge_selected.emit(ch_key))
		contracts_vbox.add_child(btn)

	contracts_scroll.add_child(contracts_vbox)
	wb_vbox.add_child(contracts_scroll)

	add_child(workshop_panel)

func _make_label(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	l.custom_minimum_size = Vector2(90, 0)
	return l

func set_workshop_visible(visible_state: bool) -> void:
	if workshop_panel:
		workshop_panel.visible = visible_state
	if in_game_hud:
		in_game_hud.visible = not visible_state

func update_power(cur: float, max_p: float) -> void:
	if power_bar:
		power_bar.max_value = max_p
		power_bar.value = cur

func update_mass(m: float) -> void:
	if mass_label:
		mass_label.text = "MASS: %d KG" % int(m)

func update_time(sec: float) -> void:
	if timer_label:
		var mins = int(sec) / 60
		var s = int(sec) % 60
		var ms = int((sec - int(sec)) * 10.0)
		timer_label.text = "TIME: %02d:%02d.%01d" % [mins, s, ms]

func update_objective(text: String) -> void:
	if objective_label:
		objective_label.text = text
