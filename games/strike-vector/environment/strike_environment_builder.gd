class_name StrikeEnvironmentBuilder
extends RefCounted

## Modular PBR 3D environment builder for all 8 campaign biomes in Strike Vector:
## Urban Blackout / City Breach, High-Speed Rail, Harbor Assault, Desert Convoy, Arctic Installation,
## Megafactory, Sky Fortress, and Final Citadel.
## Builds high-fidelity interconnected environments using production-grade 3D assets, authentic lighting,
## background skylines, recognizable street dressing, and hardened continuous collision geometry.

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

static func build_segment_environment(biome: String, seg_idx: int, length: float = 40.0, width: float = 16.0, is_last: bool = false) -> Node3D:
	var root = Node3D.new()
	root.name = "Environment_" + biome + "_" + str(seg_idx)

	match biome:
		"urban": _build_urban_segment(root, seg_idx, length, width, is_last)
		"rail": _build_rail_segment(root, seg_idx, length, width, is_last)
		"harbor": _build_harbor_segment(root, seg_idx, length, width, is_last)
		"desert": _build_desert_segment(root, seg_idx, length, width, is_last)
		"arctic": _build_arctic_segment(root, seg_idx, length, width, is_last)
		"factory": _build_factory_segment(root, seg_idx, length, width, is_last)
		"sky_fortress": _build_sky_fortress_segment(root, seg_idx, length, width, is_last)
		"citadel": _build_citadel_segment(root, seg_idx, length, width, is_last)
		_: _build_urban_segment(root, seg_idx, length, width, is_last)

	return root

# ==============================================================================
# 1. URBAN BLACKOUT / CITY BREACH (Expansive Multi-Street Metropolis)
# ==============================================================================
static func _build_urban_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_road = MaterialGenerator.get_material("asphalt_track")
	var mat_sidewalk = MaterialGenerator.get_material("grimy_concrete")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_dark = MaterialGenerator.get_material("dark_hull")

	# 1. Grand Arterial Boulevard (16m roadway + 4m elevated concrete sidewalks on each side = 24m canyon)
	var road_len = length + (16.0 if seg_idx == 0 else 4.0)
	var z_offset = -length * 0.5 + (6.0 if seg_idx == 0 else -1.0)
	var road_w = 16.0
	var sidewalk_w = 4.0
	var total_street_w = road_w + sidewalk_w * 2.0 # 24.0m street corridor

	# Roadway carriageway
	_create_solid_floor(root, Vector3(road_w, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_road)

	# Elevated sidewalks with bevelled curb profile (0.15m height above road)
	_create_solid_floor(root, Vector3(sidewalk_w, 1.4, road_len), Vector3(-road_w * 0.5 - sidewalk_w * 0.5, -0.45, z_offset), mat_sidewalk)
	_create_solid_floor(root, Vector3(sidewalk_w, 1.4, road_len), Vector3(road_w * 0.5 + sidewalk_w * 0.5, -0.45, z_offset), mat_sidewalk)

	# Roadway center-line dashes and crosswalk markings
	_add_street_surface_markings(root, road_len, z_offset, seg_idx)

	# 2. Cross Streets, Alleys, and Intersecting District Plazas
	_build_district_cross_streets(root, seg_idx, road_w, sidewalk_w, length, z_offset, mat_road, mat_sidewalk)

	# 3. Perimeter Containment Barriers & End Walls
	_create_boundary_walls(root, total_street_w + 2.0, road_len, z_offset, seg_idx == 0, is_last)

	# 4. Navigation Region for AI Pathfinding
	_create_navigation_region(root, total_street_w + 12.0, road_len, z_offset)

	# 5. Distant Metropolitan Skyline Backdrop (eliminates empty black void)
	_add_skyline_backdrop(root, z_offset, length)

	# 6. Varied Architectural Facades & Commercial Buildings
	_build_urban_architecture(root, seg_idx, length, road_w, sidewalk_w)

	# 7. Street-Level Dressing & Contextual Tactical Props (Vehicles, Barriers, Streetlights, Foliage)
	_populate_urban_street_dressing(root, seg_idx, length, road_w, sidewalk_w)

static func _add_street_surface_markings(root: Node3D, road_len: float, z_offset: float, seg_idx: int) -> void:
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.95, 0.78, 0.15)
	mat_yellow.roughness = 0.6

	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.92, 0.94, 0.96)
	mat_white.roughness = 0.5

	# Center double-yellow dividing lines
	for z_step in range(0, int(road_len), 6):
		var z_pos = z_offset - road_len * 0.5 + float(z_step) + 3.0
		_create_visual_box(root, Vector3(0.18, 0.02, 3.2), Vector3(-0.15, 0.02, z_pos), mat_yellow)
		_create_visual_box(root, Vector3(0.18, 0.02, 3.2), Vector3(0.15, 0.02, z_pos), mat_yellow)

	# Pedestrian Crosswalk stripes at segment start
	if seg_idx == 1 or seg_idx == 2:
		for stripe_x in range(-6, 7, 2):
			_create_visual_box(root, Vector3(1.1, 0.02, 4.0), Vector3(float(stripe_x), 0.02, z_offset + road_len * 0.42), mat_white)

