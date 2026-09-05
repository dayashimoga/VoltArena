class_name Launcher
extends Control

var game_cards_container: GridContainer
var main_vbox: VBoxContainer
var loading_overlay: PanelContainer
var loading_bar: ProgressBar
var loading_status_label: Label
var loading_bytes_label: Label
var settings_dialog: PanelContainer
var controls_dialog: PanelContainer

const ThemeGen = preload("res://shared/ui/theme_generator.gd")
const LauncherArtScript = preload("res://launcher/launcher_art.gd")

var current_target_game: String = ""

# Metadata for all 4 games
var games_meta = [
	{
		"id": "arena_fps",
		"title": "IRON CRUCIBLE",
		"tagline": "Tactical Arena FPS",
		"desc": "High-octane arena combat with fluid sprint-slide movement, 5 original energy weapons, and combat AI bots.",
		"tags": ["TACTICAL", "ARENA", "BOTS", "WEAPONS"],
		"color": Color(0.0, 0.9, 1.0),
		"scene": "res://games/arena-fps/arena_fps_main.tscn"
	},
	{
		"id": "subway_survival",
		"title": "METRO SIEGE",
		"tagline": "Underground Wave Survival",
		"desc": "Survive endless waves of mutated terrors in atmospheric subterranean metro stations with progressive scavenging.",
		"tags": ["SURVIVAL", "HORROR", "WAVES", "DIRECTOR"],
		"color": Color(1.0, 0.2, 0.3),
		"scene": "res://games/subway-survival/subway_main.tscn"
	},
	{
		"id": "rocket_car",
		"title": "NITRO KICK",
		"tagline": "Rocket-Car Arena Football",
		"desc": "Supersonic rocket vehicle sports with aerial jumps, nitrous boost, physics bouncing ball, and explosive goals.",
		"tags": ["PHYSICS", "VEHICLE", "SPORTS", "AERIAL"],
		"color": Color(1.0, 0.6, 0.0),
		"scene": "res://games/rocket-car/rocket_car_main.tscn"
	},
	{
		"id": "kart_racing",
		"title": "DRIFT STORM",
		"tagline": "Arcade Kart Racing",
		"desc": "Grand Prix circuit racing with drift-charging mini-turbos, power-up item boxes, and competitive AI racers.",
		"tags": ["RACING", "DRIFT", "BOOST", "CIRCUIT"],
		"color": Color(0.2, 1.0, 0.5),
		"scene": "res://games/kart-racing/kart_racing_main.tscn"
	}
]

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	theme = ThemeGen.get_theme()
	_sanitize_root_scene()
	setup_launcher_ui()
	connect_loader_signals()
	update_responsive_layout(get_viewport_rect().size)

	var vp = get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

	var im = GameConstants.get_autoload(self, "InputManager")
	if im:
		im.capture_mouse(false)

func _on_viewport_size_changed() -> void:
	update_responsive_layout(get_viewport_rect().size)

func _sanitize_root_scene() -> void:
	var tree = get_tree()
	if not tree or not tree.root:
		return
	var valid_autoloads = [
		"EventBus", "SettingsManager", "SaveManager", "AudioManager",
		"InputManager", "PlatformAdapter", "QualityManager", "TelemetryManager",
		"AssetLoader", "GameManager"
	]
	for child in tree.root.get_children():
		if child == self or child == tree.current_scene:
			continue
		if child.name in valid_autoloads:
			continue
		if child is CanvasLayer or child is Control or "HUD" in child.name or "Screen" in child.name:
			child.queue_free()

