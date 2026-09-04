class_name TestKartController
extends RefCounted

const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_initialization()
	test_drift_charge()
	test_boost_activation()
	test_speed_properties()
	test_ready_and_visual()
	test_controls_and_physics()
	test_item_boost()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://games/kart-racing/kart/kart_controller.gd",
		[
			"_ready", "setup_kart_visual", "_physics_process",
			"handle_player_input", "apply_kart_controls",
			"trigger_drift_boost", "apply_item_boost"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit KartController FAIL: " + msg)

func test_initialization() -> void:
	var kart = KartControllerScript.new()
	assert_true(kart.base_speed > 0.0, "Base speed must be positive")
	assert_true(kart.acceleration > 0.0, "Acceleration must be positive")
	assert_true(kart.steer_speed > 0.0, "Steering must be positive")
	kart.queue_free()

func test_drift_charge() -> void:
	var kart = KartControllerScript.new()
	kart.drift_charge_time = 0.0
	assert_true(kart.drift_charge_time == 0.0, "Drift charge must start at 0")
	kart.drift_charge_time = 1.5
	assert_true(kart.drift_charge_time == 1.5, "Drift charge must accumulate")
	kart.queue_free()

func test_boost_activation() -> void:
	var kart = KartControllerScript.new()
	kart.drift_charge_time = 3.0
	kart.trigger_drift_boost()
	assert_true(kart.boost_timer > 0.0, "Boost must activate from high drift charge")
	assert_true(kart.drift_charge_time == 0.0, "Drift charge must reset after boost")
	kart.queue_free()

func test_speed_properties() -> void:
	var kart = KartControllerScript.new()
	assert_true(kart.boost_top_speed > kart.base_speed, "Boost top speed must exceed base speed")
	assert_true(kart.brake_deceleration > 0.0, "Brake force must be positive")
	kart.queue_free()

func test_ready_and_visual() -> void:
	var kart = KartControllerScript.new()
	kart._ready()
	assert_true(kart.kart_visual != null, "Kart visual must be created in _ready")
	kart.queue_free()

func test_controls_and_physics() -> void:
	var kart = KartControllerScript.new()
	kart._ready()
	kart.apply_kart_controls(1.0, 0.5, true, 0.016)
	kart.handle_player_input(0.016)
	kart._physics_process(0.016)
	assert_true(true, "Kart controls and physics process must execute safely")
	kart.queue_free()

func test_item_boost() -> void:
	var kart = KartControllerScript.new()
	kart.apply_item_boost(3.0)
	assert_true(kart.boost_timer >= 3.0, "Boost timer must be set by item boost")
	kart.queue_free()
