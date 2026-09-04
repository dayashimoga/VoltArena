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

	# Pitch Floor
	create_box(Vector3(0, -0.5, 0), Vector3(width, 1.0, length), "asphalt_track")

	# Pitch Ceiling (keeps ball and aerial cars inside stadium)
	create_box(Vector3(0, wall_height + 0.5, 0), Vector3(width, 1.0, length), "dark_hull")

	# Sidewalls (West and East)
	create_box(Vector3(-half_x, wall_height * 0.5, 0), Vector3(1.0, wall_height, length), "sci_fi_metal")
	create_box(Vector3(half_x, wall_height * 0.5, 0), Vector3(1.0, wall_height, length), "sci_fi_metal")

	# End Walls with Goal Openings
	build_end_wall(true)  # North wall (-Z)
	build_end_wall(false) # South wall (+Z)

	# Goal trigger zones
	create_goal_trigger(Vector3(0, goal_height * 0.5, -half_z - goal_depth * 0.5), 1) # Orange scores in North
	create_goal_trigger(Vector3(0, goal_height * 0.5, half_z + goal_depth * 0.5), 0)  # Blue scores in South

	# Boost pads on field
	var pad_positions = [
		Vector3(-18.0, 0.1, -25.0),
		Vector3(18.0, 0.1, -25.0),
		Vector3(-18.0, 0.1, 25.0),
		Vector3(18.0, 0.1, 25.0),
		Vector3(0.0, 0.1, 0.0) # Center boost pad
	]
	for p in pad_positions:
		create_boost_pad(p)

	setup_stadium_lighting()

func build_end_wall(is_north: bool) -> void:
	var z_pos = (-length * 0.5) if is_north else (length * 0.5)
	var half_x = width * 0.5
	var side_wall_w = (width - goal_width) * 0.5

	# Left section
	var left_x = -half_x + side_wall_w * 0.5
	create_box(Vector3(left_x, wall_height * 0.5, z_pos), Vector3(side_wall_w, wall_height, 1.0), "sci_fi_metal")

	# Right section
	var right_x = half_x - side_wall_w * 0.5
	create_box(Vector3(right_x, wall_height * 0.5, z_pos), Vector3(side_wall_w, wall_height, 1.0), "sci_fi_metal")

	# Top crossbar section above goal
	var top_h = wall_height - goal_height
	var top_y = goal_height + top_h * 0.5
	create_box(Vector3(0, top_y, z_pos), Vector3(goal_width, top_h, 1.0), "sci_fi_metal")

	# Goal Back Wall & Net
	var back_z = z_pos + (-goal_depth if is_north else goal_depth)
	var mat_name = "neon_cyan" if is_north else "neon_orange"
	create_box(Vector3(0, goal_height * 0.5, back_z), Vector3(goal_width, goal_height, 1.0), mat_name)

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
	cyl.height = 0.1
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
			if get_node_or_null("/root/AudioManager"):
				get_node("/root/AudioManager").play_sound_3d("pickup", pos)
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
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.03, 0.06)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.25, 0.35)
	environment.ambient_light_energy = 1.0
	environment.glow_enabled = true
	env.environment = environment
	add_child(env)

	# Stadium floodlights
	for p in [Vector3(-20, 14, -35), Vector3(20, 14, -35), Vector3(-20, 14, 35), Vector3(20, 14, 35)]:
		var spot = SpotLight3D.new()
		spot.position = p
		spot.look_at(Vector3(0, 0, 0))
		spot.spot_range = 65.0
		spot.spot_angle = 55.0
		spot.light_energy = 2.5
		add_child(spot)
