class_name SubwayGenerator
extends Node3D

@export var station_length: float = 60.0
@export var station_width: float = 24.0
@export var ceiling_height: float = 6.0

func _ready() -> void:
	build_subway_station()

func build_subway_station() -> void:
	var half_z = station_length * 0.5

	# Passenger Platform Floor (left side) with ceramic subway tiles
	create_box(Vector3(-5.0, -0.5, 0.0), Vector3(14.0, 1.0, station_length), "subway_tile")

	# Platform Edge Tactile Warning Hazard Stripe (yellow/black ribbed)
	create_box(Vector3(1.8, 0.02, 0.0), Vector3(0.5, 0.05, station_length), "hazard_stripe")

	# Sunken Track Recess Floor (right side, lower by 1.4m) with grimy concrete
	create_box(Vector3(7.0, -1.9, 0.0), Vector3(10.0, 1.0, station_length), "grimy_concrete")

	# Steel Train Rails along track
	create_box(Vector3(4.5, -1.35, 0.0), Vector3(0.18, 0.12, station_length), "sci_fi_metal")
	create_box(Vector3(8.5, -1.35, 0.0), Vector3(0.18, 0.12, station_length), "sci_fi_metal")

	# Third Rail (Electrified power rail with caution glow)
	create_box(Vector3(10.2, -1.30, 0.0), Vector3(0.15, 0.20, station_length), "neon_orange")

	# Concrete Railway Ties across the track
	for z_pos in range(-int(half_z) + 2, int(half_z) - 2, 2):
		create_box(Vector3(6.5, -1.38, float(z_pos)), Vector3(5.2, 0.08, 0.4), "dark_hull")

	# Overhead Structural Arched Ceiling with Steel Girders
	create_box(Vector3(0.0, ceiling_height, 0.0), Vector3(station_width, 0.8, station_length), "grimy_concrete")
	# Transverse Steel Structural Girders every 6m
	for z_pos in range(-int(half_z) + 3, int(half_z) - 3, 6):
		create_box(Vector3(0.0, ceiling_height - 0.4, float(z_pos)), Vector3(station_width - 1.0, 0.5, 0.6), "dark_hull")

	# Side Walls
	# Left Platform Back Wall with subway tile and backlit signage
	create_box(Vector3(-12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, station_length), "subway_tile")
	create_box(Vector3(-11.45, 3.2, 0.0), Vector3(0.1, 1.2, 14.0), "digital_signage_cyan") # Station name sign
	create_box(Vector3(-11.45, 3.2, -18.0), Vector3(0.1, 1.2, 8.0), "digital_signage_cyan")
	create_box(Vector3(-11.45, 3.2, 18.0), Vector3(0.1, 1.2, 8.0), "digital_signage_cyan")

	# Right Track Tunnel Wall
	create_box(Vector3(12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, station_length), "grimy_concrete")

	# End Tunnel Portals (North and South where mutated enemies emerge)
	create_box(Vector3(-5.0, ceiling_height * 0.5, -half_z), Vector3(14.0, ceiling_height, 1.0), "grimy_concrete")
	create_box(Vector3(-5.0, ceiling_height * 0.5, half_z), Vector3(14.0, ceiling_height, 1.0), "grimy_concrete")

	# Tunnel Arch Portals above tracks
	create_box(Vector3(7.0, ceiling_height - 0.8, -half_z), Vector3(10.0, 1.6, 1.0), "dark_hull")
	create_box(Vector3(7.0, ceiling_height - 0.8, half_z), Vector3(10.0, 1.6, 1.0), "dark_hull")

	# Platform Support Pillars with Illuminated Signs
	for z in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		create_box(Vector3(-0.5, ceiling_height * 0.5, z), Vector3(1.0, ceiling_height, 1.0), "sci_fi_metal")
		create_box(Vector3(-0.5, 2.5, z + 0.52), Vector3(0.6, 0.8, 0.05), "neon_cyan")

	# Scavenging Supply Terminal & Workbench on Platform
	create_box(Vector3(-10.5, 1.0, 0.0), Vector3(1.4, 2.0, 1.4), "sci_fi_metal")
	create_box(Vector3(-10.5, 1.5, 0.72), Vector3(0.9, 0.7, 0.05), "digital_signage_orange")
	var crate1 = MeshBuilder.build_cyber_crate(Vector3(1.2, 1.0, 1.2))
	crate1.position = Vector3(-10.5, 0.5, 2.0)
	add_child(crate1)

	# Platform Passenger Benches & Barricades
	create_box(Vector3(-8.0, 0.45, -12.0), Vector3(2.5, 0.5, 0.9), "dark_hull")
	create_box(Vector3(-8.0, 0.45, 12.0), Vector3(2.5, 0.5, 0.9), "dark_hull")
	create_box(Vector3(-7.5, 0.7, -22.0), Vector3(4.0, 1.4, 0.6), "dark_hull")
	create_box(Vector3(-7.5, 0.7, 22.0), Vector3(4.0, 1.4, 0.6), "dark_hull")

	# Setup Production Lighting & WorldEnvironment
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
	# WorldEnvironment with Filmic Tonemapping & Subterranean Volumetric Fog
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.10, 0.14)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.48, 0.58)
	environment.ambient_light_energy = 1.6

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_bloom = 0.15

	environment.fog_enabled = true
	environment.fog_light_color = Color(0.25, 0.32, 0.42)
	environment.fog_density = 0.012

	env.environment = environment
	add_child(env)

	# Overhead Fluorescent Tube Fixtures along Platform (every 7m for continuous bright illumination)
	for z in [-24.0, -17.0, -10.0, -3.0, 4.0, 11.0, 18.0, 25.0]:
		var omni = OmniLight3D.new()
		omni.position = Vector3(-5.0, ceiling_height - 0.6, z)
		omni.light_color = Color(0.95, 0.97, 1.0)
		omni.light_energy = 2.4
		omni.omni_range = 16.0
		omni.shadow_enabled = true
		add_child(omni)

	# Sunken Track Recess Uplights
	for z in [-20.0, -7.0, 7.0, 20.0]:
		var track_light = OmniLight3D.new()
		track_light.position = Vector3(7.0, -0.6, z)
		track_light.light_color = Color(0.5, 0.7, 1.0)
		track_light.light_energy = 1.8
		track_light.omni_range = 12.0
		add_child(track_light)

	# Red Emergency Tunnel Beacons (Warning lights indicating approaching threats)
	var red_beacon_north = OmniLight3D.new()
	red_beacon_north.position = Vector3(7.0, 2.0, -station_length * 0.46)
	red_beacon_north.light_color = Color(1.0, 0.2, 0.2)
	red_beacon_north.light_energy = 2.5
	red_beacon_north.omni_range = 18.0
	add_child(red_beacon_north)

	var red_beacon_south = OmniLight3D.new()
	red_beacon_south.position = Vector3(7.0, 2.0, station_length * 0.46)
	red_beacon_south.light_color = Color(1.0, 0.2, 0.2)
	red_beacon_south.light_energy = 2.5
	red_beacon_south.omni_range = 18.0
	add_child(red_beacon_south)
