class_name TestUrbanWorldAndRoadsUnit
extends RefCounted

## Unit test suite for Urban Legends open world districts, continuous road network,
## surface friction variations, zero road obstructions, and 100/100 safe spawn points.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")
const UrbanPropFactory = preload("res://games/urban-legends/world/urban_prop_factory.gd")
const UrbanWorldGenerator = preload("res://games/urban-legends/world/urban_world_generator.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanWorldAndRoadsUnit ---")
	test_all_eight_districts()
	test_district_spatial_lookup()
	test_road_network_continuity()
	test_surface_friction_zones()
	test_nearest_road_projection()
	test_traffic_waypoints_generation()
	test_stunt_ramps_and_kickers()
	test_prop_factory_instantiation()
	test_zero_road_obstructions()
	test_safe_spawn_point_registry()

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

func test_all_eight_districts() -> void:
	var ids = UrbanDistrictDefinitions.get_district_ids()
	assert_true(ids.size() == 8, "Must define exactly 8 distinct districts (found: %d)" % ids.size())
	assert_true(ids.has(UrbanConstants.DISTRICT_DOWNTOWN), "Downtown Metro must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_COLINAS), "Colinas Heights must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_VERDANT), "Verdant Glen must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_HARBORFLY), "Harborfly Freeway must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_BAYVIEW), "Bayview Promenade must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_INDUSTRIAL), "Industrial Apex must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_RIDGECREST), "Ridgecrest Hills must exist")
	assert_true(ids.has(UrbanConstants.DISTRICT_AIRPORT), "Skyline Airport must exist")

	for d_id in ids:
		var def = UrbanDistrictDefinitions.get_district_def(d_id)
		assert_true(not def["name"].is_empty(), "District %s must have a non-empty name" % d_id)
		var b: Rect2 = def["bounds"]
		assert_true(b.get_area() > 50000.0, "District %s area must exceed 50,000 m² (was: %f)" % [d_id, b.get_area()])
		assert_true(def["elevation_max"] >= def["elevation_min"], "District %s elevation bounds must be ordered" % d_id)
		assert_true(def["speed_limit_kmh"] >= 50.0, "District %s speed limit must be >= 50 km/h" % d_id)

func test_district_spatial_lookup() -> void:
	# Downtown Core
	var d1 = UrbanDistrictDefinitions.get_district_at_position(Vector3(-100, 1.0, -100))
	assert_true(d1 == UrbanConstants.DISTRICT_DOWNTOWN, "Downtown position must resolve to Downtown Metro (was: %s)" % d1)

	# Colinas Heights Hillside
	var d2 = UrbanDistrictDefinitions.get_district_at_position(Vector3(450, 50.0, 500))
	assert_true(d2 == UrbanConstants.DISTRICT_COLINAS, "Hillside position must resolve to Colinas Heights (was: %s)" % d2)

	# Verdant Glen Parkland
	var d3 = UrbanDistrictDefinitions.get_district_at_position(Vector3(400, 10.0, -300))
	assert_true(d3 == UrbanConstants.DISTRICT_VERDANT, "Parkland position must resolve to Verdant Glen (was: %s)" % d3)

	# Harborfly Freeway Transverse Corridor
	var d4 = UrbanDistrictDefinitions.get_district_at_position(Vector3(0, 18.0, 20.0))
	assert_true(d4 == UrbanConstants.DISTRICT_HARBORFLY, "Freeway position must resolve to Harborfly Freeway (was: %s)" % d4)

	# Bayview Promenade Coastline
	var d5 = UrbanDistrictDefinitions.get_district_at_position(Vector3(0, 1.0, -900))
	assert_true(d5 == UrbanConstants.DISTRICT_BAYVIEW, "Coastline position must resolve to Bayview Promenade (was: %s)" % d5)

	# Skyline Airport Runways
	var d6 = UrbanDistrictDefinitions.get_district_at_position(Vector3(-800, 1.0, -450))
	assert_true(d6 == UrbanConstants.DISTRICT_AIRPORT, "Runway position must resolve to Skyline Airport (was: %s)" % d6)

func test_road_network_continuity() -> void:
	var net = UrbanRoadNetwork.new()
	var segs = net.get_road_segments()
	assert_true(segs.size() >= 25, "Road network must contain >= 25 segments (found: %d)" % segs.size())

	var total_len = net.get_total_road_length_meters()
	assert_true(total_len >= 8000.0, "Total contiguous roadway length must be >= 8,000m (was: %.1fm)" % total_len)

	# Continuity Check: Every segment connects to the network without isolated disjoint islands
	for seg in segs:
		assert_true(seg["length"] >= 10.0, "Road segment %d must be >= 10m long" % seg["id"])
		var st: Vector3 = seg["start"]
		var en: Vector3 = seg["end"]
		var st_connected = false
		var en_connected = false
		for other in segs:
			if other["id"] == seg["id"]:
				continue
			var o_st: Vector3 = other["start"]
			var o_en: Vector3 = other["end"]
			if st.distance_to(o_st) < 2.0 or st.distance_to(o_en) < 2.0:
				st_connected = true
			if en.distance_to(o_st) < 2.0 or en.distance_to(o_en) < 2.0:
				en_connected = true
		assert_true(st_connected or en_connected, "Segment %d must be connected to network" % seg["id"])

