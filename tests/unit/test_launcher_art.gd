class_name TestLauncherArt
extends RefCounted

## Unit test for procedural launcher artwork generator

var assertions_passed: int = 0
var assertions_failed: int = 0

const LauncherArtScript = preload("res://launcher/launcher_art.gd")

func run_tests() -> Dictionary:
	test_all_game_banners()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://launcher/launcher_art.gd", ["create_game_banner"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: " + msg)

func test_all_game_banners() -> void:
	var games = ["arena_fps", "subway_survival", "rocket_car", "kart_racing", "unknown"]
	for g in games:
		var tex = LauncherArtScript.create_game_banner(g, 64, 32)
		assert_true(tex != null, "Banner texture for %s must not be null" % g)
		assert_true(tex.get_width() == 64, "Banner width must match")
		assert_true(tex.get_height() == 32, "Banner height must match")
