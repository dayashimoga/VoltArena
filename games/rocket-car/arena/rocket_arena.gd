class_name RocketArena
extends Node3D

## RocketArena: Regulation-scale championship arena for Nitro Kick.
## Features octagonal curved containment boundaries with transparent acrylic upper walls,
## realistic goal cages with depth/netting, MultiMesh 3D spectator crowd system,
## flush hexagonal turf boost pads, rotating full-boost orbs, and 3 distinct venue environments.

signal goal_triggered(scoring_team: int)

@export var stadium_theme: String = "day" # "day" (Volt Grand Arena), "coastal" (Coastal Park), "cyber" (Neon Night Dome)
@export var length: float = 110.0
@export var width: float = 64.0
@export var wall_height: float = 20.0
@export var goal_width: float = 16.0
@export var goal_height: float = 6.5
@export var goal_depth: float = 6.0
@export var corner_cut: float = 12.0

var pitch_length: float:
	get: return length
	set(v): length = v
var pitch_width: float:
	get: return width
	set(v): width = v
var pitch_height: float:
	get: return wall_height
	set(v): wall_height = v

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

var crowd_multimesh: MultiMeshInstance3D
var crowd_transforms: Array[Transform3D] = []
var crowd_colors: Array[Color] = []
var crowd_state: String = "idle"
var crowd_anim_time: float = 0.0

var boost_pads: Array[Node3D] = []
var boost_orbs: Array[Node3D] = []

func _ready() -> void:
	build_arena()

func _process(delta: float) -> void:
	crowd_anim_time += delta
	_update_crowd_animation(delta)

func build_arena() -> void:
	var half_x = width * 0.5
	var half_z = length * 0.5

	# 1. Broad Regulation Pitch Floor with deep 3.0m collision to prevent tunneling
	var turf_mat = "stadium_pitch_day" if stadium_theme == "day" else ("grass" if stadium_theme == "coastal" else "stadium_pitch_cyber")
	create_box(Vector3(0, -1.5, 0), Vector3(width, 3.0, length), turf_mat)

	# 2. Football-Style Pitch Markings & Team Halves
	build_pitch_markings(half_x, half_z)

	# 3. Transparent/Contained Octagonal Arena Perimeter Walls
	build_octagonal_perimeter(half_x, half_z)

	# 4. Invisible Hardened Collision Ceiling at wall_height
	var ceiling = create_box(Vector3(0, wall_height + 1.5, 0), Vector3(width + 8.0, 3.0, length + 8.0), "dark_hull")
	ceiling.visible = false

	# 5. Realistic Goals with Depth, Crossbars, Nets, and Goal Explosion VFX
	build_regulation_goal(true, half_z)  # North: Orange Goal (-Z)
	build_regulation_goal(false, half_z) # South: Blue Goal (+Z)

	# 6. Regulation Boost System (28 Small Flush Pads + 6 Large Floating Orbs)
	build_boost_system(half_x, half_z)

	# 7. Tiered Stadium Grandstands with MultiMesh Spectator Crowd
	build_stadium_grandstands_and_crowd(half_x, half_z)

	# 8. Overhead Suspended Scoreboard / Jumbotron
	create_jumbotron()

	# 9. Venue Architecture & Lighting Rigs
	setup_stadium_environment()

# ==============================================================================
# PERIMETER WALLS: OCTAGONAL CURVED BOUNDARIES & TRANSPARENT ACRYLIC
# ==============================================================================

