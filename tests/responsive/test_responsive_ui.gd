class_name TestResponsiveUI
extends RefCounted

## Validates responsive UI layouts across multiple display resolutions and aspect ratios:
## - 1920x1080 (Desktop 16:9)
## - 1280x720 (HD 16:9)
## - 1024x768 (Tablet 4:3)
## - 720x1280 (Mobile Portrait 9:16)
## - 800x480 (Handheld 5:3)

const LauncherScript = preload("res://launcher/launcher.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

const TEST_RESOLUTIONS: Array[Dictionary] = [
	{"name": "Desktop 1080p", "size": Vector2(1920, 1080), "is_portrait": false},
	{"name": "Standard HD 720p", "size": Vector2(1280, 720), "is_portrait": false},
	{"name": "Tablet 4:3", "size": Vector2(1024, 768), "is_portrait": false},
	{"name": "Mobile Portrait 9:16", "size": Vector2(720, 1280), "is_portrait": true},
	{"name": "Handheld 5:3", "size": Vector2(800, 480), "is_portrait": false},
]

func run_tests() -> Dictionary:
	test_launcher_responsive_resolutions()
	test_hud_responsive_resolutions()
	test_pause_menu_responsive_resolutions()
	test_results_screen_responsive_resolutions()
	var results_dict = {
		"overall_status": "PASS" if assertions_failed == 0 else "FAIL",
		"total_passed": assertions_passed,
		"total_failed": assertions_failed,
		"resolutions_tested": TEST_RESOLUTIONS.size(),
		"timestamp": Time.get_datetime_string_from_system()
	}
	var file = FileAccess.open("res://artifacts/responsive-results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(results_dict, "  "))
		file.close()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://launcher/launcher.gd",
			["_notification", "update_responsive_layout"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Responsive UI FAIL: " + msg)

func test_launcher_responsive_resolutions() -> void:
	for res in TEST_RESOLUTIONS:
		var launcher = LauncherScript.new()
		launcher.size = res["size"]
		launcher._ready()
		launcher.update_responsive_layout(res["size"])

		assert_true(launcher.game_cards_container != null, "%s: Game cards container must exist" % res["name"])
		assert_true(launcher.game_cards_container.get_child_count() == launcher.games_meta.size(), "%s: Must have %d game cards" % [res["name"], launcher.games_meta.size()])

		# Verify all game cards have positive non-zero minimum size
		for card in launcher.game_cards_container.get_children():
			if card is Control:
				assert_true(card.custom_minimum_size.x > 0, "%s: Card min width must be positive" % res["name"])
				assert_true(card.custom_minimum_size.y > 0, "%s: Card min height must be positive" % res["name"])

		launcher.queue_free()

func test_hud_responsive_resolutions() -> void:
	for res in TEST_RESOLUTIONS:
		var hud = HUDBaseScript.new()
		hud.size = res["size"]
		hud._ready()

		assert_true(hud.health_bar != null, "%s: HUD health bar must exist" % res["name"])
		assert_true(hud.armor_bar != null, "%s: HUD armor bar must exist" % res["name"])
		assert_true(hud.ammo_label != null, "%s: HUD ammo label must exist" % res["name"])
		assert_true(hud.score_label != null, "%s: HUD score label must exist" % res["name"])
		assert_true(hud.timer_label != null, "%s: HUD timer label must exist" % res["name"])

		hud.queue_free()

func test_pause_menu_responsive_resolutions() -> void:
	for res in TEST_RESOLUTIONS:
		var pm = PauseMenuScript.new()
		pm._ready()
		pm.show_pause()
		assert_true(pm.panel != null, "%s: Pause panel must exist" % res["name"])
		assert_true(pm.panel.offset_right > pm.panel.offset_left, "%s: Panel must have positive width" % res["name"])
		pm.queue_free()

func test_results_screen_responsive_resolutions() -> void:
	for res in TEST_RESOLUTIONS:
		var rs = ResultsScreenScript.new()
		rs._ready()
		rs.display_results(true, {"Score": "100"})
		assert_true(rs.visible, "%s: Results screen must be visible" % res["name"])
		assert_true(rs.stats_vbox != null, "%s: Stats vbox must exist" % res["name"])
		rs.queue_free()