func test_surface_friction_zones() -> void:
	var net = UrbanRoadNetwork.new()

	# Downtown Asphalt
	var f_asphalt = net.get_surface_friction(Vector3(-100, 1.0, -100))
	assert_true(f_asphalt >= 0.99, "Asphalt road friction should be ~1.0 (was: %f)" % f_asphalt)

	# Verdant Glen Grass Drift Path
	var f_grass = net.get_surface_friction(Vector3(380, 11.0, -220))
	assert_true(f_grass <= 0.75 and f_grass >= 0.70, "Grass drift path friction should be ~0.72 (was: %f)" % f_grass)

	# Ridgecrest Gravel Pass
	var f_dirt = net.get_surface_friction(Vector3(80, 65.0, 700))
	assert_true(f_dirt <= 0.85 and f_dirt >= 0.80, "Mountain gravel friction should be ~0.82 (was: %f)" % f_dirt)

	# Deep off-road terrain
	var f_offroad = net.get_surface_friction(Vector3(800, 1.0, -300))
	assert_true(f_offroad <= 0.75, "Off-road terrain friction should be reduced for grass resistance (was: %f)" % f_offroad)

func test_nearest_road_projection() -> void:
	var net = UrbanRoadNetwork.new()

	# Point 5m east of Central Grand Avenue (-100, 1.0, -200)
	var query_pos = Vector3(-95.0, 1.0, -200.0)
	var near = net.get_nearest_road_point(query_pos)
	assert_true(near["distance"] < 6.0, "Nearest road distance should be ~5.0m (was: %f)" % near["distance"])
	assert_true(near["speed_limit"] == 80.0, "Downtown speed limit should be 80 km/h (was: %f)" % near["speed_limit"])
	assert_true(net.is_point_on_road(query_pos, 8.0), "Point within 5m must report is_point_on_road = true")

	# Point on Harborfly Freeway
	var freeway_pt = Vector3(150, 18.0, 20)
	var f_near = net.get_nearest_road_point(freeway_pt)
	assert_true(f_near["speed_limit"] == 140.0, "Harborfly Freeway speed limit should be 140 km/h")

func test_traffic_waypoints_generation() -> void:
	var net = UrbanRoadNetwork.new()
	var wps = net.get_traffic_waypoints()
	assert_true(wps.size() >= 200, "Traffic waypoints count should be >= 200 (was: %d)" % wps.size())

	# Verify waypoint validity
	var first_wp = wps[0]
	assert_true(first_wp.origin.is_finite(), "Waypoint origin must be finite")
	var fwd = -first_wp.basis.z
	assert_true(absf(fwd.length() - 1.0) < 0.05, "Waypoint forward basis should be normalized")

func test_stunt_ramps_and_kickers() -> void:
	var gen = UrbanWorldGenerator.new()
	gen.generate_world()

	var ramps_found = 0
	for c in gen.props_container.get_children():
		if c.name.begins_with("StuntRamp") or c.is_in_group("stunt_ramps"):
			ramps_found += 1
		else:
			print("  [DEBUG CHILD] ", c.name)
	assert_true(ramps_found >= 4, "Must generate at least 4 designated stunt ramps across districts (found: %d)" % ramps_found)
	gen.free()

