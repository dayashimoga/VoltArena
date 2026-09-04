class_name SubwayMain
extends Node3D

const FPSPlayerScript = preload("res://games/arena-fps/player/fps_player.gd")
const WaveDirectorScript = preload("res://games/subway-survival/game/wave_director.gd")
const SubwayGenScript = preload("res://games/subway-survival/maps/subway_generator.gd")
const HUDBaseScript = preload("res://shared/ui/hud_base.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

var total_score: int = 0
var total_kills: int = 0
var highest_wave: int = 0
var is_game_active: bool = true

var player_node: Node3D
var wave_director: Node

var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

func _ready() -> void:
	setup_scene()
	connect_signals()

func setup_scene() -> void:
	# Subway environment
	var env = SubwayGenScript.new()
	env.name = "SubwayEnvironment"
	add_child(env)

	# UI systems
	if not hud:
		hud = HUDBaseScript.new()
		hud.name = "HUD"
		add_child(hud)

	if not pause_menu:
		pause_menu = PauseMenuScript.new()
		pause_menu.name = "PauseMenu"
		pause_menu.resume_requested.connect(_on_resume)
		pause_menu.restart_requested.connect(_on_restart)
		pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
		add_child(pause_menu)

	if not results_screen:
		results_screen = ResultsScreenScript.new()
		results_screen.name = "ResultsScreen"
		results_screen.restart_pressed.connect(_on_restart)
		results_screen.launcher_pressed.connect(_on_quit_to_launcher)
		add_child(results_screen)

	# Spawn Player on passenger platform
	player_node = FPSPlayerScript.new()
	player_node.name = "Player"
	player_node.position = Vector3(-5.0, 1.0, 0.0)
	add_child(player_node)

	# Wave Director
	wave_director = WaveDirectorScript.new()
	wave_director.name = "WaveDirector"
	add_child(wave_director)

func connect_signals() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.connect(_on_enemy_killed)
		bus.player_died.connect(_on_player_died)
		bus.wave_completed.connect(_on_wave_completed)

func _on_enemy_killed(_type: String, score_val: int) -> void:
	total_kills += 1
	total_score += score_val
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.score_updated.emit(0, total_score)

func _on_wave_completed(wave_num: int, bonus_score: int) -> void:
	highest_wave = wave_num
	total_score += bonus_score
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.score_updated.emit(0, total_score)

func _on_player_died(_killer: String) -> void:
	is_game_active = false
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_subway_run(highest_wave, total_kills, total_score)

	results_screen.display_results(false, {
		"Final Score": total_score,
		"Waves Survived": highest_wave,
		"Mutants Eliminated": total_kills,
		"Outcome": "Overrun by the Swarm"
	})

func _on_resume() -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	if is_instance_valid(player_node) and im:
		im.capture_mouse(true)

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
