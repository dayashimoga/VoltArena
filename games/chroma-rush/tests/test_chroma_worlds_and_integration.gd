class_name TestChromaWorldsAndIntegration
extends RefCounted

## Unit tests for Chroma Rush 3D worlds, waypoints, road networks, and checkpoints

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const WorldBase = preload("res://games/chroma-rush/worlds/world_base.gd")
const NeonCity = preload("res://games/chroma-rush/worlds/neon_city.gd")
const CoastalRush = preload("res://games/chroma-rush/worlds/coastal_rush.gd")
const PrismCanyon = preload("res://games/chroma-rush/worlds/prism_canyon.gd")
const SkyCircuit = preload("res://games/chroma-rush/worlds/sky_circuit.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_neon_city_construction()
	test_coastal_rush_construction()
	test_prism_canyon_construction()
	test_sky_circuit_construction()
	test_checkpoint_gate_trigger_matching()
	test_checkpoint_gate_trigger_mismatching()
	test_waypoint_navigation_queries()
	test_continuous_road_mesh_and_collision()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaWorlds FAIL] " + msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaWorlds FAIL] %s (Expected %s, got %s)" % [msg, str(b), str(a)])

func test_neon_city_construction() -> void:
	var city = NeonCity.new()
	city._ready()

	assert_eq(city.world_id, ChromaConstants.WORLD_NEON_CITY, "World ID matches neon_city")
	assert_true(city.waypoints.size() >= 16, "Neon City must have at least 16 waypoints")
	assert_eq(city.checkpoints.size(), 6, "Neon City must have 6 checkpoints")
	assert_true(city.traffic_spawn_data.size() >= 4, "Must have traffic spawn data")
	assert_true(city.road_container.get_child_count() > 0, "Road mesh segments must be built")

	city.free()

func test_coastal_rush_construction() -> void:
	var coast = CoastalRush.new()
	coast._ready()

	assert_eq(coast.world_id, ChromaConstants.WORLD_COASTAL_RUSH, "World ID matches coastal_rush")
	assert_true(coast.waypoints.size() >= 16, "Coastal Rush must have at least 16 waypoints")
	assert_eq(coast.checkpoints.size(), 6, "Coastal Rush must have 6 checkpoints")
	assert_true(coast.props_container.get_child_count() > 0, "Props container must contain ocean and palms")

	coast.free()

func test_prism_canyon_construction() -> void:
	var canyon = PrismCanyon.new()
	canyon._ready()

	assert_eq(canyon.world_id, ChromaConstants.WORLD_PRISM_CANYON, "World ID matches prism_canyon")
	assert_true(canyon.waypoints.size() >= 16, "Prism Canyon must have at least 16 waypoints")
	assert_eq(canyon.checkpoints.size(), 6, "Prism Canyon must have 6 checkpoints")
	assert_true(canyon.props_container.get_child_count() > 0, "Props container must contain rock arches and mesas")

	canyon.free()

func test_sky_circuit_construction() -> void:
	var sky = SkyCircuit.new()
	sky._ready()

	assert_eq(sky.world_id, ChromaConstants.WORLD_SKY_CIRCUIT, "World ID matches sky_circuit")
	assert_true(sky.waypoints.size() >= 16, "Sky Circuit must have at least 16 waypoints")
	assert_eq(sky.checkpoints.size(), 6, "Sky Circuit must have 6 checkpoints")
	assert_true(sky.waypoints[0].y >= 45.0, "Sky Circuit waypoints should be elevated in stratosphere")

	sky.free()

func test_checkpoint_gate_trigger_matching() -> void:
	var gate = CheckpointGate.new()
	gate.target_color = ChromaConstants.ChromaColor.EMERALD
	gate._ready()

	var v = ChromaVehicle.new()
	v.initial_color = ChromaConstants.ChromaColor.EMERALD
	v._ready()

	var res_match = {"passed": false, "match": false}
	gate.gate_passed.connect(func(veh, is_match):
		res_match["passed"] = true
		res_match["match"] = is_match
	)

	gate._on_body_entered(v)
	assert_true(res_match["passed"], "gate_passed signal must be fired")
	assert_true(res_match["match"], "is_match must be true when vehicle holds matching color")

	gate.free()
	v.free()

