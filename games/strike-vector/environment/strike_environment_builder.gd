class_name StrikeEnvironmentBuilder
extends RefCounted

## Modular PBR 3D environment builder for all 8 campaign biomes in Strike Vector:
## Urban, Rail, Harbor, Desert, Arctic, Factory, Sky Fortress, and Citadel.
## Builds high-fidelity corridor segments with lighting, materials, and static collision.

static func build_segment_environment(biome: String, seg_idx: int, length: float = 45.0, width: float = 14.0) -> Node3D:
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

# 1. URBAN BLACKOUT (Asphalt, curbs, skyscraper facades, streetlights, barriers)
static func _build_urban_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_road = MaterialGenerator.get_material("asphalt_track")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	# Road floor
	_create_static_box(root, Vector3(width, 0.4, length), Vector3(0, -0.2, -length * 0.5), mat_road)

	# Sidewalks & Curbs
	_create_static_box(root, Vector3(2.5, 0.3, length), Vector3(-width * 0.5 - 1.25, 0.15, -length * 0.5), mat_hull)
	_create_static_box(root, Vector3(2.5, 0.3, length), Vector3(width * 0.5 + 1.25, 0.15, -length * 0.5), mat_hull)

	# Flanking Skyscraper Facades
	for z_step in range(0, int(length), 15):
		var z_pos = -float(z_step) - 7.5
		# Left Building
		_create_static_box(root, Vector3(8.0, 18.0, 12.0), Vector3(-width * 0.5 - 6.5, 9.0, z_pos), mat_hull)
		# Right Building
		_create_static_box(root, Vector3(8.0, 22.0, 12.0), Vector3(width * 0.5 + 6.5, 11.0, z_pos), mat_hull)
		# Neon Cyber Billboard
		_create_visual_box(root, Vector3(0.2, 3.5, 8.0), Vector3(-width * 0.5 - 2.4, 6.0, z_pos), mat_cyan)

# 2. HIGH-SPEED RAIL (Train tracks, carriage interiors/roofs, couplers, speed rails)
static func _build_rail_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_orange = MaterialGenerator.get_material("neon_orange")

	# Train Floor / Roof Deck
	_create_static_box(root, Vector3(width * 0.65, 0.5, length), Vector3(0, -0.25, -length * 0.5), mat_metal)

	# Train Side Safety Rails
	_create_static_box(root, Vector3(0.3, 1.2, length), Vector3(-width * 0.32, 0.6, -length * 0.5), mat_hull)
	_create_static_box(root, Vector3(0.3, 1.2, length), Vector3(width * 0.32, 0.6, -length * 0.5), mat_hull)

	# High-Speed Track Rails underneath
	_create_visual_box(root, Vector3(0.2, 0.4, length), Vector3(-width * 0.20, -0.6, -length * 0.5), mat_orange)
	_create_visual_box(root, Vector3(0.2, 0.4, length), Vector3(width * 0.20, -0.6, -length * 0.5), mat_orange)

	# Overhead Gantries / Tunnels
	for z_step in range(0, int(length), 20):
		var z_pos = -float(z_step) - 10.0
		_create_static_box(root, Vector3(width * 0.8, 0.8, 0.8), Vector3(0, 4.2, z_pos), mat_metal)

# 3. HARBOR ASSAULT (Wet docks, multi-colored cargo shipping containers, cranes)
static func _build_harbor_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_blue = MaterialGenerator.get_material("neon_blue")

	# Wet Concrete Dock Floor
	_create_static_box(root, Vector3(width, 0.5, length), Vector3(0, -0.25, -length * 0.5), mat_hull)

	# Stacks of Shipping Containers forming combat lanes
	for z_step in range(0, int(length), 12):
		var z_pos = -float(z_step) - 6.0
		# Left Container Stack
		_create_static_box(root, Vector3(3.2, 3.0, 6.5), Vector3(-width * 0.5 + 2.0, 1.5, z_pos), mat_metal)
		# Right Container Stack
		_create_static_box(root, Vector3(3.2, 3.0, 6.5), Vector3(width * 0.5 - 2.0, 1.5, z_pos + 3.0), mat_metal)

	# Gantry Crane Legs along perimeter
	_create_visual_box(root, Vector3(1.2, 14.0, 1.2), Vector3(-width * 0.5 - 1.5, 7.0, -length * 0.5), mat_blue)

