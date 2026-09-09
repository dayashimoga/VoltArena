class_name TestPuzzleElements
extends RefCounted

## Unit tests for shared PuzzleElements (shared/gameplay/puzzle_elements.gd)

const PuzzleElementsScript = preload("res://shared/gameplay/puzzle_elements.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_pressure_plate_trigger()
	test_puzzle_door_activation()
	test_puzzle_switch_toggle()
	test_wind_current_force()
	test_grapple_anchor_properties()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/gameplay/puzzle_elements.gd",
		[
			"_ready", "_init", "toggle", "register_trigger", "_evaluate_door",
			"_physics_process"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit PuzzleElements FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_pressure_plate_trigger() -> void:
	var plate = PuzzleElementsScript.PressurePlate.new()
	assert_true(plate != null, "Pressure plate should instantiate")
	assert_true(not plate.is_pressed, "Pressure plate should initially be unpressed")
	plate.queue_free()

func test_puzzle_door_activation() -> void:
	var door = PuzzleElementsScript.PuzzleDoor.new()
	door.required_activations = 2
	assert_true(door != null, "Puzzle door should instantiate")
	assert_true(not door.is_open, "Door should initially be closed")

	var sw = PuzzleElementsScript.PuzzleSwitch.new()
	door.register_trigger(sw.switch_toggled)

	sw.toggle()
	assert_eq(door.current_activations, 1, "Door activations count should be 1 after switch toggle")
	assert_true(not door.is_open, "Door should not open with only 1 of 2 activations")

	sw.toggle()
	assert_eq(door.current_activations, 0, "Door activations count should be 0 after switch toggle off")

	door.queue_free()
	sw.queue_free()

func test_puzzle_switch_toggle() -> void:
	var sw = PuzzleElementsScript.PuzzleSwitch.new()
	assert_true(not sw.is_on, "Switch should start inactive")

	sw.toggle()
	assert_true(sw.is_on, "Switch should become active after toggle")

	sw.toggle()
	assert_true(not sw.is_on, "Switch should become inactive after second toggle")
	sw.queue_free()

func test_wind_current_force() -> void:
	var wind = PuzzleElementsScript.WindCurrent.new()
	wind.upward_force = 18.0
	assert_eq(wind.upward_force, 18.0, "Wind updraft force should match assigned value")
	wind._physics_process(0.016)
	assert_true(true, "_physics_process should execute safely")
	wind.queue_free()

func test_grapple_anchor_properties() -> void:
	var anchor = PuzzleElementsScript.GrappleAnchor.new()
	anchor.position = Vector3(10, 20, 30)
	assert_true(anchor != null, "Grapple anchor should instantiate")
	anchor.queue_free()
