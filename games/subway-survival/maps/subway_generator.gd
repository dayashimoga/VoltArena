class_name SubwayGenerator
extends Node3D

@export var station_length: float = 60.0
@export var station_width: float = 24.0
@export var ceiling_height: float = 6.0

func _ready() -> void:
	build_subway_station()

var gate_zone2: Node3D = null
var gate_zone3: Node3D = null
var is_zone2_unlocked: bool = false
var is_zone3_unlocked: bool = false

func build_subway_station() -> void:
	_build_zone_1_platform()
	_build_zone_2_tunnels()
	_build_zone_3_pump_hive()
	setup_subway_lighting()

func _build_zone_1_platform() -> void:
	var half_z = 30.0

	# Passenger Platform Floor (left side) with ceramic subway tiles
	create_box(Vector3(-5.0, -0.5, 0.0), Vector3(14.0, 1.0, 60.0), "subway_tile")

	# Platform Edge Tactile Warning Hazard Stripe
	create_box(Vector3(1.8, 0.02, 0.0), Vector3(0.5, 0.05, 60.0), "hazard_stripe")

	# Sunken Track Recess Floor (right side)
	create_box(Vector3(7.0, -1.9, 0.0), Vector3(10.0, 1.0, 60.0), "grimy_concrete")

	# Steel Train Rails
	create_box(Vector3(4.5, -1.35, 0.0), Vector3(0.18, 0.12, 60.0), "sci_fi_metal")
	create_box(Vector3(8.5, -1.35, 0.0), Vector3(0.18, 0.12, 60.0), "sci_fi_metal")
	create_box(Vector3(10.2, -1.30, 0.0), Vector3(0.15, 0.20, 60.0), "neon_orange")

	# Ceiling
	create_box(Vector3(0.0, ceiling_height, 0.0), Vector3(station_width, 0.8, 60.0), "grimy_concrete")

	# Left Back Wall & Signs
	create_box(Vector3(-12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, 60.0), "subway_tile")
	create_box(Vector3(-11.45, 3.2, 0.0), Vector3(0.1, 1.2, 14.0), "digital_signage_cyan")
	create_box(Vector3(12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, 60.0), "grimy_concrete")

	# Back wall at North end (Z = -30)
	create_box(Vector3(0.0, ceiling_height * 0.5, -30.0), Vector3(station_width, ceiling_height, 1.0), "grimy_concrete")

	# Pillars
	for z in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		create_box(Vector3(-0.5, ceiling_height * 0.5, z), Vector3(1.0, ceiling_height, 1.0), "sci_fi_metal")
		create_box(Vector3(-0.5, 2.5, z + 0.52), Vector3(0.6, 0.8, 0.05), "neon_cyan")

	# Realistic Subway Extraction Train on Tracks (Zone 1)
	var train_zone1 = MeshBuilder.build_subway_car_mesh()
	train_zone1.name = "ExtractionTrain"
	train_zone1.position = Vector3(6.5, -1.4, 0.0)
	add_child(train_zone1)

	# Interactive Holographic Upgrade Kiosk
	var kiosk = MeshBuilder.build_upgrade_kiosk_mesh()
	kiosk.position = Vector3(-10.5, 0.0, -4.0)
	add_child(kiosk)

	# Ticket Turnstile Gates near North Entrance
	var turnstile1 = MeshBuilder.build_ticket_turnstile()
	turnstile1.position = Vector3(-6.0, 0.0, -25.0)
	add_child(turnstile1)
	var turnstile2 = MeshBuilder.build_ticket_turnstile()
	turnstile2.position = Vector3(-8.0, 0.0, -25.0)
	add_child(turnstile2)

	# Passenger Waiting Benches
	var bench1 = MeshBuilder.build_subway_bench()
	bench1.position = Vector3(-9.5, 0.0, -12.0)
	add_child(bench1)
	var bench2 = MeshBuilder.build_subway_bench()
	bench2.position = Vector3(-9.5, 0.0, 12.0)
	add_child(bench2)

	# Vending Machines along platform wall
	var vend1 = MeshBuilder.build_vending_machine()
	vend1.position = Vector3(-11.2, 0.0, -18.0)
	vend1.rotation_degrees.y = 90.0
	add_child(vend1)
	var vend2 = MeshBuilder.build_vending_machine()
	vend2.position = Vector3(-11.2, 0.0, 18.0)
	vend2.rotation_degrees.y = 90.0
	add_child(vend2)

	# Supply Crates
	var c_plat = MeshBuilder.build_cyber_crate(Vector3(1.4, 1.2, 1.4))
	c_plat.position = Vector3(-10.5, 0.6, -1.0)
	add_child(c_plat)

	# Security Blast Door leading to Zone 2 (at Z = 30)
	gate_zone2 = MeshBuilder.build_blast_door_mesh()
	gate_zone2.position = Vector3(0.0, 0.0, 30.0)
	add_child(gate_zone2)

