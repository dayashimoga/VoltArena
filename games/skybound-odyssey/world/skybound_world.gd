class_name SkyboundWorld
extends Node3D

## SkyboundWorld: 5 Distinct Production-Quality 3D Exploration Regions for Skybound Odyssey.
## Features Emerald Isles, Crystal Caverns, Sunken Sky Temple, Frost Peaks, and Storm Citadel.
## Features multi-tiered floating islands, stalactite underbellies, waterfalls with mist,
## ancient ruins, grapple chasms, wind updrafts, and complete progression.

signal region_entered(region_name: String)
signal shard_picked_up(shard_node: Node3D)
signal puzzle_solved(puzzle_id: String)
signal region_unlocked(region_id: int)

const PuzzleElementsScript = preload("res://shared/gameplay/puzzle_elements.gd")
const InteractionAreaScript = preload("res://shared/gameplay/interaction_area.gd")

var unlocked_regions: Array[int] = [0] # Region 0 (Emerald Isles) unlocked by default
var current_region_idx: int = 0
var region_names: Array[String] = [
	"Emerald Isles",
	"Crystal Caverns",
	"Sunken Sky Temple",
	"Frost Peaks",
	"Storm Citadel"
]

# Interactive nodes
var npcs: Array[Node3D] = []
var shards: Array[Node3D] = []
var puzzle_doors: Array[Node3D] = []

func _ready() -> void:
	build_world()

func build_world() -> void:
	if get_child_count() > 0:
		return
	# 1. Emerald Isles (Region 0: 0, 0, 0)
	build_emerald_isles(Vector3(0, 0, 0))

	# 2. Crystal Caverns (Region 1: 0, -20.0, 80.0)
	build_crystal_caverns(Vector3(0, -20.0, 80.0))

	# 3. Sunken Sky Temple (Region 2: 95.0, 12.0, 0)
	build_sky_temple(Vector3(95.0, 12.0, 0))

	# 4. Frost Peaks (Region 3: -95.0, 24.0, 0)
	build_frost_peaks(Vector3(-95.0, 24.0, 0))

	# 5. Storm Citadel (Region 4: 0, 42.0, -115.0)
	build_storm_citadel(Vector3(0, 42.0, -115.0))

# ==============================================================================
# REGION 1: EMERALD ISLES (Lush Floating Islands, Waterfalls & Ancient Ruins)
# ==============================================================================
func build_emerald_isles(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "EmeraldIsles"
	root.position = origin
	add_child(root)

	# Main Central Island with tiered plateau
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(36.0, 8.0, 36.0), "lush_grass", "ancient_stone")

	# Upper Temple Terrace
	_create_floating_platform(root, Vector3(0, 3.5, -10.0), Vector3(18.0, 1.4, 14.0), "ancient_stone")

	# Ancient Ruin Archways & Columns
	_create_ruin_arch(root, Vector3(0, 4.2, -14.0))
	_create_pillar(root, Vector3(-7.0, 4.2, -6.0), 5.5, "ancient_stone")
	_create_pillar(root, Vector3(7.0, 4.2, -6.0), 5.5, "ancient_stone")
	_create_pillar(root, Vector3(-12.0, 0.8, 8.0), 4.5, "ancient_stone")
	_create_pillar(root, Vector3(12.0, 0.8, 8.0), 4.5, "ancient_stone")

	# Stepping Stone Floating Platforms leading to outer shard
	_create_floating_platform(root, Vector3(0, 1.5, 22.0), Vector3(6.5, 1.8, 6.5), "ancient_stone")
	_create_floating_platform(root, Vector3(0, 3.5, 34.0), Vector3(7.5, 2.0, 7.5), "ancient_stone")

	# Waterfall cascading from island edge into void
	_create_waterfall(root, Vector3(14.0, 0.5, 0), Vector3(4.0, 14.0, 0.8))

	# Foliage & trees
	for p in [Vector3(-10.0, 0.8, -4.0), Vector3(10.0, 0.8, 6.0), Vector3(-8.0, 0.8, 12.0)]:
		var tree = MeshBuilder.build_pine_tree(7.5)
		tree.position = p
		root.add_child(tree)

	# Tutorial Puzzle: Pressure plate opens ruin gate
	var plate = PuzzleElementsScript.PressurePlate.new()
	plate.position = Vector3(0, 4.2, 2.0)
	root.add_child(plate)

	var door = PuzzleElementsScript.PuzzleDoor.new()
	door.position = Vector3(0, 4.2, -14.0)
	door.register_trigger(plate.state_changed)
	root.add_child(door)
	puzzle_doors.append(door)

	# NPC: Elder Zephyr
	var elder = _create_npc("Elder Zephyr", Vector3(6.0, 4.2, -2.0), "Welcome, Skyfarer! Collect the energy shards to awaken the ancient temples.")
	root.add_child(elder)
	npcs.append(elder)

	# Shards
	_spawn_shard(root, Vector3(0, 4.8, 22.0))
	_spawn_shard(root, Vector3(0, 6.5, 34.0))
	_spawn_shard(root, Vector3(0, 5.8, -18.0))

	# Region trigger volume
	_create_region_detector(root, Vector3.ZERO, Vector3(55.0, 20.0, 55.0), 0)

