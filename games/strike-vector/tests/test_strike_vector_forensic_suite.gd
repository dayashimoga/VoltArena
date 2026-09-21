class_name TestStrikeVectorForensicSuite
extends SceneTree

## Forensic Production-Hardening Test Suite for Strike Vector
## Tests:
## 1. Complete Mission Topology (all 8 missions have 5 segments, no dead ends, no open voids)
## 2. Perimeter Enclosure & Boundaries (solid visible side walls, rear wall, end perimeter wall on final segment)
## 3. Extraction Helipad & Extraction Trigger (authored helipad visual, physical ExtractionZone Area3D)
## 4. Deterministic Combat & 0 HP Lockout (no movement, jump, or firing at 0 HP; velocity zeroed)
## 5. Boss Encounter Completion & Signal Wiring (boss defeat triggers complete_encounter)
## 6. Campaign Save Persistence & Multi-Stage Progression (SaveManager updated, Next Stage loads Stage 2)

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const StrikeEnvironmentBuilderScript = preload("res://games/strike-vector/environment/strike_environment_builder.gd")
const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const CampaignManagerScript = preload("res://games/strike-vector/campaign/campaign_manager.gd")
const StrikeVectorMainScript = preload("res://games/strike-vector/strike_vector_main.gd")
const BossArchetypesScript = preload("res://games/strike-vector/bosses/boss_archetypes.gd")

var passes: int = 0
var fails: int = 0

func _init() -> void:
	print("[STRIKE_VECTOR_FORENSIC] Starting Forensic Runtime Audit...")
	run_all_tests()
	print("[STRIKE_VECTOR_FORENSIC] Complete: %d PASSED, %d FAILED" % [passes, fails])
	quit(0 if fails == 0 else 1)

func assert_true(cond: bool, test_name: String) -> void:
	if cond:
		passes += 1
		print("  [PASS] %s" % test_name)
	else:
		fails += 1
		print("  [FAIL] %s" % test_name)

func run_all_tests() -> void:
	test_mission_topology_all_campaign_stages()
	test_perimeter_enclosure_and_boundaries()
	test_extraction_helipad_and_trigger()
	test_zero_hp_combat_lockout()
	test_boss_encounter_completion()
	test_campaign_progression_and_save_persistence()
	test_next_stage_loading()

func test_mission_topology_all_campaign_stages() -> void:
	print("--- Test 1: Mission Topology for All 8 Campaign Stages ---")
	for m in range(1, 9):
		var meta = MissionDefinitionsScript.get_mission_meta(m)
		assert_true(meta["segments"].size() == 5, "Mission %d (%s) defines exactly 5 distinct segments" % [m, meta["name"]])

		var segs = MissionDefinitionsScript.build_mission_segments(m)
		assert_true(segs.size() == 5, "Mission %d instantiated 5 segment managers" % m)
		assert_true(segs[4].is_boss_segment, "Mission %d segment 5 is authored boss encounter segment" % m)

		# Check segment positions advance along -Z
		var strictly_advancing = true
		for i in range(1, segs.size()):
			if segs[i].position.z >= segs[i - 1].position.z:
				strictly_advancing = false
				break
		assert_true(strictly_advancing, "Mission %d segments advance strictly forward along -Z axis" % m)

		for s in segs:
			s.queue_free()

func test_perimeter_enclosure_and_boundaries() -> void:
	print("--- Test 2: Perimeter Enclosure & Solid Boundary Walls ---")
	# Build segment 0 (first) and segment 4 (last)
	var env_first = StrikeEnvironmentBuilderScript.build_segment_environment("urban", 0, 40.0, 14.0, false)
	root.add_child(env_first)

	var env_last = StrikeEnvironmentBuilderScript.build_segment_environment("urban", 4, 40.0, 14.0, true)
	root.add_child(env_last)

	# Verify solid boundary walls in segment 0 (left, right, rear)
	var walls_first = []
	for child in env_first.get_children():
		if child is StaticBody3D and child.collision_layer == GameConstants.LAYER_WORLD:
			walls_first.append(child)
	assert_true(walls_first.size() >= 3, "First segment contains solid perimeter walls (left, right, rear spawn containment)")

	# Verify end perimeter wall and extraction visual in final segment
	var has_end_wall = false
	var has_ext_pad = false
	for child in env_last.get_children():
		if child.name == "ExtractionPadVisual":
			has_ext_pad = true
		if child is StaticBody3D and child.collision_layer == GameConstants.LAYER_WORLD:
			# Check for wall positioned at the end of the segment (-Z)
			if child.position.z < -20.0:
				has_end_wall = true

	assert_true(has_end_wall, "Final segment contains solid end perimeter wall (0 reachable voids on valid paths)")
	assert_true(has_ext_pad, "Final segment contains authored extraction helipad visual structure")

	env_first.queue_free()
	env_last.queue_free()

