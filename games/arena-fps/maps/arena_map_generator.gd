class_name ArenaMapGenerator
extends Node3D

@export var map_type: String = "foundry" # "foundry", "citadel", "sektor"
@export var arena_size: Vector2 = Vector2(70, 70)
@export var wall_height: float = 8.0

var capture_zones: Array[Dictionary] = []

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

func _build_foundry_map() -> void:
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5

	# Main Foundry Floor with PBR sci-fi metal panels
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "sci_fi_metal")

	# Perimeter Tactical Bulkhead Walls
	create_box(Vector3(0, wall_height * 0.5, -half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(0, wall_height - 1.5, -half_z + 0.7), Vector3(22.0, 2.8, 0.2), "digital_signage_cyan")
	create_box(Vector3(0, wall_height * 0.5, half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(0, wall_height - 1.5, half_z - 0.7), Vector3(22.0, 2.8, 0.2), "digital_signage_orange")
	create_box(Vector3(-half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")
	create_box(Vector3(half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")

	# Upper Perimeter Catwalks
	create_box(Vector3(0, 4.5, -half_z + 3.0), Vector3(arena_size.x - 8.0, 0.4, 4.0), "sci_fi_metal")
	create_box(Vector3(0, 5.2, -half_z + 5.0), Vector3(arena_size.x - 8.0, 1.0, 0.15), "dark_hull")
	create_box(Vector3(0, 4.5, half_z - 3.0), Vector3(arena_size.x - 8.0, 0.4, 4.0), "sci_fi_metal")
	create_box(Vector3(0, 5.2, half_z - 5.0), Vector3(arena_size.x - 8.0, 1.0, 0.15), "dark_hull")

	# Molten Core / Blast Furnace Center Dais
	create_box(Vector3(0, 1.2, 0), Vector3(20, 2.4, 20), "sci_fi_metal")
	create_box(Vector3(0, 2.5, 0), Vector3(12, 0.6, 12), "dark_hull")
	create_box(Vector3(0, 2.85, 0), Vector3(4.0, 0.1, 4.0), "neon_orange")

	# Tactical Ramps
	create_box(Vector3(0, 0.8, 14.0), Vector3(6.0, 1.6, 8.0), "dark_hull")
	create_box(Vector3(0, 0.8, -14.0), Vector3(6.0, 1.6, 8.0), "dark_hull")
	create_box(Vector3(14.0, 0.8, 0), Vector3(8.0, 1.6, 6.0), "dark_hull")
	create_box(Vector3(-14.0, 0.8, 0), Vector3(8.0, 1.6, 6.0), "dark_hull")

	# Molten lava hazard trenches along flanks
	for side_x in [-22.0, 22.0]:
		create_box(Vector3(side_x, 0.05, 0), Vector3(4.0, 0.1, 30.0), "neon_red")

	# 4 Corner Fortified Foundry Pillars & Crate Bunkers
	for pos in [Vector3(-20, 3.5, -20), Vector3(20, 3.5, -20), Vector3(-20, 3.5, 20), Vector3(20, 3.5, 20)]:
		create_box(pos, Vector3(3.6, 7.0, 3.6), "dark_hull")
		var crate = MeshBuilder.build_cyber_crate(Vector3(2.4, 1.2, 2.4))
		crate.position = pos + Vector3(2.0, -2.8, 0)
		add_child(crate)

	# Pickups
	spawn_pickup(Vector3(0, 3.6, 0), PickupBase.PickupType.ARMOR, 50)
	spawn_pickup(Vector3(-20, 1.0, -10), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(20, 1.0, 10), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(20, 1.0, -10), PickupBase.PickupType.AMMO, 50)
	spawn_pickup(Vector3(-20, 1.0, 10), PickupBase.PickupType.AMMO, 50)

	# 3 Capture Beacons
	_add_capture_beacon("Alpha", Vector3(-18, 0.5, 0), Color(0.0, 0.9, 1.0))
	_add_capture_beacon("Bravo", Vector3(0, 3.0, 0), Color(1.0, 0.6, 0.1))
	_add_capture_beacon("Charlie", Vector3(18, 0.5, 0), Color(0.8, 0.2, 1.0))

func _build_citadel_map() -> void:
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5

	# Clean Orbital Deck Floor
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "sci_fi_metal")

	# Low Perimeter Glass Balustrades (open to starfield)
	create_box(Vector3(0, 1.5, -half_z), Vector3(arena_size.x, 3.0, 0.8), "dark_hull")
	create_box(Vector3(0, 1.5, half_z), Vector3(arena_size.x, 3.0, 0.8), "dark_hull")
	create_box(Vector3(-half_x, 1.5, 0), Vector3(0.8, 3.0, arena_size.y), "dark_hull")
	create_box(Vector3(half_x, 1.5, 0), Vector3(0.8, 3.0, arena_size.y), "dark_hull")

	# Twin Elevated Observation Terraces
	create_box(Vector3(-18.0, 2.5, 0), Vector3(10.0, 5.0, 24.0), "sci_fi_metal")
	create_box(Vector3(18.0, 2.5, 0), Vector3(10.0, 5.0, 24.0), "sci_fi_metal")

	# Central Energy Concourse with Sunken Ring
	create_box(Vector3(0, 0.8, 0), Vector3(14.0, 1.6, 14.0), "dark_hull")
	create_box(Vector3(0, 1.7, 0), Vector3(6.0, 0.2, 6.0), "neon_cyan")

	# Gravity Lift Pads & Glass Bridges
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

	# Asphalt Street Pavement
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "asphalt")

	# Towering Cyberpunk Skyscraper Facades
	create_box(Vector3(0, 10.0, -half_z), Vector3(arena_size.x, 20.0, 2.0), "dark_concrete")
	create_box(Vector3(0, 10.0, half_z), Vector3(arena_size.x, 20.0, 2.0), "dark_concrete")
	create_box(Vector3(-half_x, 10.0, 0), Vector3(2.0, 20.0, arena_size.y), "dark_concrete")
	create_box(Vector3(half_x, 10.0, 0), Vector3(2.0, 20.0, arena_size.y), "dark_concrete")

	# Giant Neon Billboards
	create_box(Vector3(-14, 8.0, -half_z + 1.5), Vector3(16.0, 6.0, 0.3), "digital_signage_cyan")
	create_box(Vector3(14, 8.0, half_z - 1.5), Vector3(16.0, 6.0, 0.3), "digital_signage_orange")

	# Tight Alley Corridor Dividers & Cover Blocks
	create_box(Vector3(0, 3.0, -10.0), Vector3(28.0, 6.0, 2.0), "dark_concrete")
	create_box(Vector3(0, 3.0, 10.0), Vector3(28.0, 6.0, 2.0), "dark_concrete")
	create_box(Vector3(-12.0, 2.0, 0), Vector3(2.0, 4.0, 16.0), "dark_hull")
	create_box(Vector3(12.0, 2.0, 0), Vector3(2.0, 4.0, 16.0), "dark_hull")

	# Overhead Walkways
	create_box(Vector3(0, 5.5, 0), Vector3(8.0, 0.4, 22.0), "sci_fi_metal")

	# Pickups
	spawn_pickup(Vector3(0, 1.0, 0), PickupBase.PickupType.HEALTH, 25)
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
		"captured_by": 0, # 0: neutral, 1: player, 2: bots
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
	# Key Light (Directional Sun)
	var sun = DirectionalLight3D.new()
	sun.name = "KeySun"
	sun.rotation_degrees = Vector3(-50, 40, 0)
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	add_child(sun)

	# Fill Light (Soft cool ambient fill from opposite angle)
	var fill = DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(45, -140, 0)
	fill.light_color = Color(0.40, 0.65, 0.90)
	fill.light_energy = 0.65
	fill.shadow_enabled = false
	add_child(fill)

	# Corner Accent Omni Lights (giving depth and rim illumination in combat alcoves)
	var corner_lights = [
		Vector3(-22, 5.0, -22),
		Vector3(22, 5.0, -22),
		Vector3(-22, 5.0, 22),
		Vector3(22, 5.0, 22)
	]
	for pos in corner_lights:
		var omni = OmniLight3D.new()
		omni.position = pos
		omni.light_color = Color(0.3, 0.8, 1.0)
		omni.light_energy = 1.8
		omni.omni_range = 22.0
		add_child(omni)

	# WorldEnvironment with Procedural Sky and Filmic Tonemapping
	var env = WorldEnvironment.new()
	var environment = Environment.new()

	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.32, 0.58)
	sky_mat.sky_horizon_color = Color(0.48, 0.58, 0.72)
	sky_mat.ground_bottom_color = Color(0.18, 0.20, 0.24)
	sky_mat.ground_horizon_color = Color(0.35, 0.40, 0.50)
	sky_mat.sun_angle_max = 35.0

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.45, 0.52, 0.65)
	environment.ambient_light_energy = 1.4

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.12

	env.environment = environment
	add_child(env)
