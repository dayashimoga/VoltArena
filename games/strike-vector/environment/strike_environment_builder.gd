class_name StrikeEnvironmentBuilder
extends RefCounted

## Modular PBR 3D environment builder for all 8 campaign biomes in Strike Vector:
## Urban Blackout, High-Speed Rail, Harbor Assault, Desert Convoy, Arctic Installation,
## Megafactory, Sky Fortress, and Final Citadel.
## Builds high-fidelity environments using production-grade 3D assets, authentic lighting,
## and hardened continuous collision geometry with zero-fall boundaries.

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

static func build_segment_environment(biome: String, seg_idx: int, length: float = 40.0, width: float = 16.0) -> Node3D:
	var root = Node3D.new()
	root.name = "Environment_" + biome + "_" + str(seg_idx)

	match biome:
		"urban": _build_urban_segment(root, seg_idx, length, width)
		"rail": _build_rail_segment(root, seg_idx, length, width)
		"harbor": _build_harbor_segment(root, seg_idx, length, width)
		"desert": _build_desert_segment(root, seg_idx, length, width)
		"arctic": _build_arctic_segment(root, seg_idx, length, width)
		"factory": _build_factory_segment(root, seg_idx, length, width)
		"sky_fortress": _build_sky_fortress_segment(root, seg_idx, length, width)
		"citadel": _build_citadel_segment(root, seg_idx, length, width)
		_: _build_urban_segment(root, seg_idx, length, width)

	return root

# ==============================================================================
# 1. URBAN BLACKOUT (Asphalt, curbs, buildings, streetlights, vehicles, barriers)
# ==============================================================================
static func _build_urban_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_road = MaterialGenerator.get_material("asphalt_track")
	var mat_sidewalk = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")
	var mat_amber = MaterialGenerator.get_material("neon_orange")

	# 1. Hardened Continuous Roadway Floor
	var road_len = length + (16.0 if seg_idx == 0 else 4.0)
	var z_offset = -length * 0.5 + (6.0 if seg_idx == 0 else -1.0)
	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_road)

	# 2. Elevated Sidewalks & Curbs
	_create_solid_floor(root, Vector3(3.0, 1.4, road_len), Vector3(-width * 0.5 - 1.5, -0.5, z_offset), mat_sidewalk)
	_create_solid_floor(root, Vector3(3.0, 1.4, road_len), Vector3(width * 0.5 + 1.5, -0.5, z_offset), mat_sidewalk)

	# 3. Lateral & Rear Anti-Fall Containment Barriers
	_create_boundary_walls(root, width + 6.0, road_len, z_offset, seg_idx == 0)

	# 4. Authored 3D Modular Buildings along Flanks
	var building_types = [
		"res://assets/models/environment/building_a.glb",
		"res://assets/models/environment/building_b.glb",
		"res://assets/models/environment/building_c.glb",
		"res://assets/models/environment/building_d.glb",
		"res://assets/models/environment/building_garage.glb"
	]

	for z_step in range(0, int(length), 14):
		var z_pos = -float(z_step) - 7.0
		var b_idx = (seg_idx * 3 + z_step / 14) % building_types.size()
		var b_path = building_types[b_idx]
		var b_path_r = building_types[(b_idx + 1) % building_types.size()]

		# Left Building with collision
		_add_authored_building(root, b_path, Vector3(-width * 0.5 - 5.5, 0.0, z_pos), Vector3(1.4, 1.4, 1.4), 90.0)
		# Right Building with collision
		_add_authored_building(root, b_path_r, Vector3(width * 0.5 + 5.5, 0.0, z_pos), Vector3(1.4, 1.4, 1.4), -90.0)

		# Streetlights with active local illumination
		var light_z = z_pos + 3.0
		_add_streetlight(root, Vector3(-width * 0.5 + 0.5, 0.0, light_z), Color(1.0, 0.75, 0.35))
		_add_streetlight(root, Vector3(width * 0.5 - 0.5, 0.0, light_z + 7.0), Color(0.25, 0.85, 1.0))

		# Commercial Signage and Billboards
		_create_visual_box(root, Vector3(0.2, 2.5, 6.0), Vector3(-width * 0.5 - 1.2, 5.5, z_pos), mat_cyan)

	# 5. Segment-Specific Tactical Dressing & Vehicles
	match seg_idx:
		0:
			# Spawn Street: Roadblocks & Parked Heavy Truck
			_add_model(root, "res://assets/models/vehicles/truck_yellow.glb", Vector3(-2.8, 0.0, -12.0), Vector3(1.2, 1.2, 1.2), 15.0)
			_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(2.5, 0.0, -18.0), Vector3(1.4, 1.4, 1.4), 0.0)
			_add_model(root, "res://assets/models/environment/scifi/computer_terminal.glb", Vector3(width * 0.5 - 1.0, 0.2, -8.0), Vector3(1.2, 1.2, 1.2), -90.0)
		1:
			# Damaged Intersection: Abandoned Car & Debris Barriers
			_add_model(root, "res://assets/models/vehicles/racecar_gp.glb", Vector3(2.0, 0.0, -10.0), Vector3(1.2, 1.2, 1.2), -45.0)
			_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(-2.0, 0.0, -22.0), Vector3(1.4, 1.4, 1.4), 20.0)
			_add_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(-width * 0.5 - 0.2, 0.0, -16.0), Vector3(1.5, 1.5, 1.5), 0.0)
		2:
			# Commercial Interior / Alley: Pillars, Industrial Stairs & Delivery Truck
			_add_model(root, "res://assets/models/vehicles/truck_green.glb", Vector3(3.2, 0.0, -14.0), Vector3(1.2, 1.2, 1.2), 170.0)
			_add_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(-3.5, 0.0, -8.0), Vector3(1.5, 1.5, 1.5), 0.0)
			_add_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(3.5, 0.0, -8.0), Vector3(1.5, 1.5, 1.5), 0.0)
			_add_model(root, "res://assets/models/environment/scifi/stairs_industrial.glb", Vector3(-width * 0.5 + 1.0, 0.2, -24.0), Vector3(1.3, 1.3, 1.3), 90.0)
		3:
			# Parking Structure & Rooftop Catwalks: Garage Facade & High Barriers
			_add_model(root, "res://assets/models/vehicles/truck_red.glb", Vector3(-2.5, 0.0, -15.0), Vector3(1.2, 1.2, 1.2), 30.0)
			_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(3.0, 0.0, -12.0), Vector3(1.4, 1.4, 1.4), -10.0)
			_add_model(root, "res://assets/models/environment/subway/station_bench.glb", Vector3(width * 0.5 - 1.2, 0.2, -20.0), Vector3(1.3, 1.3, 1.3), -90.0)
		4:
			# Evacuation Plaza: Grand Open Arena with High Perimeter Cover
			_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(-5.0, 0.0, -15.0), Vector3(1.6, 1.6, 1.6), 45.0)
			_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(5.0, 0.0, -15.0), Vector3(1.6, 1.6, 1.6), -45.0)
			_add_model(root, "res://assets/models/environment/subway/station_bench.glb", Vector3(-4.0, 0.2, -26.0), Vector3(1.3, 1.3, 1.3), 0.0)
			_add_model(root, "res://assets/models/environment/subway/station_bench.glb", Vector3(4.0, 0.2, -26.0), Vector3(1.3, 1.3, 1.3), 0.0)