func setup_launcher_ui() -> void:
	# Dark Cyberpunk Background
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.03, 0.04, 0.07)
	add_child(bg)

	# Decorative Grid Background lines
	var grid_overlay = Control.new()
	grid_overlay.anchor_right = 1.0
	grid_overlay.anchor_bottom = 1.0
	grid_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	grid_overlay.draw.connect(func():
		for x in range(0, int(size.x), 60):
			grid_overlay.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.08, 0.14, 0.22, 0.2), 1.0)
		for y in range(0, int(size.y), 60):
			grid_overlay.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.08, 0.14, 0.22, 0.2), 1.0)
	)
	add_child(grid_overlay)

	# Main Vertical Layout
	main_vbox = VBoxContainer.new()
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 32
	main_vbox.offset_top = 24
	main_vbox.offset_right = -32
	main_vbox.offset_bottom = -24
	add_child(main_vbox)

	# Header Bar
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = "VOLTARENA"
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.modulate = Color(0.0, 1.0, 1.0)
	header.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = " | CROSS-PLATFORM 3D SUITE"
	subtitle_lbl.modulate = Color(0.6, 0.75, 0.9)
	header.add_child(subtitle_lbl)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	# Controls Guide Button
	var btn_controls = Button.new()
	btn_controls.text = "CONTROLS"
	btn_controls.pressed.connect(show_controls)
	header.add_child(btn_controls)

	# Settings Button
	var btn_settings = Button.new()
	btn_settings.text = "SETTINGS"
	btn_settings.pressed.connect(show_settings)
	header.add_child(btn_settings)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 16)
	main_vbox.add_child(spacer1)

	# Game Selection Scroll / Cards Container (Vertical scroll only)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	game_cards_container = GridContainer.new()
	game_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_cards_container.add_theme_constant_override("h_separation", 20)
	game_cards_container.add_theme_constant_override("v_separation", 20)
	game_cards_container.columns = 4
	scroll.add_child(game_cards_container)

	for meta in games_meta:
		create_game_card(meta)

	# Footer Bar
	var footer = HBoxContainer.new()
	main_vbox.add_child(footer)

	var platform_info = Label.new()
	platform_info.text = "VOLTARENA 3D HIGH-PERFORMANCE SUITE"
	platform_info.modulate = Color(0.45, 0.75, 0.95)
	footer.add_child(platform_info)

	var footer_spacer = Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)

	var hint_info = Label.new()
	hint_info.text = "Press ESC or Select for Settings | Gamepad & Touch Ready"
	hint_info.modulate = Color(0.35, 0.45, 0.6)
	footer.add_child(hint_info)

	setup_loading_overlay()
	setup_settings_dialog()
	_setup_controls_dialog()