func build_octagonal_perimeter(half_x: float, half_z: float) -> void:
	var kick_h = 2.5
	var win_h = wall_height - kick_h
	var ribbon_blue = "digital_signage_cyan" if stadium_theme != "cyber" else "neon_cyan"
	var ribbon_orange = "digital_signage_orange" if stadium_theme != "cyber" else "neon_orange"
	var glass_mat = "arena_glass" if stadium_theme != "cyber" else "arena_energy_grid"

	# West Wall (-X): Straight segment
	var w_len = length - corner_cut * 2.0
	_build_wall_segment(Vector3(-half_x, 0, 0), Vector3(0, 0, 1), w_len, kick_h, win_h, ribbon_blue, glass_mat)

	# East Wall (+X): Straight segment
	_build_wall_segment(Vector3(half_x, 0, 0), Vector3(0, 0, 1), w_len, kick_h, win_h, ribbon_orange, glass_mat)

	# North Wall (-Z): Left and right wings flanking orange goal mouth
	var n_wing_w = (width - corner_cut * 2.0 - goal_width) * 0.5
	var n_left_x = -half_x + corner_cut + n_wing_w * 0.5
	var n_right_x = half_x - corner_cut - n_wing_w * 0.5
	_build_wall_segment(Vector3(n_left_x, 0, -half_z), Vector3(1, 0, 0), n_wing_w, kick_h, win_h, ribbon_orange, glass_mat)
	_build_wall_segment(Vector3(n_right_x, 0, -half_z), Vector3(1, 0, 0), n_wing_w, kick_h, win_h, ribbon_orange, glass_mat)
	# Above goal mouth
	_build_wall_segment(Vector3(0, goal_height, -half_z), Vector3(1, 0, 0), goal_width, 0.8, wall_height - goal_height - 0.8, ribbon_orange, glass_mat)

	# South Wall (+Z): Left and right wings flanking blue goal mouth
	_build_wall_segment(Vector3(n_left_x, 0, half_z), Vector3(1, 0, 0), n_wing_w, kick_h, win_h, ribbon_blue, glass_mat)
	_build_wall_segment(Vector3(n_right_x, 0, half_z), Vector3(1, 0, 0), n_wing_w, kick_h, win_h, ribbon_blue, glass_mat)
	# Above goal mouth
	_build_wall_segment(Vector3(0, goal_height, half_z), Vector3(1, 0, 0), goal_width, 0.8, wall_height - goal_height - 0.8, ribbon_blue, glass_mat)

	# 4 Chamfered 45-degree Corner Bevels (NW, NE, SW, SE)
	var diag_len = sqrt(corner_cut * corner_cut + corner_cut * corner_cut)
	var c_nw = Vector3(-half_x + corner_cut * 0.5, 0, -half_z + corner_cut * 0.5)
	var c_ne = Vector3(half_x - corner_cut * 0.5, 0, -half_z + corner_cut * 0.5)
	var c_sw = Vector3(-half_x + corner_cut * 0.5, 0, half_z - corner_cut * 0.5)
	var c_se = Vector3(half_x - corner_cut * 0.5, 0, half_z - corner_cut * 0.5)

	_build_angled_wall_segment(c_nw, 45.0, diag_len, kick_h, win_h, ribbon_orange, glass_mat)
	_build_angled_wall_segment(c_ne, -45.0, diag_len, kick_h, win_h, ribbon_orange, glass_mat)
	_build_angled_wall_segment(c_sw, -45.0, diag_len, kick_h, win_h, ribbon_blue, glass_mat)
	_build_angled_wall_segment(c_se, 45.0, diag_len, kick_h, win_h, ribbon_blue, glass_mat)

func _build_wall_segment(pos: Vector3, _dir: Vector3, seg_len: float, kick_h: float, win_h: float, ribbon_mat: String, glass_mat: String) -> void:
	var is_z_aligned = abs(_dir.z) > 0.5
	var kick_size = Vector3(1.2, kick_h, seg_len) if is_z_aligned else Vector3(seg_len, kick_h, 1.2)
	var win_size = Vector3(0.6, win_h, seg_len) if is_z_aligned else Vector3(seg_len, win_h, 0.6)

	# 1. Lower Kickboard (Solid Dark Hull + LED Ribbon)
	var kb_body = create_box(pos + Vector3(0, kick_h * 0.5, 0), kick_size, "dark_hull")
	var rib_size = Vector3(0.12, 0.35, seg_len) if is_z_aligned else Vector3(seg_len, 0.35, 0.12)
	var rib = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = rib_size
	rib.mesh = r_box
	rib.material_override = MaterialGenerator.get_material(ribbon_mat)
	rib.position = Vector3(0, kick_h * 0.5 - 0.2, 0)
	kb_body.add_child(rib)

	# 2. Transparent Acrylic Window (Allows viewing Grandstands and Crowd)
	create_box(pos + Vector3(0, kick_h + win_h * 0.5, 0), win_size, glass_mat)

