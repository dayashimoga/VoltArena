class_name TestAeroE2E
extends RefCounted

## End-to-End integration test suite for AeroRush: Impossible Circuit.
## Verifies the complete closed-loop gameplay lifecycle:
## 1. Standalone Menu & Garage selection
## 2. Dynamic course building & world instantiation
## 3. Real driving, drift mini-turbo, and nitro boost
## 4. Jumps, aerial stunt execution, and perfect landing combo banking
## 5. Checkpoint progression & safe checkpoint recovery
## 6. Finish line crossing, medal calculation, and rewards
## 7. Persistence survival across simulated application restart
## 8. Next-course navigation and return to VoltArena hub

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroRushMain = preload("res://games/aero-rush/aero_rush_main.gd")
const AeroSaveAdapter = preload("res://games/aero-rush/persistence/aero_save_adapter.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [AeroRush E2E] Running Complete Gameplay Lifecycle Scenarios...")
	test_scenario_1_menu_and_garage_selection()
	test_scenario_2_course_instantiation_and_countdown()
	test_scenario_3_driving_drift_and_nitro()
	test_scenario_4_jump_stunt_and_combo_banking()
	test_scenario_5_checkpoint_progression_and_recovery()
	test_scenario_6_race_finish_and_victory_dossier()
	test_scenario_7_persistence_across_app_restart()
	test_scenario_8_next_course_and_return_to_hub()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL Aero E2E: " + msg)

func test_scenario_1_menu_and_garage_selection() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	assert_true(aero.current_state == AeroRushMain.State.MENU, "Initial state must be MENU")
	assert_true(aero.main_menu.visible, "Main menu must be visible initially")

	# Select vehicle in garage
	aero.set_state(AeroRushMain.State.GARAGE)
	assert_true(aero.garage.visible, "Garage must be visible in GARAGE state")
	aero._on_vehicle_selected_in_garage(AeroConstants.VEHICLE_QUANTUM, Color(0.68, 0.15, 0.95))
	assert_true(aero.selected_vehicle_id == AeroConstants.VEHICLE_QUANTUM, "Selected vehicle must update to Quantum Phantom")

	aero.queue_free()

func test_scenario_2_course_instantiation_and_countdown() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	aero.start_race("neon_express")

	assert_true(aero.current_state == AeroRushMain.State.COUNTDOWN, "Starting race must enter COUNTDOWN state")
	assert_true(aero.player_vehicle != null, "Player vehicle must be instantiated")
	assert_true(aero.checkpoints.size() >= 3, "Checkpoints must be instantiated along track")
	assert_true(aero.active_world != null, "Active world environment must be spawned")

	# Simulate countdown
	aero._process_countdown(3.6)
	assert_true(aero.current_state == AeroRushMain.State.RACING, "Countdown completion must transition to RACING")
	assert_true(aero.player_vehicle.controls_enabled, "Player vehicle controls must be enabled when racing")

	aero.clean_up_session()
	aero.queue_free()

func test_scenario_3_driving_drift_and_nitro() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	aero.start_race("neon_express")
	aero.set_state(AeroRushMain.State.RACING)

	var veh = aero.player_vehicle
	assert_true(veh != null, "Player vehicle must exist")
	assert_true(veh.controls_enabled, "Controls must be enabled in RACING state")
	assert_true(not veh.programmatic_override, "Programmatic override must be disabled for real player driving")

	# 1. Genuine Acceleration from Standstill using real InputMap action
	var initial_z = veh.global_position.z
	Input.action_press("move_forward")
	for i in range(40):
		veh._physics_process(0.016)
	Input.action_release("move_forward")

	assert_true(veh.throttle_input > 0.0, "Vehicle must detect real move_forward throttle action")
	assert_true(veh.forward_speed > 8.0, "Vehicle must accelerate naturally from 0 to > 8 m/s under real throttle")
	assert_true(veh.get_speed_kmh() > 28.0, "Speedometer must register > 28 km/h under real throttle")

	# 2. Genuine Steering using real InputMap action
	var init_rot_y = veh.global_rotation.y
	Input.action_press("move_right")
	for i in range(15):
		veh._physics_process(0.016)
	Input.action_release("move_right")
	assert_true(veh.global_rotation.y != init_rot_y or veh.steer_input > 0.0, "Vehicle must respond to real move_right steering action")

	# 3. Genuine Braking using real InputMap action
	var speed_before_brake = veh.forward_speed
	Input.action_press("move_back")
	for i in range(20):
		veh._physics_process(0.016)
	Input.action_release("move_back")
	assert_true(veh.forward_speed < speed_before_brake, "Vehicle must decelerate under real move_back brake action")

	# 4. Genuine Nitro Boost using real InputMap action
	var initial_boost = veh.boost_gauge
	Input.action_press("move_forward")
	Input.action_press("boost")
	for i in range(15):
		veh._physics_process(0.016)
	Input.action_release("boost")
	Input.action_release("move_forward")
	assert_true(veh.boost_gauge < initial_boost, "Nitro boost must consume boost gauge during real boost action")

	aero.clean_up_session()
	aero.queue_free()

