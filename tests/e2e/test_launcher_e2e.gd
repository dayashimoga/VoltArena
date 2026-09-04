class_name TestLauncherE2E
extends RefCounted

## End-to-end acceptance test for the VoltArena Universal Launcher.
## Tests: UI setup → game cards → career stats → loading overlay → settings → scene signals

const LauncherScript = preload("res://launcher/launcher.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_launcher_initialization()
	test_game_cards_created()
	test_game_metadata_completeness()
	test_loading_overlay()
	test_settings_dialog()
	test_career_stats_formatting()
	test_game_selection_flow()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://launcher/launcher.gd", ["_ready", "setup_launcher_ui", "create_game_card", "get_game_career_stats", "setup_loading_overlay", "setup_settings_dialog", "show_settings", "set_quality", "toggle_audio", "on_play_game_pressed", "connect_loader_signals"]],
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

	launcher.queue_free()

func test_game_cards_created() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	assert_eq(launcher.game_cards_container.get_child_count(), 4, "Must create 4 game cards")

	launcher.queue_free()

func test_game_metadata_completeness() -> void:
	var launcher = LauncherScript.new()

	assert_eq(launcher.games_meta.size(), 4, "Must have metadata for 4 games")

	var required_keys = ["id", "title", "tagline", "desc", "tags", "color", "scene"]
	for meta in launcher.games_meta:
		for key in required_keys:
			assert_true(meta.has(key), "Game '%s' must have key '%s'" % [meta.get("title", "unknown"), key])

	# Verify unique IDs
	var ids = []
	for meta in launcher.games_meta:
		assert_true(not meta["id"] in ids, "Game ID '%s' must be unique" % meta["id"])
		ids.append(meta["id"])

	# Verify scene paths are valid res:// paths
	for meta in launcher.games_meta:
		assert_true(meta["scene"].begins_with("res://"), "Scene path must start with res://")
		assert_true(meta["scene"].ends_with(".tscn"), "Scene path must end with .tscn")

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

	launcher.queue_free()

func test_career_stats_formatting() -> void:
	var launcher = LauncherScript.new()

	# Without SaveManager, should return empty string
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

	# Simulate pressing play — without AssetLoader/EventBus, should not crash
	var meta = launcher.games_meta[0]
	launcher.on_play_game_pressed(meta)

	assert_true(launcher.loading_overlay.visible, "Loading overlay must show on game selection")
	assert_eq(launcher.current_target_game, meta["id"], "Target game must be set")

	launcher.queue_free()
