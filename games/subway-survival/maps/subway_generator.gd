class_name SubwayGenerator
extends Node3D

@export var station_length: float = 60.0
@export var station_width: float = 24.0
@export var ceiling_height: float = 6.0

func _ready() -> void:
	build_subway_station()

func build_subway_station() -> void:
	# Passenger Platform Floor (left side)
	create_box(Vector3(-5.0, -0.5, 0.0), Vector3(14.0, 1.0, station_length), "subway_tile")
	# Subway Tracks Recess Floor (right side, lower by 1.2m)
	create_box(Vector3(6.0, -1.7, 0.0), Vector3(10.0, 1.0, station_length), "grimy_concrete")

	# Platform Edge Hazard Stripe
	create_box(Vector3(1.8, 0.01, 0.0), Vector3(0.4, 0.05, station_length), "neon_orange")

	# Rails along the track
	create_box(Vector3(4.0, -1.15, 0.0), Vector3(0.15, 0.1, station_length), "sci_fi_metal")
	create_box(Vector3(7.5, -1.15, 0.0), Vector3(0.15, 0.1, station_length), "sci_fi_metal")

	# Wooden Railway Ties across the track
	var half_z = station_length * 0.5
	for z_pos in range(-int(half_z) + 2, int(half_z) - 2, 2):
		create_box(Vector3(5.75, -1.18, float(z_pos)), Vector3(4.4, 0.06, 0.4), "dark_hull")

	# Tactical Supply Terminal / Upgrade Station on Platform
	create_box(Vector3(-10.5, 1.0, 0.0), Vector3(1.2, 2.0, 1.2), "sci_fi_metal")
	create_box(Vector3(-10.5, 1.4, 0.61), Vector3(0.8, 0.6, 0.05), "neon_cyan")

	# Ceiling
	create_box(Vector3(0.0, ceiling_height, 0.0), Vector3(station_width, 1.0, station_length), "grimy_concrete")

	# Side Walls
	# Left Wall (behind platform)
	create_box(Vector3(-12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, station_length), "subway_tile")
	# Right Wall (track tunnel side)
	create_box(Vector3(11.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, station_length), "grimy_concrete")

	# End Tunnel Portals (North and South tunnel mouths where enemies spawn)
	# North Wall with tunnel arch
	create_box(Vector3(-5.0, ceiling_height * 0.5, -half_z), Vector3(14.0, ceiling_height, 1.0), "grimy_concrete")
	# South Wall with tunnel arch
	create_box(Vector3(-5.0, ceiling_height * 0.5, half_z), Vector3(14.0, ceiling_height, 1.0), "grimy_concrete")

	# Pillars along platform edge
	for z in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		create_box(Vector3(-0.5, ceiling_height * 0.5, z), Vector3(1.0, ceiling_height, 1.0), "sci_fi_metal")

	# Ticket gates / barricades on platform
	create_box(Vector3(-8.0, 0.6, -15.0), Vector3(4.0, 1.2, 0.8), "dark_hull")
	create_box(Vector3(-8.0, 0.6, 15.0), Vector3(4.0, 1.2, 0.8), "dark_hull")

	# Atmospheric Lighting (Flickering fluorescent tubes & emergency red lamps)
	setup_subway_lighting()

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

func setup_subway_lighting() -> void:
	# Ambient dark moody lighting
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.01, 0.02, 0.04)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.08, 0.10, 0.14)
	environment.ambient_light_energy = 0.5
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	env.environment = environment
	add_child(env)

	# Ceiling light fixtures along the platform
	for z in [-22.0, -11.0, 0.0, 11.0, 22.0]:
		var omni = OmniLight3D.new()
		omni.position = Vector3(-5.0, ceiling_height - 0.5, z)
		omni.light_color = Color(0.85, 0.92, 1.0)
		omni.light_energy = 1.5
		omni.omni_range = 14.0
		omni.shadow_enabled = true
		add_child(omni)

	# Red Emergency Tunnel Beacon
	var red_beacon = OmniLight3D.new()
	red_beacon.position = Vector3(6.0, 1.0, -station_length * 0.45)
	red_beacon.light_color = Color(1.0, 0.1, 0.1)
	red_beacon.light_energy = 2.0
	red_beacon.omni_range = 16.0
	add_child(red_beacon)
