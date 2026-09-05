class_name SubwayGenerator
extends Node3D

## SubwayGenerator: Builds an authentic 3-sector subterranean transit network:
## Sector 1: Passenger Concourse & Platform (with subway carriages, rails, benches, stairs)
## Sector 2: Deep Transit Tunnels & maintenance recesses
## Sector 3: Subterranean Pumping Station / Hive Nest (with pipe networks, turbines, containment)
## Built with production 3D GLB assets.

@export var station_length: float = 60.0
@export var station_width: float = 24.0
@export var ceiling_height: float = 6.0

var gate_zone2: Node3D = null
var gate_zone3: Node3D = null
var is_zone2_unlocked: bool = false
var is_zone3_unlocked: bool = false

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func _ready() -> void:
	build_subway_station()

func build_subway_station() -> void:
	_build_zone_1_platform()
	_build_zone_2_tunnels()
	_build_zone_3_pump_hive()
	setup_subway_lighting()

func _spawn_subway_prop(asset_name: String, pos: Vector3, rot_y: float = 0.0, s: Vector3 = Vector3(1.0, 1.0, 1.0)) -> Node3D:
	var prop = ModelCacheScript.get_prop(asset_name)
	if prop:
		prop.position = pos
		prop.rotation_degrees.y = rot_y
		prop.scale = s
		add_child(prop)
		return prop
	return null

func _build_zone_1_platform() -> void:
	# Passenger Platform Floor (left side) with ceramic subway tiles
	create_box(Vector3(-5.0, -0.5, 0.0), Vector3(14.0, 1.0, 60.0), "subway_tile")

	# Platform Edge Hazard Stripe
	create_box(Vector3(1.8, 0.02, 0.0), Vector3(0.5, 0.05, 60.0), "hazard_stripe")

	# Sunken Track Recess Floor
	create_box(Vector3(7.0, -1.9, 0.0), Vector3(10.0, 1.0, 60.0), "grimy_concrete")

	# Production 3D Detailed Railway Tracks
	for tz in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		_spawn_subway_prop("train_track", Vector3(6.5, -1.4, tz), 0.0, Vector3(2.5, 2.5, 2.5))

	# Ceiling
	create_box(Vector3(0.0, ceiling_height, 0.0), Vector3(station_width, 0.8, 60.0), "grimy_concrete")

	# Left Back Wall
	create_box(Vector3(-12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, 60.0), "subway_tile")
	create_box(Vector3(12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, 60.0), "grimy_concrete")

	# Back wall at North end
	create_box(Vector3(0.0, ceiling_height * 0.5, -30.0), Vector3(station_width, ceiling_height, 1.0), "grimy_concrete")

	# Structural Support Columns
	for z in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		_spawn_subway_prop("wall_pillar", Vector3(-0.5, 0.0, z), 0.0, Vector3(2.0, 3.0, 2.0))

	# Production Subway Train Carriages (Engine + Passenger Car)
	var train_car1 = _spawn_subway_prop("train_subway_car", Vector3(6.5, -0.6, -10.0), 0.0, Vector3(2.8, 2.8, 2.8))
	if train_car1:
		train_car1.name = "ExtractionTrain"
	var train_car2 = _spawn_subway_prop("train_subway_middle", Vector3(6.5, -0.6, 12.0), 0.0, Vector3(2.8, 2.8, 2.8))

	# Platform Access Stairs
	_spawn_subway_prop("station_stairs", Vector3(-8.0, 0.0, -25.0), 0.0, Vector3(2.5, 2.5, 2.5))

	# Production Passenger Waiting Benches
	_spawn_subway_prop("station_bench", Vector3(-9.5, 0.0, -12.0), 90.0, Vector3(2.2, 2.2, 2.2))
	_spawn_subway_prop("station_bench", Vector3(-9.5, 0.0, 12.0), 90.0, Vector3(2.2, 2.2, 2.2))

	# Supply Crates & Upgrade Terminal
	_spawn_subway_prop("ammo_box", Vector3(-10.5, 0.0, -4.0), 0.0, Vector3(2.0, 2.0, 2.0))
	_spawn_subway_prop("computer_terminal", Vector3(-10.5, 0.0, 4.0), 90.0, Vector3(2.0, 2.0, 2.0))

	# Security Blast Door leading to Zone 2 (at Z = 30)
	gate_zone2 = _spawn_subway_prop("door_double", Vector3(0.0, 0.0, 30.0), 0.0, Vector3(3.5, 3.0, 3.0))
	if not gate_zone2:
		gate_zone2 = MeshBuilder.build_blast_door_mesh()
		gate_zone2.position = Vector3(0.0, 0.0, 30.0)
		add_child(gate_zone2)

