class_name TestHealthComponent
extends RefCounted

const HealthComponentScript = preload("res://shared/combat/health_component.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_initialization()
	test_damage_absorption()
	test_healing()
	test_death_signal()
	test_add_armor_and_reset()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/combat/health_component.gd",
		["_ready", "take_damage", "heal", "add_armor", "reset"]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Assertion failed: " + msg)

func test_initialization() -> void:
	var hp = HealthComponentScript.new()
	hp.max_health = 100.0
	hp.current_health = 100.0
	hp.max_armor = 50.0
	hp.current_armor = 50.0
	hp._ready()

	assert_true(hp.current_health == 100.0, "Health should initialize to 100")
	assert_true(hp.current_armor == 50.0, "Armor should initialize to 50")
	assert_true(not hp.is_dead, "Entity should not be dead on init")

func test_damage_absorption() -> void:
	var hp = HealthComponentScript.new()
	hp.max_health = 100.0
	hp.current_health = 100.0
	hp.max_armor = 100.0
	hp.current_armor = 50.0
	hp.armor_absorption_ratio = 0.5

	# 40 damage with 50% absorbed by armor
	hp.take_damage(40.0)
	assert_true(hp.current_armor == 30.0, "Armor should absorb 20 damage")
	assert_true(hp.current_health == 80.0, "Health should take 20 damage")

func test_healing() -> void:
	var hp = HealthComponentScript.new()
	hp.max_health = 100.0
	hp.current_health = 40.0

	hp.heal(30.0)
	assert_true(hp.current_health == 70.0, "Healing should restore health to 70")
	hp.heal(100.0)
	assert_true(hp.current_health == 100.0, "Healing should cap at max health")

func test_death_signal() -> void:
	var hp = HealthComponentScript.new()
	hp.max_health = 50.0
	hp.current_health = 50.0
	hp.current_armor = 0.0

	var died_called = [false]
	hp.died.connect(func(_source): died_called[0] = true)
	hp.take_damage(60.0)

	assert_true(hp.is_dead, "Entity should be dead after lethal damage")
	assert_true(hp.current_health == 0.0, "Health should be 0")
	assert_true(died_called[0], "Died signal must be emitted")

func test_add_armor_and_reset() -> void:
	var hp = HealthComponentScript.new()
	hp.max_armor = 50.0
	hp.current_armor = 10.0
	hp.add_armor(20.0)
	assert_true(hp.current_armor == 30.0, "Armor should increase by 20")
	hp.take_damage(500.0)
	assert_true(hp.is_dead, "Should be dead")
	hp.reset()
	assert_true(not hp.is_dead, "Reset must restore alive state")
	assert_true(hp.current_health == hp.max_health, "Reset must restore full health")
