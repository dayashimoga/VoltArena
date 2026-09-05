class_name MetroSiegeHUD
extends Control

var health_bar: ProgressBar
var armor_bar: ProgressBar
var health_label: Label
var armor_label: Label
var ammo_label: Label
var weapon_label: Label
var wave_label: Label
var threats_label: Label
var scrap_label: Label
var intermission_panel: PanelContainer
var intermission_label: Label
var toast_container: VBoxContainer
var crosshair: Control
var touch_controls: TouchControls

var crosshair_spread: float = 8.0

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGenerator.get_theme()
	setup_hud_layout()
	connect_bus_signals()
	check_mobile_controls()

func setup_hud_layout() -> void:
	# Crosshair in center
	crosshair = Control.new()
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.mouse_filter = MOUSE_FILTER_IGNORE
	crosshair.draw.connect(_on_draw_crosshair)
	add_child(crosshair)

	# Bottom-Left: Vitality (Health & Armor)
	var stat_panel = PanelContainer.new()
	stat_panel.position = Vector2(24, -130)
	stat_panel.anchor_top = 1.0
	stat_panel.anchor_bottom = 1.0
	add_child(stat_panel)

	var stat_vbox = VBoxContainer.new()
	stat_panel.add_child(stat_vbox)

	var hp_box = HBoxContainer.new()
	stat_vbox.add_child(hp_box)
	var hp_title = Label.new()
	hp_title.text = "VIT:"
	hp_title.modulate = Color(1.0, 0.3, 0.3)
	hp_box.add_child(hp_title)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(160, 16)
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	hp_box.add_child(health_bar)
	health_label = Label.new()
	health_label.text = "100"
	hp_box.add_child(health_label)

	var arm_box = HBoxContainer.new()
	stat_vbox.add_child(arm_box)
	var arm_title = Label.new()
	arm_title.text = "ARM:"
	arm_title.modulate = Color(0.3, 0.8, 1.0)
	arm_box.add_child(arm_title)
	armor_bar = ProgressBar.new()
	armor_bar.custom_minimum_size = Vector2(160, 16)
	armor_bar.max_value = 100.0
	armor_bar.value = 50.0
	armor_bar.show_percentage = false
	arm_box.add_child(armor_bar)
	armor_label = Label.new()
	armor_label.text = "50"
	arm_box.add_child(armor_label)

	# Bottom-Right: Firearm & Scrap
	var weapon_panel = PanelContainer.new()
	weapon_panel.anchor_left = 1.0
	weapon_panel.anchor_top = 1.0
	weapon_panel.anchor_right = 1.0
	weapon_panel.anchor_bottom = 1.0
	weapon_panel.offset_left = -220
	weapon_panel.offset_top = -120
	weapon_panel.offset_right = -24
	weapon_panel.offset_bottom = -24
	add_child(weapon_panel)

	var wpn_vbox = VBoxContainer.new()
	weapon_panel.add_child(wpn_vbox)

	weapon_label = Label.new()
	weapon_label.text = "Pulse Rifle"
	weapon_label.add_theme_font_size_override("font_size", 18)
	weapon_label.modulate = Color(1.0, 0.85, 0.2)
	wpn_vbox.add_child(weapon_label)

	ammo_label = Label.new()
	ammo_label.text = "30 / 120"
	ammo_label.add_theme_font_size_override("font_size", 22)
	ammo_label.modulate = Color(0.9, 0.95, 1.0)
	wpn_vbox.add_child(ammo_label)

	# Top Center: Wave Status & Threats
	var top_panel = PanelContainer.new()
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -160
	top_panel.offset_top = 20
	top_panel.offset_right = 160
	top_panel.offset_bottom = 76
	add_child(top_panel)

	var top_vbox = VBoxContainer.new()
	top_panel.add_child(top_vbox)

	wave_label = Label.new()
	wave_label.text = "METRO SIEGE // WAVE 1"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.modulate = Color(1.0, 0.35, 0.25)
	top_vbox.add_child(wave_label)

	var stats_hbox = HBoxContainer.new()
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_vbox.add_child(stats_hbox)

	threats_label = Label.new()
	threats_label.text = "THREATS: 0"
	threats_label.modulate = Color(1.0, 0.7, 0.7)
	stats_hbox.add_child(threats_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	stats_hbox.add_child(spacer)

	scrap_label = Label.new()
	scrap_label.text = "SCRAP: 0"
	scrap_label.modulate = Color(0.4, 1.0, 0.6)
	stats_hbox.add_child(scrap_label)

	# Intermission Banner
	intermission_panel = PanelContainer.new()
	intermission_panel.anchor_left = 0.5
	intermission_panel.anchor_right = 0.5
	intermission_panel.offset_left = -220
	intermission_panel.offset_top = 84
	intermission_panel.offset_right = 220
	intermission_panel.offset_bottom = 124
	intermission_panel.visible = false
	add_child(intermission_panel)

	intermission_label = Label.new()
	intermission_label.text = "INTERMISSION: 15s | PREPARE DEFENSES"
	intermission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intermission_label.modulate = Color(0.2, 1.0, 0.9)
	intermission_panel.add_child(intermission_label)

	# Toasts
	toast_container = VBoxContainer.new()
	toast_container.anchor_top = 0.2
	toast_container.anchor_bottom = 0.5
	toast_container.offset_left = 32
	toast_container.offset_right = 320
	toast_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(toast_container)

func _on_draw_crosshair() -> void:
	var col = Color(1.0, 0.2, 0.3, 0.85)
	var length = 9.0
	var offset = crosshair_spread
	crosshair.draw_line(Vector2(0, -offset - length), Vector2(0, -offset), col, 1.5)
	crosshair.draw_line(Vector2(0, offset), Vector2(0, offset + length), col, 1.5)
	crosshair.draw_line(Vector2(-offset - length, 0), Vector2(-offset, 0), col, 1.5)
	crosshair.draw_line(Vector2(offset, 0), Vector2(offset + length, 0), col, 1.5)

func connect_bus_signals() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if not bus:
		return
	bus.player_health_updated.connect(update_health)
	bus.player_armor_updated.connect(update_armor)
	bus.ammo_count_updated.connect(update_ammo)
	bus.weapon_switched.connect(update_weapon)
	bus.show_toast_requested.connect(show_toast)

func check_mobile_controls() -> void:
	var pa = GameConstants.get_autoload(self, "PlatformAdapter")
	if pa and pa.has_touchscreen():
		touch_controls = TouchControls.new()
		add_child(touch_controls)

func set_crosshair_spread(spread: float) -> void:
	crosshair_spread = spread
	if crosshair:
		crosshair.queue_redraw()

func update_health(cur: float, max_v: float) -> void:
	if health_bar:
		health_bar.max_value = max_v
		health_bar.value = cur
	if health_label:
		health_label.text = str(int(cur))

func update_armor(cur: float, max_v: float) -> void:
	if armor_bar:
		armor_bar.max_value = max_v
		armor_bar.value = cur
	if armor_label:
		armor_label.text = str(int(cur))

func update_ammo(clip: int, _max_c: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [clip, reserve]

func update_weapon(w_name: String) -> void:
	if weapon_label:
		weapon_label.text = w_name

func update_wave(wave: int, is_boss: bool = false) -> void:
	if wave_label:
		if is_boss:
			wave_label.text = "METRO SIEGE // BOSS WAVE %d // MUTATED BEHEMOTH" % wave
			wave_label.modulate = Color(1.0, 0.1, 0.2)
		else:
			wave_label.text = "METRO SIEGE // WAVE %d" % wave
			wave_label.modulate = Color(1.0, 0.35, 0.25)

func update_threats(count: int) -> void:
	if threats_label:
		threats_label.text = "THREATS: %d" % count

func update_scrap(scrap: int) -> void:
	if scrap_label:
		scrap_label.text = "SCRAP: %d" % scrap

func show_intermission(time_left: float, show: bool = true) -> void:
	if intermission_panel:
		intermission_panel.visible = show
		if show and intermission_label:
			intermission_label.text = "INTERMISSION: %ds | PREPARE DEFENSES" % int(time_left)

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