func test_checkpoint_gate_trigger_mismatching() -> void:
	var gate = CheckpointGate.new()
	gate.target_color = ChromaConstants.ChromaColor.SOLAR
	gate._ready()

	var v = ChromaVehicle.new()
	v.initial_color = ChromaConstants.ChromaColor.CRIMSON # Mismatched
	v._ready()

	var res_mismatch = {"passed": false, "match": true}
	gate.gate_passed.connect(func(veh, is_match):
		res_mismatch["passed"] = true
		res_mismatch["match"] = is_match
	)

	gate._on_body_entered(v)
	assert_false(res_mismatch["match"], "is_match must be false when vehicle holds non-matching color")

	gate.free()
	v.free()

func test_waypoint_navigation_queries() -> void:
	var city = NeonCity.new()
	city._ready()

	var nearest_idx = city.get_nearest_waypoint_index(Vector3(1, 0, -2))
	assert_eq(nearest_idx, 0, "Nearest waypoint to (1, 0, -2) should be index 0")

	var wp_pos = city.get_waypoint(1)
	assert_eq(wp_pos, Vector3(0, 0, -80), "Waypoint 1 matches known position")

	var gate1 = city.get_checkpoint_by_id("gate_1")
	assert_true(gate1 != null, "get_checkpoint_by_id finds gate_1")
	assert_eq(gate1.target_color, ChromaConstants.ChromaColor.CRIMSON, "Gate 1 target is crimson")

	city.free()

func test_continuous_road_mesh_and_collision() -> void:
	var city = NeonCity.new()
	city._ready()

	# Verify continuous road network produces static bodies with ConcavePolygonShape3D
	var road_body = city.road_container.get_node_or_null("ContinuousRoadNetwork") as StaticBody3D
	assert_true(road_body != null, "ContinuousRoadNetwork must exist in road container")
	var col_shape = road_body.get_node_or_null("ContinuousRoadCollision") as CollisionShape3D
	assert_true(col_shape != null, "ContinuousRoadCollision must exist")
	assert_true(col_shape.shape is ConcavePolygonShape3D, "Collision shape must be seamless ConcavePolygonShape3D (Trimesh)")
	var trimesh = col_shape.shape as ConcavePolygonShape3D
	assert_true(trimesh.get_faces().size() > 100, "Road trimesh must have faces representing all waypoints")

	# Verify visual ribbon
	var ribbon = road_body.get_node_or_null("RoadMesh") as MeshInstance3D
	assert_true(ribbon != null, "RoadMesh visual must exist")

	city.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/worlds/checkpoint_gate.gd", [
			"_ready", "setup_gate_visuals", "setup_gate_collision", "apply_target_color"
		]],
		["res://games/chroma-rush/worlds/world_base.gd", [
			"_ready", "build_world", "setup_lighting", "build_continuous_road_network",
			"get_nearest_waypoint_index", "get_waypoint", "get_total_waypoints",
			"get_checkpoint", "get_checkpoint_by_id", "add_road_segment"
		]],
		["res://games/chroma-rush/worlds/neon_city.gd", [
			"generate_waypoints", "build_road_mesh", "build_checkpoints", "build_props"
		]],
		["res://games/chroma-rush/worlds/coastal_rush.gd", [
			"setup_lighting", "generate_waypoints", "build_road_mesh", "build_checkpoints", "build_props"
		]],
		["res://games/chroma-rush/worlds/prism_canyon.gd", [
			"setup_lighting", "generate_waypoints", "build_road_mesh", "build_checkpoints", "build_props"
		]],
		["res://games/chroma-rush/worlds/sky_circuit.gd", [
			"setup_lighting", "generate_waypoints", "build_road_mesh", "build_checkpoints", "build_props"
		]]
	]