func _build_angled_wall_segment(pos: Vector3, angle_deg: float, seg_len: float, kick_h: float, win_h: float, ribbon_mat: String, glass_mat: String) -> void:
	var root = Node3D.new()
	root.position = pos
	root.rotation_degrees.y = angle_deg
	add_child(root)

	var kb_size = Vector3(seg_len, kick_h, 1.2)
	var win_size = Vector3(seg_len, win_h, 0.6)

	# Kickboard
	var kb_body = StaticBody3D.new()
	kb_body.collision_layer = GameConstants.LAYER_WORLD
	kb_body.collision_mask = 0
	kb_body.position = Vector3(0, kick_h * 0.5, 0)
	var col_k = CollisionShape3D.new()
	var b_k = BoxShape3D.new()
	b_k.size = kb_size
	col_k.shape = b_k
	kb_body.add_child(col_k)
	var m_k = MeshInstance3D.new()
	var mb_k = BoxMesh.new()
	mb_k.size = kb_size
	m_k.mesh = mb_k
	m_k.material_override = MaterialGenerator.get_material("dark_hull")
	kb_body.add_child(m_k)
	root.add_child(kb_body)

	# Ribbon
	var rib = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(seg_len, 0.35, 0.12)
	rib.mesh = r_box
	rib.material_override = MaterialGenerator.get_material(ribbon_mat)
	rib.position = Vector3(0, 0, 0.62)
	kb_body.add_child(rib)

	# Window
	var win_body = StaticBody3D.new()
	win_body.collision_layer = GameConstants.LAYER_WORLD
	win_body.collision_mask = 0
	win_body.position = Vector3(0, kick_h + win_h * 0.5, 0)
	var col_w = CollisionShape3D.new()
	var b_w = BoxShape3D.new()
	b_w.size = win_size
	col_w.shape = b_w
	win_body.add_child(col_w)
	var m_w = MeshInstance3D.new()
	var mb_w = BoxMesh.new()
	mb_w.size = win_size
	m_w.mesh = mb_w
	m_w.material_override = MaterialGenerator.get_material(glass_mat)
	win_body.add_child(m_w)
	root.add_child(win_body)

# ==============================================================================
# REALISTIC GOALS WITH DEPTH, POSTS, NET, AND GOAL SENSORS
# ==============================================================================

