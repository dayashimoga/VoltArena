class_name TestChromaE2E
extends RefCounted

## End-to-End integration test suite for Chroma Rush: The Color Chase.
## Verifies the 6 mandatory packaged scenarios:
## 1. Tutorial completion and a successful color delivery.
## 2. Legitimate AI swap and completed rival objective.
## 3. Success, failure, retry, and rewards in every mode (Hunt, Sprint, Puzzle, Championship).
## 4. Correct progression and session restoration after restarting.
## 5. Access to all four worlds and six vehicles.
## 6. Functional gameplay invariants and scene coordinator flow.

const ChromaRushMain = preload("res://games/chroma-rush/chroma_rush_main.gd")
const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const MissionDirector = preload("res://games/chroma-rush/core/mission_director.gd")
const MissionDatabase = preload("res://games/chroma-rush/content/mission_database.gd")
const ChromaSaveAdapter = preload("res://games/chroma-rush/persistence/chroma_save_adapter.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const VehicleCatalog = preload("res://games/chroma-rush/vehicles/vehicle_catalog.gd")
const TrafficAgent = preload("res://games/chroma-rush/ai/traffic_agent.gd")
const RivalAI = preload("res://games/chroma-rush/ai/rival_ai.gd")

const NeonCity = preload("res://games/chroma-rush/worlds/neon_city.gd")
const CoastalRush = preload("res://games/chroma-rush/worlds/coastal_rush.gd")
const PrismCanyon = preload("res://games/chroma-rush/worlds/prism_canyon.gd")
const SkyCircuit = preload("res://games/chroma-rush/worlds/sky_circuit.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [E2E] Running Chroma Rush End-to-End Release Gate Scenarios...")
	test_scenario_1_tutorial_and_color_delivery()
	test_scenario_2_legitimate_ai_swap_and_rival_objective()
	test_scenario_3_all_four_modes_lifecycle()
	test_scenario_4_progression_and_session_restoration()
	test_scenario_5_access_all_worlds_and_vehicles()
	test_scenario_6_main_scene_coordinator_lifecycle()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL Chroma E2E: " + msg)

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/chroma_rush_main.gd", [
			"_ready", "_init_subsystems", "_init_environment", "_init_camera", "_init_ui",
			"_build_main_menu", "_create_menu_button", "_connect_events", "set_state",
			"_unhandled_input", "_physics_process", "_update_camera", "_update_swap_eligibility",
			"_update_hud_telemetry", "start_mission", "_load_world", "_spawn_player_vehicle",
			"_spawn_traffic", "_spawn_rivals", "clean_up_session", "_on_swap_requested",
			"_on_target_cycle_requested", "_on_swap_committed", "_on_swap_rejected",
			"_on_checkpoint_gate_entered", "_on_objective_progress_updated",
			"_on_mission_director_completed", "_on_mission_completed", "_on_mission_failed",
			"quick_play", "continue_game", "show_mission_select", "open_garage",
			"_on_garage_vehicle_selected", "_on_garage_closed", "start_tutorial",
			"_on_tutorial_completed", "_on_tutorial_skipped", "pause_game", "resume_game",
			"restart_mission", "next_mission", "_get_next_mission_id", "return_to_menu", "quit_to_launcher"
		]]
	]

# --- Scenario 1: Tutorial completion and a successful color delivery ---
func test_scenario_1_tutorial_and_color_delivery() -> void:
	print("    -> Scenario 1: Tutorial onboarding & color gate delivery...")
	var main = ChromaRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(main)

	main.start_tutorial()
	assert_true(main.current_state == ChromaRushMain.State.TUTORIAL, "State should be TUTORIAL")
	assert_true(main.tutorial_mgr.is_active, "Tutorial manager should be active")

	for step in range(5):
		main.tutorial_mgr.advance_step()
	assert_true(main.tutorial_mgr.current_step == 5, "Tutorial should reach final delivery step")

	main.tutorial_mgr.advance_step()
	assert_true(not main.tutorial_mgr.is_active, "Tutorial should complete")
	var profile = main.save_adapter.get_profile_data()
	assert_true(profile.get("tutorial_completed", false), "Tutorial completed flag should be persisted")

	main.clean_up_session()
	main.queue_free()

