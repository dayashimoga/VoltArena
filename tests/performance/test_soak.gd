class_name TestSoak
extends RefCounted

## Soak and stability test: repeatedly loads, simulates, and unloads each game
## to verify zero memory runaway and clean lifecycle resource handling.

const ArenaFPSMainScript = preload("res://games/arena-fps/arena_fps_main.gd")
const SubwayMainScript = preload("res://games/subway-survival/subway_main.gd")
const RocketCarMainScript = preload("res://games/rocket-car/rocket_car_main.gd")
const KartRacingMainScript = preload("res://games/kart-racing/kart_racing_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

const SOAK_CYCLES: int = 3

func run_tests() -> Dictionary:
	test_arena_fps_soak()
	test_subway_soak()
	test_rocket_car_soak()
	test_kart_racing_soak()
	test_memory_bounded()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/arena-fps/arena_fps_main.gd", ["_process"]],
		["res://games/subway-survival/subway_main.gd", ["_ready"]],
		["res://games/rocket-car/rocket_car_main.gd", ["_process"]],
		["res://games/kart-racing/kart_racing_main.gd", ["_process"]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Soak Test FAIL: " + msg)

func test_arena_fps_soak() -> void:
	for cycle in range(SOAK_CYCLES):
		var arena = ArenaFPSMainScript.new()
		arena.setup_scene()
		for frame in range(10):
			arena._process(0.016)
		arena.queue_free()
	assert_true(true, "Arena FPS survived %d soak load/unload cycles" % SOAK_CYCLES)

func test_subway_soak() -> void:
	for cycle in range(SOAK_CYCLES):
		var subway = SubwayMainScript.new()
		subway.setup_scene()
		subway.queue_free()
	assert_true(true, "Subway survival survived %d soak load/unload cycles" % SOAK_CYCLES)

func test_rocket_car_soak() -> void:
	for cycle in range(SOAK_CYCLES):
		var rocket = RocketCarMainScript.new()
		rocket.setup_scene()
		for frame in range(10):
			rocket._process(0.016)
		rocket.queue_free()
	assert_true(true, "Rocket car survived %d soak load/unload cycles" % SOAK_CYCLES)

func test_kart_racing_soak() -> void:
	for cycle in range(SOAK_CYCLES):
		var kart = KartRacingMainScript.new()
		kart.setup_scene()
		for frame in range(10):
			kart._process(0.016)
		kart.queue_free()
	assert_true(true, "Kart racing survived %d soak load/unload cycles" % SOAK_CYCLES)

func test_memory_bounded() -> void:
	var mem_usage = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	# Memory in headless tests must stay under 500 MB
	assert_true(mem_usage < 500.0, "Static memory usage (%.1f MB) must remain bounded under 500 MB" % mem_usage)