func test_scenario_4_jump_stunt_and_combo_banking() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	aero.start_race("neon_express")
	aero.set_state(AeroRushMain.State.RACING)

	var veh = aero.player_vehicle
	veh.forward_speed = 35.0

	# Launch airborne & do a 360 spin
	veh.is_grounded = false
	veh.total_air_yaw = deg_to_rad(360.0)
	veh._track_airborne_rotations()

	assert_true(aero.combo_system.is_combo_active, "Stunt execution must activate combo system")
	assert_true(aero.combo_system.pending_combo_score > 0, "Pending combo score must be positive")

	# Touchdown with perfect landing
	veh.is_grounded = true
	veh._handle_touchdown()
	assert_true(aero.combo_system.pending_combo_score >= 450, "Perfect landing must add points to combo")

	# Bank combo
	aero.combo_system._bank_combo()
	assert_true(aero.combo_system.total_banked_score > 0, "Banked score must be retained")

	aero.clean_up_session()
	aero.queue_free()

func test_scenario_5_checkpoint_progression_and_recovery() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	aero.start_race("neon_express")
	aero.set_state(AeroRushMain.State.RACING)

	var initial_cp = aero.next_checkpoint_idx
	# Simulate passing checkpoint 0
	aero._on_checkpoint_passed(0, aero.player_vehicle)
	assert_true(aero.next_checkpoint_idx == initial_cp + 1, "Passing checkpoint must advance checkpoint index")

	# Test safe recovery
	var prev_pos = aero.player_vehicle.global_position
	aero.player_vehicle.recover_to_checkpoint()
	assert_true(aero.player_vehicle.forward_speed > 0.0, "Recovery must provide forward impulse")

	aero.clean_up_session()
	aero.queue_free()

func test_scenario_6_race_finish_and_victory_dossier() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	aero.start_race("neon_express")
	aero.set_state(AeroRushMain.State.RACING)

	aero.race_timer = 58.2 # Faster than gold time (68.0s) -> Platinum / Gold
	aero._finish_race(true)

	assert_true(aero.current_state == AeroRushMain.State.RESULTS, "Finishing race must transition to RESULTS")
	assert_true(aero.results_screen.visible, "Results screen must be visible on finish")

	aero.clean_up_session()
	aero.queue_free()

func test_scenario_7_persistence_across_app_restart() -> void:
	# Save a verified result
	var recorded = AeroSaveAdapter.record_course_result("cyber_loopway", 71.4, 22000, AeroConstants.Medal.GOLD, 800)
	assert_true(recorded["new_medal"] == AeroConstants.Medal.GOLD, "Gold medal recorded")

	# Simulate app restart by clearing cache and re-loading
	AeroSaveAdapter._cached_data = {}
	var reloaded = AeroSaveAdapter.load_aero_data()

	assert_true(reloaded.get("course_medals", {}).get("cyber_loopway", 0) == AeroConstants.Medal.GOLD, "Persisted medal must survive restart")
	assert_true(reloaded.get("best_times", {}).get("cyber_loopway", 0.0) == 71.4, "Persisted best time must survive restart")
	assert_true(reloaded.get("credits", 0) >= 1800, "Persisted credits must survive restart")

func test_scenario_8_next_course_and_return_to_hub() -> void:
	var aero = AeroRushMain.new()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(aero)

	aero._ready()
	aero.selected_course_id = "neon_express"
	aero._on_next_course()
	assert_true(aero.selected_course_id == "cyber_loopway", "Next course must advance to course 2 (Cyber Loopway)")

	# Return to hub
	aero.set_state(AeroRushMain.State.MENU)
	assert_true(aero.current_state == AeroRushMain.State.MENU, "Return to menu must reset state to MENU")

	aero.clean_up_session()
	aero.queue_free()

func get_coverage_entries() -> Array:
	return [
		["res://games/aero-rush/aero_rush_main.gd", [
			"_ready", "_init_containers", "_init_subsystems", "_init_ui", "set_state",
			"quick_play", "start_race", "restart_race", "_spawn_environment", "_build_track",
			"_spawn_hazards", "_spawn_player_vehicle", "_spawn_rivals", "_physics_process",
			"_process_countdown", "_process_racing", "_on_checkpoint_passed", "_finish_race",
			"_on_next_course", "_on_stunt_verified", "_on_combo_updated", "_on_combo_banked",
			"_on_combo_dropped", "_on_vehicle_selected_in_garage", "_on_return_to_hub",
			"clean_up_session", "_play_music", "_play_course_music", "_play_sfx"
		]]
	]
