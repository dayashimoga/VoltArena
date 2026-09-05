extends Node

const STATE_INITIALIZING: int = 0
const STATE_LOADING: int = 1
const STATE_MENU: int = 2
const STATE_PLAYING: int = 4

var current_state: int = STATE_INITIALIZING
var active_game_id: String = ""
var active_game_instance: Node = null

var event_bus: Node:
	get:
		return GameConstants.get_autoload(self, "EventBus")

var asset_loader: Node:
	get:
		return GameConstants.get_autoload(self, "AssetLoader")

var _web_bridge_launch = null
var _web_bridge_return = null
var _web_bridge_exec = null

func _ready() -> void:
	if event_bus:
		event_bus.game_selected.connect(start_game)
		event_bus.return_to_launcher_requested.connect(return_to_launcher)
		event_bus.game_restart_requested.connect(restart_current_game)

	if OS.has_feature("web"):
		_setup_web_bridge()

	_check_cmdline_args()

func _setup_web_bridge() -> void:
	_web_bridge_launch = JavaScriptBridge.create_callback(func(args):
		if args.size() > 0:
			var gid = str(args[0])
			start_game(gid)
	)
	_web_bridge_return = JavaScriptBridge.create_callback(func(_args):
		return_to_launcher()
	)
	_web_bridge_exec = JavaScriptBridge.create_callback(func(args):
		if args.size() > 0:
			var cmd = str(args[0])
			handle_exec_cmd(cmd)
	)
	var win = JavaScriptBridge.get_interface("window")
	if win:
		win._godotLaunchGame = _web_bridge_launch
		win._godotReturnToLauncher = _web_bridge_return
		win._godotExec = _web_bridge_exec
		JavaScriptBridge.eval("""
			window.godotLaunchGame = function(id) {
				if (window._godotLaunchGame) window._godotLaunchGame(id);
			};
			window.godotReturnToLauncher = function() {
				if (window._godotReturnToLauncher) window._godotReturnToLauncher();
			};
			window.godotExec = function(cmd) {
				if (window._godotExec) window._godotExec(cmd);
			};
		""")

func handle_exec_cmd(cmd: String) -> void:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if not tree or not tree.current_scene:
		return
	var scene = tree.current_scene

	if cmd == "dismiss_onboarding":
		var hud = scene.get_node_or_null("HUD")
		if hud and hud.has_method("dismiss_onboarding"):
			hud.dismiss_onboarding()
		return

	match active_game_id:
		"arena_fps":
			_handle_arena_fps_cmd(scene, cmd)
		"subway_survival":
			_handle_subway_cmd(scene, cmd)
		"rocket_car":
			_handle_rocket_car_cmd(scene, cmd)
		"kart_racing":
			_handle_kart_cmd(scene, cmd)

func _handle_arena_fps_cmd(scene: Node, cmd: String) -> void:
	var player = scene.get_node_or_null("Player")
	var hud = scene.get_node_or_null("HUD")
	var results = scene.get_node_or_null("ResultsScreen")

	if cmd.begins_with("weapon_"):
		var idx = cmd.substr(7).to_int()
		if player and player.has_method("select_weapon"):
			player.select_weapon(idx)
		if hud and hud.has_method("highlight_active_weapon"):
			hud.highlight_active_weapon(idx)
	elif cmd == "objective":
		if hud and hud.has_method("update_objective"):
			hud.update_objective(0, 0, 20)
	elif cmd == "cam_character":
		var cam = scene.find_child("Camera3D", true, false)
		if cam and player:
			cam.top_level = true
			cam.global_position = player.global_position + Vector3(0.8, 0.4, -2.4)
			cam.look_at(player.global_position + Vector3(0, 0.2, 0), Vector3.UP)
	elif cmd == "cam_first_person":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = false
			cam.position = Vector3(0, 0.6, 0)
			cam.rotation = Vector3.ZERO
	elif cmd == "cam_pickup":
		var cam = scene.find_child("Camera3D", true, false)
		var pickups = scene.get_tree().get_nodes_in_group("pickups")
		if cam and not pickups.is_empty():
			cam.top_level = true
			cam.global_position = pickups[0].global_position + Vector3(1.2, 0.8, 1.8)
			cam.look_at(pickups[0].global_position, Vector3.UP)
		elif cam:
			cam.top_level = true
			cam.global_position = Vector3(0, 4.4, 2.5)
			cam.look_at(Vector3(0, 3.6, 0), Vector3.UP)
	elif cmd == "active_combat":
		if player and player.has_method("fire_weapon"):
			player.fire_weapon()
			var bots = scene.get("bots")
			if bots and not bots.is_empty() and is_instance_valid(bots[0]):
				bots[0].global_position = player.global_position - player.global_transform.basis.z * 7.0
				bots[0].take_damage(25.0, "You", "Pulse Rifle")
	elif cmd == "frag_progression":
		if hud:
			hud.update_objective(15, 8, 20)
			hud.update_frags(15, 20)
			hud.add_killfeed_entry("You", "Assault Titan", "Scatter Cannon")
	elif cmd == "show_results":
		if results and results.has_method("display_results"):
			results.display_results(true, {"Match": "TDM 20 Frags", "Frags": "20 / 20", "Accuracy": "78%", "Result": "VICTORY"})

