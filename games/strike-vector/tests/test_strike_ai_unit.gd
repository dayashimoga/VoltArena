class_name TestStrikeAIUnit
extends RefCounted

## Unit tests for Strike Vector Enemy AI, 10 Archetypes, Squad Coordination, and Bosses.

const StrikeAIBaseScript = preload("res://games/strike-vector/ai/strike_ai_base.gd")
const AIArchetypesScript = preload("res://games/strike-vector/ai/ai_archetypes.gd")
const SquadCoordScript = preload("res://games/strike-vector/ai/squad_coordinator.gd")
const StrikeBossBaseScript = preload("res://games/strike-vector/bosses/strike_boss_base.gd")
const BossArchetypesScript = preload("res://games/strike-vector/bosses/boss_archetypes.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	test_ai_hfsm_state_transitions()
	test_all_10_ai_archetypes()
	test_squad_coordination_tokens()
	test_boss_state_machine_and_phases()
	test_all_8_mission_bosses()
	return {"passed": passed, "failed": failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/strike-vector/ai/strike_ai_base.gd", [
			"_ready", "_setup_nav_agent", "_apply_difficulty_modifiers", "_physics_process", "_find_player_target",
			"_evaluate_perception", "_update_timers", "_execute_hfsm", "_process_patrol", "_process_alert",
			"_process_cover_flank", "_process_attack", "_execute_burst_shot", "_process_reposition", "_process_search",
			"_move_along_nav_path", "_turn_toward", "_start_reload", "set_state", "take_damage", "_die", "_watchdog_stuck_recovery"
		]],
		["res://games/strike-vector/ai/ai_archetypes.gd", [
			"create_enemy", "get_all_archetypes", "create_rifle_trooper", "create_assault_rusher", "create_heavy",
			"create_marksman", "create_shield_unit", "create_grenadier", "create_combat_drone", "create_turret",
			"create_elite", "create_commander", "_attach_humanoid_visual", "_setup_collision"
		]],
		["res://games/strike-vector/ai/squad_coordinator.gd", [
			"register_member", "unregister_member", "request_attack_slot", "release_attack_slot", "_cleanup_shooters", "broadcast_alert"
		]],
		["res://games/strike-vector/bosses/strike_boss_base.gd", [
			"_ready", "_setup_boss_visual", "_setup_collision", "_physics_process", "_find_player",
			"_process_telegraph", "_process_attack", "_process_evade", "_process_weakness_exposed",
			"_process_phase_transition", "_execute_boss_attack_pattern", "take_damage", "_defeat", "set_state", "_turn_toward"
		]],
		["res://games/strike-vector/bosses/boss_archetypes.gd", [
			"create_boss_by_mission", "create_m1_urban_jammer_mech", "create_m2_vtol_gunship", "create_m3_gantry_loader_titan",
			"create_m4_convoy_battle_rig", "create_m5_subzero_walker", "create_m6_megafactory_apex_robot",
			"create_m7_sky_fortress_core", "create_m8_citadel_overlord", "_build_mech_model", "_build_aircraft_model",
			"_build_industrial_mech_model", "_build_tank_rig_model", "_build_aerial_core_model", "_build_citadel_overlord_model", "_add_box"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + msg)

func test_ai_hfsm_state_transitions() -> void:
	var ai = StrikeAIBaseScript.new()
	assert_true(ai.current_state == StrikeAIBaseScript.AIState.IDLE, "AI should start in IDLE")
	ai.set_state(StrikeAIBaseScript.AIState.ALERT)
	assert_true(ai.current_state == StrikeAIBaseScript.AIState.ALERT, "AI should transition to ALERT")
	ai.set_state(StrikeAIBaseScript.AIState.ATTACK)
	assert_true(ai.current_state == StrikeAIBaseScript.AIState.ATTACK, "AI should transition to ATTACK")
	ai.take_damage(20.0)
	assert_true(ai.current_health == ai.max_health - 20.0, "AI should take damage")
	ai.queue_free()

func test_all_10_ai_archetypes() -> void:
	var archetypes = AIArchetypesScript.get_all_archetypes()
	assert_true(archetypes.size() == 10, "Must have exactly 10 AI archetypes")

	for arch in archetypes:
		var enemy = AIArchetypesScript.create_enemy(arch)
		assert_true(is_instance_valid(enemy), "Archetype %s must instantiate" % arch)
		assert_true(enemy.max_health > 0.0, "Archetype %s health must be positive" % arch)
		assert_true(enemy.weapon_damage > 0.0, "Archetype %s damage must be positive" % arch)
		assert_true(enemy.score_value > 0, "Archetype %s score must be positive" % arch)
		enemy.queue_free()

func test_squad_coordination_tokens() -> void:
	var sq = SquadCoordScript.new()
	sq.max_simultaneous_shooters = 2

	var m1 = StrikeAIBaseScript.new()
	var m2 = StrikeAIBaseScript.new()
	var m3 = StrikeAIBaseScript.new()

	sq.register_member(m1)
	sq.register_member(m2)
	sq.register_member(m3)

	assert_true(sq.request_attack_slot(m1), "Member 1 should get attack slot")
	assert_true(sq.request_attack_slot(m2), "Member 2 should get attack slot")
	assert_true(not sq.request_attack_slot(m3), "Member 3 should be denied when slots full")

	sq.release_attack_slot(m1)
	assert_true(sq.request_attack_slot(m3), "Member 3 should get slot after release")

	m1.queue_free()
	m2.queue_free()
	m3.queue_free()
	sq.queue_free()

func test_boss_state_machine_and_phases() -> void:
	var boss = StrikeBossBaseScript.new()
	boss.max_health_per_phase = 100.0
	boss.total_phases = 2
	boss.current_health = 100.0

	assert_true(boss.current_phase == 1, "Boss should start in Phase 1")
	boss.set_state(StrikeBossBaseScript.BossState.WEAKNESS_EXPOSED)
	assert_true(boss.current_state == StrikeBossBaseScript.BossState.WEAKNESS_EXPOSED, "Boss should be in WEAKNESS_EXPOSED")

	# Damage boss to trigger phase transition
	boss.take_damage(100.0)
	assert_true(boss.current_state == StrikeBossBaseScript.BossState.PHASE_TRANSITION, "Boss should transition to next phase")
	boss._process_phase_transition(3.0)
	assert_true(boss.current_phase == 2, "Boss should advance to Phase 2")
	boss.queue_free()

func test_all_8_mission_bosses() -> void:
	for m in range(1, 9):
		var b = BossArchetypesScript.create_boss_by_mission(m)
		assert_true(is_instance_valid(b), "Mission %d boss must instantiate" % m)
		assert_true(not b.boss_name.is_empty(), "Mission %d boss must have a name" % m)
		assert_true(b.total_phases >= 2, "Mission %d boss must have >= 2 phases" % m)
		assert_true(b.score_value >= 5000, "Mission %d boss score reward must be >= 5000" % m)
		b.queue_free()
