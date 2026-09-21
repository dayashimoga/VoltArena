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
	# 1. Main Hangar Floor with Industrial Plate & Caution Border
	var floor_sb = StaticBody3D.new()
	floor_sb.collision_layer = GameConstants.LAYER_WORLD
	var mi_floor = MeshInstance3D.new()
	var box_floor = BoxMesh.new()
	box_floor.size = Vector3(28.0, 1.0, 28.0)
	mi_floor.mesh = box_floor
	mi_floor.material_override = MaterialGenerator.get_material("dark_hull")
	mi_floor.position = Vector3(0, -0.5, 0)
	floor_sb.add_child(mi_floor)

	# Hazard Yellow Caution Border
	var border = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(22.0, 0.05, 22.0)
	border.mesh = b_box
	border.material_override = MaterialGenerator.get_material("hazard_yellow")
	border.position = Vector3(0, 0.02, 0)
	floor_sb.add_child(border)
	add_child(floor_sb)

	# 2. Rotating Central Assembly Turntable
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

	# 3. Overhead Gantry Crane & Hydraulic Arm
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

	# 4. Diagnostic Computer Terminals & Server Racks
	for tz in [-10.0, 10.0]:
		var rack = Node3D.new()
		rack.position = Vector3(0, 0, tz)
		var r_mesh = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(8.0, 3.2, 1.4)
		r_mesh.mesh = r_box
		r_mesh.material_override = MaterialGenerator.get_material("dark_hull")
		r_mesh.position = Vector3(0, 1.6, 0)
		rack.add_child(r_mesh)

		# Screen displays
		var screen = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(7.2, 1.2, 0.1)
		screen.mesh = s_box
		screen.material_override = MaterialGenerator.get_material("neon_cyan")
		screen.position = Vector3(0, 2.0, 0.72 if tz < 0 else -0.72)
		rack.add_child(screen)
		add_child(rack)

	# 5. Overhead High-Intensity Spotlights
	var spot = SpotLight3D.new()
	spot.position = Vector3(0, 7.5, 0)
	spot.rotation_degrees.x = -90.0
	spot.spot_range = 16.0
	spot.spot_angle = 50.0
	spot.light_energy = 4.0
	spot.light_color = Color(0.95, 0.98, 1.0)
	add_child(spot)

func spawn_preview_robot() -> void:
	if preview_robot:
		preview_robot.queue_free()

	preview_robot = ModularRobotScript.new()
	preview_robot.name = "PreviewRobot"
	preview_robot.is_player_controlled = false
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
