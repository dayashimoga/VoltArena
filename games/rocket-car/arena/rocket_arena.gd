class_name RocketArena
extends Node3D

signal goal_triggered(scoring_team: int)

@export var length: float = 90.0
@export var width: float = 50.0
@export var wall_height: float = 16.0
@export var goal_width: float = 16.0
@export var goal_height: float = 7.0
@export var goal_depth: float = 6.0

func _ready() -> void:
	build_arena()

func build_arena() -> void:
	var half_x = width * 0.5
	var half_z = length * 0.5

	# Regulation Pitch Floor with Mowed Turf & Chalk Lines
	create_box(Vector3(0, -0.5, 0), Vector3(width, 1.0, length), "stadium_pitch")

	# Invisible Collision Ceiling (retains aerial cars & ball without black roof)
	var ceiling_body = StaticBody3D.new()
	ceiling_body.collision_layer = GameConstants.LAYER_WORLD
	ceiling_body.collision_mask = 0
	ceiling_body.position = Vector3(0, wall_height + 0.5, 0)
	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, 1.0, length)
	col_shape.shape = box_shape
	ceiling_body.add_child(col_shape)
	add_child(ceiling_body)

	# Sidewalls (West and East) with Lower Kickboard & Translucent Upper Glass
	# West Wall
	create_box(Vector3(-half_x, 1.5, 0), Vector3(1.0, 3.0, length), "dark_hull")
	create_box(Vector3(-half_x, 3.1, 0), Vector3(0.9, 0.2, length), "digital_signage_cyan") # LED Ribbon Board
	create_box(Vector3(-half_x, wall_height * 0.5 + 1.5, 0), Vector3(0.6, wall_height - 3.0, length), "sci_fi_metal")
	# East Wall
	create_box(Vector3(half_x, 1.5, 0), Vector3(1.0, 3.0, length), "dark_hull")
	create_box(Vector3(half_x, 3.1, 0), Vector3(0.9, 0.2, length), "digital_signage_orange") # LED Ribbon Board
	create_box(Vector3(half_x, wall_height * 0.5 + 1.5, 0), Vector3(0.6, wall_height - 3.0, length), "sci_fi_metal")

	# Tiered Spectator Grandstands (Outside perimeter walls)
	for tier in range(4):
		var tier_y = 2.0 + float(tier) * 2.2
		var tier_depth = 3.5
		var w_offset = half_x + 2.0 + float(tier) * 3.0
		# West Grandstands
		create_box(Vector3(-w_offset, tier_y, 0), Vector3(tier_depth, 1.8, length - 4.0), "stadium_spectators")
		# East Grandstands
		create_box(Vector3(w_offset, tier_y, 0), Vector3(tier_depth, 1.8, length - 4.0), "stadium_spectators")

	# End Walls with Goal Openings
	build_end_wall(true)  # North wall (-Z)
	build_end_wall(false) # South wall (+Z)

	# Goal trigger zones
	create_goal_trigger(Vector3(0, goal_height * 0.5, -half_z - goal_depth * 0.5), 1) # Orange scores in North
	create_goal_trigger(Vector3(0, goal_height * 0.5, half_z + goal_depth * 0.5), 0)  # Blue scores in South

	# Suspended Center Jumbotron Scoreboard Cube
	create_jumbotron()

	# Boost refill pads on field
	var pad_positions = [
		Vector3(-18.0, 0.08, -25.0),
		Vector3(18.0, 0.08, -25.0),
		Vector3(-18.0, 0.08, 25.0),
		Vector3(18.0, 0.08, 25.0),
		Vector3(0.0, 0.08, 0.0) # Center pad
	]
	for p in pad_positions:
		create_boost_pad(p)

	setup_stadium_lighting()

func create_jumbotron() -> void:
	var jumbotron = Node3D.new()
	jumbotron.name = "Jumbotron"
	jumbotron.position = Vector3(0, wall_height - 3.0, 0)

	# Main Core Box
	var core = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(10.0, 4.5, 10.0)
	core.mesh = b_mesh
	core.material_override = MaterialGenerator.get_material("dark_hull")
	jumbotron.add_child(core)

	# 4 Display Screens
	# North Screen
	var s_n = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(8.5, 3.5, 0.2)
	s_n.mesh = s_mesh
	s_n.position = Vector3(0, 0, -5.1)
	s_n.material_override = MaterialGenerator.get_material("digital_signage_cyan")
	jumbotron.add_child(s_n)
	# South Screen
	var s_s = MeshInstance3D.new()
	s_s.mesh = s_mesh
	s_s.position = Vector3(0, 0, 5.1)
	s_s.material_override = MaterialGenerator.get_material("digital_signage_orange")
	jumbotron.add_child(s_s)

	add_child(jumbotron)

