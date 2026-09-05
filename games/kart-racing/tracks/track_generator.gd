class_name TrackGenerator
extends Node3D

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_theme: String = "metropolis" # "metropolis", "canyon", "frozen"
@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = []
	match track_theme:
		"canyon":
			# Canyon Run: 14 Waypoints, ~520m closed canyon circuit
			circuit_nodes = [
				Vector3(0, 0, 0),          # 0: Start / Finish Line
				Vector3(0, 0, -45),        # 1: Canyon Gorge Straight
				Vector3(15, -0.5, -90),    # 2: Turn 1 Canyon Entry
				Vector3(45, -1.0, -125),   # 3: Canyon Floor Sweep
				Vector3(90, -1.5, -135),   # 4: Red Rock Curve
				Vector3(140, -1.0, -120),  # 5: High Desert Straight
				Vector3(175, 0.0, -80),    # 6: Turn 2 Uphill S-Curve
				Vector3(180, 1.5, -30),    # 7: Ridge Apex
				Vector3(160, 2.0, 20),     # 8: Sandstone Mesa Turn
				Vector3(125, 1.5, 60),     # 9: Canyon Rim Hairpin
				Vector3(85, 0.5, 75),      # 10: Downhill Chute
				Vector3(45, 0.0, 60),      # 11: Final Gorge S-Bend
				Vector3(20, 0.0, 35),      # 12: Chicane
				Vector3(5, 0.0, 15)        # 13: Entry to Home Straight
			]
			# Vast Red Rock Canyon Floor
			create_box(Vector3(90.0, -0.8, -30.0), Vector3(450.0, 1.0, 450.0), "canyon_rock")
			# Sandstone Mesa Formations
			for p in [Vector3(-35, 15, -70), Vector3(65, 20, -165), Vector3(210, 18, -30), Vector3(70, 16, 110), Vector3(-25, 14, 50)]:
				create_box(p, Vector3(45.0, 30.0, 45.0), "canyon_rock")
		"frozen":
			# Frozen Ridge: 14 Waypoints, ~500m high-speed glacial circuit
			circuit_nodes = [
				Vector3(0, 0, 0),          # 0: Start / Finish Line
				Vector3(0, 0, -45),        # 1: Glacier Straight
				Vector3(-25, 0.5, -90),    # 2: Turn 1 Ice Curve
				Vector3(-40, 1.0, -135),   # 3: Frozen Fjord
				Vector3(-10, 1.5, -170),   # 4: North Ice Apex
				Vector3(35, 1.2, -160),    # 5: Crevasse Run
				Vector3(80, 0.8, -125),    # 6: Glacier Descent
				Vector3(115, 0.0, -75),    # 7: Snowfield Straight
				Vector3(125, 0.0, -20),    # 8: South Hairpin Entry
				Vector3(105, 0.0, 30),     # 9: Hairpin Apex
				Vector3(70, 0.0, 55),      # 10: Ice Bridge
				Vector3(35, 0.0, 45),      # 11: Chicane Left
				Vector3(15, 0.0, 25)       # 12: Chicane Right into Straight
			]
			# Glacial Ice Floor
			create_box(Vector3(45.0, -0.8, -50.0), Vector3(450.0, 1.0, 450.0), "snow_ice")
			# Glacial Ice Spires
			for p in [Vector3(-60, 18, -60), Vector3(25, 24, -195), Vector3(145, 20, -60), Vector3(40, 16, 80)]:
				create_box(p, Vector3(36.0, 32.0, 36.0), "snow_ice")
		_: # "metropolis" (Neon Circuit / Skyline Drift)
			# Skyline Drift: 15 Waypoints, ~560m professional circuit
			circuit_nodes = [
				Vector3(0, 0, 0),          # 0: Start / Finish Line
				Vector3(0, 0, -40),        # 1: Main Straight past Pit Lane
				Vector3(10, 0, -85),       # 2: Turn 1 (High-speed right sweeper)
				Vector3(35, 0, -125),      # 3: Turn 1 Apex
				Vector3(75, 0, -145),      # 4: Exit into Boulevard Straight
				Vector3(130, 0, -145),     # 5: Long Neon Boulevard
				Vector3(175, 0, -120),     # 6: Turn 2 Entry (Right curve)
				Vector3(195, 0, -75),      # 7: Technical Sector 2
				Vector3(185, 0, -25),      # 8: Hairpin Entry
				Vector3(155, 0, 15),       # 9: Hairpin Apex
				Vector3(115, 0, 35),       # 10: Expressway Flyover
				Vector3(70, 0, 55),        # 11: S-Bend Left
				Vector3(40, 0, 40),        # 12: S-Bend Right
				Vector3(15, 0, 20)         # 13: Final Chicane to Main Straight
			]
			# Metropolis Ground Surface
			create_box(Vector3(95.0, -0.8, -45.0), Vector3(450.0, 1.0, 450.0), "asphalt")
			# Cyberpunk Skyscrapers with Digital Billboards
			for p in [Vector3(-35, 20, -65), Vector3(65, 30, -180), Vector3(150, 32, -180), Vector3(225, 26, -50), Vector3(140, 24, 75), Vector3(-20, 20, 55)]:
				create_box(p, Vector3(38.0, 48.0, 38.0), "dark_concrete")
				create_box(p + Vector3(0, 5, 19.2), Vector3(22.0, 10.0, 0.4), "digital_signage_cyan")

	waypoints = circuit_nodes

	# Build track segments between sequential nodes
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Start/Finish Overhead Gantry Truss
	var gantry = MeshBuilder.build_start_gantry(track_width)
	gantry.position = circuit_nodes[0] + Vector3(0, 0, -2.0)
	add_child(gantry)

	# Grandstands with Spectators along Main Straight (Left & Right)
	var stand_left = MeshBuilder.build_stadium_grandstand(45.0, 8.0, 10.0)
	stand_left.position = Vector3(-track_width * 0.5 - 6.0, 0.0, -20.0)
	add_child(stand_left)

	var stand_right = MeshBuilder.build_stadium_grandstand(45.0, 8.0, 10.0)
	stand_right.position = Vector3(track_width * 0.5 + 6.0, 0.0, -20.0)
	stand_right.rotation_degrees.y = 180.0
	add_child(stand_right)

	# Stadium Floodlight Towers
	var tower1 = MeshBuilder.build_stadium_floodlight_tower(22.0)
	tower1.position = Vector3(-track_width * 0.5 - 12.0, 0.0, -42.0)
	add_child(tower1)

	var tower2 = MeshBuilder.build_stadium_floodlight_tower(22.0)
	tower2.position = Vector3(track_width * 0.5 + 12.0, 0.0, -42.0)
	tower2.rotation_degrees.y = 180.0
	add_child(tower2)

	# Place item box powerups around the circuit
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

	# Asphalt road slab with PBR aggregate texture & lane lines
	var road = StaticBody3D.new()
	road.collision_layer = GameConstants.LAYER_WORLD
	road.position = center
	road.rotation.y = angle_y

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(track_width, 0.5, seg_length + 2.0)
	col.shape = box
	road.add_child(col)

	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(track_width, 0.5, seg_length + 2.0)
	mesh.mesh = b_mesh
	mesh.material_override = MaterialGenerator.get_material("asphalt_track")
	road.add_child(mesh)

	# Red/White Ripple Rumble Curbs along both sides of the racing line
	var curb_mesh = BoxMesh.new()
	curb_mesh.size = Vector3(0.8, 0.15, seg_length + 2.0)
	var curb_mat = MaterialGenerator.get_material("curb_stripes")

	var curb_l = MeshInstance3D.new()
	curb_l.mesh = curb_mesh
	curb_l.position = Vector3(-track_width * 0.5 + 0.4, 0.28, 0)
	curb_l.material_override = curb_mat
	road.add_child(curb_l)

	var curb_r = MeshInstance3D.new()
	curb_r.mesh = curb_mesh
	curb_r.position = Vector3(track_width * 0.5 - 0.4, 0.28, 0)
	curb_r.material_override = curb_mat
	road.add_child(curb_r)

	# Continuous Physical Crash Barriers along both flanks with COLLISION SHAPES
	var rail_w = 0.6
	var rail_h = 2.0

	var left_rail = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(rail_w, rail_h, seg_length + 2.0)
	left_rail.mesh = r_mesh
	left_rail.position = Vector3(-track_width * 0.5 - rail_w * 0.5, rail_h * 0.5, 0)
	left_rail.material_override = MaterialGenerator.get_material("neon_magenta")
	road.add_child(left_rail)

	var right_rail = MeshInstance3D.new()
	right_rail.mesh = r_mesh
	right_rail.position = Vector3(track_width * 0.5 + rail_w * 0.5, rail_h * 0.5, 0)
	right_rail.material_override = MaterialGenerator.get_material("neon_cyan")
	road.add_child(right_rail)

	# Left physical barrier collider
	var col_l = CollisionShape3D.new()
	var bar_shape_l = BoxShape3D.new()
	bar_shape_l.size = Vector3(rail_w, rail_h + 1.2, seg_length + 2.0)
	col_l.shape = bar_shape_l
	col_l.position = Vector3(-track_width * 0.5 - rail_w * 0.5, rail_h * 0.5 + 0.3, 0)
	road.add_child(col_l)

	# Right physical barrier collider
	var col_r = CollisionShape3D.new()
	var bar_shape_r = BoxShape3D.new()
	bar_shape_r.size = Vector3(rail_w, rail_h + 1.2, seg_length + 2.0)
	col_r.shape = bar_shape_r
	col_r.position = Vector3(track_width * 0.5 + rail_w * 0.5, rail_h * 0.5 + 0.3, 0)
	road.add_child(col_r)

	# Outer safety tire wall at apex
	var tire_wall = MeshInstance3D.new()
	var tw_mesh = BoxMesh.new()
	tw_mesh.size = Vector3(0.8, 1.2, seg_length + 2.0)
	tire_wall.mesh = tw_mesh
	tire_wall.position = Vector3(track_width * 0.5 + 1.1, 0.6, 0)
	tire_wall.material_override = MaterialGenerator.get_material("dark_hull")
	road.add_child(tire_wall)

	add_child(road)

	# Add checkpoint at the start of each segment
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

	# Vibrant Coastal / Canyon Daylight Sky
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.52, 0.95)
	sky_mat.sky_horizon_color = Color(0.68, 0.80, 0.92)
	sky_mat.ground_bottom_color = Color(0.22, 0.28, 0.20)
	sky_mat.ground_horizon_color = Color(0.45, 0.55, 0.40)
	sky_mat.sun_angle_max = 40.0

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.55, 0.62, 0.72)
	environment.ambient_light_energy = 1.35

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.12

	env.environment = environment
	add_child(env)

	# High-Energy Golden Daylight Sun
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 45, 0)
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 2.2
	sun.shadow_enabled = true
	add_child(sun)

	# Cool Horizon Fill Light
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(45, -135, 0)
	fill.light_color = Color(0.45, 0.65, 0.95)
	fill.light_energy = 0.75
	fill.shadow_enabled = false
	add_child(fill)
