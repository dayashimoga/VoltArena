class_name TrackGenerator
extends Node3D

## TrackGenerator: Procedurally synthesizes championship racing circuits for Drift Storm.
## Features 3 high-detail environments:
## 1. Neon Circuit (Metropolitan Night Stadium with grandstands and floodlights)
## 2. Canyon Run (Expansive red rock mesa with elevation changes and rock arches)
## 3. Skyline Drift (High-altitude twilight expressway through skyscrapers)
## Built with production 3D racing and architecture kit pieces.

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_theme: String = "metropolis" # "metropolis", "canyon", "skyline"
@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = []
	match track_theme.to_lower():
		"canyon":
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -50),
				Vector3(20, 1.2, -100),
				Vector3(60, 3.5, -145),
				Vector3(110, 6.0, -165),
				Vector3(170, 7.5, -150),
				Vector3(220, 8.0, -105),
				Vector3(235, 7.5, -50),
				Vector3(225, 6.0, 10),
				Vector3(190, 4.0, 60),
				Vector3(150, 2.5, 95),
				Vector3(100, 1.0, 110),
				Vector3(55, 0.0, 90),
				Vector3(30, -0.5, 60),
				Vector3(15, 0.0, 35),
				Vector3(5, 0.0, 18)
			]
			create_box(Vector3(110.0, -1.5, -25.0), Vector3(550.0, 3.0, 550.0), "canyon_rock")
			for p in [Vector3(-45, 18, -80), Vector3(85, 24, -190), Vector3(260, 22, -40), Vector3(85, 20, 135), Vector3(-35, 16, 60), Vector3(175, 14, 25)]:
				create_box(p, Vector3(52.0, 36.0, 52.0), "canyon_rock")

		"skyline":
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -55),
				Vector3(15, 1.0, -110),
				Vector3(45, 3.5, -160),
				Vector3(95, 6.0, -190),
				Vector3(155, 7.5, -195),
				Vector3(210, 6.5, -170),
				Vector3(240, 4.5, -115),
				Vector3(235, 2.0, -55),
				Vector3(205, 0.5, 0),
				Vector3(165, 0.0, 45),
				Vector3(120, 0.0, 75),
				Vector3(75, 0.0, 70),
				Vector3(45, 0.0, 45),
				Vector3(20, 0.0, 22)
			]
			create_box(Vector3(115.0, -1.5, -55.0), Vector3(550.0, 3.0, 550.0), "asphalt")
			var building_coords = [
				[Vector3(-45, 0, -75), "a", Vector3(5, 10, 5)],
				[Vector3(75, 0, -210), "b", Vector3(6, 12, 6)],
				[Vector3(175, 0, -215), "c", Vector3(5, 11, 5)],
				[Vector3(265, 0, -60), "d", Vector3(6, 14, 6)],
				[Vector3(155, 0, 95), "a", Vector3(5, 9, 5)],
				[Vector3(-30, 0, 70), "c", Vector3(4, 4, 4)]
			]
			for bc in building_coords:
				var bld = ModelCacheScript.get_building(bc[1])
				if bld:
					bld.position = bc[0]
					bld.scale = bc[2]
					add_child(bld)
				else:
					create_box(bc[0] + Vector3(0, 25, 0), Vector3(40, 50, 40), "dark_concrete")

		_: # "metropolis" / "neon"
			circuit_nodes = [
				Vector3(0, 0, 0),
				Vector3(0, 0, -50),
				Vector3(12, 0, -100),
				Vector3(42, 0.5, -145),
				Vector3(88, 1.0, -168),
				Vector3(145, 1.0, -168),
				Vector3(195, 0.5, -140),
				Vector3(215, 0.0, -90),
				Vector3(205, 0.0, -35),
				Vector3(170, 0.0, 15),
				Vector3(125, 0.0, 40),
				Vector3(80, 0.0, 60),
				Vector3(45, 0.0, 45),
				Vector3(18, 0.0, 22)
			]
			create_box(Vector3(105.0, -1.5, -50.0), Vector3(500.0, 3.0, 500.0), "asphalt")
			var neon_props = [
				[Vector3(-35, 0, -70), "c", Vector3(4, 4, 4)],
				[Vector3(70, 0, -190), "a", Vector3(5, 8, 5)],
				[Vector3(160, 0, -190), "b", Vector3(5, 9, 5)],
				[Vector3(235, 0, -55), "c", Vector3(5, 10, 5)],
				[Vector3(150, 0, 80), "d", Vector3(5, 8, 5)]
			]
			for np in neon_props:
				var b = ModelCacheScript.get_building(np[1])
				if b:
					b.position = np[0]
					b.scale = np[2]
					add_child(b)
				else:
					create_box(np[0] + Vector3(0, 20, 0), Vector3(36, 40, 36), "dark_concrete")

	waypoints = circuit_nodes

	# Build track segments
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Production Start/Finish Overhead Gantry with Turbo Kart Rush banner & lights
	var gantry = MeshBuilder.build_start_gantry(track_width)
	gantry.position = circuit_nodes[0] + Vector3(0, 0, -2.0)
	add_child(gantry)

	# Production Grandstands with Spectator Crowds along the home straight facing inward toward track
	for z_pos in [-50.0, -25.0, 0.0, 25.0]:
		var stand_l = MeshBuilder.build_grandstand_with_crowd(24.0, 7.0, 9.0)
		stand_l.position = Vector3(-track_width * 0.5 - 6.5, 0.0, z_pos)
		stand_l.rotation_degrees.y = -90.0
		add_child(stand_l)

		var stand_r = MeshBuilder.build_grandstand_with_crowd(24.0, 7.0, 9.0)
		stand_r.position = Vector3(track_width * 0.5 + 6.5, 0.0, z_pos)
		stand_r.rotation_degrees.y = 90.0
		add_child(stand_r)

	# Production Stadium Floodlight Towers
	for fl_pos in [Vector3(-track_width * 0.5 - 12.0, 0.0, -48.0), Vector3(track_width * 0.5 + 12.0, 0.0, -48.0)]:
		var fl = ModelCacheScript.get_prop("floodlight_tower")
		if fl:
			fl.position = fl_pos
			fl.scale = Vector3(3.0, 3.0, 3.0)
			add_child(fl)

	# PowerUp Item Pickups
	var item_indices = [1, int(circuit_nodes.size() * 0.35), int(circuit_nodes.size() * 0.65), int(circuit_nodes.size() * 0.85)]
	for idx in item_indices:
		var item = PowerUpItem.new()
		item.position = circuit_nodes[idx] + Vector3(0, 0.3, 0)
		add_child(item)

	setup_racing_environment()
	track_built.emit(waypoints, checkpoints)

