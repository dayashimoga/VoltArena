class_name TestPhysicsHelpers
extends RefCounted

const PhysicsHelpersScript = preload("res://shared/physics/physics_helpers.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_raycast_null_world()
	test_calculate_ballistic_velocity()
	test_reflect_velocity()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/physics/physics_helpers.gd",
		["raycast_3d", "calculate_ballistic_velocity", "reflect_velocity"]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit PhysicsHelpers FAIL: " + msg)

func test_raycast_null_world() -> void:
	var result = PhysicsHelpersScript.raycast_3d(null, Vector3.ZERO, Vector3.FORWARD)
	assert_true(result.is_empty(), "Raycast with null world must return empty dictionary")

func test_calculate_ballistic_velocity() -> void:
	var start = Vector3(0, 0, 0)
	var target = Vector3(10, 0, 0)
	var gravity = 9.8
	var arc_height = 5.0
	var vel = PhysicsHelpersScript.calculate_ballistic_velocity(start, target, gravity, arc_height)
	assert_true(vel.y > 0.0, "Ballistic initial vy must be positive upwards")
	assert_true(vel.x > 0.0, "Ballistic initial vx must be positive towards target")

func test_reflect_velocity() -> void:
	var incoming = Vector3(0, -10, 0)
	var normal = Vector3.UP
	var bounce = PhysicsHelpersScript.reflect_velocity(incoming, normal, 0.5)
	assert_true(bounce.y == 5.0, "Reflected velocity must bounce upward with 50% restitution")
