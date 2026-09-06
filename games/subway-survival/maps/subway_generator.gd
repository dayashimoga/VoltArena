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

var is_built: bool = false

func _ready() -> void:
	if not is_built:
		build_subway_station()

func build_subway_station() -> void:
	if is_built:
		return
	is_built = true
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
		_add_subway_prop_collision(prop, asset_name, s)
		add_child(prop)
		return prop
	return null

func _add_subway_prop_collision(prop: Node3D, asset_name: String, _s: Vector3) -> void:
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0

	match asset_name:
		"train_subway_car", "train_subway_middle":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.6, 3.8, 8.2)
			col.shape = box
			col.position = Vector3(0, 1.7, 0)
			body.add_child(col)
			prop.add_child(body)
		"station_stairs":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.0, 0.4, 3.6)
			col.shape = box
			col.position = Vector3(0.9, 0.7, -0.4)
			col.rotation_degrees.x = 32.0
			body.add_child(col)

			var top_col = CollisionShape3D.new()
			var top_box = BoxShape3D.new()
			top_box.size = Vector3(3.0, 0.4, 1.2)
			top_col.shape = top_box
			top_col.position = Vector3(0.9, 1.35, -0.8)
			body.add_child(top_col)
			prop.add_child(body)
		"station_bench":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(0.9, 0.9, 2.4)
			col.shape = box
			col.position = Vector3(0, 0.45, 0)
			body.add_child(col)
			prop.add_child(body)
		"ammo_box":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.2, 1.0, 1.2)
			col.shape = box
			col.position = Vector3(0, 0.5, 0)
			body.add_child(col)
			prop.add_child(body)
		"computer_terminal":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(1.2, 1.8, 1.0)
			col.shape = box
			col.position = Vector3(0, 0.9, 0)
			body.add_child(col)
			prop.add_child(body)
		"barrier_high":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(2.5, 2.0, 0.6)
			col.shape = box
			col.position = Vector3(0, 1.0, 0)
			body.add_child(col)
			prop.add_child(body)
		"door_double":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.5, 3.0, 0.5)
			col.shape = box
			col.position = Vector3(0, 1.5, 0)
			body.add_child(col)
			prop.add_child(body)
		"pipe_network":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.5, 3.5, 1.2)
			col.shape = box
			col.position = Vector3(0, 1.75, 0)
			body.add_child(col)
			prop.add_child(body)
		"wall_pillar":
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(3.0, 4.0, 3.0)
			col.shape = box
			col.position = Vector3(0, 2.0, 0)
			body.add_child(col)
			prop.add_child(body)
		_:
			body.queue_free()

func _create_visual_box(pos: Vector3, size: Vector3, material_name: String) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = MaterialGenerator.get_material(material_name)
	mesh_inst.position = pos
	add_child(mesh_inst)
	return mesh_inst