func build_track_segment(start_pt: Vector3, end_pt: Vector3, segment_index: int) -> void:
	var delta = end_pt - start_pt
	var seg_length = delta.length()
	var center = start_pt + delta * 0.5
	var angle_y = atan2(-delta.x, -delta.z)

	var road = StaticBody3D.new()
	road.collision_layer = GameConstants.LAYER_WORLD
	road.position = center
	road.rotation.y = angle_y

	# Hardened road slab collision (2.0m depth to prevent kart tunneling, seg_length + 0.1 for clean corners)
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(track_width, 2.0, seg_length + 0.1)
	col.shape = box
	col.position = Vector3(0, -0.8, 0)
	road.add_child(col)

	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(track_width, 0.5, seg_length + 0.1)
	mesh.mesh = b_mesh
	mesh.material_override = MaterialGenerator.get_material("asphalt_lanes")
	road.add_child(mesh)

	# Rumble Curbs along track shoulders
	var curb_w = 1.0
	var curb_h = 0.15
	var curb_l = MeshInstance3D.new()
	var cm_l = BoxMesh.new()
	cm_l.size = Vector3(curb_w, curb_h, seg_length + 0.1)
	curb_l.mesh = cm_l
	curb_l.material_override = MaterialGenerator.get_material("curb_blue_white")
	curb_l.position = Vector3(-track_width * 0.5 + curb_w * 0.5, 0.15, 0)
	road.add_child(curb_l)

	var curb_r = MeshInstance3D.new()
	var cm_r = BoxMesh.new()
	cm_r.size = Vector3(curb_w, curb_h, seg_length + 0.1)
	curb_r.mesh = cm_r
	curb_r.material_override = MaterialGenerator.get_material("curb_blue_white")
	curb_r.position = Vector3(track_width * 0.5 - curb_w * 0.5, 0.15, 0)
	road.add_child(curb_r)

	# Hardened Outer Crash Barriers strictly outside track lane
	var rail_w = 0.8
	var rail_h = 2.4
	var barrier_offset = track_width * 0.5 + rail_w * 0.5 + 0.2

	var left_bar = ModelCacheScript.get_prop("racing_barrier")
	if left_bar:
		left_bar.position = Vector3(-barrier_offset, 0.2, 0)
		left_bar.scale = Vector3(2.0, 2.0, seg_length * 0.4)
		road.add_child(left_bar)

	var right_bar = ModelCacheScript.get_prop("racing_barrier")
	if right_bar:
		right_bar.position = Vector3(barrier_offset, 0.2, 0)
		right_bar.scale = Vector3(2.0, 2.0, seg_length * 0.4)
		road.add_child(right_bar)

	# Physical barrier colliders flush with barriers, zero track encroachment
	var col_l = CollisionShape3D.new()
	var bar_shape_l = BoxShape3D.new()
	bar_shape_l.size = Vector3(rail_w, rail_h + 1.5, seg_length + 0.1)
	col_l.shape = bar_shape_l
	col_l.position = Vector3(-barrier_offset, rail_h * 0.5, 0)
	road.add_child(col_l)

	var col_r = CollisionShape3D.new()
	var bar_shape_r = BoxShape3D.new()
	bar_shape_r.size = Vector3(rail_w, rail_h + 1.5, seg_length + 0.1)
	col_r.shape = bar_shape_r
	col_r.position = Vector3(barrier_offset, rail_h * 0.5, 0)
	road.add_child(col_r)

	# Apex Tire Wall
	if segment_index % 3 == 0:
		var tire = ModelCacheScript.get_prop("racing_tire_stack")
		if tire:
			tire.position = Vector3(track_width * 0.5 + 1.5, 0.2, 0)
			tire.scale = Vector3(2.0, 2.0, 2.0)
			road.add_child(tire)

	add_child(road)

	# Checkpoint
	var cp = RaceCheckpoint.new()
	cp.checkpoint_index = segment_index
	cp.is_finish_line = (segment_index == 0)
	cp.checkpoint_width = track_width
	cp.position = start_pt + Vector3(0, 0.5, 0)
	cp.rotation.y = angle_y
	add_child(cp)
	checkpoints.append(cp)

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