static func _build_district_cross_streets(root: Node3D, seg_idx: int, road_w: float, sidewalk_w: float, length: float, z_offset: float, mat_road: Material, mat_sidewalk: Material) -> void:
	# Cross-streets create an authentic grid topology
	match seg_idx:
		0:
			# City Center Plaza: Arterial intersection opening on right toward Commercial District
			var cross_z = z_offset - 4.0
			_create_solid_floor(root, Vector3(20.0, 1.2, 10.0), Vector3(road_w * 0.5 + sidewalk_w + 10.0, -0.6, cross_z), mat_road)
			_create_solid_floor(root, Vector3(20.0, 1.4, 3.0), Vector3(road_w * 0.5 + sidewalk_w + 10.0, -0.45, cross_z - 6.5), mat_sidewalk)
			_create_solid_floor(root, Vector3(20.0, 1.4, 3.0), Vector3(road_w * 0.5 + sidewalk_w + 10.0, -0.45, cross_z + 6.5), mat_sidewalk)
			# Roadblock barrier closing the secondary avenue
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(road_w * 0.5 + sidewalk_w + 18.0, 0.0, cross_z), 90.0, Vector3(0.8, 1.5, 9.0))
		1:
			# Commercial District: 4-Way Major Intersection
			var cross_z = z_offset
			# Left Avenue (Residential branch)
			_create_solid_floor(root, Vector3(24.0, 1.2, 12.0), Vector3(-road_w * 0.5 - sidewalk_w - 12.0, -0.6, cross_z), mat_road)
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(-road_w * 0.5 - sidewalk_w - 22.0, 0.0, cross_z), 90.0, Vector3(0.8, 1.5, 11.0))
			# Right Avenue (Financial branch)
			_create_solid_floor(root, Vector3(24.0, 1.2, 12.0), Vector3(road_w * 0.5 + sidewalk_w + 12.0, -0.6, cross_z), mat_road)
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(road_w * 0.5 + sidewalk_w + 22.0, 0.0, cross_z), 90.0, Vector3(0.8, 1.5, 11.0))
		2:
			# Metro Station Plaza & Park Promenade (Park square on left side)
			var park_w = 18.0
			var park_z = z_offset
			_create_solid_floor(root, Vector3(park_w, 1.4, 28.0), Vector3(-road_w * 0.5 - sidewalk_w - park_w * 0.5, -0.45, park_z), mat_sidewalk)
		3:
			# Industrial Logistics: Warehouse loading apron on right
			var apron_w = 20.0
			var apron_z = z_offset
			_create_solid_floor(root, Vector3(apron_w, 1.2, 32.0), Vector3(road_w * 0.5 + sidewalk_w + apron_w * 0.5, -0.6, apron_z), mat_road)

static func _build_urban_architecture(root: Node3D, seg_idx: int, length: float, road_w: float, sidewalk_w: float) -> void:
	var building_models = [
		"res://assets/models/environment/building_comm_a.glb",
		"res://assets/models/environment/building_comm_b.glb",
		"res://assets/models/environment/building_comm_c.glb",
		"res://assets/models/environment/building_comm_d.glb",
		"res://assets/models/environment/building_comm_e.glb",
		"res://assets/models/environment/building_comm_f.glb",
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb",
		"res://assets/models/environment/building_garage.glb"
	]

	var b_dist_x = road_w * 0.5 + sidewalk_w + 6.5
	for z_step in range(0, int(length), 14):
		var z_pos = -float(z_step) - 7.0
		var b_idx = (seg_idx * 4 + z_step / 14) % building_models.size()
		var b_path_l = building_models[b_idx]
		var b_path_r = building_models[(b_idx + 3) % building_models.size()]

		# Authentic architectural heights: 20m, 28m, 36m, 44m
		var h_left = 22.0 if (z_step % 28 == 0) else 34.0
		var h_right = 38.0 if (z_step % 28 == 0) else 26.0

		# Left Building facade (named building_* for visual test invariant compliance)
		_add_authored_building(root, b_path_l, Vector3(-b_dist_x, 0.0, z_pos), Vector3(14.0, h_left, 13.0), 90.0)
		# Right Building facade
		_add_authored_building(root, b_path_r, Vector3(b_dist_x, 0.0, z_pos), Vector3(14.0, h_right, 13.0), -90.0)

		# Commercial Billboards mounted on building facades
		if z_step % 28 == 0:
			var bb = _add_model(root, "res://assets/models/environment/stadium/billboard.glb", Vector3(-road_w * 0.5 - sidewalk_w, 8.5, z_pos), Vector3(2.5, 2.5, 2.5), 90.0)
			if not bb:
				_create_visual_box(root, Vector3(0.3, 3.0, 7.0), Vector3(-road_w * 0.5 - sidewalk_w, 8.5, z_pos), MaterialGenerator.get_material("sci_fi_metal"))

