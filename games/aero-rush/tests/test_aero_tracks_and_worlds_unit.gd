class_name TestAeroTracksAndWorldsUnit
extends RefCounted

## Unit test suite for AeroRush continuous tracks, automated course validation,
## environment worlds, checkpoints, and kinetic hazard fields.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroCourseDatabase = preload("res://games/aero-rush/tracks/aero_course_database.gd")
const AeroTrackGenerator = preload("res://games/aero-rush/tracks/aero_track_generator.gd")
const AeroTrackValidator = preload("res://games/aero-rush/tracks/aero_track_validator.gd")
const AeroCheckpoint = preload("res://games/aero-rush/tracks/aero_checkpoint.gd")
const AeroMovingHazard = preload("res://games/aero-rush/tracks/aero_moving_hazard.gd")

const AeroWorldMegacity = preload("res://games/aero-rush/worlds/aero_world_megacity.gd")
const AeroWorldCanyon = preload("res://games/aero-rush/worlds/aero_world_canyon.gd")
const AeroWorldCoastal = preload("res://games/aero-rush/worlds/aero_world_coastal.gd")
const AeroWorldSky = preload("res://games/aero-rush/worlds/aero_world_sky.gd")
const AeroWorldSnow = preload("res://games/aero-rush/worlds/aero_world_snow.gd")
const AeroWorldForest = preload("res://games/aero-rush/worlds/aero_world_forest.gd")
const AeroWorldSkyline = preload("res://games/aero-rush/worlds/aero_world_skyline.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [AeroRush] Running Tracks, Worlds & Course Validation Unit Tests...")
	test_all_12_courses_pass_automated_validation()
	test_track_spline_mesh_and_collision_hull()
	test_checkpoint_gate_functionality()
	test_moving_hazard_kinematics()
	test_all_six_environments_instantiation()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL Aero Tracks/Worlds: " + msg)

func test_all_12_courses_pass_automated_validation() -> void:
	var courses = AeroCourseDatabase.get_all_courses()
	assert_true(courses.size() == 12, "Course database must contain exactly 12 handcrafted circuits")

	for c in courses:
		var c_id = c.get("id", "unknown")
		var val_result = AeroTrackValidator.validate_course(c)
		var is_pass = val_result.get("passed", false) as bool
		var errs = val_result.get("errors", []) as Array
		var err_msg = ", ".join(errs) if not errs.is_empty() else "none"
		assert_true(is_pass, "Course '%s' must PASS automated validation! Errors: %s" % [c_id, err_msg])

