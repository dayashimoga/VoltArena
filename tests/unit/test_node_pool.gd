class_name TestNodePool
extends RefCounted

## Unit test suite for NodePool

var assertions_passed: int = 0
var assertions_failed: int = 0

const NodePoolScript = preload("res://shared/core/node_pool.gd")

func run_tests() -> Dictionary:
	test_pool_lifecycle()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://shared/core/node_pool.gd", ["register_pool", "acquire", "release", "get_pool_size", "clear_pool", "clear_all"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_pool_lifecycle() -> void:
	var pool = NodePoolScript.new()

	pool.register_pool("dummy", func(): return Node3D.new(), 4, 8)
	assert_eq(pool.get_pool_size("dummy"), 4, "Initial pool size should be 4")

	var n1 = pool.acquire("dummy")
	assert_true(n1 != null, "Acquired node must not be null")
	assert_eq(pool.get_pool_size("dummy"), 3, "Pool size should decrease after acquire")

	pool.release("dummy", n1)
	assert_eq(pool.get_pool_size("dummy"), 4, "Pool size should increase after release")

	pool.clear_pool("dummy")
	assert_eq(pool.get_pool_size("dummy"), 0, "Pool size should be 0 after clear")

	pool.clear_all()
	pool.free()