# ==============================================================================
# REGION 2: CRYSTAL CAVERNS (Luminous Crystals & Chasm Traversal)
# ==============================================================================
func build_crystal_caverns(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "CrystalCaverns"
	root.position = origin
	add_child(root)

	# Subterranean cavern floor with basalt texture
	_create_box_collider(root, Vector3(0, 0, 0), Vector3(40.0, 5.0, 48.0), "dark_hull")

	# Luminous Glowing Crystal Formations (cyan, magenta, amber)
	for pos in [Vector3(-12.0, 2.5, -12.0), Vector3(12.0, 2.5, -12.0), Vector3(-14.0, 2.5, 12.0), Vector3(14.0, 2.5, 12.0)]:
		_create_crystal_cluster(root, pos, "neon_cyan")
	for pos in [Vector3(0, 2.5, -16.0), Vector3(0, 2.5, 16.0)]:
		_create_crystal_cluster(root, pos, "neon_magenta")

	# Basalt Arch Bridges over chasm
	var arch = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(8.0, 1.4, 28.0)
	arch.mesh = b_box
	arch.material_override = MaterialGenerator.get_material("dark_hull")
	arch.position = Vector3(0, 1.0, 0)
	root.add_child(arch)

	# Chasm gap with Grapple Anchors
	var anchor1 = PuzzleElementsScript.GrappleAnchor.new()
	anchor1.position = Vector3(-8.0, 9.0, 0)
	root.add_child(anchor1)

	var anchor2 = PuzzleElementsScript.GrappleAnchor.new()
	anchor2.position = Vector3(8.0, 9.0, 0)
	root.add_child(anchor2)

	# Shards
	_spawn_shard(root, Vector3(-12.0, 5.0, -12.0))
	_spawn_shard(root, Vector3(12.0, 5.0, 12.0))

	_create_region_detector(root, Vector3.ZERO, Vector3(50.0, 22.0, 55.0), 1)

# ==============================================================================
# REGION 3: SUNKEN SKY TEMPLE (Floating Columns & Wind Updrafts)
# ==============================================================================
func build_sky_temple(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "SunkenSkyTemple"
	root.position = origin
	add_child(root)

	# Main Temple Plaza
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(38.0, 6.0, 38.0), "ancient_stone", "temple_gold")

	# Gilded Columns
	for cp in [Vector3(-12.0, 3.0, -12.0), Vector3(12.0, 3.0, -12.0), Vector3(-12.0, 3.0, 12.0), Vector3(12.0, 3.0, 12.0)]:
		_create_pillar(root, cp, 7.5, "temple_gold")

	# Wind Updraft for Glider Flight
	var wind = PuzzleElementsScript.WindCurrent.new()
	wind.position = Vector3(0, 3.0, 14.0)
	root.add_child(wind)

	# Elevated Altar reached via Wind Gliding
	_create_floating_platform(root, Vector3(0, 18.0, 24.0), Vector3(9.0, 2.0, 9.0), "temple_gold")
	_spawn_shard(root, Vector3(0, 20.2, 24.0), 2)

	_create_region_detector(root, Vector3.ZERO, Vector3(50.0, 30.0, 50.0), 2)

# ==============================================================================
# REGION 4: FROST PEAKS (Jagged Ice Pinnacles & Narrow Glaciers)
# ==============================================================================
func build_frost_peaks(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "FrostPeaks"
	root.position = origin
	add_child(root)

	# Snowy Mountain Plateau
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(36.0, 10.0, 36.0), "arctic_ice", "alpine_rock")

	# Jagged Ice Formations
	for ip in [Vector3(-10.0, 5.0, -10.0), Vector3(10.0, 5.0, -10.0), Vector3(-10.0, 5.0, 10.0), Vector3(10.0, 5.0, 10.0)]:
		_create_ice_formation(root, ip)

	# Frozen narrow bridge to isolated peak
	_create_floating_platform(root, Vector3(0, 5.0, -22.0), Vector3(3.2, 1.2, 16.0), "arctic_ice")
	_create_floating_platform(root, Vector3(0, 7.0, -36.0), Vector3(8.0, 2.0, 8.0), "arctic_ice")
	_spawn_shard(root, Vector3(0, 9.2, -36.0), 2)

	_create_region_detector(root, Vector3.ZERO, Vector3(50.0, 25.0, 55.0), 3)

# ==============================================================================
# REGION 5: STORM CITADEL (Obsidian Sky Fortress & Apex Relic Altar)
# ==============================================================================
func build_storm_citadel(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "StormCitadel"
	root.position = origin
	add_child(root)

	# Main Citadel Fortress Platform
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(46.0, 10.0, 46.0), "storm_citadel", "dark_hull")

	# Lightning Pylons with crackling energy
	for lp in [Vector3(-16.0, 5.0, -16.0), Vector3(16.0, 5.0, -16.0), Vector3(-16.0, 5.0, 16.0), Vector3(16.0, 5.0, 16.0)]:
		_create_lightning_pylon(root, lp)

	# Apex Artifact Pedestal
	var pedestal = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.8
	cyl.height = 1.4
	pedestal.mesh = cyl
	pedestal.material_override = MaterialGenerator.get_material("temple_gold")
	pedestal.position = Vector3(0, 5.7, 0)
	root.add_child(pedestal)

	# Apex Skybound Artifact Shard
	_spawn_shard(root, Vector3(0, 7.8, 0), 5) # 5 shards value

	_create_region_detector(root, Vector3.ZERO, Vector3(55.0, 35.0, 55.0), 4)

# ==============================================================================
# PROCEDURAL ENVIRONMENT BUILDERS
# ==============================================================================
func _create_floating_island(parent: Node3D, pos: Vector3, size: Vector3, top_mat: String, base_mat: String) -> void:
	var island = StaticBody3D.new()
	island.collision_layer = GameConstants.LAYER_WORLD
	island.position = pos

	# 1. Top turf slab with stepped elevation
	var top_mesh = MeshInstance3D.new()
	var b_top = BoxMesh.new()
	b_top.size = Vector3(size.x, 1.4, size.z)
	top_mesh.mesh = b_top
	top_mesh.material_override = MaterialGenerator.get_material(top_mat)
	top_mesh.position = Vector3(0, size.y * 0.5 - 0.7, 0)
	island.add_child(top_mesh)

	# 2. Stepped middle rock ledge
	var mid_mesh = MeshInstance3D.new()
	var b_mid = BoxMesh.new()
	b_mid.size = Vector3(size.x * 0.92, size.y * 0.4, size.z * 0.92)
	mid_mesh.mesh = b_mid
	mid_mesh.material_override = MaterialGenerator.get_material(base_mat)
	mid_mesh.position = Vector3(0, size.y * 0.5 - 1.4 - (size.y * 0.2), 0)
	island.add_child(mid_mesh)

	# 3. Inverted rock stalactite underbelly (3 tapered cones pointing downward)
	for i in range(3):
		var cone_mesh = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = (size.x * 0.35) - float(i) * 1.5
		cone.bottom_radius = 0.4
		cone.height = size.y * 0.75 + float(i) * 2.0
		cone_mesh.mesh = cone
		cone_mesh.material_override = MaterialGenerator.get_material(base_mat)
		var offset_x = (float(i) - 1.0) * (size.x * 0.22)
		cone_mesh.position = Vector3(offset_x, -size.y * 0.5, 0)
		island.add_child(cone_mesh)

	# Collision
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = size
	col.shape = col_box
	island.add_child(col)

	parent.add_child(island)

func _create_waterfall(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var stream = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	stream.mesh = box
	stream.material_override = MaterialGenerator.get_material("water_stream")
	stream.position = pos - Vector3(0, size.y * 0.5, 0)
	parent.add_child(stream)

	# Mist emitter at waterfall impact
	var mist = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 2.5
	sphere.height = 1.2
	mist.mesh = sphere
	mist.material_override = MaterialGenerator.get_material("neon_cyan")
	mist.position = pos - Vector3(0, size.y, 0)
	parent.add_child(mist)

func _create_floating_platform(parent: Node3D, pos: Vector3, size: Vector3, mat_name: String = "ancient_stone") -> void:
	var plat = StaticBody3D.new()
	plat.collision_layer = GameConstants.LAYER_WORLD
	plat.position = pos

	var mesh_inst = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = size
	mesh_inst.mesh = b_mesh
	mesh_inst.material_override = MaterialGenerator.get_material(mat_name)
	plat.add_child(mesh_inst)

	# Inverted stone taper under platform
	var under = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = size.x * 0.45
	cone.bottom_radius = 0.2
	cone.height = size.y * 1.5
	under.mesh = cone
	under.material_override = MaterialGenerator.get_material(mat_name)
	under.position = Vector3(0, -size.y * 0.8, 0)
	plat.add_child(under)

	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = size
	col.shape = col_box
	plat.add_child(col)

	parent.add_child(plat)

func _create_box_collider(parent: Node3D, pos: Vector3, size: Vector3, mat_name: String) -> void:
	var sb = StaticBody3D.new()
	sb.collision_layer = GameConstants.LAYER_WORLD
	sb.position = pos

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = MaterialGenerator.get_material(mat_name)
	sb.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = size
	col.shape = col_box
	sb.add_child(col)

	parent.add_child(sb)

func _create_pillar(parent: Node3D, pos: Vector3, h: float, mat_name: String = "ancient_stone") -> void:
	var pillar = StaticBody3D.new()
	pillar.collision_layer = GameConstants.LAYER_WORLD
	pillar.position = pos

	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.65
	cyl.bottom_radius = 0.75
	cyl.height = h
	var mi = MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = MaterialGenerator.get_material(mat_name)
	mi.position = Vector3(0, h * 0.5, 0)
	pillar.add_child(mi)

	# Capital & Base plinths
	var cap = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.8, 0.4, 1.8)
	cap.mesh = box
	cap.material_override = MaterialGenerator.get_material(mat_name)
	cap.position = Vector3(0, h + 0.2, 0)
	pillar.add_child(cap)

	var col = CollisionShape3D.new()
	var col_cyl = CylinderShape3D.new()
	col_cyl.radius = 0.85
	col_cyl.height = h + 0.4
	col.shape = col_cyl
	col.position = Vector3(0, h * 0.5, 0)
	pillar.add_child(col)

	parent.add_child(pillar)

func _create_ruin_arch(parent: Node3D, pos: Vector3) -> void:
	var arch = Node3D.new()
	arch.position = pos

	# Stepped stone plinth base
	var base_sb = StaticBody3D.new()
	base_sb.collision_layer = GameConstants.LAYER_WORLD
	var b_mi = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(11.0, 0.6, 3.5)
	b_mi.mesh = b_box
	b_mi.material_override = MaterialGenerator.get_material("ancient_stone")
	b_mi.position = Vector3(0, 0.3, 0)
	base_sb.add_child(b_mi)
	var b_col = CollisionShape3D.new()
	var b_cbox = BoxShape3D.new()
	b_cbox.size = Vector3(11.0, 0.6, 3.5)
	b_col.shape = b_cbox
	b_col.position = Vector3(0, 0.3, 0)
	base_sb.add_child(b_col)
	arch.add_child(base_sb)

	# Fluted Pillars with stepped capitals
	_create_pillar(arch, Vector3(-3.8, 0.6, 0), 6.5, "ancient_stone")
	_create_pillar(arch, Vector3(3.8, 0.6, 0), 6.5, "ancient_stone")

	# Classical Architrave & Frieze Lintel
	var lintel = StaticBody3D.new()
	lintel.collision_layer = GameConstants.LAYER_WORLD
	lintel.position = Vector3(0, 7.3, 0)
	var mi = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(10.5, 1.2, 2.0)
	mi.mesh = l_box
	mi.material_override = MaterialGenerator.get_material("ancient_stone")
	lintel.add_child(mi)

	# Triangular pediment crest
	var ped = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(9.5, 1.8, 1.6)
	ped.mesh = prism
	ped.material_override = MaterialGenerator.get_material("ancient_stone")
	ped.position = Vector3(0, 1.5, 0)
	lintel.add_child(ped)

	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(10.5, 2.8, 2.0)
	col.shape = col_box
	col.position = Vector3(0, 0.8, 0)
	lintel.add_child(col)
	arch.add_child(lintel)

	# Glowing Runic Portal Archway
	var portal = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(5.6, 6.2, 0.2)
	portal.mesh = p_mesh
	portal.material_override = MaterialGenerator.get_material("hex_grid_cyan")
	portal.position = Vector3(0, 3.8, 0)
	arch.add_child(portal)

	# Two flanking stone braziers with glowing embers
	for bx in [-5.8, 5.8]:
		var brazier = Node3D.new()
		brazier.position = Vector3(bx, 0.6, 1.2)
		var b_cyl = MeshInstance3D.new()
		var c_mesh = CylinderMesh.new()
		c_mesh.top_radius = 0.55
		c_mesh.bottom_radius = 0.4
		c_mesh.height = 1.4
		b_cyl.mesh = c_mesh
		b_cyl.material_override = MaterialGenerator.get_material("ancient_stone")
		b_cyl.position = Vector3(0, 0.7, 0)
		brazier.add_child(b_cyl)

		var ember = MeshInstance3D.new()
		var e_mesh = SphereMesh.new()
		e_mesh.radius = 0.35
		e_mesh.height = 0.4
		ember.mesh = e_mesh
		ember.material_override = MaterialGenerator.get_material("neon_orange")
		ember.position = Vector3(0, 1.5, 0)
		brazier.add_child(ember)
		arch.add_child(brazier)

	parent.add_child(arch)

func _create_crystal_cluster(parent: Node3D, pos: Vector3, mat_name: String) -> void:
	var cluster = Node3D.new()
	cluster.position = pos

	var mat = MaterialGenerator.get_material(mat_name)
	for i in range(4):
		var mi = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.9, 3.0 + i * 0.8, 0.9)
		mi.mesh = prism
		mi.material_override = mat
		var ang = float(i) * (PI * 0.5)
		mi.position = Vector3(cos(ang) * 0.7, 1.5, sin(ang) * 0.7)
		mi.rotation_degrees.z = (float(i) - 1.5) * 12.0
		cluster.add_child(mi)

	parent.add_child(cluster)

