class_name Workshop3D
extends Node3D

## Workshop3D: Production High-Tech Robotics Hangar for RoboForge Arena.
## Features interactive turntable, diagnostic computer racks, hydraulic gantry arms,
## hazard striping, tool benches, and live 3D robot assembly preview.

signal blueprint_updated(blueprint: Dictionary, stats: Dictionary)
signal test_dyno_requested()
signal launch_challenge_requested(challenge_id: String)

const RobotDataScript = preload("res://games/roboforge-arena/robot/robot_data.gd")
const ModularRobotScript = preload("res://games/roboforge-arena/robot/modular_robot.gd")

var preview_robot: Node3D
var turntable: Node3D
var gantry_arm: Node3D
var active_blueprint: Dictionary = {}

func _ready() -> void:
	build_workshop_environment()
	active_blueprint = RobotDataScript.get_default_blueprint()
	spawn_preview_robot()

func build_workshop_environment() -> void:
	# 1. World Environment for Hangar Ambience & Atmospheric Bloom
	var world_env = WorldEnvironment.new()
	world_env.name = "WorkshopEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.45)
	env.ambient_light_energy = 1.1
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.2
	world_env.environment = env
	add_child(world_env)

	# 2. Main Hangar Floor with Industrial Plate & Caution Border
	var floor_sb = StaticBody3D.new()
	floor_sb.name = "WorkshopFloor"
	floor_sb.collision_layer = GameConstants.LAYER_WORLD
	var mi_floor = MeshInstance3D.new()
	var box_floor = BoxMesh.new()
	box_floor.size = Vector3(28.0, 1.0, 28.0)
	mi_floor.mesh = box_floor
	mi_floor.material_override = MaterialGenerator.get_material("dark_hull")
	mi_floor.position = Vector3(0, -0.5, 0)
	floor_sb.add_child(mi_floor)

	# Floor Collision Shape (Crucial: prevents falling into abyss)
	var col_floor = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(28.0, 1.0, 28.0)
	col_floor.shape = box_shape
	col_floor.position = Vector3(0, -0.5, 0)
	floor_sb.add_child(col_floor)

	# Hazard Yellow Caution Border
	var border = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(22.0, 0.05, 22.0)
	border.mesh = b_box
	border.material_override = MaterialGenerator.get_material("hazard_yellow")
	border.position = Vector3(0, 0.02, 0)
	floor_sb.add_child(border)
	add_child(floor_sb)

	# 3. Rotating Central Assembly Turntable with Physical Collider
	var tt_body = StaticBody3D.new()
	tt_body.name = "TurntableBody"
	tt_body.collision_layer = GameConstants.LAYER_WORLD
	var tt_col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 4.2
	cyl_shape.height = 0.3
	tt_col.shape = cyl_shape
	tt_col.position = Vector3(0, 0.12, 0)
	tt_body.add_child(tt_col)
	add_child(tt_body)

	turntable = Node3D.new()
	turntable.name = "Turntable"
	var t_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.2
	cyl.height = 0.25
	t_mesh.mesh = cyl
	t_mesh.material_override = MaterialGenerator.get_material("chassis_carbon")
	t_mesh.position = Vector3(0, 0.12, 0)
	turntable.add_child(t_mesh)

	# Glowing Neon Cyan Perimeter Rings
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 4.1
	torus.outer_radius = 4.35
	ring.mesh = torus
	ring.material_override = MaterialGenerator.get_material("neon_cyan")
	ring.position = Vector3(0, 0.15, 0)
	turntable.add_child(ring)
	add_child(turntable)

	# 4. Overhead Gantry Crane & Hydraulic Arm
	var gantry_frame = Node3D.new()
	gantry_frame.name = "GantryCrane"
	var beam = MeshInstance3D.new()
	var b_beam = BoxMesh.new()
	b_beam.size = Vector3(18.0, 0.8, 1.2)
	beam.mesh = b_beam
	beam.material_override = MaterialGenerator.get_material("hazard_yellow")
	beam.position = Vector3(0, 7.5, 0)
	gantry_frame.add_child(beam)

	# Vertical support pillars
	for px in [-8.5, 8.5]:
		var pillar = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.8, 8.0, 0.8)
		pillar.mesh = p_box
		pillar.material_override = MaterialGenerator.get_material("sci_fi_metal")
		pillar.position = Vector3(px, 3.5, 0)
		gantry_frame.add_child(pillar)

	# Suspended Robotic Arm
	gantry_arm = Node3D.new()
	gantry_arm.name = "RoboticArm"
	gantry_arm.position = Vector3(0, 7.0, 0)
	var arm_mesh = MeshInstance3D.new()
	var a_cyl = CylinderMesh.new()
	a_cyl.top_radius = 0.18
	a_cyl.bottom_radius = 0.18
	a_cyl.height = 3.5
	arm_mesh.mesh = a_cyl
	arm_mesh.material_override = MaterialGenerator.get_material("sci_fi_metal")
	arm_mesh.position = Vector3(0, -1.75, 0)
	gantry_arm.add_child(arm_mesh)

	# Tool End-Effector / Welder
	var welder = MeshInstance3D.new()
	var w_cyl = CylinderMesh.new()
	w_cyl.top_radius = 0.35
	w_cyl.bottom_radius = 0.1
	w_cyl.height = 0.6
	welder.mesh = w_cyl
	welder.material_override = MaterialGenerator.get_material("neon_cyan")
	welder.position = Vector3(0, -3.7, 0)
	gantry_arm.add_child(welder)
	gantry_frame.add_child(gantry_arm)
	add_child(gantry_frame)

	# 5. Authentic SciFi Props: Computer Terminals, Pipe Networks, Barriers
	var term_left = ModelCache.get_model("res://assets/models/environment/scifi/computer_terminal.glb")
	if term_left:
		term_left.position = Vector3(-6.5, 0.0, 3.0)
		term_left.rotation_degrees.y = 45.0
		term_left.scale = Vector3(1.2, 1.2, 1.2)
		add_child(term_left)

	var term_right = ModelCache.get_model("res://assets/models/environment/scifi/computer_terminal.glb")
	if term_right:
		term_right.position = Vector3(6.5, 0.0, 3.0)
		term_right.rotation_degrees.y = -45.0
		term_right.scale = Vector3(1.2, 1.2, 1.2)
		add_child(term_right)

	var pipes_back = ModelCache.get_model("res://assets/models/environment/scifi/pipe_network.glb")
	if pipes_back:
		pipes_back.position = Vector3(0, 0.0, -11.0)
		pipes_back.scale = Vector3(1.5, 1.5, 1.5)
		add_child(pipes_back)

	var stairs = ModelCache.get_model("res://assets/models/environment/scifi/stairs_industrial.glb")
	if stairs:
		stairs.position = Vector3(-9.5, 0.0, -8.0)
		stairs.rotation_degrees.y = 90.0
		stairs.scale = Vector3(1.2, 1.2, 1.2)
		add_child(stairs)

	# Safety Perimeter Barriers
	for bx in [-8.0, 0.0, 8.0]:
		var barrier = ModelCache.get_model("res://assets/models/environment/scifi/barrier_high.glb")
		if barrier:
			barrier.position = Vector3(bx, 0.0, 10.5)
			barrier.scale = Vector3(1.0, 1.0, 1.0)
			add_child(barrier)

	# 6. High-Production 3-Point Studio Lighting (Key, Fill, Rim)
	# Overhead Key Spot
	var key_spot = SpotLight3D.new()
	key_spot.position = Vector3(0, 7.5, 0)
	key_spot.rotation_degrees.x = -90.0
	key_spot.spot_range = 18.0
	key_spot.spot_angle = 55.0
	key_spot.light_energy = 3.2
	key_spot.light_color = Color(0.95, 0.98, 1.0)
	key_spot.shadow_enabled = true
	add_child(key_spot)

	# Cool Cyan Fill Light (Low front-left)
	var fill_omni = OmniLight3D.new()
	fill_omni.position = Vector3(-4.5, 1.8, 4.5)
	fill_omni.omni_range = 12.0
	fill_omni.light_energy = 2.2
	fill_omni.light_color = Color(0.3, 0.8, 1.0)
	add_child(fill_omni)

	# Warm Amber Rim Light (High rear-right for crisp silhouette separation)
	var rim_omni = OmniLight3D.new()
	rim_omni.position = Vector3(4.5, 3.2, -4.5)
	rim_omni.omni_range = 12.0
	rim_omni.light_energy = 2.8
	rim_omni.light_color = Color(1.0, 0.82, 0.45)
	add_child(rim_omni)

