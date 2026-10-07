class_name TestAeroStuntAndComboUnit
extends RefCounted

## Unit test suite for AeroRush stunt detection, anti-exploit rules,
## combo multiplier chaining, and persistent progression saving.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroVehicle = preload("res://games/aero-rush/vehicles/aero_vehicle.gd")
const AeroStuntDetector = preload("res://games/aero-rush/core/aero_stunt_detector.gd")
const AeroComboSystem = preload("res://games/aero-rush/core/aero_combo_system.gd")
const AeroSaveAdapter = preload("res://games/aero-rush/persistence/aero_save_adapter.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	print("  [AeroRush] Running Stunt, Combo & Persistence Unit Tests...")
	test_stunt_speed_gate_anti_exploit()
	test_stunt_repetition_decay()
	test_combo_escalation_and_multiplier()
	test_combo_banking()
	test_combo_drop_on_crash()
	test_save_adapter_defaults_and_records()
	test_tier_unlocking_progression()
	test_vehicle_purchase_and_unlock()
	return {"passed": passed, "failed": failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL Aero Stunt/Combo: " + msg)

func test_stunt_speed_gate_anti_exploit() -> void:
	var veh = AeroVehicle.new()
	veh._ready()
	var detector = AeroStuntDetector.new()
	detector.setup(veh)

	var verified_stunts: Array[Dictionary] = []
	detector.stunt_verified.connect(func(id, pts, lbl): verified_stunts.append({"id": id, "pts": pts}))

	# 1. Car is stopped / stationary (speed = 0)
	veh.forward_speed = 0.0
	detector._on_vehicle_stunt(AeroConstants.StuntType.SPIN_360, 450, "360 FLAT SPIN")
	assert_true(verified_stunts.is_empty(), "Tricks performed while stationary must be dropped by anti-exploit gate")

	# 2. Car is driving at high speed (speed = 30 m/s >= MIN_STUNT_SPEED)
	veh.forward_speed = 30.0
	detector._on_vehicle_stunt(AeroConstants.StuntType.SPIN_360, 450, "360 FLAT SPIN")
	assert_true(verified_stunts.size() == 1, "Tricks performed at legitimate driving speed must be verified")
	assert_true(verified_stunts[0]["pts"] == 450, "First execution must award full points")

	veh.free()

func test_stunt_repetition_decay() -> void:
	var veh = AeroVehicle.new()
	veh._ready()
	veh.forward_speed = 35.0
	var detector = AeroStuntDetector.new()
	detector.setup(veh)

	var awards: Array[int] = []
	detector.stunt_verified.connect(func(_id, pts, _lbl): awards.append(pts))

	# Perform same trick 4 times in quick succession
	for i in range(4):
		detector._on_vehicle_stunt(AeroConstants.StuntType.BARREL_ROLL, 500, "BARREL ROLL")

	assert_true(awards.size() == 4, "All 4 tricks recorded")
	assert_true(awards[0] == 500, "1st attempt awards 100% (500 pts)")
	assert_true(awards[1] < awards[0], "2nd attempt must suffer repetition decay")
	assert_true(awards[2] < awards[1], "3rd attempt must suffer further repetition decay")
	assert_true(awards[3] <= awards[2], "4th attempt capped at maximum decay")

	veh.free()

func test_combo_escalation_and_multiplier() -> void:
	var combo = AeroComboSystem.new()
	assert_true(combo.current_multiplier == 1, "Initial multiplier must be 1")
	assert_true(not combo.is_combo_active, "Initial combo must be inactive")

	# Add stunts
	combo.add_stunt(AeroConstants.StuntType.AIRTIME, 200, "AIRTIME")
	assert_true(combo.is_combo_active, "Combo must be active after stunt")
	assert_true(combo.pending_combo_score == 200, "Pending score must match base points * 1")

	combo.add_stunt(AeroConstants.StuntType.SPIN_360, 400, "360 SPIN")
	assert_true(combo.current_multiplier == 2, "Multiplier must escalate to x2 after 2 stunts")

	for i in range(16):
		combo.add_stunt(AeroConstants.StuntType.DRIFT, 100, "DRIFT")

	assert_true(combo.current_multiplier == AeroConstants.MAX_COMBO_MULTIPLIER, "Multiplier must cap at max 10x")

func test_combo_banking() -> void:
	var combo = AeroComboSystem.new()
	combo.add_stunt(AeroConstants.StuntType.LONG_JUMP, 500, "LONG JUMP")
	var initial_pending = combo.pending_combo_score

	# Simulate time expiring smoothly
	combo.update(AeroConstants.COMBO_TIMEOUT_SECONDS + 0.1)

	assert_true(not combo.is_combo_active, "Combo must deactivate after timer expires")
	assert_true(combo.total_banked_score == initial_pending, "Pending score must be banked into total score")
	assert_true(combo.pending_combo_score == 0, "Pending score must be cleared after banking")

func test_combo_drop_on_crash() -> void:
	var combo = AeroComboSystem.new()
	combo.add_stunt(AeroConstants.StuntType.BARREL_ROLL, 600, "BARREL ROLL")
	assert_true(combo.pending_combo_score > 0, "Pending score must exist before crash")

	# Vehicle crashes
	combo.on_vehicle_crash()

	assert_true(not combo.is_combo_active, "Combo must be reset on crash")
	assert_true(combo.pending_combo_score == 0, "Pending score must be dropped on crash")
	assert_true(combo.total_banked_score == 0, "Banked score must not receive dropped combo")

func test_save_adapter_defaults_and_records() -> void:
	var defaults = AeroSaveAdapter.get_default_data()
	assert_true(defaults["credits"] == 1000, "Default credits must be 1000")
	assert_true(AeroConstants.VEHICLE_APEX in defaults["unlocked_vehicles"], "Apex Zephyr must be unlocked by default")
	assert_true(1 in defaults["unlocked_tiers"], "Tier 1 must be unlocked by default")

	# Record a course result
	var res = AeroSaveAdapter.record_course_result("neon_express", 62.5, 15000, AeroConstants.Medal.GOLD, 500)
	assert_true(res["new_medal"] == AeroConstants.Medal.GOLD, "Gold medal must be recorded")
	assert_true(res["credits_granted"] >= 500, "Credits must be awarded")

	var loaded = AeroSaveAdapter.load_aero_data()
	assert_true(loaded["course_medals"]["neon_express"] == AeroConstants.Medal.GOLD, "Persisted medal must match")
	assert_true(loaded["best_times"]["neon_express"] == 62.5, "Persisted best time must match")

func test_tier_unlocking_progression() -> void:
	var data = AeroSaveAdapter.get_default_data()
	# Award 3 medals
	data["course_medals"]["c1"] = AeroConstants.Medal.BRONZE
	data["course_medals"]["c2"] = AeroConstants.Medal.SILVER
	data["course_medals"]["c3"] = AeroConstants.Medal.GOLD

	AeroSaveAdapter._check_and_unlock_tiers(data)
	assert_true(2 in data["unlocked_tiers"], "Earning 3 medals must unlock Tier 2")

	# Award 3 more medals (total 6)
	data["course_medals"]["c4"] = AeroConstants.Medal.GOLD
	data["course_medals"]["c5"] = AeroConstants.Medal.GOLD
	data["course_medals"]["c6"] = AeroConstants.Medal.GOLD

	AeroSaveAdapter._check_and_unlock_tiers(data)
	assert_true(3 in data["unlocked_tiers"], "Earning 6 medals must unlock Tier 3")

func test_vehicle_purchase_and_unlock() -> void:
	var data = AeroSaveAdapter.load_aero_data()
	data["credits"] = 5000
	data["unlocked_vehicles"] = [AeroConstants.VEHICLE_APEX]
	AeroSaveAdapter.save_aero_data(data)

	var success = AeroSaveAdapter.unlock_vehicle(AeroConstants.VEHICLE_STRYKER, 3000)
	assert_true(success, "Vehicle unlock must succeed when player has sufficient credits")

	var after = AeroSaveAdapter.load_aero_data()
	assert_true(AeroConstants.VEHICLE_STRYKER in after["unlocked_vehicles"], "Torque Stryker must be in unlocked list")
	assert_true(after["credits"] == 2000, "Credits must be deducted by vehicle cost")

func get_coverage_entries() -> Array:
	return [
		["res://games/aero-rush/core/aero_stunt_detector.gd", [
			"setup", "update", "_on_vehicle_stunt", "_on_vehicle_landing", "trigger_near_miss", "clear"
		]],
		["res://games/aero-rush/core/aero_combo_system.gd", [
			"update", "add_stunt", "_bank_combo", "on_vehicle_crash", "_reset_combo_state", "get_total_score", "reset"
		]],
		["res://games/aero-rush/persistence/aero_save_adapter.gd", [
			"get_default_data", "load_aero_data", "save_aero_data", "record_course_result",
			"unlock_vehicle", "_check_and_unlock_tiers", "_migrate_and_verify"
		]]
	]
