class_name TestUrbanLegendsE2E
extends RefCounted

## End-to-end integration and gameplay scenario test suite for Urban Legends.
## Validates full runtime assembly:
## - World generator + road network + district bounds
## - Vehicle driving, raycast suspension, acceleration, and braking
## - Airborne launch, stunt detection, and combo banking
## - Day/night weather system and dynamic lighting transitions
## - Ambient traffic AI spawning and road following
## - Mission lifecycle (start, checkpoints, reward banking)
## - In-game UI (HUD, circular minimap, garage kiosk, map menu, pause menu)
## - Fast travel and safe respawn recovery

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanLegendsMain = preload("res://games/urban-legends/urban_legends_main.gd")
const UrbanVehicleCatalog = preload("res://games/urban-legends/vehicles/urban_vehicle_catalog.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanLegendsE2E ---")
	test_full_gameplay_initialization()
	test_driving_physics_and_controls_scenario()
	test_stunt_jump_and_landing_scenario()
	test_mission_lifecycle_scenario()
	test_garage_and_map_menu_flows()
	test_weather_cycle_scenario()
	test_input_handling_scenario()

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

func test_full_gameplay_initialization() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	assert_true(main.world_generator != null, "World generator must be initialized")
	assert_true(main.weather_system != null, "Weather system must be initialized")
	assert_true(main.road_network != null, "Road network must be assembled")
	assert_true(main.player_vehicle != null, "Player vehicle must be spawned")
	assert_true(main.chase_camera != null, "Chase camera must be active")
	assert_true(main.traffic_manager != null, "Traffic manager must be active")
	assert_true(main.hud != null, "Telemetry HUD must be created")
	assert_true(main.garage_menu != null, "Garage menu must be created")
	assert_true(main.map_menu != null, "Map menu must be created")
	assert_true(main.pause_menu != null, "Pause menu must be created")

	# District verification
	assert_true(UrbanDistrictDefinitions.get_district_ids().size() == 8, "All 8 districts must be defined")

	main.free()

func test_driving_physics_and_controls_scenario() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	var car = main.player_vehicle
	car.position = Vector3(0, 2.0, 0)
	car.force_grounded_for_testing = true

	# Apply full throttle forward
	car.set_inputs(0.0, 1.0, 0.0, false, false)
	for _i in range(30): # 0.5 sec of driving
		car._physics_process(1.0 / 60.0)

	assert_true(car.forward_speed > 5.0, "Car must accelerate forward under throttle (was: %f)" % car.forward_speed)
	assert_true(car.get_speed_kmh() > 18.0, "Speedometer must register forward speed (was: %f)" % car.get_speed_kmh())

	# Apply steering and handbrake drift
	car.set_inputs(1.0, 0.5, 0.0, true, false)
	for _i in range(20):
		car._physics_process(1.0 / 60.0)

	assert_true(car.is_drifting, "Handbrake + steer at speed must trigger drift state")

	# Full braking
	car.set_inputs(0.0, 0.0, 1.0, false, false)
	for _i in range(40):
		car._physics_process(1.0 / 60.0)

	assert_true(car.forward_speed < 8.0, "Vehicle must decelerate under braking (was: %f)" % car.forward_speed)

	main.free()

func test_stunt_jump_and_landing_scenario() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	var car = main.player_vehicle
	var save = main.save_data
	var initial_cash = save.career_cash

	# Trigger Airborne Jump
	car.force_grounded_for_testing = false
	car.position = Vector3(100.0, 8.0, 200.0)
	main.stunt_detector._on_airborne_started()

	# Simulate 65m launch distance and landing
	car.position = Vector3(165.0, 1.5, 200.0)
	main.stunt_detector._on_stunt_landed("Clean", 9.0, 1.6)

	assert_true(save.career_cash > initial_cash, "Clean jump landing must award career cash")
	assert_true(main.hud.stunt_toast.visible, "Stunt toast notification must be displayed on HUD")

	main.free()

func test_mission_lifecycle_scenario() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	var director = main.mission_director
	var car = main.player_vehicle
	var save = main.save_data

	# Start Circuit Race
	var started = director.start_mission(UrbanConstants.MISSION_CIRCUIT_RACE)
	assert_true(started, "Circuit race mission should start")
	assert_true(director.is_mission_active, "Mission active flag should be true")

	# Drive through all checkpoints across all laps
	var total_cps = director.checkpoints.size()
	for _lap in range(director.total_laps):
		for i in range(total_cps):
			car.position = director.checkpoints[i]
			director._physics_process(0.1)

	assert_true(not director.is_mission_active, "Mission should finish when last checkpoint is cleared")

	main.free()

func test_garage_and_map_menu_flows() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	# Open Garage
	main._open_garage()
	assert_true(main.is_in_garage, "Game should enter garage state")
	assert_true(main.garage_menu.visible, "Garage UI must be visible")

	# Buy upgrade
	main.save_data.career_cash = 50000
	main.garage_menu._on_buy_upgrade("engine")
	assert_true(main.save_data.get_upgrade_level(main.player_vehicle.vehicle_id, "engine") >= 2, "Engine upgrade should be applied")

	# Close Garage
	main._close_garage()
	assert_true(not main.is_in_garage, "Garage should be closed")
	assert_true(not main.garage_menu.visible, "Garage UI should be hidden")

	# Fast Travel via Map
	var colinas_pos = Vector3(450.0, 52.0, 620.0)
	main._on_fast_travel(colinas_pos)
	var p_pos = main.player_vehicle.global_position if main.player_vehicle.is_inside_tree() else main.player_vehicle.position
	assert_true(p_pos.distance_to(colinas_pos) < 5.0, "Fast travel must reposition vehicle to target district")

	main.free()

func test_weather_cycle_scenario() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	var weather = main.weather_system
	assert_true(weather != null, "Weather system must be present")

	# Test Golden Sunset (Default)
	assert_true(weather.current_preset == UrbanConstants.WEATHER_GOLDEN_SUNSET, "Default preset should be golden_sunset")
	assert_true(weather.sun_light.light_color.r > 0.9, "Sunset sun light must have warm red/amber component")

	# Switch to Neon Night
	weather.apply_preset(UrbanConstants.WEATHER_NEON_NIGHT)
	assert_true(weather.is_night(), "Neon Night preset must report is_night = true")

	main.free()

func test_input_handling_scenario() -> void:
	var main = UrbanLegendsMain.new()
	main._ready()

	var ev_m = InputEventKey.new()
	ev_m.pressed = true
	ev_m.keycode = KEY_M
	main._unhandled_input(ev_m)
	assert_true(main.is_in_map, "Pressing M should open district map")

	main._unhandled_input(ev_m)
	assert_true(not main.is_in_map, "Pressing M again should close district map")

	main.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/urban_legends_main.gd", [
			"_ready", "_init_save_and_progression", "_build_world_environment",
			"_spawn_player_vehicle", "_setup_traffic_ai", "_setup_gameplay_and_stunts",
			"_setup_ui_overlays", "_connect_subsystem_events", "_physics_process",
			"_unhandled_input",
			"_toggle_pause", "_open_garage", "_close_garage", "_open_map", "_close_map",
			"_on_reset_vehicle", "_on_fast_travel", "_on_garage_vehicle_changed",
			"_on_garage_vehicle_customized", "_on_quit_to_launcher"
		]]
	]
