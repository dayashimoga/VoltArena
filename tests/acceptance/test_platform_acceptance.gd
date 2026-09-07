class_name TestPlatformAcceptance
extends RefCounted

const ArenaFPSMainScript = preload("res://games/arena-fps/arena_fps_main.gd")
const SubwayMainScript = preload("res://games/subway-survival/subway_main.gd")
const RocketCarMainScript = preload("res://games/rocket-car/rocket_car_main.gd")
const KartRacingMainScript = preload("res://games/kart-racing/kart_racing_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_arena_acceptance()
	test_subway_acceptance()
	test_rocket_acceptance()
	test_kart_acceptance()
	return {"passed": assertions_passed, "failed": assertions_failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Acceptance Failed: " + msg)

func test_arena_acceptance() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()
	arena.player_node._ready() # Explicitly initialize nodes in headless mode
	for b in arena.bots:
		b._ready()

	assert_true(arena.player_node != null, "Arena player must be instantiated")
	assert_true(arena.bots.size() == 3, "Arena must spawn 3 bots")
	assert_true(arena.hud != null, "HUD must be instantiated")
	assert_true(arena.player_node.weapons.size() == 5, "Player must possess 5 weapons")

	# Test weapon firing
	var active_w = arena.player_node.weapons[0]
	var old_ammo = active_w.current_clip_ammo
	var fired = active_w.trigger_fire(Vector3.ZERO, Vector3.FORWARD)
	assert_true(fired, "Weapon must successfully fire")
	assert_true(active_w.current_clip_ammo == old_ammo - 1, "Ammo must decrement on shot")

	# Test bot hit detection & kill scoring
	var bot = arena.bots[0]
	bot.health_component.take_damage(200.0, arena.player_node)
	assert_true(bot.health_component.is_dead, "Bot must die from lethal damage")
	arena.queue_free()

func test_subway_acceptance() -> void:
	var subway = SubwayMainScript.new()
	subway.setup_scene()
	assert_true(subway.player_node != null, "Subway player must be instantiated")
	assert_true(subway.wave_director != null, "WaveDirector must be active")

	# Trigger wave progression
	subway.wave_director.start_next_wave()
	assert_true(subway.wave_director.current_wave == 1, "Wave 1 must start")
	subway.queue_free()

func test_rocket_acceptance() -> void:
	var rocket = RocketCarMainScript.new()
	rocket.setup_scene()
	assert_true(rocket.player_car != null, "Player car must be instantiated")
	assert_true(rocket.ball != null, "Rocket ball must be instantiated")
	assert_true(rocket.ai_cars.size() >= 2, "AI opponents must be spawned")

	# Test ball impulse and goal detection
	rocket.ball.apply_ball_impulse(Vector3(0, 0, -20.0))
	assert_true(rocket.ball.velocity.z < -10.0, "Ball must accelerate upon impulse")
	rocket.is_kickoff_pause = false
	rocket._on_goal_scored(0)
	assert_true(rocket.blue_score == 1, "Blue score must increment on goal")
	rocket.queue_free()

func test_kart_acceptance() -> void:
	var kart_race = KartRacingMainScript.new()
	kart_race.setup_scene()
	assert_true(kart_race.player_kart != null, "Player kart must be instantiated")
	assert_true(kart_race.ai_karts.size() >= 3, "AI racers must be spawned")
	assert_true(kart_race.race_manager != null, "Race manager must be active")

	# Test drift charge & boost
	kart_race.player_kart.drift_charge_time = 2.5
	kart_race.player_kart.trigger_drift_boost()
	assert_true(kart_race.player_kart.boost_timer > 0.0, "Kart must gain boost upon drift release")
	kart_race.queue_free()
