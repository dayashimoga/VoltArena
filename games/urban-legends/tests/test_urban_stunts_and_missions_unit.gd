class_name TestUrbanStuntsAndMissionsUnit
extends RefCounted

## Unit test suite for Urban Legends stunt detection, combo scoring,
## 6 mission archetypes, career progression, garage unlocks, and achievements.

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicle = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const StuntDetector = preload("res://games/urban-legends/gameplay/stunt_detector.gd")
const MissionDirector = preload("res://games/urban-legends/gameplay/mission_director.gd")
const ProgressionManager = preload("res://games/urban-legends/gameplay/progression_manager.gd")
const UrbanDistrictDefinitions = preload("res://games/urban-legends/world/urban_district_definitions.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanStuntsAndMissionsUnit ---")
	test_stunt_detector_jump_scoring()
	test_stunt_detector_flips_and_rolls()
	test_drift_combo_accumulation_and_banking()
	test_all_six_missions_initialization()
	test_mission_checkpoint_advancement_and_completion()
	test_mission_time_limit_failure()
	test_progression_manager_wallet_and_upgrades()
	test_vehicle_unlocking_and_achievements()

	return {
		"total": total_assertions,
		"passed": passed_assertions,
		"failed": failed_assertions
	}

func assert_true(condition: bool, msg: String) -> void:
	total_assertions += 1
	if condition:
		passed_assertions += 1
		print("  [PASS] " + msg)
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg)
		push_error("Assertion failed: %s" % msg)

func test_stunt_detector_jump_scoring() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	var save = UrbanSaveData.new()
	var detector = StuntDetector.new()
	detector.setup(car, save)

	var captured = {"title": "", "cash": 0}
	detector.stunt_rewarded.connect(func(title: String, cash: int, _details: Dictionary):
		captured["title"] = title
		captured["cash"] = cash
	)

	# Simulate 50m airborne launch
	car.position = Vector3(0, 5.0, 0)
	detector._on_airborne_started()

	car.position = Vector3(50.0, 1.0, 0)
	detector._on_stunt_landed("Smooth", 8.0, 1.4)

	assert_true(captured["cash"] > 0, "50m jump must award stunt cash (was: %d)" % captured["cash"])
	assert_true(captured["title"].contains("MONSTER JUMP") or captured["title"].contains("BIG AIR"), "Jump title must describe jump scale (was: %s)" % captured["title"])
	assert_true(save.career_cash >= captured["cash"], "Awarded cash must be banked in player save data")

	car.free()

func test_stunt_detector_flips_and_rolls() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	var save = UrbanSaveData.new()
	var detector = StuntDetector.new()
	detector.setup(car, save)

	var captured = {"title": "", "cash": 0}
	detector.stunt_rewarded.connect(func(title: String, cash: int, _details: Dictionary):
		captured["title"] = title
		captured["cash"] = cash
	)

	car.position = Vector3(0, 10.0, 0)
	detector._on_airborne_started()

	# 1 Full pitch flip (360 deg) and 1 barrel roll (360 deg)
	car.total_air_pitch_deg = 360.0
	car.total_air_roll_deg = 360.0
	car.position = Vector3(30.0, 1.0, 0)

	detector._on_stunt_landed("Good", 6.0, 1.8)

	assert_true(captured["title"].contains("FLIP"), "Title must recognize flip trick (was: %s)" % captured["title"])
	assert_true(captured["title"].contains("BARREL ROLL"), "Title must recognize barrel roll trick (was: %s)" % captured["title"])
	assert_true(captured["cash"] >= 200, "Flip + Roll combo must award >= $200 cash (was: %d)" % captured["cash"])

	car.free()

func test_drift_combo_accumulation_and_banking() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	car.force_grounded_for_testing = true
	var save = UrbanSaveData.new()
	var detector = StuntDetector.new()
	detector.setup(car, save)

	var initial_cash = save.career_cash

	# Simulate active high-speed drifting
	car.is_drifting = true
	car.forward_speed = 30.0
	car.drift_angle_deg = 35.0

	for _i in range(60): # 1 second of drifting
		detector.process_stunt_frame(1.0 / 60.0)

	assert_true(detector.current_drift_score > 50.0, "Drift score should accumulate over 1 second (was: %f)" % detector.current_drift_score)
	assert_true(detector.drift_multiplier > 1.2, "Drift multiplier should increase during drift (was: %f)" % detector.drift_multiplier)

	# End drift and let combo timer expire to bank points
	car.is_drifting = false
	detector.process_stunt_frame(2.0)

	assert_true(save.career_cash > initial_cash, "Banking drift combo must award cash to player wallet")
	assert_true(detector.current_drift_score == 0.0, "Drift score resets to 0 after banking")

	car.free()

func test_all_six_missions_initialization() -> void:
	var ids = MissionDirector.get_all_mission_ids()
	assert_true(ids.size() == 6, "Must define exactly 6 mission archetypes (found: %d)" % ids.size())
	assert_true(ids.has(UrbanConstants.MISSION_CIRCUIT_RACE), "Circuit Race must exist")
	assert_true(ids.has(UrbanConstants.MISSION_DRIFT_TRIAL), "Drift Trial must exist")
	assert_true(ids.has(UrbanConstants.MISSION_HILL_CLIMB), "Hill Climb must exist")
	assert_true(ids.has(UrbanConstants.MISSION_COURIER), "Courier Delivery must exist")
	assert_true(ids.has(UrbanConstants.MISSION_STUNT_LEAP), "Stunt Leap must exist")
	assert_true(ids.has(UrbanConstants.MISSION_EXPLORER), "District Explorer must exist")

	var director = MissionDirector.new()
	for m_id in ids:
		var started = director.start_mission(m_id)
		assert_true(started, "Mission %s must start successfully" % m_id)
		assert_true(director.is_mission_active, "Mission %s state must be active" % m_id)
		assert_true(director.checkpoints.size() >= 2, "Mission %s must define >= 2 checkpoints" % m_id)
		assert_true(director.reward_cash >= 2000, "Mission %s reward must be >= $2000" % m_id)
		director.abort_mission()
	director.free()