func _handle_subway_cmd(scene: Node, cmd: String) -> void:
	var player = scene.get_node_or_null("Player")
	var hud = scene.get_node_or_null("HUD")
	var results = scene.get_node_or_null("ResultsScreen")

	if cmd == "cam_train":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(1.5, 1.2, 4.5)
			cam.look_at(Vector3(6.5, 0.0, 0.0), Vector3.UP)
	elif cmd == "cam_crawlers":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(0.0, 2.5, 12.0)
			cam.look_at(Vector3(0.0, 0.0, 18.0), Vector3.UP)
	elif cmd == "cam_spitter":
		var enemies = scene.get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if "Spitter" in e.name or e.get("enemy_type") == "spitter":
				var cam = scene.find_child("Camera3D", true, false)
				if cam:
					cam.top_level = true
					cam.global_position = e.global_position + Vector3(0.8, 0.6, 2.4)
					cam.look_at(e.global_position + Vector3(0, 0.3, 0), Vector3.UP)
				break
	elif cmd == "cam_brute":
		var enemies = scene.get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if "Brute" in e.name or e.get("enemy_type") == "brute":
				var cam = scene.find_child("Camera3D", true, false)
				if cam:
					cam.top_level = true
					cam.global_position = e.global_position + Vector3(1.2, 0.8, 3.2)
					cam.look_at(e.global_position + Vector3(0, 0.6, 0), Vector3.UP)
				break
	elif cmd == "cam_boss":
		var boss = BioColossus.new()
		boss.name = "BioColossus_Boss"
		boss.position = Vector3(0.0, 0.0, 10.0)
		scene.add_child(boss)
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(2.5, 1.8, 3.5)
			cam.look_at(boss.global_position + Vector3(0, 1.5, 0), Vector3.UP)
	elif cmd == "cam_kiosk":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(-7.5, 1.2, -1.5)
			cam.look_at(Vector3(-10.5, 0.8, -4.0), Vector3.UP)
	elif cmd == "scrap_gears":
		if player:
			for k in range(4):
				var sc = ScrapPickup.new()
				sc.position = player.global_position + Vector3(sin(k * 1.5) * 2.0, 0.5, cos(k * 1.5) * 2.0)
				scene.add_child(sc)
	elif cmd == "wave_escalation":
		if hud:
			if hud.has_method("update_wave"):
				hud.update_wave(7, 10)
			if hud.has_method("update_threats"):
				hud.update_threats(14)
	elif cmd == "active_combat":
		if player and player.has_method("fire_weapon"):
			player.fire_weapon()
	elif cmd == "show_results":
		if results and results.has_method("display_results"):
			results.display_results(true, {"Waves": "10 / 10 Complete", "Boss Defeated": "BioColossus", "Scrap": "1,450", "Status": "EVACUATED"})