func spawn_preview_robot() -> void:
	if preview_robot:
		preview_robot.queue_free()

	preview_robot = ModularRobotScript.new()
	preview_robot.name = "PreviewRobot"
	preview_robot.is_player_controlled = false
	preview_robot.process_mode = Node.PROCESS_MODE_DISABLED # Critical: disable physics so it never falls
	preview_robot.position = Vector3(0, 0.25, 0)
	turntable.add_child(preview_robot)
	preview_robot.load_blueprint(active_blueprint)

func _process(delta: float) -> void:
	if turntable:
		turntable.rotate_y(0.22 * delta)

	# Subtle robotic arm calibration sway
	if gantry_arm:
		gantry_arm.rotation.z = sin(Time.get_ticks_msec() * 0.0015) * 0.08
		gantry_arm.rotation.x = cos(Time.get_ticks_msec() * 0.0012) * 0.06

func set_chassis(chassis_id: String) -> void:
	active_blueprint["chassis"] = chassis_id
	_on_blueprint_changed()

func set_locomotion(loc_id: String) -> void:
	active_blueprint["locomotion"] = loc_id
	_on_blueprint_changed()

func set_power_core(pwr_id: String) -> void:
	active_blueprint["power_core"] = pwr_id
	_on_blueprint_changed()

func toggle_module(mod_id: String) -> void:
	var mods: Array = active_blueprint.get("modules", [])
	if mods.has(mod_id):
		mods.erase(mod_id)
	else:
		mods.append(mod_id)
	active_blueprint["modules"] = mods
	_on_blueprint_changed()

func _on_blueprint_changed() -> void:
	if preview_robot:
		preview_robot.load_blueprint(active_blueprint)
	var stats = RobotDataScript.calculate_stats(active_blueprint)
	blueprint_updated.emit(active_blueprint, stats)
