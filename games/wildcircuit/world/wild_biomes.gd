class_name WildBiomes
extends Node3D

## WildBiomes: Generates 5 distinct, dense nature exploration biomes for WildCircuit.
## Savannah, Rainforest, Alpine Forest, Tropical Coast, and Wetlands.
## Features procedural terrain elevation, dense flora, water bodies, landmarks, and autonomous wildlife.

signal biome_changed(biome_name: String)

const WildAnimalScript = preload("res://games/wildcircuit/animals/wild_animal.gd")

var current_biome: String = "savannah"
var spawned_animals: Array[Node3D] = []

func _ready() -> void:
	build_all_biomes()

func build_all_biomes() -> void:
	# 1. Savannah (Center: 0, 0, 0)
	build_savannah(Vector3(0, 0, 0))

	# 2. Rainforest (North: 0, 0, -85.0)
	build_rainforest(Vector3(0, 0, -85.0))

	# 3. Alpine Forest (West: -90.0, 12.0, 0)
	build_alpine_forest(Vector3(-90.0, 12.0, 0))

	# 4. Tropical Coast (South: 0, -4.0, 90.0)
	build_tropical_coast(Vector3(0, -4.0, 90.0))

	# 5. Wetlands (East: 90.0, -2.0, 0)
	build_wetlands(Vector3(90.0, -2.0, 0))

# ==============================================================================
# 1. SAVANNAH BIOME (Watering Hole, Acacia Trees, Termite Mounds, Tall Grass)
# ==============================================================================
func build_savannah(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "SavannahBiome"
	root.position = origin
	add_child(root)

	# Multi-tiered rolling terrain
	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(65.0, 1.0, 65.0), "savannah_dirt")
	_add_terrain_slab(root, Vector3(12.0, 0.4, -10.0), Vector3(24.0, 0.8, 20.0), "savannah_dirt")
	_add_terrain_slab(root, Vector3(-14.0, 0.6, 12.0), Vector3(20.0, 1.2, 22.0), "savannah_dirt")

	# Central Watering Hole (Reflective water disc with muddy shoreline)
	var shore = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 12.0
	s_cyl.bottom_radius = 13.0
	s_cyl.height = 0.05
	shore.mesh = s_cyl
	shore.material_override = MaterialGenerator.get_material("wetland_mud")
	shore.position = Vector3(0, 0.02, 0)
	root.add_child(shore)

	var water = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 10.0
	cyl.bottom_radius = 10.0
	cyl.height = 0.08
	water.mesh = cyl
	water.material_override = MaterialGenerator.get_material("water_stream")
	water.position = Vector3(0, 0.06, 0)
	root.add_child(water)

	# Acacia Trees
	for p in [Vector3(-18.0, 0, -14.0), Vector3(18.0, 0, -12.0), Vector3(-14.0, 0, 18.0), Vector3(16.0, 0, 16.0), Vector3(0, 0, -22.0)]:
		_create_acacia_tree(root, p)

	# Tall Grass Clumps & Termite Mounds
	for p in [Vector3(-10.0, 0, 14.0), Vector3(12.0, 0, 10.0), Vector3(-20.0, 0, 2.0)]:
		_create_termite_mound(root, p)

	for p in [Vector3(-6.0, 0, 8.0), Vector3(8.0, 0, -6.0), Vector3(-12.0, 0, -8.0), Vector3(14.0, 0, 4.0)]:
		_create_grass_cluster(root, p, "savannah_dirt")

	# Wildlife: Gazelles, Lion, Zebra
	_spawn_animal(root, "gazelle", Vector3(-8.0, 0.5, -5.0))
	_spawn_animal(root, "gazelle", Vector3(-5.0, 0.5, -8.0))
	_spawn_animal(root, "lion", Vector3(15.0, 0.5, -16.0))
	_spawn_animal(root, "zebra", Vector3(-12.0, 0.5, 8.0))

# ==============================================================================
# 2. RAINFOREST BIOME (Dense Canopy, Vines, Fallen Trunks)
# ==============================================================================
func build_rainforest(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "RainforestBiome"
	root.position = origin
	add_child(root)

	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(60.0, 1.0, 60.0), "rainforest_canopy")

	# Giant Canopy Trees
	for p in [Vector3(-16.0, 0, -16.0), Vector3(16.0, 0, -16.0), Vector3(-14.0, 0, 14.0), Vector3(14.0, 0, 14.0), Vector3(0, 0, 0)]:
		_create_canopy_tree(root, p)

	# Understory Ferns & Fallen Logs
	for p in [Vector3(-6.0, 0.3, -8.0), Vector3(8.0, 0.3, 6.0)]:
		_create_fallen_log(root, p)

	# Wildlife: Jaguar and Macaw
	_spawn_animal(root, "jaguar", Vector3(-6.0, 0.5, -6.0))
	_spawn_animal(root, "macaw", Vector3(0, 5.0, 14.0))