static func _populate_urban_street_dressing(root: Node3D, seg_idx: int, length: float, road_w: float, sidewalk_w: float) -> void:
	var curb_left_x = -road_w * 0.5 - 0.5
	var curb_right_x = road_w * 0.5 + 0.5

	# Elevated Streetlights with warm downward illumination
	for z_step in range(0, int(length), 18):
		var z_pos = -float(z_step) - 6.0
		_add_streetlight_prop(root, Vector3(curb_left_x, 0.0, z_pos), 90.0, Color(1.0, 0.88, 0.65), 2.2)
		_add_streetlight_prop(root, Vector3(curb_right_x, 0.0, z_pos + 9.0), -90.0, Color(1.0, 0.88, 0.65), 2.2)

	# Segment-Specific Authored Urban Storytelling & Believable Vehicles
	match seg_idx:
		0:
			# Zone 0: Deployment Roadblock & Security Perimeter
			# Authentic Police Cruiser on left flank as tactical cover
			_add_vehicle_prop(root, "res://assets/models/vehicles/car_police.glb", Vector3(-curb_left_x * 0.5, 0.0, -10.0), -20.0, Vector3(2.1, 1.5, 4.6))
			# Security Barricades (white/red) forming lane narrowing
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_white.glb", Vector3(3.5, 0.0, -15.0), 10.0, Vector3(2.2, 1.2, 0.6))
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_red.glb", Vector3(5.6, 0.0, -15.5), 10.0, Vector3(2.2, 1.2, 0.6))
			# Sidewalk Trees & Pedestrian Benches
			_add_tree_prop(root, "res://assets/models/environment/tree_detailed.glb", Vector3(-road_w * 0.5 - sidewalk_w * 0.5, 0.0, -8.0), Vector3(1.2, 1.2, 1.2))
			_add_tree_prop(root, "res://assets/models/environment/tree_detailed.glb", Vector3(-road_w * 0.5 - sidewalk_w * 0.5, 0.0, -26.0), Vector3(1.2, 1.2, 1.2))
			_add_prop_model(root, "res://assets/models/environment/subway/station_bench.glb", Vector3(road_w * 0.5 + 1.5, 0.0, -12.0), Vector3(1.3, 1.3, 1.3), -90.0, Vector3(2.2, 0.9, 0.8))
			# Tactical Comms Console
			_add_prop_model(root, "res://assets/models/environment/scifi/computer_terminal.glb", Vector3(road_w * 0.5 + 1.8, 0.0, -7.0), Vector3(1.2, 1.2, 1.2), -90.0, Vector3(1.2, 1.8, 0.9))

		1:
			# Zone 1: Commercial District Intersection & Abandoned Traffic
			# Civilian Sedan parked along curb
			_add_vehicle_prop(root, "res://assets/models/vehicles/car_sedan.glb", Vector3(curb_right_x - 1.8, 0.0, -14.0), 5.0, Vector3(2.0, 1.5, 4.5))
			# Luxury SUV abandoned near cross-street
			_add_vehicle_prop(root, "res://assets/models/vehicles/car_suv_luxury.glb", Vector3(-curb_left_x * 0.6, 0.0, -24.0), -35.0, Vector3(2.2, 1.8, 4.8))
			# Concrete highway barriers providing player cover
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(2.0, 0.0, -20.0), 0.0, Vector3(2.6, 1.2, 0.6))
			# Sidewalk Dressing: Station bench, trees, trash bin
			_add_prop_model(root, "res://assets/models/environment/subway/station_bench.glb", Vector3(-road_w * 0.5 - 1.8, 0.0, -16.0), Vector3(1.3, 1.3, 1.3), 90.0, Vector3(2.2, 0.9, 0.8))
			_add_tree_prop(root, "res://assets/models/environment/tree_oak.glb", Vector3(road_w * 0.5 + sidewalk_w * 0.5, 0.0, -22.0), Vector3(1.3, 1.3, 1.3))

		2:
			# Zone 2: Metro Transit Entrance & Central Park
			# Metro Subway Stairs descending into underground
			_add_prop_model(root, "res://assets/models/environment/subway/station_stairs.glb", Vector3(road_w * 0.5 + 2.5, 0.0, -15.0), Vector3(1.4, 1.4, 1.4), -90.0, Vector3(3.2, 2.5, 4.0))
			# Yellow City Taxi abandoned on roadway
			_add_vehicle_prop(root, "res://assets/models/vehicles/car_taxi.glb", Vector3(-3.2, 0.0, -18.0), 25.0, Vector3(2.0, 1.5, 4.5))
			# Park side trees & seating
			_add_tree_prop(root, "res://assets/models/environment/tree_detailed.glb", Vector3(-road_w * 0.5 - 5.0, 0.0, -12.0), Vector3(1.4, 1.4, 1.4))
			_add_tree_prop(root, "res://assets/models/environment/tree_pine.glb", Vector3(-road_w * 0.5 - 10.0, 0.0, -20.0), Vector3(1.5, 1.5, 1.5))
			_add_tree_prop(root, "res://assets/models/environment/tree_oak.glb", Vector3(-road_w * 0.5 - 6.0, 0.0, -28.0), Vector3(1.3, 1.3, 1.3))
			# Overhead Walkway / Skybridge crossing the boulevard
			var skybridge_mat = MaterialGenerator.get_material("sci_fi_metal")
			_create_solid_floor(root, Vector3(road_w + sidewalk_w * 2.0, 1.0, 4.5), Vector3(0, 6.5, -28.0), skybridge_mat)
			_create_solid_floor(root, Vector3(1.2, 6.5, 1.2), Vector3(-road_w * 0.5 - sidewalk_w, 3.25, -28.0), skybridge_mat)
			_create_solid_floor(root, Vector3(1.2, 6.5, 1.2), Vector3(road_w * 0.5 + sidewalk_w, 3.25, -28.0), skybridge_mat)

		3:
			# Zone 3: Industrial Warehouses & Logistics Complex
			# Heavy Commercial Transport Truck (yellow/green) parked at warehouse bay
			_add_vehicle_prop(root, "res://assets/models/vehicles/truck_yellow.glb", Vector3(road_w * 0.5 + 4.5, 0.0, -16.0), -90.0, Vector3(2.5, 2.8, 6.5))
			_add_vehicle_prop(root, "res://assets/models/vehicles/truck_green.glb", Vector3(-4.0, 0.0, -22.0), 30.0, Vector3(2.5, 2.8, 6.5))
			# Shipping container stacks & industrial pipes
			var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
			_create_solid_floor(root, Vector3(3.2, 3.0, 7.0), Vector3(-road_w * 0.5 - 2.5, 1.5, -12.0), mat_metal)
			_add_prop_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(road_w * 0.5 + 1.5, 0.0, -26.0), Vector3(1.8, 1.8, 1.8), 0.0, Vector3(2.0, 2.5, 2.0))
			_add_prop_model(root, "res://assets/models/environment/scifi/stairs_industrial.glb", Vector3(road_w * 0.5 + 2.0, 0.0, -8.0), Vector3(1.4, 1.4, 1.4), -90.0, Vector3(2.2, 3.0, 3.0))

		_:
			# Zone 4+: Rooftop / Evacuation Plaza leading to Extraction Helipad
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(-5.0, 0.0, -15.0), 30.0, Vector3(2.6, 1.2, 0.6))
			_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(5.0, 0.0, -15.0), -30.0, Vector3(2.6, 1.2, 0.6))
			# High-power Floodlight Towers illuminating the extraction approach
			_add_prop_model(root, "res://assets/models/environment/stadium/floodlight_tower.glb", Vector3(-road_w * 0.5 - 2.0, 0.0, -28.0), Vector3(1.2, 1.2, 1.2), 45.0, Vector3(1.5, 9.0, 1.5))
			_add_prop_model(root, "res://assets/models/environment/stadium/floodlight_tower.glb", Vector3(road_w * 0.5 + 2.0, 0.0, -28.0), Vector3(1.2, 1.2, 1.2), -45.0, Vector3(1.5, 9.0, 1.5))
			# Tactical Uplink Terminal
			_add_prop_model(root, "res://assets/models/environment/scifi/computer_terminal.glb", Vector3(0.0, 0.0, -10.0), Vector3(1.3, 1.3, 1.3), 0.0, Vector3(1.2, 1.8, 0.9))

