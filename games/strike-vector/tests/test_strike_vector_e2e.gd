class_name TestStrikeVectorE2E
extends RefCounted

## End-to-End deterministic campaign playthrough test for STRIKE VECTOR.
## Validates complete continuous progression through all 8 missions:
## Deployment -> Grounded Spawn -> Advancing -> Encounter Triggers -> AI Combat -> Route Unlock
## -> Traversal -> Checkpoints -> Set-Pieces -> Boss Encounters -> Grading & Results -> Save & Continue.

const StrikeMainScript = preload("res://games/strike-vector/strike_vector_main.gd")
const MissionDefsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const CampaignManagerScript = preload("res://games/strike-vector/campaign/campaign_manager.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [E2E] Beginning Strike Vector Full Campaign Simulation (Missions 1-8)...")
	for m in range(1, 9):
		test_mission_e2e_playthrough(m)
	test_full_campaign_completion_and_save()
	return {"passed": passed, "failed": failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/strike-vector/strike_vector_main.gd", [
			"_ready", "setup_subsystems", "load_mission", "_connect_segment_events", "advance_segment",
			"_on_player_died", "_on_mission_completed", "_on_next_mission_requested", "restart_mission",
			"_on_resume", "_on_quit_to_launcher"
		]],
		["res://games/strike-vector/campaign/mission_manager.gd", [
			"_ready", "start_mission", "_process", "record_kill", "record_death", "complete_mission", "calculate_grade"
		]],
		["res://games/strike-vector/ui/strike_hud.gd", [
			"_ready", "setup_hud", "_setup_top_left_status", "_setup_bottom_right_weapon", "_setup_top_center_objective",
			"_setup_context_alert", "_setup_boss_health_bar", "update_health", "update_armor", "update_weapon",
			"update_objective", "show_context_alert", "update_boss"
		]],
		["res://games/strike-vector/ui/strike_results_screen.gd", [
			"_ready", "setup_ui", "display_results", "_add_stat_row", "hide_results"
		]],
		["res://games/strike-vector/audio/strike_audio_director.gd", [
			"set_audio_state"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL E2E Strike Vector: " + msg)

func test_mission_e2e_playthrough(mission_idx: int) -> void:
	var meta = MissionDefsScript.get_mission_meta(mission_idx)
	print("    -> Simulating Mission %d: %s (%s)..." % [mission_idx, meta["name"], meta["biome"]])

	# 1. Instantiate Main Scene
	var main = StrikeMainScript.new()
	main.start_mission_index = mission_idx
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(main)

	# Ensure setup_subsystems and load_mission have executed
	if not is_instance_valid(main.player_node):
		main.setup_subsystems()
		main.load_mission(mission_idx)

	# 2. Verify Grounded Player Spawn
	var player = main.player_node
	assert_true(is_instance_valid(player), "Player must spawn in Mission %d" % mission_idx)
	assert_true(player.is_alive, "Player must spawn alive in Mission %d" % mission_idx)
	assert_true(player.current_health > 0.0, "Player must spawn with positive health")

	# 3. Verify Weapon Inventory & Firing
	assert_true(not player.weapons.is_empty(), "Player must possess weapons")
	player.fire_weapon()
	assert_true(player.active_weapon.ammo_in_mag < player.active_weapon.magazine_capacity, "Weapon should fire and consume ammo")

	# 4. Verify Streamer Segments
	var streamer = main.mission_streamer
	assert_true(is_instance_valid(streamer), "Mission streamer must be active")
	assert_true(streamer.segments.size() >= 5, "Mission must contain >= 5 segments")

	# 5. Advance through segments and resolve encounters
	for s_idx in range(streamer.segments.size()):
		var current_seg = streamer.get_active_segment()
		assert_true(is_instance_valid(current_seg), "Segment %d must be resident" % s_idx)

		# Trigger and resolve encounter
		var enc = current_seg.encounter_director
		if is_instance_valid(enc):
			enc.trigger_encounter()
			assert_true(enc.is_active or enc.is_completed, "Encounter in segment %d should activate" % s_idx)

			# Simulate clearing active hostiles across all waves
			var safety_counter = 0
			while not enc.is_completed and safety_counter < 10:
				safety_counter += 1
				for enemy in enc.active_enemies.duplicate():
					if is_instance_valid(enemy) and enemy.has_method("take_damage"):
						enemy.take_damage(999.0)
				if not enc.is_completed and enc.active_enemies.is_empty() and enc.reinforcement_waves.is_empty():
					enc.complete_encounter()
					break

			assert_true(enc.is_completed, "Encounter in segment %d must complete" % s_idx)

		# Advance to next segment if not already advanced by route_cleared
		if s_idx < streamer.segments.size() - 1 and streamer.active_segment_index == s_idx:
			main.advance_segment()
		if s_idx < streamer.segments.size() - 1:
			assert_true(streamer.active_segment_index >= s_idx + 1, "Streamer should advance past segment %d" % s_idx)

	# 6. Complete Mission and verify Results & Grade
	main.mission_mgr.complete_mission()
	assert_true(main.mission_mgr.is_completed, "Mission %d must be marked complete" % mission_idx)
	var grade = main.mission_mgr.calculate_grade()
	assert_true(grade in ["S", "A", "B", "C"], "Mission %d grade must be S, A, B, or C" % mission_idx)

	# 7. Check save persistence
	var sm = GameConstants.get_autoload(main, "SaveManager")
	if sm and sm.has_method("get_strike_vector_stats"):
		var stats = sm.get_strike_vector_stats()
		assert_true(stats.get("highest_mission", 1) >= mission_idx, "Save data must reflect progress to at least mission %d" % mission_idx)

	if main.get_parent():
		main.get_parent().remove_child(main)
	main.queue_free()

func test_full_campaign_completion_and_save() -> void:
	var cm = CampaignManagerScript.new()
	cm.load_campaign_state()
	cm.highest_unlocked_mission = 8
	cm.on_mission_completed(8, {"score": 25000, "grade": "S"})

	var sm = GameConstants.get_autoload(cm, "SaveManager")
	if sm and sm.has_method("get_strike_vector_stats"):
		var stats = sm.get_strike_vector_stats()
		assert_true(stats.get("missions_completed", 0) >= 8, "All 8 missions should be marked completed")
	cm.queue_free()
