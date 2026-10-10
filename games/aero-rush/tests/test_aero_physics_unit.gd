class_name TestAeroPhysicsUnit
extends RefCounted

## Unit test suite for AeroRush vehicle physics, 3D gravity alignment, and landing analysis.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroVehicleCatalog = preload("res://games/aero-rush/vehicles/aero_vehicle_catalog.gd")
const AeroVehicle = preload("res://games/aero-rush/vehicles/aero_vehicle.gd")
const AeroPhysicsHelpers = preload("res://games/aero-rush/vehicles/aero_physics_helpers.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [AeroRush] Running Vehicle Physics Unit Tests...")
	test_vehicle_catalog_specs()
	test_effective_gravity_flat()
	test_effective_gravity_loop_high_speed()
	test_effective_gravity_loop_low_speed()
	test_effective_gravity_wall_ride()
	test_landing_evaluation()
	test_vehicle_instantiation_and_collision()
	test_airborne_controls_and_leveling()
	test_checkpoint_recovery_transform()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL Aero Physics: " + msg)

func test_vehicle_catalog_specs() -> void:
	var defs = AeroVehicleCatalog.get_all_definitions()
	assert_true(defs.size() == 4, "Catalog must define exactly 4 fictional vehicles")

	for d in defs:
		var v_id = d.get("id", "")
		var spd = d.get("top_speed", 0.0) as float
		var accel = d.get("acceleration", 0.0) as float
		var mass = d.get("mass", 0.0) as float
		assert_true(not v_id.is_empty(), "Vehicle ID must not be empty")
		assert_true(spd >= 45.0 and spd <= 70.0, "Top speed must be between 45 and 70 m/s for %s" % v_id)
		assert_true(accel >= 30.0 and accel <= 45.0, "Acceleration must be between 30 and 45 m/s² for %s" % v_id)
		assert_true(mass >= 900.0 and mass <= 1600.0, "Mass must be realistic for %s" % v_id)

func test_effective_gravity_flat() -> void:
	# Flat track: normal points UP
	var g = AeroPhysicsHelpers.calculate_effective_gravity(Vector3.UP, 30.0, true, 28.0)
	assert_true(g.is_equal_approx(Vector3(0, -28.0, 0)), "Effective gravity on flat ground must be standard down")

func test_effective_gravity_loop_high_speed() -> void:
	# Top of 360 loop: normal points DOWN (ceiling), forward speed = 35 m/s
	var loop_norm = Vector3.DOWN
	var g = AeroPhysicsHelpers.calculate_effective_gravity(loop_norm, 35.0, true, 28.0)
	# Normal is DOWN, so -normal is UP, pulling the car onto the inverted ceiling
	assert_true(g.y > 20.0, "At high speed in loop apex, effective gravity must push car into ceiling (+Y)")

func test_effective_gravity_loop_low_speed() -> void:
	# Top of loop with insufficient speed (5 m/s < MIN_LOOP_SPEED 16 m/s): car falls down
	var loop_norm = Vector3.DOWN
	var g = AeroPhysicsHelpers.calculate_effective_gravity(loop_norm, 5.0, true, 28.0)
	assert_true(g.y < 0.0, "At low speed in loop apex, effective gravity must pull car downwards (-Y)")

func test_effective_gravity_wall_ride() -> void:
	# 90 degree vertical wall ride on the left: normal points RIGHT (Vector3(1, 0, 0))
	var wall_norm = Vector3.RIGHT
	var g = AeroPhysicsHelpers.calculate_effective_gravity(wall_norm, 40.0, true, 28.0)
	# Normal is RIGHT, so effective adhesion pulls car LEFT (-X) into the wall
	assert_true(g.x < -20.0, "On vertical wall at high speed, effective gravity must adhere car to wall (-X)")

