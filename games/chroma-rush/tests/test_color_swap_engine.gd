class_name TestColorSwapEngine
extends RefCounted

## Unit tests for the authoritative ColorSwapEngine
## Tests invariants, conservation laws, eligibility thresholds, and atomic execution.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_vehicle_registration()
	test_color_conservation_invariant()
	test_eligibility_distance_check()
	test_eligibility_speed_check()
	test_eligibility_angle_check()
	test_eligibility_alignment_time_check()
	test_cooldown_enforcement()
	test_same_color_rejection()
	test_atomic_swap_success()
	test_deterministic_simultaneous_swap()
	test_ai_vehicle_swap_parity()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestColorSwapEngine FAIL] " + msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		push_error("[TestColorSwapEngine FAIL] %s (Expected %s, got %s)" % [msg, str(b), str(a)])

func _create_dummy_vehicle(pos: Vector3 = Vector3.ZERO, vel: Vector3 = Vector3.ZERO, fwd: Vector3 = -Vector3.FORWARD) -> Node3D:
	var n = Node3D.new()
	n.position = pos
	n.set_meta("velocity", vel)
	n.set("velocity", vel)
	if fwd.length_squared() > 0.001:
		n.transform = Transform3D().looking_at(fwd.normalized(), Vector3.UP)
		n.transform.origin = pos
	return n

func test_vehicle_registration() -> void:
	var engine = ColorSwapEngine.new()
	var dummy = _create_dummy_vehicle()

	engine.register_vehicle("car_1", dummy, ChromaConstants.ChromaColor.CRIMSON, false)
	assert_true(engine.has_vehicle("car_1"), "Vehicle car_1 should be registered")
	assert_eq(engine.get_vehicle_color("car_1"), ChromaConstants.ChromaColor.CRIMSON, "Color should match initial")

	engine.unregister_vehicle("car_1")
	assert_false(engine.has_vehicle("car_1"), "Vehicle car_1 should be unregistered")
	dummy.free()

func test_color_conservation_invariant() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -10))
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -10))
	var d3 = _create_dummy_vehicle(Vector3(4, 0, 0), Vector3(0, 0, -10))

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.COBALT)
	engine.register_vehicle("v3", d3, ChromaConstants.ChromaColor.SOLAR)

	var before = engine.compute_color_conservation_checksum()
	assert_eq(before[ChromaConstants.ChromaColor.CRIMSON], 1, "Initial crimson count is 1")
	assert_eq(before[ChromaConstants.ChromaColor.COBALT], 1, "Initial cobalt count is 1")
	assert_eq(before[ChromaConstants.ChromaColor.SOLAR], 1, "Initial solar count is 1")

	# Prime alignment and perform atomic swap v1 and v2
	engine.prime_alignment("v1", "v2", ChromaConstants.REQUIRED_ALIGNMENT_DURATION + 0.1)
	var res = engine.request_swap("v1", "v2")
	assert_true(res["success"], "Swap between v1 and v2 should succeed")
	assert_eq(engine.get_vehicle_color("v1"), ChromaConstants.ChromaColor.COBALT, "v1 should now hold cobalt")
	assert_eq(engine.get_vehicle_color("v2"), ChromaConstants.ChromaColor.CRIMSON, "v2 should now hold crimson")

	var after = engine.compute_color_conservation_checksum()
	assert_eq(before, after, "Total color counts across system must remain conserved (no loss/duplication)")

	d1.free()
	d2.free()
	d3.free()

func test_eligibility_distance_check() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0))
	var d2 = _create_dummy_vehicle(Vector3(0, 0, ChromaConstants.MAX_SWAP_DISTANCE + 5.0))

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.COBALT)

	var check = engine.evaluate_eligibility("v1", "v2", false)
	assert_false(check["eligible"], "Vehicles beyond max distance must not be eligible")
	assert_eq(check["reason"], ChromaConstants.REJECT_DISTANCE, "Reason must be distance")

	d1.free()
	d2.free()

func test_eligibility_speed_check() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -10))
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -35)) # Diff is 25 m/s > 12.5 max

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.COBALT)

	var check = engine.evaluate_eligibility("v1", "v2", false)
	assert_false(check["eligible"], "High relative speed difference must be rejected")
	assert_eq(check["reason"], ChromaConstants.REJECT_SPEED, "Reason must be speed mismatch")

	d1.free()
	d2.free()

func test_eligibility_angle_check() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3.ZERO, Vector3(0, 0, -1)) # North
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3.ZERO, Vector3(1, 0, 0))  # East (90 deg)

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.COBALT)

	var check = engine.evaluate_eligibility("v1", "v2", false)
	assert_false(check["eligible"], "Perpendicular vehicles must be rejected")
	assert_eq(check["reason"], ChromaConstants.REJECT_ANGLE, "Reason must be not aligned")

	d1.free()
	d2.free()

func test_eligibility_alignment_time_check() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -10))
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -10))

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.COBALT)

	# No time elapsed yet
	var check1 = engine.evaluate_eligibility("v1", "v2", true)
	assert_false(check1["eligible"], "Instant swap without required alignment duration must be rejected")
	assert_eq(check1["reason"], ChromaConstants.REJECT_ALIGNMENT_TIME, "Reason must be alignment incomplete")

	# Simulate 0.3s (not enough)
	engine.update(0.3)
	var check2 = engine.evaluate_eligibility("v1", "v2", true)
	assert_false(check2["eligible"], "Partial alignment must still be ineligible")

	# Simulate remaining duration to satisfy threshold
	engine.update(0.3)
	var check3 = engine.evaluate_eligibility("v1", "v2", true)
	assert_true(check3["eligible"], "Full alignment duration must satisfy eligibility")

	d1.free()
	d2.free()

