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
var onboarding_overlay: PanelContainer
var objective_badge: Label

var crosshair_spread: float = 8.0

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGenerator.get_theme()
	setup_hud_layout()
	setup_onboarding_overlay()
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
	top_panel.offset_left = -200
	top_panel.offset_top = 18
	top_panel.offset_right = 200
	top_panel.offset_bottom = 102
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
	threats_label.text = "THREATS: 10 INCOMING"
	threats_label.modulate = Color(1.0, 0.7, 0.7)
	stats_hbox.add_child(threats_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	stats_hbox.add_child(spacer)

	scrap_label = Label.new()
	scrap_label.text = "SCRAP: 0"
	scrap_label.modulate = Color(0.4, 1.0, 0.6)
	stats_hbox.add_child(scrap_label)

	objective_badge = Label.new()
	objective_badge.text = "OBJECTIVE: SURVIVE 10 WAVES & EXTRACT"
	objective_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_badge.add_theme_font_size_override("font_size", 12)
	objective_badge.modulate = Color(0.9, 0.95, 1.0, 0.85)
	top_vbox.add_child(objective_badge)

	# Intermission Banner
	intermission_panel = PanelContainer.new()
	intermission_panel.anchor_left = 0.5
	intermission_panel.anchor_right = 0.5
	intermission_panel.offset_left = -220
	intermission_panel.offset_top = 106
	intermission_panel.offset_right = 220
	intermission_panel.offset_bottom = 146
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
	title.text = "METRO SIEGE — SUBWAY SURVIVAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.35, 0.25)
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "UNDERGROUND STATION SURVIVAL OUTPOST"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.modulate = Color(0.8, 0.85, 0.95)
	vbox.add_child(sub)

	var obj_lbl = Label.new()
	obj_lbl.text = "OBJECTIVE: SURVIVE 10 ESCALATING WAVES & EXTRACT VIA THE TRAIN!"
	obj_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj_lbl.add_theme_font_size_override("font_size", 14)
	obj_lbl.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(obj_lbl)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var ctrl_grid = GridContainer.new()
	ctrl_grid.columns = 2
	ctrl_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(ctrl_grid)

	var controls_data = [
		["WASD", "Move & Strafe Locomotion"],
		["MOUSE", "Aim / Look & Recoil Control"],
		["LEFT CLICK", "Fire Equipped Weapon"],
		["RIGHT CLICK", "Aim Down Sights (ADS)"],
		["1 - 5 / WHEEL", "Switch Weapons (Pulse, Scatter, Rail, Grenade, Plasma)"],
		["SPACE / SHIFT", "Jump / Sprint Locomotion"]
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

	var prompt_lbl = Label.new()
	prompt_lbl.text = "WAVE 1 INCOMING (PRESS ANY KEY OR SPACE TO DISMISS)"
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 12)
	prompt_lbl.modulate = Color(0.7, 0.85, 0.95)
	vbox.add_child(prompt_lbl)

func dismiss_onboarding() -> void:
	if not is_instance_valid(onboarding_overlay) or not onboarding_overlay.visible:
		return
	var tween = create_tween()
	tween.tween_property(onboarding_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		onboarding_overlay.visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_onboarding()