func _create_ice_formation(parent: Node3D, pos: Vector3) -> void:
	var form = Node3D.new()
	form.position = pos
	var mat = MaterialGenerator.get_material("arctic_ice")
	for i in range(3):
		var mi = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(1.2, 4.5 + i * 1.0, 1.2)
		mi.mesh = prism
		mi.material_override = mat
		mi.position = Vector3(float(i - 1) * 0.8, 2.2, 0)
		mi.rotation_degrees.x = float(i - 1) * 10.0
		form.add_child(mi)
	parent.add_child(form)

func _create_lightning_pylon(parent: Node3D, pos: Vector3) -> void:
	var pylon = StaticBody3D.new()
	pylon.collision_layer = GameConstants.LAYER_WORLD
	pylon.position = pos

	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 1.1
	cyl.height = 14.0
	mi.mesh = cyl
	mi.material_override = MaterialGenerator.get_material("storm_citadel")
	mi.position = Vector3(0, 7.0, 0)
	pylon.add_child(mi)

	var orb = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 1.0
	s_mesh.height = 2.0
	orb.mesh = s_mesh
	orb.material_override = MaterialGenerator.get_material("neon_cyan")
	orb.position = Vector3(0, 14.5, 0)
	pylon.add_child(orb)

	var col = CollisionShape3D.new()
	var c_cyl = CylinderShape3D.new()
	c_cyl.radius = 1.1
	c_cyl.height = 14.0
	col.shape = c_cyl
	col.position = Vector3(0, 7.0, 0)
	pylon.add_child(col)

	parent.add_child(pylon)

