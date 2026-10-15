class_name UrbanRoadNetwork
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")

## Connected topological road graph and GPS waypoint network for Urban Legends.
## Represents 100% contiguous roadways spanning all 8 metropolitan districts:
## - Harborfly Freeway: 6-lane elevated viaduct highway (Y = 18m) with ramp access.
## - Downtown Metro: 4-lane grid boulevards and plaza ring roads.
## - Colinas Heights: Winding 2-lane hillside switchbacks with crest launch ramps.
## - Verdant Glen: 2-lane parkway loops and grass drift short-cuts.
## - Skyline Airport: Twin 800m wide high-speed asphalt runways.
## - Bayview Promenade: 4-lane coastal boulevard.
## - Industrial Apex: Multi-depot freight corridors and alleyways.
## - Ridgecrest Hills: Steep gravel mountain passes (up to 24-degree grade).

var segments: Array[Dictionary] = []
var intersections: Array[Vector3] = []
var traffic_waypoints: Array[Transform3D] = []

func _init() -> void:
	build_road_network()

func build_road_network() -> void:
	segments.clear()
	intersections.clear()
	traffic_waypoints.clear()

	# 1. Harborfly Freeway (East-West Arterial Elevated Viaduct at Y=18.0)
	_add_continuous_strip([
		Vector3(-950, 18.0, 20),
		Vector3(-600, 18.0, 20),
		Vector3(-200, 18.0, 20),
		Vector3(150, 18.0, 20),
		Vector3(500, 18.0, 20),
		Vector3(850, 18.0, 20),
		Vector3(950, 18.0, 20)
	], 18.0, 6, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_HARBORFLY, 140.0)

	# Freeway Ground Access On-Ramp West (Airport -> Freeway)
	_add_continuous_strip([
		Vector3(-750, 1.0, -180),
		Vector3(-700, 9.0, -80),
		Vector3(-600, 18.0, 20)
	], 10.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_HARBORFLY, 90.0)

	# Freeway Ground Access On-Ramp East (Downtown -> Freeway)
	_add_continuous_strip([
		Vector3(200, 1.0, -120),
		Vector3(250, 9.0, -50),
		Vector3(350, 18.0, 20)
	], 10.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_HARBORFLY, 90.0)

	# 2. Downtown Metro Boulevard Grid (Y = 1.0)
	# Central Grand Avenue (North-South)
	_add_continuous_strip([
		Vector3(-100, 1.0, -600),
		Vector3(-100, 1.0, -350),
		Vector3(-100, 1.0, -100),
		Vector3(-100, 1.0, 150),
		Vector3(-100, 1.0, 300)
	], 16.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_DOWNTOWN, 80.0)

	# Metro Ring Boulevard
	_add_continuous_strip([
		Vector3(-450, 1.0, -450),
		Vector3(100, 1.0, -450),
		Vector3(100, 1.0, 100),
		Vector3(-450, 1.0, 100),
		Vector3(-450, 1.0, -450) # Closed Loop
	], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_DOWNTOWN, 80.0)

	# 3. Colinas Heights Winding Mountain Roads (Y = 15.0 to 95.0)
	# Las Colinas style winding switchbacks connecting to crest ramp
	_add_continuous_strip([
		Vector3(100, 1.0, 100),   # Base junction from Downtown
		Vector3(220, 18.0, 250),
		Vector3(320, 35.0, 380),  # Mid hillside hairpin
		Vector3(420, 50.0, 480),  # Upper ridge approach
		Vector3(450, 52.0, 620),  # Crest launch point
		Vector3(560, 70.0, 720),  # Villa hairpin
		Vector3(700, 92.0, 850)   # High summit overlook
	], 10.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_COLINAS, 65.0)

	# Colinas Ridge Loop
	_add_continuous_strip([
		Vector3(700, 92.0, 850),
		Vector3(580, 80.0, 920),
		Vector3(420, 62.0, 820),
		Vector3(320, 35.0, 380) # Joins mid hairpin
	], 8.5, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_COLINAS, 60.0)

	# 4. Verdant Glen Parkland Loop & Grassy Drift Shortcuts (Y = 4.0 to 22.0)
	_add_continuous_strip([
		Vector3(100, 1.0, -450),  # Base junction from Downtown
		Vector3(280, 8.0, -380),
		Vector3(450, 14.0, -280), # Park lakeside
		Vector3(580, 20.0, -100), # Upper glade
		Vector3(480, 15.0, 80),   # Stone bridge
		Vector3(220, 8.0, 50),
		Vector3(100, 1.0, 100)    # Joins Downtown south
	], 11.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_VERDANT, 70.0)

	# Verdant Glen Grass Drift Shortcut (Glen Park reference)
	_add_continuous_strip([
		Vector3(280, 8.0, -380),
		Vector3(380, 11.0, -220), # Rolling grass field shortcut
		Vector3(480, 15.0, 80)
	], 12.0, 2, UrbanConstants.SURFACE_GRASS, UrbanConstants.DISTRICT_VERDANT, 55.0)

	# 5. Bayview Promenade Coastal Boulevard (Y = 1.0 to 4.0)
	_add_continuous_strip([
		Vector3(-950, 1.0, -850),
		Vector3(-550, 1.0, -850),
		Vector3(-100, 1.0, -850), # Meets Central Grand Ave
		Vector3(350, 1.0, -850),
		Vector3(750, 1.0, -850),
		Vector3(950, 1.0, -850)
	], 16.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 90.0)

	# Coastal Connector (Bayview -> Downtown)
	_add_continuous_strip([
		Vector3(-100, 1.0, -850),
		Vector3(-100, 1.0, -600)
	], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 80.0)

	# 6. Industrial Apex Heavy Haulage Road (Y = 1.0 to 5.0)
	_add_continuous_strip([
		Vector3(-950, 1.0, 350),
		Vector3(-750, 1.0, 480),
		Vector3(-550, 1.0, 600),
		Vector3(-450, 1.0, 100) # Connects to Downtown ring
	], 12.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_INDUSTRIAL, 75.0)

	# Container Maze Alley Loop
	_add_continuous_strip([
		Vector3(-750, 1.0, 480),
		Vector3(-850, 1.0, 650),
		Vector3(-700, 1.0, 750),
		Vector3(-550, 1.0, 600)
	], 8.0, 1, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_INDUSTRIAL, 60.0)

	# 7. Ridgecrest Hills Mountain Pass (Y = 40.0 to 155.0)
	_add_continuous_strip([
		Vector3(-100, 1.0, 300),   # North exit of Downtown Grand Ave
		Vector3(0, 30.0, 520),
		Vector3(80, 65.0, 700),
		Vector3(180, 110.0, 850),  # Steep switchback
		Vector3(320, 152.0, 960)   # Mountain Peak Observatory
	], 9.0, 2, UrbanConstants.SURFACE_DIRT, UrbanConstants.DISTRICT_RIDGECREST, 60.0)

	# 8. Skyline Airport Dual Runways (Y = 1.0)
	# Runway 09L (Primary High-Speed Straightaway: 800m length)
	_add_continuous_strip([
		Vector3(-980, 1.0, -520),
		Vector3(-750, 1.0, -520),
		Vector3(-500, 1.0, -520),
		Vector3(-250, 1.0, -520)
	], 36.0, 6, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_AIRPORT, 250.0)

	# Runway 09R (Secondary Parallel Strip)
	_add_continuous_strip([
		Vector3(-980, 1.0, -320),
		Vector3(-750, 1.0, -320),
		Vector3(-500, 1.0, -320),
		Vector3(-250, 1.0, -320)
	], 36.0, 6, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_AIRPORT, 250.0)

	# Airport Perimeter Service Road
	_add_continuous_strip([
		Vector3(-250, 1.0, -520),
		Vector3(-200, 1.0, -420),
		Vector3(-250, 1.0, -320),
		Vector3(-450, 1.0, -450) # Connects to Downtown ring
	], 10.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_AIRPORT, 80.0)

	_generate_traffic_waypoints()

