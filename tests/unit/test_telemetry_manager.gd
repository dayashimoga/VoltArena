class_name TestTelemetryManager
extends RefCounted

const TelemetryManagerScript = preload("res://shared/telemetry/telemetry_manager.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_process_and_history()
	test_calculate_stats()
	test_spike_detection()
	test_report_dictionary()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/telemetry/telemetry_manager.gd",
		["_process", "calculate_stats", "get_report_dictionary"]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit TelemetryManager FAIL: " + msg)

func test_process_and_history() -> void:
	var tm = TelemetryManagerScript.new()
	tm._process(0.016)
	assert_true(tm.fps_history.size() == 1, "FPS history must record sample")
	assert_true(tm.frame_time_history.size() == 1, "Frame time history must record sample")

	# Fill beyond max_samples
	tm.max_samples = 5
	for i in range(10):
		tm._process(0.016)
	assert_true(tm.fps_history.size() == 5, "FPS history must cap at max_samples")

func test_calculate_stats() -> void:
	var tm = TelemetryManagerScript.new()
	tm.fps_history = [30.0, 60.0, 90.0]
	tm.calculate_stats()
	assert_true(tm.min_fps == 30.0, "Min FPS must be 30")
	assert_true(tm.max_fps == 90.0, "Max FPS must be 90")
	assert_true(abs(tm.avg_fps - 60.0) < 0.001, "Avg FPS must be 60")

func test_spike_detection() -> void:
	var tm = TelemetryManagerScript.new()
	var initial_spikes = tm.frame_spikes_count
	# Delta greater than 1/30s (0.0333s) is a spike
	tm._process(0.05)
	assert_true(tm.frame_spikes_count == initial_spikes + 1, "Spike count must increment on long frame")

func test_report_dictionary() -> void:
	var tm = TelemetryManagerScript.new()
	tm._process(0.016)
	var report = tm.get_report_dictionary()
	assert_true(report.has("current_fps"), "Report must have current_fps")
	assert_true(report.has("avg_fps"), "Report must have avg_fps")
	assert_true(report.has("min_fps"), "Report must have min_fps")
	assert_true(report.has("max_fps"), "Report must have max_fps")
	assert_true(report.has("spikes"), "Report must have spikes")
	assert_true(report.has("static_memory_mb"), "Report must have static_memory_mb")
	assert_true(report.has("platform"), "Report must have platform")
	assert_true(report.has("renderer"), "Report must have renderer")