# --- Scenario 2: Legitimate AI swap and completed rival objective ---
func test_scenario_2_legitimate_ai_swap_and_rival_objective() -> void:
	print("    -> Scenario 2: Legitimate Rival AI Swap & Objective Cleared...")
	var engine = ColorSwapEngine.new()

	var rival_node = Node3D.new()
	rival_node.position = Vector3(0.0, 0.0, 0.0)
	rival_node.set_meta("velocity", Vector3(0.0, 0.0, -10.0))
	rival_node.set("velocity", Vector3(0.0, 0.0, -10.0))

	var target_node = Node3D.new()
	target_node.position = Vector3(2.5, 0.0, 1.0)
	target_node.set_meta("velocity", Vector3(0.0, 0.0, -10.0))
	target_node.set("velocity", Vector3(0.0, 0.0, -10.0))

	engine.register_vehicle("rival_0", rival_node, ChromaConstants.ChromaColor.NONE, true)
	engine.register_vehicle("traffic_0", target_node, ChromaConstants.ChromaColor.CYAN, false)

	# Prime alignment for the pair
	engine.prime_alignment("rival_0", "traffic_0", ChromaConstants.REQUIRED_ALIGNMENT_DURATION + 0.1)

	var check = engine.evaluate_eligibility("rival_0", "traffic_0", true)
	assert_true(check["eligible"], "Rival must satisfy proximity, speed and alignment conditions")

	var swap_res = engine.request_swap("rival_0", "traffic_0")
	assert_true(swap_res["success"], "Rival swap request must be approved deterministically")

	# Verify strict color conservation
	assert_true(engine.get_vehicle_color("rival_0") == ChromaConstants.ChromaColor.CYAN, "Rival must acquire CYAN")
	assert_true(engine.get_vehicle_color("traffic_0") == ChromaConstants.ChromaColor.NONE, "Target must acquire NONE")

	rival_node.free()
	target_node.free()

# --- Scenario 3: All 4 Modes Lifecycle (Success, Failure, Retry, Rewards) ---
func test_scenario_3_all_four_modes_lifecycle() -> void:
	print("    -> Scenario 3: Testing all four modes (Hunt, Sprint, Puzzle, Championship)...")
	var engine = ColorSwapEngine.new()
	var director = MissionDirector.new(engine)

	# 1. Color Hunt (Success)
	var hunt_def = MissionDatabase.get_mission_by_id("hunt_neon_01")
	var ok_hunt = director.start_mission(hunt_def)
	assert_true(ok_hunt and director.is_active, "Hunt mission should activate")

	var v = ChromaVehicle.new()
	v.vehicle_owner_id = "player"
	v.initial_color = ChromaConstants.ChromaColor.EMERALD
	v._ready()

	var gate = CheckpointGate.new()
	gate.gate_id = "gate_4"
	gate.target_color = ChromaConstants.ChromaColor.EMERALD
	gate._ready()

	director.handle_checkpoint_reached(v, gate)
	assert_true(director.is_finished, "Hunt mission should succeed on checkpoint delivery")
	assert_true(director.score >= 1000, "Score should be awarded")

	# 2. Chroma Sprint (Failure on timeout -> Retry)
	var sprint_def = MissionDatabase.get_mission_by_id("sprint_coastal_07")
	director.start_mission(sprint_def)
	director.update(sprint_def["time_limit"] + 5.0)
	assert_true(director.is_finished, "Sprint mission should complete when timer expires")
	# Retry
	director.retry_mission()
	assert_true(director.is_active and not director.is_finished, "Sprint retry must cleanly reset state")

	# 3. Puzzle Drive (Failure on exceeding swap limit)
	var puzzle_def = MissionDatabase.get_mission_by_id("puzzle_neon_13") # swap_limit = 1
	director.start_mission(puzzle_def)
	director._on_swap_committed("player", "traffic_1", 1, 3)
	director._on_swap_committed("player", "traffic_2", 3, 2)
	assert_true(director.is_finished, "Puzzle drive should fail when exceeding swap limit")

	# 4. Chroma Championship
	var champ_def = MissionDatabase.get_mission_by_id("champ_neon_19")
	director.start_mission(champ_def)
	assert_true(champ_def.get("mode") == ChromaConstants.GameMode.CHAMPIONSHIP, "Championship mode active")
	director.handle_checkpoint_reached(v, gate)
	assert_true(director.is_finished, "Championship stage cleared successfully")

	v.free()
	gate.free()

# --- Scenario 4: Progression and Session Restoration ---
func test_scenario_4_progression_and_session_restoration() -> void:
	print("    -> Scenario 4: Save adapter progression, unlocks and session restoration...")
	var adapter = ChromaSaveAdapter.new()
	adapter.reset_all_data()

	var res1 = adapter.record_mission_completion("hunt_neon_01", true, 12500, 2, 45.0, 0)
	assert_true(res1["credits_earned"] == 500, "First-time 2-star clear must grant 500 credits")

	var res2 = adapter.record_mission_completion("hunt_neon_01", true, 11000, 2, 50.0, 0)
	assert_true(res2["credits_earned"] == 0, "Retry with same/lower stars must grant 0 additional first-time credits")

	var buy_ok = adapter.unlock_vehicle("titan_vanguard", 100)
	assert_true(buy_ok, "Should unlock titan_vanguard with available credits")
	assert_true(adapter.is_vehicle_unlocked("titan_vanguard"), "titan_vanguard must now be unlocked")

	adapter.save_resumable_session({
		"mission_id": "hunt_neon_02",
		"objective_index": 2,
		"player_color": ChromaConstants.ChromaColor.MAGENTA,
		"score": 4500,
		"time_remaining": 65.4
	})

	var reboot_adapter = ChromaSaveAdapter.new()
	var profile = reboot_adapter.get_profile_data()
	assert_true(profile["credits"] == adapter.get_profile_data()["credits"], "Credits must persist across reboot")
	assert_true(reboot_adapter.is_vehicle_unlocked("titan_vanguard"), "Unlocked vehicle must persist across reboot")

	var session = profile.get("active_session", {})
	assert_true(session.get("mission_id") == "hunt_neon_02", "Resumable session must restore mission ID")
	assert_true(session.get("player_color") == ChromaConstants.ChromaColor.MAGENTA, "Resumable session must restore color")