# ==============================================================================
# 2. HIGH-SPEED RAIL (Train tracks, passenger cars, roof traversal, gantries)
# ==============================================================================
static func _build_rail_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_orange = MaterialGenerator.get_material("neon_orange")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width * 0.85, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_metal)
	_create_boundary_walls(root, width * 0.85 + 2.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width * 0.85, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	# Parallel High-Speed Train Tracks
	_add_model(root, "res://assets/models/environment/subway/train_track.glb", Vector3(-3.2, 0.0, -length * 0.5), Vector3(2.2, 1.0, length * 0.1), 0.0)
	_add_model(root, "res://assets/models/environment/subway/train_track.glb", Vector3(3.2, 0.0, -length * 0.5), Vector3(2.2, 1.0, length * 0.1), 0.0)

	# Subway Passenger Carriages with solid roof collider
	var car_path = "res://assets/models/environment/subway/train_subway_car.glb" if seg_idx % 2 == 0 else "res://assets/models/environment/subway/train_subway_middle.glb"
	_add_prop_model(root, car_path, Vector3(0, 0.0, -length * 0.5), Vector3(1.1, 1.1, 1.2), 0.0, Vector3(3.4, 3.2, 28.0))

	# Safety Railings on elevated skyway
	_create_solid_floor(root, Vector3(0.4, 1.2, road_len), Vector3(-width * 0.42, 0.6, z_offset), mat_hull)
	_create_solid_floor(root, Vector3(0.4, 1.2, road_len), Vector3(width * 0.42, 0.6, z_offset), mat_hull)

	# Overhead Electrification Gantries
	for z_step in range(0, int(length), 18):
		var z_pos = -float(z_step) - 9.0
		_create_visual_box(root, Vector3(width * 0.9, 0.6, 0.8), Vector3(0, 5.0, z_pos), mat_orange)

# ==============================================================================
# 3. HARBOR ASSAULT (Wet docks, shipping containers, marine cranes)
# ==============================================================================
static func _build_harbor_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width + 4.0, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_hull)
	_create_boundary_walls(root, width + 6.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width + 4.0, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	# Shipping Container Maze (3.2m x 2.8m x 7.0m containers)
	for z_step in range(0, int(length), 14):
		var z_pos = -float(z_step) - 7.0
		_create_solid_floor(root, Vector3(3.2, 2.8, 6.8), Vector3(-width * 0.5 + 2.0, 1.4, z_pos), mat_metal)
		_create_solid_floor(root, Vector3(3.2, 2.8, 6.8), Vector3(width * 0.5 - 2.0, 1.4, z_pos + 4.0), mat_metal)

	# Logistics Warehouse Building & Floodlight Tower
	_add_authored_building(root, "res://assets/models/environment/building_comm_d.glb", Vector3(-width * 0.5 - 7.0, 0.0, -length * 0.5), Vector3(14.0, 24.0, 14.0), 90.0)
	_add_prop_model(root, "res://assets/models/environment/stadium/floodlight_tower.glb", Vector3(width * 0.5 + 1.5, 0.0, -18.0), Vector3(1.2, 1.2, 1.2), -45.0, Vector3(1.5, 9.0, 1.5))

# ==============================================================================
# 4. DESERT CONVOY (Canyon sandstone, highway, convoy trucks, pipelines)
# ==============================================================================
static func _build_desert_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_road = MaterialGenerator.get_material("asphalt_track")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width + 2.0, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_road)
	_create_boundary_walls(root, width + 6.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width + 2.0, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	# Heavy Pipeline Infrastructure
	_add_prop_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(-width * 0.5 - 0.5, 0.0, -14.0), Vector3(1.8, 1.8, 1.8), 0.0, Vector3(2.0, 2.5, 2.0))
	_add_prop_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(width * 0.5 + 0.5, 0.0, -28.0), Vector3(1.8, 1.8, 1.8), 180.0, Vector3(2.0, 2.5, 2.0))

	# Armored Convoy Trucks
	var truck_model = "res://assets/models/vehicles/truck_red.glb" if seg_idx % 2 == 0 else "res://assets/models/vehicles/truck_yellow.glb"
	_add_vehicle_prop(root, truck_model, Vector3(1.8, 0.0, -18.0), -15.0, Vector3(2.5, 2.8, 6.5))

