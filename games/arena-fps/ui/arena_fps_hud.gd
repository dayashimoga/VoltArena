class_name ArenaFPSHUD
extends HUDBase

var frags_label: Label
var target_kills: int = 20
var current_frags: int = 0
var enemy_frags: int = 0
var objective_label: Label
var countdown_panel: PanelContainer
var countdown_label: Label
var onboarding_overlay: PanelContainer

# Tactical Radar / Minimap
var radar_panel: PanelContainer
var radar_canvas: Control
var player_ref: Node3D = null
var bots_ref: Array = []
var pickups_ref: Array = []

# Killfeed
var killfeed_vbox: VBoxContainer

# Weapon Selector Bar
var weapon_buttons: Array[Button] = []
var weapon_names = ["Pulse Rifle", "Scatter Cannon", "Rail Driver", "Grenade Launcher", "Plasma Cutter"]
var active_weapon_idx: int = 0

class TacticalRadarCanvas extends Control:
	var player_ref: Node3D = null
	func _draw() -> void:
		var center = size * 0.5
		var radius = center.x - 6.0

		# Radar background circle
		draw_circle(center, radius, Color(0.04, 0.08, 0.12, 0.85))
		draw_arc(center, radius, 0, TAU, 32, Color(0.0, 0.8, 1.0, 0.5), 1.5)
		draw_arc(center, radius * 0.5, 0, TAU, 24, Color(0.0, 0.8, 1.0, 0.25), 1.0)
		draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color(0.0, 0.8, 1.0, 0.2), 1.0)
		draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color(0.0, 0.8, 1.0, 0.2), 1.0)

		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if not tree:
			return
		if not is_instance_valid(player_ref):
			var p_list = tree.get_nodes_in_group("players")
			if not p_list.is_empty():
				player_ref = p_list[0]

		var scale_factor = radius / 38.0 # 38 meter radar view range

		if is_instance_valid(player_ref):
			var p_fwd = -player_ref.global_transform.basis.z
			p_fwd.y = 0.0
			p_fwd = p_fwd.normalized()
			var p_arrow = Vector2(p_fwd.x, p_fwd.z) * 10.0
			draw_circle(center, 4.5, Color(0.0, 1.0, 0.4))
			draw_line(center, center + p_arrow, Color(0.0, 1.0, 0.4), 2.0)

			var bots = tree.get_nodes_in_group("bots")
			for bot in bots:
				if is_instance_valid(bot) and bot != player_ref:
					var delta_pos = bot.global_position - player_ref.global_position
					var rx = delta_pos.x * scale_factor
					var rz = delta_pos.z * scale_factor
					var r_vec = Vector2(rx, rz)
					if r_vec.length() < radius - 4.0:
						draw_circle(center + r_vec, 3.5, Color(1.0, 0.25, 0.25))

			var pickups = tree.get_nodes_in_group("pickups")
			for p in pickups:
				if is_instance_valid(p):
					var delta_p = p.global_position - player_ref.global_position
					var px = delta_p.x * scale_factor
					var pz = delta_p.z * scale_factor
					var p_vec = Vector2(px, pz)
					if p_vec.length() < radius - 4.0:
						draw_circle(center + p_vec, 2.5, Color(1.0, 0.85, 0.1))

var obj_panel: PanelContainer
var killfeed_container: PanelContainer
var weapon_bar: HBoxContainer

func update_layout_positions() -> void:
	super.update_layout_positions()
	var vp = size
	if radar_panel and is_instance_valid(radar_panel):
		radar_panel.position = Vector2(maxf(vp.x - 170, 24), 24)
	if killfeed_container and is_instance_valid(killfeed_container):
		killfeed_container.position = Vector2(maxf(vp.x - 260, 24), 180)
	if weapon_bar and is_instance_valid(weapon_bar):
		weapon_bar.position = Vector2((vp.x - 500) * 0.5, maxf(vp.y - 68, 24))
	if obj_panel and is_instance_valid(obj_panel):
		obj_panel.position = Vector2((vp.x - 440) * 0.5, 20)
	if countdown_panel and is_instance_valid(countdown_panel):
		countdown_panel.position = Vector2((vp.x - 280) * 0.5, (vp.y - 90) * 0.35)
	if onboarding_overlay and is_instance_valid(onboarding_overlay):
		onboarding_overlay.position = Vector2((vp.x - 440) * 0.5, vp.y * 0.72 - 40)

func setup_hud_layout() -> void:
	super.setup_hud_layout()
	_setup_arena_extras()
	_setup_tactical_radar()
	_setup_killfeed()
	_setup_weapon_bar()
	setup_onboarding_overlay()
	update_layout_positions()

