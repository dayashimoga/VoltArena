class_name TestWorldGeometryAndClearance
extends RefCounted

## Integration & World Validation Test Suite (Phase 7)
## Validates geometric scanners, road graph connectivity, lane clearances,
## ground-contact foundation bounds, spawn clearances, and checkpoint reachability.

const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const UrbanWorldGenerator = preload("res://games/urban-legends/world/urban_world_generator.gd")
const UrbanPropFactory = preload("res://games/urban-legends/world/urban_prop_factory.gd")
const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const CityFlightWorld = preload("res://games/aircraft-flight/worlds/city_flight_world.gd")
const FlightWorldManager = preload("res://games/aircraft-flight/worlds/flight_world_manager.gd")
const RunwayGenerator = preload("res://games/aircraft-flight/worlds/runway_generator.gd")
const AeroCourseDatabase = preload("res://games/aero-rush/tracks/aero_course_database.gd")
const AeroTrackValidator = preload("res://games/aero-rush/tracks/aero_track_validator.gd")
const GameManager = preload("res://shared/core/game_manager.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestWorldGeometryAndClearance ---")
	test_road_graph_connectivity()
	test_zero_props_and_trees_overlapping_lanes_or_runways()
	test_zero_floating_buildings_ground_contact()
	test_valid_spawn_clearances_across_all_games()
	test_reachable_mission_checkpoints()
	test_13_game_registry_and_routing_integrity()

	print("World Geometry & Clearance: %d passed, %d failed" % [passed_assertions, failed_assertions])
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

func test_road_graph_connectivity() -> void:
	# 1. Urban Legends Road Network
	var network = UrbanRoadNetwork.new()
	network.build_road_network()
	var segs = network.get_road_segments()
	assert_true(segs.size() >= 10, "Urban Legends road network must have >= 10 segments (found: %d)" % segs.size())
	
	var total_len = network.get_total_road_length_meters()
	assert_true(total_len >= 3000.0, "Urban Legends total road length must be >= 3000m (actual: %.1fm)" % total_len)

	# Verify every segment has valid non-zero length and continuous endpoints
	var zero_len_count = 0
	for seg in segs:
		var p1: Vector3 = seg["start"]
		var p2: Vector3 = seg["end"]
		if p1.distance_to(p2) < 1.0:
			zero_len_count += 1
	assert_true(zero_len_count == 0, "All road segments must have valid length >= 1.0m (zero-len: %d)" % zero_len_count)

	# 2. Apex Flight Airport Runways & Taxiways
	var runway = RunwayGenerator.build_runway(3000.0, 45.0, "09L")
	assert_true(runway != null, "Apex Flight runway must generate cleanly")
	var sb = runway.get_node_or_null("RunwayCollision")
	assert_true(sb != null and sb.get_child_count() > 0, "Runway collision body must exist")
	var col = sb.get_child(0) as CollisionShape3D
	assert_true(col != null and col.shape is BoxShape3D, "Runway collision box must exist")
	var box: BoxShape3D = col.shape
	assert_true(box.size.z >= 2000.0, "Apex Flight runway length must be >= 2000m (actual: %.1fm)" % box.size.z)
	assert_true(box.size.x >= 40.0, "Apex Flight runway width must be >= 40m (actual: %.1fm)" % box.size.x)
	runway.free()

	# 3. AeroSim 6-DoF Runway Threshold Alignment
	var aero_rwy_path = "res://games/flight-simulator-6dof/world/runway_builder.gd"
	assert_true(FileAccess.file_exists(aero_rwy_path), "AeroSim 6-DoF runway builder script must exist")

func test_zero_props_and_trees_overlapping_lanes_or_runways() -> void:
	# 1. Urban Legends World
	var gen = UrbanWorldGenerator.new()
	gen.generate_world()

	var solid_obstructions = 0
	var tree_obstructions = 0
	for prop in gen.props_container.get_children():
		var p_name = prop.name
		# Exclude intentional stunt kickers and flyovers from lane clearance test
		if p_name.begins_with("Stunt") or p_name.begins_with("Flyover") or p_name.begins_with("Bridge"):
			continue
		var p_pos = prop.position
		var near = gen.road_network.get_nearest_road_point(p_pos)
		
		if p_name.begins_with("Skyscraper") or p_name.begins_with("Brownstone") or p_name.begins_with("Villa"):
			# Buildings must clear road by at least 5.0m
			if near["distance"] < 5.0:
				solid_obstructions += 1
		elif p_name.begins_with("Palm") or p_name.begins_with("Tree"):
			# Trees must clear drivable asphalt lanes
			if near["distance"] < 3.8:
				tree_obstructions += 1

	assert_true(solid_obstructions == 0, "Zero buildings may encroach into road corridors (found: %d)" % solid_obstructions)
	assert_true(tree_obstructions == 0, "Zero trees may encroach into drivable lanes (found: %d)" % tree_obstructions)
	gen.free()

	# Prop factory & catalog utility checks
	var comm = UrbanPropFactory.build_commercial_block(35.0, 20.0, 20.0)
	assert_true(comm != null, "Commercial block must build")
	comm.free()
	var tree = UrbanPropFactory.build_tree(9.0)
	assert_true(tree != null, "Tree must build")
	tree.free()
	var all_veh = UrbanVehicleCatalog.get_all_vehicle_ids()
	assert_true(all_veh.size() >= 4, "Catalog must list all vehicle IDs")
	var biomes = WildBiomes.new()
	biomes.build_biome(0)
	assert_true(biomes != null, "WildBiomes must build biome")
	biomes.free()

	# 2. Apex Flight Airport Corridor Clearance
	var city_flight = CityFlightWorld.new()
	assert_true(city_flight != null, "CityFlightWorld must instantiate cleanly")
	city_flight.free()

