class_name TrackGenerator
extends Node3D

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []

func _ready() -> void:
	build_circuit()

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = [
		Vector3(0, 0, 0),        # 0: Start/Finish straight
		Vector3(0, 0, -40),      # 1: Straightaway
		Vector3(20, 0, -75),     # 2: Turn 1 (Right curve)
		Vector3(60, 0, -75),     # 3: North Straight
		Vector3(85, 0, -40),     # 4: Turn 2 (Hairpin entry)
		Vector3(85, 0, 10),      # 5: Hairpin apex
		Vector3(60, 0, 45),      # 6: Turn 3
		Vector3(20, 0, 45)       # 7: Final chicane back to 0
	]

	waypoints = circuit_nodes

	# Surrounding Natural Grass Terrain (No empty black voids!)
	create_box(Vector3(45.0, -0.6, -15.0), Vector3(220.0, 0.8, 220.0), "grass")

	# Perimeter Canyon Hills & Rock Formations (Scenic framing)
	var hill_positions = [
		Vector3(-30.0, 6.0, -60.0),
		Vector3(45.0, 8.0, -110.0),
		Vector3(115.0, 7.0, -15.0),
		Vector3(45.0, 6.0, 75.0),
		Vector3(-35.0, 5.0, 20.0)
	]
	for p in hill_positions:
		create_box(p, Vector3(35.0, 14.0, 35.0), "grimy_concrete")

	# Build track segments between sequential nodes
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Start/Finish Overhead Gantry Truss with Countdown Signal Lights
	create_start_finish_gantry(circuit_nodes[0])

	# Place item box powerups
	var item_spots = [
		Vector3(0, 0.2, -25),
		Vector3(40, 0.2, -75),
		Vector3(85, 0.2, -15),
		Vector3(40, 0.2, 45)
	]
	for spot in item_spots:
		var item = PowerUpItem.new()
		item.position = spot
		add_child(item)

	setup_racing_environment()
	track_built.emit(waypoints, checkpoints)

func create_start_finish_gantry(pos: Vector3) -> void:
	var gantry = Node3D.new()
	gantry.position = pos + Vector3(0, 0, -2.0)

	# Left & Right Support Towers
	var tower_mesh = BoxMesh.new()
	tower_mesh.size = Vector3(1.2, 7.5, 1.2)
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	var t_left = MeshInstance3D.new()
	t_left.mesh = tower_mesh
	t_left.position = Vector3(-track_width * 0.5 - 1.0, 3.75, 0)
	t_left.material_override = mat_metal
	gantry.add_child(t_left)

	var t_right = MeshInstance3D.new()
	t_right.mesh = tower_mesh
	t_right.position = Vector3(track_width * 0.5 + 1.0, 3.75, 0)
	t_right.material_override = mat_metal
	gantry.add_child(t_right)

	# Overhead Cross Truss Bridge
	var bridge = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(track_width + 3.2, 1.4, 1.2)
	bridge.mesh = b_mesh
	bridge.position = Vector3(0, 7.0, 0)
	bridge.material_override = mat_metal
	gantry.add_child(bridge)

	# Digital Display Banner
	var banner = MeshInstance3D.new()
	var banner_mesh = BoxMesh.new()
	banner_mesh.size = Vector3(track_width - 1.0, 1.2, 0.2)
	banner.mesh = banner_mesh
	banner.position = Vector3(0, 7.0, 0.65)
	banner.material_override = MaterialGenerator.get_material("digital_signage_cyan")
	gantry.add_child(banner)

	add_child(gantry)

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

	# Outer Guard Rails & Crash Barriers
	var rail_w = 0.5
	var rail_h = 1.4
	var left_rail = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(rail_w, rail_h, seg_length + 2.0)
	left_rail.mesh = r_mesh
	left_rail.position = Vector3(-track_width * 0.5 - 0.25, rail_h * 0.5, 0)
	left_rail.material_override = MaterialGenerator.get_material("neon_magenta")
	road.add_child(left_rail)

	var right_rail = MeshInstance3D.new()
	right_rail.mesh = r_mesh
	right_rail.position = Vector3(track_width * 0.5 + 0.25, rail_h * 0.5, 0)
	right_rail.material_override = MaterialGenerator.get_material("neon_cyan")
	road.add_child(right_rail)

	# Safety Tire Barriers at outer edge
	var tire_wall = MeshInstance3D.new()
	var tw_mesh = BoxMesh.new()
	tw_mesh.size = Vector3(0.8, 1.2, seg_length + 2.0)
	tire_wall.mesh = tw_mesh
	tire_wall.position = Vector3(track_width * 0.5 + 0.8, 0.6, 0)
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
