class_name SkyboundWorld
extends Node3D

## SkyboundWorld: 5 Interconnected Production-Quality 3D Regions for Skybound Odyssey
## Features Emerald Isles, Crystal Caverns, Sunken Sky Temple, Frost Peaks, and Storm Citadel.
## Houses complete puzzle chains, traversal obstacles, NPCs, collectible shards, and checkpoints.

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
	# 1. Emerald Isles (Region 0: 0, 0, 0)
	build_emerald_isles(Vector3(0, 0, 0))

	# 2. Crystal Caverns (Region 1: 0, -25.0, 70.0)
	build_crystal_caverns(Vector3(0, -20.0, 80.0))

	# 3. Sunken Sky Temple (Region 2: 90.0, 10.0, 0)
	build_sky_temple(Vector3(95.0, 12.0, 0))

	# 4. Frost Peaks (Region 3: -90.0, 25.0, 0)
	build_frost_peaks(Vector3(-95.0, 24.0, 0))

	# 5. Storm Citadel (Region 4: 0, 45.0, -110.0)
	build_storm_citadel(Vector3(0, 42.0, -115.0))

# ==============================================================================
# REGION 1: EMERALD ISLES (Floating Lush Islands & Ancient Ruins)
# ==============================================================================
func build_emerald_isles(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "EmeraldIsles"
	root.position = origin
	add_child(root)

	# Main Central Island
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(32.0, 6.0, 32.0), "lush_grass", "ancient_stone")

	# Ancient Ruin Archways & Columns
	_create_ruin_arch(root, Vector3(0, 3.0, -8.0))
	_create_pillar(root, Vector3(-8.0, 3.0, 8.0), 5.0)
	_create_pillar(root, Vector3(8.0, 3.0, 8.0), 5.0)

	# Stepping Stone Floating Platforms
	_create_floating_platform(root, Vector3(0, 1.5, 22.0), Vector3(5.0, 1.2, 5.0))
	_create_floating_platform(root, Vector3(0, 3.0, 32.0), Vector3(6.0, 1.2, 6.0))

	# Tutorial Puzzle: Pressure plate opens ruin gate
	var plate = PuzzleElementsScript.PressurePlate.new()
	plate.position = Vector3(0, 3.0, 6.0)
	root.add_child(plate)

	var door = PuzzleElementsScript.PuzzleDoor.new()
	door.position = Vector3(0, 3.0, -14.0)
	door.register_trigger(plate.state_changed)
	root.add_child(door)
	puzzle_doors.append(door)

	# NPC: Elder Zephyr
	var elder = _create_npc("Elder Zephyr", Vector3(5.0, 3.0, 2.0), "Welcome, Skyfarer! Collect the energy shards to awaken the ancient temples.")
	root.add_child(elder)
	npcs.append(elder)

	# Shards
	_spawn_shard(root, Vector3(0, 4.2, 22.0))
	_spawn_shard(root, Vector3(0, 5.8, 32.0))
	_spawn_shard(root, Vector3(0, 4.2, -18.0))

	# Region trigger volume
	_create_region_detector(root, Vector3.ZERO, Vector3(45.0, 15.0, 45.0), 0)