func _handle_rocket_car_cmd(scene: Node, cmd: String) -> void:
	var results = scene.get_node_or_null("ResultsScreen")
	var hud = scene.get_node_or_null("HUD")
	var p_list = scene.get_tree().get_nodes_in_group("players")
	var player = p_list[0] if not p_list.is_empty() else null

	if cmd == "cam_car_closeup":
		var cam = scene.find_child("Camera3D", true, false)
		if cam and player:
			cam.top_level = true
			cam.global_position = player.global_position + Vector3(1.2, 0.8, -3.2)
			cam.look_at(player.global_position + Vector3(0, 0.3, 0), Vector3.UP)
	elif cmd == "cam_stadium":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(0, 24.0, -35.0)
			cam.look_at(Vector3(0, 0, 10.0), Vector3.UP)
	elif cmd == "cam_goal_objective":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(0, 3.5, 20.0)
			cam.look_at(Vector3(0, 4.0, 53.0), Vector3.UP)
	elif cmd == "cam_ball":
		var ball = scene.get_node_or_null("Ball")
		var cam = scene.find_child("Camera3D", true, false)
		if cam and ball:
			cam.top_level = true
			cam.global_position = ball.global_position + Vector3(2.5, 1.8, 3.5)
			cam.look_at(ball.global_position, Vector3.UP)
	elif cmd == "cam_ai_chase":
		var cam = scene.find_child("Camera3D", true, false)
		var ai_cars = scene.get_tree().get_nodes_in_group("ai_cars")
		if cam and not ai_cars.is_empty():
			var ai = ai_cars[0]
			cam.top_level = true
			cam.global_position = ai.global_position + Vector3(1.2, 1.0, -3.5)
			cam.look_at(ai.global_position + Vector3(0, 0.5, 2.0), Vector3.UP)
	elif cmd == "cam_boost_pad":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(18.0, 1.5, 12.0)
			cam.look_at(Vector3(20.0, 0.2, 10.0), Vector3.UP)
	elif cmd == "boost_aerial":
		if player and player is RigidBody3D:
			player.linear_velocity.y = 8.0
			player.is_boosting = true
	elif cmd == "goal_attack":
		var ball = scene.get_node_or_null("Ball")
		var cam = scene.find_child("Camera3D", true, false)
		if ball:
			ball.global_position = Vector3(2.0, 3.5, 42.0)
			if ball is RigidBody3D:
				ball.linear_velocity = Vector3(0, 2.0, 15.0)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(0, 4.0, 30.0)
			cam.look_at(Vector3(0, 4.0, 53.0), Vector3.UP)
	elif cmd == "score_goal":
		var ball = scene.get_node_or_null("Ball")
		if ball:
			ball.global_position = Vector3(0, 2.0, 53.0)
	elif cmd == "match_progression":
		if hud:
			if hud.has_method("update_score"):
				hud.update_score(3, 1)
			if hud.has_method("update_time"):
				hud.update_time(105.0)
	elif cmd == "show_results":
		if results and results.has_method("display_results"):
			results.display_results(true, {"Final Score": "Blue 3 - 1 Orange", "Goals": 3, "Saves": 4, "Result": "VICTORY"})

