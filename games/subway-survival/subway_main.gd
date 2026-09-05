class_name SubwayMain
extends Node3D

const FPSPlayerScript = preload("res://games/arena-fps/player/fps_player.gd")
const WaveDirectorScript = preload("res://games/subway-survival/game/wave_director.gd")
const SubwayGenScript = preload("res://games/subway-survival/maps/subway_generator.gd")
const MetroSiegeHUDScript = preload("res://games/subway-survival/ui/metro_siege_hud.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

var total_score: int = 0
var total_kills: int = 0
var highest_wave: int = 0
var total_scrap: int = 0
var is_game_active: bool = true

var player_node: Node3D
var wave_director: Node

var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

func _ready() -> void:
	setup_scene()
	connect_signals()
	if wave_director and wave_director.has_method("start_next_wave"):
		wave_director.start_next_wave()

func setup_scene() -> void:
	# Subway environment
	var env = SubwayGenScript.new()
	env.name = "SubwayEnvironment"
	add_child(env)

	# UI systems
	if not hud:
		hud = MetroSiegeHUDScript.new()
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
	if wave_director and wave_director.has_signal("all_waves_defeated"):
		wave_director.all_waves_defeated.connect(_on_all_waves_defeated)

func _on_enemy_killed(_type: String, score_val: int) -> void:
	total_kills += 1
	total_score += score_val
	total_scrap += int(score_val * 0.5)
	if hud and hud.has_method("update_scrap"):
		hud.update_scrap(total_scrap)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.score_updated.emit(0, total_score)

func _on_wave_completed(wave_num: int, bonus_score: int) -> void:
	highest_wave = wave_num
	total_score += bonus_score
	total_scrap += 50
	if hud and hud.has_method("update_wave"):
		hud.update_wave(wave_num + 1)
	if hud and hud.has_method("update_scrap"):
		hud.update_scrap(total_scrap)
	if hud and hud.get("objective_badge"):
		var obj_text = "OBJECTIVE: SURVIVE WAVE %d & DEFEND PLATFORM" % (wave_num + 1)
		match wave_num + 1:
			2: obj_text = "OBJECTIVE: REPEL CONCOURSE SWARM"
			3: obj_text = "OBJECTIVE: BREACH TUNNEL BULKHEAD"
			4: obj_text = "OBJECTIVE: RESTORE AUXILIARY GENERATOR"
			5: obj_text = "OBJECTIVE: ELIMINATE ENRAGED BRUTES"
			6: obj_text = "OBJECTIVE: RETRIEVE TRAIN ACCESS KEY"
			7: obj_text = "OBJECTIVE: BREACH PUMP HIVE CHAMBER"
			8: obj_text = "OBJECTIVE: DEFEND EXTRACTION CORRIDOR"
			9: obj_text = "OBJECTIVE: REPEL APEX SWARM"
			10: obj_text = "OBJECTIVE: DEFEAT BIO-COLOSSUS & EXTRACT VIA TRAIN"
		hud.objective_badge.text = obj_text

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.score_updated.emit(0, total_score)

	var env = get_node_or_null("SubwayEnvironment")
	if env:
		if wave_num == 3:
			env.unlock_gate(2)
			if bus:
				bus.show_toast_requested.emit("ZONE 2 UNLOCKED: TRAIN TUNNELS CLEARED!", Color(0.2, 1.0, 0.4))
		elif wave_num == 7:
			env.unlock_gate(3)
			if bus:
				bus.show_toast_requested.emit("ZONE 3 UNLOCKED: PUMP HIVE ACCESSIBLE!", Color(1.0, 0.8, 0.1))

	if wave_num >= 10:
		_on_all_waves_defeated()

func _on_all_waves_defeated() -> void:
	is_game_active = false
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_subway_run(highest_wave, total_kills, total_score)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("BIO-COLOSSUS DESTROYED! EXTRACTION SUCCESSFUL!", Color(0.0, 1.0, 0.8))

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("goal_horn", 1.0, 2.0)

	results_screen.display_results(true, {
		"Final Score": total_score,
		"Waves Survived": highest_wave,
		"Mutants Eliminated": total_kills,
		"Scrap Salvaged": total_scrap,
		"Outcome": "EXTRACTION SUCCESSFUL"
	})

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
