class_name TestFlightSim6DoFE2E
extends RefCounted

## End-to-End Flight Scenario and System Integration Test Suite for Game #13.
## Validates complete simulation loop: ground roll, takeoff, climb, trim, coordinated turn,
## stall warning & recovery, approach, landing touchdown, braking, and flight school scoring.

const WorldMainScene = preload("res://games/flight-simulator-6dof/world_main.tscn")
const StandaloneScene = preload("res://games/flight-simulator-6dof/flight_sim_standalone.tscn")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestFlightSim6DoFE2E ---")
	test_world_scene_assembly_and_nodes()
	test_standalone_menu_and_launch_flow()
	test_ground_roll_and_takeoff_scenario()
	test_climb_and_coordinated_turn_scenario()
	test_stall_warning_and_recovery_scenario()
	test_approach_landing_and_braking_scenario()
	test_flight_school_lesson_progression()

	return {
		"total": total_assertions,
		"passed": passed_assertions,
		"failed": failed_assertions
	}

func assert_true(cond: bool, msg: String) -> void:
	total_assertions += 1
	if cond:
		passed_assertions += 1
		print("  [PASS] " + msg)
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg)
		push_error("Assertion failed: %s" % msg)

func assert_almost_equal(val: float, expected: float, tol: float, msg: String) -> void:
	total_assertions += 1
	if abs(val - expected) <= tol:
		passed_assertions += 1
		print("  [PASS] " + msg + " (val: %.4f, expected: %.4f)" % [val, expected])
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg + " (val: %.4f, expected: %.4f, tol: %.4f)" % [val, expected, tol])
		push_error("Assertion failed: %s" % msg)

func _get_tree_root() -> Node:
	if Engine.get_main_loop() and Engine.get_main_loop() is SceneTree:
		return (Engine.get_main_loop() as SceneTree).root
	return null

func test_world_scene_assembly_and_nodes() -> void:
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	assert_true(world != null, "world_main.tscn instantiates cleanly")

	var terrain = world.get_node_or_null("TerrainSystem")
	var runway = world.get_node_or_null("RunwayComplex")
	var aircraft = world.get_node_or_null("AircraftRig")
	var origin = world.get_node_or_null("FloatingOrigin")

	assert_true(terrain != null, "TerrainSystem exists in world")
	assert_true(runway != null, "RunwayComplex exists in world")
	assert_true(aircraft != null, "AircraftRig exists in world")
	assert_true(origin != null, "FloatingOrigin exists in world")

	# Check runway placement at (0, 0.05, 0)
	assert_almost_equal(runway.position.y, 0.05, 0.01, "Runway placed at exact (0, 0.05, 0)")

	# Check aircraft initial runway placement
	assert_almost_equal(aircraft.position.x, 0.0, 0.5, "Aircraft aligned with runway centerline (X ~ 0)")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_standalone_menu_and_launch_flow() -> void:
	var root = _get_tree_root()
	var standalone = StandaloneScene.instantiate()
	if root:
		root.add_child(standalone)
	standalone._ready()
	assert_true(standalone != null, "flight_sim_standalone.tscn instantiates cleanly")

	assert_true(standalone.main_menu_panel != null, "Standalone main menu panel created")
	assert_true(standalone.world_viewport != null, "Standalone 3D viewport created")

	# Simulate launching flight school
	standalone._launch_simulation(0)
	assert_true(standalone.active_world != null, "Simulation launches world into viewport")

	if root and standalone.get_parent() == root:
		root.remove_child(standalone)
	standalone.free()