func test_landing_evaluation() -> void:
	# 1. Perfectly aligned landing (0 deg angle)
	var perf = AeroPhysicsHelpers.evaluate_landing(Vector3.UP, Vector3.UP)
	assert_true(perf["quality"] == "perfect", "0 deg angle must be evaluated as perfect landing")
	assert_true(perf["boost_refill"] > 0.0, "Perfect landing must award boost refund")
	assert_true(not perf["is_crash"], "Perfect landing must not be crash")

	# 2. Clean landing (25 deg angle)
	var clean_up = Vector3(0.42, 0.90, 0.0).normalized()
	var clean = AeroPhysicsHelpers.evaluate_landing(clean_up, Vector3.UP)
	assert_true(clean["quality"] == "clean", "25 deg angle must be clean landing")

	# 3. Inverted crash (160 deg angle)
	var crash_up = Vector3.DOWN
	var crash = AeroPhysicsHelpers.evaluate_landing(crash_up, Vector3.UP)
	assert_true(crash["is_crash"], "Inverted landing must be classified as crash")

func test_vehicle_instantiation_and_collision() -> void:
	var veh = AeroVehicle.new()
	veh.vehicle_id = AeroConstants.VEHICLE_APEX
	veh._ready()

	assert_true(veh.collision_layer == AeroConstants.LAYER_PLAYER, "Player collision layer must be set")
	assert_true(veh.floor_snap_length >= 0.45, "Floor snap length must be >= 0.45m to eliminate seam snagging")
	assert_true(veh.wheel_raycasts.size() == 4, "Vehicle must have exactly 4 suspension raycasts")

	var col = veh.get_node_or_null("VehicleCollisionHull") as CollisionShape3D
	assert_true(col != null, "Vehicle must have collision hull")
	assert_true(col.shape is CapsuleShape3D, "Collision shape must be capsule to eliminate step snagging")

	veh.free()

func test_airborne_controls_and_leveling() -> void:
	var veh = AeroVehicle.new()
	veh.vehicle_id = AeroConstants.VEHICLE_QUANTUM
	veh._ready()

	veh.is_grounded = false
	veh.set_inputs(0.5, 1.0, 0.0, false, false) # Steer right, throttle up in air
	var init_rot = veh.rotation

	veh._process_airborne_movement(0.016)
	assert_true(veh.rotation != init_rot, "Airborne controls must rotate vehicle around pitch and yaw")

	veh.free()

func test_checkpoint_recovery_transform() -> void:
	var veh = AeroVehicle.new()
	veh._ready()

	var safe_pos = Vector3(50, 4, -120)
	var safe_basis = Basis.IDENTITY.rotated(Vector3.UP, deg_to_rad(45.0))
	veh.update_checkpoint(safe_pos, safe_basis)

	veh.recover_to_checkpoint()
	assert_true(veh.position.distance_to(safe_pos + Vector3(0, 1.2, 0)) < 0.1, "Recovery must place car at checkpoint height")
	assert_true(veh.forward_speed == 0.0, "Recovery must place car at rest with zero unintended acceleration")

	veh.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/aero-rush/vehicles/aero_vehicle.gd", [
			"_ready", "_apply_catalog_specs", "_setup_collision_shape", "_setup_suspension_raycasts",
			"_setup_visuals", "get_speed_kmh", "get_speed_mps", "set_inputs", "_physics_process",
			"_process_player_inputs", "_update_grounding_and_suspension", "_handle_touchdown",
			"_track_airborne_rotations", "_process_movement", "_process_ground_movement",
			"_process_airborne_movement", "_update_visual_dynamics", "_check_rollover_and_recovery",
			"update_checkpoint", "recover_to_checkpoint"
		]],
		["res://games/aero-rush/vehicles/aero_physics_helpers.gd", [
			"calculate_effective_gravity", "evaluate_landing", "align_basis_to_normal", "project_velocity_on_plane"
		]],
		["res://games/aero-rush/vehicles/aero_vehicle_catalog.gd", [
			"get_vehicle_definition", "get_all_definitions"
		]]
	]