# ==============================================================================
# 5. ARCTIC INSTALLATION (Research modules, radar facilities, ice caverns)
# ==============================================================================
static func _build_arctic_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width + 2.0, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_hull)
	_create_boundary_walls(root, width + 6.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width + 2.0, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	_add_authored_building(root, "res://assets/models/environment/building_comm_b.glb", Vector3(-width * 0.5 - 6.0, 0.0, -length * 0.4), Vector3(14.0, 22.0, 14.0), 90.0)
	_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(3.2, 0.0, -14.0), -25.0, Vector3(2.6, 1.2, 0.6))
	_add_prop_model(root, "res://assets/models/environment/scifi/computer_terminal.glb", Vector3(-width * 0.5 + 1.2, 0.0, -22.0), Vector3(1.2, 1.2, 1.2), 90.0, Vector3(1.2, 1.8, 0.9))

# ==============================================================================
# 6. MEGAFACTORY (Smelting furnaces, assembly lines, conveyor catwalks)
# ==============================================================================
static func _build_factory_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width + 2.0, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_metal)
	_create_boundary_walls(root, width + 6.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width + 2.0, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	_add_prop_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(-4.5, 0.0, -10.0), Vector3(1.8, 1.8, 1.8), 0.0, Vector3(1.5, 8.0, 1.5))
	_add_prop_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(4.5, 0.0, -10.0), Vector3(1.8, 1.8, 1.8), 0.0, Vector3(1.5, 8.0, 1.5))
	_add_prop_model(root, "res://assets/models/environment/scifi/stairs_industrial.glb", Vector3(width * 0.5 - 1.5, 0.0, -20.0), Vector3(1.4, 1.4, 1.4), -90.0, Vector3(2.2, 3.0, 3.0))
	_add_prop_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(-width * 0.5 + 0.5, 0.0, -24.0), Vector3(1.8, 1.8, 1.8), 0.0, Vector3(2.0, 2.5, 2.0))