# ==============================================================================
# 2. HIGH-SPEED RAIL (Train tracks, passenger cars, roof traversal, gantries)
# ==============================================================================
static func _build_rail_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_orange = MaterialGenerator.get_material("neon_orange")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	# Heavy Steel Train Deck Floor
	_create_solid_floor(root, Vector3(width * 0.70, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_metal)
	_create_boundary_walls(root, width * 0.70 + 2.0, road_len, z_offset, seg_idx == 0)

	# Moving Rail Cars & Train Tracks
	_add_model(root, "res://assets/models/environment/subway/train_track.glb", Vector3(-2.5, 0.0, -length * 0.5), Vector3(2.0, 1.0, length * 0.1), 0.0)
	_add_model(root, "res://assets/models/environment/subway/train_track.glb", Vector3(2.5, 0.0, -length * 0.5), Vector3(2.0, 1.0, length * 0.1), 0.0)

	# Train Passenger Carriage Body
	var car_path = "res://assets/models/environment/subway/train_subway_car.glb" if seg_idx % 2 == 0 else "res://assets/models/environment/subway/train_subway_middle.glb"
	_add_model(root, car_path, Vector3(0, 0.0, -length * 0.5), Vector3(1.0, 1.0, 1.2), 0.0)

	# Side Safety Railings
	_create_solid_floor(root, Vector3(0.4, 1.2, road_len), Vector3(-width * 0.35, 0.6, z_offset), mat_hull)
	_create_solid_floor(root, Vector3(0.4, 1.2, road_len), Vector3(width * 0.35, 0.6, z_offset), mat_hull)

	# Overhead Tunnel Gantries with Orange Warning Beacons
	for z_step in range(0, int(length), 18):
		var z_pos = -float(z_step) - 9.0
		_create_visual_box(root, Vector3(width * 0.8, 0.6, 0.8), Vector3(0, 4.5, z_pos), mat_orange)

# ==============================================================================
# 3. HARBOR ASSAULT (Wet docks, multi-colored containers, warehouses, gantries)
# ==============================================================================
static func _build_harbor_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_blue = MaterialGenerator.get_material("neon_blue")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	# Wet Concrete Dock Slab
	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_hull)
	_create_boundary_walls(root, width + 4.0, road_len, z_offset, seg_idx == 0)

	# Shipping Container Labyrinths
	for z_step in range(0, int(length), 12):
		var z_pos = -float(z_step) - 6.0
		# Stacks of containers
		_create_solid_floor(root, Vector3(3.5, 3.2, 7.0), Vector3(-width * 0.5 + 2.5, 1.6, z_pos), mat_metal)
		_create_solid_floor(root, Vector3(3.5, 3.2, 7.0), Vector3(width * 0.5 - 2.5, 1.6, z_pos + 3.0), mat_metal)

	# Marine Warehouse / Logistics Terminal
	_add_authored_building(root, "res://assets/models/environment/building_d.glb", Vector3(-width * 0.5 - 6.0, 0.0, -length * 0.5), Vector3(1.3, 1.3, 1.3), 90.0)
	_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(0.0, 0.0, -18.0), Vector3(1.4, 1.4, 1.4), 0.0)