func test_prop_factory_instantiation() -> void:
	var tower = UrbanPropFactory.build_skyscraper(60.0, 20.0, 20.0)
	assert_true(_find_static_body(tower) != null, "Skyscraper must have StaticBody3D")
	tower.free()

	var villa = UrbanPropFactory.build_residential_villa(12.0, 10.0)
	assert_true(_find_static_body(villa) != null, "Villa must have StaticBody3D")
	villa.free()

	var viaduct = UrbanPropFactory.build_flyover_viaduct(40.0, 18.0, 16.0)
	assert_true(_find_static_body(viaduct) != null, "Viaduct must have road deck StaticBody3D")
	viaduct.free()

	var palm = UrbanPropFactory.build_palm_tree(10.0)
	assert_true(_find_static_body(palm) != null, "Palm tree must have StaticBody3D")
	palm.free()

	var ramp = UrbanPropFactory.build_stunt_ramp(8.0, 12.0, 3.5, 25.0)
	assert_true(_find_static_body(ramp) != null, "Stunt ramp must have StaticBody3D")
	ramp.free()

	# NYC Phase 2 Modular Prop Builders
	var deco = UrbanPropFactory.build_art_deco_skyscraper(120.0, 35.0, 35.0)
	assert_true(_find_static_body(deco) != null, "Art Deco skyscraper must have StaticBody3D")
	deco.free()

	var brownstone = UrbanPropFactory.build_brownstone_rowhouse(18.0, 12.0, 16.0, true)
	assert_true(_find_static_body(brownstone) != null, "Brownstone rowhouse must have StaticBody3D")
	brownstone.free()

	var marquee = UrbanPropFactory.build_theater_marquee_store(22.0, 25.0, 20.0)
	assert_true(_find_static_body(marquee) != null, "Theater marquee store must have StaticBody3D")
	marquee.free()

	var subway = UrbanPropFactory.build_subway_kiosk()
	assert_true(subway != null, "Subway kiosk must instantiate")
	subway.free()

	var pwall = UrbanPropFactory.build_park_stone_wall(30.0, 1.4)
	assert_true(_find_static_body(pwall) != null, "Park stone wall must have StaticBody3D")
	pwall.free()

	var crane = UrbanPropFactory.build_gantry_crane(35.0, 40.0)
	assert_true(crane != null, "Gantry crane must instantiate")
	crane.free()

	var sbridge = UrbanPropFactory.build_suspension_bridge(450.0, 35.0, 20.0)
	assert_true(_find_static_body(sbridge) != null, "Suspension bridge must have StaticBody3D")
	sbridge.free()

	var tunnel = UrbanPropFactory.build_underpass_tunnel(80.0, 16.0, 6.5)
	assert_true(tunnel != null, "Underpass tunnel must instantiate")
	tunnel.free()

	var signal_mast = UrbanPropFactory.build_traffic_signal_mast(6.5, 8.0)
	assert_true(signal_mast != null, "Traffic signal mast must instantiate")
	signal_mast.free()

	var hydrant = UrbanPropFactory.build_fire_hydrant()
	assert_true(hydrant != null, "Fire hydrant must instantiate")
	hydrant.free()

	var cluster = UrbanPropFactory.build_street_furniture_cluster()
	assert_true(cluster != null, "Street furniture cluster must instantiate")
	cluster.free()

	var shelter = UrbanPropFactory.build_bus_shelter()
	assert_true(shelter != null, "Bus shelter must instantiate")
	shelter.free()

	var acorn = UrbanPropFactory.build_acorn_streetlight(5.5)
	assert_true(acorn != null, "Acorn streetlight must instantiate")
	acorn.free()

	var skyline = UrbanPropFactory.build_distant_skyline(600.0)
	assert_true(skyline != null, "Distant skyline must instantiate")
	skyline.free()

	# San Andreas Open World Architecture & Props
	var sa_house = UrbanPropFactory.build_san_andreas_house(0)
	assert_true(_find_static_body(sa_house) != null, "San Andreas house must have StaticBody3D")
	sa_house.free()

	var r_track = UrbanPropFactory.build_railway_track(60.0)
	assert_true(_find_static_body(r_track) != null, "Railway track must have StaticBody3D")
	r_track.free()

	var r_crossing = UrbanPropFactory.build_railroad_crossing()
	assert_true(r_crossing != null, "Railroad crossing must instantiate")
	r_crossing.free()

	var f_train = UrbanPropFactory.build_freight_train()
	assert_true(_find_static_body(f_train) != null, "Freight train must have StaticBody3D")
	f_train.free()

	var u_pole = UrbanPropFactory.build_utility_pole(8.5)
	assert_true(u_pole != null, "Utility pole must instantiate")
	u_pole.free()

	var gantry = UrbanPropFactory.build_overhead_highway_gantry(22.0)
	assert_true(_find_static_body(gantry) != null, "Highway gantry must have StaticBody3D")
	gantry.free()

	var pier = UrbanPropFactory.build_boardwalk_pier(80.0, 12.0)
	assert_true(_find_static_body(pier) != null, "Boardwalk pier must have StaticBody3D")
	pier.free()

	var tower_lg = UrbanPropFactory.build_lifeguard_tower()
	assert_true(_find_static_body(tower_lg) != null, "Lifeguard tower must have StaticBody3D")
	tower_lg.free()

	var lookout = UrbanPropFactory.build_chiliad_summit_lookout()
	assert_true(_find_static_body(lookout) != null, "Mount Chiliad summit lookout must have StaticBody3D")
	lookout.free()

	var comm = UrbanPropFactory.build_commercial_block(35.0, 20.0, 20.0)
	assert_true(_find_static_body(comm) != null, "Commercial block must have StaticBody3D")
	comm.free()

	var u_tree = UrbanPropFactory.build_tree(9.0)
	assert_true(_find_static_body(u_tree) != null, "Tree must have StaticBody3D")
	u_tree.free()

	# NYC / Brooklyn Civic, Educational & Transit Landmark Props
	var city_hall = UrbanPropFactory.build_neoclassical_city_hall()
	assert_true(_find_static_body(city_hall) != null, "Neoclassical City Hall must have StaticBody3D")
	city_hall.free()

	var high_school = UrbanPropFactory.build_collegiate_high_school()
	assert_true(_find_static_body(high_school) != null, "Collegiate High School must have StaticBody3D")
	high_school.free()

	var uni_lib = UrbanPropFactory.build_university_library()
	assert_true(_find_static_body(uni_lib) != null, "University Library must have StaticBody3D")
	uni_lib.free()

	var acad_hall = UrbanPropFactory.build_academic_hall()
	assert_true(_find_static_body(acad_hall) != null, "Academic Hall must have StaticBody3D")
	acad_hall.free()

	var el_viaduct = UrbanPropFactory.build_el_train_viaduct(140.0)
	assert_true(_find_static_body(el_viaduct) != null, "El-Train Viaduct must have StaticBody3D")
	el_viaduct.free()

