class_name RocketCarMain
extends Node3D

const CarControllerScript = preload("res://games/rocket-car/vehicle/car_controller.gd")
const CarAIScript = preload("res://games/rocket-car/ai/car_ai.gd")
const RocketBallScript = preload("res://games/rocket-car/ball/ball.gd")
const RocketArenaScript = preload("res://games/rocket-car/arena/rocket_arena.gd")
const NitroKickHUDScript = preload("res://games/rocket-car/ui/nitro_kick_hud.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

@export var selected_theme: String = "day" # "day" (Volt Park) or "cyber" (Cyber Dome)
@export var match_duration: float = 300.0 # 5 minutes
@export var enable_overtime: bool = false
@export var game_mode: String = "2v2" # "1v1", "2v2", "3v3", "target_challenge"
@export var selected_vehicle: String = "speed_demon" # "speed_demon", "turbo_truck", "phantom"

var blue_score: int = 0
var orange_score: int = 0
var time_left: float = 300.0
var match_active: bool = true
var is_kickoff_pause: bool = false
var is_overtime: bool = false

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
	# Arena with selected stadium theme
	var arena = RocketArenaScript.new()
	arena.name = "RocketArena"
	arena.stadium_theme = selected_theme
	arena.goal_triggered.connect(_on_goal_scored)
	add_child(arena)

	# UI
	if not hud:
		hud = NitroKickHUDScript.new()
		hud.name = "HUD"
		add_child(hud)

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
	if hud and hud.has_method("update_boost"):
		player_car.boost_updated.connect(hud.update_boost)

	# Follow Camera
	camera = Camera3D.new()
	camera.name = "ChaseCamera"
	camera.current = true
	camera.global_position = Vector3(0, 4.0, 37.5)
	camera.look_at(Vector3(0, 1.2, 25.0), Vector3.UP)
	add_child(camera)
	if hud and hud.has_method("set_tracking_targets"):
		hud.set_tracking_targets(camera, ball)

	# Blue Team AI Teammates
	var b_ai1 = _create_ai_car("AI_Blue_1", 0, false)
	var b_ai2 = _create_ai_car("AI_Blue_2", 0, false)
	blue_ai_cars.append(b_ai1)
	blue_ai_cars.append(b_ai2)

	# Orange Team AI Opponents
	var o_ai1 = _create_ai_car("AI_Orange_1", 1, true)
	var o_ai2 = _create_ai_car("AI_Orange_2", 1, true)
	var o_ai3 = _create_ai_car("AI_Orange_3", 1, true)
	orange_ai_cars.append(o_ai1)
	orange_ai_cars.append(o_ai2)
	orange_ai_cars.append(o_ai3)

	# Maintain ai_cars array for backwards compatibility
	ai_cars.clear()
	ai_cars.append(o_ai1)
	ai_cars.append(o_ai2)
	ai_cars.append(o_ai3)
	ai_cars.append(b_ai1)
	ai_cars.append(b_ai2)

	select_game_mode(game_mode)
	reset_kickoff()

func _create_ai_car(car_name: String, team: int, is_orange: bool) -> Node3D:
	var car_node = CarControllerScript.new()
	car_node.name = car_name
	car_node.team_id = team
	car_node.is_player_controlled = false
	add_child(car_node)

	var ai_brain = CarAIScript.new()
	ai_brain.car = car_node
	ai_brain.ball = ball
	ai_brain.is_orange_team = is_orange
	car_node.add_child(ai_brain)
	return car_node

var blue_ai_cars: Array[Node3D] = []
var orange_ai_cars: Array[Node3D] = []

func _process(delta: float) -> void:
	if not match_active:
		return

	if not is_kickoff_pause:
		time_left -= delta
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.round_timer_updated.emit(max(0.0, time_left))

		if time_left <= 0.0:
			if enable_overtime and blue_score == orange_score:
				if not is_overtime:
					is_overtime = true
					if bus:
						bus.show_toast_requested.emit("OVERTIME! NEXT GOAL WINS!", Color(1.0, 0.85, 0.1))
					var am = GameConstants.get_autoload(self, "AudioManager")
					if am:
						am.play_sound("referee_whistle", 1.0, 2.0)
			else:
				end_match()

	update_chase_camera(delta)

var camera_override: bool = false

func update_chase_camera(delta: float) -> void:
	if camera_override:
		return
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

	# Positions depending on game mode
	if game_mode == "1v1":
		if is_instance_valid(player_car):
			_place_car(player_car, Vector3(0.0, 0.5, 30.0), 0.0)
		if orange_ai_cars.size() > 0 and is_instance_valid(orange_ai_cars[0]):
			_place_car(orange_ai_cars[0], Vector3(0.0, 0.5, -30.0), PI)
	elif game_mode == "2v2":
		if is_instance_valid(player_car):
			_place_car(player_car, Vector3(-10.0, 0.5, 30.0), 0.0)
		if blue_ai_cars.size() > 0 and is_instance_valid(blue_ai_cars[0]):
			_place_car(blue_ai_cars[0], Vector3(10.0, 0.5, 30.0), 0.0)
		if orange_ai_cars.size() > 1:
			_place_car(orange_ai_cars[0], Vector3(-10.0, 0.5, -30.0), PI)
			_place_car(orange_ai_cars[1], Vector3(10.0, 0.5, -30.0), PI)
	elif game_mode == "3v3":
		if is_instance_valid(player_car):
			_place_car(player_car, Vector3(0.0, 0.5, 34.0), 0.0)
		if blue_ai_cars.size() > 1:
			_place_car(blue_ai_cars[0], Vector3(-14.0, 0.5, 26.0), 0.0)
			_place_car(blue_ai_cars[1], Vector3(14.0, 0.5, 26.0), 0.0)
		if orange_ai_cars.size() > 2:
			_place_car(orange_ai_cars[0], Vector3(0.0, 0.5, -34.0), PI)
			_place_car(orange_ai_cars[1], Vector3(-14.0, 0.5, -26.0), PI)
			_place_car(orange_ai_cars[2], Vector3(14.0, 0.5, -26.0), PI)
	else:
		# Target challenge or solo practice
		if is_instance_valid(player_car):
			_place_car(player_car, Vector3(0.0, 0.5, 30.0), 0.0)

	# Sequential 3-2-1-GO Kickoff countdown
	var am = GameConstants.get_autoload(self, "AudioManager")
	if hud and hud.has_method("show_kickoff_countdown"):
		hud.show_kickoff_countdown(3)
	if am:
		am.play_sound("referee_whistle", 0.9, 1.0)

	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(1.0).timeout.connect(func():
			if hud and hud.has_method("show_kickoff_countdown"):
				hud.show_kickoff_countdown(2)
			if am: am.play_sound("referee_whistle", 0.9, 1.0)
		)
		tree.create_timer(2.0).timeout.connect(func():
			if hud and hud.has_method("show_kickoff_countdown"):
				hud.show_kickoff_countdown(1)
			if am: am.play_sound("referee_whistle", 0.9, 1.0)
		)
		tree.create_timer(3.0).timeout.connect(func():
			if hud and hud.has_method("show_kickoff_countdown"):
				hud.show_kickoff_countdown(0)
			if hud and hud.has_method("dismiss_onboarding"):
				hud.dismiss_onboarding()
			if am: am.play_sound("referee_whistle", 1.2, 1.6)
			is_kickoff_pause = false
		)

func _place_car(car_node: Node3D, pos: Vector3, y_rot: float) -> void:
	if not is_instance_valid(car_node):
		return
	car_node.global_position = pos
	car_node.rotation = Vector3(0, y_rot, 0)
	if "velocity" in car_node:
		car_node.velocity = Vector3.ZERO
	if "forward_speed" in car_node:
		car_node.forward_speed = 0.0


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
		am.play_sound("goal_horn", 1.0, 2.5)

	if hud and hud.has_method("show_goal_celebration"):
		hud.show_goal_celebration(scoring_team, 88.0)

	if is_overtime or blue_score >= 3 or orange_score >= 3:
		end_match()
		return

	reset_kickoff()

func end_match() -> void:
	match_active = false
	var won = blue_score > orange_score
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_rocket_match(blue_score, 0, won)

	var outcome = "VICTORY!" if won else "DEFEAT"
	if is_overtime:
		outcome += " (Overtime Sudden Death)"

	results_screen.display_results(won, {
		"Blue Score": blue_score,
		"Orange Score": orange_score,
		"Status": outcome,
		"Arena": "Volt Park Arena" if selected_theme == "day" else "Cyber Dome"
	})

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()

func select_game_mode(mode: String) -> void:
	game_mode = mode
	for b in blue_ai_cars:
		if is_instance_valid(b):
			b.visible = false
			b.process_mode = Node.PROCESS_MODE_DISABLED
	for o in orange_ai_cars:
		if is_instance_valid(o):
			o.visible = false
			o.process_mode = Node.PROCESS_MODE_DISABLED

	match mode:
		"1v1":
			if orange_ai_cars.size() > 0 and is_instance_valid(orange_ai_cars[0]):
				orange_ai_cars[0].visible = true
				orange_ai_cars[0].process_mode = Node.PROCESS_MODE_INHERIT
		"2v2":
			if blue_ai_cars.size() > 0 and is_instance_valid(blue_ai_cars[0]):
				blue_ai_cars[0].visible = true
				blue_ai_cars[0].process_mode = Node.PROCESS_MODE_INHERIT
			for i in range(mini(2, orange_ai_cars.size())):
				if is_instance_valid(orange_ai_cars[i]):
					orange_ai_cars[i].visible = true
					orange_ai_cars[i].process_mode = Node.PROCESS_MODE_INHERIT
		"3v3":
			for b in blue_ai_cars:
				if is_instance_valid(b):
					b.visible = true
					b.process_mode = Node.PROCESS_MODE_INHERIT
			for o in orange_ai_cars:
				if is_instance_valid(o):
					o.visible = true
					o.process_mode = Node.PROCESS_MODE_INHERIT
		"target_challenge":
			time_left = 120.0 # 2 minute time attack challenge


func select_car_vehicle(vehicle_id: String) -> void:
	selected_vehicle = vehicle_id
	if is_instance_valid(player_car) and player_car is CarController:
		match vehicle_id:
			"speed_demon":
				player_car.max_speed = 28.0
				player_car.boost_speed = 42.0
			"turbo_truck":
				player_car.max_boost = 150.0
				player_car.boost_recharge_rate = 14.0
			"phantom":
				player_car.jump_impulse = 13.5
				player_car.steer_speed = 3.2

func get_available_modes() -> Array[String]:
	return ["1v1", "2v2", "3v3", "target_challenge"]

func get_available_cars() -> Array[String]:
	return ["speed_demon", "turbo_truck", "phantom"]
