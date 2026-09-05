class_name ArenaMapGenerator
extends Node3D

@export var arena_size: Vector2 = Vector2(70, 70)
@export var wall_height: float = 8.0

func _ready() -> void:
	build_arena()

func build_arena() -> void:
	# Main Floor
	create_box(Vector3(0, -0.5, 0), Vector3(arena_size.x, 1.0, arena_size.y), "sci_fi_metal")

	# Boundary Walls
	var half_x = arena_size.x * 0.5
	var half_z = arena_size.y * 0.5
	# North Wall
	create_box(Vector3(0, wall_height * 0.5, -half_z), Vector3(arena_size.x, wall_height, 1.0), "dark_hull")
	# South Wall
	create_box(Vector3(0, wall_height * 0.5, half_z), Vector3(arena_size.x, wall_height, 1.0), "dark_hull")
	# West Wall
	create_box(Vector3(-half_x, wall_height * 0.5, 0), Vector3(1.0, wall_height, arena_size.y), "dark_hull")
	# East Wall
	create_box(Vector3(half_x, wall_height * 0.5, 0), Vector3(1.0, wall_height, arena_size.y), "dark_hull")

	# Central Elevated Platform
	create_box(Vector3(0, 2.0, 0), Vector3(16, 4.0, 16), "sci_fi_metal")
	# Ramps to central platform
	create_box(Vector3(0, 1.0, 12), Vector3(6, 2.0, 8), "dark_hull")
	create_box(Vector3(0, 1.0, -12), Vector3(6, 2.0, 8), "dark_hull")

	# Pillars and Cover Blocks (Upgraded to detailed cyber crates)
	var pillar_positions = [
		Vector3(-18, 2.5, -18),
		Vector3(18, 2.5, -18),
		Vector3(-18, 2.5, 18),
		Vector3(18, 2.5, 18),
		Vector3(-24, 1.5, 0),
		Vector3(24, 1.5, 0)
	]
	for pos in pillar_positions:
		create_box(pos, Vector3(3.0, 5.0, 3.0), "dark_hull")
		var crate = MeshBuilder.build_cyber_crate(Vector3(3.1, 1.2, 3.1))
		crate.position = pos + Vector3(0, -1.8, 0)
		add_child(crate)

	# Neon Decorative Floor Trims
	create_box(Vector3(0, 0.05, -half_z + 0.5), Vector3(arena_size.x, 0.1, 0.4), "neon_cyan")
	create_box(Vector3(0, 0.05, half_z - 0.5), Vector3(arena_size.x, 0.1, 0.4), "neon_cyan")
	create_box(Vector3(-half_x + 0.5, 0.05, 0), Vector3(0.4, 0.1, arena_size.y), "neon_cyan")
	create_box(Vector3(half_x - 0.5, 0.05, 0), Vector3(0.4, 0.1, arena_size.y), "neon_cyan")

	# Place Pickups
	spawn_pickup(Vector3(0, 4.8, 0), PickupBase.PickupType.ARMOR, 50) # On top of central platform
	spawn_pickup(Vector3(-18, 0.8, -12), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(18, 0.8, 12), PickupBase.PickupType.HEALTH, 25)
	spawn_pickup(Vector3(18, 0.8, -12), PickupBase.PickupType.AMMO, 50)
	spawn_pickup(Vector3(-18, 0.8, 12), PickupBase.PickupType.AMMO, 50)

	# Sun / Directional Light & Environment
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
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_color = Color(0.95, 0.98, 1.0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.06, 0.10)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.25, 0.35)
	environment.ambient_light_energy = 0.8
	environment.glow_enabled = true
	environment.glow_intensity = 0.6
	env.environment = environment
	add_child(env)
