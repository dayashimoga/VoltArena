class_name ArenaMapGenerator
extends Node3D

## ArenaMapGenerator: Generates 3 distinct production arenas for Iron Crucible:
## 1. Foundry (Ruined Urban/Industrial Sector with blast furnaces and catwalks)
## 2. Citadel (Orbital Military Facility with observation decks and airlocks)
## 3. Sektor (Reactor and Energy Core Complex with turbine piping and consoles)
## Populated with authentic Kenney & Quaternius 3D modular architecture kits.

@export var map_type: String = "foundry" # "foundry", "citadel", "sektor"
@export var arena_size: Vector2 = Vector2(70, 70)
@export var wall_height: float = 8.0

var capture_zones: Array[Dictionary] = []

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func _ready() -> void:
	build_arena()

func build_arena() -> void:
	match map_type:
		"citadel":
			_build_citadel_map()
		"sektor":
			_build_sektor_map()
		_:
			_build_foundry_map()
	setup_lighting()

func _spawn_prop_asset(asset_name: String, pos: Vector3, rot_y: float = 0.0, s: Vector3 = Vector3(1.0, 1.0, 1.0)) -> Node3D:
	var prop = ModelCacheScript.get_prop(asset_name)
	if prop:
		prop.position = pos
		prop.rotation_degrees.y = rot_y
		prop.scale = s
		add_child(prop)
		return prop
	return null

