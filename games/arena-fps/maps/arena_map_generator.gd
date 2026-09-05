class_name ArenaMapGenerator
extends Node3D

@export var arena_size: Vector2 = Vector2(70, 70)
@export var wall_height: float = 8.0

func _ready() -> void:
	build_arena()

func build_arena() -> void:
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5

	# Main Floor with PBR sci-fi metal panels
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "sci_fi_metal")

	# Perimeter Tactical Bulkhead Walls
	# North Wall with upper display
	create_box(Vector3(0, wall_height * 0.5, -half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(0, wall_height - 1.5, -half_z + 0.7), Vector3(20.0, 2.8, 0.2), "digital_signage_cyan")
	# South Wall with upper display
	create_box(Vector3(0, wall_height * 0.5, half_z), Vector3(arena_size.x, wall_height, 1.2), "dark_hull")
	create_box(Vector3(0, wall_height - 1.5, half_z - 0.7), Vector3(20.0, 2.8, 0.2), "digital_signage_orange")
	# West Wall
	create_box(Vector3(-half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")
	# East Wall
	create_box(Vector3(half_x, wall_height * 0.5, 0), Vector3(1.2, wall_height, arena_size.y), "dark_hull")

	# Upper Perimeter Observation Catwalks (running along North & South perimeters)
	create_box(Vector3(0, 4.5, -half_z + 3.0), Vector3(arena_size.x - 8.0, 0.4, 4.0), "sci_fi_metal")
	create_box(Vector3(0, 5.2, -half_z + 5.0), Vector3(arena_size.x - 8.0, 1.0, 0.15), "dark_hull") # railing
	create_box(Vector3(0, 4.5, half_z - 3.0), Vector3(arena_size.x - 8.0, 0.4, 4.0), "sci_fi_metal")
	create_box(Vector3(0, 5.2, half_z - 5.0), Vector3(arena_size.x - 8.0, 1.0, 0.15), "dark_hull") # railing

	# Wall structural buttresses with hazard caution striping
	for x_pos in [-24.0, -12.0, 12.0, 24.0]:
		create_box(Vector3(x_pos, wall_height * 0.5, -half_z + 1.0), Vector3(1.8, wall_height, 1.2), "dark_hull")
		create_box(Vector3(x_pos, 0.6, -half_z + 1.7), Vector3(1.8, 1.2, 0.2), "hazard_stripe")
		create_box(Vector3(x_pos, wall_height * 0.5, half_z - 1.0), Vector3(1.8, wall_height, 1.2), "dark_hull")
		create_box(Vector3(x_pos, 0.6, half_z - 1.7), Vector3(1.8, 1.2, 0.2), "hazard_stripe")

	# Central Tactical Command Dais (Multi-Tier Platform)
	create_box(Vector3(0, 1.2, 0), Vector3(20, 2.4, 20), "sci_fi_metal")
	create_box(Vector3(0, 2.5, 0), Vector3(12, 0.6, 12), "dark_hull")
	create_box(Vector3(0, 2.85, 0), Vector3(4.0, 0.1, 4.0), "neon_cyan") # Holographic Capture Beacon

	# Tactical Ramps to Center (North, South, East, West)
	create_box(Vector3(0, 0.8, 14.0), Vector3(6.0, 1.6, 8.0), "dark_hull")
	create_box(Vector3(0, 0.8, -14.0), Vector3(6.0, 1.6, 8.0), "dark_hull")
	create_box(Vector3(14.0, 0.8, 0), Vector3(8.0, 1.6, 6.0), "dark_hull")
	create_box(Vector3(-14.0, 0.8, 0), Vector3(8.0, 1.6, 6.0), "dark_hull")

	# Tactical Low-Cover Barriers on Dais
	create_box(Vector3(-4.5, 3.3, 0), Vector3(0.5, 1.0, 6.0), "dark_hull")
	create_box(Vector3(4.5, 3.3, 0), Vector3(0.5, 1.0, 6.0), "dark_hull")

	# 4 Corner Fortified Pillars & Cover Bunkers
	var pillar_positions = [
		Vector3(-20, 3.5, -20),
		Vector3(20, 3.5, -20),
		Vector3(-20, 3.5, 20),
		Vector3(20, 3.5, 20),
		Vector3(-26, 2.0, 0),
		Vector3(26, 2.0, 0)
	]
	for pos in pillar_positions:
		create_box(pos, Vector3(3.6, 7.0, 3.6), "dark_hull")
		create_box(pos + Vector3(0, -2.5, 1.9), Vector3(3.6, 1.2, 0.2), "hazard_stripe")
		var crate = MeshBuilder.build_cyber_crate(Vector3(2.4, 1.2, 2.4))
		crate.position = pos + Vector3(2.0, -2.8, 0)
		add_child(crate)

	# Neon Decorative Floor Trims (Perimeter and Center pathways)
	create_box(Vector3(0, 0.05, -half_z + 1.2), Vector3(arena_size.x - 4.0, 0.1, 0.5), "neon_cyan")
	create_box(Vector3(0, 0.05, half_z - 1.2), Vector3(arena_size.x - 4.0, 0.1, 0.5), "neon_orange")
	create_box(Vector3(-half_x + 1.2, 0.05, 0), Vector3(0.5, 0.1, arena_size.y - 4.0), "neon_cyan")
	create_box(Vector3(half_x - 1.2, 0.05, 0), Vector3(0.5, 0.1, arena_size.y - 4.0), "neon_orange")

	# Place Pickups (Armor, Health, Ammo)
	spawn_pickup(Vector3(0, 3.6, 0), PickupBase.PickupType.ARMOR, 50)
	spawn_pickup(Vector3(-20, 1.0, -10), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(20, 1.0, 10), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(20, 1.0, -10), PickupBase.PickupType.AMMO, 50)
	spawn_pickup(Vector3(-20, 1.0, 10), PickupBase.PickupType.AMMO, 50)

	# Setup Production 3-Point Lighting, Sky, and WorldEnvironment
	setup_lighting()

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