# ==============================================================================
# REGION 2: CRYSTAL CAVERNS (Luminous Crystals & Chasm Traversal)
# ==============================================================================
func build_crystal_caverns(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "CrystalCaverns"
	root.position = origin
	add_child(root)

	# Subterranean cavern floor
	_create_box_collider(root, Vector3(0, 0, 0), Vector3(36.0, 4.0, 42.0), "dark_hull")

	# Luminous Glowing Crystal Formations
	for pos in [Vector3(-10.0, 2.0, -10.0), Vector3(10.0, 2.0, -10.0), Vector3(-12.0, 2.0, 10.0), Vector3(12.0, 2.0, 10.0)]:
		_create_crystal_cluster(root, pos, "crystal_cyan")
	for pos in [Vector3(0, 2.0, -14.0), Vector3(0, 2.0, 14.0)]:
		_create_crystal_cluster(root, pos, "crystal_magenta")

	# Chasm gap with Grapple Anchors
	var anchor1 = PuzzleElementsScript.GrappleAnchor.new()
	anchor1.position = Vector3(-6.0, 8.0, 0)
	root.add_child(anchor1)

	var anchor2 = PuzzleElementsScript.GrappleAnchor.new()
	anchor2.position = Vector3(6.0, 8.0, 0)
	root.add_child(anchor2)

	# Shards
	_spawn_shard(root, Vector3(-10.0, 4.0, -10.0))
	_spawn_shard(root, Vector3(10.0, 4.0, 10.0))

	_create_region_detector(root, Vector3.ZERO, Vector3(45.0, 18.0, 50.0), 1)

# ==============================================================================
# REGION 3: SUNKEN SKY TEMPLE (Floating Columns & Wind Updrafts)
# ==============================================================================
func build_sky_temple(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "SunkenSkyTemple"
	root.position = origin
	add_child(root)

	# Main Temple Plaza
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(34.0, 5.0, 34.0), "ancient_stone", "temple_gold")

	# Gilded Columns
	for cp in [Vector3(-10.0, 2.5, -10.0), Vector3(10.0, 2.5, -10.0), Vector3(-10.0, 2.5, 10.0), Vector3(10.0, 2.5, 10.0)]:
		_create_pillar(root, cp, 6.5, "temple_gold")

	# Wind Updraft for Glider Flight
	var wind = PuzzleElementsScript.WindCurrent.new()
	wind.position = Vector3(0, 2.5, 14.0)
	root.add_child(wind)

	# Elevated Altar reached via Wind Gliding
	_create_floating_platform(root, Vector3(0, 16.0, 22.0), Vector3(8.0, 1.5, 8.0), "temple_gold")

	# Puzzle Switch on elevated altar
	var p_switch = PuzzleElementsScript.PuzzleSwitch.new()
	p_switch.position = Vector3(0, 16.8, 22.0)
	root.add_child(p_switch)

	# NPC: Scholar Lyra
	var scholar = _create_npc("Scholar Lyra", Vector3(-4.0, 2.5, -4.0), "Use the wind thermal to glide up to the Sunken Altar and activate the temple core!")
	root.add_child(scholar)
	npcs.append(scholar)

	# Temple Shard on elevated altar
	_spawn_shard(root, Vector3(0, 18.5, 22.0))

	_create_region_detector(root, Vector3.ZERO, Vector3(45.0, 30.0, 45.0), 2)

# ==============================================================================
# REGION 4: FROST PEAKS (Snow-Covered Crags & Ice Platforms)
# ==============================================================================
func build_frost_peaks(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "FrostPeaks"
	root.position = origin
	add_child(root)

	# Icy Mountain Base
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(32.0, 7.0, 32.0), "frost_ice", "alpine_rock")

	# Ascending Crag Ledges for mantling & double-jumping
	_create_floating_platform(root, Vector3(-10.0, 4.0, 0), Vector3(6.0, 1.5, 6.0), "frost_ice")
	_create_floating_platform(root, Vector3(-10.0, 8.0, 10.0), Vector3(6.0, 1.5, 6.0), "frost_ice")
	_create_floating_platform(root, Vector3(0.0, 12.0, 12.0), Vector3(7.0, 1.5, 7.0), "frost_ice")

	# NPC: Scout Kael
	var scout = _create_npc("Scout Kael", Vector3(3.0, 3.5, 0), "The storm clouds ahead guard the Citadel. Use double jumps to climb the icy peaks!")
	root.add_child(scout)
	npcs.append(scout)

	# Shards
	_spawn_shard(root, Vector3(0.0, 14.0, 12.0))

	_create_region_detector(root, Vector3.ZERO, Vector3(45.0, 25.0, 45.0), 3)

# ==============================================================================
# REGION 5: STORM CITADEL (Apex Challenge Fortress)
# ==============================================================================
func build_storm_citadel(origin: Vector3) -> void:
	var root = Node3D.new()
	root.name = "StormCitadel"
	root.position = origin
	add_child(root)

	# Main Citadel Fortress Platform
	_create_floating_island(root, Vector3(0, 0, 0), Vector3(42.0, 8.0, 42.0), "storm_citadel", "dark_hull")

	# Lightning Pylons
	for lp in [Vector3(-14.0, 4.0, -14.0), Vector3(14.0, 4.0, -14.0), Vector3(-14.0, 4.0, 14.0), Vector3(14.0, 4.0, 14.0)]:
		_create_lightning_pylon(root, lp)

	# Apex Artifact Pedestal
	var pedestal = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.5
	cyl.height = 1.2
	pedestal.mesh = cyl
	pedestal.material_override = MaterialGenerator.get_material("temple_gold")
	pedestal.position = Vector3(0, 4.6, 0)
	root.add_child(pedestal)

	# Apex Skybound Artifact Shard
	_spawn_shard(root, Vector3(0, 6.5, 0), 5) # 5 shards value

	_create_region_detector(root, Vector3.ZERO, Vector3(50.0, 30.0, 50.0), 4)

# ==============================================================================
# PROCEDURAL ENVIRONMENT BUILDERS
# ==============================================================================
func _create_floating_island(parent: Node3D, pos: Vector3, size: Vector3, top_mat: String, base_mat: String) -> void:
	var island = StaticBody3D.new()
	island.collision_layer = GameConstants.LAYER_WORLD
	island.position = pos

	# Top turf slab
	var top_mesh = MeshInstance3D.new()
	var b_top = BoxMesh.new()
	b_top.size = Vector3(size.x, 1.2, size.z)
	top_mesh.mesh = b_top
	top_mesh.material_override = MaterialGenerator.get_material(top_mat)
	top_mesh.position = Vector3(0, size.y * 0.5 - 0.6, 0)
	island.add_child(top_mesh)

	# Under-rock base
	var base_mesh = MeshInstance3D.new()
	var b_base = BoxMesh.new()
	b_base.size = Vector3(size.x * 0.85, size.y - 1.2, size.z * 0.85)
	base_mesh.mesh = b_base
	base_mesh.material_override = MaterialGenerator.get_material(base_mat)
	base_mesh.position = Vector3(0, -0.6, 0)
	island.add_child(base_mesh)

	# Collision
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = size
	col.shape = col_box
	island.add_child(col)

	parent.add_child(island)

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

	var col = CollisionShape3D.new()
	var col_cyl = CylinderShape3D.new()
	col_cyl.radius = 0.75
	col_cyl.height = h
	col.shape = col_cyl
	col.position = Vector3(0, h * 0.5, 0)
	pillar.add_child(col)

	parent.add_child(pillar)

func _create_ruin_arch(parent: Node3D, pos: Vector3) -> void:
	var arch = Node3D.new()
	arch.position = pos
	_create_pillar(arch, Vector3(-3.0, 0, 0), 6.0)
	_create_pillar(arch, Vector3(3.0, 0, 0), 6.0)

	var lintel = StaticBody3D.new()
	lintel.collision_layer = GameConstants.LAYER_WORLD
	lintel.position = Vector3(0, 6.0, 0)
	var mi = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(7.5, 1.2, 1.4)
	mi.mesh = b_box
	mi.material_override = MaterialGenerator.get_material("ancient_stone")
	lintel.add_child(mi)
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(7.5, 1.2, 1.4)
	col.shape = col_box
	lintel.add_child(col)
	arch.add_child(lintel)

	parent.add_child(arch)

func _create_crystal_cluster(parent: Node3D, pos: Vector3, mat_name: String) -> void:
	var cluster = Node3D.new()
	cluster.position = pos

	var mat = MaterialGenerator.get_material(mat_name)
	for i in range(3):
		var mi = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.8, 2.5 + i * 0.8, 0.8)
		mi.mesh = prism
		mi.material_override = mat
		mi.position = Vector3((i - 1) * 0.6, 1.2, (i - 1) * 0.3)
		mi.rotation_degrees.z = (i - 1) * 15.0
		cluster.add_child(mi)

	parent.add_child(cluster)