func _build_zone_2_tunnels() -> void:
	# Zone 2: Abandoned Train Tunnels (Z: 30 to 90)
	create_box(Vector3(0.0, -1.9, 60.0), Vector3(station_width, 1.0, 60.0), "grimy_concrete")
	create_box(Vector3(0.0, ceiling_height, 60.0), Vector3(station_width, 0.8, 60.0), "dark_hull")

	# Tunnel Walls
	create_box(Vector3(-12.0, ceiling_height * 0.5, 60.0), Vector3(1.0, ceiling_height, 60.0), "subway_rust_metal")
	create_box(Vector3(12.0, ceiling_height * 0.5, 60.0), Vector3(1.0, ceiling_height, 60.0), "subway_rust_metal")

	# Track Rails in Tunnel
	for tz in [40.0, 55.0, 70.0, 85.0]:
		_spawn_subway_prop("train_track", Vector3(0.0, -1.4, tz), 0.0, Vector3(2.5, 2.5, 2.5))

	# Derailed Train Car inside Tunnel
	_spawn_subway_prop("train_subway_car", Vector3(2.0, -0.6, 60.0), 15.0, Vector3(2.8, 2.8, 2.8))

	# Heavy High Barriers as tunnel barricades
	_spawn_subway_prop("barrier_high", Vector3(-6.0, -1.4, 50.0), 0.0, Vector3(2.5, 2.0, 2.0))

	# Hydraulic Gate leading to Zone 3 (at Z = 90)
	gate_zone3 = _spawn_subway_prop("door_double", Vector3(0.0, -1.4, 90.0), 0.0, Vector3(3.5, 3.0, 3.0))
	if not gate_zone3:
		gate_zone3 = MeshBuilder.build_blast_door_mesh()
		gate_zone3.position = Vector3(0.0, -1.4, 90.0)
		add_child(gate_zone3)

func _build_zone_3_pump_hive() -> void:
	# Zone 3: Subterranean Pump Station & Hive Nest (Z: 90 to 150)
	create_box(Vector3(0.0, -2.5, 120.0), Vector3(36.0, 1.0, 60.0), "dark_concrete")
	create_box(Vector3(0.0, ceiling_height + 4.0, 120.0), Vector3(36.0, 1.0, 60.0), "dark_hull")

	# Perimeter Walls
	create_box(Vector3(-18.0, ceiling_height * 0.5 + 2.0, 120.0), Vector3(1.0, ceiling_height + 4.0, 60.0), "dark_concrete")
	create_box(Vector3(18.0, ceiling_height * 0.5 + 2.0, 120.0), Vector3(1.0, ceiling_height + 4.0, 60.0), "dark_concrete")
	create_box(Vector3(0.0, ceiling_height * 0.5 + 2.0, 150.0), Vector3(36.0, ceiling_height + 4.0, 1.0), "dark_concrete")

	# Toxic Acid Hazard Pools
	create_box(Vector3(-8.0, -2.35, 115.0), Vector3(10.0, 0.2, 12.0), "acid_pool")
	create_box(Vector3(8.0, -2.35, 130.0), Vector3(10.0, 0.2, 12.0), "acid_pool")

	# Industrial Pipe Networks and Turbine Columns
	for px in [-12.0, 12.0]:
		for pz in [105.0, 135.0]:
			_spawn_subway_prop("pipe_network", Vector3(px, -2.0, pz), 90.0 if px < 0 else -90.0, Vector3(3.5, 3.5, 3.5))
			_spawn_subway_prop("wall_pillar", Vector3(px, -2.0, pz + 8.0), 0.0, Vector3(3.0, 4.0, 3.0))

func unlock_gate(zone_idx: int) -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("gate_unlock", 1.0, 1.5)

	if zone_idx == 2 and gate_zone2:
		is_zone2_unlocked = true
		var tween = create_tween()
		tween.tween_property(gate_zone2, "position:y", 6.0, 1.2)
	elif zone_idx == 3 and gate_zone3:
		is_zone3_unlocked = true
		var tween = create_tween()
		tween.tween_property(gate_zone3, "position:y", 6.0, 1.2)

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

	# Overhead Fluorescent Tube Fixtures along Platform
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

	# Red Emergency Tunnel Beacons
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