func _setup_arena_extras() -> void:
	# Top Left Frags Badge
	var frag_panel = PanelContainer.new()
	frag_panel.position = Vector2(24, 24)
	frag_panel.custom_minimum_size = Vector2(190, 56)
	add_child(frag_panel)

	var frag_vbox = VBoxContainer.new()
	frag_panel.add_child(frag_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "IRON CRUCIBLE // TDM"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.modulate = Color(0.0, 0.9, 1.0, 0.9)
	frag_vbox.add_child(title_lbl)

	frags_label = Label.new()
	frags_label.text = "FRAGS: 0 / %d" % target_kills
	frags_label.add_theme_font_size_override("font_size", 16)
	frags_label.modulate = Color(1.0, 0.9, 0.3)
	frag_vbox.add_child(frags_label)

	# Top Center: Active Match Objective Banner
	obj_panel = PanelContainer.new()
	obj_panel.custom_minimum_size = Vector2(440, 38)
	add_child(obj_panel)

	objective_label = Label.new()
	objective_label.text = "OBJECTIVE: FIRST TO 20 FRAGS WINS"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 13)
	objective_label.modulate = Color(0.9, 0.95, 1.0)
	obj_panel.add_child(objective_label)

	# Center: 3-2-1 Countdown Panel
	countdown_panel = PanelContainer.new()
	countdown_panel.custom_minimum_size = Vector2(280, 90)
	countdown_panel.visible = false
	add_child(countdown_panel)

	countdown_label = Label.new()
	countdown_label.text = "3"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 38)
	countdown_label.modulate = Color(1.0, 0.85, 0.1)
	countdown_panel.add_child(countdown_label)

func _setup_tactical_radar() -> void:
	radar_panel = PanelContainer.new()
	radar_panel.custom_minimum_size = Vector2(146, 146)
	add_child(radar_panel)

	radar_canvas = TacticalRadarCanvas.new()
	radar_canvas.custom_minimum_size = Vector2(146, 146)
	radar_panel.add_child(radar_canvas)

func _setup_killfeed() -> void:
	killfeed_container = PanelContainer.new()
	killfeed_container.custom_minimum_size = Vector2(236, 120)
	killfeed_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(killfeed_container)

	killfeed_vbox = VBoxContainer.new()
	killfeed_container.add_child(killfeed_vbox)

	var kf_header = Label.new()
	kf_header.text = "COMBAT LOG"
	kf_header.add_theme_font_size_override("font_size", 10)
	kf_header.modulate = Color(0.5, 0.7, 0.9, 0.6)
	killfeed_vbox.add_child(kf_header)

func _setup_weapon_bar() -> void:
	weapon_bar = HBoxContainer.new()
	weapon_bar.custom_minimum_size = Vector2(500, 44)
	add_child(weapon_bar)

	var short_names = ["1 PULSE", "2 SCATTER", "3 RAIL", "4 GRENADE", "5 PLASMA"]
	for i in range(5):
		var btn = Button.new()
		btn.text = short_names[i]
		btn.custom_minimum_size = Vector2(96, 40)
		btn.add_theme_font_size_override("font_size", 11)
		var captured_i = i
		btn.pressed.connect(func():
			_on_weapon_button_pressed(captured_i)
		)
		weapon_bar.add_child(btn)
		weapon_buttons.append(btn)

	highlight_active_weapon(0)

func _on_weapon_button_pressed(idx: int) -> void:
	highlight_active_weapon(idx)
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		var players = tree.get_nodes_in_group("players")
		if not players.is_empty() and players[0].has_method("select_weapon"):
			players[0].select_weapon(idx)

func highlight_active_weapon(idx: int) -> void:
	active_weapon_idx = idx
	for i in range(weapon_buttons.size()):
		var b = weapon_buttons[i]
		if i == idx:
			b.modulate = Color(0.0, 1.0, 0.8)
		else:
			b.modulate = Color(0.6, 0.65, 0.75, 0.7)

func _process(_delta: float) -> void:
	if radar_canvas and is_instance_valid(radar_canvas):
		radar_canvas.queue_redraw()

func add_killfeed_entry(killer: String, victim: String, weapon_used: String) -> void:
	if not killfeed_vbox:
		return
	var lbl = Label.new()
	lbl.text = "%s [%s] %s" % [killer, weapon_used, victim]
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(1.0, 0.35, 0.35) if victim == "You" else Color(0.3, 1.0, 0.5)
	killfeed_vbox.add_child(lbl)

	# Fade out and clean up after 4 seconds
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(4.0).timeout.connect(func():
			if is_instance_valid(lbl):
				lbl.queue_free()
		)

