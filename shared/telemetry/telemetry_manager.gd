extends Node

var fps_history: Array[float] = []
var frame_time_history: Array[float] = []
var max_samples: int = 300

var current_fps: float = 60.0
var avg_fps: float = 60.0
var min_fps: float = 60.0
var max_fps: float = 60.0
var frame_spikes_count: int = 0

func _process(delta: float) -> void:
	current_fps = Engine.get_frames_per_second()
	fps_history.append(current_fps)
	frame_time_history.append(delta * 1000.0)

	if delta > (1.0 / 30.0): # Dropped below 30 FPS threshold
		frame_spikes_count += 1

	if fps_history.size() > max_samples:
		fps_history.pop_front()
		frame_time_history.pop_front()

	calculate_stats()

func calculate_stats() -> void:
	if fps_history.is_empty():
		return
	var sum: float = 0.0
	min_fps = 999.0
	max_fps = 0.0
	for f in fps_history:
		sum += f
		if f < min_fps:
			min_fps = f
		if f > max_fps:
			max_fps = f
	avg_fps = sum / float(fps_history.size())

func get_report_dictionary() -> Dictionary:
	return {
		"current_fps": current_fps,
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"spikes": frame_spikes_count,
		"static_memory_mb": OS.get_static_memory_usage() / (1024.0 * 1024.0),
		"platform": OS.get_name(),
		"renderer": RenderingServer.get_video_adapter_name()
	}