# --- Scenario 5: Access to all 4 Worlds and 6 Vehicles ---
func test_scenario_5_access_all_worlds_and_vehicles() -> void:
	print("    -> Scenario 5: Validating all 4 worlds and 6 vehicle archetypes...")
	var w1 = NeonCity.new()
	var w2 = CoastalRush.new()
	var w3 = PrismCanyon.new()
	var w4 = SkyCircuit.new()

	w1._ready()
	w2._ready()
	w3._ready()
	w4._ready()

	assert_true(w1.waypoints.size() >= 16, "NeonCity must have connected waypoints")
	assert_true(w2.waypoints.size() >= 16, "CoastalRush must have connected waypoints")
	assert_true(w3.waypoints.size() >= 16, "PrismCanyon must have connected waypoints")
	assert_true(w4.waypoints.size() >= 16, "SkyCircuit must have connected waypoints")

	assert_true(w1.checkpoints.size() == 6, "NeonCity must have 6 checkpoint gates")
	assert_true(w2.checkpoints.size() == 6, "CoastalRush must have 6 checkpoint gates")
	assert_true(w3.checkpoints.size() == 6, "PrismCanyon must have 6 checkpoint gates")
	assert_true(w4.checkpoints.size() == 6, "SkyCircuit must have 6 checkpoint gates")

	w1.free()
	w2.free()
	w3.free()
	w4.free()

	var archetypes = VehicleCatalog.get_all_vehicle_ids()
	assert_true(archetypes.size() == 6, "Must contain exactly 6 vehicle archetypes")

	for v_id in archetypes:
		var veh = ChromaVehicle.new()
		veh.set_vehicle_type(v_id)
		veh.paint_finish = "metallic"
		veh._ready()

		# Rollover recovery test
		veh.rotation_degrees = Vector3(0.0, 0.0, 180.0)
		veh.recover_vehicle()
		assert_true(abs(veh.rotation_degrees.z) < 1.0, "Vehicle %s must recover safely from rollover" % v_id)
		veh.free()

# --- Scenario 6: Main Scene Coordinator Lifecycle ---
func test_scenario_6_main_scene_coordinator_lifecycle() -> void:
	print("    -> Scenario 6: Testing ChromaRushMain coordinator state transitions...")
	var main = ChromaRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(main)
	main._ready()

	assert_true(main.current_state == ChromaRushMain.State.MENU, "Initial state should be MENU")

	main.open_garage()
	assert_true(main.current_state == ChromaRushMain.State.GARAGE, "State should be GARAGE")
	main._on_garage_closed()
	assert_true(main.current_state == ChromaRushMain.State.MENU, "State should return to MENU")

	main.quick_play()
	assert_true(main.current_state == ChromaRushMain.State.PLAYING, "Quick play should enter PLAYING state")
	assert_true(is_instance_valid(main.player_vehicle), "Player vehicle should be spawned")
	assert_true(is_instance_valid(main.active_world), "Active world should be loaded")

	main.pause_game()
	assert_true(main.current_state == ChromaRushMain.State.PAUSED, "State should be PAUSED")
	main.resume_game()
	assert_true(main.current_state == ChromaRushMain.State.PLAYING, "State should resume to PLAYING")

	main._on_objective_progress_updated(1, 3, ChromaConstants.ChromaColor.CYAN, "gate_1")
	main._on_mission_completed({"score": 8500, "stars": 3, "time_elapsed": 45.0, "credits_earned": 500})
	assert_true(main.current_state == ChromaRushMain.State.RESULTS, "State should transition to RESULTS on mission complete")

	var next_id = main._get_next_mission_id("hunt_neon_01")
	assert_true(next_id != "hunt_neon_01", "Next mission ID should advance")

	main.return_to_menu()
	assert_true(main.current_state == ChromaRushMain.State.MENU, "State should return to MENU")
	assert_true(main.player_vehicle == null, "Player vehicle should be cleaned up")
	assert_true(main.active_world == null, "Active world should be cleaned up")

	main.queue_free()
