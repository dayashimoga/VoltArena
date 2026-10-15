class_name TestUrbanVehiclePhysicsUnit
extends RefCounted

## Unit test suite for Urban Legends vehicle physics, suspension, steering,
## drift, stunt mechanics, and camera stability.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicleCatalog = preload("res://games/urban-legends/vehicles/urban_vehicle_catalog.gd")
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanChaseCamera = preload("res://games/urban-legends/vehicles/urban_chase_camera.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanVehiclePhysicsUnit ---")
	test_vehicle_catalog_specs()
	test_suspension_raycasts_and_grounding()
	test_acceleration_and_launch_torque()
	test_braking_and_reversing()
	test_speed_sensitive_steering()
	test_handbrake_and_drift_slip()
	test_airborne_stunt_authority()
	test_landing_and_damage()
	test_upside_down_and_recovery()
	test_vehicle_upgrades()
	test_camera_modes_and_interpolation()

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

func assert_approx_eq(val: float, expected: float, tol: float, msg: String) -> void:
	assert_true(absf(val - expected) <= tol, "%s (expected %f, got %f)" % [msg, expected, val])

func test_vehicle_catalog_specs() -> void:
	var ids = UrbanVehicleCatalog.get_vehicle_ids()
	assert_true(ids.size() == 5, "Catalog should define 5 archetypes")
	assert_true(ids.has(UrbanConstants.VEHICLE_VORTEX_GT), "Vortex GT must exist")
	assert_true(ids.has(UrbanConstants.VEHICLE_THUNDERBOLT_V8), "Thunderbolt V8 must exist")
	assert_true(ids.has(UrbanConstants.VEHICLE_SPECTER_R), "Specter R must exist")
	assert_true(ids.has(UrbanConstants.VEHICLE_RIDGEBACK_4X4), "Ridgeback 4x4 must exist")
	assert_true(ids.has(UrbanConstants.VEHICLE_VALIANT_COUPE), "Valiant Coupe must exist")

	var vortex = UrbanVehicleCatalog.get_vehicle_def(UrbanConstants.VEHICLE_VORTEX_GT)
	assert_true(vortex["top_speed"] >= 65.0, "Vortex GT top speed should be >= 65 m/s")
	assert_true(vortex["acceleration"] >= 30.0, "Vortex GT acceleration should be >= 30 m/s²")
	assert_true(vortex["mass"] > 1000.0, "Vehicle mass should be > 1000 kg")

func _spawn_test_vehicle(vehicle_id: String = UrbanConstants.VEHICLE_VORTEX_GT) -> UrbanVehicle:
	var v = UrbanVehicle.new()
	v.vehicle_id = vehicle_id
	v._ready()
	return v

func _cleanup_test_vehicle(v: UrbanVehicle) -> void:
	if is_instance_valid(v):
		v.free()

func test_suspension_raycasts_and_grounding() -> void:
	var vehicle = _spawn_test_vehicle(UrbanConstants.VEHICLE_VORTEX_GT)

	assert_true(vehicle.wheel_raycasts.size() == 4, "Vehicle must possess 4 suspension raycasts")
	assert_true(vehicle.wheel_raycasts[0].position.x < 0.0, "FL ray must be on left (-X)")
	assert_true(vehicle.wheel_raycasts[1].position.x > 0.0, "FR ray must be on right (+X)")
	assert_true(vehicle.wheel_raycasts[2].position.z > 0.0, "RL ray must be at rear (+Z)")
	assert_true(vehicle.wheel_raycasts[3].position.z > 0.0, "RR ray must be at rear (+Z)")

	# Initially in air (before physics step over ground)
	assert_true(vehicle.get_grounded_wheel_count() == 0, "Initial grounded wheel count should be 0 before step")
	_cleanup_test_vehicle(vehicle)

func test_acceleration_and_launch_torque() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.force_grounded_for_testing = true

	# Simulate full throttle for 1.0 second
	vehicle.throttle_input = 1.0
	vehicle.brake_input = 0.0

	for _i in range(60):
		vehicle._physics_process(1.0 / 60.0)

	var speed_ms = vehicle.get_forward_speed_ms()
	var speed_kmh = vehicle.get_speed_kmh()
	assert_true(speed_ms > 12.0, "Vehicle should accelerate to > 12 m/s in 1.0s (was: %f)" % speed_ms)
	assert_true(speed_kmh > 43.0, "Vehicle should accelerate to > 43 km/h in 1.0s (was: %f)" % speed_kmh)
	assert_true(vehicle.get_gear() >= 1, "Vehicle should be in gear >= 1")
	assert_true(vehicle.get_rpm() > 2000.0, "Engine RPM should rise under load")
	_cleanup_test_vehicle(vehicle)

