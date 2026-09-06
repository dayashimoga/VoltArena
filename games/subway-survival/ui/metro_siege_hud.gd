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

var radar_panel: PanelContainer
var radar_canvas: Control
var player_ref: Node3D = null
var top_panel: PanelContainer
var stat_panel: PanelContainer
var weapon_panel: PanelContainer

class MetroCrosshairControl extends Control:
	var spread: float = 8.0
	func _draw() -> void:
		var col = Color(1.0, 0.2, 0.3, 0.85)
		var length = 9.0
		var offset = spread
		draw_line(Vector2(0, -offset - length), Vector2(0, -offset), col, 1.5)
		draw_line(Vector2(0, offset), Vector2(0, offset + length), col, 1.5)
		draw_line(Vector2(-offset - length, 0), Vector2(-offset, 0), col, 1.5)
		draw_line(Vector2(offset, 0), Vector2(offset + length), col, 1.5)

var crosshair_spread: float = 8.0

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = ThemeGenerator.get_theme()
	if get_viewport():
		size = get_viewport().get_visible_rect().size
		if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
			get_viewport().size_changed.connect(_on_viewport_size_changed)
	else:
		size = Vector2(1280, 720)
	setup_hud_layout()
	_setup_radar()
	setup_onboarding_overlay()
	connect_bus_signals()
	check_mobile_controls()
	update_layout_positions()

func _on_viewport_size_changed() -> void:
	if get_viewport():
		size = get_viewport().get_visible_rect().size
		update_layout_positions()

func setup_hud_layout() -> void:
	# Crosshair in center
	var ch = MetroCrosshairControl.new()
	ch.name = "Crosshair"
	crosshair = ch
	add_child(crosshair)

	# Bottom-Left: Vitality & Armor
	stat_panel = PanelContainer.new()
	stat_panel.custom_minimum_size = Vector2(200, 80)
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
	weapon_panel = PanelContainer.new()
	weapon_panel.custom_minimum_size = Vector2(196, 96)
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
	top_panel = PanelContainer.new()
	top_panel.custom_minimum_size = Vector2(400, 84)
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

class MetroSonarCanvas extends Control:
	var player_ref: Node3D = null
	func _draw() -> void:
		var center = size * 0.5
		var radius = center.x - 6.0

		# Tactical Radar Background Grid (Subway Sonar)
		draw_circle(center, radius, Color(0.04, 0.08, 0.12, 0.85))
		draw_arc(center, radius, 0, TAU, 32, Color(1.0, 0.45, 0.15, 0.6), 1.5)
		draw_arc(center, radius * 0.5, 0, TAU, 24, Color(1.0, 0.45, 0.15, 0.3), 1.0)
		draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color(1.0, 0.45, 0.15, 0.2), 1.0)
		draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color(1.0, 0.45, 0.15, 0.2), 1.0)

		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if not tree:
			return
		if not is_instance_valid(player_ref):
			var p_list = tree.get_nodes_in_group("players")
			if not p_list.is_empty():
				player_ref = p_list[0]

		var scale_factor = radius / 45.0 # 45 meter radar detection range

		if is_instance_valid(player_ref):
			var p_pos = player_ref.global_position

			# Player indicator at center with heading pointer
			var p_fwd = -player_ref.global_transform.basis.z
			p_fwd.y = 0.0
			p_fwd = p_fwd.normalized()
			var p_arrow = Vector2(p_fwd.x, p_fwd.z) * 10.0
			draw_circle(center, 4.0, Color(0.2, 1.0, 0.4))
			draw_line(center, center + p_arrow, Color(0.2, 1.0, 0.4), 2.0)

			# Draw Extraction Train landmark (at X=6.5, Z=0)
			var train_delta = Vector3(6.5, 0, 0) - p_pos
			var t_vec = Vector2(train_delta.x, train_delta.z) * scale_factor
			if t_vec.length() < radius - 6.0:
				draw_rect(Rect2(center + t_vec - Vector2(5, 12), Vector2(10, 24)), Color(0.0, 0.8, 1.0, 0.7), false, 1.5)

			# Draw Upgrade Kiosk landmark (at X=-10.5, Z=-4.0)
			var kiosk_delta = Vector3(-10.5, 0, -4.0) - p_pos
			var k_vec = Vector2(kiosk_delta.x, kiosk_delta.z) * scale_factor
			if k_vec.length() < radius - 4.0:
				draw_circle(center + k_vec, 3.5, Color(0.0, 1.0, 0.8))

			# Draw Enemies in range
			var enemies = tree.get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy):
					var e_delta = enemy.global_position - p_pos
					var e_vec = Vector2(e_delta.x, e_delta.z) * scale_factor
					if e_vec.length() < radius - 4.0:
						var is_boss = enemy.get("is_boss") == true or enemy.name.begins_with("BioColossus")
						if is_boss:
							draw_circle(center + e_vec, 6.0, Color(1.0, 0.1, 0.3))
							draw_arc(center + e_vec, 8.0, 0, TAU, 12, Color(1.0, 0.8, 0.0), 1.5)
						else:
							draw_circle(center + e_vec, 3.5, Color(1.0, 0.2, 0.2))

			# Draw Scrap pickups
			var scraps = tree.get_nodes_in_group("scraps")
			for s in scraps:
				if is_instance_valid(s):
					var s_delta = s.global_position - p_pos
					var s_vec = Vector2(s_delta.x, s_delta.z) * scale_factor
					if s_vec.length() < radius - 4.0:
						draw_circle(center + s_vec, 2.5, Color(1.0, 0.85, 0.1))

func update_layout_positions() -> void:
	var vp = size
	if stat_panel and is_instance_valid(stat_panel):
		stat_panel.position = Vector2(24, maxf(vp.y - 130, 24))
	if weapon_panel and is_instance_valid(weapon_panel):
		weapon_panel.position = Vector2(maxf(vp.x - 220, 24), maxf(vp.y - 120, 24))
	if radar_panel and is_instance_valid(radar_panel):
		radar_panel.position = Vector2(maxf(vp.x - 170, 24), 24)
	if top_panel and is_instance_valid(top_panel):
		top_panel.position = Vector2((vp.x - 400) * 0.5, 18)
	if intermission_panel and is_instance_valid(intermission_panel):
		intermission_panel.position = Vector2((vp.x - 440) * 0.5, 106)
	if crosshair and is_instance_valid(crosshair):
		crosshair.position = vp * 0.5
	if toast_container and is_instance_valid(toast_container):
		toast_container.position = Vector2(32, vp.y * 0.2)
	if onboarding_overlay and is_instance_valid(onboarding_overlay):
		onboarding_overlay.position = Vector2((vp.x - 440) * 0.5, vp.y * 0.72 - 40)

func _setup_radar() -> void:
	radar_panel = PanelContainer.new()
	radar_panel.custom_minimum_size = Vector2(146, 146)
	add_child(radar_panel)

	radar_canvas = MetroSonarCanvas.new()
	radar_canvas.custom_minimum_size = Vector2(146, 146)
	radar_panel.add_child(radar_canvas)

func _process(_delta: float) -> void:
	if radar_canvas and is_instance_valid(radar_canvas):
		radar_canvas.queue_redraw()

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
	if crosshair is MetroCrosshairControl:
		(crosshair as MetroCrosshairControl).spread = spread
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
	if is_instance_valid(onboarding_overlay):
		onboarding_overlay.visible = false
		onboarding_overlay.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_onboarding()