func setup_racing_environment() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()

	match track_theme.to_lower():
		"canyon":
			sky_mat.sky_top_color = Color(0.20, 0.45, 0.85)
			sky_mat.sky_horizon_color = Color(0.85, 0.65, 0.45)
			sky_mat.ground_bottom_color = Color(0.35, 0.20, 0.12)
			sky_mat.ground_horizon_color = Color(0.70, 0.45, 0.30)
			environment.ambient_light_color = Color(0.75, 0.55, 0.40)
			environment.ambient_light_energy = 1.2
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.80, 0.60, 0.45)
			environment.fog_density = 0.0015
		"skyline":
			sky_mat.sky_top_color = Color(0.12, 0.18, 0.42)
			sky_mat.sky_horizon_color = Color(0.88, 0.40, 0.28)
			sky_mat.ground_bottom_color = Color(0.08, 0.08, 0.15)
			sky_mat.ground_horizon_color = Color(0.40, 0.22, 0.35)
			environment.ambient_light_color = Color(0.45, 0.40, 0.65)
			environment.ambient_light_energy = 1.1
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.50, 0.30, 0.45)
			environment.fog_density = 0.0012
		_: # "metropolis" / "neon"
			sky_mat.sky_top_color = Color(0.12, 0.20, 0.42)
			sky_mat.sky_horizon_color = Color(0.24, 0.38, 0.65)
			sky_mat.ground_bottom_color = Color(0.10, 0.14, 0.22)
			sky_mat.ground_horizon_color = Color(0.16, 0.24, 0.38)
			environment.ambient_light_color = Color(0.60, 0.70, 0.90)
			environment.ambient_light_energy = 1.6
			environment.fog_enabled = false

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.45
	environment.glow_bloom = 0.18

	env.environment = environment
	add_child(env)

	var sun = DirectionalLight3D.new()
	if track_theme.to_lower() == "neon":
		sun.rotation_degrees = Vector3(-65, 30, 0)
		sun.light_color = Color(0.85, 0.92, 1.0)
		sun.light_energy = 1.8
	elif track_theme.to_lower() == "canyon":
		sun.rotation_degrees = Vector3(-45, 55, 0)
		sun.light_color = Color(1.0, 0.92, 0.80)
		sun.light_energy = 2.4
	else:
		sun.rotation_degrees = Vector3(-50, 40, 0)
		sun.light_color = Color(1.0, 0.88, 0.82)
		sun.light_energy = 2.0
	sun.shadow_enabled = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(40, -140, 0)
	fill.light_color = Color(0.35, 0.50, 0.80)
	fill.light_energy = 0.7
	fill.shadow_enabled = false
	add_child(fill)