func test_mission_checkpoint_advancement_and_completion() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	var save = UrbanSaveData.new()
	var director = MissionDirector.new()
	director.setup(car, save)

	var completed = {"done": false, "cash": 0}
	director.mission_completed.connect(func(_id: String, reward: int, _t: float):
		completed["done"] = true
		completed["cash"] = reward
	)

	# Start Stunt Leap mission (2 checkpoints)
	director.start_mission(UrbanConstants.MISSION_STUNT_LEAP)
	assert_true(director.current_checkpoint_idx == 0, "Should begin at checkpoint 0")

	# Drive to checkpoint 0
	car.position = director.checkpoints[0]
	director._physics_process(0.1)
	assert_true(director.current_checkpoint_idx == 1, "Should advance to checkpoint 1")

	# Drive to checkpoint 1 (finish) and satisfy jump distance
	car.position = director.checkpoints[1]
	director.report_jump_distance(75.0)
	director._physics_process(0.1)

	assert_true(completed["done"], "Mission must complete when all checkpoints and targets are reached")
	assert_true(completed["cash"] == 3500, "Stunt Leap reward should be $3500 (was: %d)" % completed["cash"])
	assert_true(save.career_cash >= 3500, "Player wallet must reflect mission reward")

	director.free()
	car.free()

func test_mission_time_limit_failure() -> void:
	var car = UrbanVehicle.new()
	car._ready()
	var director = MissionDirector.new()
	director.setup(car)

	var failed = {"triggered": false, "reason": ""}
	director.mission_failed.connect(func(_id: String, reason: String):
		failed["triggered"] = true
		failed["reason"] = reason
	)

	director.start_mission(UrbanConstants.MISSION_HILL_CLIMB)
	director.mission_timer = 80.0 # Exceeds 75s time limit
	director._physics_process(0.1)

	assert_true(failed["triggered"], "Exceeding time limit must trigger mission failure")
	assert_true(not director.is_mission_active, "Mission active flag must reset to false upon failure")

	director.free()
	car.free()

func test_progression_manager_wallet_and_upgrades() -> void:
	var save = UrbanSaveData.new()
	save.career_cash = 10000
	var mgr = ProgressionManager.new(save)

	assert_true(mgr.get_cash() == 10000, "Initial cash balance should be 10,000")
	assert_true(mgr.can_afford(5000), "Can afford $5000")

	# Buy Engine Upgrade level 2
	var ok = mgr.buy_upgrade(UrbanConstants.VEHICLE_VORTEX_GT, "engine")
	assert_true(ok, "Purchasing upgrade with sufficient funds should succeed")
	assert_true(save.get_upgrade_level(UrbanConstants.VEHICLE_VORTEX_GT, "engine") == 2, "Engine level should increment to 2")
	assert_true(mgr.get_cash() < 10000, "Cash balance should decrease after purchase")

	# Try buying with 0 cash
	save.career_cash = 0
	var fail_buy = mgr.buy_upgrade(UrbanConstants.VEHICLE_VORTEX_GT, "engine")
	assert_true(not fail_buy, "Buying upgrade without funds must fail")

func test_vehicle_unlocking_and_achievements() -> void:
	var save = UrbanSaveData.new()
	save.career_cash = 50000
	var mgr = ProgressionManager.new(save)

	assert_true(mgr.is_vehicle_unlocked(UrbanConstants.VEHICLE_VORTEX_GT), "Starter car Vortex GT must be unlocked by default")

	# Unlock remaining 4 archetypes
	var ok1 = mgr.unlock_vehicle(UrbanConstants.VEHICLE_THUNDERBOLT_V8)
	var ok2 = mgr.unlock_vehicle(UrbanConstants.VEHICLE_SPECTER_R)
	var ok3 = mgr.unlock_vehicle(UrbanConstants.VEHICLE_RIDGEBACK_4X4)
	var ok4 = mgr.unlock_vehicle(UrbanConstants.VEHICLE_VALIANT_COUPE)

	assert_true(ok1 and ok2 and ok3 and ok4, "All vehicle unlocks should succeed with adequate funds")
	assert_true(save.achievements_unlocked.has("fleet_master"), "Unlocking all vehicles must award fleet_master achievement")

	# District discovery achievement
	for d_id in UrbanDistrictDefinitions.get_district_ids():
		mgr.register_district_discovery(d_id)

	assert_true(save.achievements_unlocked.has("cartographer"), "Discovering all 8 districts must award cartographer achievement")

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/gameplay/stunt_detector.gd", [
			"setup", "process_stunt_frame", "_on_airborne_started", "_on_stunt_landed",
			"_bank_drift_combo", "_award_stunt", "report_near_miss"
		]],
		["res://games/urban-legends/gameplay/mission_director.gd", [
			"get_all_mission_ids", "setup", "start_mission", "_physics_process",
			"add_drift_points", "report_jump_distance", "complete_mission",
			"fail_mission", "abort_mission", "get_current_objective_pos"
		]],
		["res://games/urban-legends/gameplay/progression_manager.gd", [
			"_init", "get_cash", "add_cash", "can_afford", "spend_cash",
			"is_vehicle_unlocked", "unlock_vehicle", "get_upgrade_cost",
			"buy_upgrade", "unlock_achievement", "register_district_discovery"
		]]
	]