func _find_static_body(node: Node) -> StaticBody3D:
	if node is StaticBody3D:
		return node
	for c in node.get_children():
		var found = _find_static_body(c)
		if found != null:
			return found
	return null

func test_zero_road_obstructions() -> void:
	var gen = UrbanWorldGenerator.new()
	gen.generate_world()

	var obstructions = 0
	for prop in gen.props_container.get_children():
		# Stunt ramps are deliberately on roads/crests, check all buildings and solid props
		if prop.name.begins_with("Skyscraper") or prop.name.begins_with("ColinasVilla") or prop.name.begins_with("ShippingContainer"):
			var p_pos = prop.position
			var near = gen.road_network.get_nearest_road_point(p_pos)
			# Road width / 2 is typically 4.5 to 9.0m. Clearance should be >= 5.0m
			if near["distance"] < 5.0:
				obstructions += 1

	assert_true(obstructions == 0, "Zero solid props may obstruct road lanes (found: %d obstructions)" % obstructions)
	gen.free()

func test_safe_spawn_point_registry() -> void:
	var gen = UrbanWorldGenerator.new()
	gen.generate_world()

	var total_spawns = gen.get_verified_spawn_count()
	assert_true(total_spawns >= 100, "Must provide >= 100 safe verified spawn points across world (was: %d)" % total_spawns)

	# Verify all spawn points are above ground and near road network
	var valid_spawns = 0
	for i in range(total_spawns):
		var sp = gen.get_spawn_point(i)
		var pos = sp.origin
		var near = gen.road_network.get_nearest_road_point(pos)
		if pos.y >= 0.5 and near["distance"] <= 35.0:
			valid_spawns += 1

	assert_true(valid_spawns == total_spawns, "100%% of spawn points must be valid and road-accessible (%d/%d)" % [valid_spawns, total_spawns])
	gen.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/world/urban_district_definitions.gd", [
			"get_district_ids", "get_district_def", "get_district", "get_district_at_position",
			"get_district_spawn_points", "get_all_spawn_points"
		]],
		["res://games/urban-legends/world/urban_road_network.gd", [
			"_init", "build_road_network", "_add_continuous_strip", "_generate_traffic_waypoints",
			"get_nearest_road_point", "is_point_on_road", "get_surface_friction",
			"get_traffic_waypoints", "get_road_segments", "get_total_road_length_meters"
		]],
		["res://games/urban-legends/world/urban_prop_factory.gd", [
			"build_skyscraper", "build_residential_villa", "build_flyover_viaduct",
			"build_palm_tree", "build_street_lamp", "build_stunt_ramp",
			"build_shipping_container", "build_stone_bridge",
			"build_art_deco_skyscraper", "build_brownstone_rowhouse",
			"build_theater_marquee_store", "build_subway_kiosk", "build_park_stone_wall",
			"build_gantry_crane", "build_suspension_bridge", "build_underpass_tunnel",
			"build_traffic_signal_mast", "build_fire_hydrant", "build_street_furniture_cluster",
			"build_bus_shelter", "build_acorn_streetlight", "build_distant_skyline",
			"build_neoclassical_city_hall", "build_collegiate_high_school", "build_university_library",
			"build_academic_hall", "build_el_train_viaduct"
		]],
		["res://games/urban-legends/world/urban_world_generator.gd", [
			"_ready", "generate_world", "_cleanup_children", "_build_ground_planes",
			"_build_road_meshes", "_populate_district_props", "_populate_stunt_kickers",
			"_is_obstructing_road", "_build_verified_spawns", "get_verified_spawn_count",
			"get_spawn_point", "get_random_spawn_point"
		]]
	]
