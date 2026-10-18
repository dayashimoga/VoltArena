class_name TestUrbanTrafficAndAIUnit
extends RefCounted

## Unit tests for Urban Legends traffic AI, waypoint navigation, raycast collision
## avoidance, vehicle pooling, and dynamic atmospheric weather / lighting systems.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const TrafficVehicle = preload("res://games/urban-legends/traffic/traffic_vehicle.gd")
const TrafficVehicleBuilder = preload("res://games/urban-legends/traffic/traffic_vehicle_builder.gd")
const TrafficManager = preload("res://games/urban-legends/traffic/traffic_manager.gd")
const UrbanWeatherSystem = preload("res://games/urban-legends/world/urban_weather_system.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanTrafficAndAIUnit ---")
	test_traffic_vehicle_initialization()
	test_traffic_vehicle_waypoint_following()
	test_traffic_vehicle_obstacle_avoidance()
	test_traffic_vehicle_builder_models()
	test_traffic_manager_pooling_and_recycling()
	test_weather_system_time_and_presets()
	test_weather_system_clock_formatting()

	return {
		"total": total_assertions,
		"passed": passed_assertions,
		"failed": failed_assertions
	}

func assert_true(condition: bool, msg: String) -> void:
	total_assertions += 1
	if condition:
		passed_assertions += 1
		print("  [PASS] " + msg)
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg)
		push_error("Assertion failed: %s" % msg)

func test_traffic_vehicle_initialization() -> void:
	var tv = TrafficVehicle.new()
	tv._ready()

	assert_true(tv.cruise_speed_ms >= 10.0 and tv.cruise_speed_ms <= 35.0, "Cruise speed should be 10-35 m/s (~36-126 km/h) (was: %f)" % tv.cruise_speed_ms)
	assert_true(tv.visual_wheels.size() == 4, "Traffic vehicle must instantiate 4 visual wheels (found: %d)" % tv.visual_wheels.size())
	assert_true(tv.avoidance_ray != null, "Forward raycast obstacle sensor must be initialized")
	assert_true(tv.is_traffic_active, "Vehicle should be marked active initially")

	tv.free()

func test_traffic_vehicle_waypoint_following() -> void:
	var tv = TrafficVehicle.new()
	tv._ready()

	# Supply 3 straight waypoints 50m apart along Z axis
	var wps: Array[Transform3D] = [
		Transform3D(Basis(), Vector3(0, 0, 0)),
		Transform3D(Basis(), Vector3(0, 0, 50.0)),
		Transform3D(Basis(), Vector3(0, 0, 100.0))
	]
	tv.set_waypoints(wps)
	tv.position = Vector3(0, 0, 0)
	tv.current_speed = 15.0

	assert_true(tv.current_waypoint_index == 0, "Initial target waypoint should be 0")

	# Step physics at origin (<8m of wp 0) -> should advance to waypoint 1
	tv._physics_process(0.1)
	assert_true(tv.current_waypoint_index >= 1, "Vehicle should advance waypoint index when near target (current: %d)" % tv.current_waypoint_index)

	tv.free()

func test_traffic_vehicle_obstacle_avoidance() -> void:
	var tv = TrafficVehicle.new()
	tv._ready()
	tv.set_waypoints([
		Transform3D(Basis(), Vector3(0, 0, 0)),
		Transform3D(Basis(), Vector3(0, 0, 100.0))
	])
	tv.current_speed = 20.0

	# Emulate detecting an obstacle ahead
	tv.force_obstacle_detected = true
	var speed_before = tv.current_speed
	tv._physics_process(0.2)

	assert_true(tv.current_speed < speed_before, "Vehicle must decelerate when obstacle detected (was %f -> %f)" % [speed_before, tv.current_speed])

	# Reset state via helper
	tv.reset_traffic_state(Vector3(100, 0, 100), Vector3(0, 0, 1))
	assert_true(tv.position == Vector3(100, 0, 100), "Reset state should update position correctly")

	tv.free()