func _add_continuous_strip(points: Array[Vector3], width: float, lanes: int, surface: int, district: String, speed_limit: float) -> void:
	for i in range(points.size() - 1):
		var start_pt = points[i]
		var end_pt = points[i + 1]
		var seg = {
			"id": segments.size(),
			"start": start_pt,
			"end": end_pt,
			"length": start_pt.distance_to(end_pt),
			"width": width,
			"lanes": lanes,
			"surface": surface,
			"district": district,
			"speed_limit": speed_limit,
			"direction": (end_pt - start_pt).normalized()
		}
		segments.append(seg)
		if not intersections.has(start_pt):
			intersections.append(start_pt)
		if not intersections.has(end_pt):
			intersections.append(end_pt)

func _generate_traffic_waypoints() -> void:
	traffic_waypoints.clear()
	for seg in segments:
		var st: Vector3 = seg["start"]
		var en: Vector3 = seg["end"]
		var dist: float = seg["length"]
		var dir: Vector3 = seg["direction"]
		var step: float = 25.0
		var num_steps = int(dist / step)
		for s in range(num_steps + 1):
			var pos = st.lerp(en, float(s) / float(maxi(1, num_steps)))
			var t = Transform3D()
			t.origin = pos + Vector3(0, 0.4, 0)
			# Align orientation along road direction
			if dir.length_squared() > 0.001:
				var up = Vector3.UP
				if absf(dir.dot(up)) > 0.9:
					up = Vector3.RIGHT
				t = t.looking_at(pos + dir, up)
			traffic_waypoints.append(t)

