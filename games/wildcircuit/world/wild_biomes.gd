class_name WildBiomes
extends Node3D

## WildBiomes: Generates and manages the 5 distinct nature biomes for WildCircuit.
## Savannah, Rainforest, Alpine Forest, Tropical Coast, and Wetlands.
## Houses procedural flora, water bodies, landmarks, and autonomous wildlife spawns.

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

	# 3. Alpine Forest (West: -90.0, 15.0, 0)
	build_alpine_forest(Vector3(-90.0, 12.0, 0))

	# 4. Tropical Coast (South: 0, -5.0, 90.0)
	build_tropical_coast(Vector3(0, -4.0, 90.0))

	# 5. Wetlands (East: 90.0, -2.0, 0)
	build_wetlands(Vector3(90.0, -2.0, 0))

# ==============================================================================
# 1. SAVANNAH BIOME
# ==============================================================================
func build_savannah(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "SavannahBiome"
	root.position = origin
	add_child(root)

	# Terrain floor
	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(55.0, 1.0, 55.0), "savannah_dirt")

	# Central Watering Hole (Reflective water disc)
	var water = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 9.0
	cyl.bottom_radius = 9.0
	cyl.height = 0.1
	water.mesh = cyl
	water.material_override = MaterialGenerator.get_material("water_stream")
	water.position = Vector3(0, 0.05, 0)
	root.add_child(water)

	# Acacia Trees
	for p in [Vector3(-14.0, 0, -12.0), Vector3(14.0, 0, -10.0), Vector3(-12.0, 0, 14.0)]:
		_create_acacia_tree(root, p)

	# Termite Mounds
	for p in [Vector3(-8.0, 0, 12.0), Vector3(10.0, 0, 8.0)]:
		_create_termite_mound(root, p)

	# Wildlife: Gazelles and Lion
	_spawn_animal(root, "gazelle", Vector3(-6.0, 0.5, -4.0))
	_spawn_animal(root, "gazelle", Vector3(-4.0, 0.5, -6.0))
	_spawn_animal(root, "lion", Vector3(12.0, 0.5, -14.0))

# ==============================================================================
# 2. RAINFOREST BIOME
# ==============================================================================
func build_rainforest(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "RainforestBiome"
	root.position = origin
	add_child(root)

	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(50.0, 1.0, 50.0), "rainforest_canopy")

	# Canopy Giant Trees & Vines
	for p in [Vector3(-12.0, 0, -12.0), Vector3(12.0, 0, -12.0), Vector3(0, 0, 12.0)]:
		_create_canopy_tree(root, p)

	# Wildlife: Jaguar and Macaw
	_spawn_animal(root, "jaguar", Vector3(-5.0, 0.5, -5.0))
	_spawn_animal(root, "macaw", Vector3(0, 4.5, 12.0))

# ==============================================================================
# 3. ALPINE FOREST BIOME
# ==============================================================================
func build_alpine_forest(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "AlpineBiome"
	root.position = origin
	add_child(root)

	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(50.0, 1.0, 50.0), "alpine_rock")

	# Mountain Crags & Pines
	for p in [Vector3(-10.0, 0, -10.0), Vector3(10.0, 0, -10.0), Vector3(0, 0, 10.0)]:
		_create_pine_tree(root, p)

	# Wildlife: Snow Leopard and Mountain Goat
	_spawn_animal(root, "snow_leopard", Vector3(8.0, 0.5, -8.0))
	_spawn_animal(root, "mountain_goat", Vector3(-8.0, 0.5, 6.0))

# ==============================================================================
# 4. TROPICAL COAST BIOME
# ==============================================================================
func build_tropical_coast(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "CoastBiome"
	root.position = origin
	add_child(root)

	# Sand dunes
	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(50.0, 1.0, 50.0), "tropical_sand")

	# Ocean shallows
	var ocean = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(48.0, 0.2, 16.0)
	ocean.mesh = b_box
	ocean.material_override = MaterialGenerator.get_material("water_stream")
	ocean.position = Vector3(0, 0.1, 16.0)
	root.add_child(ocean)

	# Palm trees
	for p in [Vector3(-12.0, 0, -6.0), Vector3(12.0, 0, -6.0)]:
		_create_palm_tree(root, p)

	# Wildlife: Sea Turtle
	_spawn_animal(root, "sea_turtle", Vector3(0, 0.3, 10.0))

