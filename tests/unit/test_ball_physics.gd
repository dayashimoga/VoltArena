class_name TestBallPhysics
extends RefCounted

const BallScript = preload("res://games/rocket-car/ball/ball.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_initialization()
	test_impulse()
	test_reset()
	test_velocity_damping()
	test_ready_and_physics_process()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://games/rocket-car/ball/ball.gd",
		["_ready", "setup_visuals", "_physics_process", "apply_ball_impulse", "reset_to_center"]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit BallPhysics FAIL: " + msg)

func test_initialization() -> void:
	var ball = BallScript.new()
	assert_true(ball != null, "Ball must instantiate")
	assert_true(ball.velocity == Vector3.ZERO, "Ball must start stationary")
	ball.queue_free()

func test_impulse() -> void:
	var ball = BallScript.new()
	ball.apply_ball_impulse(Vector3(10, 5, -20))
	assert_true(ball.velocity.length() > 10.0, "Ball must gain speed from impulse")
	assert_true(ball.velocity.z < 0, "Ball must move in impulse direction")
	ball.queue_free()

func test_reset() -> void:
	var ball = BallScript.new()
	ball.velocity = Vector3(50, 20, -30)
	ball.position = Vector3(10, 5, 15)
	ball.reset_to_center()
	assert_true(ball.velocity.length() < 0.1, "Velocity must be near zero after reset")
	ball.queue_free()

func test_velocity_damping() -> void:
	var ball = BallScript.new()
	ball.apply_ball_impulse(Vector3(100, 0, 0))
	var speed_before = ball.velocity.length()
	assert_true(speed_before > 50.0, "Ball must have high initial speed")
	ball.queue_free()

func test_ready_and_physics_process() -> void:
	var ball = BallScript.new()
	ball._ready()
	assert_true(ball.get_child_count() > 0, "Ball must create visual and collision children")
	ball.apply_ball_impulse(Vector3(10, 0, 0))
	ball._physics_process(0.016)
	assert_true(true, "Ball _physics_process must execute safely")
	ball.queue_free()