# ==============================================================================
# 4. DESERT CONVOY (Canyon sandstone, highway, convoy trucks, pipelines)
# ==============================================================================
static func _build_desert_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_road = MaterialGenerator.get_material("asphalt_track")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_road)
	_create_boundary_walls(root, width + 4.0, road_len, z_offset, seg_idx == 0)

	# Canyon Pipeline Infrastructure
	_add_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(-width * 0.5 + 0.5, 0.0, -12.0), Vector3(1.6, 1.6, 1.6), 0.0)
	_add_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(width * 0.5 - 0.5, 0.0, -28.0), Vector3(1.6, 1.6, 1.6), 180.0)

	# Armored Convoy Transport Vehicles
	var truck_model = "res://assets/models/vehicles/truck_red.glb" if seg_idx % 2 == 0 else "res://assets/models/vehicles/truck_yellow.glb"
	_add_model(root, truck_model, Vector3(1.5, 0.0, -18.0), Vector3(1.3, 1.3, 1.3), -15.0)

# ==============================================================================
# 5. ARCTIC INSTALLATION (Sub-zero research modules, radar facilities, caverns)
# ==============================================================================
static func _build_arctic_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_hull)
	_create_boundary_walls(root, width + 4.0, road_len, z_offset, seg_idx == 0)

	# Arctic Research Buildings & Radars
	_add_authored_building(root, "res://assets/models/environment/building_b.glb", Vector3(-width * 0.5 - 5.0, 0.0, -length * 0.4), Vector3(1.3, 1.3, 1.3), 90.0)
	_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(3.0, 0.0, -14.0), Vector3(1.4, 1.4, 1.4), -30.0)
	_add_model(root, "res://assets/models/environment/scifi/computer_terminal.glb", Vector3(-width * 0.5 + 1.2, 0.0, -22.0), Vector3(1.2, 1.2, 1.2), 90.0)

# ==============================================================================
# 6. MEGAFACTORY (Robotic assembly, conveyor floors, smelting furnaces)
# ==============================================================================
static func _build_factory_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_metal)
	_create_boundary_walls(root, width + 4.0, road_len, z_offset, seg_idx == 0)

	# Industrial Pillars & Catwalk Stairs
	_add_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(-4.0, 0.0, -10.0), Vector3(1.6, 1.6, 1.6), 0.0)
	_add_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(4.0, 0.0, -10.0), Vector3(1.6, 1.6, 1.6), 0.0)
	_add_model(root, "res://assets/models/environment/scifi/stairs_industrial.glb", Vector3(width * 0.5 - 1.5, 0.0, -20.0), Vector3(1.4, 1.4, 1.4), -90.0)
	_add_model(root, "res://assets/models/environment/scifi/pipe_network.glb", Vector3(-width * 0.5 + 0.5, 0.0, -24.0), Vector3(1.5, 1.5, 1.5), 0.0)

