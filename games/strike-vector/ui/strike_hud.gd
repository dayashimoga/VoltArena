class_name StrikeHUD
extends Control

## Compact Cyberpunk HUD for Strike Vector.
## Displays: Health & Armor gauges, Weapon & Ammo counter, Grenades,
## Active Arcade Power Module countdown, Mission Objective, Context Alerts, and Boss Health.

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

var health_bar: ProgressBar
var health_label: Label
var armor_bar: ProgressBar
var armor_label: Label

var weapon_name_label: Label
var ammo_label: Label
var grenade_label: Label
var module_badge: PanelContainer
var module_label: Label

var objective_badge: PanelContainer
var objective_label: Label
var alert_label: Label

var boss_panel: PanelContainer
var boss_name_label: Label
var boss_health_bar: ProgressBar
var boss_phase_label: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGen.get_theme()
	setup_hud()

func setup_hud() -> void:
	_setup_top_left_status()
	_setup_bottom_right_weapon()
	_setup_top_center_objective()
	_setup_context_alert()
	_setup_boss_health_bar()

func _setup_top_left_status() -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(260, 80)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Health row
	var h_box = HBoxContainer.new()
	vbox.add_child(h_box)
	var h_title = Label.new()
	h_title.text = "VITALS"
	h_title.modulate = Color(0.2, 1.0, 0.4)
	h_title.custom_minimum_size = Vector2(65, 0)
	h_box.add_child(h_title)

	health_bar = ProgressBar.new()
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.custom_minimum_size = Vector2(120, 16)
	health_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	health_bar.show_percentage = false
	h_box.add_child(health_bar)

	health_label = Label.new()
	health_label.text = "100"
	health_label.modulate = Color(0.2, 1.0, 0.4)
	h_box.add_child(health_label)

	# Armor row
	var a_box = HBoxContainer.new()
	vbox.add_child(a_box)
	var a_title = Label.new()
	a_title.text = "ARMOR"
	a_title.modulate = Color(0.1, 0.7, 1.0)
	a_title.custom_minimum_size = Vector2(65, 0)
	a_box.add_child(a_title)

	armor_bar = ProgressBar.new()
	armor_bar.max_value = 100.0
	armor_bar.value = 50.0
	armor_bar.custom_minimum_size = Vector2(120, 16)
	armor_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	armor_bar.show_percentage = false
	a_box.add_child(armor_bar)

	armor_label = Label.new()
	armor_label.text = "50"
	armor_label.modulate = Color(0.1, 0.7, 1.0)
	a_box.add_child(armor_label)

func _setup_bottom_right_weapon() -> void:
	var panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -280
	panel.offset_top = -120
	panel.offset_right = -24
	panel.offset_bottom = -24
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	weapon_name_label = Label.new()
	weapon_name_label.text = "VX-7 ASSAULT RIFLE"
	weapon_name_label.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(weapon_name_label)

	ammo_label = Label.new()
	ammo_label.text = "30 / 150"
	ammo_label.add_theme_font_size_override("font_size", 22)
	ammo_label.modulate = Color(0.0, 1.0, 1.0)
	vbox.add_child(ammo_label)

	var footer_box = HBoxContainer.new()
	vbox.add_child(footer_box)

	grenade_label = Label.new()
	grenade_label.text = "FRAG: 3"
	grenade_label.modulate = Color(1.0, 0.4, 0.2)
	footer_box.add_child(grenade_label)

	module_badge = PanelContainer.new()
	module_badge.visible = false
	footer_box.add_child(module_badge)
	module_label = Label.new()
	module_label.text = "RAPID FIRE (20s)"
	module_label.modulate = Color(1.0, 0.2, 0.9)
	module_badge.add_child(module_label)