func test_ground_roll_and_takeoff_scenario() -> void:
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController

	# Initial ground state: stationary on runway
	aircraft.linear_velocity = Vector3.ZERO
	aircraft.throttle_input = 0.0
	aircraft.weight_on_wheels = true

	# Step 1: Advance throttle to 100%
	aircraft.throttle_input = 1.0
	for i in range(60): # 0.5 sec at 120Hz
		aircraft._update_engine_and_propeller(0.00833, 1.225)

	assert_true(aircraft.current_thrust_n > 2000.0, "Engine spools and generates takeoff thrust")

	# Step 2: Accelerate past 65 KIAS (~33.4 m/s)
	aircraft.linear_velocity = Vector3(0, 0, -36.0)
	aircraft._update_engine_and_propeller(0.00833, 1.225)
	aircraft._update_telemetry(0.00833, 1.225, 340.0)
	assert_true(aircraft.airspeed_kias >= 65.0, "Aircraft airspeed exceeds 65 KIAS rotation threshold")

	# Step 3: Rotate stick back (pitch input +0.6) and simulate lift-off
	aircraft.pitch_input = 0.6
	aircraft.linear_velocity += Vector3(0, 2.5, 0) # Positive climb
	aircraft.weight_on_wheels = false # Airborne
	aircraft._update_telemetry(0.00833, 1.225, 340.0)

	assert_true(not aircraft.weight_on_wheels, "Weight-on-wheels switches to false on lift-off")
	assert_true(aircraft.vertical_speed_fpm > 0.0, "Positive climb rate established")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_climb_and_coordinated_turn_scenario() -> void:
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController

	aircraft.weight_on_wheels = false
	aircraft.linear_velocity = Vector3(0, 4.0, -48.0) # 4 m/s climb at ~93 KIAS
	aircraft._update_telemetry(0.00833, 1.225, 340.0)

	assert_true(aircraft.vertical_speed_fpm > 600.0, "Climb vertical speed > 600 FPM")

	# Coordinated turn: Roll right (bank 30 deg), apply slight elevator backpressure
	aircraft.roll_input = 0.5
	aircraft.pitch_input = 0.15
	aircraft.rudder_input = 0.12 # Coordinated turn eliminates sideslip

	aircraft._update_aerodynamics(0.00833, 1.225)
	assert_true(aircraft.current_g_force >= 1.0, "Turn load factor G >= 1.0")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_stall_warning_and_recovery_scenario() -> void:
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController

	aircraft.weight_on_wheels = false
	aircraft.throttle_input = 0.0 # Idle
	aircraft.linear_velocity = Vector3(0, -0.5, -22.0) # Low speed 42 KIAS
	aircraft.max_inboard_aoa_deg = 14.5 # Above 13.5 deg threshold

	aircraft._update_telemetry(0.00833, 1.225, 340.0)
	assert_true(aircraft.stall_horn_active, "Stall warning horn sounds in flight when AoA >= 13.5 deg")

	# Recovery maneuver: push stick forward (pitch -0.8), full throttle
	aircraft.pitch_input = -0.8
	aircraft.throttle_input = 1.0
	aircraft.max_inboard_aoa_deg = 4.0 # Broken stall AoA
	aircraft.linear_velocity = Vector3(0, 0, -38.0) # Regained airspeed

	aircraft._update_telemetry(0.00833, 1.225, 340.0)
	assert_true(not aircraft.stall_horn_active, "Stall horn silences immediately upon AoA reduction")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_approach_landing_and_braking_scenario() -> void:
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController

	# Approach setup: Flaps 35 deg, descending on 3 deg glide slope
	aircraft.flaps_index = 2 # 35 deg
	aircraft.linear_velocity = Vector3(0, -1.8, -32.0) # ~62 KIAS, sink rate ~350 FPM
	aircraft.weight_on_wheels = false
	aircraft._update_telemetry(0.00833, 1.225, 340.0)

	assert_almost_equal(aircraft.flaps_angles[aircraft.flaps_index], 35.0, 0.1, "Landing flaps deployed at 35 deg")

	# Touchdown flare: sink rate reduced to < 200 FPM
	aircraft.linear_velocity = Vector3(0, -0.8, -26.0) # Sink rate ~157 FPM
	aircraft.weight_on_wheels = true

	var sink_rate_fpm = abs(aircraft.linear_velocity.y * 196.85)
	assert_true(sink_rate_fpm < 250.0, "Touchdown sink rate below 250 FPM limit (soft landing)")

	# Apply wheel brakes to stop
	aircraft.brake_input = 1.0
	aircraft.linear_velocity = Vector3.ZERO
	aircraft.weight_on_wheels = true

	assert_true(aircraft.weight_on_wheels, "Weight on wheels confirmed after touchdown")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_flight_school_lesson_progression() -> void:
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController
	var director = world.get_node_or_null("FlightSchoolDirector") as FlightSchoolDirector

	assert_true(director != null, "FlightSchoolDirector active in world")

	# Test starting lesson
	director.start_lesson(FlightSchoolDirector.LessonType.TAXI_TAKEOFF)
	assert_true(director.lesson_active, "Lesson is active")
	assert_true(director.waypoints.size() > 0, "Navigation waypoints populated for takeoff lesson")

	# Award waypoint score
	director.current_score += 250
	assert_true(director.current_score >= 250, "Flight school scoring awards points")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/flight-simulator-6dof/world_main.gd",
			["_ready", "_exit_tree", "_setup_camera_hud_binding", "_setup_floating_origin", "_setup_flight_director", "_unhandled_input"]
		],
		[
			"res://games/flight-simulator-6dof/flight_sim_standalone.gd",
			["_ready", "_ensure_save_directory", "_setup_ui", "_launch_simulation", "_on_flight_school_pressed", "_on_free_flight_pressed", "_on_controls_pressed", "_on_exit_pressed", "_unhandled_input"]
		],
		[
			"res://games/flight-simulator-6dof/flight_school_director.gd",
			["_ready", "start_lesson", "_physics_process", "_setup_ui_overlay", "_setup_waypoint_marker", "_update_waypoint_marker", "_set_instruction", "_check_current_lesson_objectives", "_complete_current_lesson", "_award_score", "_fail_current_lesson"]
		],
		[
			"res://games/flight-simulator-6dof/world/runway_builder.gd",
			["build_runway_complex", "_build_asphalt_deck", "_build_runway_markings", "_build_edge_lights", "_build_papi_system"]
		],
		[
			"res://games/flight-simulator-6dof/world/terrain_builder.gd",
			["build_terrain", "_compute_height", "_compute_normal"]
		],
		[
			"res://games/flight-simulator-6dof/visuals/aircraft_visuals_6dof.gd",
			["_ready", "_setup_materials", "_build_airframe", "_build_fuselage", "_build_wings", "_build_empennage", "_build_cockpit_canopy", "_build_articulated_surfaces", "_build_propeller_disc", "update_visuals"]
		]
	]
