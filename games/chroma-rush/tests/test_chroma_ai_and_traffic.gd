class_name TestChromaAIAndTraffic
extends RefCounted

## Unit tests for Chroma Rush AI Driver, Traffic Agent, and Rival AI

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ChromaAIDriver = preload("res://games/chroma-rush/ai/chroma_ai_driver.gd")
const TrafficAgent = preload("res://games/chroma-rush/ai/traffic_agent.gd")
const RivalAI = preload("res://games/chroma-rush/ai/rival_ai.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_ai_driver_steering_towards_target()
	test_ai_driver_braking_for_sharp_turns()
	test_traffic_agent_waypoint_progression()
	test_rival_ai_color_search_and_pursuit()
	test_rival_ai_legitimate_swap_execution()
	test_rival_ai_checkpoint_delivery_transition()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaAIAndTraffic FAIL] " + msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaAIAndTraffic FAIL] %s (Expected %s, got %s)" % [msg, str(b), str(a)])

func _create_test_vehicle(pos: Vector3 = Vector3.ZERO) -> ChromaVehicle:
	var v = ChromaVehicle.new()
	v.vehicle_id = ChromaConstants.VEHICLE_APEX
	v.position = pos
	v._ready()
	return v

func test_ai_driver_steering_towards_target() -> void:
	var v = _create_test_vehicle(Vector3.ZERO)
	var driver = ChromaAIDriver.new(v)

	# Target is 30m to the right (+X) and 30m forward (-Z)
	driver.set_target(Vector3(30, 0, -30), 25.0)
	driver.update_driving(0.1)

	assert_true(v.steer_input > 0.3, "Driver should steer right towards target (+X)")
	assert_true(v.throttle_input > 0.0, "Driver should apply throttle")

	# Target is to the left (-X)
	driver.set_target(Vector3(-30, 0, -30), 25.0)
	driver.update_driving(0.1)
	assert_true(v.steer_input < -0.3, "Driver should steer left towards target (-X)")

	v.free()

func test_ai_driver_braking_for_sharp_turns() -> void:
	var v = _create_test_vehicle(Vector3.ZERO)
	v.forward_speed = 35.0 # High speed
	var driver = ChromaAIDriver.new(v)

	# Target is directly perpendicular (+X 90 deg)
	driver.set_target(Vector3(40, 0, 0), 25.0)
	driver.update_driving(0.1)

	assert_true(v.brake_input > 0.0 or v.throttle_input < 0.5, "Driver must reduce throttle or apply brake before sharp turn")

	v.free()

func test_traffic_agent_waypoint_progression() -> void:
	var engine = ColorSwapEngine.new()
	var v = _create_test_vehicle(Vector3(0, 0, 0))
	var agent = TrafficAgent.new(v, engine, "traffic_1", ChromaConstants.ChromaColor.SOLAR)

	var wps: Array[Vector3] = [
		Vector3(0, 0, -20),
		Vector3(20, 0, -20),
		Vector3(20, 0, 0),
		Vector3(0, 0, 0)
	]
	agent.set_waypoints(wps, 0)
	assert_eq(agent.current_waypoint_idx, 0, "Initial waypoint index is 0")

	# Move vehicle close to waypoint 0
	v.position = Vector3(0, 0, -18)
	agent.update(0.1)

	assert_eq(agent.current_waypoint_idx, 1, "Agent should advance to waypoint 1 when reaching waypoint 0")
	assert_eq(agent.get_current_color(), ChromaConstants.ChromaColor.SOLAR, "Agent color matches solar")

	agent.cleanup()
	v.free()

func test_rival_ai_color_search_and_pursuit() -> void:
	var engine = ColorSwapEngine.new()
	var v_rival = _create_test_vehicle(Vector3(0, 0, 0))
	var v_target = _create_test_vehicle(Vector3(25, 0, -30))

	var rival = RivalAI.new(v_rival, engine, "rival_blaze", ChromaConstants.ChromaColor.COBALT, "skilled")
	engine.register_vehicle("target_car", v_target, ChromaConstants.ChromaColor.EMERALD, true)

	# Assign objective: Rival needs EMERALD to reach checkpoint
	rival.set_required_objective(ChromaConstants.ChromaColor.EMERALD, Vector3(100, 0, -100))
	assert_eq(rival.current_state, RivalAI.RivalState.SEARCHING_COLOR, "Rival begins searching for emerald")

	# Update 0.4s to trigger search query
	rival.update(0.4)
	assert_eq(rival.current_state, RivalAI.RivalState.PURSUING_TARGET, "Rival found emerald vehicle and switched to pursuit")
	assert_eq(rival.current_target_id, "target_car", "Rival correctly locked onto target_car")

	rival.cleanup()
	engine.unregister_vehicle("target_car")
	v_rival.free()
	v_target.free()

func test_rival_ai_legitimate_swap_execution() -> void:
	var engine = ColorSwapEngine.new()
	var v_rival = _create_test_vehicle(Vector3(0, 0, 0))
	var v_target = _create_test_vehicle(Vector3(2.5, 0, 0))

	var rival = RivalAI.new(v_rival, engine, "rival_1", ChromaConstants.ChromaColor.COBALT)
	engine.register_vehicle("target_car", v_target, ChromaConstants.ChromaColor.EMERALD)

	rival.set_required_objective(ChromaConstants.ChromaColor.EMERALD, Vector3(50, 0, -50))
	rival.current_target_id = "target_car"
	rival.current_state = RivalAI.RivalState.ALIGNING_FOR_SWAP

	# Prime alignment for legitimate swap execution
	engine.prime_alignment("rival_1", "target_car", ChromaConstants.REQUIRED_ALIGNMENT_DURATION + 0.1)

	# Execute rival update step
	rival.update(0.1)

	assert_eq(rival.get_current_color(), ChromaConstants.ChromaColor.EMERALD, "Rival successfully acquired emerald via legitimate swap")
	assert_eq(engine.get_vehicle_color("target_car"), ChromaConstants.ChromaColor.COBALT, "Target vehicle received cobalt (conservation)")
	assert_eq(rival.current_state, RivalAI.RivalState.DELIVERING_CHECKPOINT, "Rival transitioned to DELIVERING_CHECKPOINT state")

	rival.cleanup()
	engine.unregister_vehicle("target_car")
	v_rival.free()
	v_target.free()

func test_rival_ai_checkpoint_delivery_transition() -> void:
	var engine = ColorSwapEngine.new()
	var v_rival = _create_test_vehicle(Vector3(45, 0, -45))
	var rival = RivalAI.new(v_rival, engine, "rival_2", ChromaConstants.ChromaColor.SOLAR)

	var goal_pos = Vector3(50, 0, -50)
	rival.set_required_objective(ChromaConstants.ChromaColor.SOLAR, goal_pos)
	assert_eq(rival.current_state, RivalAI.RivalState.DELIVERING_CHECKPOINT, "Already holding required color, states is DELIVERING")

	rival.update(0.1)
	assert_true(rival.checkpoints_delivered >= 1, "Rival within 8m of checkpoint completes delivery")
	assert_true(rival.score >= 500, "Rival score increased")

	rival.cleanup()
	v_rival.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/ai/chroma_ai_driver.gd", [
			"set_vehicle", "set_target", "update_driving"
		]],
		["res://games/chroma-rush/ai/traffic_agent.gd", [
			"set_waypoints", "update", "get_current_color", "set_cruise_speed", "cleanup"
		]],
		["res://games/chroma-rush/ai/rival_ai.gd", [
			"set_required_objective", "update", "get_current_color", "cleanup"
		]]
	]
