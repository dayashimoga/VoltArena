class_name ThreadedSceneLoader
extends Node

## ThreadedSceneLoader: Non-blocking asynchronous scene streamer for VoltArena.
## Safely loads packed scenes using background sub-threads, yields execution to the
## engine main loop every frame to prevent Windows "Not Responding" title-bar freezes,
## and hands loaded PackedScenes directly to GameManager.

signal load_progress_updated(percent: float, bytes_loaded: int, total_bytes: int, message: String)
signal load_completed(scene_path: String, success: bool, packed_scene: PackedScene)

var current_scene_path: String = ""
var is_loading: bool = false
var load_start_time_msec: int = 0
const LOAD_TIMEOUT_MSEC: int = 15000

func _ready() -> void:
	set_process(false)

## Non-blocking coroutine that yields to the OS event loop every frame.
func load_game_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("ThreadedSceneLoader: scene_path is empty")
		load_completed.emit("", false, null)
		return

	current_scene_path = scene_path
	is_loading = true
	load_start_time_msec = Time.get_ticks_msec()

	# 1. Initiate threaded request with use_sub_threads = true
	var err := ResourceLoader.load_threaded_request(scene_path, "", true)
	if err != OK:
		# Fallback to direct load if threaded request was already completed or cached
		if ResourceLoader.has_cached(scene_path) or ResourceLoader.exists(scene_path):
			var res = load(scene_path) as PackedScene
			is_loading = false
			load_progress_updated.emit(100.0, 1000000, 1000000, "Ready!")
			load_completed.emit(scene_path, true, res)
			return
		push_error("Failed to initiate threaded load for: " + scene_path)
		is_loading = false
		load_completed.emit(scene_path, false, null)
		return

	# 2. Asynchronous Polling Loop yielding every frame
	var progress: Array = []
	while is_loading:
		# Timeout safety guard
		if Time.get_ticks_msec() - load_start_time_msec > LOAD_TIMEOUT_MSEC:
			push_warning("Threaded load timeout for: " + scene_path + ", falling back to sync load")
			is_loading = false
			if ResourceLoader.exists(scene_path):
				var res = load(scene_path) as PackedScene
				load_progress_updated.emit(100.0, 1000000, 1000000, "Completed!")
				load_completed.emit(scene_path, true, res)
			else:
				load_completed.emit(scene_path, false, null)
			break

		progress.clear()
		var status := ResourceLoader.load_threaded_get_status(scene_path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var percent: float = progress[0] * 100.0 if progress.size() > 0 else 0.0
				var loaded_b: int = int((progress[0] if progress.size() > 0 else 0.0) * 1000000.0)
				load_progress_updated.emit(percent, loaded_b, 1000000, "Loading resources: %d%%" % int(percent))
				# CRITICAL: YIELD TO ENGINE MAIN LOOP & OS EVENT PUMP TO PREVENT HANG
				if is_inside_tree():
					await get_tree().process_frame
				else:
					break

			ResourceLoader.THREAD_LOAD_LOADED:
				is_loading = false
				var packed_scene: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
				load_progress_updated.emit(100.0, 1000000, 1000000, "Ready!")
				load_completed.emit(scene_path, true, packed_scene)
				break

			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Threaded load failed for: " + scene_path)
				is_loading = false
				load_completed.emit(scene_path, false, null)
				break
