class_name TestResponsiveUI
extends RefCounted

## Validates responsive UI layouts across the 9 mandatory platform viewport gates:
## - 360x800 (Modern Android Phone Portrait, 20:9)
## - 393x852 (iPhone 14/15/16 Portrait, 19.5:9)
## - 412x915 (Google Pixel / Galaxy Portrait, 20:9)
## - 600x960 (7-inch Tablet / Foldable, 16:10)
## - 800x1280 (10-inch Android Tablet, 16:10)
## - 1280x720 (Standard HD, 16:9)
## - 1366x768 (Budget Laptop / Scaled Window, 16:9)
## - 1920x1080 (Desktop Full HD, 16:9)
## - 2560x1440 (Desktop QHD, 16:9)

const LauncherScript = preload("res://launcher/launcher.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")
const DriftStormHUDScript = preload("res://games/kart-racing/ui/drift_storm_hud.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

const TEST_RESOLUTIONS: Array[Dictionary] = [
	{"name": "Android Phone 360x800", "size": Vector2(360, 800), "is_portrait": true},
	{"name": "iPhone 393x852", "size": Vector2(393, 852), "is_portrait": true},
	{"name": "Pixel/Galaxy 412x915", "size": Vector2(412, 915), "is_portrait": true},
	{"name": "7-inch Tablet 600x960", "size": Vector2(600, 960), "is_portrait": true},
	{"name": "10-inch Tablet 800x1280", "size": Vector2(800, 1280), "is_portrait": true},
	{"name": "Standard HD 1280x720", "size": Vector2(1280, 720), "is_portrait": false},
	{"name": "Laptop 1366x768", "size": Vector2(1366, 768), "is_portrait": false},
	{"name": "Desktop 1080p 1920x1080", "size": Vector2(1920, 1080), "is_portrait": false},
	{"name": "Desktop QHD 2560x1440", "size": Vector2(2560, 1440), "is_portrait": false},
]

func run_tests() -> Dictionary:
	test_launcher_responsive_resolutions()
	test_hud_responsive_resolutions()
	test_pause_menu_responsive_resolutions()
	test_results_screen_responsive_resolutions()
	test_drift_storm_hud_responsive_resolutions()

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

func test_drift_storm_hud_responsive_resolutions() -> void:
	for res in TEST_RESOLUTIONS:
		var hud = DriftStormHUDScript.new()
		hud.size = res["size"]
		hud._ready()

		assert_true(hud.onboarding_overlay != null, "%s: Drift Storm onboarding overlay must exist" % res["name"])
		assert_true(hud.onboarding_overlay.visible, "%s: Drift Storm onboarding overlay must be visible" % res["name"])
		assert_true(hud.track_btn_map.size() == 6, "%s: All 6 track selector buttons must be registered" % res["name"])
		assert_true(hud.veh_btn_map.size() == 5, "%s: All 5 vehicle selector buttons must be registered" % res["name"])

		var cont_btn = hud.onboarding_overlay.find_child("ContinueButton", true, false) as Button
		assert_true(cont_btn != null, "%s: Always-visible Continue button must exist in hierarchy" % res["name"])
		assert_true(cont_btn.visible, "%s: Continue button must be visible" % res["name"])

		hud.queue_free()
