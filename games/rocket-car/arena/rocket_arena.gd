class_name RocketArena
extends Node3D

signal goal_triggered(scoring_team: int)

@export var stadium_theme: String = "day" # "day" (Volt Park) or "cyber" (Cyber Dome)
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

	# Pitch Floor with Turf based on Theme
	var turf_material = "stadium_pitch_day" if stadium_theme == "day" else "stadium_pitch_cyber"
	create_box(Vector3(0, -0.5, 0), Vector3(width, 1.0, length), turf_material)

	# High-Readability Soccer Pitch Markings & Team Halves
	build_pitch_markings(half_x, half_z)

	# Invisible Collision Ceiling
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

	# Sidewalls (West and East) with Lower Kickboard & LED Ribbon
	var ribbon_color_1 = "digital_signage_cyan" if stadium_theme == "day" else "neon_cyan"
	var ribbon_color_2 = "digital_signage_orange" if stadium_theme == "day" else "neon_orange"

	create_box(Vector3(-half_x, 1.5, 0), Vector3(1.0, 3.0, length), "dark_hull")
	create_box(Vector3(-half_x, 3.1, 0), Vector3(0.9, 0.2, length), ribbon_color_1)
	create_box(Vector3(-half_x, wall_height * 0.5 + 1.5, 0), Vector3(0.6, wall_height - 3.0, length), "sci_fi_metal")

	create_box(Vector3(half_x, 1.5, 0), Vector3(1.0, 3.0, length), "dark_hull")
	create_box(Vector3(half_x, 3.1, 0), Vector3(0.9, 0.2, length), ribbon_color_2)
	create_box(Vector3(half_x, wall_height * 0.5 + 1.5, 0), Vector3(0.6, wall_height - 3.0, length), "sci_fi_metal")

	# Tiered Spectator Grandstands
	for tier in range(4):
		var tier_y = 2.0 + float(tier) * 2.2
		var tier_depth = 3.5
		var w_offset = half_x + 2.0 + float(tier) * 3.0
		create_box(Vector3(-w_offset, tier_y, 0), Vector3(tier_depth, 1.8, length - 4.0), "stadium_spectators")
		create_box(Vector3(w_offset, tier_y, 0), Vector3(tier_depth, 1.8, length - 4.0), "stadium_spectators")

	# End Walls with Goal Openings
	build_end_wall(true)  # North wall (-Z, Team 1 Orange Goal)
	build_end_wall(false) # South wall (+Z, Team 0 Blue Goal)

	# Modeled Stadium Goals
	var goal_north = MeshBuilder.build_stadium_goal_mesh(1)
	goal_north.position = Vector3(0, 0, -half_z)
	add_child(goal_north)

	var goal_south = MeshBuilder.build_stadium_goal_mesh(0)
	goal_south.position = Vector3(0, 0, half_z)
	goal_south.rotation_degrees = Vector3(0, 180, 0)
	add_child(goal_south)

	# Goal trigger zones
	create_goal_trigger(Vector3(0, goal_height * 0.5, -half_z - goal_depth * 0.5), 1) # Orange scores in North
	create_goal_trigger(Vector3(0, goal_height * 0.5, half_z + goal_depth * 0.5), 0)  # Blue scores in South

	# Suspended Center Jumbotron Scoreboard Cube
	create_jumbotron()

	# 6 Full 100% Boost Orbs (4 corners + 2 midfield wings)
	var full_orb_positions = [
		Vector3(-20.0, 0.0, -38.0),
		Vector3(20.0, 0.0, -38.0),
		Vector3(-20.0, 0.0, 38.0),
		Vector3(20.0, 0.0, 38.0),
		Vector3(-22.0, 0.0, 0.0),
		Vector3(22.0, 0.0, 0.0)
	]
	for op in full_orb_positions:
		create_boost_orb(op)

	# 12 Small Boost Refill Pads
	var small_pad_positions = [
		Vector3(-10.0, 0.08, -25.0),
		Vector3(10.0, 0.08, -25.0),
		Vector3(-10.0, 0.08, 25.0),
		Vector3(10.0, 0.08, 25.0),
		Vector3(-10.0, 0.08, -12.0),
		Vector3(10.0, 0.08, -12.0),
		Vector3(-10.0, 0.08, 12.0),
		Vector3(10.0, 0.08, 12.0),
		Vector3(0.0, 0.08, -20.0),
		Vector3(0.0, 0.08, 20.0),
		Vector3(0.0, 0.08, -8.0),
		Vector3(0.0, 0.08, 8.0)
	]
	for sp in small_pad_positions:
		create_boost_pad(sp)

	setup_stadium_lighting()

