extends Node

signal load_progress_updated(game_id: String, progress: float, bytes_loaded: int, total_bytes: int, message: String)
signal load_completed(game_id: String, success: bool, loaded_scene: PackedScene)

var current_loading_path: String = ""
var current_game_id: String = ""
var is_loading: bool = false
var load_start_time_msec: int = 0
const LOAD_TIMEOUT_MSEC: int = 10000

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	if not is_loading or current_loading_path.is_empty():
		set_process(false)
		return

	# Timeout fallback: fallback to sync load if threaded load stalls
	if Time.get_ticks_msec() - load_start_time_msec > LOAD_TIMEOUT_MSEC:
		is_loading = false
		set_process(false)
		if ResourceLoader.exists(current_loading_path):
			var scene = load(current_loading_path) as PackedScene
			load_progress_updated.emit(current_game_id, 1.0, 1000000, 1000000, "Completed!")
			load_completed.emit(current_game_id, true, scene)
		else:
			push_error("Loading timed out: " + current_loading_path)
			load_completed.emit(current_game_id, false, null)
		return

	var progress_arr = []
	var status = ResourceLoader.load_threaded_get_status(current_loading_path, progress_arr)

	var p = progress_arr[0] if progress_arr.size() > 0 else 0.0
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			load_progress_updated.emit(current_game_id, p, int(p * 1000000), 1000000, "Loading resources: %d%%" % int(p * 100.0))
		ResourceLoader.THREAD_LOAD_LOADED:
			is_loading = false
			set_process(false)
			var scene = ResourceLoader.load_threaded_get(current_loading_path) as PackedScene
			load_progress_updated.emit(current_game_id, 1.0, 1000000, 1000000, "Completed!")
			load_completed.emit(current_game_id, true, scene)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			is_loading = false
			set_process(false)
			push_error("Failed to load scene: " + current_loading_path)
			load_completed.emit(current_game_id, false, null)

func request_game_load(game_id: String, scene_path: String) -> void:
	current_game_id = game_id
	current_loading_path = scene_path
	is_loading = true
	load_start_time_msec = Time.get_ticks_msec()
	set_process(true)

	# Check if external pack exists
	var pck_path = "user://packs/%s.pck" % game_id
	if FileAccess.file_exists(pck_path):
		ProjectSettings.load_resource_pack(pck_path)

	var err = ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		# Fallback to direct load
		if ResourceLoader.exists(scene_path):
			var res = load(scene_path)
			load_completed.emit(game_id, true, res)
		else:
			load_completed.emit(game_id, false, null)
		is_loading = false
		set_process(false)
