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
	# Persistent Arena WorldEnvironment & Atmospheric Lighting
	var world_env = WorldEnvironment.new()
	world_env.name = "RoboForgeWorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.12, 0.22, 0.38) # Industrial arena navy
	sky_mat.sky_horizon_color = Color(0.48, 0.58, 0.70)
	sky_mat.ground_bottom_color = Color(0.08, 0.10, 0.14)
	sky_mat.ground_horizon_color = Color(0.35, 0.42, 0.52)
	sky_mat.energy_multiplier = 1.2
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.95
	env.ambient_light_color = Color(0.45, 0.52, 0.65)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.10
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.15
	world_env.environment = env
	add_child(world_env)

	var dir_light = DirectionalLight3D.new()
	dir_light.name = "ArenaSunLight"
	dir_light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	dir_light.light_color = Color(1.0, 0.98, 0.92)
	dir_light.light_energy = 1.35
	dir_light.shadow_enabled = true
	dir_light.shadow_bias = 0.03
	add_child(dir_light)

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
	results_screen.next_stage_pressed.connect(_on_next_stage_requested)
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
		if sm and sm.has_method("record_roboforge_challenge"):
			sm.record_roboforge_challenge(ch_id, time_taken, true)

		results_screen.display_results(true, {
			"Challenge": ch_id.replace("_", " ").capitalize(),
			"Completion Time": "%.2f s" % time_taken,
			"Engineering Score": score,
			"Status": "QUALIFIED"
		}, "trophy_gold", "ENGINEERING TROPHY // UPGRADE UNLOCKED")
	)

func _on_next_stage_requested() -> void:
	results_screen.hide_results()
	var challenge_list = [
		"obstacle_course", "cargo_delivery", "energy_competition",
		"maze_escape", "physics_puzzle", "precision_platform", "machine_repair"
	]
	var cur_idx = challenge_list.find(challenge_manager.active_challenge_id)
	if cur_idx != -1 and cur_idx < challenge_list.size() - 1:
		launch_challenge(challenge_list[cur_idx + 1])
	else:
		enter_workshop_mode()

func _apply_blueprint() -> void:
	player_robot.load_blueprint(active_blueprint)
	var stats = RobotDataScript.calculate_stats(active_blueprint)
	hud.update_mass(stats.get("total_mass", 300.0))

func enter_workshop_mode() -> void:
	is_in_workshop = true
	workshop.visible = true
	challenge_manager.visible = false
	hud.set_workshop_visible(true)
	player_robot.visible = false
	player_robot.process_mode = Node.PROCESS_MODE_DISABLED
	player_robot.global_position = Vector3(0, 0.5, 0)
	player_robot.velocity = Vector3.ZERO
	player_robot.forward_speed = 0.0
	if workshop and workshop.get("turntable"):
		camera.set_target(workshop.turntable)

func start_challenge(challenge_id: String) -> void:
	launch_challenge(challenge_id)

func launch_challenge(challenge_id: String) -> void:
	is_in_workshop = false
	workshop.visible = false
	challenge_manager.visible = true
	hud.set_workshop_visible(false)

	player_robot.visible = true
	player_robot.process_mode = Node.PROCESS_MODE_INHERIT
	player_robot.global_position = Vector3(0, 0.8, 0)
	player_robot.velocity = Vector3.ZERO
	player_robot.forward_speed = 0.0
	camera.set_target(player_robot)

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
