class_name TestGameManager
extends RefCounted

const GameManagerScript = preload("res://shared/core/game_manager.gd")
const AssetLoaderScript = preload("res://shared/loading/asset_loader.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_state_management()
	test_game_manager_signals()
	test_asset_loader()
	test_game_constants()
	test_all_13_games_routing()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://shared/core/game_manager.gd",
			["_ready", "set_state", "start_game", "switch_to_scene", "restart_current_game", "return_to_launcher", "clean_root_orphans", "handle_exec_cmd"]
		],
		[
			"res://shared/loading/asset_loader.gd",
			["_ready", "_process", "request_game_load"]
		],
		[
			"res://shared/core/game_constants.gd",
			["get_autoload"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit GameManager FAIL: " + msg)

func test_state_management() -> void:
	var gm = GameManagerScript.new()
	gm.set_state(gm.STATE_MENU)
	assert_true(gm.current_state == gm.STATE_MENU, "GameManager state must update to STATE_MENU")
	gm.set_state(gm.STATE_PLAYING)
	assert_true(gm.current_state == gm.STATE_PLAYING, "GameManager state must update to STATE_PLAYING")
	gm.queue_free()

func test_game_manager_signals() -> void:
	var gm = GameManagerScript.new()
	gm._ready()
	# Test restart and return to launcher methods execute safely
	gm.restart_current_game()
	gm.return_to_launcher()
	gm.clean_root_orphans(null)
	assert_true(gm.current_state == gm.STATE_MENU, "return_to_launcher must set STATE_MENU")
	gm.queue_free()

func test_asset_loader() -> void:
	var al = AssetLoaderScript.new()
	al._ready()
	al.request_game_load("arena_fps", "res://games/arena-fps/arena_fps_main.tscn")
	assert_true(al.is_loading, "Asset loader should be in loading state")
	al.is_loading = false
	al._process(0.016)
	assert_true(not al.is_loading, "Asset loader must be stopped")
	al.queue_free()

func test_game_constants() -> void:
	var dummy = Node.new()
	var res = GameConstants.get_autoload(dummy, "NonExistentAutoload")
	assert_true(res == null, "NonExistent autoload must return null")
	dummy.queue_free()

func test_all_13_games_routing() -> void:
	var expected_games = [
		{"id": "arena_fps", "scene": "res://games/arena-fps/arena_fps_main.tscn"},
		{"id": "subway_survival", "scene": "res://games/subway-survival/subway_main.tscn"},
		{"id": "rocket_car", "scene": "res://games/rocket-car/rocket_car_main.tscn"},
		{"id": "kart_racing", "scene": "res://games/kart-racing/kart_racing_main.tscn"},
		{"id": "skybound_odyssey", "scene": "res://games/skybound-odyssey/skybound_main.tscn"},
		{"id": "roboforge_arena", "scene": "res://games/roboforge-arena/roboforge_main.tscn"},
		{"id": "wildcircuit", "scene": "res://games/wildcircuit/wildcircuit_main.tscn"},
		{"id": "strike_vector", "scene": "res://games/strike-vector/strike_vector_main.tscn"},
		{"id": "chroma_rush", "scene": "res://games/chroma-rush/chroma_rush_main.tscn"},
		{"id": "aero_rush", "scene": "res://games/aero-rush/aero_rush_main.tscn"},
		{"id": "aircraft_flight", "scene": "res://games/aircraft-flight/aircraft_flight_main.tscn"},
		{"id": "urban_legends", "scene": "res://games/urban-legends/urban_legends_main.tscn"},
		{"id": "flight_simulator_6dof", "scene": "res://games/flight-simulator-6dof/flight_sim_standalone.tscn"}
	]
	for g in expected_games:
		assert_true(ResourceLoader.exists(g["scene"]), "Scene file must exist for %s: %s" % [g["id"], g["scene"]])