func test_traffic_vehicle_builder_models() -> void:
	# Test all 8 authentic vehicle classes
	for v_class in TrafficVehicleBuilder.ALL_CLASSES:
		var res: Dictionary = TrafficVehicleBuilder.build_traffic_vehicle_visual(v_class)
		assert_true(res.has("visual_root") and res["visual_root"] != null, "Vehicle model class '%s' must build visual root" % v_class)
		assert_true(res.has("wheels") and res["wheels"].size() == 4, "Vehicle model class '%s' must provide 4 wheels" % v_class)
		res["visual_root"].free()

	# Test realistic PBR materials
	var tire_mat = TrafficVehicleBuilder.get_tire_material()
	assert_true(tire_mat != null, "Tire material must be defined")
	assert_true(tire_mat.albedo_color.r < 0.2 and tire_mat.albedo_color.g < 0.2 and tire_mat.albedo_color.b < 0.2, "Tires must be dark rubber (not bright cyan)")

	var rim_mat = TrafficVehicleBuilder.get_rim_material()
	assert_true(rim_mat != null and rim_mat.metallic >= 0.7, "Rims must be metallic alloy")

	var hl_mat = TrafficVehicleBuilder.get_headlight_material()
	assert_true(hl_mat != null and hl_mat.emission_enabled and hl_mat.emission_energy_multiplier >= 3.0, "Headlights must have bright emission")

	var tl_mat = TrafficVehicleBuilder.get_taillight_material()
	assert_true(tl_mat != null and tl_mat.emission_enabled and tl_mat.emission_energy_multiplier >= 4.5, "Taillights must have bright red emission >= 4.5")

func test_traffic_manager_pooling_and_recycling() -> void:
	var road_net = UrbanRoadNetwork.new()
	var player = Node3D.new()
	player.position = Vector3(0, 0, 0)

	var mgr = TrafficManager.new()
	mgr.setup_traffic(road_net, player, 8)

	assert_true(mgr.traffic_pool.size() == 8, "TrafficManager must populate specified pool size (8) (found: %d)" % mgr.traffic_pool.size())
	assert_true(mgr.get_active_traffic_count() == 8, "All 8 pooled vehicles must be active")

	# Move player far away to trigger recycling
	player.position = Vector3(1000.0, 0, 1000.0)
	mgr._physics_process(0.1)

	# Verify pool is still intact and managed
	assert_true(mgr.traffic_pool.size() == 8, "Pool size must remain constant during recycling")

	mgr.clear_all_traffic()
	assert_true(mgr.traffic_pool.is_empty(), "clear_all_traffic must empty pool")

	mgr.free()
	player.free()
	# Note: road_net is RefCounted, automatically cleaned up when out of scope

func test_weather_system_time_and_presets() -> void:
	var weather = UrbanWeatherSystem.new()
	weather._ready()

	assert_true(weather.sun_light != null, "Celestial sun light must be created")
	assert_true(weather.world_environment != null, "WorldEnvironment must be created")

	# Apply Golden Sunset preset
	weather.apply_preset(UrbanConstants.WEATHER_GOLDEN_SUNSET)
	assert_true(weather.current_preset == UrbanConstants.WEATHER_GOLDEN_SUNSET, "Weather preset should be golden_sunset")
	assert_true(weather.current_time_hours >= 17.0 and weather.current_time_hours <= 19.5, "Golden hour time must be between 17:00 and 19:30 (was: %f)" % weather.current_time_hours)
	assert_true(not weather.is_night(), "Golden sunset should not be classified as night")

	# Apply Neon Night preset
	weather.apply_preset(UrbanConstants.WEATHER_NEON_NIGHT)
	assert_true(weather.is_night(), "Neon night preset must report is_night = true")
	assert_true(weather.sun_light.light_energy < 0.1, "Sun light energy must be attenuated at night")

	# Set manual time to 12.0 (Noon)
	weather.set_time(12.0)
	assert_true(absf(weather.current_time_hours - 12.0) < 0.01, "set_time must set current_time_hours")
	assert_true(not weather.is_night(), "Noon is not night")

	weather.free()

func test_weather_system_clock_formatting() -> void:
	var weather = UrbanWeatherSystem.new()
	weather._ready()

	weather.set_time(17.5) # 17:30
	var clock_str = weather.get_formatted_clock()
	assert_true(clock_str == "17:30", "17.5 hours must format as 17:30 (was: %s)" % clock_str)

	weather.set_time(8.25) # 08:15
	assert_true(weather.get_formatted_clock() == "08:15", "8.25 hours must format as 08:15 (was: %s)" % weather.get_formatted_clock())

	assert_true(weather.get_wetness_factor() >= 0.0 and weather.get_wetness_factor() <= 1.0, "Wetness factor must be in [0, 1]")

	weather.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/traffic/traffic_vehicle.gd", [
			"_ready", "set_waypoints", "_physics_process", "reset_traffic_state"
		]],
		["res://games/urban-legends/traffic/traffic_manager.gd", [
			"_ready", "setup_traffic", "_physics_process", "get_active_traffic_count", "clear_all_traffic"
		]],
		["res://games/urban-legends/world/urban_weather_system.gd", [
			"_init", "_ready", "_physics_process", "apply_preset", "set_time", "get_formatted_clock",
			"get_wetness_factor", "is_night"
		]],
		["res://games/urban-legends/traffic/traffic_vehicle_builder.gd", [
			"get_tire_material", "get_rim_material", "get_headlight_material",
			"get_taillight_material", "build_traffic_vehicle_visual"
		]]
	]
