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
			"_ready", "press", "release", "activate_door", "deactivate_door",
			"open_door", "close_door", "toggle_switch", "activate_switch",
			"apply_wind", "get_grapple_position"
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

	var activated_emitted = false
	plate.plate_activated.connect(func(): activated_emitted = true)
	plate.press()
	assert_true(plate.is_pressed, "Pressure plate should be pressed after press()")
	assert_true(activated_emitted, "plate_activated signal should emit")

	plate.release()
	assert_true(not plate.is_pressed, "Pressure plate should not be pressed after release()")
	plate.queue_free()

func test_puzzle_door_activation() -> void:
	var door = PuzzleElementsScript.PuzzleDoor.new()
	door.required_activations = 2
	assert_true(door != null, "Puzzle door should instantiate")
	assert_true(not door.is_open, "Door should initially be closed")

	door.activate_door()
	assert_eq(door.current_activations, 1, "Activations count should be 1")
	assert_true(not door.is_open, "Door should not open with only 1 of 2 activations")

	door.activate_door()
	assert_eq(door.current_activations, 2, "Activations count should be 2")
	assert_true(door.is_open, "Door should open when required activations reached")

	door.deactivate_door()
	assert_eq(door.current_activations, 1, "Activations count should decrease to 1")
	assert_true(not door.is_open, "Door should close when activations fall below required")
	door.queue_free()

func test_puzzle_switch_toggle() -> void:
	var sw = PuzzleElementsScript.PuzzleSwitch.new()
	assert_true(not sw.is_active, "Switch should start inactive")

	sw.toggle_switch()
	assert_true(sw.is_active, "Switch should become active after toggle")

	sw.toggle_switch()
	assert_true(not sw.is_active, "Switch should become inactive after second toggle")
	sw.queue_free()

func test_wind_current_force() -> void:
	var wind = PuzzleElementsScript.WindCurrent.new()
	wind.updraft_force = 18.0
	assert_eq(wind.updraft_force, 18.0, "Wind updraft force should match assigned value")
	wind.queue_free()

func test_grapple_anchor_properties() -> void:
	var anchor = PuzzleElementsScript.GrappleAnchor.new()
	anchor.position = Vector3(10, 20, 30)
	var pos = anchor.get_grapple_position()
	assert_true(pos.distance_to(Vector3(10, 20, 30)) < 0.01, "Grapple position should match anchor position")
	anchor.queue_free()