func update_frags(frags: int, target: int = 20) -> void:
	current_frags = frags
	target_kills = target
	if frags_label:
		frags_label.text = "FRAGS: %d / %d" % [current_frags, target_kills]

func update_objective(p_frags: int, b_frags: int, target: int = 20) -> void:
	current_frags = p_frags
	enemy_frags = b_frags
	target_kills = target
	update_frags(p_frags, target)
	if objective_label:
		objective_label.text = "RACE TO %d FRAGS | YOU: %d  vs  ENEMIES: %d" % [target, p_frags, b_frags]

func show_countdown(seconds: int) -> void:
	if not countdown_panel:
		return
	if seconds > 0:
		countdown_panel.visible = true
		countdown_label.text = str(seconds)
	elif seconds == 0:
		countdown_panel.visible = true
		countdown_label.text = "FIGHT!"
		countdown_label.modulate = Color(0.0, 1.0, 0.5)
		var tween = create_tween()
		tween.tween_property(countdown_panel, "modulate:a", 0.0, 0.6).set_delay(0.4)
		tween.tween_callback(func():
			if is_instance_valid(countdown_panel):
				countdown_panel.visible = false
		)

func update_objective_label(text: String) -> void:
	if objective_label:
		objective_label.text = text

func setup_onboarding_overlay() -> void:
	onboarding_overlay = PanelContainer.new()
	onboarding_overlay.anchor_left = 0.5
	onboarding_overlay.anchor_top = 0.65
	onboarding_overlay.anchor_right = 0.5
	onboarding_overlay.anchor_bottom = 0.65
	onboarding_overlay.offset_left = -300
	onboarding_overlay.offset_top = -100
	onboarding_overlay.offset_right = 300
	onboarding_overlay.offset_bottom = 100
	add_child(onboarding_overlay)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	onboarding_overlay.add_child(vb)

	var title = Label.new()
	title.text = "IRON CRUCIBLE — TACTICAL COMBAT SUITE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color(0.2, 0.9, 1.0)
	vb.add_child(title)

	# Map Selection
	var map_box = HBoxContainer.new()
	map_box.alignment = BoxContainer.ALIGNMENT_CENTER
	map_box.add_theme_constant_override("separation", 8)
	vb.add_child(map_box)

	var m_lbl = Label.new()
	m_lbl.text = "MAP:"
	m_lbl.modulate = Color(0.2, 0.9, 1.0)
	m_lbl.add_theme_font_size_override("font_size", 11)
	map_box.add_child(m_lbl)

	var maps = [["REACTOR COMPLEX", "foundry"], ["ORBITAL STATION", "citadel"], ["INDUSTRIAL CITY", "sektor"]]
	for m in maps:
		var btn = Button.new()
		btn.text = m[0]
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(func():
			var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree:
				var af = tree.root.find_child("ArenaFPSMain", true, false)
				if af and af.has_method("select_map"):
					af.select_map(m[1])
					show_toast("MAP SELECTED: " + m[0], Color(0.2, 0.9, 1.0))
		)
		map_box.add_child(btn)

	# Mode Selection
	var mode_box = HBoxContainer.new()
	mode_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_box.add_theme_constant_override("separation", 6)
	vb.add_child(mode_box)

	var md_lbl = Label.new()
	md_lbl.text = "MODE:"
	md_lbl.modulate = Color(1.0, 0.8, 0.2)
	md_lbl.add_theme_font_size_override("font_size", 11)
	mode_box.add_child(md_lbl)

	var modes = [["FRAG RACE", "frag_race"], ["TDM", "tdm"], ["CONTROL POINT", "control_point"], ["ARTIFACT", "artifact"], ["SURVIVAL", "survival"]]
	for md in modes:
		var btn = Button.new()
		btn.text = md[0]
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(func():
			var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
			if tree:
				var af = tree.root.find_child("ArenaFPSMain", true, false)
				if af and af.has_method("select_game_mode"):
					af.select_game_mode(md[1])
					show_toast("MODE: " + md[0], Color(1.0, 0.8, 0.2))
		)
		mode_box.add_child(btn)

	var t1 = Label.new()
	t1.text = "WASD: Move | Mouse: Aim | Left-Click: Fire | 1-5: Switch Weapon"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 11)
	t1.modulate = Color(0.85, 0.95, 1.0)
	vb.add_child(t1)

func dismiss_onboarding() -> void:
	if is_instance_valid(onboarding_overlay):
		var tw = create_tween()
		tw.tween_property(onboarding_overlay, "modulate:a", 0.0, 0.8)
		tw.tween_callback(func():
			if is_instance_valid(onboarding_overlay):
				onboarding_overlay.visible = false
		)
