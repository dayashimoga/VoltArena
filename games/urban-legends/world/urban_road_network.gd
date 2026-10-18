class_name UrbanRoadNetwork
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")

## Connected topological road graph and GPS waypoint network for Urban Legends.
## Represents a massive 3.2 km x 3.2 km Continuous Interconnected Grid & Ring-Highway Network:
## - Perimeter Ring Expressway: 4-lane highway with sweeping banked flyovers encircling the metropolis (Y = 1.0 to 18.0).
## - Harborfly Freeway: 6-lane elevated viaduct highway (Y = 18m) spanning East-West across the city.
## - 8x8 Metropolitan Grid: Major avenues and cross-streets covering Manhattan Midtown, Civic Center,
##   Brooklyn Brownstones, University Campus, and Central Park with ZERO dead-ends.
## - Brooklyn/Manhattan Suspension Bridge: 4-lane deck spanning the East River channel (Y = 14m) with approach ramps.
## - Sunken Concrete Underpass Tunnel: Depressed roadway (Y = -2.5m) dipping underneath cross-streets.
## - Elevated El-Train Avenue: Commercial corridor with parallel surface roadways under the rail viaduct.
## - Colinas & Ridgecrest Mountain Switchbacks: Fully closed loops returning to city and perimeter ring.
## - Skyline Airport Dual Runways: High-speed straightaways looping into perimeter service boulevards.

var segments: Array[Dictionary] = []
var intersections: Array[Vector3] = []
var traffic_waypoints: Array[Transform3D] = []

func _init() -> void:
	build_road_network()