func test_cooldown_enforcement() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -10))
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -10))

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.COBALT)

	engine.prime_alignment("v1", "v2", ChromaConstants.REQUIRED_ALIGNMENT_DURATION + 0.1)
	var swap1 = engine.request_swap("v1", "v2")
	assert_true(swap1["success"], "First swap succeeds")

	# Immediate second swap attempt must fail due to cooldown
	var swap2 = engine.request_swap("v1", "v2")
	assert_false(swap2["success"], "Immediate repeat swap must be rejected by cooldown")
	assert_eq(swap2["reason"], ChromaConstants.REJECT_COOLDOWN, "Reason must be cooldown")

	# Advance engine by cooldown duration
	engine.update(ChromaConstants.SWAP_COOLDOWN + 0.1)
	assert_eq(engine.get_vehicle_cooldown("v1"), 0.0, "Cooldown should reach zero")

	d1.free()
	d2.free()

func test_same_color_rejection() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -10))
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -10))

	engine.register_vehicle("v1", d1, ChromaConstants.ChromaColor.CRIMSON)
	engine.register_vehicle("v2", d2, ChromaConstants.ChromaColor.CRIMSON) # Same color

	engine.prime_alignment("v1", "v2", ChromaConstants.REQUIRED_ALIGNMENT_DURATION + 0.1)
	var check = engine.evaluate_eligibility("v1", "v2", true)
	assert_false(check["eligible"], "Trading identical colors must be rejected")
	assert_eq(check["reason"], ChromaConstants.REJECT_SAME_COLOR, "Reason must be same color")

	d1.free()
	d2.free()

func test_atomic_swap_success() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -15))
	var d2 = _create_dummy_vehicle(Vector3(3, 0, 0), Vector3(0, 0, -15))

	engine.register_vehicle("player", d1, ChromaConstants.ChromaColor.SOLAR)
	engine.register_vehicle("traffic_7", d2, ChromaConstants.ChromaColor.EMERALD)

	var signal_data = {"emitted": false}
	engine.swap_committed.connect(func(src, tgt, c_src, c_tgt):
		signal_data["emitted"] = true
	)

	engine.prime_alignment("player", "traffic_7", 1.0)
	var res = engine.request_swap("player", "traffic_7")
	assert_true(res["success"], "Swap must succeed")
	assert_true(signal_data["emitted"], "swap_committed signal must be emitted")
	assert_eq(engine.get_vehicle_color("player"), ChromaConstants.ChromaColor.EMERALD, "Player received emerald")
	assert_eq(engine.get_vehicle_color("traffic_7"), ChromaConstants.ChromaColor.SOLAR, "Target received solar")
	assert_eq(engine.total_swaps_committed, 1, "Swap counter incremented")

	d1.free()
	d2.free()

func test_deterministic_simultaneous_swap() -> void:
	var engine = ColorSwapEngine.new()
	var d1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -15))
	var d2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -15))

	engine.register_vehicle("vA", d1, ChromaConstants.ChromaColor.CYAN)
	engine.register_vehicle("vB", d2, ChromaConstants.ChromaColor.MAGENTA)

	engine.prime_alignment("vA", "vB", 1.0)

	# vA requests swap with vB
	var res_a = engine.request_swap("vA", "vB")
	assert_true(res_a["success"], "First swap request commits atomically")

	# Simultaneous second request in the same tick from vB to vA
	var res_b = engine.request_swap("vB", "vA")
	assert_false(res_b["success"], "Simultaneous swap is safely rejected via cooldown/lock")

	d1.free()
	d2.free()

func test_ai_vehicle_swap_parity() -> void:
	# Verifies AI vehicles exchange colors under the exact same authoritative rules
	var engine = ColorSwapEngine.new()
	var d_ai1 = _create_dummy_vehicle(Vector3(0, 0, 0), Vector3(0, 0, -12))
	var d_ai2 = _create_dummy_vehicle(Vector3(2, 0, 0), Vector3(0, 0, -12))

	engine.register_vehicle("ai_rival", d_ai1, ChromaConstants.ChromaColor.COBALT, true)
	engine.register_vehicle("ai_traffic", d_ai2, ChromaConstants.ChromaColor.SOLAR, true)

	engine.prime_alignment("ai_rival", "ai_traffic", 0.8)
	var res = engine.request_swap("ai_rival", "ai_traffic")
	assert_true(res["success"], "AI vehicle can execute valid swap under identical rules")
	assert_eq(engine.get_vehicle_color("ai_rival"), ChromaConstants.ChromaColor.SOLAR, "Rival got solar")
	assert_eq(engine.get_vehicle_color("ai_traffic"), ChromaConstants.ChromaColor.COBALT, "Traffic got cobalt")

	d_ai1.free()
	d_ai2.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/core/chroma_constants.gd", [
			"get_color_name", "get_color_value", "get_color_symbol", "get_pattern_type", "format_color_label"
		]],
		["res://games/chroma-rush/core/color_swap_engine.gd", [
			"register_vehicle", "unregister_vehicle", "has_vehicle", "get_vehicle_color",
			"set_vehicle_color_authoritative", "get_vehicle_node", "get_registered_vehicle_ids",
			"get_vehicle_cooldown", "update", "request_swap", "evaluate_eligibility",
			"find_nearest_eligible_target", "find_target_with_color", "get_alignment_progress",
			"prime_alignment", "compute_color_conservation_checksum"
		]]
	]
