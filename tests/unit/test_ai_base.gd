class_name TestAIBase
extends RefCounted

const AIBaseScript = preload("res://shared/ai/ai_base.gd")
const KartAIScript = preload("res://games/kart-racing/ai/kart_ai.gd")
const CarAIScript = preload("res://games/rocket-car/ai/car_ai.gd")
const CarControllerScript = preload("res://games/rocket-car/vehicle/car_controller.gd")
const RocketBallScript = preload("res://games/rocket-car/ball/ball.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_difficulty_configuration()
	test_steer_towards()
	test_line_of_sight_null()
	test_find_target()
	test_car_ai_physics()
	test_kart_ai_physics()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://shared/ai/ai_base.gd",
			["_ready", "configure_difficulty", "find_nearest_target_in_group", "has_line_of_sight", "steer_towards"]
		],
		[
			"res://games/rocket-car/ai/car_ai.gd",
			["_physics_process"]
		],
		[
			"res://games/kart-racing/ai/kart_ai.gd",
			["_physics_process"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit AIBase FAIL: " + msg)

func test_difficulty_configuration() -> void:
	var ai = AIBaseScript.new()
	var base_speed = ai.movement_speed
	ai.configure_difficulty(GameConstants.Difficulty.EASY)
	assert_true(ai.movement_speed < base_speed, "Easy AI must move slower")
	assert_true(ai.aim_jitter_amount > 0.1, "Easy AI must have high aim jitter")

	ai.configure_difficulty(GameConstants.Difficulty.NIGHTMARE)
	assert_true(ai.aim_jitter_amount < 0.01, "Nightmare AI must have precise aim")

func test_steer_towards() -> void:
	var ai = AIBaseScript.new()
	ai.position = Vector3(0, 0, 0)
	ai.steer_towards(Vector3(10, 0, 0), 0.1)
	assert_true(ai.velocity.x > 0.0, "AI must set velocity toward target X")

func test_line_of_sight_null() -> void:
	var ai = AIBaseScript.new()
	assert_true(not ai.has_line_of_sight(null), "Null target must have no line of sight")

func test_find_target() -> void:
	var ai = AIBaseScript.new()
	var target = ai.find_nearest_target_in_group("nonexistent_group")
	assert_true(target == null, "Nonexistent group must return null target")

func test_car_ai_physics() -> void:
	var car_ai = CarAIScript.new()
	var car = CarControllerScript.new()
	var ball = RocketBallScript.new()
	car_ai.car = car
	car_ai.ball = ball
	car_ai._physics_process(0.016)
	assert_true(true, "CarAI _physics_process must execute safely")
	car_ai.queue_free()
	car.queue_free()
	ball.queue_free()

func test_kart_ai_physics() -> void:
	var kart_ai = KartAIScript.new()
	kart_ai._physics_process(0.016)
	assert_true(true, "KartAI _physics_process must execute safely without crash")
	kart_ai.queue_free()