func create_game_card(meta: Dictionary) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 320)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Hover micro-animation effect
	card.mouse_entered.connect(func():
		var tween = card.create_tween()
		tween.tween_property(card, "modulate", Color(1.15, 1.15, 1.2), 0.15)
	)
	card.mouse_exited.connect(func():
		var tween = card.create_tween()
		tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0), 0.15)
	)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# Stylized In-Engine Artwork Banner
	var banner_rect = TextureRect.new()
	banner_rect.custom_minimum_size = Vector2(100, 100)
	banner_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_rect.stretch_mode = TextureRect.STRETCH_SCALE
	banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_rect.texture = LauncherArtScript.create_game_banner(meta["id"], 360, 190)
	vbox.add_child(banner_rect)

	# Title & Tagline
	var title = Label.new()
	title.text = meta["title"]
	title.add_theme_font_size_override("font_size", 19)
	title.modulate = meta["color"]
	vbox.add_child(title)

	var tagline = Label.new()
	tagline.text = meta["tagline"]
	tagline.modulate = Color(0.7, 0.8, 0.9)
	vbox.add_child(tagline)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Tags Row
	var tags_box = HBoxContainer.new()
	for tag in meta["tags"]:
		var chip = Label.new()
		chip.text = "[%s]" % tag
		chip.modulate = meta["color"] * 0.85
		tags_box.add_child(chip)
	vbox.add_child(tags_box)

	# Description
	var desc = Label.new()
	desc.text = meta["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.modulate = Color(0.8, 0.85, 0.9)
	vbox.add_child(desc)

	# Stats display
	var stats_lbl = Label.new()
	stats_lbl.text = get_game_career_stats(meta["id"])
	stats_lbl.modulate = Color(0.5, 0.8, 1.0)
	vbox.add_child(stats_lbl)

	# Play Button
	var btn_play = Button.new()
	btn_play.text = "PLAY"
	btn_play.custom_minimum_size = Vector2(0, 38)
	btn_play.mouse_entered.connect(func():
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sfx("ui_hover")
	)
	btn_play.pressed.connect(func():
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sfx("ui_click")
		on_play_game_pressed(meta)
	)
	vbox.add_child(btn_play)

	game_cards_container.add_child(card)

func get_game_career_stats(game_id: String) -> String:
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if not sm:
		return ""
	var stats = sm.save_data.get("statistics", {}).get(game_id, {})
	match game_id:
		"arena_fps":
			return "Kills: %d | High Score: %d" % [stats.get("kills", 0), stats.get("highest_score", 0)]
		"subway_survival":
			return "Highest Wave: %d | Total Kills: %d" % [stats.get("highest_wave", 0), stats.get("total_kills", 0)]
		"rocket_car":
			return "Goals Scored: %d | Wins: %d" % [stats.get("goals_scored", 0), stats.get("wins", 0)]
		"kart_racing":
			var best = stats.get("best_lap_canyon", 999.0)
			return "Races: %d | Best Lap: %s" % [stats.get("races_finished", 0), ("%.1fs" % best) if best < 900.0 else "--"]
		_:
			return ""

func setup_loading_overlay() -> void:
	loading_overlay = PanelContainer.new()
	loading_overlay.anchor_left = 0.5
	loading_overlay.anchor_top = 0.5
	loading_overlay.anchor_right = 0.5
	loading_overlay.anchor_bottom = 0.5
	loading_overlay.offset_left = -220
	loading_overlay.offset_top = -100
	loading_overlay.offset_right = 220
	loading_overlay.offset_bottom = 100
	loading_overlay.visible = false
	add_child(loading_overlay)

	var vbox = VBoxContainer.new()
	loading_overlay.add_child(vbox)

	loading_status_label = Label.new()
	loading_status_label.text = "Loading game assets..."
	loading_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(loading_status_label)

	loading_bar = ProgressBar.new()
	loading_bar.custom_minimum_size = Vector2(380, 24)
	loading_bar.max_value = 1.0
	loading_bar.show_percentage = true
	vbox.add_child(loading_bar)

	loading_bytes_label = Label.new()
	loading_bytes_label.text = "0 KB / 0 KB"
	loading_bytes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_bytes_label.modulate = Color(0.5, 0.7, 0.9)
	vbox.add_child(loading_bytes_label)

func setup_settings_dialog() -> void:
	settings_dialog = PanelContainer.new()
	settings_dialog.anchor_left = 0.5
	settings_dialog.anchor_top = 0.5
	settings_dialog.anchor_right = 0.5
	settings_dialog.anchor_bottom = 0.5
	settings_dialog.offset_left = -260
	settings_dialog.offset_top = -210
	settings_dialog.offset_right = 260
	settings_dialog.offset_bottom = 210
	settings_dialog.visible = false
	add_child(settings_dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	settings_dialog.add_child(vbox)

	var title = Label.new()
	title.text = "PLATFORM SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.0, 0.9, 1.0)
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Quality Presets Row
	var q_row = HBoxContainer.new()
	var q_lbl = Label.new()
	q_lbl.text = "Graphics Preset:"
	q_row.add_child(q_lbl)
	for p_info in [["LOW", 0], ["MED", 1], ["HIGH", 2], ["ULTRA", 3]]:
		var btn_q = Button.new()
		btn_q.text = p_info[0]
		btn_q.pressed.connect(func(): set_quality(p_info[1]))
		q_row.add_child(btn_q)
	vbox.add_child(q_row)

	# Audio Volume Control
	var a_row = HBoxContainer.new()
	var a_lbl = Label.new()
	a_lbl.text = "Audio Mute:"
	a_row.add_child(a_lbl)
	var btn_audio_toggle = Button.new()
	btn_audio_toggle.text = "TOGGLE MUTE"
	btn_audio_toggle.pressed.connect(toggle_audio)
	a_row.add_child(btn_audio_toggle)
	vbox.add_child(a_row)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var btn_close = Button.new()
	btn_close.text = "CLOSE"
	btn_close.pressed.connect(func(): settings_dialog.visible = false)
	vbox.add_child(btn_close)

func _setup_controls_dialog() -> void:
	controls_dialog = PanelContainer.new()
	controls_dialog.anchor_left = 0.5
	controls_dialog.anchor_top = 0.5
	controls_dialog.anchor_right = 0.5
	controls_dialog.anchor_bottom = 0.5
	controls_dialog.offset_left = -280
	controls_dialog.offset_top = -220
	controls_dialog.offset_right = 280
	controls_dialog.offset_bottom = 220
	controls_dialog.visible = false
	add_child(controls_dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	controls_dialog.add_child(vbox)

	var title = Label.new()
	title.text = "CONTROLS & INPUT GUIDE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.2, 1.0, 0.5)
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var guide_text = Label.new()
	guide_text.text = "FPS / Survival:\n  • WASD / Left Stick: Move & Strafe\n  • Mouse / Right Stick: Look / Aim\n  • Space / A Button: Jump\n  • Shift / Left Trigger: Sprint / Slide\n  • Left Click / Right Trigger: Fire\n  • 1 - 5 Keys: Switch Weapons\n\nVehicles / Racing:\n  • W / Accelerate (Right Trigger): Throttle\n  • S / Brake (Left Trigger): Reverse / Brake\n  • A / D / Left Stick: Steer\n  • Space / X Button: Handbrake / Drift\n  • Shift / B Button: Nitrous Boost\n  • ESC / Start: Pause / Back to Launcher"
	guide_text.modulate = Color(0.85, 0.9, 0.95)
	vbox.add_child(guide_text)

	var btn_close = Button.new()
	btn_close.text = "CLOSE"
	btn_close.pressed.connect(func(): controls_dialog.visible = false)
	vbox.add_child(btn_close)

func show_settings() -> void:
	settings_dialog.visible = true
	if controls_dialog:
		controls_dialog.visible = false

func show_controls() -> void:
	if controls_dialog:
		controls_dialog.visible = true
	if settings_dialog:
		settings_dialog.visible = false

func set_quality(preset: int) -> void:
	var qm = GameConstants.get_autoload(self, "QualityManager")
	if qm:
		qm.apply_preset(preset)

func toggle_audio() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, not is_muted)

func on_play_game_pressed(meta: Dictionary) -> void:
	current_target_game = meta["id"]
	loading_overlay.visible = true
	loading_status_label.text = "Preparing %s..." % meta["title"]
	loading_bar.value = 0.0

	var loader = GameConstants.get_autoload(self, "AssetLoader")
	if loader:
		loader.request_game_load(meta["id"], meta["scene"])
	else:
		# Direct fallback
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.game_selected.emit(meta["id"])

func connect_loader_signals() -> void:
	var loader = GameConstants.get_autoload(self, "AssetLoader")
	if loader:
		loader.load_progress_updated.connect(func(_g_id, p, cur_b, tot_b, msg):
			loading_bar.value = p
			loading_status_label.text = msg
			loading_bytes_label.text = "%d KB / %d KB" % [cur_b / 1024, tot_b / 1024]
		)
		loader.load_completed.connect(func(g_id, success, _scene):
			loading_overlay.visible = false
			if not success:
				var bus = GameConstants.get_autoload(self, "EventBus")
				if bus:
					bus.show_toast_requested.emit("Failed to load %s assets" % g_id, Color(1.0, 0.3, 0.3))
				return
			var bus = GameConstants.get_autoload(self, "EventBus")
			if success and bus:
				bus.game_selected.emit(g_id)
		)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_responsive_layout(size)

func update_responsive_layout(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return

	var safe_left = 24.0
	var safe_right = 24.0
	var safe_top = 20.0
	var safe_bottom = 20.0

	# Safe area cutouts only on mobile devices with notches
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		var safe_area = DisplayServer.get_display_safe_area()
		var screen_sz = DisplayServer.screen_get_size()
		if safe_area.size.x > 0 and screen_sz.x > 0:
			var scale_x = viewport_size.x / float(screen_sz.x)
			var scale_y = viewport_size.y / float(screen_sz.y)
			safe_left = maxf(24.0, float(safe_area.position.x) * scale_x)
			safe_top = maxf(20.0, float(safe_area.position.y) * scale_y)
			safe_right = maxf(24.0, float(screen_sz.x - (safe_area.position.x + safe_area.size.x)) * scale_x)
			safe_bottom = maxf(20.0, float(screen_sz.y - (safe_area.position.y + safe_area.size.y)) * scale_y)

	if main_vbox:
		main_vbox.offset_left = safe_left
		main_vbox.offset_top = safe_top
		main_vbox.offset_right = -safe_right
		main_vbox.offset_bottom = -safe_bottom

	if settings_dialog:
		var dialog_w = min(viewport_size.x * 0.9, 520.0)
		var dialog_h = min(viewport_size.y * 0.8, 420.0)
		settings_dialog.offset_left = -dialog_w * 0.5
		settings_dialog.offset_right = dialog_w * 0.5
		settings_dialog.offset_top = -dialog_h * 0.5
		settings_dialog.offset_bottom = dialog_h * 0.5

	if controls_dialog:
		var dialog_w = min(viewport_size.x * 0.9, 560.0)
		var dialog_h = min(viewport_size.y * 0.8, 440.0)
		controls_dialog.offset_left = -dialog_w * 0.5
		controls_dialog.offset_right = dialog_w * 0.5
		controls_dialog.offset_top = -dialog_h * 0.5
		controls_dialog.offset_bottom = dialog_h * 0.5

	if game_cards_container:
		var cols = 4
		if viewport_size.x < 680.0:
			cols = 1 # Mobile portrait (1 col)
		elif viewport_size.x < 1120.0:
			cols = 2 # Tablet / compact desktop (2x2 grid)
		else:
			cols = 4 # Desktop (4 columns)

		game_cards_container.columns = cols

		var h_sep = 16.0
		var v_sep = 16.0
		game_cards_container.add_theme_constant_override("h_separation", int(h_sep))
		game_cards_container.add_theme_constant_override("v_separation", int(v_sep))

		var available_w = maxf(280.0, viewport_size.x - (safe_left + safe_right) - 8.0)
		var total_sep = float(cols - 1) * h_sep
		var card_w = floor((available_w - total_sep) / float(cols))

		var padding_v = safe_top + safe_bottom + 110.0
		var available_h = maxf(320.0, viewport_size.y - padding_v)

		for c in game_cards_container.get_children():
			if c is Control:
				c.custom_minimum_size.x = maxf(100.0, card_w)
				if cols == 4:
					c.custom_minimum_size.y = clampf(available_h, 320.0, 520.0)
				elif cols == 2:
					c.custom_minimum_size.y = clampf(available_h * 0.48, 280.0, 390.0)
				else:
					c.custom_minimum_size.y = 320.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var vp = get_viewport()
		if settings_dialog and settings_dialog.visible:
			settings_dialog.visible = false
			if vp:
				vp.set_input_as_handled()
		elif controls_dialog and controls_dialog.visible:
			controls_dialog.visible = false
			if vp:
				vp.set_input_as_handled()
