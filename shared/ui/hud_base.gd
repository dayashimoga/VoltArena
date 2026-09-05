class_name HUDBase
extends Control

# UI Element References
var health_bar: ProgressBar
var armor_bar: ProgressBar
var health_label: Label
var armor_label: Label
var ammo_label: Label
var weapon_label: Label
var score_label: Label
var timer_label: Label
var crosshair: Control
var toast_container: VBoxContainer
var touch_controls: TouchControls

class CrosshairControl extends Control:
	var spread: float = 8.0
	func _draw() -> void:
		var col = Color(0.0, 1.0, 0.9, 0.85)
		var s = spread
		var l = 8.0
		draw_line(Vector2(-s - l, 0), Vector2(-s, 0), col, 2.0)
		draw_line(Vector2(s, 0), Vector2(s + l, 0), col, 2.0)
		draw_line(Vector2(0, -s - l), Vector2(0, -s), col, 2.0)
		draw_line(Vector2(0, s), Vector2(0, s + l), col, 2.0)
		draw_circle(Vector2.ZERO, 1.5, col)

var stat_panel: PanelContainer
var weapon_panel: PanelContainer
var top_panel: PanelContainer

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
	connect_bus_signals()
	check_mobile_controls()
	update_layout_positions()

func _on_viewport_size_changed() -> void:
	if get_viewport():
		size = get_viewport().get_visible_rect().size
		update_layout_positions()

func update_layout_positions() -> void:
	var vp = size
	if stat_panel and is_instance_valid(stat_panel):
		stat_panel.position = Vector2(24, maxf(vp.y - 130, 24))
	if weapon_panel and is_instance_valid(weapon_panel):
		weapon_panel.position = Vector2(maxf(vp.x - 220, 24), maxf(vp.y - 120, 24))
	if top_panel and is_instance_valid(top_panel):
		top_panel.position = Vector2((vp.x - 300) * 0.5, 16)
	if crosshair and is_instance_valid(crosshair):
		crosshair.position = vp * 0.5
	if toast_container and is_instance_valid(toast_container):
		toast_container.position = Vector2(maxf(vp.x - 320, 24), 80)

func setup_hud_layout() -> void:
	# Bottom-Left: Health & Armor
	stat_panel = PanelContainer.new()
	stat_panel.custom_minimum_size = Vector2(200, 80)
	add_child(stat_panel)

	var stat_vbox = VBoxContainer.new()
	stat_panel.add_child(stat_vbox)

	var hp_box = HBoxContainer.new()
	stat_vbox.add_child(hp_box)
	var hp_title = Label.new()
	hp_title.text = "HP:"
	hp_title.modulate = Color(0.2, 1.0, 0.4)
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
	arm_title.modulate = Color(0.2, 0.8, 1.0)
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

	# Bottom-Right: Weapon & Ammo
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
	weapon_label.text = "PULSE RIFLE"
	weapon_label.modulate = Color(0.0, 0.9, 1.0)
	wpn_vbox.add_child(weapon_label)

	ammo_label = Label.new()
	ammo_label.text = "30 / 120"
	ammo_label.modulate = Color(1.0, 0.85, 0.2)
	wpn_vbox.add_child(ammo_label)

	# Top-Center: Score & Timer
	var top_panel = PanelContainer.new()
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -150
	top_panel.offset_top = 16
	top_panel.offset_right = 150
	top_panel.offset_bottom = 70
	add_child(top_panel)

	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_panel.add_child(top_hbox)

	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.modulate = Color(0.0, 1.0, 0.8)
	top_hbox.add_child(score_label)

	var sep = VSeparator.new()
	top_hbox.add_child(sep)

	timer_label = Label.new()
	timer_label.text = "05:00"
	timer_label.modulate = Color(1.0, 1.0, 1.0)
	top_hbox.add_child(timer_label)

	# Center: Crosshair
	var ch = CrosshairControl.new()
	ch.name = "Crosshair"
	crosshair = ch
	add_child(crosshair)

	# Toast / Notifications on Top-Right
	toast_container = VBoxContainer.new()
	add_child(toast_container)

func connect_bus_signals() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.player_health_changed.connect(update_health)
		bus.player_armor_changed.connect(update_armor)
		bus.player_ammo_changed.connect(update_ammo)
		bus.player_weapon_switched.connect(update_weapon)
		bus.score_updated.connect(update_score)
		bus.round_timer_updated.connect(update_timer)
		bus.show_toast_requested.connect(show_toast)

func check_mobile_controls() -> void:
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"):
		touch_controls = TouchControls.new()
		add_child(touch_controls)

func set_crosshair_spread(spread: float) -> void:
	if crosshair is CrosshairControl:
		(crosshair as CrosshairControl).spread = spread
		crosshair.queue_redraw()

func update_health(hp: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if health_label:
		health_label.text = str(int(hp))
		if hp < 25.0:
			health_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			health_label.modulate = Color(1.0, 1.0, 1.0)

func update_armor(armor: float, max_armor: float) -> void:
	if armor_bar:
		armor_bar.max_value = max_armor
		armor_bar.value = armor
	if armor_label:
		armor_label.text = str(int(armor))

func update_ammo(cur: int, max_clip: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [cur, reserve]

func update_weapon(wpn_name: String, _icon: String) -> void:
	if weapon_label:
		weapon_label.text = wpn_name.to_upper()

func update_score(_team_or_player: int, score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %d" % score

func update_timer(time_left: float) -> void:
	if timer_label:
		var mins = int(time_left) / 60
		var secs = int(time_left) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]

func show_toast(msg: String, col: Color = Color.WHITE) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.modulate = col
	if toast_container:
		toast_container.add_child(lbl)
	if is_inside_tree():
		var tw = create_tween()
		if tw:
			lbl.modulate.a = 0.0
			tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
			tw.tween_interval(2.0)
			tw.tween_property(lbl, "modulate:a", 0.0, 0.3)
			tw.tween_callback(lbl.queue_free)
	else:
		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree:
			tree.create_timer(2.5).timeout.connect(func():
				if is_instance_valid(lbl):
					lbl.queue_free()
			)