# 4. DESERT CONVOY (Canyon sandstone, rocky barriers, pipelines, dusty highway)
static func _build_desert_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_road = MaterialGenerator.get_material("asphalt_track")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	# Canyon Road
	_create_static_box(root, Vector3(width, 0.4, length), Vector3(0, -0.2, -length * 0.5), mat_road)

	# Canyon Rock Walls
	for z_step in range(0, int(length), 15):
		var z_pos = -float(z_step) - 7.5
		_create_static_box(root, Vector3(6.0, 12.0, 15.0), Vector3(-width * 0.5 - 3.0, 6.0, z_pos), mat_road)
		_create_static_box(root, Vector3(6.0, 12.0, 15.0), Vector3(width * 0.5 + 3.0, 6.0, z_pos), mat_road)

	# Heavy Industrial Pipeline along side
	_create_static_box(root, Vector3(1.2, 1.2, length), Vector3(-width * 0.42, 1.5, -length * 0.5), mat_metal)

# 5. ARCTIC INSTALLATION (Snow, ice caverns, high-tech research outpost, radar dish)
static func _build_arctic_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	# Frozen Ice/Snow Pathway
	_create_static_box(root, Vector3(width, 0.5, length), Vector3(0, -0.25, -length * 0.5), mat_hull)

	# High-tech insulated research facility walls
	for z_step in range(0, int(length), 14):
		var z_pos = -float(z_step) - 7.0
		_create_static_box(root, Vector3(4.0, 6.0, 12.0), Vector3(-width * 0.5 - 1.5, 3.0, z_pos), mat_metal)
		_create_static_box(root, Vector3(4.0, 6.0, 12.0), Vector3(width * 0.5 + 1.5, 3.0, z_pos), mat_metal)
		_create_visual_box(root, Vector3(0.2, 0.3, 10.0), Vector3(-width * 0.5 + 0.4, 2.5, z_pos), mat_cyan)

# 6. MEGAFACTORY (Conveyor belts, automated machinery, smelting furnaces, robot arms)
static func _build_factory_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_orange = MaterialGenerator.get_material("neon_orange")
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	# Industrial Steel Grate Floor
	_create_static_box(root, Vector3(width, 0.4, length), Vector3(0, -0.2, -length * 0.5), mat_hull)

	# Central Automated Conveyor Belt
	_create_visual_box(root, Vector3(3.0, 0.2, length), Vector3(0, 0.1, -length * 0.5), mat_orange)

	# Stamping Pistons & Machinery Overhead
	for z_step in range(0, int(length), 15):
		var z_pos = -float(z_step) - 7.5
		_create_static_box(root, Vector3(2.5, 6.0, 3.0), Vector3(-width * 0.5 + 2.0, 3.0, z_pos), mat_metal)
		_create_static_box(root, Vector3(2.5, 6.0, 3.0), Vector3(width * 0.5 - 2.0, 3.0, z_pos), mat_metal)

# 7. SKY FORTRESS (Altitude catwalks, hangars, antenna arrays, heavy drop-off clouds)
static func _build_sky_fortress_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_magenta = MaterialGenerator.get_material("neon_magenta")

	# Suspended Fortress Catwalk Deck
	_create_static_box(root, Vector3(width * 0.8, 0.6, length), Vector3(0, -0.3, -length * 0.5), mat_metal)

	# Catwalk Handrails
	_create_static_box(root, Vector3(0.2, 1.2, length), Vector3(-width * 0.4, 0.6, -length * 0.5), mat_hull)
	_create_static_box(root, Vector3(0.2, 1.2, length), Vector3(width * 0.4, 0.6, -length * 0.5), mat_hull)

	# Floating Plasma Reactor Conduits
	_create_visual_box(root, Vector3(0.3, 0.3, length), Vector3(0, 3.8, -length * 0.5), mat_magenta)

# 8. FINAL CITADEL (Fortress walls, energy barriers, defensive turrets, imperial spires)
static func _build_citadel_segment(root: Node3D, _idx: int, length: float, width: float) -> void:
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_red = MaterialGenerator.get_material("neon_orange")

	# Polished Black Citadel Slabs
	_create_static_box(root, Vector3(width, 0.6, length), Vector3(0, -0.3, -length * 0.5), mat_hull)

	# Fortified Citadel Tower Pylons
	for z_step in range(0, int(length), 16):
		var z_pos = -float(z_step) - 8.0
		_create_static_box(root, Vector3(3.5, 14.0, 3.5), Vector3(-width * 0.5 - 1.0, 7.0, z_pos), mat_hull)
		_create_static_box(root, Vector3(3.5, 14.0, 3.5), Vector3(width * 0.5 + 1.0, 7.0, z_pos), mat_hull)
		_create_visual_box(root, Vector3(0.3, 12.0, 0.3), Vector3(-width * 0.5 + 0.8, 6.0, z_pos), mat_red)
		_create_visual_box(root, Vector3(0.3, 12.0, 0.3), Vector3(width * 0.5 - 0.8, 6.0, z_pos), mat_red)

# --- Helper Methods ---

static func _create_static_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
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

static func _create_visual_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi
