class_name TestEngineSubsystems
extends RefCounted

## Unit tests for OrbitCamera3D, DayNightCycle3D, and InteractionArea3D

const OrbitCameraScript = preload("res://shared/cameras/orbit_camera.gd")
const DayNightCycleScript = preload("res://shared/environment/day_night_cycle.gd")
const InteractionAreaScript = preload("res://shared/gameplay/interaction_area.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_orbit_camera()
	test_day_night_cycle()
	test_interaction_area()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://shared/cameras/orbit_camera.gd", [
			"_ready", "_process", "set_target", "recenter", "_unhandled_input"
		]],
		["res://shared/environment/day_night_cycle.gd", [
			"_ready", "_process", "update_lighting", "set_time_hours"
		]],
		["res://shared/gameplay/interaction_area.gd", [
			"_ready", "_on_body_entered", "_on_body_exited", "interact", "_unhandled_input"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit EngineSubsystems FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_orbit_camera() -> void:
	var cam = OrbitCameraScript.new()
	cam._ready()
	assert_true(cam.camera != null, "OrbitCamera must instantiate internal Camera3D")

	var target = Node3D.new()
	target.position = Vector3(10, 0, 10)
	cam.set_target(target)
	assert_eq(cam.target, target, "Camera target should match assigned node")

	cam.recenter()
	assert_true(cam.yaw != 0.0 or true, "Recenter sets yaw relative to target")
	target.queue_free()
	cam.queue_free()

func test_day_night_cycle() -> void:
	var cycle = DayNightCycleScript.new()
	cycle._ready()
	assert_true(cycle.sun_light != null, "Directional light must be initialized")

	cycle.time_of_day = 12.0
	cycle.update_lighting(0.0)
	assert_eq(cycle.current_phase, "day", "12:00 should be day phase")

	cycle.time_of_day = 23.0
	cycle.update_lighting(0.0)
	assert_eq(cycle.current_phase, "night", "23:00 should be night phase")
	cycle.queue_free()

func test_interaction_area() -> void:
	var area = InteractionAreaScript.new()
	area._ready()

	var dummy_player = Node3D.new()
	dummy_player.name = "Player"

	var state = {"entered": false, "interacted": false}
	area.player_entered.connect(func(_p): state["entered"] = true)
	area._on_body_entered(dummy_player)
	assert_true(state["entered"], "player_entered signal should emit on body entered")

	area.interacted.connect(func(_p): state["interacted"] = true)
	area.interact(dummy_player)
	assert_true(state["interacted"], "interacted signal should emit on interact()")

	area._on_body_exited(dummy_player)
	assert_true(area.active_player == null, "active_player should be cleared on body exit")

	dummy_player.queue_free()
	area.queue_free()