func _build_zone_2_tunnels() -> void:
	# Zone 2: Abandoned Train Tunnels (Z: 30 to 90)
	# Tunnel floor
	create_box(Vector3(0.0, -1.9, 60.0), Vector3(station_width, 1.0, 60.0), "grimy_concrete")
	create_box(Vector3(0.0, ceiling_height, 60.0), Vector3(station_width, 0.8, 60.0), "dark_hull")

	# Tunnel Walls
	create_box(Vector3(-12.0, ceiling_height * 0.5, 60.0), Vector3(1.0, ceiling_height, 60.0), "subway_rust_metal")
	create_box(Vector3(12.0, ceiling_height * 0.5, 60.0), Vector3(1.0, ceiling_height, 60.0), "subway_rust_metal")

	# Derailed Train Car inside Tunnel
	var train_car = MeshBuilder.build_subway_car_mesh()
	train_car.position = Vector3(3.0, -1.4, 60.0)
	train_car.rotation_degrees = Vector3(0, 12, 0)
	add_child(train_car)

	# Scrap Caches & Crates
	var c1 = MeshBuilder.build_cyber_crate(Vector3(1.8, 1.2, 1.8))
	c1.position = Vector3(-8.0, -0.8, 50.0)
	add_child(c1)

	var c2 = MeshBuilder.build_cyber_crate(Vector3(1.5, 1.5, 1.5))
	c2.position = Vector3(-6.0, -0.8, 70.0)
	add_child(c2)

	# Hydraulic Gate leading to Zone 3 (at Z = 90)
	gate_zone3 = MeshBuilder.build_blast_door_mesh()
	gate_zone3.position = Vector3(0.0, -1.4, 90.0)
	add_child(gate_zone3)

func _build_zone_3_pump_hive() -> void:
	# Zone 3: Sub-Level Pump Station & Hive Nest (Z: 90 to 150)
	# Cavernous Room Floor
	create_box(Vector3(0.0, -2.5, 120.0), Vector3(36.0, 1.0, 60.0), "dark_concrete")
	create_box(Vector3(0.0, ceiling_height + 4.0, 120.0), Vector3(36.0, 1.0, 60.0), "dark_hull")

	# Perimeter Walls
	create_box(Vector3(-18.0, ceiling_height * 0.5 + 2.0, 120.0), Vector3(1.0, ceiling_height + 4.0, 60.0), "dark_concrete")
	create_box(Vector3(18.0, ceiling_height * 0.5 + 2.0, 120.0), Vector3(1.0, ceiling_height + 4.0, 60.0), "dark_concrete")
	create_box(Vector3(0.0, ceiling_height * 0.5 + 2.0, 150.0), Vector3(36.0, ceiling_height + 4.0, 1.0), "dark_concrete")

	# Toxic Acid Hazard Pools
	create_box(Vector3(-8.0, -2.35, 115.0), Vector3(10.0, 0.2, 12.0), "acid_pool")
	create_box(Vector3(8.0, -2.35, 130.0), Vector3(10.0, 0.2, 12.0), "acid_pool")

	# Industrial Pump Columns
	for px in [-10.0, 10.0]:
		for pz in [105.0, 135.0]:
			var pump = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 1.2
			cyl.bottom_radius = 1.6
			cyl.height = 8.0
			pump.mesh = cyl
			pump.position = Vector3(px, 1.5, pz)
			pump.material_override = MaterialGenerator.get_material("sci_fi_metal")
			add_child(pump)

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
