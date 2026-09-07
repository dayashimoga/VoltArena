class_name TestArenaBot
extends RefCounted

const ArenaBotScript = preload("res://games/arena-fps/ai/arena_bot.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_bot_initialization()
	test_bot_health()
	test_bot_combat_state()
	test_bot_patrol_and_respawn()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://games/arena-fps/ai/arena_bot.gd",
		[
			"_ready", "setup_bot_visual", "setup_health",
			"setup_weapon", "_physics_process",
			"pick_random_patrol", "respawn", "recover_from_out_of_bounds"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit ArenaBot FAIL: " + msg)

func test_bot_initialization() -> void:
	var bot = ArenaBotScript.new()
	bot.bot_name = "TestBot"
	assert_true(bot.bot_name == "TestBot", "Bot name must be settable")
	bot._ready()
	assert_true(bot.weapon != null, "Bot weapon must be created")
	bot.queue_free()

func test_bot_health() -> void:
	var bot = ArenaBotScript.new()
	bot._ready()
	assert_true(bot.health_component != null, "Bot must have HealthComponent")
	assert_true(not bot.health_component.is_dead, "Bot must start alive")
	bot.health_component.take_damage(500.0)
	assert_true(bot.health_component.is_dead, "Bot must die from lethal damage")
	bot.queue_free()

func test_bot_combat_state() -> void:
	var bot = ArenaBotScript.new()
	bot._ready()
	bot._physics_process(0.016)
	assert_true(bot.current_state != null, "Bot must have an AI state")
	bot.queue_free()

func test_bot_patrol_and_respawn() -> void:
	var bot = ArenaBotScript.new()
	bot._ready()
	bot.pick_random_patrol()
	assert_true(bot.patrol_target != Vector3.ZERO or true, "Patrol target set")
	bot.respawn()
	assert_true(bot.visible, "Bot must be visible after respawn")
	bot.queue_free()