# ==============================================================================
# 3. ALPINE FOREST BIOME (Mountain Crags, Pines, Elevation)
# ==============================================================================
func build_alpine_forest(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "AlpineBiome"
	root.position = origin
	add_child(root)

	# Multi-tiered mountain rock slopes
	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(60.0, 1.0, 60.0), "alpine_rock")
	_add_terrain_slab(root, Vector3(0, 3.0, -10.0), Vector3(35.0, 4.0, 30.0), "alpine_rock")
	_add_terrain_slab(root, Vector3(0, 7.0, -18.0), Vector3(20.0, 5.0, 18.0), "arctic_ice")

	# Mountain Pines
	for p in [Vector3(-14.0, 0, -12.0), Vector3(14.0, 0, -12.0), Vector3(-10.0, 3.5, -10.0), Vector3(10.0, 3.5, -10.0), Vector3(0, 7.5, -18.0)]:
		_create_pine_tree(root, p)

	# Wildlife: Snow Leopard and Mountain Goat
	_spawn_animal(root, "snow_leopard", Vector3(10.0, 4.0, -12.0))
	_spawn_animal(root, "mountain_goat", Vector3(-8.0, 7.5, -16.0))

# ==============================================================================
# 4. TROPICAL COAST BIOME (Sand Dunes, Palms, Turquoise Ocean)
# ==============================================================================
func build_tropical_coast(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "CoastBiome"
	root.position = origin
	add_child(root)

	# Sand dunes
	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(60.0, 1.0, 60.0), "tropical_sand")

	# Turquoise ocean shallows
	var ocean = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(58.0, 0.3, 24.0)
	ocean.mesh = b_box
	ocean.material_override = MaterialGenerator.get_material("water_stream")
	ocean.position = Vector3(0, 0.12, 18.0)
	root.add_child(ocean)

	# Palm trees leaning over water
	for p in [Vector3(-16.0, 0, -8.0), Vector3(16.0, 0, -8.0), Vector3(-8.0, 0, 4.0), Vector3(8.0, 0, 4.0)]:
		_create_palm_tree(root, p)

	# Wildlife: Sea Turtle
	_spawn_animal(root, "sea_turtle", Vector3(0, 0.35, 14.0))

# ==============================================================================
# 5. WETLANDS BIOME (Marsh Basins, Water Lilies, Dense Reeds)
# ==============================================================================
func build_wetlands(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "WetlandsBiome"
	root.position = origin
	add_child(root)

	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(60.0, 1.0, 60.0), "wetland_mud")

	# Marsh basins
	for p in [Vector3(-12.0, 0.05, -8.0), Vector3(12.0, 0.05, 8.0), Vector3(0, 0.05, 0)]:
		var pool = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 8.5
		cyl.bottom_radius = 8.5
		cyl.height = 0.08
		pool.mesh = cyl
		pool.material_override = MaterialGenerator.get_material("water_stream")
		pool.position = p
		root.add_child(pool)

	# Reeds and marsh grass
	for p in [Vector3(-8.0, 0, -4.0), Vector3(8.0, 0, 4.0), Vector3(-4.0, 0, 6.0), Vector3(4.0, 0, -6.0)]:
		_create_grass_cluster(root, p, "lush_grass")

	# Wildlife: Crocodile and Flamingo
	_spawn_animal(root, "crocodile", Vector3(-5.0, 0.35, -5.0))
	_spawn_animal(root, "flamingo", Vector3(4.0, 0.5, 5.0))

# ==============================================================================
# PROCEDURAL PROPS & VEGETATION
# ==============================================================================
func _add_terrain_slab(parent: Node3D, pos: Vector3, size: Vector3, mat_name: String) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.position = pos

	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = MaterialGenerator.get_material(mat_name)
	sb.add_child(mi)

	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = size
	col.shape = bs
	sb.add_child(col)

	parent.add_child(sb)
	return sb

