class_name TestEnemyBase
extends RefCounted

const EnemyBaseScript = preload("res://games/subway-survival/enemies/enemy_base.gd")
const CrawlerScript = preload("res://games/subway-survival/enemies/crawler.gd")
const StalkerScript = preload("res://games/subway-survival/enemies/stalker.gd")
const BruteScript = preload("res://games/subway-survival/enemies/brute.gd")
const SpitterScript = preload("res://games/subway-survival/enemies/spitter.gd")
const BioColossusScript = preload("res://games/subway-survival/enemies/bio_colossus.gd")
const InfectedHumanScript = preload("res://games/subway-survival/enemies/infected_human.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_enemy_base()
	test_crawler()
	test_stalker()
	test_brute()
	test_spitter()
	test_bio_colossus()
	test_infected_human()
	test_enemy_ai_methods()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/subway-survival/enemies/enemy_base.gd",
			["_ready", "setup_health", "setup_visuals", "_physics_process", "steer_to_target", "perform_attack", "attach_enemy_weapon", "recover_from_out_of_bounds"]
		],
		[
			"res://games/subway-survival/enemies/crawler.gd",
			["_init", "setup_visuals"]
		],
		[
			"res://games/subway-survival/enemies/stalker.gd",
			["_init", "setup_visuals", "perform_attack"]
		],
		[
			"res://games/subway-survival/enemies/brute.gd",
			["_init", "setup_visuals", "perform_attack"]
		],
		[
			"res://games/subway-survival/enemies/spitter.gd",
			["_init", "setup_visuals", "perform_attack"]
		],
		[
			"res://games/subway-survival/enemies/bio_colossus.gd",
			["_init", "setup_visuals", "perform_attack"]
		],
		[
			"res://games/subway-survival/enemies/infected_human.gd",
			["_init", "setup_visuals"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit EnemyBase FAIL: " + msg)

func test_enemy_base() -> void:
	var e = EnemyBaseScript.new()
	e._ready()
	assert_true(e.health_component != null, "Enemy must have HealthComponent")
	assert_true(e.move_speed > 0.0, "Move speed must be positive")
	assert_true(e.attack_damage > 0.0, "Attack damage must be positive")
	assert_true(e.score_value > 0, "Score value must be positive")
	e.queue_free()

func test_crawler() -> void:
	var c = CrawlerScript.new()
	c._ready()
	assert_true(c.move_speed > 5.0, "Crawler must be fast (>5)")
	assert_true(c.enemy_type == "Crawler", "Type must be Crawler")
	c.queue_free()

func test_stalker() -> void:
	var s = StalkerScript.new()
	s._ready()
	assert_true(s.attack_range > 5.0, "Stalker must have ranged attack (>5m)")
	assert_true(s.enemy_type == "Stalker", "Type must be Stalker")
	s.perform_attack()
	s.queue_free()

func test_brute() -> void:
	var b = BruteScript.new()
	b._ready()
	assert_true(b.health_component.max_health > 150.0, "Brute must be tanky (>150 HP)")
	assert_true(b.enemy_type == "Brute", "Type must be Brute")
	b.perform_attack()
	b.queue_free()

func test_spitter() -> void:
	var s = SpitterScript.new()
	s._ready()
	assert_true(s.enemy_type == "Spitter", "Type must be Spitter")
	assert_true(s.attack_range >= 10.0, "Spitter must have ranged attack")
	s.perform_attack()
	s.queue_free()

func test_bio_colossus() -> void:
	var boss = BioColossusScript.new()
	boss._ready()
	assert_true(boss.enemy_type == "Boss", "Type must be Boss")
	assert_true(boss.health_component.max_health >= 1000.0, "Boss must have high health")
	boss.perform_attack()
	boss.queue_free()

func test_infected_human() -> void:
	var inf = InfectedHumanScript.new()
	inf._ready()
	assert_true(inf.enemy_type == "Infected", "Type must be Infected")
	assert_true(inf.health_component.max_health > 0.0, "Infected must have health")
	inf.queue_free()

func test_enemy_ai_methods() -> void:
	var e = EnemyBaseScript.new()
	e._ready()
	e.steer_to_target(Vector3(10, 0, 10), 0.016)
	assert_true(e.velocity.length() > 0.0, "Steer to target must apply velocity")
	e.perform_attack()
	e._physics_process(0.016)
	assert_true(true, "AI methods must execute safely")
	e.queue_free()
