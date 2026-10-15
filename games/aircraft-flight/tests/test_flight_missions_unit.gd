class_name TestFlightMissionsUnit
extends RefCounted

## TestFlightMissionsUnit: Unit tests for mission director, 8 mission definitions,
## checkpoint rings, orientation scoring, and medal evaluations.

const MissionDefs = preload("res://games/aircraft-flight/missions/mission_definitions.gd")
const CheckpointRingScript = preload("res://games/aircraft-flight/missions/checkpoint_ring.gd")
const FlightMissionDirectorScript = preload("res://games/aircraft-flight/missions/flight_mission_director.gd")
const FlightPhysicsScript = preload("res://games/aircraft-flight/core/flight_physics.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_mission_definitions_catalog()
	test_checkpoint_ring_orientations()
	test_mission_director_lifecycle()
	test_race_checkpoint_progression()
	test_medal_grading()

	return {"passed": assertions_passed, "failed": assertions_failed}

func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: %s" % msg)

func test_mission_definitions_catalog() -> void:
	var missions = MissionDefs.get_all_missions()
	_assert_true(missions.size() == 8, "Mission catalog contains all 8 advertised mission modes")

	var m_takeoff = MissionDefs.get_mission("m2_takeoff_landing")
	_assert_true(m_takeoff.get("target_climb_alt_m") == 600.0, "Takeoff certification climb target configured")

	var m_race = MissionDefs.get_mission("m4_checkpoint_race")
	_assert_true(m_race.get("ring_waypoints", []).size() >= 8, "Air race waypoints configured")

	var m_recon = MissionDefs.get_mission("m7_landmark_recon")
	_assert_true(m_recon.get("recon_targets", []).size() == 4, "Landmark photography targets configured")

func test_checkpoint_ring_orientations() -> void:
	var ring = CheckpointRingScript.new()
	ring.ring_radius = 35.0
	ring._build_ring_visuals()

	# Normal upright roll (0 deg)
	ring.required_orientation = CheckpointRingScript.RingOrientation.UPRIGHT
	_assert_true(ring._evaluate_orientation(10.0), "Upright orientation accepted at 10 deg roll")
	_assert_true(not ring._evaluate_orientation(85.0), "Upright orientation rejected at 85 deg roll")

	# Knife-Edge roll (90 deg)
	ring.required_orientation = CheckpointRingScript.RingOrientation.KNIFE_EDGE
	_assert_true(ring._evaluate_orientation(90.0), "Knife-edge orientation accepted at 90 deg roll")
	_assert_true(not ring._evaluate_orientation(0.0), "Knife-edge rejected at 0 deg roll")

	# Inverted roll (180 deg)
	ring.required_orientation = CheckpointRingScript.RingOrientation.INVERTED
	_assert_true(ring._evaluate_orientation(175.0), "Inverted orientation accepted at 175 deg roll")

	ring.free()

func test_mission_director_lifecycle() -> void:
	var md = FlightMissionDirectorScript.new()
	var plane = FlightPhysicsScript.new()
	var world = Node3D.new()

	md.start_mission("m1_free_flight", plane, world)
	_assert_true(md.is_mission_active == true, "Mission marked active")
	_assert_true(md.current_objective_text != "", "Initial objective prompt generated")

	md.update_mission(1.0, plane)
	_assert_true(md.elapsed_time_s >= 1.0, "Elapsed mission time tracked")

	md.complete_mission()
	_assert_true(md.is_mission_active == false, "Mission marked inactive upon completion")

	md.free()
	plane.free()
	world.free()

func test_race_checkpoint_progression() -> void:
	var md = FlightMissionDirectorScript.new()
	var plane = FlightPhysicsScript.new()
	var world = Node3D.new()

	md.start_mission("m4_checkpoint_race", plane, world)
	_assert_true(md.total_rings == 8, "8 race rings instantiated")
	_assert_true(md.current_ring_index == 0, "Initial ring index is 0")

	# Pass ring 0
	md._on_ring_passed(0, true, 0.0)
	_assert_true(md.current_ring_index == 1, "Passing ring 0 advances index to 1")
	_assert_true(md.score >= 500, "Passing ring awards points")

	md.free()
	plane.free()
	world.free()

func test_medal_grading() -> void:
	var md = FlightMissionDirectorScript.new()
	md.current_mission_data = MissionDefs.get_mission("m4_checkpoint_race")

	md.elapsed_time_s = 40.0 # Under 45s gold target
	_assert_true(md._calculate_medal() == "Gold", "Fast race time awards Gold medal")

	md.elapsed_time_s = 55.0 # Under 60s silver target
	_assert_true(md._calculate_medal() == "Silver", "Intermediate race time awards Silver medal")

	md.elapsed_time_s = 75.0 # Bronze
	_assert_true(md._calculate_medal() == "Bronze", "Slower race time awards Bronze medal")

	md.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/aircraft-flight/missions/checkpoint_ring.gd",
			["_ready", "_build_ring_visuals", "_on_body_entered", "_evaluate_orientation"]
		],
		[
			"res://games/aircraft-flight/missions/mission_definitions.gd",
			["get_mission", "get_all_missions"]
		],
		[
			"res://games/aircraft-flight/missions/flight_mission_director.gd",
			[
				"start_mission", "_setup_race_rings", "_update_initial_objective",
				"update_mission", "_update_takeoff_landing_logic", "_update_urban_corridor_logic",
				"_update_deadstick_logic", "_update_landmark_recon_logic", "_update_sar_logic",
				"_on_ring_passed", "complete_mission", "fail_mission", "_calculate_medal",
				"_save_progression"
			]
		]
	]