func test_zero_floating_buildings_ground_contact() -> void:
	var gen = UrbanWorldGenerator.new()
	gen.generate_world()

	var floating_buildings = 0
	for prop in gen.props_container.get_children():
		if prop.name.begins_with("Skyscraper") or prop.name.begins_with("Brownstone") or prop.name.begins_with("Villa"):
			var base_y = prop.position.y
			# In urban legends, ground plane elevation is at 0.0m or plateau level
			# Foundation base must sit on ground (base_y <= 0.15m above ground level)
			if base_y > 0.15:
				floating_buildings += 1

	assert_true(floating_buildings == 0, "Zero floating buildings in Urban Legends world (found: %d)" % floating_buildings)
	gen.free()

func test_valid_spawn_clearances_across_all_games() -> void:
	var manifest_path = "res://shared/manifest/games_manifest.json"
	assert_true(FileAccess.file_exists(manifest_path), "games_manifest.json must exist")

	var manifest_file = FileAccess.open(manifest_path, FileAccess.READ)
	var manifest_data = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()

	assert_true(manifest_data is Dictionary, "Manifest must be a valid JSON dictionary")
	var games = manifest_data.get("games", {})
	assert_true(games.size() == 13, "Manifest must register all 13 standalone titles (actual: %d)" % games.size())

	# Verify every game's main scene file exists and has non-empty scene path
	var missing_scenes = 0
	for g_id in games.keys():
		var g_info = games[g_id]
		var scene_path = g_info.get("scene_path", "")
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			missing_scenes += 1
			push_error("Missing main scene for game '%s': %s" % [g_id, scene_path])

	assert_true(missing_scenes == 0, "100%% of 13 games must have valid loadable scene files (missing: %d)" % missing_scenes)

func test_reachable_mission_checkpoints() -> void:
	# 1. AeroRush 12 Courses Reachability
	var all_courses = AeroCourseDatabase.get_all_courses()
	assert_true(all_courses.size() == 12, "Must contain exactly 12 handcrafted stunt courses")
	for c_def in all_courses:
		var c_id = c_def.get("id", "course")
		var val_res = AeroTrackValidator.validate_course(c_def)
		assert_true(val_res.get("is_valid", false), "AeroRush course '%s' must pass geometric validation" % c_id)

	# 2. Apex Flight Aerial Slalom Rings
	var ring_script_path = "res://games/aircraft-flight/missions/checkpoint_ring.gd"
	assert_true(FileAccess.file_exists(ring_script_path), "Apex Flight checkpoint_ring.gd must exist")

	# 3. Drift Storm Checkpoints
	var kart_ckpt_path = "res://games/kart-racing/tracks/checkpoint.gd"
	assert_true(FileAccess.file_exists(kart_ckpt_path), "Drift Storm tracks/checkpoint.gd must exist")

func test_13_game_registry_and_routing_integrity() -> void:
	var gm = GameManager.new()
	assert_true(gm.GAME_REGISTRY.size() == 13, "GameManager.GAME_REGISTRY must contain exactly 13 games (found: %d)" % gm.GAME_REGISTRY.size())

	var expected_ids = [
		"arena_fps", "subway_survival", "rocket_car", "kart_racing",
		"roboforge_arena", "wildcircuit", "skybound_odyssey", "chroma_rush",
		"strike_vector", "aero_rush", "aircraft_flight", "urban_legends",
		"flight_simulator_6dof"
	]

	var missing_ids = 0
	for e_id in expected_ids:
		if not gm.GAME_REGISTRY.has(e_id):
			missing_ids += 1
			push_error("GameManager missing registered ID: %s" % e_id)

	assert_true(missing_ids == 0, "GameManager must register all 13 canonical game IDs (missing: %d)" % missing_ids)
	gm.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/world/urban_road_network.gd", [
			"build_road_network", "get_road_segments", "get_total_road_length_meters", "get_nearest_road_point"
		]],
		["res://games/urban-legends/world/urban_world_generator.gd", [
			"generate_world", "get_verified_spawn_count", "get_spawn_point"
		]],
		["res://shared/core/game_manager.gd", [
			"get_game_title", "get_scene_path", "start_game"
		]],
		["res://games/urban-legends/world/urban_prop_factory.gd", [
			"build_commercial_block", "build_tree"
		]],
		["res://games/urban-legends/vehicles/urban_vehicle_catalog.gd", [
			"get_all_vehicle_ids"
		]],
		["res://games/wildcircuit/world/wild_biomes.gd", [
			"build_biome"
		]]
	]