func create_boost_orb(pos: Vector3) -> void:
	var orb_node = MeshBuilder.build_boost_orb_mesh()
	orb_node.position = pos
	add_child(orb_node)

	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.6
	col.shape = sphere
	col.position = Vector3(0, 1.2, 0)
	area.add_child(col)
	orb_node.add_child(area)

	area.body_entered.connect(func(body: Node3D):
		if body.has_method("replenish_boost"):
			body.replenish_boost(100.0)
			var am = GameConstants.get_autoload(area, "AudioManager")
			if am:
				am.play_sound_3d("boost", pos, 1.2)
	)

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

func create_flat_marker(pos: Vector3, size: Vector3, material_name: String) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = MaterialGenerator.get_material(material_name)
	add_child(mesh_inst)
	return mesh_inst

func build_pitch_markings(half_x: float, half_z: float) -> void:
	var line_mat = "pitch_line_white"
	var y_elev = 0.02
	var line_w = 0.45

	# Center Line dividing Blue and Orange Halves
	create_flat_marker(Vector3(0, y_elev, 0), Vector3(width - 4.0, 0.02, line_w), line_mat)

	# Center Spot (Kickoff Ball Point)
	create_flat_marker(Vector3(0, y_elev + 0.01, 0), Vector3(1.6, 0.02, 1.6), line_mat)

	# Center Circle (8.5m radius approximated with 24 segments)
	var radius = 8.5
	var segments = 24
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU
		var angle2 = (float(i + 1) / segments) * TAU
		var p1 = Vector3(cos(angle1) * radius, y_elev, sin(angle1) * radius)
		var p2 = Vector3(cos(angle2) * radius, y_elev, sin(angle2) * radius)
		var mid = (p1 + p2) * 0.5
		var seg_len = p1.distance_to(p2)
		var seg = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(line_w, 0.02, seg_len)
		seg.mesh = s_box
		seg.position = mid
		seg.look_at_from_position(mid, p2, Vector3.UP)
		seg.material_override = MaterialGenerator.get_material(line_mat)
		add_child(seg)

	# Outer Boundary Touchlines
	create_flat_marker(Vector3(-half_x + 1.8, y_elev, 0), Vector3(line_w, 0.02, length - 3.6), line_mat)
	create_flat_marker(Vector3(half_x - 1.8, y_elev, 0), Vector3(line_w, 0.02, length - 3.6), line_mat)
	create_flat_marker(Vector3(0, y_elev, -half_z + 1.8), Vector3(width - 3.6, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(0, y_elev, half_z - 1.8), Vector3(width - 3.6, 0.02, line_w), line_mat)

	# North Half (Orange Goal Territory, -Z)
	create_flat_marker(Vector3(0, y_elev, -half_z + 18.0), Vector3(26.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(-13.0, y_elev, -half_z + 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
	create_flat_marker(Vector3(13.0, y_elev, -half_z + 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
	create_flat_marker(Vector3(0, y_elev, -half_z + 8.0), Vector3(18.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(-9.0, y_elev, -half_z + 4.9), Vector3(line_w, 0.02, 6.2), line_mat)
	create_flat_marker(Vector3(9.0, y_elev, -half_z + 4.9), Vector3(line_w, 0.02, 6.2), line_mat)
	create_flat_marker(Vector3(0, y_elev + 0.01, -half_z + 12.0), Vector3(1.0, 0.02, 1.0), line_mat)
	create_flat_marker(Vector3(0, y_elev + 0.005, -half_z * 0.5), Vector3(0.2, 0.02, half_z - 3.0), "pitch_orange_zone")

	# South Half (Blue Goal Territory, +Z)
	create_flat_marker(Vector3(0, y_elev, half_z - 18.0), Vector3(26.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(-13.0, y_elev, half_z - 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
	create_flat_marker(Vector3(13.0, y_elev, half_z - 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
	create_flat_marker(Vector3(0, y_elev, half_z - 8.0), Vector3(18.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(-9.0, y_elev, half_z - 4.9), Vector3(line_w, 0.02, 6.2), line_mat)
	create_flat_marker(Vector3(9.0, y_elev, half_z - 4.9), Vector3(line_w, 0.02, 6.2), line_mat)
	create_flat_marker(Vector3(0, y_elev + 0.01, half_z - 12.0), Vector3(1.0, 0.02, 1.0), line_mat)
	create_flat_marker(Vector3(0, y_elev + 0.005, half_z * 0.5), Vector3(0.2, 0.02, half_z - 3.0), "pitch_blue_zone")

func setup_stadium_lighting() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()

	var sky_mat = ProceduralSkyMaterial.new()
	if stadium_theme == "day":
		# Volt Park Daylight Stadium: Crisp sunny clear atmosphere
		sky_mat.sky_top_color = Color(0.25, 0.55, 0.92)
		sky_mat.sky_horizon_color = Color(0.72, 0.85, 0.98)
		sky_mat.ground_bottom_color = Color(0.20, 0.38, 0.18)
		sky_mat.ground_horizon_color = Color(0.55, 0.72, 0.52)
		sky_mat.sun_angle_max = 35.0

		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		environment.ambient_light_color = Color(0.68, 0.78, 0.90)
		environment.ambient_light_energy = 1.65

		environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		environment.tonemap_exposure = 1.25
		environment.tonemap_white = 6.0

		environment.glow_enabled = true
		environment.glow_intensity = 0.25
		environment.glow_bloom = 0.10

		# Dedicated Directional Sunlight
		var sun = DirectionalLight3D.new()
		sun.name = "StadiumSun"
		sun.light_color = Color(1.0, 0.98, 0.92)
		sun.light_energy = 2.4
		sun.shadow_enabled = true
		sun.rotation_degrees = Vector3(-55, 35, 0)
		add_child(sun)
	else:
		# Cyber Dome Night Stadium: Electric floodlit arena
		sky_mat.sky_top_color = Color(0.06, 0.10, 0.22)
		sky_mat.sky_horizon_color = Color(0.20, 0.32, 0.50)
		sky_mat.ground_bottom_color = Color(0.10, 0.14, 0.18)
		sky_mat.ground_horizon_color = Color(0.20, 0.28, 0.40)
		sky_mat.sun_angle_max = 20.0

		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		environment.ambient_light_color = Color(0.50, 0.58, 0.70)
		environment.ambient_light_energy = 1.45

		environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		environment.tonemap_exposure = 1.35
		environment.tonemap_white = 6.0

		environment.glow_enabled = true
		environment.glow_intensity = 0.35
		environment.glow_bloom = 0.15

		# Overhead Main Floodlight Key
		var flood_key = DirectionalLight3D.new()
		flood_key.name = "StadiumFloodKey"
		flood_key.light_color = Color(0.95, 0.98, 1.0)
		flood_key.light_energy = 1.8
		flood_key.shadow_enabled = true
		flood_key.rotation_degrees = Vector3(-80, 0, 0)
		add_child(flood_key)

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

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
		var spot = SpotLight3D.new()
		spot.look_at_from_position(p, Vector3(0, 0, p.z * 0.2))
		spot.spot_range = 80.0
		spot.spot_angle = 60.0
		spot.light_color = Color(0.98, 0.99, 1.0)
		spot.light_energy = 2.2 if stadium_theme == "day" else 2.8
		spot.shadow_enabled = (stadium_theme != "day")
		add_child(spot)

		var omni = OmniLight3D.new()
		omni.position = p
		omni.light_color = Color(0.85, 0.92, 1.0)
		omni.light_energy = 1.4 if stadium_theme == "day" else 1.8
		omni.omni_range = 35.0
		add_child(omni)