func build_regulation_goal(is_north: bool, half_z: float) -> void:
	var defending_team = 1 if is_north else 0 # 1 = Orange (North), 0 = Blue (South)
	var scoring_team = 0 if is_north else 1   # Entering North goal scores for Blue, South scores for Orange
	var z_sign = -1.0 if is_north else 1.0
	var mouth_z = z_sign * half_z
	var net_color = "neon_orange" if is_north else "neon_cyan"
	var team_banner_mat = "stadium_banner_orange" if is_north else "stadium_banner_blue"

	var goal_root = Node3D.new()
	goal_root.name = "Goal_" + ("Orange" if is_north else "Blue")
	goal_root.position = Vector3(0, 0, mouth_z)
	add_child(goal_root)

	var mat_post = MaterialGenerator.get_material(net_color)
	var mat_net = MaterialGenerator.create_pbr_material(Color(0.9, 0.9, 0.95, 0.4), 0.2, 0.4, Color(0.8, 0.9, 1.0), 0.8)
	mat_net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_net.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 1. Left and Right Goalposts (0.35m diameter cylinders)
	for side in [-0.5, 0.5]:
		var post = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.22
		p_cyl.bottom_radius = 0.22
		p_cyl.height = goal_height
		post.mesh = p_cyl
		post.material_override = mat_post
		post.position = Vector3(side * goal_width, goal_height * 0.5, 0)
		goal_root.add_child(post)

	# 2. Horizontal Crossbar (0.35m diameter cylinder across goal mouth)
	var bar = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.22
	b_cyl.bottom_radius = 0.22
	b_cyl.height = goal_width
	bar.mesh = b_cyl
	bar.rotation_degrees.z = 90.0
	bar.material_override = mat_post
	bar.position = Vector3(0, goal_height, 0)
	goal_root.add_child(bar)

	# 3. 6.0m Deep Net Box (Back, Left, Right, Ceiling)
	var back_z = z_sign * goal_depth
	# Back wall behind net (Solid hardened collision + goal banner)
	create_box(Vector3(0, goal_height * 0.5, mouth_z + back_z + z_sign * 1.0), Vector3(goal_width + 1.0, goal_height, 2.0), "dark_hull")
	# Left and Right net sidewalls
	create_box(Vector3(-goal_width * 0.5 - 0.5, goal_height * 0.5, mouth_z + back_z * 0.5), Vector3(1.0, goal_height, goal_depth), "dark_hull")
	create_box(Vector3(goal_width * 0.5 + 0.5, goal_height * 0.5, mouth_z + back_z * 0.5), Vector3(1.0, goal_height, goal_depth), "dark_hull")
	# Net ceiling
	create_box(Vector3(0, goal_height + 0.5, mouth_z + back_z * 0.5), Vector3(goal_width + 1.0, 1.0, goal_depth), "dark_hull")

	# Net Visual Mesh inside goal cage
	var net_mesh = MeshInstance3D.new()
	var n_box = BoxMesh.new()
	n_box.size = Vector3(goal_width, goal_height, goal_depth)
	net_mesh.mesh = n_box
	net_mesh.material_override = mat_net
	net_mesh.position = Vector3(0, goal_height * 0.5, back_z * 0.5)
	goal_root.add_child(net_mesh)

	# Team Scoreboard Banner above Goal
	var banner = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(goal_width + 4.0, 3.5, 0.4)
	banner.mesh = b_box
	banner.material_override = MaterialGenerator.get_material(team_banner_mat)
	banner.position = Vector3(0, goal_height + 2.2, z_sign * -0.3)
	goal_root.add_child(banner)

	# Goal Line Floor Sensor Stripe
	var gl = MeshInstance3D.new()
	var gl_box = BoxMesh.new()
	gl_box.size = Vector3(goal_width, 0.04, 0.60)
	gl.mesh = gl_box
	gl.material_override = mat_post
	gl.position = Vector3(0, 0.02, 0)
	goal_root.add_child(gl)

	# Goal Trigger Zone (Area3D detecting ball entrance)
	create_goal_trigger(Vector3(0, goal_height * 0.5, mouth_z + back_z * 0.5), scoring_team)

func create_goal_trigger(pos: Vector3, scoring_team: int) -> void:
	var area = Area3D.new()
	area.name = "GoalTrigger_" + str(scoring_team)
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
			trigger_goal_explosion(scoring_team, pos)
	)
	add_child(area)

func trigger_goal_explosion(scoring_team: int, pos: Vector3) -> void:
	set_crowd_state("celebration")
	# Goal explosion visual burst
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 2.0
	torus.outer_radius = 2.5
	ring.mesh = torus
	var col = Color(0.1, 0.85, 1.0) if scoring_team == 0 else Color(1.0, 0.55, 0.05)
	var mat = MaterialGenerator.create_pbr_material(col, 0.2, 0.1, col, 4.0)
	ring.material_override = mat
	ring.position = pos
	add_child(ring)

	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector3(15, 15, 15), 1.2)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 1.2)
	tween.tween_callback(ring.queue_free)

# ==============================================================================
# MULTIMESH SPECTATOR CROWD & GRANDSTAND SYSTEM
# ==============================================================================