func build_end_wall(is_north: bool) -> void:
	var z_pos = (-length * 0.5) if is_north else (length * 0.5)
	var half_x = width * 0.5
	var side_wall_w = (width - goal_width) * 0.5

	# Left section
	var left_x = -half_x + side_wall_w * 0.5
	create_box(Vector3(left_x, wall_height * 0.5, z_pos), Vector3(side_wall_w, wall_height, 1.2), "sci_fi_metal")

	# Right section
	var right_x = half_x - side_wall_w * 0.5
	create_box(Vector3(right_x, wall_height * 0.5, z_pos), Vector3(side_wall_w, wall_height, 1.2), "sci_fi_metal")

	# Top crossbar section above goal
	var top_h = wall_height - goal_height
	var top_y = goal_height + top_h * 0.5
	create_box(Vector3(0, top_y, z_pos), Vector3(goal_width, top_h, 1.2), "dark_hull")

	# End Wall Banner Sign
	var banner_mat = "digital_signage_cyan" if is_north else "digital_signage_orange"
	create_box(Vector3(0, top_y + 1.2, z_pos + (0.7 if is_north else -0.7)), Vector3(goal_width - 2.0, 2.0, 0.15), banner_mat)

	# Goal Back Wall & Net
	var back_z = z_pos + (-goal_depth if is_north else goal_depth)
	var net_mat = "neon_cyan" if is_north else "neon_orange"
	create_box(Vector3(0, goal_height * 0.5, back_z), Vector3(goal_width, goal_height, 0.8), net_mat)

	# Goal Posts and Crossbar Frame
	var post_mat = "sci_fi_metal"
	create_box(Vector3(-goal_width * 0.5, goal_height * 0.5, z_pos), Vector3(0.5, goal_height, 0.5), post_mat)
	create_box(Vector3(goal_width * 0.5, goal_height * 0.5, z_pos), Vector3(0.5, goal_height, 0.5), post_mat)
	create_box(Vector3(0, goal_height, z_pos), Vector3(goal_width, 0.5, 0.5), post_mat)

func create_goal_trigger(pos: Vector3, scoring_team: int) -> void:
	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_BALL
	area.position = pos

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(goal_width, goal_height, goal_depth)
	col.shape = box
	area.add_child(col)

	area.body_entered.connect(func(body: Node3D):
		if body.is_in_group("balls"):
			goal_triggered.emit(scoring_team)
	)
	add_child(area)

func create_boost_pad(pos: Vector3) -> void:
	var pad = Area3D.new()
	pad.collision_layer = 0
	pad.collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	pad.position = pos

	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.4
	cyl.bottom_radius = 1.4
	cyl.height = 0.12
	mesh.mesh = cyl
	mesh.material_override = MaterialGenerator.get_material("gold_pickup")
	pad.add_child(mesh)

	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 1.4
	cyl_shape.height = 1.0
	col.shape = cyl_shape
	pad.add_child(col)

	pad.body_entered.connect(func(body: Node3D):
		if body.has_method("replenish_boost"):
			body.replenish_boost(100.0)
			var am = GameConstants.get_autoload(pad, "AudioManager")
			if am:
				am.play_sound_3d("pickup", pos)
	)
	add_child(pad)

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

func setup_stadium_lighting() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()

	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.08, 0.12, 0.25) # Night stadium deep navy
	sky_mat.sky_horizon_color = Color(0.28, 0.38, 0.58) # Stadium floodlight glow haze
	sky_mat.ground_bottom_color = Color(0.12, 0.15, 0.20)
	sky_mat.ground_horizon_color = Color(0.22, 0.30, 0.42)
	sky_mat.sun_angle_max = 20.0

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.40, 0.48, 0.60)
	environment.ambient_light_energy = 1.4

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.15

	env.environment = environment
	add_child(env)

	# 4 High-Powered Corner Stadium Floodlight Towers
	var towers = [
		Vector3(-width * 0.45, wall_height - 1.0, -length * 0.45),
		Vector3(width * 0.45, wall_height - 1.0, -length * 0.45),
		Vector3(-width * 0.45, wall_height - 1.0, length * 0.45),
		Vector3(width * 0.45, wall_height - 1.0, length * 0.45)
	]
	for p in towers:
		# Directional Floodlight Spot
		var spot = SpotLight3D.new()
		spot.look_at_from_position(p, Vector3(0, 0, p.z * 0.2))
		spot.spot_range = 80.0
		spot.spot_angle = 60.0
		spot.light_color = Color(0.98, 0.99, 1.0)
		spot.light_energy = 2.8
		spot.shadow_enabled = true
		add_child(spot)

		# Omnidirectional Light Cluster Fill
		var omni = OmniLight3D.new()
		omni.position = p
		omni.light_color = Color(0.85, 0.92, 1.0)
		omni.light_energy = 1.8
		omni.omni_range = 35.0
		add_child(omni)