func _setup_top_center_objective() -> void:
	objective_badge = PanelContainer.new()
	objective_badge.anchor_left = 0.5
	objective_badge.anchor_right = 0.5
	objective_badge.offset_left = -200
	objective_badge.offset_right = 200
	objective_badge.offset_top = 24
	objective_badge.offset_bottom = 60
	add_child(objective_badge)

	objective_label = Label.new()
	objective_label.text = "OBJECTIVE: DESTROY JAMMER & REACH EXTRACTION"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.modulate = Color(0.9, 0.95, 1.0)
	objective_badge.add_child(objective_label)

func _setup_context_alert() -> void:
	alert_label = Label.new()
	alert_label.anchor_left = 0.5
	alert_label.anchor_top = 0.5
	alert_label.anchor_right = 0.5
	alert_label.anchor_bottom = 0.5
	alert_label.offset_left = -250
	alert_label.offset_right = 250
	alert_label.offset_top = -80
	alert_label.offset_bottom = -40
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_size_override("font_size", 24)
	alert_label.modulate = Color(1.0, 0.9, 0.1, 0.0) # start invisible
	add_child(alert_label)

func _setup_boss_health_bar() -> void:
	boss_panel = PanelContainer.new()
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -260
	boss_panel.offset_right = 260
	boss_panel.offset_top = 70
	boss_panel.offset_bottom = 120
	boss_panel.visible = false
	add_child(boss_panel)

	var vbox = VBoxContainer.new()
	boss_panel.add_child(vbox)

	var h_box = HBoxContainer.new()
	vbox.add_child(h_box)

	boss_name_label = Label.new()
	boss_name_label.text = "BOSS ENCOUNTER"
	boss_name_label.modulate = Color(1.0, 0.2, 0.2)
	boss_name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	h_box.add_child(boss_name_label)

	boss_phase_label = Label.new()
	boss_phase_label.text = "PHASE 1 / 2"
	boss_phase_label.modulate = Color(1.0, 0.8, 0.2)
	h_box.add_child(boss_phase_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.max_value = 500.0
	boss_health_bar.value = 500.0
	boss_health_bar.custom_minimum_size = Vector2(0, 18)
	boss_health_bar.show_percentage = false
	vbox.add_child(boss_health_bar)

# --- Public API Methods ---

func update_health(current: float, max_val: float) -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_val
		health_bar.value = current
	if is_instance_valid(health_label):
		health_label.text = str(int(current))

func update_armor(current: float, max_val: float) -> void:
	if is_instance_valid(armor_bar):
		armor_bar.max_value = max_val
		armor_bar.value = current
	if is_instance_valid(armor_label):
		armor_label.text = str(int(current))

func update_weapon(w_name: String, ammo: int, reserve: int) -> void:
	if is_instance_valid(weapon_name_label):
		weapon_name_label.text = w_name.to_upper()
	if is_instance_valid(ammo_label):
		ammo_label.text = "%d / %d" % [ammo, reserve]

func update_objective(text: String) -> void:
	if is_instance_valid(objective_label):
		objective_label.text = "OBJECTIVE: " + text.to_upper()

func show_context_alert(alert_text: String, alert_color: Color = Color(1.0, 0.9, 0.1)) -> void:
	if not is_instance_valid(alert_label):
		return
	alert_label.text = alert_text
	alert_label.modulate = alert_color

	var tween = create_tween()
	tween.tween_property(alert_label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.8)
	tween.tween_property(alert_label, "modulate:a", 0.0, 0.4)

func update_boss(current_hp: float, max_hp: float, phase: int, total_phases: int, b_name: String = "") -> void:
	if not is_instance_valid(boss_panel):
		return
	boss_panel.visible = current_hp > 0.0
	if not b_name.is_empty() and is_instance_valid(boss_name_label):
		boss_name_label.text = b_name.to_upper()
	if is_instance_valid(boss_health_bar):
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = current_hp
	if is_instance_valid(boss_phase_label):
		boss_phase_label.text = "PHASE %d / %d" % [phase, total_phases]