func build_stadium_grandstands_and_crowd(half_x: float, half_z: float) -> void:
	var stand_dist_x = half_x + 6.0
	var stand_dist_z = half_z + 8.0

	# 1. Tiered Concrete Grandstand Architecture surrounding pitch
	# West Grandstand
	var w_stand = MeshBuilder.build_grandstand_with_crowd(length, 12.0, 14.0)
	w_stand.position = Vector3(-stand_dist_x, 0, 0)
	w_stand.rotation_degrees.y = -90.0
	add_child(w_stand)

	# East Grandstand
	var e_stand = MeshBuilder.build_grandstand_with_crowd(length, 12.0, 14.0)
	e_stand.position = Vector3(stand_dist_x, 0, 0)
	e_stand.rotation_degrees.y = 90.0
	add_child(e_stand)

	# North Grandstand (Orange End)
	var n_stand = MeshBuilder.build_grandstand_with_crowd(width, 10.0, 12.0)
	n_stand.position = Vector3(0, 0, -stand_dist_z)
	n_stand.rotation_degrees.y = 180.0
	add_child(n_stand)

	# South Grandstand (Blue End)
	var s_stand = MeshBuilder.build_grandstand_with_crowd(width, 10.0, 12.0)
	s_stand.position = Vector3(0, 0, stand_dist_z)
	s_stand.rotation_degrees.y = 0.0
	add_child(s_stand)

	# 2. Optimized MultiMesh 3D Spectator Crowd Instancing
	_setup_multimesh_crowd(half_x, half_z)

func _setup_multimesh_crowd(half_x: float, half_z: float) -> void:
	crowd_multimesh = MultiMeshInstance3D.new()
	crowd_multimesh.name = "StadiumCrowdMultiMesh"

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true

	# Low-Poly Stylized Spectator Mesh (Torso cylinder + head sphere)
	var spec_mesh = CylinderMesh.new()
	spec_mesh.top_radius = 0.22
	spec_mesh.bottom_radius = 0.26
	spec_mesh.height = 0.95
	mm.mesh = spec_mesh

	var spectator_positions: Array[Vector3] = []
	var team_colors = [
		Color(0.12, 0.75, 1.0),  # Blue Fan
		Color(1.0, 0.55, 0.08),  # Orange Fan
		Color(0.92, 0.92, 0.95), # White Jersey
		Color(1.0, 0.85, 0.15)   # Gold/Yellow Fan
	]

	# West Tiers (4 tiers, 50 spectators per tier = 200)
	for t in range(4):
		var ty = 3.0 + float(t) * 2.2
		var tx = -half_x - 4.5 - float(t) * 2.4
		for z_idx in range(45):
			var tz = -length * 0.42 + float(z_idx) * (length * 0.84 / 45.0)
			spectator_positions.append(Vector3(tx, ty, tz))
			crowd_colors.append(team_colors[(t + z_idx) % team_colors.size()])

	# East Tiers (4 tiers, 50 spectators per tier = 200)
	for t in range(4):
		var ty = 3.0 + float(t) * 2.2
		var tx = half_x + 4.5 + float(t) * 2.4
		for z_idx in range(45):
			var tz = -length * 0.42 + float(z_idx) * (length * 0.84 / 45.0)
			spectator_positions.append(Vector3(tx, ty, tz))
			crowd_colors.append(team_colors[(t + z_idx + 1) % team_colors.size()])

	# North & South End Tiers (3 tiers each, 30 per tier = 180)
	for t in range(3):
		var ty = 3.5 + float(t) * 2.2
		var tz_n = -half_z - 6.5 - float(t) * 2.4
		var tz_s = half_z + 6.5 + float(t) * 2.4
		for x_idx in range(30):
			var tx = -width * 0.40 + float(x_idx) * (width * 0.80 / 30.0)
			spectator_positions.append(Vector3(tx, ty, tz_n))
			crowd_colors.append(Color(1.0, 0.55, 0.08) if (x_idx % 2 == 0) else Color(0.92, 0.92, 0.95))
			spectator_positions.append(Vector3(tx, ty, tz_s))
			crowd_colors.append(Color(0.12, 0.75, 1.0) if (x_idx % 2 == 0) else Color(0.92, 0.92, 0.95))

	var total_count = spectator_positions.size()
	mm.instance_count = total_count

	for i in range(total_count):
		var t = Transform3D(Basis(), spectator_positions[i])
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, crowd_colors[i])
		crowd_transforms.append(t)

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	crowd_multimesh.material_override = mat
	crowd_multimesh.multimesh = mm
	add_child(crowd_multimesh)