func _handle_kart_cmd(scene: Node, cmd: String) -> void:
	var results = scene.get_node_or_null("ResultsScreen")
	var hud = scene.get_node_or_null("HUD")
	var p_list = scene.get_tree().get_nodes_in_group("players")
	var player = p_list[0] if not p_list.is_empty() else null

	if cmd == "cam_kart_closeup":
		var cam = scene.find_child("Camera3D", true, false)
		if cam and player:
			cam.top_level = true
			cam.global_position = player.global_position + Vector3(1.0, 0.7, -2.8)
			cam.look_at(player.global_position + Vector3(0, 0.3, 0), Vector3.UP)
	elif cmd == "cam_barriers_crowd":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(14.0, 5.0, 10.0)
			cam.look_at(Vector3(30.0, 6.0, 10.0), Vector3.UP)
	elif cmd == "racers_move":
		var ai_list = scene.get_tree().get_nodes_in_group("ai_racers")
		for ai in ai_list:
			if ai is RigidBody3D:
				ai.linear_velocity = -ai.global_transform.basis.z * 22.0
	elif cmd == "drift_hairpin":
		if player and player.has_method("trigger_mini_turbo"):
			player.is_drifting = true
			player.drift_charge = 1.0
	elif cmd == "mini_turbo":
		if player and player.has_method("trigger_mini_turbo"):
			player.trigger_mini_turbo(1.0)
	elif cmd == "cam_item_box":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(4.0, 1.5, 18.0)
			cam.look_at(Vector3(0.0, 1.0, 22.0), Vector3.UP)
	elif cmd == "offtrack_recovery":
		if player:
			player.global_position = Vector3(0, 0.5, 0)
			player.rotation = Vector3.ZERO
			if player is RigidBody3D:
				player.linear_velocity = Vector3.ZERO
	elif cmd == "cam_canyon":
		var cam = scene.find_child("Camera3D", true, false)
		if cam:
			cam.top_level = true
			cam.global_position = Vector3(35.0, 8.0, -15.0)
			cam.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
	elif cmd == "lap_progression":
		if hud:
			if hud.has_method("update_lap"):
				hud.update_lap(2, 3)
			if hud.has_method("update_position"):
				hud.update_position(1, 6)
	elif cmd == "show_results":
		if results and results.has_method("display_results"):
			results.display_results(true, {"Position": "1st Place (GOLD)", "Best Lap": "00:48.2", "Total Time": "02:31.5"})

func _check_cmdline_args() -> void:
	var args = OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--game" and i + 1 < args.size():
			var g_id = args[i + 1]
			call_deferred("start_game", g_id)

func set_state(new_state: int) -> void:
	var old = current_state
	current_state = new_state
	if event_bus:
		event_bus.game_state_changed.emit(old, new_state)

func start_game(game_id: String) -> void:
	active_game_id = game_id
	set_state(STATE_LOADING)

	var scene_path = ""
	match game_id:
		"arena_fps":
			scene_path = "res://games/arena-fps/arena_fps_main.tscn"
		"subway_survival":
			scene_path = "res://games/subway-survival/subway_main.tscn"
		"rocket_car":
			scene_path = "res://games/rocket-car/rocket_car_main.tscn"
		"kart_racing":
			scene_path = "res://games/kart-racing/kart_racing_main.tscn"
		_:
			push_error("Unknown game ID: " + game_id)
			return

	if ResourceLoader.exists(scene_path):
		var packed = load(scene_path) as PackedScene
		if packed:
			switch_to_scene(packed)
			set_state(STATE_PLAYING)
			var im = GameConstants.get_autoload(self, "InputManager")
			if im and im.has_method("set_game_context"):
				im.set_game_context(game_id)
			if event_bus:
				event_bus.game_loaded.emit(game_id)
	else:
		push_error("Scene file missing: " + scene_path)

func switch_to_scene(packed_scene: PackedScene) -> void:
	if is_instance_valid(active_game_instance):
		active_game_instance.queue_free()
		active_game_instance = null
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = false
		clean_root_orphans(tree)
		tree.change_scene_to_packed(packed_scene)

func restart_current_game() -> void:
	if not active_game_id.is_empty():
		start_game(active_game_id)

func return_to_launcher() -> void:
	if is_instance_valid(active_game_instance):
		active_game_instance.queue_free()
		active_game_instance = null
	active_game_id = ""
	set_state(STATE_MENU)

	# Stop all audio during scene transition to return cleanly
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("stop_all"):
		am.stop_all()

	# Release mouse cursor and reset input context
	var im = GameConstants.get_autoload(self, "InputManager")
	if im:
		im.capture_mouse(false)
		if im.has_method("set_game_context"):
			im.set_game_context("")
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = false
		clean_root_orphans(tree)
		tree.change_scene_to_file("res://launcher/launcher.tscn")

func clean_root_orphans(tree: SceneTree) -> void:
	if not tree or not tree.root:
		return
	var valid_autoloads = [
		"EventBus", "SettingsManager", "SaveManager", "AudioManager",
		"InputManager", "PlatformAdapter", "QualityManager", "TelemetryManager",
		"AssetLoader", "GameManager"
	]
	for child in tree.root.get_children():
		if child == tree.current_scene:
			continue
		if child.name in valid_autoloads:
			continue
		child.queue_free()

