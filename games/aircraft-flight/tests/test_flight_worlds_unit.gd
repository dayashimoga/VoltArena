class_name TestFlightWorldsUnit
extends RefCounted

## TestFlightWorldsUnit: Unit tests for runway generation, city architecture,
## 8 world biomes, and safe spawn/recovery points.

const RunwayGen = preload("res://games/aircraft-flight/worlds/runway_generator.gd")
const CityFlightWorldScript = preload("res://games/aircraft-flight/worlds/city_flight_world.gd")
const FlightWorldManagerScript = preload("res://games/aircraft-flight/worlds/flight_world_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_runway_generation()
	test_city_flight_world_architecture()
	test_world_manager_all_biomes()
	test_safe_spawn_points()

	return {"passed": assertions_passed, "failed": assertions_failed}

func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: %s" % msg)

func test_runway_generation() -> void:
	var runway = RunwayGen.build_runway(2400.0, 60.0, "09L")
	_assert_true(runway != null, "Runway node generated")
	_assert_true(runway.find_child("RunwayCollision", true, false) != null, "Runway static collision body exists")
	_assert_true(runway.find_child("PAPI_Lights", true, false) != null, "PAPI glide slope lighting exists")
	_assert_true(runway.find_child("ALS_Towers", true, false) != null, "Approach lighting towers exist")
	runway.free()

func test_city_flight_world_architecture() -> void:
	var city = CityFlightWorldScript.new()
	city.build_world()

	_assert_true(city.airport_runway != null, "City airport primary runway initialized")
	_assert_true(city.bridge_root != null, "Twin-tower suspension bridge exists")
	_assert_true(city.skyscraper_colliders.size() >= 40, "Skyscraper grid contains 40+ high-rises")
	city.free()

func test_world_manager_all_biomes() -> void:
	var wm = FlightWorldManagerScript.new()
	wm.setup_lighting_and_atmosphere()

	var biomes = [
		"metropolitan_city", "alpine_mountains", "arctic_snow",
		"tropical_beach", "desert_canyon", "volcanic_underworld",
		"dense_forest", "alien_planet"
	]

	for b_id in biomes:
		wm.load_world(b_id)
		_assert_true(wm.active_world_root != null, "World biome loaded successfully: %s" % b_id)
		_assert_true(wm.active_world_root.name == "ActiveWorld_" + b_id, "Biome root container correctly tagged: %s" % b_id)

	wm.free()

func test_safe_spawn_points() -> void:
	var city = CityFlightWorldScript.new()
	var sp_rwy = city.get_spawn_point("runway_takeoff")
	_assert_true(sp_rwy.get("airborne") == false, "Runway takeoff spawn grounded")
	_assert_true(sp_rwy.get("airspeed_kmh") == 0.0, "Takeoff initial speed is 0 km/h")

	var sp_app = city.get_spawn_point("airborne_approach")
	_assert_true(sp_app.get("airborne") == true, "Airborne approach spawn active")
	_assert_true(sp_app.get("airspeed_kmh") > 200.0, "Airborne spawn initial airspeed applied")

	var sp_city = city.get_spawn_point("city_skimming")
	_assert_true(sp_city.get("position").y > 100.0, "City skimming altitude safely above street level")
	city.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/aircraft-flight/worlds/runway_generator.gd",
			["build_runway", "_create_decal_box"]
		],
		[
			"res://games/aircraft-flight/worlds/city_flight_world.gd",
			[
				"_ready", "build_world", "_build_ground_plane", "_build_airport_complex",
				"_build_metropolitan_city_grid", "_build_suspension_bridge",
				"_build_harbor_and_docks", "_add_colliding_box", "get_spawn_point"
			]
		],
		[
			"res://games/aircraft-flight/worlds/flight_world_manager.gd",
			[
				"_ready", "setup_lighting_and_atmosphere", "load_world", "_apply_atmosphere",
				"_build_mountain_biome", "_build_arctic_biome", "_build_tropical_biome",
				"_build_desert_biome", "_build_volcanic_biome", "_build_forest_biome",
				"_build_alien_biome", "_create_terrain_plane", "_create_colliding_box",
				"_create_peak", "get_spawn_point"
			]
		]
	]