func set_crowd_state(new_state: String) -> void:
	crowd_state = new_state
	if new_state == "celebration":
		var tree = get_tree() if is_inside_tree() else null
		if tree:
			tree.create_timer(3.5).timeout.connect(func(): crowd_state = "idle")

func set_crowd_reaction_state(new_state: String) -> void:
	set_crowd_state(new_state)

func _update_crowd_animation(_delta: float) -> void:
	if not crowd_multimesh or not crowd_multimesh.multimesh:
		return

	var mm = crowd_multimesh.multimesh
	var freq = 3.0
	var amp = 0.08

	match crowd_state:
		"celebration":
			freq = 9.0
			amp = 0.45
		"buildup", "tension":
			freq = 6.0
			amp = 0.18
		_:
			freq = 2.5
			amp = 0.06

	# Modulate a subset of spectators dynamically
	var count = mini(mm.instance_count, crowd_transforms.size())
	for i in range(0, count, 4):
		var base_t = crowd_transforms[i]
		var wave = sin(crowd_anim_time * freq + float(i) * 0.15) * amp
		var t = base_t
		t.origin.y += wave
		mm.set_instance_transform(i, t)

# ==============================================================================
# REGULATION BOOST SYSTEM: 28 SMALL FLUSH PADS + 6 FLOATING ORBS
# ==============================================================================

func build_boost_system(half_x: float, half_z: float) -> void:
	# 6 Full 100% Boost Orbs at regulation corner and midfield locations
	var full_orb_coords = [
		Vector3(-half_x + 6.0, 0.0, -half_z + 10.0), # NW Corner
		Vector3(half_x - 6.0, 0.0, -half_z + 10.0),  # NE Corner
		Vector3(-half_x + 6.0, 0.0, half_z - 10.0),  # SW Corner
		Vector3(half_x - 6.0, 0.0, half_z - 10.0),   # SE Corner
		Vector3(-half_x + 5.0, 0.0, 0.0),            # West Midfield
		Vector3(half_x - 5.0, 0.0, 0.0)              # East Midfield
	]
	for p in full_orb_coords:
		create_boost_orb(p)

	# 28 Small 12% Boost Pads flush in turf
	var small_pad_coords: Array[Vector3] = []
	# Center circle ring
	for a in range(8):
		var ang = float(a) / 8.0 * TAU
		small_pad_coords.append(Vector3(cos(ang) * 11.5, 0.02, sin(ang) * 11.5))
	# Midfield lanes
	for x_lane in [-16.0, 0.0, 16.0]:
		for z_pos in [-34.0, -22.0, -10.0, 10.0, 22.0, 34.0]:
			small_pad_coords.append(Vector3(x_lane, 0.02, z_pos))
	# Goalmouth defensive arcs
	for x_side in [-7.0, 7.0]:
		small_pad_coords.append(Vector3(x_side, 0.02, -half_z + 18.0))
		small_pad_coords.append(Vector3(x_side, 0.02, half_z - 18.0))

	for sp in small_pad_coords:
		create_flush_boost_pad(sp)

func create_boost_orb(pos: Vector3) -> void:
	var orb_root = Node3D.new()
	orb_root.name = "FullBoostOrb"
	orb_root.position = pos
	add_child(orb_root)

	var orb_mesh = MeshBuilder.build_boost_orb_mesh()
	orb_mesh.position = Vector3(0, 1.4, 0)
	orb_root.add_child(orb_mesh)

	var area = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.6
	col.shape = sphere
	col.position = Vector3(0, 1.4, 0)
	area.add_child(col)
	orb_root.add_child(area)

	var is_active = [true]
	area.body_entered.connect(func(body: Node3D):
		if not is_active[0]:
			return
		if body.has_method("replenish_boost"):
			body.replenish_boost(100.0)
			is_active[0] = false
			orb_mesh.visible = false
			var am = GameConstants.get_autoload(area, "AudioManager")
			if am:
				am.play_sound_3d("boost", pos, 1.2)
			var tree = area.get_tree() if area.is_inside_tree() else null
			if tree:
				tree.create_timer(10.0).timeout.connect(func():
					is_active[0] = true
					orb_mesh.visible = true
				)
	)
	boost_orbs.append(orb_root)