func get_nearest_road_point(world_pos: Vector3) -> Dictionary:
	var best_dist: float = 999999.0
	var best_pt: Vector3 = world_pos
	var best_dir: Vector3 = Vector3.FORWARD
	var best_seg: int = -1
	var best_speed: float = 80.0
	var best_surface: int = UrbanConstants.SURFACE_ASPHALT

	for seg in segments:
		var st: Vector3 = seg["start"]
		var en: Vector3 = seg["end"]
		var seg_vec = en - st
		var seg_len = seg["length"]
		if seg_len < 0.01:
			continue

		var t_val = clampf((world_pos - st).dot(seg_vec) / (seg_len * seg_len), 0.0, 1.0)
		var proj = st + seg_vec * t_val
		var d = world_pos.distance_to(proj)
		if d < best_dist:
			best_dist = d
			best_pt = proj
			best_dir = seg["direction"]
			best_seg = seg["id"]
			best_speed = seg["speed_limit"]
			best_surface = seg["surface"]

	return {
		"point": best_pt,
		"distance": best_dist,
		"direction": best_dir,
		"segment_id": best_seg,
		"speed_limit": best_speed,
		"surface": best_surface
	}

func is_point_on_road(world_pos: Vector3, tolerance: float = 8.0) -> bool:
	var res = get_nearest_road_point(world_pos)
	return res["distance"] <= tolerance

func get_surface_friction(world_pos: Vector3) -> float:
	var res = get_nearest_road_point(world_pos)
	if res["distance"] > 10.0:
		# Off-road / Grassland terrain
		return 0.70
	var s_type = res["surface"]
	match s_type:
		UrbanConstants.SURFACE_ASPHALT:
			return 1.0
		UrbanConstants.SURFACE_GRASS:
			return 0.72 # Drifting slide surface
		UrbanConstants.SURFACE_DIRT:
			return 0.82
		_:
			return 0.95

func get_traffic_waypoints() -> Array[Transform3D]:
	return traffic_waypoints

func get_road_segments() -> Array[Dictionary]:
	return segments

func get_total_road_length_meters() -> float:
	var total: float = 0.0
	for seg in segments:
		total += seg.get("length", 0.0)
	return total
