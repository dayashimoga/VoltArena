class_name RoboForgeMain
extends Node3D

## RoboForgeMain: Main Game Controller for RoboForge Arena.
## Seamlessly switches between 3D Workshop assembly bay and physical challenge courses.

const Workshop3DScript = preload("res://games/roboforge-arena/workshop/workshop_3d.gd")
const ModularRobotScript = preload("res://games/roboforge-arena/robot/modular_robot.gd")
const ChallengeManagerScript = preload("res://games/roboforge-arena/challenges/challenge_manager.gd")
const RoboForgeHUDScript = preload("res://games/roboforge-arena/ui/roboforge_hud.gd")
const RobotDataScript = preload("res://games/roboforge-arena/robot/robot_data.gd")
const OrbitCameraScript = preload("res://shared/cameras/orbit_camera.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

var workshop: Node3D
var challenge_manager: Node3D
var player_robot: CharacterBody3D
var camera: Node3D
var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

var is_in_workshop: bool = true
var active_blueprint: Dictionary = {}

func _ready() -> void:
	setup_game()

func setup_game() -> void:
	# 1. 3D Workshop Assembly Bay
	workshop = Workshop3DScript.new()
	workshop.name = "Workshop3D"
	add_child(workshop)

	# 2. Challenge Course Container
	challenge_manager = ChallengeManagerScript.new()
	challenge_manager.name = "ChallengeManager"
	add_child(challenge_manager)

	# 3. Active Player Robot
	player_robot = ModularRobotScript.new()
	player_robot.name = "PlayerRobot"
	player_robot.is_player_controlled = true
	add_child(player_robot)

	# 4. Orbit Camera
	camera = OrbitCameraScript.new()
	camera.name = "OrbitCamera"
	camera.set_target(player_robot)
	add_child(camera)

	# 5. UI & Menus
	hud = RoboForgeHUDScript.new()
	hud.name = "HUD"
	add_child(hud)

	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.restart_requested.connect(_on_restart)
	pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
	add_child(pause_menu)

	results_screen = ResultsScreenScript.new()
	results_screen.name = "ResultsScreen"
	results_screen.restart_pressed.connect(_on_restart)
	results_screen.launcher_pressed.connect(_on_quit_to_launcher)
	add_child(results_screen)

	active_blueprint = RobotDataScript.get_default_blueprint()
	player_robot.load_blueprint(active_blueprint)

	connect_signals()
	enter_workshop_mode()

func connect_signals() -> void:
	hud.chassis_selected.connect(func(ch_id: String):
		active_blueprint["chassis"] = ch_id
		_apply_blueprint()
	)
	hud.locomotion_selected.connect(func(loc_id: String):
		active_blueprint["locomotion"] = loc_id
		_apply_blueprint()
	)
	hud.module_toggled.connect(func(mod_id: String):
		workshop.toggle_module(mod_id)
		active_blueprint = workshop.active_blueprint
		_apply_blueprint()
	)
	hud.test_dyno_pressed.connect(func():
		launch_challenge("obstacle_course")
	)
	hud.challenge_selected.connect(func(ch_id: String):
		launch_challenge(ch_id)
	)

	player_robot.power_updated.connect(hud.update_power)

	challenge_manager.challenge_completed.connect(func(ch_id: String, time_taken: float, score: int):
		var sm = GameConstants.get_autoload(self, "SaveManager")
		if sm:
			sm.record_roboforge_challenge(ch_id, time_taken, true)

		results_screen.display_results(true, {
			"Challenge": ch_id.replace("_", " ").capitalize(),
			"Completion Time": "%.2f s" % time_taken,
			"Engineering Score": score,
			"Status": "QUALIFIED"
		})
	)

func _apply_blueprint() -> void:
	player_robot.load_blueprint(active_blueprint)
	var stats = RobotDataScript.calculate_stats(active_blueprint)
	hud.update_mass(stats.get("total_mass", 300.0))

func enter_workshop_mode() -> void:
	is_in_workshop = true
	workshop.visible = true
	challenge_manager.visible = false
	hud.set_workshop_visible(true)
	player_robot.global_position = Vector3(0, 0.5, 0)
	player_robot.velocity = Vector3.ZERO
	player_robot.forward_speed = 0.0

func launch_challenge(challenge_id: String) -> void:
	is_in_workshop = false
	workshop.visible = false
	challenge_manager.visible = true
	hud.set_workshop_visible(false)

	player_robot.global_position = Vector3(0, 0.8, 0)
	player_robot.velocity = Vector3.ZERO
	player_robot.forward_speed = 0.0

	challenge_manager.load_challenge(challenge_id, challenge_manager)
	hud.update_objective("Challenge: " + challenge_id.replace("_", " ").capitalize())

func _process(delta: float) -> void:
	if not is_in_workshop and challenge_manager:
		hud.update_time(challenge_manager.challenge_time)

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
