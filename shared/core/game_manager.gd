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

func _ready() -> void:
	if event_bus:
		event_bus.game_selected.connect(start_game)
		event_bus.return_to_launcher_requested.connect(return_to_launcher)
		event_bus.game_restart_requested.connect(restart_current_game)

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
		tree.change_scene_to_file("res://launcher/launcher.tscn")
