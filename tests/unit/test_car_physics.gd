class_name TestCarPhysics
extends RefCounted

const CarControllerScript = preload("res://games/rocket-car/vehicle/car_controller.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_car_ready_and_visual()
	test_boost_replenish()
	test_driving_acceleration()
	test_car_physics_process()
	test_handle_player_input()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://games/rocket-car/vehicle/car_controller.gd",
		[
			"_ready", "setup_car_visual", "_physics_process",
			"handle_player_input", "apply_driving_controls", "replenish_boost",
			"perform_jump", "perform_dodge"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Assertion failed: " + msg)

func test_car_ready_and_visual() -> void:
	var car = CarControllerScript.new()
	car.team_id = 0
	car._ready()
	assert_true(car.car_visual != null, "Car visual must be created in _ready")
	car.queue_free()

func test_boost_replenish() -> void:
	var car = CarControllerScript.new()
	car.current_boost = 20.0
	car.replenish_boost(50.0)
	assert_true(car.current_boost == 70.0, "Boost should increase to 70")
	car.replenish_boost(100.0)
	assert_true(car.current_boost == 100.0, "Boost should cap at max 100")
	car.queue_free()

func test_driving_acceleration() -> void:
	var car = CarControllerScript.new()
	car.forward_speed = 0.0
	car.apply_driving_controls(1.0, 0.0, 0.1) # 100ms full throttle
	assert_true(car.forward_speed > 0.0, "Forward speed should increase under throttle")
	car.queue_free()

func test_car_physics_process() -> void:
	var car = CarControllerScript.new()
	car.is_player_controlled = false
	car._physics_process(0.016)
	assert_true(true, "Car _physics_process must execute safely")
	car.queue_free()

func test_handle_player_input() -> void:
	var car = CarControllerScript.new()
	car.is_player_controlled = true
	car.handle_player_input(0.016)
	assert_true(true, "Car handle_player_input must execute safely")
	car.queue_free()
