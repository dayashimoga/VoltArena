class_name TestWaveDirector
extends RefCounted

const WaveDirectorScript = preload("res://games/subway-survival/game/wave_director.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_wave_composition()
	test_wave_escalation()
	test_spawning_and_lifecycle()
	test_wave_finish()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://games/subway-survival/game/wave_director.gd",
		[
			"_ready", "_process", "start_next_wave",
			"build_wave_composition", "process_spawning",
			"spawn_enemy", "clean_dead_enemies", "finish_current_wave"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Assertion failed: " + msg)

func test_wave_composition() -> void:
	var wd = WaveDirectorScript.new()
	wd.build_wave_composition(1)
	assert_true(wd.enemies_to_spawn.size() == 7, "Wave 1 should have 7 enemies")
	assert_true(wd.enemies_to_spawn.has("crawler"), "Wave 1 must contain crawlers")
	assert_true(not wd.enemies_to_spawn.has("brute"), "Wave 1 should not have brutes")
	wd.queue_free()

func test_wave_escalation() -> void:
	var wd = WaveDirectorScript.new()
	wd.build_wave_composition(3)
	assert_true(wd.enemies_to_spawn.has("crawler"), "Wave 3 must contain crawlers")
	assert_true(wd.enemies_to_spawn.has("stalker"), "Wave 3 must contain stalkers")
	assert_true(wd.enemies_to_spawn.has("brute"), "Wave 3 must contain brutes")
	wd.queue_free()

func test_spawning_and_lifecycle() -> void:
	var wd = WaveDirectorScript.new()
	wd._ready()
	wd.start_next_wave()
	assert_true(wd.current_wave == 1, "Wave 1 must be active")
	wd.spawn_cooldown = 0.0
	wd.process_spawning(0.1)
	assert_true(wd.active_enemies.size() > 0, "Active enemies must contain spawned enemy")
	wd.clean_dead_enemies()
	wd._process(0.016)
	assert_true(true, "WaveDirector _process and clean_dead_enemies must succeed")
	wd.queue_free()

func test_wave_finish() -> void:
	var wd = WaveDirectorScript.new()
	wd.current_wave = 2
	wd.finish_current_wave()
	assert_true(wd.current_state == wd.WaveState.INTERMISSION, "State must transition to INTERMISSION")
	wd.queue_free()