func test_track_spline_mesh_and_collision_hull() -> void:
	var test_waypoints = [
		{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
		{"pos": Vector3(0, 4, -50), "bank_deg": 25.0, "width": 16.0},
		{"pos": Vector3(30, 8, -100), "bank_deg": 45.0, "width": 16.0},
		{"pos": Vector3(80, 0, -120), "bank_deg": 0.0, "width": 16.0}
	]

	var res = AeroTrackGenerator.generate_track(test_waypoints, 16.0)
	var root = res.get("root") as Node3D
	assert_true(root != null, "Track generator must return root Node3D")

	var mesh_inst = res.get("mesh_instance") as MeshInstance3D
	assert_true(mesh_inst != null and mesh_inst.mesh != null, "Track must have generated ArrayMesh")

	var sb = res.get("static_body") as StaticBody3D
	assert_true(sb != null, "Track must have StaticBody3D collision body")
	assert_true(sb.collision_layer == AeroConstants.LAYER_WORLD, "Track collision layer must be WORLD")

	var col = sb.get_node_or_null("ContinuousConcaveShape") as CollisionShape3D
	assert_true(col != null and col.shape is ConcavePolygonShape3D, "Collision shape must be seamless ConcavePolygonShape3D")

	var faces = (col.shape as ConcavePolygonShape3D).get_faces()
	assert_true(faces.size() > 0, "Concave collision shape must have non-zero faces (has %d)" % faces.size())

	if root:
		root.free()

func test_checkpoint_gate_functionality() -> void:
	var gate = AeroCheckpoint.new()
	gate.checkpoint_index = 2
	gate._ready()

	assert_true(gate.collision_layer == AeroConstants.LAYER_CHECKPOINTS, "Checkpoint must be on CHECKPOINTS layer")
	assert_true(gate.monitoring and gate.monitorable, "Checkpoint must be active monitorable area")

	var xform = gate.get_recovery_transform()
	assert_true(xform != null, "Checkpoint must provide recovery transform")

	gate.free()

func test_moving_hazard_kinematics() -> void:
	var hazard = AeroMovingHazard.new()
	hazard.hazard_type = AeroMovingHazard.HazardType.ROTATING_BARRIER
	hazard._ready()

	assert_true(hazard.collision_layer == AeroConstants.LAYER_WORLD, "Hazard must be on WORLD collision layer")
	var initial_rot = hazard.rotation.y

	hazard._physics_process(0.1)
	assert_true(hazard.rotation.y != initial_rot, "Rotating barrier must rotate over physics frames")

	hazard.free()

func test_all_six_environments_instantiation() -> void:
	# 1. Megacity / Neon Afterdark
	var city = AeroWorldMegacity.new()
	city.build_environment()
	assert_true(city.sun_light != null, "Megacity must have directional sun light")
	assert_true(city.world_env != null, "Megacity must have WorldEnvironment")
	city.free()

	# 2. Canyon / Desert Extreme
	var canyon = AeroWorldCanyon.new()
	canyon.build_environment()
	assert_true(canyon.sun_light != null, "Canyon must have directional sun light")
	canyon.free()

	# 3. Coastal / Coastal Velocity
	var coastal = AeroWorldCoastal.new()
	coastal.build_environment()
	assert_true(coastal.sun_light != null, "Coastal must have directional sun light")
	coastal.free()

	# 4. Sky Circuit
	var sky = AeroWorldSky.new()
	sky.build_environment()
	assert_true(sky.sun_light != null, "Sky circuit must have directional sun light")
	sky.free()

	# 5. Snowbound Peaks
	var snow = AeroWorldSnow.new()
	snow.build_environment()
	assert_true(snow.sun_light != null, "Snowbound peaks must have directional sun light")
	assert_true(snow.world_env != null, "Snowbound peaks must have WorldEnvironment")
	snow.free()

	# 6. Wild Forest
	var forest = AeroWorldForest.new()
	forest.build_environment()
	assert_true(forest.sun_light != null, "Wild forest must have directional sun light")
	assert_true(forest.world_env != null, "Wild forest must have WorldEnvironment")
	forest.free()

	# 7. Skyline Rush
	var skyline = AeroWorldSkyline.new()
	skyline.build_environment()
	assert_true(skyline.sun_light != null, "Skyline rush must have directional sun light")
	assert_true(skyline.world_env != null, "Skyline rush must have WorldEnvironment")
	skyline.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/aero-rush/tracks/aero_course_database.gd", [
			"get_all_courses", "get_course_by_id", "_get_course_1_neon_express",
			"_get_course_2_cyber_loopway", "_get_course_3_skyscraper_rush",
			"_get_course_4_canyon_slingshot", "_get_course_5_red_rock_roller",
			"_get_course_6_ridge_hazard_run", "_get_course_7_azure_boardwalk",
			"_get_course_8_cliffside_wallride", "_get_course_9_tropic_stunt_arena",
			"_get_course_10_strato_pylon_gp", "_get_course_11_zenith_corkscrew",
			"_get_course_12_apex_impossible"
		]],
		["res://games/aero-rush/tracks/aero_track_generator.gd", [
			"generate_track", "_add_quad", "_interpolate_spline_points",
			"_catmull_rom", "_catmull_rom_tangent", "_generate_support_pylons"
		]],
		["res://games/aero-rush/tracks/aero_track_validator.gd", [
			"validate_course", "_simulate_kinematic_reachability"
		]],
		["res://games/aero-rush/tracks/aero_checkpoint.gd", [
			"_ready", "_build_gate_shape", "_build_visual_arch", "_on_body_entered",
			"_pulse_visual", "get_recovery_transform"
		]],
		["res://games/aero-rush/tracks/aero_moving_hazard.gd", [
			"_ready", "_build_hazard_shape", "_build_near_miss_detector",
			"_on_near_miss_entered", "_physics_process"
		]],
		["res://games/aero-rush/worlds/aero_world_base.gd", [
			"setup_lighting", "create_ground_bed", "spawn_tree", "spawn_building"
		]]
	]