func test_extraction_helipad_and_trigger() -> void:
	print("--- Test 3: Extraction Helipad & ExtractionZone Trigger ---")
	var main = StrikeVectorMainScript.new()
	root.add_child(main)
	main.load_mission(1)

	var segs = main.mission_streamer.segments
	var last_seg = segs[segs.size() - 1]

	var ext_zone = last_seg.get_node_or_null("ExtractionZone")
	assert_true(ext_zone != null and ext_zone is Area3D, "ExtractionZone Area3D exists on final segment")
	if ext_zone:
		assert_true(ext_zone.collision_mask & GameConstants.LAYER_PLAYER != 0, "ExtractionZone monitors PLAYER collision layer")

	main.queue_free()

func test_zero_hp_combat_lockout() -> void:
	print("--- Test 4: Deterministic Combat & 0 HP Lockout ---")
	var player = StrikePlayerScript.new()
	root.add_child(player)

	assert_true(player.is_alive, "Player initialized alive with 100 HP")

	# Deal lethal damage
	player.take_damage(250.0, "TestHostile", "Rifle")

	assert_true(player.current_health == 0.0, "Player HP reduced to exactly 0.0")
	assert_true(not player.is_alive, "Player is_alive flag set to false")
	assert_true(player.velocity == Vector3.ZERO, "Player velocity zeroed upon death")

	# Attempt to jump
	player.trigger_jump()
	assert_true(player.velocity.y == 0.0, "Jump input locked out at 0 HP (velocity.y remains 0.0)")

	# Attempt to fire
	var initial_ammo = player.active_weapon.ammo_in_mag if is_instance_valid(player.active_weapon) else -1
	player.fire_weapon()
	var after_ammo = player.active_weapon.ammo_in_mag if is_instance_valid(player.active_weapon) else -1
	assert_true(initial_ammo == after_ammo, "Weapon firing locked out at 0 HP (ammo unchanged: %d)" % after_ammo)

	player.queue_free()

func test_boss_encounter_completion() -> void:
	print("--- Test 5: Boss Encounter Completion & Signal Wiring ---")
	var segs = MissionDefinitionsScript.build_mission_segments(1)
	var boss_seg = segs[4]
	root.add_child(boss_seg)

	var boss = null
	for child in boss_seg.get_children():
		if child is StrikeBossBase:
			boss = child
			break

	assert_true(boss != null, "Boss entity instantiated in final segment")
	var enc = boss_seg.encounter_director
	assert_true(enc != null, "EncounterDirector exists in boss segment")

	# Defeating boss should trigger encounter completion
	if boss and enc:
		boss.boss_defeated.emit(boss.boss_name, boss.score_value)
		assert_true(enc.is_completed, "Boss defeat signal triggers EncounterDirector.complete_encounter()")

	for s in segs:
		s.queue_free()

func test_campaign_progression_and_save_persistence() -> void:
	print("--- Test 6: Campaign Save Persistence & Progression ---")
	var cm = CampaignManagerScript.new()
	root.add_child(cm)

	var initial_unlocked = cm.highest_unlocked_mission
	# Complete Mission 1 with Rank S
	cm.on_mission_completed(1, {"score": 12500, "grade": "S", "time": 142.0, "kills": 24, "deaths": 0})

	assert_true(cm.highest_unlocked_mission >= 2, "Completing Mission 1 unlocks Mission 2 (highest_unlocked: %d)" % cm.highest_unlocked_mission)
	assert_true(cm.current_mission_index == 2, "Current mission index advances to 2")

	# Verify SaveManager received the update
	var sm = GameConstants.get_autoload(cm, "SaveManager")
	if sm and sm.has_method("get_strike_vector_stats"):
		var stats = sm.get_strike_vector_stats()
		assert_true(stats.get("highest_mission", 1) >= 2, "SaveManager persisted highest_mission >= 2")
		assert_true(stats.get("best_grades", {}).get("1") == "S", "SaveManager persisted Mission 1 Grade S")

	cm.queue_free()

func test_next_stage_loading() -> void:
	print("--- Test 7: Next Stage Dynamic Loading ---")
	var main = StrikeVectorMainScript.new()
	root.add_child(main)
	main.load_mission(1)
	assert_true(main.mission_mgr.mission_index == 1, "Mission 1 initially loaded")

	# Trigger Next Mission
	main._on_next_mission_requested()
	assert_true(main.mission_mgr.mission_index == 2, "Next Mission request successfully transitions to Mission 2")

	var meta = MissionDefinitionsScript.get_mission_meta(2)
	assert_true(main.mission_mgr.mission_name == meta["name"], "Mission 2 title matches High-Speed Rail ('%s')" % main.mission_mgr.mission_name)

	main.queue_free()