func _create_npc(p_name: String, pos: Vector3, dialogue: String) -> Node3D:
	var npc = CharacterBody3D.new()
	npc.name = p_name
	npc.position = pos
	npc.collision_layer = GameConstants.LAYER_WORLD

	var char_model = ModelCache.get_model("res://assets/models/characters/trooper.glb")
	if char_model:
		char_model.name = "CharacterModel"
		char_model.scale = Vector3(1.0, 1.0, 1.0)
		char_model.rotation_degrees.y = 180.0
		npc.add_child(char_model)
		ModelCache.play_animation(char_model, "Idle", 0.2)
	else:
		var mi = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.4
		cap.height = 1.8
		mi.mesh = cap
		mi.material_override = MaterialGenerator.get_material("temple_gold")
		mi.position = Vector3(0, 0.9, 0)
		npc.add_child(mi)

	var col = CollisionShape3D.new()
	var c_shape = CapsuleShape3D.new()
	c_shape.radius = 0.45
	c_shape.height = 1.8
	col.shape = c_shape
	col.position = Vector3(0, 0.9, 0)
	npc.add_child(col)

	var ia = InteractionAreaScript.new()
	ia.prompt_message = "[E] Speak to " + p_name
	ia.interacted.connect(func(_p):
		var bus = GameConstants.get_autoload(npc, "EventBus")
		if bus:
			bus.show_toast_requested.emit(p_name + ": \"" + dialogue + "\"", Color(1.0, 0.9, 0.3))
	)
	npc.add_child(ia)
	return npc