# ==============================================================================
# 5. WETLANDS BIOME
# ==============================================================================
func build_wetlands(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "WetlandsBiome"
	root.position = origin
	add_child(root)

	_add_terrain_slab(root, Vector3(0, -0.5, 0), Vector3(50.0, 1.0, 50.0), "wetland_mud")

	# Marsh basins & reeds
	for p in [Vector3(-8.0, 0.05, -6.0), Vector3(8.0, 0.05, 6.0)]:
		var pool = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 6.0
		cyl.bottom_radius = 6.0
		cyl.height = 0.08
		pool.mesh = cyl
		pool.material_override = MaterialGenerator.get_material("water_stream")
		pool.position = p
		root.add_child(pool)

	# Wildlife: Crocodile and Flamingo
	_spawn_animal(root, "crocodile", Vector3(-4.0, 0.3, -4.0))
	_spawn_animal(root, "flamingo", Vector3(6.0, 0.8, 4.0))

# ==============================================================================
# ENVIRONMENT & FLORA HELPERS
# ==============================================================================
func _add_terrain_slab(parent: Node3D, pos: Vector3, size: Vector3, mat_name: String) -> void:
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

func _create_acacia_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.5
	cyl.height = 4.5
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 2.25, 0)
	parent.add_child(trunk)

	var canopy = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 3.5
	disc.bottom_radius = 3.2
	disc.height = 0.8
	canopy.mesh = disc
	canopy.material_override = MaterialGenerator.get_material("lush_grass")
	canopy.position = pos + Vector3(0, 4.8, 0)
	parent.add_child(canopy)

func _create_canopy_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.8
	cyl.height = 8.0
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 4.0, 0)
	parent.add_child(trunk)

	var leaves = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 4.0
	sphere.height = 5.0
	leaves.mesh = sphere
	leaves.material_override = MaterialGenerator.get_material("rainforest_canopy")
	leaves.position = pos + Vector3(0, 8.5, 0)
	parent.add_child(leaves)

func _create_pine_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.35
	cyl.height = 3.5
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 1.75, 0)
	parent.add_child(trunk)

	var foliage = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 2.2
	cone.height = 5.0
	foliage.mesh = cone
	foliage.material_override = MaterialGenerator.get_material("rainforest_canopy")
	foliage.position = pos + Vector3(0, 5.0, 0)
	parent.add_child(foliage)

func _create_palm_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.35
	cyl.height = 5.5
	trunk.mesh = cyl
	trunk.material_override = MaterialGenerator.get_material("wood_bark")
	trunk.position = pos + Vector3(0, 2.75, 0)
	trunk.rotation_degrees.z = 8.0
	parent.add_child(trunk)

	var fronds = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 2.8
	disc.bottom_radius = 2.4
	disc.height = 0.4
	fronds.mesh = disc
	fronds.material_override = MaterialGenerator.get_material("lush_grass")
	fronds.position = pos + Vector3(0.5, 5.5, 0)
	parent.add_child(fronds)

func _create_termite_mound(parent: Node3D, pos: Vector3) -> void:
	var mound = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.15
	cone.bottom_radius = 0.7
	cone.height = 2.2
	mound.mesh = cone
	mound.material_override = MaterialGenerator.get_material("savannah_dirt")
	mound.position = pos + Vector3(0, 1.1, 0)
	parent.add_child(mound)

func _spawn_animal(parent: Node3D, sp_id: String, pos: Vector3) -> Node3D:
	var animal = WildAnimalScript.new()
	animal.species_id = sp_id
	animal.position = pos
	parent.add_child(animal)
	spawned_animals.append(animal)
	return animal
