class_name TestUrbanCameraAndHUDUnit
extends RefCounted

## Unit tests for Urban Legends chase camera modes, telemetry HUD,
## circular minimap, garage kiosk, district map, and pause menu.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanChaseCamera = preload("res://games/urban-legends/vehicles/urban_chase_camera.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const ProgressionManager = preload("res://games/urban-legends/gameplay/progression_manager.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const UrbanWeatherSystem = preload("res://games/urban-legends/world/urban_weather_system.gd")

const UrbanHUD = preload("res://games/urban-legends/ui/urban_hud.gd")
const UrbanGarageMenu = preload("res://games/urban-legends/ui/urban_garage_menu.gd")
const UrbanMapMenu = preload("res://games/urban-legends/ui/urban_map_menu.gd")
const UrbanPauseMenu = preload("res://games/urban-legends/ui/urban_pause_menu.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanCameraAndHUDUnit ---")
	test_chase_camera_modes_and_orbit()
	test_hud_telemetry_and_banners()
	test_hud_minimap_rendering()
	test_garage_menu_interactions()
	test_map_menu_navigation_and_selection()
	test_pause_menu_signals()

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

func test_chase_camera_modes_and_orbit() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	car.position = Vector3(100, 2, 100)

	var cam = UrbanChaseCamera.new()
	cam._ready()
	cam.set_target(car)

	assert_true(cam.camera_mode == UrbanConstants.CAM_CHASE, "Initial camera mode must be CHASE")

	# Mode cycling: Chase (0) -> Free (1) -> Bumper (2) -> Chase (0)
	cam.cycle_camera_mode()
	assert_true(cam.camera_mode == UrbanConstants.CAM_FREE, "Next mode should be FREE")

	cam.cycle_camera_mode()
	assert_true(cam.camera_mode == UrbanConstants.CAM_BUMPER, "Next mode should be BUMPER")

	cam.cycle_camera_mode()
	assert_true(cam.camera_mode == UrbanConstants.CAM_CHASE, "Cycling back should return to CHASE")

	cam.set_camera_mode(UrbanConstants.CAM_STUNT)
	assert_true(cam.camera_mode == UrbanConstants.CAM_STUNT, "Setting camera mode to STUNT should succeed")

	# Orbit Input (delta_yaw: float, delta_pitch: float)
	cam.handle_orbit_input(0.35, -0.15)
	assert_true(cam.orbit_yaw != 0.0 or cam.orbit_pitch != 0.0, "Orbit input should change yaw/pitch angles")

	# Step physics
	cam._physics_process(0.016)
	assert_true(cam.get_camera() != null, "Internal Camera3D instance must exist")

	cam.free()
	car.free()

func test_hud_telemetry_and_banners() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	var hud = UrbanHUD.new()
	hud._ready()
	hud.setup(car)

	# Telemetry Updates
	car.forward_speed = 35.0 # ~126 km/h
	car.nitro_gauge = 0.85
	car.health = 92.0
	hud._update_telemetry(0.016)

	assert_true(hud.speed_label.text.contains("126"), "HUD speedometer should display 126 km/h (was: %s)" % hud.speed_label.text)
	assert_true(absf(hud.nitro_bar.value - 85.0) < 0.1, "Nitro gauge should reflect 85%% (was: %f)" % hud.nitro_bar.value)
	assert_true(hud.health_bar.value == 92.0, "Health gauge should reflect 92%% (was: %f)" % hud.health_bar.value)

	# District Banner
	hud.show_district_banner("Colinas Heights", 70.0)
	assert_true(hud.district_banner.visible, "District banner must be visible after transition")
	assert_true(hud.district_banner_label.text.contains("COLINAS HEIGHTS"), "Banner label should display district name")

	# Stunt Reward Toast
	hud.show_stunt_reward("MONSTER AIR", 500)
	assert_true(hud.stunt_toast.visible, "Stunt toast should become visible")
	assert_true(hud.stunt_title_label.text.contains("MONSTER AIR"), "Stunt title should be displayed")
	assert_true(hud.stunt_cash_label.text == "+$500", "Stunt cash toast should read +$500")

	# Wallet update
	hud.update_wallet(45000)
	assert_true(hud.cash_label.text.contains("45000"), "Wallet label must update to $45,000")

	hud.free()
	car.free()

func test_hud_minimap_rendering() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	car.position = Vector3(200, 0, -150)

	var road_net = UrbanRoadNetwork.new()
	var hud = UrbanHUD.new()
	hud._ready()
	hud.setup(car, road_net)

	assert_true(hud.minimap_draw != null, "Minimap canvas must be instantiated")
	assert_true(hud.minimap_draw.radar_radius > 50.0, "Minimap radar radius must be > 50px")

	# Coordinate transformation
	var screen_pt = hud.minimap_draw._world_to_minimap(Vector3(200, 0, -150), car.position, 0.0, Vector2(80, 80))
	assert_true(screen_pt.distance_to(Vector2(80, 80)) < 0.01, "Player world pos must project to minimap center")

	hud.free()
	car.free()

