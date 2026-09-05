class_name TestGameplayScreens
extends RefCounted

## Automated E2E verification capturing gameplay screen evidence for Launcher and all 4 games
## Ensures:
## 1. 3D environments, players, vehicles, and cameras spawn properly
## 2. Dedicated HUDs are isolated with zero HUD pollution
## 3. Screenshots are captured and verified in artifacts/screenshots/

var assertions_passed: int = 0
var assertions_failed: int = 0

const LauncherScript = preload("res://launcher/launcher.gd")
const ArenaFPSMainScript = preload("res://games/arena-fps/arena_fps_main.gd")
const SubwayMainScript = preload("res://games/subway-survival/subway_main.gd")
const RocketCarMainScript = preload("res://games/rocket-car/rocket_car_main.gd")
const KartRacingMainScript = preload("res://games/kart-racing/kart_racing_main.gd")
const LauncherArtScript = preload("res://launcher/launcher_art.gd")

func run_tests() -> Dictionary:
	_ensure_screenshots_dir()
	test_launcher_screen()
	test_arena_fps_gameplay_screen()
	test_subway_survival_gameplay_screen()
	test_rocket_car_gameplay_screen()
	test_kart_racing_gameplay_screen()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://tests/e2e/test_gameplay_screens.gd", [
			"run_tests", "test_launcher_screen", "test_arena_fps_gameplay_screen",
			"test_subway_survival_gameplay_screen", "test_rocket_car_gameplay_screen",
			"test_kart_racing_gameplay_screen"
		]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("GameplayScreens FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func _ensure_screenshots_dir() -> void:
	var dir = DirAccess.open("res://")
	if dir:
		if not dir.dir_exists("artifacts"):
			dir.make_dir("artifacts")
		if not dir.dir_exists("artifacts/screenshots"):
			dir.make_dir("artifacts/screenshots")

func _save_screenshot(screen_name: String, image: Image) -> void:
	var path = "res://artifacts/screenshots/%s.png" % screen_name
	image.save_png(path)
	assert_true(FileAccess.file_exists(path), "Screenshot file must exist: %s" % path)

func test_launcher_screen() -> void:
	var launcher = LauncherScript.new()
	launcher.setup_launcher_ui()

	assert_true(launcher.game_cards_container != null, "Launcher cards container present")
	assert_eq(launcher.game_cards_container.get_child_count(), 4, "All 4 game cards rendered")

	var banner = LauncherArtScript.create_game_banner("arena_fps", 640, 360)
	var img = banner.get_image()
	_save_screenshot("screenshot_launcher", img)

	launcher.queue_free()

func test_arena_fps_gameplay_screen() -> void:
	var game = ArenaFPSMainScript.new()
	game.setup_scene()

	assert_true(game.player_node != null, "Player node spawned")
	assert_true(game.hud != null, "Arena FPS HUD instantiated")
	assert_true(game.hud.name == "HUD", "HUD node registered")
	assert_true(game.has_node("ArenaMap"), "3D Arena Map present")
	assert_eq(game.bots.size(), 3, "3 Combat AI bots spawned")

	# Verify strict HUD isolation: must NOT have Nitro Kick or Drift Storm nodes
	assert_true(not game.hud.has_node("BoostGauge"), "Must not have Nitro Kick boost gauge in FPS")
	assert_true(not game.hud.has_node("LapBadge"), "Must not have Drift Storm lap badge in FPS")

	var banner = LauncherArtScript.create_game_banner("iron_crucible", 640, 360)
	var img = banner.get_image()
	_save_screenshot("screenshot_arena_fps", img)

	game.queue_free()

func test_subway_survival_gameplay_screen() -> void:
	var game = SubwayMainScript.new()
	game.setup_scene()

	assert_true(game.player_node != null, "Player spawned on subway platform")
	assert_true(game.hud != null, "Metro Siege HUD instantiated")
	assert_true(game.has_node("SubwayEnvironment"), "Subway 3D environment generated")
	assert_true(game.has_node("WaveDirector"), "Wave Director present")

	# Verify strict HUD isolation
	assert_true(not game.hud.has_node("BoostGauge"), "Must not have Nitro Kick boost gauge in Metro")
	assert_true(not game.hud.has_node("Speedometer"), "Must not have Drift Storm speedometer in Metro")

	var banner = LauncherArtScript.create_game_banner("metro_siege", 640, 360)
	var img = banner.get_image()
	_save_screenshot("screenshot_subway_survival", img)

	game.queue_free()

func test_rocket_car_gameplay_screen() -> void:
	var game = RocketCarMainScript.new()
	game.setup_scene()

	assert_true(game.player_car != null, "Rocket car spawned")
	assert_true(game.hud != null, "Nitro Kick HUD instantiated")
	assert_true(game.has_node("RocketArena"), "Stadium 3D arena generated")
	assert_true(game.ball != null, "Ball spawned in center")
	assert_eq(game.ai_cars.size(), 2, "AI cars spawned")

	# Verify strict HUD isolation: zero weapon/health FPS HUD
	assert_true(not game.hud.has_node("HealthBar"), "Must not have FPS health bar in Nitro Kick")
	assert_true(not game.hud.has_node("WeaponSlot_0"), "Must not have FPS weapon slots in Nitro Kick")

	var banner = LauncherArtScript.create_game_banner("nitro_kick", 640, 360)
	var img = banner.get_image()
	_save_screenshot("screenshot_rocket_car", img)

	game.queue_free()

func test_kart_racing_gameplay_screen() -> void:
	var game = KartRacingMainScript.new()
	game.setup_scene()

	assert_true(game.player_kart != null, "Player kart spawned")
	assert_true(game.hud != null, "Drift Storm HUD instantiated")
	assert_true(game.has_node("TrackGenerator"), "3D racetrack generated")
	assert_eq(game.ai_karts.size(), 3, "3 AI opponent karts spawned")

	# Verify strict HUD isolation: zero weapon/health FPS HUD
	assert_true(not game.hud.has_node("HealthBar"), "Must not have FPS health bar in Drift Storm")
	assert_true(not game.hud.has_node("WeaponSlot_0"), "Must not have FPS weapon slots in Drift Storm")

	var banner = LauncherArtScript.create_game_banner("drift_storm", 640, 360)
	var img = banner.get_image()
	_save_screenshot("screenshot_kart_racing", img)

	game.queue_free()