# ==============================================================================
# 7. SKY FORTRESS (High-altitude platforms, hangars, fighter craft, conduits)
# ==============================================================================
static func _build_sky_fortress_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width * 0.85, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_metal)
	_create_boundary_walls(root, width * 0.85 + 2.0, road_len, z_offset, seg_idx == 0)

	# Fighter Hangar Aircraft
	_add_model(root, "res://assets/models/vehicles/rocket_car_spectre.glb", Vector3(-3.0, 0.0, -16.0), Vector3(1.4, 1.4, 1.4), 45.0)
	_add_model(root, "res://assets/models/environment/scifi/wall_window.glb", Vector3(width * 0.5 - 0.5, 0.0, -12.0), Vector3(1.5, 1.5, 1.5), -90.0)
	_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(2.5, 0.0, -24.0), Vector3(1.4, 1.4, 1.4), 0.0)

# ==============================================================================
# 8. FINAL CITADEL (Fortress bastions, monolith pillars, grand spires)
# ==============================================================================
static func _build_citadel_segment(root: Node3D, seg_idx: int, length: float, width: float) -> void:
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_orange = MaterialGenerator.get_material("neon_orange")

	var road_len = length + 4.0
	var z_offset = -length * 0.5 - 1.0

	_create_solid_floor(root, Vector3(width, 1.2, road_len), Vector3(0, -0.6, z_offset), mat_hull)
	_create_boundary_walls(root, width + 4.0, road_len, z_offset, seg_idx == 0)

	# Grand Obsidian Monolith Columns
	_add_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(-width * 0.5 + 1.0, 0.0, -12.0), Vector3(2.0, 2.0, 2.0), 0.0)
	_add_model(root, "res://assets/models/environment/scifi/wall_pillar.glb", Vector3(width * 0.5 - 1.0, 0.0, -12.0), Vector3(2.0, 2.0, 2.0), 0.0)
	_add_model(root, "res://assets/models/environment/scifi/barrier_high.glb", Vector3(0.0, 0.0, -20.0), Vector3(1.6, 1.6, 1.6), 0.0)
	_add_authored_building(root, "res://assets/models/environment/building_c.glb", Vector3(-width * 0.5 - 6.0, 0.0, -length * 0.5), Vector3(1.5, 1.5, 1.5), 90.0)

# ==============================================================================
# CORE HELPER METHODS & COLLISION SECURITY
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

static func _create_boundary_walls(parent: Node3D, width: float, length: float, z_pos: float, is_first: bool) -> void:
	var wall_h = 8.0
	var half_w = width * 0.5

	# Left Wall
	_create_invisible_wall(parent, Vector3(1.0, wall_h, length), Vector3(-half_w, wall_h * 0.5, z_pos))
	# Right Wall
	_create_invisible_wall(parent, Vector3(1.0, wall_h, length), Vector3(half_w, wall_h * 0.5, z_pos))

	# Rear Wall on first segment so player cannot walk backwards off spawn
	if is_first:
		_create_invisible_wall(parent, Vector3(width + 2.0, wall_h, 1.0), Vector3(0, wall_h * 0.5, z_pos + length * 0.5))

static func _create_invisible_wall(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.collision_mask = 0
	sb.position = pos

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	sb.add_child(col)

	parent.add_child(sb)
	return sb

static func _add_authored_building(parent: Node3D, path: String, pos: Vector3, sc: Vector3, rot_y: float) -> Node3D:
	var m = _add_model(parent, path, pos, sc, rot_y)
	if m:
		# Add physical box collider for building base to provide solid cover
		var sb = StaticBody3D.new()
		sb.collision_layer = GameConstants.LAYER_WORLD
		sb.collision_mask = 0
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(8.0 * sc.x, 16.0 * sc.y, 8.0 * sc.z)
		col.shape = box
		col.position = Vector3(0, 8.0 * sc.y, 0)
		sb.add_child(col)
		m.add_child(sb)
		return m

	# Fallback box if model unavailable
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	return _create_solid_floor(parent, Vector3(10.0, 20.0, 10.0), pos + Vector3(0, 10.0, 0), mat_hull)

static func _add_streetlight(parent: Node3D, pos: Vector3, col: Color) -> void:
	var post = _add_model(parent, "res://assets/models/environment/road_lightposts.glb", pos, Vector3(1.2, 1.2, 1.2), 0.0)
	if not post:
		post = _create_visual_box(parent, Vector3(0.3, 5.0, 0.3), pos + Vector3(0, 2.5, 0), MaterialGenerator.get_material("sci_fi_metal"))

	# Active point light casting warm amber or cyan street glow
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.4
	light.omni_range = 16.0
	light.omni_attenuation = 1.2
	light.position = pos + Vector3(0, 4.2, 0)
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
