class_name TestMapGenerators
extends RefCounted

const ArenaMapGenScript = preload("res://games/arena-fps/maps/arena_map_generator.gd")
const SubwayGenScript = preload("res://games/subway-survival/maps/subway_generator.gd")
const RocketArenaScript = preload("res://games/rocket-car/arena/rocket_arena.gd")
const TrackGenScript = preload("res://games/kart-racing/tracks/track_generator.gd")
const CheckpointScript = preload("res://games/kart-racing/tracks/checkpoint.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_arena_map_generator()
	test_subway_generator()
	test_rocket_arena_generator()
	test_track_generator()
	test_race_checkpoint()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/arena-fps/maps/arena_map_generator.gd",
			["_ready", "build_arena", "create_box", "spawn_pickup", "setup_lighting"]
		],
		[
			"res://games/subway-survival/maps/subway_generator.gd",
			["_ready", "build_subway_station", "create_box", "setup_subway_lighting", "unlock_gate"]
		],
		[
			"res://games/rocket-car/arena/rocket_arena.gd",
			["_ready", "build_arena", "build_end_wall", "create_goal_trigger", "create_boost_pad", "create_boost_orb", "create_box", "create_flat_marker", "build_pitch_markings", "create_jumbotron", "setup_stadium_lighting"]
		],
		[
			"res://games/kart-racing/tracks/track_generator.gd",
			["_ready", "build_circuit", "build_track_segment", "create_start_finish_gantry", "create_box", "setup_racing_environment"]
		],
		[
			"res://games/kart-racing/tracks/checkpoint.gd",
			["_ready", "setup_trigger_volume"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit MapGenerators FAIL: " + msg)

func test_arena_map_generator() -> void:
	var map = ArenaMapGenScript.new()
	map._ready()
	assert_true(map.get_child_count() > 10, "ArenaMap must create geometry children")
	var box = map.create_box(Vector3.ZERO, Vector3(2, 2, 2), "dark_hull")
	assert_true(box is StaticBody3D, "create_box must produce StaticBody3D")
	map.queue_free()

func test_subway_generator() -> void:
	var sub = SubwayGenScript.new()
	sub._ready()
	assert_true(sub.get_child_count() > 10, "SubwayGenerator must create station geometry")
	sub.unlock_gate(2)
	sub.unlock_gate(3)
	assert_true(sub.is_zone2_unlocked and sub.is_zone3_unlocked, "Gates 2 and 3 should be unlocked")
	sub.queue_free()

func test_rocket_arena_generator() -> void:
	var arena = RocketArenaScript.new()
	arena._ready()
	assert_true(arena.get_child_count() > 5, "RocketArena must create walls and floor")
	arena.create_jumbotron()
	arena.queue_free()

func test_track_generator() -> void:
	var track = TrackGenScript.new()
	track._ready()
	assert_true(track.waypoints.size() >= 8, "Track must have at least 8 circuit waypoints")
	assert_true(track.checkpoints.size() >= 8, "Track must have checkpoints")
	var box = track.create_box(Vector3.ZERO, Vector3.ONE, "grass")
	assert_true(box is StaticBody3D, "track.create_box must return StaticBody3D")
	track.create_start_finish_gantry(Vector3.ZERO)
	track.queue_free()

func test_race_checkpoint() -> void:
	var cp = CheckpointScript.new()
	cp.is_finish_line = true
	cp._ready()
	assert_true(cp.get_child_count() >= 2, "Finish line checkpoint must have collision and visual arch")
	cp.queue_free()