func _add_box_collision_to(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	col.shape = box
	body.add_child(col)
	parent.add_child(body)
	return body

func _build_zone_1_platform() -> void:
	# Continuous sub-station foundation slab beneath everything - zero void visible
	var f_slab = create_box(Vector3(0.0, -3.2, 30.0), Vector3(station_width + 8.0, 1.5, 140.0), "dark_concrete")
	f_slab.name = "PlatformFoundation"
	for c in f_slab.get_children():
		if c is CollisionShape3D:
			c.name = "FoundationCol"

	# Passenger Platform Floor (Single solid continuous collision slab at Y=0)
	create_box(Vector3(-5.0, -0.5, 0.0), Vector3(14.0, 1.0, 60.0), "subway_tile")

	# Platform Edge Yellow Tactile Hazard Bump Stripe (visual overlay flush with floor)
	_create_visual_box(Vector3(1.7, 0.005, 0.0), Vector3(0.6, 0.01, 60.0), "yellow_tactile_edge")

	# Platform Vertical Face Riser (between platform edge at X=2 and track bed at X=2 to 12)
	create_box(Vector3(2.0, -0.7, 0.0), Vector3(0.2, 1.4, 60.0), "dark_concrete")

	# Sunken Track Recess Ballast Bed
	create_box(Vector3(7.0, -1.9, 0.0), Vector3(10.0, 1.0, 60.0), "grimy_concrete")

	# Production 3D Detailed Railway Tracks with restored textures
	for tz in [-24.0, -16.0, -8.0, 0.0, 8.0, 16.0, 24.0]:
		_spawn_subway_prop("train_track", Vector3(6.5, -1.4, tz), 0.0, Vector3(2.5, 2.5, 2.5))

	# Exposed Industrial Concrete Ceiling with Cross-Beams
	create_box(Vector3(0.0, ceiling_height, 0.0), Vector3(station_width, 0.8, 60.0), "grimy_concrete")
	for bz in [-25.0, -15.0, -5.0, 5.0, 15.0, 25.0]:
		create_box(Vector3(0.0, ceiling_height - 0.3, bz), Vector3(station_width, 0.6, 0.8), "dark_hull")

	# Platform Back Wall with Subway Tiles and Decorative Station Frieze
	create_box(Vector3(-12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, 60.0), "subway_tile")
	create_box(Vector3(-11.45, ceiling_height * 0.72, 0.0), Vector3(0.1, 0.55, 60.0), "dark_hull") # Dark accent border band
	create_box(Vector3(-11.45, ceiling_height * 0.72, 0.0), Vector3(0.12, 0.45, 60.0), "neon_cyan")

	# Station Name Mosaic Signage ("ASHWORTH ST") & Ad Posters along platform wall
	for sz in [-20.0, -5.0, 10.0]:
		_spawn_station_sign(Vector3(-11.42, ceiling_height * 0.65, sz), "ASHWORTH ST")
		_spawn_ad_poster(Vector3(-11.42, 2.4, sz + 6.0))

	# Right Track Outer Tunnel Wall
	create_box(Vector3(12.0, ceiling_height * 0.5, 0.0), Vector3(1.0, ceiling_height, 60.0), "dark_concrete")

	# Back wall at North end
	create_box(Vector3(0.0, ceiling_height * 0.5, -30.0), Vector3(station_width, ceiling_height, 1.0), "grimy_concrete")

	# TWO ROWS OF HEAVY CAST-IRON FLUTED COLUMNS matching Reference Screenshots 2 & 4
	for cz in [-25.0, -15.0, -5.0, 5.0, 15.0, 25.0]:
		_spawn_subway_column(Vector3(-1.8, 0.0, cz), ceiling_height)
		_spawn_subway_column(Vector3(-8.8, 0.0, cz), ceiling_height)

	# SUSPENDED OVERHEAD FLUORESCENT TUBE FIXTURES matching Reference Screenshots 2 & 4
	for fz in [-22.0, -14.0, -6.0, 2.0, 10.0, 18.0, 26.0]:
		_spawn_fluorescent_fixture(Vector3(-5.3, ceiling_height - 0.65, fz))
		_spawn_fluorescent_fixture(Vector3(6.5, ceiling_height - 0.65, fz))

	# Red Vending / Ticket Kiosk Machines matching Reference Screenshot 2
	var kiosk1 = MeshBuilder.build_vending_machine()
	kiosk1.position = Vector3(-10.5, 0.0, -2.0)
	kiosk1.rotation_degrees.y = 90.0
	kiosk1.scale = Vector3(1.25, 1.25, 1.25)
	_add_box_collision_to(kiosk1, Vector3(1.4, 2.6, 1.2), Vector3(0, 1.3, 0))
	add_child(kiosk1)

	var kiosk2 = MeshBuilder.build_vending_machine()
	kiosk2.position = Vector3(-10.5, 0.0, 18.0)
	kiosk2.rotation_degrees.y = 90.0
	kiosk2.scale = Vector3(1.25, 1.25, 1.25)
	_add_box_collision_to(kiosk2, Vector3(1.4, 2.6, 1.2), Vector3(0, 1.3, 0))
	add_child(kiosk2)

	# Production Subway Train Carriages (Engine + Middle Car) with restored textures
	var train_car1 = _spawn_subway_prop("train_subway_car", Vector3(6.5, -0.6, -10.0), 0.0, Vector3(2.8, 2.8, 2.8))
	if train_car1:
		train_car1.name = "ExtractionTrain"
	var train_car2 = _spawn_subway_prop("train_subway_middle", Vector3(6.5, -0.6, 12.0), 0.0, Vector3(2.8, 2.8, 2.8))

	# Platform Access Stairs
	_spawn_subway_prop("station_stairs", Vector3(-8.5, 0.0, -26.0), 0.0, Vector3(2.5, 2.5, 2.5))

	# Passenger Waiting Benches
	_spawn_subway_prop("station_bench", Vector3(-5.3, 0.0, -12.0), 0.0, Vector3(2.2, 2.2, 2.2))
	_spawn_subway_prop("station_bench", Vector3(-5.3, 0.0, 8.0), 0.0, Vector3(2.2, 2.2, 2.2))

	# Supply Crates & Upgrade Terminal
	_spawn_subway_prop("ammo_box", Vector3(-10.5, 0.0, -8.0), 0.0, Vector3(2.0, 2.0, 2.0))
	_spawn_subway_prop("computer_terminal", Vector3(-10.5, 0.0, 6.0), 90.0, Vector3(2.0, 2.0, 2.0))

	# Security Blast Door leading to Zone 2 (at Z = 30)
	gate_zone2 = _spawn_subway_prop("door_double", Vector3(0.0, 0.0, 30.0), 0.0, Vector3(3.5, 3.0, 3.0))
	if not gate_zone2:
		gate_zone2 = MeshBuilder.build_blast_door_mesh()
		gate_zone2.position = Vector3(0.0, 0.0, 30.0)
		add_child(gate_zone2)

func _spawn_subway_column(pos: Vector3, h: float) -> Node3D:
	var col_node = Node3D.new()
	col_node.position = pos

	var mat_iron = MaterialGenerator.get_material("dark_hull")

	# Bolted Industrial Pedestal Base
	var base = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.85, 0.45, 0.85)
	base.mesh = b_mesh
	base.material_override = mat_iron
	base.position = Vector3(0, 0.22, 0)
	col_node.add_child(base)

	# Fluted Heavy Column Shaft
	var shaft = MeshInstance3D.new()
	var s_mesh = CylinderMesh.new()
	s_mesh.top_radius = 0.28
	s_mesh.bottom_radius = 0.30
	s_mesh.height = h - 0.8
	shaft.mesh = s_mesh
	shaft.material_override = mat_iron
	shaft.position = Vector3(0, (h - 0.8) * 0.5 + 0.45, 0)
	col_node.add_child(shaft)

	# Flanged Capital Bracket at ceiling
	var cap = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(0.85, 0.35, 0.85)
	cap.mesh = c_mesh
	cap.material_override = mat_iron
	cap.position = Vector3(0, h - 0.18, 0)
	col_node.add_child(cap)

	# Solid physics collider for column
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.38
	cyl.height = h
	col.shape = cyl
	col.position = Vector3(0, h * 0.5, 0)
	body.add_child(col)
	col_node.add_child(body)

	add_child(col_node)
	return col_node