# ==============================================================================
# 7. SKY FORTRESS (High-altitude platforms, hangars, fighter craft)
# ==============================================================================
static func _build_sky_fortress_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_metal)
	_create_boundary_walls(root, width + 4.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	_add_vehicle_prop(root, "res://assets/models/vehicles/car_race_future.glb", Vector3(-3.2, 0.0, -16.0), 35.0, Vector3(2.2, 1.4, 4.6))
	_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(2.8, 0.0, -24.0), 0.0, Vector3(2.6, 1.2, 0.6))

# ==============================================================================
# 8. FINAL CITADEL (Fortress bastions, monolithic obsidian spires)
# ==============================================================================
static func _build_citadel_segment(root: Node3D, seg_idx: int, length: float, width: float, is_last: bool = false) -> void:
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width + 4.0, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_hull)
	_create_boundary_walls(root, width + 8.0, road_len, z_offset, seg_idx == 0, is_last)
	_create_navigation_region(root, width + 4.0, road_len, z_offset)
	_add_skyline_backdrop(root, z_offset, length)

	_add_prop_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(-width * 0.5, 0.0, -12.0), Vector3(2.2, 2.2, 2.2), 0.0, Vector3(1.8, 12.0, 1.8))
	_add_prop_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(width * 0.5, 0.0, -12.0), Vector3(2.2, 2.2, 2.2), 0.0, Vector3(1.8, 12.0, 1.8))
	_add_barrier_prop(root, "res://assets/models/environment/racing/barrier_wall.glb", Vector3(0.0, 0.0, -20.0), 0.0, Vector3(3.0, 1.4, 0.8))
	_add_authored_building(root, "res://assets/models/environment/building_skyscraper_c.glb", Vector3(-width * 0.5 - 8.0, 0.0, -length * 0.5), Vector3(16.0, 48.0, 16.0), 90.0)

# ==============================================================================
# SKYLINE BACKDROP & MULTI-LAYER URBAN DEPTH
# ==============================================================================

static func _add_skyline_backdrop(parent: Node3D, z_offset: float, length: float) -> void:
	var skyline_root = Node3D.new()
	skyline_root.name = "SkylineBackdrop"

	var mat_skyline = MaterialGenerator.get_material("dark_hull")
	var mat_lit = MaterialGenerator.get_material("sci_fi_metal")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")
	var mat_amber = MaterialGenerator.get_material("neon_orange")

	# Perimeter Distant Towers (rendered beyond boundary walls)
	var tower_offsets_x = [-48.0, -68.0, 48.0, 68.0]
	var heights = [45.0, 68.0, 52.0, 80.0, 60.0, 74.0]

	for i in range(tower_offsets_x.size()):
		var tx = tower_offsets_x[i]
		for tz_step in range(0, int(length), 20):
			var tz = z_offset - length * 0.5 + float(tz_step) + 10.0
			var h = heights[(i * 3 + tz_step / 20) % heights.size()]
			var w = 18.0 if i % 2 == 0 else 24.0

			# Distant Skyscraper Tower Body
			var tw_mi = _create_visual_box(skyline_root, Vector3(w, h, w), Vector3(tx, h * 0.5, tz), mat_skyline)
			tw_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			# Illuminated Window Band Bands on distant towers
			var band_y = h * 0.75
			var band_mat = mat_cyan if (i % 2 == 0) else mat_amber
			var band = _create_visual_box(skyline_root, Vector3(w + 0.2, 1.8, w + 0.2), Vector3(tx, band_y, tz), band_mat)
			band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			# Spire on tallest towers
			if h > 65.0:
				var spire = _create_visual_box(skyline_root, Vector3(0.6, 12.0, 0.6), Vector3(tx, h + 6.0, tz), mat_lit)
				spire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	parent.add_child(skyline_root)

# ==============================================================================
# CORE HELPER METHODS & HARDENED CONTINUOUS COLLISION
# ==============================================================================