func test_garage_menu_interactions() -> void:
	var save = UrbanSaveData.new()
	save.career_cash = 60000
	var prog = ProgressionManager.new(save)

	var garage = UrbanGarageMenu.new()
	garage._ready()
	garage.setup(save, prog)

	assert_true(garage.current_vehicle_id == UrbanConstants.VEHICLE_VORTEX_GT, "Default garage car should be Vortex GT")

	# Next vehicle
	garage._on_next_vehicle()
	assert_true(garage.current_vehicle_id == UrbanConstants.VEHICLE_THUNDERBOLT_V8, "Next car should be Thunderbolt V8")

	# Select / Buy Vehicle
	garage._on_unlock_or_select_pressed()
	assert_true(save.is_vehicle_unlocked(UrbanConstants.VEHICLE_THUNDERBOLT_V8), "Thunderbolt V8 should now be unlocked")
	assert_true(save.current_vehicle_id == UrbanConstants.VEHICLE_THUNDERBOLT_V8, "Current active vehicle should be Thunderbolt V8")

	# Performance upgrade purchase
	var ok_upg = prog.buy_upgrade(UrbanConstants.VEHICLE_THUNDERBOLT_V8, "engine")
	assert_true(ok_upg, "Engine upgrade purchase should succeed")
	assert_true(save.get_upgrade_level(UrbanConstants.VEHICLE_THUNDERBOLT_V8, "engine") == 2, "Engine level should now be 2")

	# Paint color change
	garage._on_color_chosen(Color(0.85, 0.12, 0.15))
	assert_true(save.get_vehicle_color(UrbanConstants.VEHICLE_THUNDERBOLT_V8) == Color(0.85, 0.12, 0.15), "Vehicle color should update to crimson")

	garage.free()

func test_map_menu_navigation_and_selection() -> void:
	var save = UrbanSaveData.new()
	var map = UrbanMapMenu.new()
	map._ready()
	map.setup(save)

	# Select Colinas Heights
	map.select_district(UrbanConstants.DISTRICT_COLINAS)
	assert_true(map.selected_district_id == UrbanConstants.DISTRICT_COLINAS, "Selected district should be Colinas Heights")
	assert_true(map.district_name_lbl.text.contains("COLINAS HEIGHTS"), "District label should show COLINAS HEIGHTS")

	# Fast Travel Signal
	var fast_travel_called = {"triggered": false, "pos": Vector3.ZERO}
	map.fast_travel_requested.connect(func(dest: Vector3):
		fast_travel_called["triggered"] = true
		fast_travel_called["pos"] = dest
	)

	map._on_fast_travel_pressed()
	assert_true(fast_travel_called["triggered"], "Pressing fast travel must emit fast_travel_requested signal")
	assert_true(fast_travel_called["pos"] != Vector3.ZERO, "Fast travel target position must be non-zero")

	map.free()

func test_pause_menu_signals() -> void:
	var pause = UrbanPauseMenu.new()
	pause._ready()

	var resume_signal_hit = {"val": false}
	pause.resume_requested.connect(func(): resume_signal_hit["val"] = true)
	pause.btn_resume.emit_signal("pressed")
	assert_true(resume_signal_hit["val"], "Resume button press must emit resume_requested")

	var garage_signal_hit = {"val": false}
	pause.open_garage_requested.connect(func(): garage_signal_hit["val"] = true)
	pause.btn_garage.emit_signal("pressed")
	assert_true(garage_signal_hit["val"], "Garage button press must emit open_garage_requested")

	var map_signal_hit = {"val": false}
	pause.open_map_requested.connect(func(): map_signal_hit["val"] = true)
	pause.btn_map.emit_signal("pressed")
	assert_true(map_signal_hit["val"], "Map button press must emit open_map_requested")

	pause.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/vehicles/urban_chase_camera.gd", [
			"_ready", "set_target", "set_camera_mode", "cycle_camera_mode",
			"handle_orbit_input", "_physics_process", "get_camera"
		]],
		["res://games/urban-legends/ui/urban_hud.gd", [
			"_init", "_ready", "setup", "_setup_minimap", "_setup_progression_card",
			"_setup_speedometer_card", "_setup_district_banner", "_setup_stunt_toast",
			"_setup_touch_controls", "_process", "_update_telemetry",
			"show_district_banner", "show_stunt_reward", "update_wallet",
			"_update_responsive_layout"
		]],
		["res://games/urban-legends/ui/urban_garage_menu.gd", [
			"_init", "_ready", "setup", "_setup_ui", "_create_stat_row", "_setup_upgrade_track",
			"_refresh_display", "_on_prev_vehicle", "_on_next_vehicle",
			"_on_unlock_or_select_pressed", "_on_buy_upgrade", "_on_color_chosen",
			"_update_responsive_layout", "_unhandled_input"
		]],
		["res://games/urban-legends/ui/urban_map_menu.gd", [
			"_init", "_ready", "setup", "_setup_ui", "select_district", "_on_fast_travel_pressed",
			"_update_responsive_layout", "_unhandled_input"
		]],
		["res://games/urban-legends/ui/urban_pause_menu.gd", [
			"_init", "_ready", "_setup_ui", "_update_responsive_layout", "_unhandled_input"
		]]
	]