func _spawn_fluorescent_fixture(pos: Vector3) -> Node3D:
	var fix_node = Node3D.new()
	fix_node.position = pos

	# Metal casing
	var casing = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(0.45, 0.15, 2.4)
	casing.mesh = c_mesh
	casing.material_override = MaterialGenerator.get_material("dark_hull")
	fix_node.add_child(casing)

	# Glowing fluorescent tube
	var tube = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(0.28, 0.06, 2.2)
	tube.mesh = t_mesh
	var mat_tube = StandardMaterial3D.new()
	mat_tube.albedo_color = Color(0.96, 0.99, 1.0)
	mat_tube.emission_enabled = true
	mat_tube.emission = Color(0.92, 0.98, 1.0)
	mat_tube.emission_energy_multiplier = 3.2
	tube.material_override = mat_tube
	tube.position = Vector3(0, -0.06, 0)
	fix_node.add_child(tube)

	# Downward light pool
	var light = OmniLight3D.new()
	light.light_color = Color(0.92, 0.98, 1.0)
	light.light_energy = 2.4
	light.omni_range = 14.0
	light.shadow_enabled = true
	light.position = Vector3(0, -0.4, 0)
	fix_node.add_child(light)

	add_child(fix_node)
	return fix_node

func _spawn_station_sign(pos: Vector3, sign_text: String) -> Node3D:
	var sign_node = Node3D.new()
	sign_node.position = pos

	var backing = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.08, 0.65, 3.2)
	backing.mesh = b_mesh
	var mat_back = StandardMaterial3D.new()
	mat_back.albedo_color = Color(0.12, 0.28, 0.22) # Classic subway forest green tile
	backing.material_override = mat_back
	sign_node.add_child(backing)

	var text_plate = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(0.10, 0.35, 2.8)
	text_plate.mesh = p_mesh
	var mat_plate = StandardMaterial3D.new()
	mat_plate.albedo_color = Color(0.98, 0.98, 0.98)
	mat_plate.emission_enabled = true
	mat_plate.emission = Color(0.95, 0.95, 0.95)
	mat_plate.emission_energy_multiplier = 0.8
	text_plate.material_override = mat_plate
	sign_node.add_child(text_plate)

	add_child(sign_node)
	return sign_node

func _spawn_ad_poster(pos: Vector3) -> Node3D:
	var ad = Node3D.new()
	ad.position = pos
	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(0.08, 1.8, 1.4)
	frame.mesh = f_mesh
	var mat_ad = StandardMaterial3D.new()
	mat_ad.albedo_color = Color(0.95, 0.45, 0.15)
	mat_ad.emission_enabled = true
	mat_ad.emission = Color(0.95, 0.45, 0.15)
	mat_ad.emission_energy_multiplier = 0.5
	frame.material_override = mat_ad
	ad.add_child(frame)
	add_child(ad)
	return ad

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
	environment.background_color = Color(0.04, 0.05, 0.07)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.32, 0.38)
	environment.ambient_light_energy = 1.15

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.25
	environment.tonemap_white = 5.5

	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.2

	# Atmospheric Station Haze matching Screenshots 2 & 4
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.18, 0.22, 0.26)
	environment.fog_density = 0.008

	env.environment = environment
	add_child(env)

	# Key Downlight from station ceiling fixtures
	var dir_fill = DirectionalLight3D.new()
	dir_fill.name = "StationFill"
	dir_fill.rotation_degrees = Vector3(-75, 15, 0)
	dir_fill.light_color = Color(0.92, 0.96, 1.0)
	dir_fill.light_energy = 0.85
	dir_fill.shadow_enabled = false
	add_child(dir_fill)

	# Sunken Track Recess Uplights
	for z in [-20.0, -7.0, 7.0, 20.0]:
		var track_light = OmniLight3D.new()
		track_light.position = Vector3(7.0, -0.6, z)
		track_light.light_color = Color(0.5, 0.7, 1.0)
		track_light.light_energy = 1.6
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
