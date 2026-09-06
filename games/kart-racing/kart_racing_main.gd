class_name KartRacingMain
extends Node3D

const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")
const KartAIScript = preload("res://games/kart-racing/ai/kart_ai.gd")
const TrackGeneratorScript = preload("res://games/kart-racing/tracks/track_generator.gd")
const RaceManagerScript = preload("res://games/kart-racing/game/race_manager.gd")
const DriftStormHUDScript = preload("res://games/kart-racing/ui/drift_storm_hud.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

@export var selected_track: String = "metropolis" # "metropolis", "canyon", "frozen"
@export var selected_kart: String = "speeder" # "speeder", "phantom", "enforcer"
@export var ai_racer_count: int = 3

var player_kart: Node3D
var ai_karts: Array[Node3D] = []
var all_karts: Array[Node3D] = []
var camera: Camera3D

var race_manager: Node
var track_generator: Node

var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

func _ready() -> void:
	setup_scene()

func setup_scene() -> void:
	# UI
	if not hud:
		hud = DriftStormHUDScript.new()
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

	# Race Manager
	race_manager = RaceManagerScript.new()
	race_manager.name = "RaceManager"
	race_manager.race_finished.connect(_on_race_finished)
	add_child(race_manager)

	# Player Kart
	player_kart = KartControllerScript.new()
	player_kart.name = "PlayerKart"
	player_kart.is_player = true
	player_kart.kart_type = selected_kart
	player_kart.racer_name = "Player 1"
	player_kart.position = Vector3(-3.0, 0.5, 0.0)
	add_child(player_kart)
	all_karts.append(player_kart)

	# Camera
	camera = Camera3D.new()
	camera.name = "KartCamera"
	camera.current = true
	camera.global_position = Vector3(0.0, 3.3, 11.5)
	camera.look_at(Vector3(0.0, 1.0, 5.0), Vector3.UP)
	add_child(camera)

	# 4 Competitive AI Racers
	var grid_slots = [
		Vector3(3.0, 0.5, 0.0),
		Vector3(-3.0, 0.5, 5.0),
		Vector3(3.0, 0.5, 5.0),
		Vector3(-3.0, 0.5, 10.0)
	]
	var ai_names = ["Apex Nova", "Blaze Raptor", "Viper Strike", "Turbo Titan"]
	var ai_types = ["speeder", "phantom", "enforcer", "speeder"]
	for i in range(min(ai_racer_count, grid_slots.size())):
		var ai_kart = KartControllerScript.new()
		ai_kart.name = "AI_Racer_" + str(i + 1)
		ai_kart.racer_id = i + 1
		ai_kart.racer_name = ai_names[i]
		ai_kart.kart_type = ai_types[i]
		ai_kart.is_player = false
		ai_kart.position = grid_slots[i]
		add_child(ai_kart)

		var ai_brain = KartAIScript.new()
		ai_brain.kart = ai_kart
		ai_kart.add_child(ai_brain)

		ai_karts.append(ai_kart)
		all_karts.append(ai_kart)

	# Track Generator
	track_generator = TrackGeneratorScript.new()
	track_generator.name = "TrackGenerator"
	track_generator.track_theme = selected_track
	track_generator.track_built.connect(_on_track_built)
	add_child(track_generator)

func _on_track_built(waypoints: Array, checkpoints: Array) -> void:
	# Provide waypoints to AI
	for ai_kart in ai_karts:
		var brain = ai_kart.get_node_or_null("KartAI")
		if brain:
			brain.waypoints = waypoints

	# Initialize race manager with participants and checkpoints
	race_manager.initialize_race(all_karts, checkpoints)

	# Starting lights countdown sequence
	if hud and hud.has_method("show_countdown"):
		hud.show_countdown("3")

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("countdown_tick", 1.0)

	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(1.0).timeout.connect(func():
			if hud and hud.has_method("show_countdown"):
				hud.show_countdown("2")
			if am: am.play_sound("countdown_tick", 1.0)
		)
		tree.create_timer(2.0).timeout.connect(func():
			if hud and hud.has_method("show_countdown"):
				hud.show_countdown("1")
			if am: am.play_sound("countdown_tick", 1.0)
		)
		tree.create_timer(3.0).timeout.connect(func():
			if hud and hud.has_method("show_countdown"):
				hud.show_countdown("GO!")
			if hud and hud.has_method("dismiss_onboarding"):
				hud.dismiss_onboarding()
			if am: am.play_sound("countdown_go", 1.2)
		)

func _process(delta: float) -> void:
	update_camera(delta)
	if hud and is_instance_valid(player_kart):
		if hud.has_method("update_speed"):
			hud.update_speed(player_kart.forward_speed)
		if hud.has_method("update_lap"):
			hud.update_lap(player_kart.current_lap, 3)
		if hud.has_method("update_drift_charge"):
			var tier = 0
			if player_kart.drift_charge_time > 2.5:
				tier = 3
			elif player_kart.drift_charge_time > 1.5:
				tier = 2
			elif player_kart.drift_charge_time > 0.8:
				tier = 1
			hud.update_drift_charge(player_kart.drift_charge_time, tier)

var camera_override: bool = false

func update_camera(delta: float) -> void:
	if camera_override:
		return
	if not is_instance_valid(player_kart) or not is_instance_valid(camera):
		return

	var k_pos = player_kart.global_position if player_kart.is_inside_tree() else player_kart.position
	var k_fwd = -player_kart.global_transform.basis.z if player_kart.is_inside_tree() else -player_kart.transform.basis.z

	var target_cam = k_pos - k_fwd * 6.5 + Vector3(0, 2.8, 0)
	if camera.is_inside_tree():
		camera.global_position = camera.global_position.lerp(target_cam, delta * 10.0)
		camera.look_at(k_pos + Vector3(0, 1.0, 0), Vector3.UP)
	else:
		camera.position = camera.position.lerp(target_cam, delta * 10.0)
		camera.look_at_from_position(camera.position, k_pos + Vector3(0, 1.0, 0), Vector3.UP)

func _on_race_finished(winner: Node) -> void:
	var won = (winner == player_kart)
	var best_lap = player_kart.best_lap_time
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_kart_race("canyon", best_lap, won)

	results_screen.display_results(won, {
		"Position": "1st Place (WINNER!)" if won else "Finished",
		"Total Time": "%.2fs" % race_manager.race_time,
		"Best Lap": "%.2fs" % best_lap if best_lap < 900.0 else "N/A"
	})

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()

func select_track(track_name: String) -> void:
	selected_track = track_name
	if track_generator and is_instance_valid(track_generator):
		track_generator.track_theme = selected_track
		track_generator.waypoints.clear()
		track_generator.checkpoints.clear()
		for child in track_generator.get_children():
			child.queue_free()
		track_generator.build_circuit()

func select_kart(kart_name: String) -> void:
	selected_kart = kart_name
	if player_kart and is_instance_valid(player_kart) and player_kart.has_method("set_kart_type"):
		player_kart.set_kart_type(selected_kart)