func _create_acacia_tree(parent: Node3D, pos: Vector3) -> void:
	var tree_root = Node3D.new()
	tree_root.position = pos
	var mat_bark = MaterialGenerator.get_material("wood_bark")
	var mat_leaves = MaterialGenerator.get_material("lush_grass")

	# Base trunk with organic taper and slight lean
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.65
	cyl.height = 4.2
	trunk.mesh = cyl
	trunk.material_override = mat_bark
	trunk.position = Vector3(0, 2.1, 0)
	trunk.rotation_degrees.z = 6.0
	tree_root.add_child(trunk)

	# 3 Outward spreading angled branches
	var branch_data = [
		{"pos": Vector3(-0.4, 3.6, 0.2), "rot": Vector3(15.0, 0, -32.0), "pad_pos": Vector3(-2.2, 5.1, 0.5), "r": 2.8, "h": 0.55},
		{"pos": Vector3(0.5, 3.8, -0.3), "rot": Vector3(-20.0, 0, 35.0), "pad_pos": Vector3(2.4, 5.3, -0.6), "r": 3.0, "h": 0.55},
		{"pos": Vector3(0.1, 4.0, 0.4), "rot": Vector3(28.0, 0, 10.0), "pad_pos": Vector3(0.3, 5.5, 2.2), "r": 2.6, "h": 0.50}
	]
	for b in branch_data:
		var limb = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.18
		l_cyl.bottom_radius = 0.28
		l_cyl.height = 2.4
		limb.mesh = l_cyl
		limb.material_override = mat_bark
		limb.position = b["pos"]
		limb.rotation_degrees = b["rot"]
		tree_root.add_child(limb)

		# Tiered umbrella foliage pad at limb end
		var pad = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = b["r"]
		p_cyl.bottom_radius = b["r"] * 0.85
		p_cyl.height = b["h"]
		pad.mesh = p_cyl
		pad.material_override = mat_leaves
		pad.position = b["pad_pos"]
		tree_root.add_child(pad)

	# Crown top umbrella canopy
	var crown = MeshInstance3D.new()
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 3.6
	c_cyl.bottom_radius = 3.2
	c_cyl.height = 0.65
	crown.mesh = c_cyl
	crown.material_override = mat_leaves
	crown.position = Vector3(0.1, 6.0, 0)
	tree_root.add_child(crown)

	parent.add_child(tree_root)

func _create_canopy_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 1.0
	cyl.height = 9.5
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 4.75, 0)
	parent.add_child(trunk)

	var leaves = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 4.8
	sphere.height = 6.0
	leaves.mesh = sphere
	leaves.material_override = MaterialGenerator.get_material("rainforest_canopy")
	leaves.position = pos + Vector3(0, 10.0, 0)
	parent.add_child(leaves)

func _create_pine_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.45
	cyl.height = 4.2
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 2.1, 0)
	parent.add_child(trunk)

	var foliage = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 2.8
	cone.height = 6.2
	foliage.mesh = cone
	foliage.material_override = MaterialGenerator.get_material("rainforest_canopy")
	foliage.position = pos + Vector3(0, 6.0, 0)
	parent.add_child(foliage)

func _create_palm_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.4
	cyl.height = 6.5
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 3.25, 0)
	trunk.rotation_degrees.z = 10.0
	parent.add_child(trunk)

	var fronds = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 3.4
	disc.bottom_radius = 2.8
	disc.height = 0.45
	fronds.mesh = disc
	fronds.material_override = MaterialGenerator.get_material("lush_grass")
	fronds.position = pos + Vector3(0.6, 6.5, 0)
	parent.add_child(fronds)

func _create_termite_mound(parent: Node3D, pos: Vector3) -> void:
	var mound = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.18
	cone.bottom_radius = 0.85
	cone.height = 2.6
	mound.mesh = cone
	mound.material_override = MaterialGenerator.get_material("savannah_dirt")
	mound.position = pos + Vector3(0, 1.3, 0)
	parent.add_child(mound)

func _create_grass_cluster(parent: Node3D, pos: Vector3, mat_name: String) -> void:
	for i in range(3):
		var blade = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.4, 1.4, 0.4)
		blade.mesh = prism
		blade.material_override = MaterialGenerator.get_material(mat_name)
		blade.position = pos + Vector3((i - 1) * 0.3, 0.7, 0)
		blade.rotation_degrees.z = (i - 1) * 12.0
		parent.add_child(blade)

func _create_fallen_log(parent: Node3D, pos: Vector3) -> void:
	var log_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.45
	cyl.bottom_radius = 0.5
	cyl.height = 5.0
	log_mesh.mesh = cyl
	log_mesh.material_override = MaterialGenerator.get_material("wood_bark")
	log_mesh.position = pos
	log_mesh.rotation_degrees.z = 90.0
	parent.add_child(log_mesh)

func _spawn_animal(parent: Node3D, sp_id: String, pos: Vector3) -> Node3D:
	var animal = WildAnimalScript.new()
	animal.species_id = sp_id
	animal.position = pos
	parent.add_child(animal)
	spawned_animals.append(animal)
	return animal