func create_flush_boost_pad(pos: Vector3) -> void:
	var pad = Area3D.new()
	pad.name = "SmallBoostPad"
	pad.collision_layer = 0
	pad.collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	pad.position = pos

	# Flush hexagonal pitch pad (0.02m high, 1.2m diameter)
	var hex = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.65
	cyl.bottom_radius = 0.70
	cyl.height = 0.04
	hex.mesh = cyl
	var mat_active = MaterialGenerator.create_pbr_material(Color(1.0, 0.85, 0.15), 0.8, 0.2, Color(1.0, 0.85, 0.15), 3.0)
	var mat_inactive = MaterialGenerator.get_material("dark_hull")
	hex.material_override = mat_active
	pad.add_child(hex)

	var col = CollisionShape3D.new()
	var c_shape = CylinderShape3D.new()
	c_shape.radius = 1.1
	c_shape.height = 1.0
	col.shape = c_shape
	pad.add_child(col)

	var is_active = [true]
	pad.body_entered.connect(func(body: Node3D):
		if not is_active[0]:
			return
		if body.has_method("replenish_boost"):
			body.replenish_boost(15.0)
			is_active[0] = false
			hex.material_override = mat_inactive
			var am = GameConstants.get_autoload(pad, "AudioManager")
			if am:
				am.play_sound_3d("pickup", pos)
			var tree = pad.get_tree() if pad.is_inside_tree() else null
			if tree:
				tree.create_timer(4.0).timeout.connect(func():
					is_active[0] = true
					hex.material_override = mat_active
				)
	)
	add_child(pad)
	boost_pads.append(pad)

# ==============================================================================
# JUMBOTRON SCOREBOARD & STADIUM ENVIRONMENT LIGHTING
# ==============================================================================

func create_jumbotron() -> void:
	var jb_root = Node3D.new()
	jb_root.name = "Jumbotron"
	jb_root.position = Vector3(0, wall_height - 3.5, 0)

	var core = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(12.0, 5.0, 12.0)
	core.mesh = b_mesh
	core.material_override = MaterialGenerator.get_material("dark_hull")
	jb_root.add_child(core)

	# 4 Large Jumbotron Screens facing all 4 directions
	var screens = [
		[Vector3(0, 0, -6.1), Vector3(10.5, 4.0, 0.2), "digital_signage_orange"],
		[Vector3(0, 0, 6.1), Vector3(10.5, 4.0, 0.2), "digital_signage_cyan"],
		[Vector3(-6.1, 0, 0), Vector3(0.2, 4.0, 10.5), "neon_cyan"],
		[Vector3(6.1, 0, 0), Vector3(0.2, 4.0, 10.5), "neon_orange"]
	]
	for sc in screens:
		var s = MeshInstance3D.new()
		var sm = BoxMesh.new()
		sm.size = sc[1]
		s.mesh = sm
		s.position = sc[0]
		s.material_override = MaterialGenerator.get_material(sc[2])
		jb_root.add_child(s)

	add_child(jb_root)

