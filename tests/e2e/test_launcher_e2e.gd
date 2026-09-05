class_name TestLauncherE2E
extends RefCounted

## End-to-end acceptance test for the VoltArena Universal Launcher.

const LauncherScript = preload("res://launcher/launcher.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_launcher_initialization()
	test_game_cards_creation()
	test_game_metadata_completeness()
	test_loading_overlay()
	test_settings_dialog()
	test_controls_dialog()
	test_responsive_layout()
	test_career_stats_formatting()
	test_game_selection_flow()
	test_unhandled_input_esc()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://launcher/launcher.gd", [
			"_ready", "setup_launcher_ui", "create_game_card", "get_game_career_stats",
			"setup_loading_overlay", "setup_settings_dialog", "show_settings", "show_controls",
			"set_quality", "toggle_audio", "on_play_game_pressed", "connect_loader_signals",
			"_notification", "update_responsive_layout", "_unhandled_input"
		]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E Launcher FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_launcher_initialization() -> void:
	var launcher = LauncherScript.new()
	launcher._ready()

	assert_true(launcher.game_cards_container != null, "Game cards container must exist")
	assert_true(launcher.loading_overlay != null, "Loading overlay must exist")
	assert_true(launcher.settings_dialog != null, "Settings dialog must exist")
	assert_true(launcher.controls_dialog != null, "Controls dialog must exist")

	launcher.queue_free()

func test_game_cards_creation() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	assert_eq(launcher.game_cards_container.get_child_count(), 4, "Must create 4 game cards")

	launcher.queue_free()

func test_game_metadata_completeness() -> void:
	var launcher = LauncherScript.new()

	assert_eq(launcher.games_meta.size(), 4, "Must have metadata for 4 games")

	var expected_ids = ["arena_fps", "subway_survival", "rocket_car", "kart_racing"]
	for meta in launcher.games_meta:
		assert_true(meta["id"] in expected_ids, "Game ID must be valid: %s" % meta["id"])
		assert_true(meta["title"].length() > 0, "Game must have title: %s" % meta["id"])
		assert_true(meta["desc"].length() > 0, "Game must have description: %s" % meta["id"])
		assert_true(meta["tags"].size() > 0, "Game must have tags: %s" % meta["id"])
		assert_true(meta["scene"].begins_with("res://"), "Game must have valid scene path: %s" % meta["id"])

	for meta in launcher.games_meta:
		var has_res = ResourceLoader.exists(meta["scene"])
		assert_true(has_res, "Game scene must exist on disk: %s" % meta["scene"])

	var ids = []
	for meta in launcher.games_meta:
		assert_true(not meta["id"] in ids, "Game ID must be unique: %s" % meta["id"])
		ids.append(meta["id"])

	launcher.queue_free()

func test_loading_overlay() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	assert_true(not launcher.loading_overlay.visible, "Loading overlay must be hidden initially")
	assert_true(launcher.loading_bar != null, "Loading bar must exist")
	assert_true(launcher.loading_status_label != null, "Status label must exist")
	assert_true(launcher.loading_bytes_label != null, "Bytes label must exist")

	launcher.queue_free()

func test_settings_dialog() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	assert_true(not launcher.settings_dialog.visible, "Settings dialog must be hidden initially")

	launcher.show_settings()
	assert_true(launcher.settings_dialog.visible, "Settings dialog must be visible after show")

	launcher.set_quality(1)
	launcher.toggle_audio()

	launcher.queue_free()

func test_controls_dialog() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	assert_true(not launcher.controls_dialog.visible, "Controls dialog must be hidden initially")

	launcher.show_controls()
	assert_true(launcher.controls_dialog.visible, "Controls dialog must be visible after show")
	assert_true(not launcher.settings_dialog.visible, "Settings dialog should close when controls opened")

	launcher.queue_free()

func test_responsive_layout() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	launcher.update_responsive_layout(Vector2(600, 800)) # Mobile portrait
	assert_eq(launcher.game_cards_container.columns, 1, "Should be 1 column on mobile")

	launcher.update_responsive_layout(Vector2(900, 700)) # Tablet
	assert_eq(launcher.game_cards_container.columns, 2, "Should be 2 columns on tablet")

	launcher.update_responsive_layout(Vector2(1400, 900)) # Desktop
	assert_eq(launcher.game_cards_container.columns, 4, "Should be 4 columns on desktop")

	launcher._notification(Control.NOTIFICATION_RESIZED)

	launcher.queue_free()

func test_career_stats_formatting() -> void:
	var launcher = LauncherScript.new()

	var stats = launcher.get_game_career_stats("arena_fps")
	assert_eq(stats, "", "Stats must be empty without SaveManager")

	stats = launcher.get_game_career_stats("subway_survival")
	assert_eq(stats, "", "Stats must be empty without SaveManager")

	stats = launcher.get_game_career_stats("rocket_car")
	assert_eq(stats, "", "Stats must be empty without SaveManager")

	stats = launcher.get_game_career_stats("kart_racing")
	assert_eq(stats, "", "Stats must be empty without SaveManager")

	stats = launcher.get_game_career_stats("nonexistent_game")
	assert_eq(stats, "", "Unknown game must return empty stats")

	launcher.queue_free()

func test_game_selection_flow() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	var meta = launcher.games_meta[0]
	launcher.on_play_game_pressed(meta)

	assert_true(launcher.loading_overlay.visible, "Loading overlay must show on game selection")
	assert_eq(launcher.current_target_game, meta["id"], "Target game must be set")

	launcher.queue_free()

func test_unhandled_input_esc() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()
	launcher.show_settings()
	assert_true(launcher.settings_dialog.visible, "Settings dialog must be visible after show_settings")

	var ev = InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_ESCAPE
	launcher._unhandled_input(ev)
	assert_true(not launcher.settings_dialog.visible, "Settings dialog must close on ESC")

	launcher.show_controls()
	launcher._unhandled_input(ev)
	assert_true(not launcher.controls_dialog.visible, "Controls dialog must close on ESC")

	launcher.queue_free()
