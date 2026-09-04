class_name KartRacingMain
extends Node3D

const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")
const KartAIScript = preload("res://games/kart-racing/ai/kart_ai.gd")
const TrackGeneratorScript = preload("res://games/kart-racing/tracks/track_generator.gd")
const RaceManagerScript = preload("res://games/kart-racing/game/race_manager.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

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
		hud = HUDBaseScript.new()
		hud.name = "HUD"
		add_child(hud)
		hud.set_crosshair_spread(0.0)

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
	player_kart.racer_name = "Player 1"
	player_kart.position = Vector3(-3.0, 0.5, 0.0)
	add_child(player_kart)
	all_karts.append(player_kart)

	# Camera
	camera = Camera3D.new()
	camera.name = "KartCamera"
	camera.current = true
	add_child(camera)

	# 3 AI Racers
	var grid_slots = [
		Vector3(3.0, 0.5, 0.0),
		Vector3(-3.0, 0.5, 5.0),
		Vector3(3.0, 0.5, 5.0)
	]
	for i in range(grid_slots.size()):
		var ai_kart = KartControllerScript.new()
		ai_kart.name = "AI_Racer_" + str(i + 1)
		ai_kart.racer_id = i + 1
		ai_kart.racer_name = "Racer " + str(i + 1)
		ai_kart.is_player = false
		ai_kart.position = grid_slots[i]
		add_child(ai_kart)

		var ai_brain = KartAIScript.new()
		ai_brain.kart = ai_kart
		ai_kart.add_child(ai_brain)

		ai_karts.append(ai_kart)
		all_karts.append(ai_kart)

	# Track Generator (built after racers & race manager are initialized)
	track_generator = TrackGeneratorScript.new()
	track_generator.name = "TrackGenerator"
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

func _process(delta: float) -> void:
	update_camera(delta)

func update_camera(delta: float) -> void:
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