func setup_stadium_environment() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()

	match stadium_theme:
		"coastal":
			# Coastal Park: Daylight, seaside sky
			sky_mat.sky_top_color = Color(0.20, 0.50, 0.95)
			sky_mat.sky_horizon_color = Color(0.75, 0.88, 1.0)
			sky_mat.ground_bottom_color = Color(0.15, 0.35, 0.15)
			sky_mat.ground_horizon_color = Color(0.50, 0.70, 0.50)
			environment.ambient_light_energy = 0.65
			environment.glow_enabled = true
			environment.glow_intensity = 0.15
			var sun = DirectionalLight3D.new()
			sun.name = "StadiumSun"
			sun.light_color = Color(1.0, 0.98, 0.92)
			sun.light_energy = 1.40
			sun.shadow_enabled = true
			sun.rotation_degrees = Vector3(-50, 30, 0)
			add_child(sun)

		"cyber":
			# Neon Night Dome: Midnight e-sports venue
			sky_mat.sky_top_color = Color(0.08, 0.10, 0.22)
			sky_mat.sky_horizon_color = Color(0.25, 0.15, 0.38)
			sky_mat.ground_bottom_color = Color(0.04, 0.04, 0.08)
			sky_mat.ground_horizon_color = Color(0.18, 0.10, 0.25)
			environment.ambient_light_color = Color(0.35, 0.40, 0.65)
			environment.ambient_light_energy = 0.85
			environment.glow_enabled = true
			environment.glow_intensity = 0.45
			environment.glow_bloom = 0.15
			var dome_light = DirectionalLight3D.new()
			dome_light.name = "DomeLighting"
			dome_light.light_color = Color(0.75, 0.85, 1.0)
			dome_light.light_energy = 0.90
			dome_light.rotation_degrees = Vector3(-70, 45, 0)
			add_child(dome_light)

		_: # "day" / "grand_arena"
			# Volt Grand Arena: Indoor championship stadium with overhead floodlights
			sky_mat.sky_top_color = Color(0.16, 0.24, 0.42)
			sky_mat.sky_horizon_color = Color(0.40, 0.52, 0.70)
			sky_mat.ground_bottom_color = Color(0.10, 0.14, 0.18)
			sky_mat.ground_horizon_color = Color(0.30, 0.38, 0.45)
			environment.ambient_light_color = Color(0.60, 0.70, 0.82)
			environment.ambient_light_energy = 0.70
			environment.glow_enabled = true
			environment.glow_intensity = 0.25
			environment.glow_bloom = 0.08
			var sun = DirectionalLight3D.new()
			sun.name = "StadiumSun"
			sun.light_color = Color(1.0, 0.98, 0.94)
			sun.light_energy = 1.30
			sun.shadow_enabled = true
			sun.rotation_degrees = Vector3(-60, 25, 0)
			add_child(sun)

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	env.environment = environment
	add_child(env)

# ==============================================================================
# UTILITY BUILDERS: BOXES, LINES, MARKINGS
# ==============================================================================

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

	# Center Halfway Line & Spot
	create_flat_marker(Vector3(0, y_elev, 0), Vector3(width - 4.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(0, y_elev + 0.01, 0), Vector3(1.6, 0.02, 1.6), line_mat)

	# Center Circle (8.5m radius)
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

	# Outer Touchlines
	create_flat_marker(Vector3(-half_x + 1.8, y_elev, 0), Vector3(line_w, 0.02, length - 3.6), line_mat)
	create_flat_marker(Vector3(half_x - 1.8, y_elev, 0), Vector3(line_w, 0.02, length - 3.6), line_mat)
	create_flat_marker(Vector3(0, y_elev, -half_z + 1.8), Vector3(width - 3.6, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(0, y_elev, half_z - 1.8), Vector3(width - 3.6, 0.02, line_w), line_mat)

	# North Penalty Area (-Z)
	create_flat_marker(Vector3(0, y_elev, -half_z + 18.0), Vector3(26.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(-13.0, y_elev, -half_z + 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
	create_flat_marker(Vector3(13.0, y_elev, -half_z + 9.9), Vector3(line_w, 0.02, 16.2), line_mat)

	# South Penalty Area (+Z)
	create_flat_marker(Vector3(0, y_elev, half_z - 18.0), Vector3(26.0, 0.02, line_w), line_mat)
	create_flat_marker(Vector3(-13.0, y_elev, half_z - 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
	create_flat_marker(Vector3(13.0, y_elev, half_z - 9.9), Vector3(line_w, 0.02, 16.2), line_mat)