func _create_lightning_pylon(parent: Node3D, pos: Vector3) -> void:
	var pylon = StaticBody3D.new()
	pylon.collision_layer = GameConstants.LAYER_WORLD
	pylon.position = pos

	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.9
	cyl.height = 12.0
	mi.mesh = cyl
	mi.material_override = MaterialGenerator.get_material("sci_fi_metal")
	mi.position = Vector3(0, 6.0, 0)
	pylon.add_child(mi)

	var orb = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.8
	s_mesh.height = 1.6
	orb.mesh = s_mesh
	orb.material_override = MaterialGenerator.get_material("neon_cyan")
	orb.position = Vector3(0, 12.4, 0)
	pylon.add_child(orb)

	var col = CollisionShape3D.new()
	var c_cyl = CylinderShape3D.new()
	c_cyl.radius = 0.9
	c_cyl.height = 12.0
	col.shape = c_cyl
	col.position = Vector3(0, 6.0, 0)
	pylon.add_child(col)

	parent.add_child(pylon)

func _create_npc(p_name: String, pos: Vector3, dialogue: String) -> Node3D:
	var npc = CharacterBody3D.new()
	npc.name = p_name
	npc.position = pos
	npc.collision_layer = GameConstants.LAYER_WORLD

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
	c_shape.radius = 0.4
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

	var mi = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.6, 0.9, 0.6)
	mi.mesh = prism
	mi.material_override = MaterialGenerator.get_material("crystal_cyan")
	shard_body.add_child(mi)

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.2
	col.shape = sphere
	shard_body.add_child(col)

	shard_body.body_entered.connect(func(body: Node3D):
		if body.has_method("collect_shard"):
			body.collect_shard(val)
			shard_picked_up.emit(shard_body)
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