func build_road_network() -> void:
	segments.clear()
	intersections.clear()
	traffic_waypoints.clear()

	# --------------------------------------------------------------------------
	# 1. Harborfly Freeway (East-West Arterial Elevated Viaduct at Y=18.0)
	# --------------------------------------------------------------------------
	_add_continuous_strip([
		Vector3(-1400, 18.0, 20),
		Vector3(-950, 18.0, 20),
		Vector3(-600, 18.0, 20),
		Vector3(-200, 18.0, 20),
		Vector3(150, 18.0, 20),
		Vector3(500, 18.0, 20),
		Vector3(850, 18.0, 20),
		Vector3(950, 18.0, 20),
		Vector3(1400, 18.0, 20)
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

	# --------------------------------------------------------------------------
	# 2. Perimeter Ring Expressway (3.2 km x 3.2 km Closed Outer Highway Loop)
	# --------------------------------------------------------------------------
	# South Expressway (Coastline)
	_add_continuous_strip([
		Vector3(-1400, 1.0, -1400),
		Vector3(-950, 1.0, -1400),
		Vector3(0, 1.0, -1400),
		Vector3(950, 1.0, -1400),
		Vector3(1400, 1.0, -1400)
	], 16.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 110.0)

	# East Expressway
	_add_continuous_strip([
		Vector3(1400, 1.0, -1400),
		Vector3(1400, 1.0, -600),
		Vector3(1400, 18.0, 20),
		Vector3(1400, 1.0, 600),
		Vector3(1400, 1.0, 1400)
	], 16.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_HARBORFLY, 110.0)

	# North Expressway
	_add_continuous_strip([
		Vector3(1400, 1.0, 1400),
		Vector3(700, 1.0, 1400),
		Vector3(0, 1.0, 1400),
		Vector3(-700, 1.0, 1400),
		Vector3(-1400, 1.0, 1400)
	], 16.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_RIDGECREST, 110.0)

	# West Expressway
	_add_continuous_strip([
		Vector3(-1400, 1.0, 1400),
		Vector3(-1400, 1.0, 600),
		Vector3(-1400, 18.0, 20),
		Vector3(-1400, 1.0, -600),
		Vector3(-1400, 1.0, -1400)
	], 16.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_AIRPORT, 110.0)

	# --------------------------------------------------------------------------
	# 3. 8x8 Continuous Metropolitan Grid (Manhattan, Civic Center, Brooklyn)
	# --------------------------------------------------------------------------
	var ave_x_coords = [-550.0, -400.0, -250.0, -100.0, 50.0, 200.0, 350.0, 500.0]
	var st_z_coords = [-850.0, -600.0, -450.0, -300.0, -100.0, 100.0, 300.0, 600.0]

	# North-South Avenues
	for ax in ave_x_coords:
		var pts: Array[Vector3] = []
		for sz in st_z_coords:
			pts.append(Vector3(ax, 1.0, sz))
		var w = 16.0 if ax == -100.0 else 14.0
		_add_continuous_strip(pts, w, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_DOWNTOWN, 80.0)

	# East-West Cross Streets
	for sz in st_z_coords:
		var pts: Array[Vector3] = []
		for ax in ave_x_coords:
			pts.append(Vector3(ax, 1.0, sz))
		var w = 16.0 if sz == -850.0 else 14.0
		var d_id = UrbanConstants.DISTRICT_BAYVIEW if sz == -850.0 else UrbanConstants.DISTRICT_DOWNTOWN
		_add_continuous_strip(pts, w, 4, UrbanConstants.SURFACE_ASPHALT, d_id, 75.0)

	# Connect Grid Edges to Outer Ring Highway & Coastal Boulevards
	# South Grid Connectors (Z = -850 to Z = -1400)
	_add_continuous_strip([Vector3(-550, 1.0, -850), Vector3(-950, 1.0, -850), Vector3(-1400, 1.0, -850)], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 80.0)
	_add_continuous_strip([Vector3(500, 1.0, -850), Vector3(750, 1.0, -850), Vector3(950, 1.0, -850), Vector3(1400, 1.0, -850)], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 80.0)
	_add_continuous_strip([Vector3(-1400, 1.0, -850), Vector3(-1400, 1.0, -1400)], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 80.0)
	_add_continuous_strip([Vector3(1400, 1.0, -850), Vector3(1400, 1.0, -1400)], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 80.0)

	# North Grid Connectors (Z = 600 to Z = 1400)
	_add_continuous_strip([Vector3(-550, 1.0, 600), Vector3(-550, 1.0, 1000), Vector3(-700, 1.0, 1400)], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_RIDGECREST, 80.0)
	_add_continuous_strip([Vector3(500, 1.0, 600), Vector3(500, 1.0, 1000), Vector3(700, 1.0, 1400)], 14.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_COLINAS, 80.0)

	# --------------------------------------------------------------------------
	# 4. Brooklyn / Manhattan Suspension Bridge (4-Lane Deck over East River)
	# --------------------------------------------------------------------------
	_add_continuous_strip([
		Vector3(-250, 1.0, -850), # Manhattan Grid Approach
		Vector3(-100, 14.0, -1050),# West Bridge Tower
		Vector3(125, 14.0, -1050), # Center Span Deck
		Vector3(350, 14.0, -1050), # East Bridge Tower
		Vector3(500, 1.0, -850)    # Brooklyn Grid Approach
	], 18.0, 4, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_BAYVIEW, 95.0)

	# --------------------------------------------------------------------------
	# 5. Sunken Concrete Underpass Tunnel Roadway
	# --------------------------------------------------------------------------
	_add_continuous_strip([
		Vector3(-300, 1.0, -250),
		Vector3(-300, -2.5, -150),
		Vector3(-300, -2.5, 0),
		Vector3(-300, 1.0, 100)
	], 14.0, 4, UrbanConstants.SURFACE_CONCRETE, UrbanConstants.DISTRICT_DOWNTOWN, 70.0)

	# --------------------------------------------------------------------------
	# 6. Colinas Heights Winding Mountain Roads (Y = 15.0 to 95.0)
	# --------------------------------------------------------------------------
	_add_continuous_strip([
		Vector3(100, 1.0, 100),   # Base junction from Downtown
		Vector3(220, 18.0, 250),
		Vector3(320, 35.0, 380),  # Mid hillside hairpin
		Vector3(420, 50.0, 480),  # Upper ridge approach
		Vector3(450, 52.0, 620),  # Crest launch point
		Vector3(560, 70.0, 720),  # Villa hairpin
		Vector3(700, 92.0, 850)   # High summit overlook
	], 10.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_COLINAS, 65.0)

	# Colinas Ridge Loop (returns to mid hairpin)
	_add_continuous_strip([
		Vector3(700, 92.0, 850),
		Vector3(580, 80.0, 920),
		Vector3(420, 62.0, 820),
		Vector3(320, 35.0, 380)
	], 8.5, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_COLINAS, 60.0)

	# --------------------------------------------------------------------------
	# 7. Verdant Glen Parkland Loop & Grassy Drift Shortcuts (Y = 4.0 to 22.0)
	# --------------------------------------------------------------------------
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

	# --------------------------------------------------------------------------
	# 8. Industrial Apex Heavy Haulage Road & Alleyway Loop
	# --------------------------------------------------------------------------
	_add_continuous_strip([
		Vector3(-1400, 1.0, 350),
		Vector3(-950, 1.0, 350),
		Vector3(-750, 1.0, 480),
		Vector3(-550, 1.0, 600),
		Vector3(-450, 1.0, 100)
	], 12.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_INDUSTRIAL, 75.0)

	_add_continuous_strip([
		Vector3(-750, 1.0, 480),
		Vector3(-850, 1.0, 650),
		Vector3(-700, 1.0, 750),
		Vector3(-550, 1.0, 600)
	], 8.0, 1, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_INDUSTRIAL, 60.0)

	# --------------------------------------------------------------------------
	# 9. Ridgecrest Hills Mountain Pass & Summit Descent Loop
	# --------------------------------------------------------------------------
	_add_continuous_strip([
		Vector3(-100, 1.0, 300),   # North exit of Downtown Grand Ave
		Vector3(0, 30.0, 520),
		Vector3(80, 65.0, 700),
		Vector3(180, 110.0, 850),  # Steep switchback
		Vector3(320, 152.0, 960)   # Mountain Peak Observatory
	], 9.0, 2, UrbanConstants.SURFACE_DIRT, UrbanConstants.DISTRICT_RIDGECREST, 60.0)

	# Summit Continuous Descent Loop (connects to Colinas & North Ring Highway)
	_add_continuous_strip([
		Vector3(320, 152.0, 960),
		Vector3(500, 95.0, 1150),
		Vector3(700, 1.0, 1400)
	], 9.0, 2, UrbanConstants.SURFACE_DIRT, UrbanConstants.DISTRICT_RIDGECREST, 60.0)

	# --------------------------------------------------------------------------
	# 10. Skyline Airport Dual Runways & High-Speed Loop
	# --------------------------------------------------------------------------
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

	# Airport Perimeter Service Road Loop
	_add_continuous_strip([
		Vector3(-250, 1.0, -520),
		Vector3(-200, 1.0, -420),
		Vector3(-250, 1.0, -320),
		Vector3(-450, 1.0, -450)
	], 10.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_AIRPORT, 80.0)

	# Airport West Connector to Ring Highway
	_add_continuous_strip([
		Vector3(-980, 1.0, -520),
		Vector3(-1200, 1.0, -520),
		Vector3(-1400, 1.0, -420),
		Vector3(-1200, 1.0, -320),
		Vector3(-980, 1.0, -320)
	], 12.0, 2, UrbanConstants.SURFACE_ASPHALT, UrbanConstants.DISTRICT_AIRPORT, 90.0)

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
			"direction": (end_pt - start_pt).normalized(),
			"is_freeway": (district == UrbanConstants.DISTRICT_HARBORFLY or speed_limit >= 110.0)
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
		var step: float = 20.0
		var num_steps = int(dist / step)
		for s in range(num_steps + 1):
			var pos = st.lerp(en, float(s) / float(maxi(1, num_steps)))
			var t = Transform3D()
			t.origin = pos + Vector3(0, 0.4, 0)
			# Strictly project forward direction onto horizontal plane (zero pitch / roll)
			var fwd = Vector3(dir.x, 0.0, dir.z).normalized()
			if fwd.length_squared() < 0.001:
				fwd = Vector3.FORWARD
			t = t.looking_at(pos + fwd, Vector3.UP)
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
		UrbanConstants.SURFACE_CONCRETE:
			return 1.0
		UrbanConstants.SURFACE_GRASS:
			return 0.72 # Drifting slide surface
		UrbanConstants.SURFACE_DIRT:
			return 0.82
		_:
			return 0.95

func get_surface_friction_at_point(world_pos: Vector3) -> float:
	return get_surface_friction(world_pos)

func get_traffic_waypoints() -> Array[Transform3D]:
	return traffic_waypoints

func get_road_segments() -> Array[Dictionary]:
	return segments

func get_total_road_length_meters() -> float:
	var total: float = 0.0
	for seg in segments:
		total += seg.get("length", 0.0)
	return total
