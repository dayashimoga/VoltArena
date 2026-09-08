class_name TestStrikeCampaignUnit
extends RefCounted

## Unit tests for Strike Vector Campaign, Streaming, Segments, Encounters, and Checkpoints.

const MissionDefsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SegmentManagerScript = preload("res://games/strike-vector/campaign/segment_manager.gd")
const MissionStreamerScript = preload("res://games/strike-vector/campaign/mission_streamer.gd")
const EncounterDirectorScript = preload("res://games/strike-vector/campaign/encounter_director.gd")
const CheckpointManagerScript = preload("res://games/strike-vector/campaign/checkpoint_manager.gd")
const CampaignManagerScript = preload("res://games/strike-vector/campaign/campaign_manager.gd")
const DestructiblePropScript = preload("res://games/strike-vector/environment/destructible_prop.gd")
const EnvBuilderScript = preload("res://games/strike-vector/environment/strike_environment_builder.gd")
const SetpieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")
const StrikeCampaignMenuScript = preload("res://games/strike-vector/ui/strike_campaign_menu.gd")
const M1Script = preload("res://games/strike-vector/missions/mission_1_urban_blackout.gd")
const M2Script = preload("res://games/strike-vector/missions/mission_2_high_speed_rail.gd")
const M3Script = preload("res://games/strike-vector/missions/mission_3_harbor_assault.gd")
const M4Script = preload("res://games/strike-vector/missions/mission_4_desert_convoy.gd")
const M5Script = preload("res://games/strike-vector/missions/mission_5_arctic_installation.gd")
const M6Script = preload("res://games/strike-vector/missions/mission_6_megafactory.gd")
const M7Script = preload("res://games/strike-vector/missions/mission_7_sky_fortress.gd")
const M8Script = preload("res://games/strike-vector/missions/mission_8_final_citadel.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	test_all_8_mission_definitions()
	test_segment_state_machine()
	test_mission_streamer_advance()
	test_encounter_director_cycle()
	test_encounter_watchdog_recovery()
	test_checkpoint_registration_and_restore()
	test_campaign_manager_unlocks()
	test_destructibles_and_environment()
	test_setpiece_director()
	test_all_mission_builders()
	test_save_manager_integration()
	test_strike_campaign_menu()
	return {"passed": passed, "failed": failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/strike-vector/missions/mission_definitions.gd", [
			"get_mission_meta", "build_mission_segments", "_get_default_spawns", "_get_reinforcement_spawns", "_populate_props_and_pickups"
		]],
		["res://games/strike-vector/campaign/segment_manager.gd", [
			"_ready", "set_state", "complete_segment"
		]],
		["res://games/strike-vector/campaign/mission_streamer.gd", [
			"setup_segments", "advance_to_next_segment", "get_active_segment"
		]],
		["res://games/strike-vector/campaign/encounter_director.gd", [
			"_ready", "add_exit_barrier", "trigger_encounter", "_spawn_initial_wave", "_on_enemy_defeated",
			"_spawn_next_reinforcement_wave", "complete_encounter", "_set_barriers_locked", "_process"
		]],
		["res://games/strike-vector/campaign/checkpoint_manager.gd", [
			"register_checkpoint", "restore_player_to_checkpoint"
		]],
		["res://games/strike-vector/campaign/campaign_manager.gd", [
			"_ready", "load_campaign_state", "start_mission", "on_mission_completed", "get_next_mission_index"
		]],
		["res://games/strike-vector/environment/destructible_prop.gd", [
			"_ready", "take_damage"
		]],
		["res://games/strike-vector/environment/strike_environment_builder.gd", [
			"build_segment_environment"
		]],
		["res://games/strike-vector/setpieces/setpiece_director.gd", [
			"trigger_setpiece", "_process", "complete_setpiece"
		]],
		["res://games/strike-vector/missions/mission_1_urban_blackout.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_2_high_speed_rail.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_3_harbor_assault.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_4_desert_convoy.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_5_arctic_installation.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_6_megafactory.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_7_sky_fortress.gd", ["create_segments"]],
		["res://games/strike-vector/missions/mission_8_final_citadel.gd", ["create_segments"]],
		["res://shared/save/save_manager.gd", [
			"record_strike_vector_mission", "save_strike_vector_checkpoint", "get_strike_vector_stats"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + msg)

func test_all_8_mission_definitions() -> void:
	for i in range(1, 9):
		var meta = MissionDefsScript.get_mission_meta(i)
		assert_true(meta["index"] == i, "Mission index must match: %d" % i)
		assert_true(not meta["name"].is_empty(), "Mission %d must have a name" % i)
		assert_true(not meta["biome"].is_empty(), "Mission %d must have a biome" % i)
		assert_true(meta["segments"].size() >= 5, "Mission %d must have at least 5 segments" % i)

func test_segment_state_machine() -> void:
	var seg = SegmentManagerScript.new()
	assert_true(seg.current_state == SegmentManagerScript.SegmentState.LOCKED, "Initial state should be LOCKED")
	seg.set_state(SegmentManagerScript.SegmentState.PRELOADED)
	assert_true(seg.current_state == SegmentManagerScript.SegmentState.PRELOADED, "State should transition to PRELOADED")
	seg.set_state(SegmentManagerScript.SegmentState.ACTIVE)
	assert_true(seg.current_state == SegmentManagerScript.SegmentState.ACTIVE, "State should transition to ACTIVE")
	seg.complete_segment()
	assert_true(seg.current_state == SegmentManagerScript.SegmentState.COMPLETE, "State should be COMPLETE")
	seg.queue_free()

func test_mission_streamer_advance() -> void:
	var streamer = MissionStreamerScript.new()
	var segs: Array = []
	for i in range(5):
		var s = SegmentManagerScript.new()
		segs.append(s)

	streamer.setup_segments(segs)
	assert_true(streamer.active_segment_index == 0, "Active segment should start at 0")
	assert_true(segs[0].current_state == SegmentManagerScript.SegmentState.ACTIVE, "Segment 0 should be ACTIVE")
	assert_true(segs[1].current_state == SegmentManagerScript.SegmentState.PRELOADED, "Segment 1 should be PRELOADED")

	streamer.advance_to_next_segment()
	assert_true(streamer.active_segment_index == 1, "Active segment should be 1 after advance")
	assert_true(segs[0].current_state == SegmentManagerScript.SegmentState.EXITED, "Segment 0 should be EXITED")
	assert_true(segs[1].current_state == SegmentManagerScript.SegmentState.ACTIVE, "Segment 1 should be ACTIVE")

	streamer.queue_free()

func test_encounter_director_cycle() -> void:
	var enc = EncounterDirectorScript.new()
	enc.enemy_spawns = [{"archetype": "rifle_trooper", "pos": Vector3.ZERO}]
	enc.trigger_encounter()
	assert_true(enc.is_active, "Encounter should be active after trigger")
	assert_true(not enc.active_enemies.is_empty(), "Encounter should spawn enemies")

	# Defeat all enemies
	for e in enc.active_enemies.duplicate():
		e.take_damage(999.0)

	assert_true(enc.is_completed, "Encounter should complete when enemies defeated")
	enc.queue_free()

func test_encounter_watchdog_recovery() -> void:
	var enc = EncounterDirectorScript.new()
	enc.enemy_spawns = [{"archetype": "rifle_trooper", "pos": Vector3.ZERO}]
	enc.trigger_encounter()
	assert_true(enc.is_active, "Encounter should start")

	# Simulate watchdog trigger threshold
	enc._process(30.0)
	assert_true(enc.is_completed or enc.active_enemies.is_empty(), "Watchdog should resolve stuck encounter")
	enc.queue_free()

func test_checkpoint_registration_and_restore() -> void:
	var cm = CheckpointManagerScript.new()
	var dummy_pos = Vector3(10, 2, -20)
	cm.register_checkpoint("cp_test", dummy_pos, 0.5, 1, 2)
	assert_true(cm.active_checkpoint_id == "cp_test", "Active checkpoint ID should match")
	assert_true(cm.active_checkpoint_pos == dummy_pos, "Active checkpoint pos should match")

	var player = CharacterBody3D.new()
	cm.restore_player_to_checkpoint(player)
	var p_pos = player.global_position if player.is_inside_tree() else player.position
	assert_true(p_pos.distance_to(dummy_pos + Vector3(0, 0.5, 0)) < 0.1, "Player should be restored to checkpoint")
	player.free()
	cm.queue_free()

func test_campaign_manager_unlocks() -> void:
	var cm = CampaignManagerScript.new()
	cm.highest_unlocked_mission = 1
	cm.on_mission_completed(1, {"score": 15000, "grade": "S"})
	assert_true(cm.highest_unlocked_mission >= 2, "Mission 2 should unlock after Mission 1 complete")
	assert_true(cm.mission_grades.get("1") == "S", "Grade for mission 1 should be recorded")
	cm.queue_free()

func test_destructibles_and_environment() -> void:
	var prop = DestructiblePropScript.new()
	prop._ready()
	prop.take_damage(50.0)
	assert_true(prop.is_destroyed, "Destructible prop should be destroyed on fatal damage")
	prop.free()

	var env = EnvBuilderScript.build_segment_environment("urban", 0, 30.0, 10.0)
	assert_true(is_instance_valid(env), "Environment builder should return valid Node3D")
	env.free()

func test_setpiece_director() -> void:
	var sp = SetpieceDirectorScript.new()
	sp.duration_sec = 2.0
	sp.trigger_setpiece()
	assert_true(sp.is_active, "Setpiece should be active after trigger")
	sp._process(2.5)
	assert_true(sp.is_completed, "Setpiece should be complete after duration")
	sp.free()

func test_all_mission_builders() -> void:
	var m_builders = [M1Script, M2Script, M3Script, M4Script, M5Script, M6Script, M7Script, M8Script]
	for idx in range(m_builders.size()):
		var b = m_builders[idx]
		var segs = b.create_segments()
		assert_true(segs.size() >= 5, "Mission builder %d must create >= 5 segments" % (idx + 1))
		for s in segs:
			s.free()

func test_save_manager_integration() -> void:
	var dummy = Node.new()
	var sm = GameConstants.get_autoload(dummy, "SaveManager")
	if sm and sm.has_method("record_strike_vector_mission"):
		sm.record_strike_vector_mission(1, 12000, "S")
		sm.save_strike_vector_checkpoint(1, 2, 5000)
		var stats = sm.get_strike_vector_stats()
		assert_true(stats.get("highest_mission", 1) >= 1, "Stats should record highest mission")
	dummy.free()

func test_strike_campaign_menu() -> void:
	var menu = StrikeCampaignMenuScript.new()
	menu._ready()
	assert_true(is_instance_valid(menu), "Strike campaign menu should instantiate")
	menu.free()
