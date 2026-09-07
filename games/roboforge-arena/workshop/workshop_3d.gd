class_name Workshop3D
extends Node3D

## Workshop3D: Interactive 3D Assembly Bay for RoboForge Arena.
## Features turntable assembly stage, live 3D robot re-meshing, live stat meters,
## and blueprint management.

signal blueprint_updated(blueprint: Dictionary, stats: Dictionary)
signal test_dyno_requested()
signal launch_challenge_requested(challenge_id: String)

const RobotDataScript = preload("res://games/roboforge-arena/robot/robot_data.gd")
const ModularRobotScript = preload("res://games/roboforge-arena/robot/modular_robot.gd")

var preview_robot: Node3D
var turntable: Node3D
var active_blueprint: Dictionary = {}

func _ready() -> void:
	build_workshop_environment()
	active_blueprint = RobotDataScript.get_default_blueprint()
	spawn_preview_robot()

func build_workshop_environment() -> void:
	# Main Bay Floor
	var floor_sb = StaticBody3D.new()
	floor_sb.collision_layer = GameConstants.LAYER_WORLD
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(20.0, 1.0, 20.0)
	mi.mesh = box
	mi.material_override = MaterialGenerator.get_material("dark_hull")
	mi.position = Vector3(0, -0.5, 0)
	floor_sb.add_child(mi)
	add_child(floor_sb)

	# Rotating Turntable Platform
	turntable = Node3D.new()
	turntable.name = "Turntable"
	var t_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 3.2
	cyl.bottom_radius = 3.3
	cyl.height = 0.2
	t_mesh.mesh = cyl
	t_mesh.material_override = MaterialGenerator.get_material("hazard_yellow")
	t_mesh.position = Vector3(0, 0.1, 0)
	turntable.add_child(t_mesh)

	# Illuminated glowing perimeter ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 3.3
	torus.outer_radius = 3.5
	ring.mesh = torus
	ring.material_override = MaterialGenerator.get_material("neon_cyan")
	ring.position = Vector3(0, 0.12, 0)
	turntable.add_child(ring)

	add_child(turntable)

	# Overhead Floodlights
	var spot = SpotLight3D.new()
	spot.position = Vector3(0, 7.0, 0)
	spot.rotation_degrees.x = -90.0
	spot.spot_range = 14.0
	spot.spot_angle = 45.0
	spot.light_energy = 3.5
	add_child(spot)

func spawn_preview_robot() -> void:
	if preview_robot:
		preview_robot.queue_free()

	preview_robot = ModularRobotScript.new()
	preview_robot.name = "PreviewRobot"
	preview_robot.is_player_controlled = false
	preview_robot.position = Vector3(0, 0.2, 0)
	turntable.add_child(preview_robot)
	preview_robot.load_blueprint(active_blueprint)

func _process(delta: float) -> void:
	if turntable:
		turntable.rotate_y(0.25 * delta)

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
