class_name Launcher
extends Control

var game_cards_container: HBoxContainer
var loading_overlay: PanelContainer
var loading_bar: ProgressBar
var loading_status_label: Label
var loading_bytes_label: Label
var settings_dialog: PanelContainer

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

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
	setup_launcher_ui()
	connect_loader_signals()

	var im = GameConstants.get_autoload(self, "InputManager")
	if im:
		im.capture_mouse(false)

func setup_launcher_ui() -> void:
	# Dark Cyberpunk Background
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.04, 0.05, 0.08)
	add_child(bg)

	# Decorative Grid Background lines
	var grid_overlay = Control.new()
	grid_overlay.anchor_right = 1.0
	grid_overlay.anchor_bottom = 1.0
	grid_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	grid_overlay.draw.connect(func():
		for x in range(0, int(size.x), 60):
			grid_overlay.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.1, 0.15, 0.25, 0.15), 1.0)
		for y in range(0, int(size.y), 60):
			grid_overlay.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.1, 0.15, 0.25, 0.15), 1.0)
	)
	add_child(grid_overlay)

	# Main Vertical Layout
	var main_vbox = VBoxContainer.new()
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
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.modulate = Color(0.0, 1.0, 1.0)
	header.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = " | CROSS-PLATFORM 3D GAME SUITE"
	subtitle_lbl.modulate = Color(0.6, 0.75, 0.9)
	header.add_child(subtitle_lbl)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	# Settings Button
	var btn_settings = Button.new()
	btn_settings.text = "SETTINGS"
	btn_settings.pressed.connect(show_settings)
	header.add_child(btn_settings)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer1)

	# Game Selection Scroll / Cards Container
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	game_cards_container = HBoxContainer.new()
	game_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_cards_container.add_theme_constant_override("separation", 20)
	scroll.add_child(game_cards_container)

	for meta in games_meta:
		create_game_card(meta)

	# Footer Bar
	var footer = HBoxContainer.new()
	main_vbox.add_child(footer)

	var platform_info = Label.new()
	var plat_name = "Desktop"
	var pa = GameConstants.get_autoload(self, "PlatformAdapter")
	if pa:
		plat_name = pa.get_platform_name_string()
	platform_info.text = "Platform: %s | Zero Host Packages Required | Cloudflare Pages Certified" % plat_name
	platform_info.modulate = Color(0.4, 0.5, 0.65)
	footer.add_child(platform_info)

	setup_loading_overlay()
	setup_settings_dialog()

func create_game_card(meta: Dictionary) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(275, 420)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# Title & Tagline
	var title = Label.new()
	title.text = meta["title"]
	title.add_theme_font_size_override("font_size", 22)
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
	btn_play.text = "LAUNCH GAME"
	btn_play.custom_minimum_size = Vector2(0, 48)
	btn_play.pressed.connect(func(): on_play_game_pressed(meta))
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
	settings_dialog.offset_left = -250
	settings_dialog.offset_top = -200
	settings_dialog.offset_right = 250
	settings_dialog.offset_bottom = 200
	settings_dialog.visible = false
	add_child(settings_dialog)

	var vbox = VBoxContainer.new()
	settings_dialog.add_child(vbox)

	var title = Label.new()
	title.text = "PLATFORM SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Quality Preset Option
	var q_row = HBoxContainer.new()
	var q_lbl = Label.new()
	q_lbl.text = "Graphics Preset:"
	q_row.add_child(q_lbl)
	var btn_q_low = Button.new()
	btn_q_low.text = "LOW"
	btn_q_low.pressed.connect(func(): set_quality(0)) # 0: LOW
	q_row.add_child(btn_q_low)
	var btn_q_high = Button.new()
	btn_q_high.text = "HIGH"
	btn_q_high.pressed.connect(func(): set_quality(2)) # 2: HIGH
	q_row.add_child(btn_q_high)
	vbox.add_child(q_row)

	# Audio Mute Toggle
	var a_row = HBoxContainer.new()
	var a_lbl = Label.new()
	a_lbl.text = "Master Audio:"
	a_row.add_child(a_lbl)
	var btn_audio_toggle = Button.new()
	btn_audio_toggle.text = "TOGGLE MUTE"
	btn_audio_toggle.pressed.connect(toggle_audio)
	a_row.add_child(btn_audio_toggle)
	vbox.add_child(a_row)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	var btn_close = Button.new()
	btn_close.text = "CLOSE"
	btn_close.pressed.connect(func(): settings_dialog.visible = false)
	vbox.add_child(btn_close)

func show_settings() -> void:
	settings_dialog.visible = true

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
			var bus = GameConstants.get_autoload(self, "EventBus")
			if success and bus:
				bus.game_selected.emit(g_id)
		)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_responsive_layout(size)

func update_responsive_layout(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0:
		return
	var is_narrow = viewport_size.x < 800.0 or (viewport_size.y > 0 and viewport_size.x / viewport_size.y < 1.2)
	if settings_dialog:
		var dialog_w = min(viewport_size.x * 0.9, 500.0)
		var dialog_h = min(viewport_size.y * 0.8, 400.0)
		settings_dialog.offset_left = -dialog_w * 0.5
		settings_dialog.offset_right = dialog_w * 0.5
		settings_dialog.offset_top = -dialog_h * 0.5
		settings_dialog.offset_bottom = dialog_h * 0.5

	if game_cards_container:
		var card_w = 260.0 if not is_narrow else clampf(viewport_size.x - 80.0, 220.0, 340.0)
		for c in game_cards_container.get_children():
			if c is Control:
				c.custom_minimum_size.x = card_w
