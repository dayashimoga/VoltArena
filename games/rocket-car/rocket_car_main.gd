class_name RocketCarMain
extends Node3D

const CarControllerScript = preload("res://games/rocket-car/vehicle/car_controller.gd")
const CarAIScript = preload("res://games/rocket-car/ai/car_ai.gd")
const RocketBallScript = preload("res://games/rocket-car/ball/ball.gd")
const RocketArenaScript = preload("res://games/rocket-car/arena/rocket_arena.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

@export var match_duration: float = 300.0 # 5 minutes

var blue_score: int = 0
var orange_score: int = 0
var time_left: float = 300.0
var match_active: bool = true
var is_kickoff_pause: bool = false

var player_car: Node3D
var ai_cars: Array[Node3D] = []
var ball: Node3D
var camera: Camera3D

var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

func _ready() -> void:
	if not player_car:
		time_left = match_duration
		setup_scene()

func setup_scene() -> void:
	# Arena
	var arena = RocketArenaScript.new()
	arena.name = "RocketArena"
	arena.goal_triggered.connect(_on_goal_scored)
	add_child(arena)

	# UI
	if not hud:
		hud = HUDBaseScript.new()
		hud.name = "HUD"
		add_child(hud)
		hud.set_crosshair_spread(0.0) # Hide weapon crosshair for driving

	if not pause_menu:
		pause_menu = PauseMenuScript.new()
		pause_menu.name = "PauseMenu"
		pause_menu.resume_requested.connect(func(): pass)
		pause_menu.restart_requested.connect(_on_restart)
		pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
		add_child(pause_menu)

	if not results_screen:
		results_screen = ResultsScreenScript.new()
		results_screen.name = "ResultsScreen"
		results_screen.restart_pressed.connect(_on_restart)
		results_screen.launcher_pressed.connect(_on_quit_to_launcher)
		add_child(results_screen)

	# Ball
	ball = RocketBallScript.new()
	ball.name = "RocketBall"
	add_child(ball)

	# Player Car (Blue Team)
	player_car = CarControllerScript.new()
	player_car.name = "PlayerCar"
	player_car.team_id = 0
	player_car.is_player_controlled = true
	add_child(player_car)

	# Follow Camera
	camera = Camera3D.new()
	camera.name = "ChaseCamera"
	camera.current = true
	add_child(camera)

	# AI Opponents (Orange Team)
	var ai1 = CarControllerScript.new()
	ai1.name = "AI_Opponent_1"
	ai1.team_id = 1
	ai1.is_player_controlled = false
	add_child(ai1)

	var ai_brain1 = CarAIScript.new()
	ai_brain1.car = ai1
	ai_brain1.ball = ball
	ai_brain1.is_orange_team = true
	ai1.add_child(ai_brain1)
	ai_cars.append(ai1)

	var ai2 = CarControllerScript.new()
	ai2.name = "AI_Opponent_2"
	ai2.team_id = 1
	ai2.is_player_controlled = false
	add_child(ai2)

	var ai_brain2 = CarAIScript.new()
	ai_brain2.car = ai2
	ai_brain2.ball = ball
	ai_brain2.is_orange_team = true
	ai2.add_child(ai_brain2)
	ai_cars.append(ai2)

	reset_kickoff()

func _process(delta: float) -> void:
	if not match_active:
		return

	if not is_kickoff_pause:
		time_left -= delta
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.round_timer_updated.emit(max(0.0, time_left))

		if time_left <= 0.0:
			end_match()

	update_chase_camera(delta)

func update_chase_camera(delta: float) -> void:
	if not is_instance_valid(player_car) or not is_instance_valid(camera):
		return

	# Smooth third-person chase camera behind car
	var car_pos = player_car.global_position if player_car.is_inside_tree() else player_car.position
	var car_fwd = -player_car.global_transform.basis.z if player_car.is_inside_tree() else -player_car.transform.basis.z

	var target_cam_pos = car_pos - car_fwd * 7.5 + Vector3(0, 3.2, 0)
	if camera.is_inside_tree():
		camera.global_position = camera.global_position.lerp(target_cam_pos, delta * 8.0)
	else:
		camera.position = camera.position.lerp(target_cam_pos, delta * 8.0)

	# Look slightly above car towards ball or forward
	var look_target = car_pos + Vector3(0, 1.2, 0)
	if is_instance_valid(ball):
		var b_pos = ball.global_position if ball.is_inside_tree() else ball.position
		look_target = look_target.lerp(b_pos, 0.25)
	if camera.is_inside_tree():
		camera.look_at(look_target, Vector3.UP)
	else:
		camera.look_at_from_position(camera.position, look_target, Vector3.UP)

func reset_kickoff() -> void:
	is_kickoff_pause = true
	# Reset ball
	ball.reset_to_center()

	# Reset player car
	if is_instance_valid(player_car):
		player_car.global_position = Vector3(0, 0.5, 25.0)
		player_car.rotation = Vector3.ZERO
		player_car.velocity = Vector3.ZERO
		player_car.forward_speed = 0.0

	# Reset AI cars
	if ai_cars.size() >= 2:
		ai_cars[0].global_position = Vector3(-8.0, 0.5, -25.0)
		ai_cars[0].rotation = Vector3.ZERO
		ai_cars[0].velocity = Vector3.ZERO
		ai_cars[0].forward_speed = 0.0

		ai_cars[1].global_position = Vector3(8.0, 0.5, -25.0)
		ai_cars[1].rotation = Vector3.ZERO
		ai_cars[1].velocity = Vector3.ZERO
		ai_cars[1].forward_speed = 0.0

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("KICKOFF!", Color(0.0, 1.0, 1.0))

	# Unpause driving after short countdown
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(1.5).timeout.connect(func():
			is_kickoff_pause = false
		)

func _on_goal_scored(scoring_team: int) -> void:
	if not match_active or is_kickoff_pause:
		return

	var bus = GameConstants.get_autoload(self, "EventBus")
	if scoring_team == 0:
		blue_score += 1
		if bus:
			bus.show_toast_requested.emit("BLUE GOAL SCORED!", Color(0.0, 0.9, 1.0))
			bus.score_updated.emit(0, blue_score)
	else:
		orange_score += 1
		if bus:
			bus.show_toast_requested.emit("ORANGE GOAL SCORED!", Color(1.0, 0.45, 0.0))
			bus.score_updated.emit(1, orange_score)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("goal")

	reset_kickoff()

func end_match() -> void:
	match_active = false
	var won = blue_score > orange_score
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_rocket_match(blue_score, 0, won)

	results_screen.display_results(won, {
		"Blue Score": blue_score,
		"Orange Score": orange_score,
		"Result": "Match Finished"
	})

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
