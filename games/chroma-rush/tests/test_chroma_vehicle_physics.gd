class_name TestChromaVehiclePhysics
extends RefCounted

## Unit tests for Chroma Rush vehicle physics, catalog stats, drifting, and recovery

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const VehicleCatalog = preload("res://games/chroma-rush/vehicles/vehicle_catalog.gd")
const VehicleVisuals = preload("res://games/chroma-rush/vehicles/vehicle_visuals.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_all_six_vehicles_catalog_stats()
	test_vehicle_instantiation_and_visuals()
	test_acceleration_and_top_speed()
	test_braking_and_reverse()
	test_steering_and_cornering()
	test_drift_mechanic_and_boost()
	test_rollover_safe_recovery()
	test_color_sync_and_visual_update()
	test_speed_derivation_and_physical_telemetry()
	test_full_body_car_paint_materials()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaVehiclePhysics FAIL] " + msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaVehiclePhysics FAIL] %s (Expected %s, got %s)" % [msg, str(b), str(a)])

func test_all_six_vehicles_catalog_stats() -> void:
	var ids = VehicleCatalog.get_all_vehicle_ids()
	assert_eq(ids.size(), 6, "Must provide exactly 6 distinct vehicle archetypes")

	var apex = VehicleCatalog.get_vehicle_definition(ChromaConstants.VEHICLE_APEX)
	var vortex = VehicleCatalog.get_vehicle_definition(ChromaConstants.VEHICLE_VORTEX)
	var titan = VehicleCatalog.get_vehicle_definition(ChromaConstants.VEHICLE_TITAN)
	var pulse = VehicleCatalog.get_vehicle_definition(ChromaConstants.VEHICLE_PULSE)
	var dune = VehicleCatalog.get_vehicle_definition(ChromaConstants.VEHICLE_DUNE)
	var quantum = VehicleCatalog.get_vehicle_definition(ChromaConstants.VEHICLE_QUANTUM)

	assert_true(apex["top_speed"] > vortex["top_speed"], "Apex should have higher top speed than Vortex")
	assert_true(titan["mass"] > vortex["mass"], "Titan must have heavier chassis than Vortex")
	assert_true(pulse["acceleration"] > dune["acceleration"], "Pulse electric accel must exceed Dune Nomad")
	assert_true(vortex["drift_factor"] > titan["drift_factor"], "Vortex drift factor must exceed Titan")
	assert_true(quantum["top_speed"] >= 40.0, "Quantum Phantom must be highest speed class")

func test_vehicle_instantiation_and_visuals() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_VORTEX
	v.initial_color = ChromaConstants.ChromaColor.EMERALD
	v._ready()

	assert_true(v.visual_node != null, "Vehicle visual node must be created")
	assert_eq(v.visual_node.position.y, 0.0, "Visual node must align at y=0 to seat tires on road without submerging")
	assert_eq(v.current_color, ChromaConstants.ChromaColor.EMERALD, "Initial color must be set")
	assert_true(v.wheel_raycasts.size() == 4, "Must have 4 suspension raycasts")

	# Verify curb-clearing collision box (DEF-03)
	var col = v.get_node_or_null("ChromaCollision") as CollisionShape3D
	assert_true(col != null, "ChromaCollision shape must exist")
	if col and col.shape is BoxShape3D:
		var box = col.shape as BoxShape3D
		var clearance = col.position.y - box.size.y * 0.5
		assert_true(clearance >= 0.15, "Chassis bottom must maintain at least 15cm curb clearance")

	# Verify 180° rotation of model root so front faces -Z forward (DEF-05)
	var model_root = v.visual_node.get_node_or_null("ModelRoot")
	if model_root:
		assert_true(absf(model_root.rotation.y - PI) < 0.01, "ModelRoot must be rotated PI radians to face forward -Z")

	v.free()

func test_acceleration_and_top_speed() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_APEX
	v._ready()

	v.set_inputs(0.0, 1.0, 0.0, false, false) # Full throttle
	for i in range(30):
		v._update_physics_movement(0.1)

	assert_true(v.forward_speed > 15.0, "Vehicle must accelerate forward under throttle")
	assert_true(v.forward_speed <= v.top_speed + 0.1, "Vehicle forward speed must cap at top speed")

	v.free()

func test_braking_and_reverse() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_APEX
	v._ready()
	v.forward_speed = 25.0

	# Apply full brake
	v.set_inputs(0.0, 0.0, 1.0, false, false)
	for i in range(10):
		v._update_physics_movement(0.1)

	assert_true(v.forward_speed < 10.0, "Brakes must decelerate vehicle rapidly")

	# Continue braking from stop to reverse
	v.forward_speed = 0.0
	for i in range(15):
		v._update_physics_movement(0.1)

	assert_true(v.forward_speed < 0.0, "Holding brake at rest must engage reverse")
	assert_true(v.forward_speed >= -12.1, "Reverse must be speed capped")

	v.free()

func test_steering_and_cornering() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_PULSE
	v._ready()
	v.forward_speed = 20.0

	var rot_before = v.rotation.y
	v.set_inputs(1.0, 1.0, 0.0, false, false) # Steer right
	v._update_physics_movement(0.2)

	assert_true(v.rotation.y != rot_before, "Steering input must rotate vehicle yaw")

	v.free()