static func _create_solid_floor(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	sb.add_child(mi)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	sb.add_child(col)

	parent.add_child(sb)
	return sb

static func _create_boundary_walls(parent: Node3D, width: float, length: float, z_pos: float, is_first: bool, is_last: bool = false) -> void:
	var wall_h = 10.0
	var half_w = width * 0.5
	var mat_wall = MaterialGenerator.get_material("dark_hull")
	var mat_gate = MaterialGenerator.get_material("grimy_concrete")

	# Left Wall (Physical + Visual)
	_create_solid_wall(parent, Vector3(1.2, wall_h, length), Vector3(-half_w, wall_h * 0.5, z_pos), mat_wall)
	# Right Wall (Physical + Visual)
	_create_solid_wall(parent, Vector3(1.2, wall_h, length), Vector3(half_w, wall_h * 0.5, z_pos), mat_wall)

	# Rear Wall on first segment so player cannot walk backwards off spawn
	if is_first:
		_create_solid_wall(parent, Vector3(width + 2.0, wall_h, 1.2), Vector3(0, wall_h * 0.5, z_pos + length * 0.5), mat_gate)

	# End Perimeter Wall on final segment so player never sees open void or falls off world edge
	if is_last:
		_create_solid_wall(parent, Vector3(width + 2.0, wall_h, 1.2), Vector3(0, wall_h * 0.5, z_pos - length * 0.5), mat_gate)
		_build_extraction_helipad(parent, Vector3(0, 0.05, z_pos - length * 0.5 + 8.0))

static func _create_solid_wall(parent: Node3D, size: Vector3, pos: Vector3, mat: Material = null) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	sb.add_child(col)

	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat if mat else MaterialGenerator.get_material("dark_hull")
	sb.add_child(mi)

	parent.add_child(sb)
	return sb

static func _create_invisible_wall(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	return _create_solid_wall(parent, size, pos)

static func _build_extraction_helipad(parent: Node3D, pos: Vector3) -> void:
	var pad = Node3D.new()
	pad.name = "ExtractionPadVisual"
	pad.position = pos

	# Octagonal Landing Base
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 5.5
	cyl.bottom_radius = 5.8
	cyl.height = 0.15
	mi.mesh = cyl
	mi.material_override = MaterialGenerator.get_material("sci_fi_metal")
	pad.add_child(mi)

	# Glowing extraction ring / beacon
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 4.4
	torus.outer_radius = 4.9
	ring.mesh = torus
	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = Color(0.1, 0.95, 1.0)
	mat_glow.emission_enabled = true
	mat_glow.emission = Color(0.1, 0.95, 1.0)
	mat_glow.emission_energy_multiplier = 4.5
	ring.material_override = mat_glow
	ring.position = Vector3(0, 0.1, 0)
	pad.add_child(ring)

	# Helipad 'H' Marking in Center
	var mat_h = StandardMaterial3D.new()
	mat_h.albedo_color = Color(1.0, 0.85, 0.1)
	mat_h.emission_enabled = true
	mat_h.emission = Color(1.0, 0.85, 0.1)
	mat_h.emission_energy_multiplier = 2.0
	_create_visual_box(pad, Vector3(0.5, 0.05, 3.2), Vector3(-1.2, 0.12, 0), mat_h)
	_create_visual_box(pad, Vector3(0.5, 0.05, 3.2), Vector3(1.2, 0.12, 0), mat_h)
	_create_visual_box(pad, Vector3(2.4, 0.05, 0.5), Vector3(0, 0.12, 0), mat_h)

	# 4 Corner Extraction Floodlights with high visibility
	var corner_offsets = [Vector3(-6.0, 0, -6.0), Vector3(6.0, 0, -6.0), Vector3(-6.0, 0, 6.0), Vector3(6.0, 0, 6.0)]
	for c_off in corner_offsets:
		_add_beacon(pad, c_off + Vector3(0, 0.5, 0), Color(0.1, 0.95, 1.0))

	# Sky Extraction Beacon Beam
	var beam = MeshInstance3D.new()
	var beam_cyl = CylinderMesh.new()
	beam_cyl.top_radius = 0.3
	beam_cyl.bottom_radius = 0.8
	beam_cyl.height = 45.0
	beam.mesh = beam_cyl
	var mat_beam = StandardMaterial3D.new()
	mat_beam.albedo_color = Color(0.1, 0.95, 1.0, 0.35)
	mat_beam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_beam.emission_enabled = true
	mat_beam.emission = Color(0.1, 0.95, 1.0)
	mat_beam.emission_energy_multiplier = 3.0
	beam.material_override = mat_beam
	beam.position = Vector3(0, 22.5, 0)
	pad.add_child(beam)

	parent.add_child(pad)

static func _create_navigation_region(parent: Node3D, width: float, length: float, z_pos: float) -> NavigationRegion3D:
	var nav_reg = NavigationRegion3D.new()
	nav_reg.name = "NavigationRegion3D"
	var nav_mesh = NavigationMesh.new()

	var half_w = width * 0.5
	var half_l = length * 0.5
	var y = 0.05

	var verts = PackedVector3Array([
		Vector3(-half_w, y, z_pos - half_l),
		Vector3(half_w, y, z_pos - half_l),
		Vector3(half_w, y, z_pos + half_l),
		Vector3(-half_w, y, z_pos + half_l),
	])
	nav_mesh.vertices = verts
	nav_mesh.add_polygon(PackedInt32Array([0, 3, 2]))
	nav_mesh.add_polygon(PackedInt32Array([0, 2, 1]))

	nav_reg.navigation_mesh = nav_mesh
	parent.add_child(nav_reg)
	return nav_reg

static func _add_authored_building(parent: Node3D, path: String, pos: Vector3, sc: Vector3, rot_y: float) -> Node3D:
	var b_root = Node3D.new()
	b_root.name = "building_" + str(parent.get_child_count())
	b_root.position = pos
	b_root.scale = sc

	var m = ModelCacheScript.get_model(path)
	if m:
		m.rotation_degrees.y = rot_y
		b_root.add_child(m)
	else:
		_create_visual_box(b_root, Vector3(1.0, 1.0, 1.0), Vector3(0, 0.5, 0), MaterialGenerator.get_material("dark_hull"))

	# Add physical box collider for building base directly to parent in unscaled world coordinates
	var sb = StaticBody3D.new()
	sb.name = "BuildingCollider_" + str(parent.get_child_count())
	sb.set_meta("is_building", true)
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos + Vector3(0, sc.y * 0.5, 0)
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(sc.x, sc.y, sc.z)
	col.shape = box
	sb.add_child(col)

	parent.add_child(b_root)
	parent.add_child(sb)
	return b_root

static func _add_vehicle_prop(parent: Node3D, path: String, pos: Vector3, rot_y: float, col_size: Vector3 = Vector3(2.1, 1.6, 4.6)) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.name = "VehicleProp"
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = col_size
	col.shape = box
	col.position = Vector3(0, col_size.y * 0.5, 0)
	sb.add_child(col)

	var m = ModelCacheScript.get_model(path)
	if m:
		m.rotation_degrees.y = rot_y
		sb.add_child(m)
	else:
		_create_visual_box(sb, col_size, Vector3(0, col_size.y * 0.5, 0), MaterialGenerator.get_material("sci_fi_metal"))

	parent.add_child(sb)
	return sb

static func _add_barrier_prop(parent: Node3D, path: String, pos: Vector3, rot_y: float, col_size: Vector3 = Vector3(2.4, 1.2, 0.6)) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.name = "BarrierProp"
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = col_size
	col.shape = box
	col.position = Vector3(0, col_size.y * 0.5, 0)
	sb.add_child(col)

	var m = ModelCacheScript.get_model(path)
	if m:
		m.rotation_degrees.y = rot_y
		sb.add_child(m)
	else:
		_create_visual_box(sb, col_size, Vector3(0, col_size.y * 0.5, 0), MaterialGenerator.get_material("grimy_concrete"))

	parent.add_child(sb)
	return sb

static func _add_tree_prop(parent: Node3D, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.name = "TreeProp"
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.35 * sc.x
	cyl.height = 3.5 * sc.y
	col.shape = cyl
	col.position = Vector3(0, 1.75 * sc.y, 0)
	sb.add_child(col)

	var m = ModelCacheScript.get_model(path)
	if m:
		m.scale = sc
		sb.add_child(m)

	parent.add_child(sb)
	return sb

static func _add_prop_model(parent: Node3D, path: String, pos: Vector3, sc: Vector3, rot_y: float, col_size: Vector3) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.name = "PropSolid"
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	if col_size.length_squared() > 0.01:
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = col_size
		col.shape = box
		col.position = Vector3(0, col_size.y * 0.5, 0)
		sb.add_child(col)

	var m = ModelCacheScript.get_model(path)
	if m:
		m.scale = sc
		m.rotation_degrees.y = rot_y
		sb.add_child(m)

	parent.add_child(sb)
	return sb

static func _add_streetlight_prop(parent: Node3D, pos: Vector3, rot_y: float, col: Color, energy: float = 2.2) -> Node3D:
	var post = _add_model(parent, "res://assets/models/environment/road_lightposts.glb", pos, Vector3(1.2, 1.2, 1.2), rot_y)
	if not post:
		post = _create_visual_box(parent, Vector3(0.25, 5.5, 0.25), pos + Vector3(0, 2.75, 0), MaterialGenerator.get_material("sci_fi_metal"))

	# Slender post collision outside driving line
	var sb = StaticBody3D.new()
	sb.name = "LightpostCollider"
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos
	var c_col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.20
	cyl.height = 5.5
	c_col.shape = cyl
	c_col.position = Vector3(0, 2.75, 0)
	sb.add_child(c_col)
	parent.add_child(sb)

	# Active street illumination (height >= 3.5m for test invariant verification)
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = energy
	light.omni_range = 14.0
	light.omni_attenuation = 1.15
	light.position = pos + Vector3(0, 4.8, 0)
	parent.add_child(light)

	return post

static func _add_beacon(parent: Node3D, pos: Vector3, col: Color) -> void:
	var mi = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.16
	sph.height = 0.32
	mi.mesh = sph
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.5
	light.omni_range = 7.0
	light.position = pos
	parent.add_child(light)

static func _add_model(parent: Node3D, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y: float = 0.0) -> Node3D:
	var m = ModelCacheScript.get_model(path)
	if m:
		m.position = pos
		m.scale = sc
		m.rotation_degrees.y = rot_y
		parent.add_child(m)
		return m
	return null

static func _create_visual_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi
