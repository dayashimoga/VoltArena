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
		["res://launcher/launcher_art.gd", [
			"create_game_banner",
			"_paint_iron_crucible", "_paint_metro_siege", "_paint_nitro_kick",
			"_paint_drift_storm", "_paint_strike_vector", "_paint_aero_rush",
			"_paint_apex_flight", "_paint_urban_legends", "_paint_skybound_odyssey",
			"_paint_roboforge_arena", "_paint_wildcircuit", "_paint_chroma_rush",
			"_paint_flight_simulator_6dof", "_paint_default_banner"
		]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: " + msg)

func test_all_game_banners() -> void:
	var games = [
		"arena_fps", "subway_survival", "rocket_car", "kart_racing",
		"skybound_odyssey", "roboforge_arena", "wildcircuit", "strike_vector",
		"chroma_rush", "aero_rush", "aircraft_flight", "urban_legends",
		"flight_simulator_6dof", "unknown"
	]
	for g in games:
		var tex = LauncherArtScript.create_game_banner(g, 64, 32)
		assert_true(tex != null, "Banner texture for %s must not be null" % g)
		assert_true(tex.get_width() == 64, "Banner width must match")
		assert_true(tex.get_height() == 32, "Banner height must match")