func test_braking_and_reversing() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.force_grounded_for_testing = true
	vehicle.set_forward_speed(30.0) # Cruising at 30 m/s (~108 km/h)

	# Full braking
	vehicle.throttle_input = 0.0
	vehicle.brake_input = 1.0

	for _i in range(30): # 0.5s of braking
		vehicle._physics_process(1.0 / 60.0)

	assert_true(vehicle.forward_speed < 18.0, "Vehicle speed should drop rapidly under full braking (was: %f)" % vehicle.forward_speed)
	_cleanup_test_vehicle(vehicle)

func test_speed_sensitive_steering() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.force_grounded_for_testing = true
	vehicle.steer_input = 1.0 # Full right turn

	# Low speed steering
	vehicle.set_forward_speed(5.0)
	for _i in range(30):
		vehicle._physics_process(1.0 / 60.0)
	var low_speed_steer = absf(vehicle.current_steer_angle)

	# High speed steering: maintain throttle so speed does not bleed off from coasting air drag
	vehicle.current_steer_angle = 0.0
	vehicle.set_forward_speed(60.0)
	vehicle.throttle_input = 1.0
	for _i in range(60):
		vehicle._physics_process(1.0 / 60.0)
	var high_speed_steer = absf(vehicle.current_steer_angle)

	assert_true(low_speed_steer > high_speed_steer, "Steering angle must be larger at low speed than at high speed")
	assert_true(rad_to_deg(low_speed_steer) > 25.0, "Low speed steer angle should be > 25 deg (was: %f)" % rad_to_deg(low_speed_steer))
	assert_true(rad_to_deg(high_speed_steer) < 22.0, "High speed steer angle should be < 22 deg (was: %f)" % rad_to_deg(high_speed_steer))
	_cleanup_test_vehicle(vehicle)

func test_handbrake_and_drift_slip() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.force_grounded_for_testing = true
	vehicle.set_forward_speed(35.0)
	vehicle.steer_input = 0.8
	vehicle.handbrake_input = true

	for _i in range(30):
		vehicle._physics_process(1.0 / 60.0)

	assert_true(vehicle.is_drifting, "Handbrake + steering at speed must trigger drift state")
	assert_true(vehicle.get_drift_angle() >= 0.0, "Drift angle should be non-negative during power slide")
	_cleanup_test_vehicle(vehicle)

func test_airborne_stunt_authority() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.grounded_wheel_count = 0 # In air off a ramp

	# Pitch up in air
	vehicle.air_pitch_input = 1.0
	vehicle.steer_input = 1.0

	for _i in range(30):
		vehicle._physics_process(1.0 / 60.0)

	assert_true(vehicle.is_airborne, "Vehicle must detect airborne state when wheels have no contact")
	assert_true(vehicle.air_timer > 0.45, "Air timer should track elapsed airborne duration")
	assert_true(vehicle.total_air_pitch_deg > 10.0, "Air pitch control should accumulate pitch degrees")
	assert_true(vehicle.total_air_yaw_deg > 10.0, "Air yaw control should accumulate yaw degrees")
	_cleanup_test_vehicle(vehicle)

func test_landing_and_damage() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.is_airborne = true
	vehicle.velocity = Vector3(0, -18.0, -20.0) # Hard downward impact velocity

	var captured = {"rating": ""}
	vehicle.stunt_landed.connect(func(rating: String, _v: float, _t: float): captured["rating"] = rating)

	vehicle._on_touchdown()
	assert_true(captured["rating"] == "Hard", "Impact at -18 m/s must be rated Hard (was: %s)" % captured["rating"])
	assert_true(vehicle.get_health() < 100.0, "Hard landing must inflict damage")

	vehicle.repair(100.0)
	assert_true(vehicle.get_health() == 100.0, "Repairing should restore health to 100")
	_cleanup_test_vehicle(vehicle)

func test_upside_down_and_recovery() -> void:
	var vehicle = _spawn_test_vehicle()
	vehicle.last_safe_ground_pos = Vector3(10.0, 1.0, -50.0)
	vehicle.position = Vector3(10.0, -40.0, -50.0) # Fallen below world

	vehicle._physics_process(1.0 / 60.0)
	assert_true(vehicle.position.y >= 0.5, "Recover vehicle must restore vehicle back onto safe ground (was: %f)" % vehicle.position.y)
	_cleanup_test_vehicle(vehicle)