func test_drift_mechanic_and_boost() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_VORTEX
	v._ready()
	v.forward_speed = 22.0

	# Initiate drift with handbrake + steer
	v.set_inputs(0.8, 1.0, 0.0, true, false)
	assert_true(v.is_drifting, "Vehicle must enter drift state")
	assert_eq(v.drift_direction, 1.0, "Drift direction must match steer sign")

	# Hold drift for 1.2s to accumulate charge
	for i in range(12):
		v._update_physics_movement(0.1)
	assert_true(v.drift_charge >= 0.9, "Drift charge must accumulate over time")

	# Release drift
	var boost_res = {"received": false, "level": 0}
	v.drift_boost_released.connect(func(lvl):
		boost_res["received"] = true
		boost_res["level"] = lvl
	)

	v.set_inputs(0.0, 1.0, 0.0, false, false) # Release handbrake
	assert_false(v.is_drifting, "Vehicle must exit drift state")
	assert_true(boost_res["received"], "Drift release signal must be fired")
	assert_true(boost_res["level"] >= 1, "Must grant at least level 1 boost")
	assert_true(v.boost_time_left > 0.0, "Nitro boost must be active")

	v.free()

func test_rollover_safe_recovery() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_TITAN
	v._ready()
	v.last_valid_track_pos = Vector3(10, 0, 10)
	v.last_valid_track_rot = 0.5

	# Simulate vehicle overturned upside-down (up vector inverted)
	v.rotation_degrees = Vector3(180, 0, 0)
	var t_down = v.global_transform if v.is_inside_tree() else v.transform
	assert_true(t_down.basis.y.dot(Vector3.UP) < 0.25, "Vehicle is upside down")

	var rec_res = {"recovered": false}
	v.vehicle_recovered.connect(func(pos): rec_res["recovered"] = true)

	# Simulate 0.8s elapsed in inverted state
	v._check_rollover_and_recovery(0.8)
	assert_true(rec_res["recovered"], "Vehicle must automatically recover from prolonged rollover")
	var t_up = v.global_transform if v.is_inside_tree() else v.transform
	assert_true(t_up.basis.y.dot(Vector3.UP) > 0.9, "Vehicle must be right-side up after recovery")

	v.free()

func test_color_sync_and_visual_update() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_QUANTUM
	v.initial_color = ChromaConstants.ChromaColor.CYAN
	v._ready()

	assert_eq(v.current_color, ChromaConstants.ChromaColor.CYAN, "Initial color is cyan")

	var color_res = {"emitted": false}
	v.color_changed.connect(func(new_c): color_res["emitted"] = true)

	v.set_color(ChromaConstants.ChromaColor.MAGENTA)
	assert_true(color_res["emitted"], "color_changed signal emitted")
	assert_eq(v.current_color, ChromaConstants.ChromaColor.MAGENTA, "Current color updated to magenta")

	# Check accessibility symbol label updated
	var sym_label = v.visual_node.get_node_or_null("AccessibilitySymbol") as Label3D
	assert_true(sym_label != null, "Symbol billboard exists")
	assert_eq(sym_label.text, ChromaConstants.get_color_symbol(ChromaConstants.ChromaColor.MAGENTA), "Symbol matches magenta")

	v.free()

func test_speed_derivation_and_physical_telemetry() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_APEX
	v._ready()

	# At rest
	v.forward_speed = 0.0
	assert_eq(int(v.get_speed_kmh()), 0, "Rest speed must be 0 km/h")

	# With forward speed
	v.forward_speed = 20.0
	assert_eq(int(v.get_speed_kmh()), 72, "20 m/s must report 72 km/h")

	# Test ground clearance: collision box center must sit at Y >= 0.50m
	var col_shape = v.get_node_or_null("ChromaCollision") as CollisionShape3D
	assert_true(col_shape != null, "ChromaCollision shape must exist")
	assert_true(col_shape.position.y >= 0.50, "Collision box must be elevated >= 0.50m for clearance over curbs")

	v.free()

func test_full_body_car_paint_materials() -> void:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_APEX
	v.paint_finish = "metallic"
	v.initial_color = ChromaConstants.ChromaColor.CRIMSON
	v._ready()

	# Verify visual node has body paint nodes in ChassisBody
	assert_true(v.visual_node != null, "Visual node exists")
	var chassis = v.visual_node.get_node_or_null("ChassisBody")
	assert_true(chassis != null, "ChassisBody exists")
	var paint_boxes: Array[MeshInstance3D] = []
	for child in chassis.get_children():
		if child is MeshInstance3D and child.get_meta("is_body_paint", false):
			paint_boxes.append(child)

	assert_true(paint_boxes.size() >= 3, "Vehicle must have full-bodied paint panels (hood, roof, doors, rear)")

	# Verify paint material is applied with crimson color
	var first_mat = paint_boxes[0].material_override as StandardMaterial3D
	assert_true(first_mat != null, "Paint material override must exist")
	var crimson_val = ChromaConstants.get_color_value(ChromaConstants.ChromaColor.CRIMSON)
	assert_true(first_mat.albedo_color.is_equal_approx(crimson_val), "Paint panel must match authoritative Crimson Red")
	assert_true(first_mat.metallic >= 0.5, "Metallic finish must have metallic >= 0.5")

	v.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/vehicles/vehicle_catalog.gd", [
			"get_vehicle_definition", "get_all_vehicle_ids"
		]],
		["res://games/chroma-rush/vehicles/vehicle_visuals.gd", [
			"build_vehicle_visual", "apply_gameplay_color"
		]],
		["res://games/chroma-rush/vehicles/chroma_vehicle.gd", [
			"_ready", "_physics_process", "apply_catalog_stats", "setup_visuals",
			"setup_collision_box", "setup_suspension_rays", "set_inputs",
			"recover_vehicle", "trigger_nitro_boost", "set_color", "set_vehicle_type",
			"get_speed_kmh"
		]]
	]