func _spawn_shard(parent: Node3D, pos: Vector3, val: int = 1) -> void:
	var shard_body = Area3D.new()
	shard_body.name = "EnergyShard"
	shard_body.collision_layer = GameConstants.LAYER_PICKUPS
	shard_body.collision_mask = GameConstants.LAYER_PLAYER
	shard_body.position = pos

	var artifact = MeshBuilder.build_ancient_energy_shard_artifact()
	shard_body.add_child(artifact)

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.2
	col.shape = sphere
	shard_body.add_child(col)

	shard_body.body_entered.connect(func(body: Node3D):
		if body.has_method("collect_shard"):
			body.collect_shard(val)
			shard_picked_up.emit(shard_body)
			var am = GameConstants.get_autoload(shard_body, "AudioManager")
			if am and am.has_method("play_sound"):
				am.play_sound("pickup_ammo", 1.2, 1.2)
			shard_body.queue_free()
	)
	parent.add_child(shard_body)
	shards.append(shard_body)

func _create_region_detector(parent: Node3D, pos: Vector3, size: Vector3, reg_idx: int) -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_PLAYER
	area.position = pos

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	col.shape = box
	area.add_child(col)

	area.body_entered.connect(func(body: Node3D):
		if body.is_in_group("players") or body.name == "Player":
			if current_region_idx != reg_idx:
				current_region_idx = reg_idx
				var reg_name = region_names[reg_idx]
				region_entered.emit(reg_name)
				var bus = GameConstants.get_autoload(area, "EventBus")
				if bus:
					bus.show_toast_requested.emit("ENTERING: " + reg_name.to_upper(), Color(0.2, 0.9, 1.0))
	)
	parent.add_child(area)

func unlock_region(idx: int) -> void:
	if not unlocked_regions.has(idx):
		unlocked_regions.append(idx)
		region_unlocked.emit(idx)

func get_region_node(region_name: String) -> Node3D:
	if get_child_count() == 0:
		build_world()
	for c in get_children():
		if c.name == region_name or c.name == region_name.replace(" ", "") or c.name.to_lower() == region_name.replace(" ", "").to_lower():
			return c
	return null