func _build_foundry_map() -> void:
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5

	# Main Foundry Hexagonal Grid Floor matching Reference Screenshot 1
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "hex_grid_cyan")

	# Perimeter Dark Tactical Bulkhead Walls
	create_box(Vector3(0, wall_height * 0.5, -half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(0, wall_height * 0.5, half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(-half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")
	create_box(Vector3(half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")

	# Horizontal Glowing Cyan Accent Lines along perimeter walls
	for h_y in [2.2, 5.2]:
		create_box(Vector3(0, h_y, -half_z + 0.65), Vector3(arena_size.x, 0.15, 0.15), "neon_cyan")
		create_box(Vector3(0, h_y, half_z - 0.65), Vector3(arena_size.x, 0.15, 0.15), "neon_cyan")
		create_box(Vector3(-half_x + 0.65, h_y, 0), Vector3(0.15, 0.15, arena_size.y), "neon_cyan")
		create_box(Vector3(half_x - 0.65, h_y, 0), Vector3(0.15, 0.15, arena_size.y), "neon_cyan")

	# Glowing Warm Amber/Orange Portal Archways matching Reference Screenshot 1
	_spawn_portal_archway(Vector3(0, 0, -half_z + 2.0), 0.0)
	_spawn_portal_archway(Vector3(0, 0, half_z - 2.0), 180.0)
	_spawn_portal_archway(Vector3(-half_x + 2.0, 0, 0), 90.0)
	_spawn_portal_archway(Vector3(half_x - 2.0, 0, 0), -90.0)

	# Tall Architectural Monolith Pillars with Glowing Cyan Edge Strips
	var monolith_positions = [
		Vector3(-16, 0, -16), Vector3(16, 0, -16),
		Vector3(-16, 0, 16), Vector3(16, 0, 16),
		Vector3(-8, 0, -22), Vector3(8, 0, -22),
		Vector3(-8, 0, 22), Vector3(8, 0, 22)
	]
	for m_pos in monolith_positions:
		_spawn_neon_monolith(m_pos, 8.5)

	# Industrial Catwalk Stairs
	_spawn_prop_asset("stairs_industrial", Vector3(-12, 0, -15), 90.0, Vector3(2.0, 2.0, 2.0))
	_spawn_prop_asset("stairs_industrial", Vector3(12, 0, 15), -90.0, Vector3(2.0, 2.0, 2.0))

	# Heavy High Barriers for combat cover
	for bx in [-14.0, 14.0]:
		_spawn_prop_asset("barrier_high", Vector3(bx, 0, -8.0), 0.0, Vector3(2.2, 2.0, 2.2))
		_spawn_prop_asset("barrier_high", Vector3(bx, 0, 8.0), 180.0, Vector3(2.2, 2.0, 2.2))

	# Central Elevated Tactical Dais
	create_box(Vector3(0, 0.9, 0), Vector3(16.0, 1.8, 16.0), "dark_hull")
	create_box(Vector3(0, 1.85, 0), Vector3(16.0, 0.1, 16.0), "hex_grid_cyan")
	create_box(Vector3(0, 1.9, 0), Vector3(16.2, 0.15, 0.2), "neon_cyan")
	create_box(Vector3(0, 1.9, 0), Vector3(0.2, 0.15, 16.2), "neon_cyan")

	# Pickups
	spawn_pickup(Vector3(0, 2.8, 0), PickupBase.PickupType.ARMOR, 50)
	spawn_pickup(Vector3(-18, 1.0, -10), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(18, 1.0, 10), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(18, 1.0, -10), PickupBase.PickupType.AMMO, 50)
	spawn_pickup(Vector3(-18, 1.0, 10), PickupBase.PickupType.AMMO, 50)

	# Capture Beacons
	_add_capture_beacon("Alpha", Vector3(-18, 0.5, 0), Color(0.0, 0.9, 1.0))
	_add_capture_beacon("Bravo", Vector3(0, 2.2, 0), Color(1.0, 0.6, 0.1))
	_add_capture_beacon("Charlie", Vector3(18, 0.5, 0), Color(0.8, 0.2, 1.0))

func _add_box_to(parent: Node3D, size: Vector3, pos: Vector3, mat_name: String) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = MaterialGenerator.get_material(mat_name)
	body.add_child(mesh_inst)

	parent.add_child(body)
	return body

func _spawn_neon_monolith(pos: Vector3, h: float = 8.5) -> Node3D:
	var root = Node3D.new()
	root.position = pos
	_add_box_to(root, Vector3(2.2, h, 2.2), Vector3(0, h * 0.5, 0), "dark_hull")
	for ox in [-1.12, 1.12]:
		for oz in [-1.12, 1.12]:
			_add_box_to(root, Vector3(0.18, h, 0.18), Vector3(ox, h * 0.5, oz), "neon_cyan")
	add_child(root)
	return root

func _spawn_portal_archway(pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var arch = Node3D.new()
	arch.position = pos
	arch.rotation_degrees.y = rot_y
	_add_box_to(arch, Vector3(0.8, 7.6, 1.2), Vector3(-2.6, 3.8, 0), "dark_hull")
	_add_box_to(arch, Vector3(0.8, 7.6, 1.2), Vector3(2.6, 3.8, 0), "dark_hull")
	_add_box_to(arch, Vector3(6.0, 0.8, 1.2), Vector3(0, 7.6, 0), "dark_hull")
	_add_box_to(arch, Vector3(4.8, 0.25, 1.25), Vector3(0, 7.4, 0), "neon_orange")
	_add_box_to(arch, Vector3(0.25, 7.2, 1.25), Vector3(-2.2, 3.7, 0), "neon_orange")
	_add_box_to(arch, Vector3(0.25, 7.2, 1.25), Vector3(2.2, 3.7, 0), "neon_orange")
	_add_box_to(arch, Vector3(4.4, 7.0, 0.1), Vector3(0, 3.7, 0), "neon_orange")
	var p_light = OmniLight3D.new()
	p_light.light_color = Color(1.0, 0.55, 0.08)
	p_light.light_energy = 3.2
	p_light.omni_range = 9.0
	p_light.position = Vector3(0, 3.8, 0)
	arch.add_child(p_light)
	add_child(arch)
	return arch

func _build_citadel_map() -> void:
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5

	# Orbital Facility Metallic Deck
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "sci_fi_metal")

	# Low Perimeter Bulkheads
	create_box(Vector3(0, 1.5, -half_z), Vector3(arena_size.x, 3.0, 0.8), "dark_hull")
	create_box(Vector3(0, 1.5, half_z), Vector3(arena_size.x, 3.0, 0.8), "dark_hull")
	create_box(Vector3(-half_x, 1.5, 0), Vector3(0.8, 3.0, arena_size.y), "dark_hull")
	create_box(Vector3(half_x, 1.5, 0), Vector3(0.8, 3.0, arena_size.y), "dark_hull")

	# Modular Observation Windows overlooking space
	for wz in [-18.0, 0.0, 18.0]:
		_spawn_prop_asset("wall_window", Vector3(-half_x + 1.2, 0, wz), 90.0, Vector3(2.5, 2.5, 2.5))
		_spawn_prop_asset("wall_window", Vector3(half_x - 1.2, 0, wz), -90.0, Vector3(2.5, 2.5, 2.5))

	# Command Consoles and Terminals
	_spawn_prop_asset("computer_terminal", Vector3(-15, 2.6, -8), 45.0, Vector3(2.0, 2.0, 2.0))
	_spawn_prop_asset("computer_terminal", Vector3(15, 2.6, 8), -135.0, Vector3(2.0, 2.0, 2.0))

	# Security High Barriers
	for wall_z in [-15.0, 15.0]:
		_spawn_prop_asset("barrier_high", Vector3(0, 0, wall_z), 0.0, Vector3(2.5, 2.0, 2.2))

	# Twin Elevated Observation Terraces
	create_box(Vector3(-18.0, 2.5, 0), Vector3(10.0, 5.0, 24.0), "sci_fi_metal")
	create_box(Vector3(18.0, 2.5, 0), Vector3(10.0, 5.0, 24.0), "sci_fi_metal")

	# Industrial Access Stairs
	_spawn_prop_asset("stairs_industrial", Vector3(-18, 0, 14), 0.0, Vector3(2.0, 2.0, 2.0))
	_spawn_prop_asset("stairs_industrial", Vector3(18, 0, -14), 180.0, Vector3(2.0, 2.0, 2.0))

	# Central Energy Concourse
	create_box(Vector3(0, 0.8, 0), Vector3(14.0, 1.6, 14.0), "dark_hull")
	create_box(Vector3(0, 4.2, 0), Vector3(4.0, 0.3, 30.0), "sci_fi_metal")

	# Pickups
	spawn_pickup(Vector3(0, 2.2, 0), PickupBase.PickupType.ARMOR, 50)
	spawn_pickup(Vector3(-18, 5.5, 0), PickupBase.PickupType.HEALTH, 50)
	spawn_pickup(Vector3(18, 5.5, 0), PickupBase.PickupType.HEALTH, 50)
	spawn_pickup(Vector3(0, 4.6, 10), PickupBase.PickupType.AMMO, 60)
	spawn_pickup(Vector3(0, 4.6, -10), PickupBase.PickupType.AMMO, 60)

	_add_capture_beacon("Alpha", Vector3(-18, 5.2, 0), Color(0.0, 0.9, 1.0))
	_add_capture_beacon("Bravo", Vector3(0, 1.8, 0), Color(0.2, 1.0, 0.4))
	_add_capture_beacon("Charlie", Vector3(18, 5.2, 0), Color(1.0, 0.3, 0.8))

func _build_sektor_map() -> void:
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5

	# Reactor Core Foundation Floor
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "sci_fi_metal")

	# Heavy Perimeter Containment
	create_box(Vector3(0, wall_height * 0.5, -half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(0, wall_height * 0.5, half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(-half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")
	create_box(Vector3(half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")

	# 4 Reactor Coolant Pipe Networks
	_spawn_prop_asset("pipe_network", Vector3(-15, 0, -15), 0.0, Vector3(3.0, 3.0, 3.0))
	_spawn_prop_asset("pipe_network", Vector3(15, 0, -15), 90.0, Vector3(3.0, 3.0, 3.0))
	_spawn_prop_asset("pipe_network", Vector3(-15, 0, 15), 270.0, Vector3(3.0, 3.0, 3.0))
	_spawn_prop_asset("pipe_network", Vector3(15, 0, 15), 180.0, Vector3(3.0, 3.0, 3.0))

	# Control Terminals at Reactor Stations
	_spawn_prop_asset("computer_terminal", Vector3(0, 0, -12), 0.0, Vector3(2.5, 2.5, 2.5))
	_spawn_prop_asset("computer_terminal", Vector3(0, 0, 12), 180.0, Vector3(2.5, 2.5, 2.5))

	# High Blast Barriers
	_spawn_prop_asset("barrier_high", Vector3(-8, 0, 0), 90.0, Vector3(2.5, 2.0, 2.0))
	_spawn_prop_asset("barrier_high", Vector3(8, 0, 0), -90.0, Vector3(2.5, 2.0, 2.0))

	# Central Reactor Core Dais
	create_box(Vector3(0, 1.5, 0), Vector3(14.0, 3.0, 14.0), "dark_hull")

	# Overhead Walkways
	create_box(Vector3(0, 5.5, 0), Vector3(8.0, 0.4, 22.0), "sci_fi_metal")
	_spawn_prop_asset("stairs_industrial", Vector3(-4, 0, -10), 0.0, Vector3(2.0, 2.0, 2.0))

	# Pickups
	spawn_pickup(Vector3(0, 3.5, 0), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(0, 6.0, 0), PickupBase.PickupType.ARMOR, 50)
	spawn_pickup(Vector3(-22, 1.0, 0), PickupBase.PickupType.AMMO, 40)
	spawn_pickup(Vector3(22, 1.0, 0), PickupBase.PickupType.AMMO, 40)

	_add_capture_beacon("Alpha", Vector3(-20, 0.5, -20), Color(0.0, 0.9, 1.0))
	_add_capture_beacon("Bravo", Vector3(0, 6.0, 0), Color(1.0, 0.85, 0.1))
	_add_capture_beacon("Charlie", Vector3(20, 0.5, 20), Color(1.0, 0.2, 0.4))

func _add_capture_beacon(beacon_name: String, pos: Vector3, beacon_color: Color) -> void:
	var beacon = Node3D.new()
	beacon.name = "Beacon_" + beacon_name
	beacon.position = pos

	var pad = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 2.2
	cyl.bottom_radius = 2.4
	cyl.height = 0.2
	pad.mesh = cyl
	pad.material_override = MaterialGenerator.get_material("sci_fi_metal")
	beacon.add_child(pad)

	var core = MeshInstance3D.new()
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 1.8
	c_cyl.bottom_radius = 1.8
	c_cyl.height = 0.25
	core.mesh = c_cyl
	core.position = Vector3(0, 0.05, 0)
	var mat = MaterialGenerator.create_pbr_material(beacon_color, 0.2, 0.2, beacon_color, 2.5)
	core.material_override = mat
	beacon.add_child(core)

	add_child(beacon)
	capture_zones.append({
		"name": beacon_name,
		"pos": pos,
		"color": beacon_color,
		"captured_by": 0,
		"progress": 0.0
	})

func create_box(pos: Vector3, size: Vector3, material_name: String) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = MaterialGenerator.get_material(material_name)
	body.add_child(mesh_inst)

	add_child(body)
	return body

func spawn_pickup(pos: Vector3, p_type: PickupBase.PickupType, amt: int) -> void:
	var pickup = PickupBase.new()
	pickup.pickup_type = p_type
	pickup.amount = amt
	pickup.position = pos
	add_child(pickup)

func setup_lighting() -> void:
	var sun = DirectionalLight3D.new()
	sun.name = "KeySun"
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_color = Color(0.65, 0.85, 1.0) # Cool nocturnal Key Light
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(45, -145, 0)
	fill.light_color = Color(0.0, 0.55, 0.85) # Electric cyan fill
	fill.light_energy = 0.5
	fill.shadow_enabled = false
	add_child(fill)

	var corner_lights = [
		Vector3(-22, 6.0, -22),
		Vector3(22, 6.0, -22),
		Vector3(-22, 6.0, 22),
		Vector3(22, 6.0, 22),
		Vector3(0, 7.0, 0)
	]
	for pos in corner_lights:
		var omni = OmniLight3D.new()
		omni.position = pos
		omni.light_color = Color(0.0, 0.90, 1.0)
		omni.light_energy = 2.2
		omni.omni_range = 25.0
		add_child(omni)

	var env = WorldEnvironment.new()
	var environment = Environment.new()

	# Deep Space Aurora Sky matching Reference Screenshot 1
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.01, 0.02, 0.06) # Deep space void
	sky_mat.sky_horizon_color = Color(0.02, 0.22, 0.28) # Cyan/green aurora ribbon glow
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.01, 0.02, 0.04)
	sky_mat.ground_horizon_color = Color(0.02, 0.08, 0.12)
	sky_mat.ground_curve = 0.08
	sky_mat.energy_multiplier = 1.05

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.15, 0.24, 0.38)
	environment.ambient_light_energy = 1.45

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.25
	environment.tonemap_white = 5.0

	# Atmospheric Sci-Fi Fog matching Screenshot 1
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.02, 0.08, 0.16)
	environment.fog_density = 0.003

	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	environment.glow_bloom = 0.25

	env.environment = environment
	add_child(env)