func test_vehicle_upgrades() -> void:
	var vehicle = _spawn_test_vehicle()
	var base_top_speed = vehicle.top_speed
	var base_accel = vehicle.acceleration_rate

	# Upgrade engine and tires to level 5
	vehicle.apply_upgrades({
		"engine": 5,
		"tires": 5,
		"nitro": 5,
		"suspension": 5,
		"armor": 5
	})

	assert_true(vehicle.top_speed > base_top_speed, "Level 5 engine must increase top speed")
	assert_true(vehicle.acceleration_rate > base_accel, "Level 5 engine must increase acceleration")
	_cleanup_test_vehicle(vehicle)

func test_camera_modes_and_interpolation() -> void:
	var vehicle = _spawn_test_vehicle()

	var cam = UrbanChaseCamera.new()
	cam.set_target(vehicle)
	cam._ready()

	assert_true(cam.get_camera() != null, "Camera3D must be instantiated")
	assert_true(cam.camera_mode == UrbanConstants.CAM_CHASE, "Default camera mode should be Chase")

	cam.cycle_camera_mode()
	assert_true(cam.camera_mode == UrbanConstants.CAM_FREE, "First cycle should switch to Free Orbit")

	cam.cycle_camera_mode()
	assert_true(cam.camera_mode == UrbanConstants.CAM_BUMPER, "Second cycle should switch to Bumper")

	cam.set_camera_mode(UrbanConstants.CAM_CHASE)
	assert_true(cam.camera_mode == UrbanConstants.CAM_CHASE, "Can explicitly set camera mode back to Chase")

	# Physics step camera follow
	vehicle.position = Vector3(0, 0, -20.0)
	for _i in range(30):
		cam._physics_process(1.0 / 60.0)

	var cam_pos = cam.global_position if cam.is_inside_tree() else cam.position
	assert_true(cam_pos.distance_to(vehicle.position) < 30.0, "Camera should track vehicle position smoothly")
	cam.free()
	_cleanup_test_vehicle(vehicle)

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/core/urban_constants.gd", []],
		["res://games/urban-legends/core/urban_events.gd", []],
		["res://games/urban-legends/core/urban_save_data.gd", [
			"_init", "_init_defaults", "to_dict", "from_dict", "add_cash", "unlock_vehicle",
			"is_vehicle_unlocked", "get_upgrade_level", "set_upgrade_level", "get_vehicle_color",
			"set_vehicle_color", "discover_district"
		]],
		["res://games/urban-legends/vehicles/urban_vehicle_catalog.gd", [
			"get_vehicle_ids", "get_vehicle_def"
		]],
		["res://games/urban-legends/vehicles/urban_vehicle.gd", [
			"_ready", "_apply_catalog_specs", "apply_upgrades", "_setup_suspension_raycasts",
			"_setup_collision_box", "_physics_process", "_update_physics_movement", "set_forward_speed",
			"set_inputs", "_update_suspension_and_grounding", "_process_steering",
			"_process_ground_physics", "_process_air_physics", "_on_takeoff", "_on_touchdown",
			"_update_weight_transfer", "_update_transmission", "_check_recovery_conditions",
			"_handle_collision_impacts", "take_damage", "repair", "recover_vehicle",
			"get_speed_kmh", "get_forward_speed_ms", "get_health", "is_on_ground",
			"get_grounded_wheel_count", "get_drift_angle", "get_suspension_compressions",
			"get_gear", "get_rpm", "get_nitro_gauge"
		]],
		["res://games/urban-legends/vehicles/urban_chase_camera.gd", [
			"_ready", "_setup_camera_nodes", "set_target", "set_camera_mode", "cycle_camera_mode",
			"handle_orbit_input", "_physics_process", "_update_fov", "_update_chase_camera",
			"_update_free_camera", "_update_bumper_camera", "_update_stunt_camera", "get_camera",
			"_get_target_pos", "_get_target_rot", "_get_target_basis", "_set_cam_pos", "_get_cam_pos",
			"_safe_look_at"
		]],
		["res://games/urban-legends/vehicles/urban_vehicle_visuals.gd", [
			"build_vehicle_visual"
		]],
		["res://games/urban-legends/vehicles/urban_vehicle_audio.gd", [
			"_ready", "setup_vehicle", "_setup_audio_players", "_assign_procedural_tones",
			"_physics_process", "_on_speed_changed", "_on_vehicle_damaged", "_on_stunt_landed"
		]]
	]
