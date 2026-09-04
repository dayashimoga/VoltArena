class_name ArenaFPSMain
extends Node3D

@export var match_duration_seconds: float = 300.0 # 5 minutes
@export var target_kills_to_win: int = 20

var player_score: int = 0
var bot_score: int = 0
var time_remaining: float = 300.0
var match_active: bool = true

var player_node: FPSPlayer
var bots: Array[ArenaBot] = []

var hud: HUDBase
var pause_menu: PauseMenu
var results_screen: ResultsScreen

func _ready() -> void:
	time_remaining = match_duration_seconds
	setup_scene()
	connect_events()

func setup_scene() -> void:
	# Map
	var map = ArenaMapGenerator.new()
	map.name = "ArenaMap"
	add_child(map)

	# UI
	if not hud:
		hud = HUDBase.new()
		hud.name = "HUD"
		add_child(hud)

	if not pause_menu:
		pause_menu = PauseMenu.new()
		pause_menu.name = "PauseMenu"
		pause_menu.resume_requested.connect(_on_resume)
		pause_menu.restart_requested.connect(_on_restart)
		pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
		add_child(pause_menu)

	if not results_screen:
		results_screen = ResultsScreen.new()
		results_screen.name = "ResultsScreen"
		results_screen.restart_pressed.connect(_on_restart)
		results_screen.launcher_pressed.connect(_on_quit_to_launcher)
		add_child(results_screen)

	# Spawn Player
	player_node = FPSPlayer.new()
	player_node.name = "Player"
	player_node.position = Vector3(0, 1.0, 25.0)
	add_child(player_node)
	player_node.setup_default_nodes()
	player_node.setup_weapons()
	player_node.connect_health()

	# Spawn Bots
	var spawn_points = [
		Vector3(-20, 1.0, -20),
		Vector3(20, 1.0, -20),
		Vector3(0, 1.0, -25)
	]
	for i in range(spawn_points.size()):
		var bot = ArenaBot.new()
		bot.name = "Bot_" + str(i + 1)
		bot.bot_name = "CyberUnit " + str(i + 1)
		bot.position = spawn_points[i]
		add_child(bot)
		bot.setup_bot_visual()
		bot.setup_health()
		bot.setup_weapon()
		bots.append(bot)

func connect_events() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.connect(_on_enemy_killed)
		bus.player_died.connect(_on_player_died)

func _process(delta: float) -> void:
	if not match_active:
		return

	time_remaining -= delta
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.round_timer_updated.emit(max(0.0, time_remaining))

	if time_remaining <= 0.0:
		end_match()

func _on_enemy_killed(_type: String, score_val: int) -> void:
	player_score += score_val
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.score_updated.emit(0, player_score)
		bus.show_toast_requested.emit("ELIMINATION! +%d PTS" % score_val, Color(0.0, 1.0, 0.5))

	if player_score >= target_kills_to_win * 100:
		end_match()

func _on_player_died(_killer: String) -> void:
	bot_score += 100
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("YOU WERE ELIMINATED! RESPAWNING...", Color(1.0, 0.2, 0.2))

	# Respawn player after 2.5s
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(2.5).timeout.connect(func():
			if is_instance_valid(player_node):
				player_node.position = Vector3(randf_range(-15, 15), 1.0, 25.0)
				player_node.health_component.reset()
		)

func end_match() -> void:
	match_active = false
	var won = player_score > bot_score
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_arena_match(player_score / 100, bot_score / 100, player_score, won)

	results_screen.display_results(won, {
		"Player Score": player_score,
		"Enemy Score": bot_score,
		"Eliminations": player_score / 100,
		"Deaths": bot_score / 100,
		"Time Remaining": "%ds" % int(time_remaining)
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
