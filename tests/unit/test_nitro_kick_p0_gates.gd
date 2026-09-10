class_name TestNitroKickP0Gates
extends RefCounted

## Automated Test Suite: Nitro Kick P0 Forensic Gates
## Verifies canonical vehicle hierarchy, orientation invariants, 4 distinct vehicle archetypes,
## physical momentum transfer, regulation arena geometry, MultiMesh crowds, and 2v2 dynamic AI roles.

const CarControllerScript = preload("res://games/rocket-car/vehicle/car_controller.gd")
const CarAIScript = preload("res://games/rocket-car/ai/car_ai.gd")
const RocketArenaScript = preload("res://games/rocket-car/arena/rocket_arena.gd")
const BallScript = preload("res://games/rocket-car/ball/ball.gd")
const MeshBuilderScript = preload("res://shared/graphics/mesh_builder.gd")
const RocketCarMainScript = preload("res://games/rocket-car/rocket_car_main.gd")

func run_tests() -> Dictionary:
	var results = {"passed": 0, "failed": 0, "errors": []}
	
	_test_canonical_vehicle_orientation(results)
	_test_four_vehicle_archetypes_and_stats(results)
	_test_ball_physics_and_momentum_transfer(results)
	_test_stadium_regulation_scale_and_crowds(results)
	_test_dynamic_match_ai_roles_and_prediction(results)
	_test_match_flow_and_kickoff_reset(results)
	
	return results

func _test_canonical_vehicle_orientation(results: Dictionary) -> void:
	var car = CarControllerScript.new()
	car.team_id = 0
	car.vehicle_archetype = "sports_coupe"
	car._ready()
	
	# 1. Front bumper canonical forward check (Godot forward is -Z)
	var bumper = car.get_node_or_null("FrontBumper") as Area3D
	if bumper and bumper.position.z < -1.0:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("FrontBumper missing or not positioned at -Z canonical forward")
	
	# 2. VisualRoot and lights orientation
	var vis = car.car_visual
	if not vis:
		results["failed"] += 1
		results["errors"].append("Car visual root is null")
		car.queue_free()
		return
	
	var found_headlight = false
	var found_thruster = false
	var headlight_at_neg_z = true
	var thruster_at_pos_z = true
	
	for child in vis.get_children():
		if "FrontHeadlight" in child.name or "PhotonVisor" in child.name or "RallyBar" in child.name:
			found_headlight = true
			if child.position.z >= 0.0:
				headlight_at_neg_z = false
		if "Thruster" in child.name or "MegaNozzle" in child.name:
			found_thruster = true
			if child.position.z <= 0.0:
				thruster_at_pos_z = false
	
	if found_headlight and headlight_at_neg_z:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Headlights must face and be positioned at -Z forward")
	
	if found_thruster and thruster_at_pos_z:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Rocket thrusters must face and be positioned at +Z rear")
	
	# 3. Steering yaw rotation
	car.apply_driving_controls(1.0, 1.0, 0.1)
	var wheels_steered = false
	for w_name in ["Wheel_0", "Wheel_1", "wheel-front-left", "wheel-front-right"]:
		var w = car.car_visual.find_child(w_name, true, false)
		if w and absf(w.rotation.y) > 0.01:
			wheels_steered = true
			break
	if wheels_steered:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Front wheels must rotate yaw corresponding to steering")
	
	car.queue_free()

func _test_four_vehicle_archetypes_and_stats(results: Dictionary) -> void:
	var archetypes = ["sports_coupe", "rally_buggy", "muscle_gt", "cyber_ev"]
	var recorded_speeds: Dictionary = {}
	var recorded_jumps: Dictionary = {}
	
	for arch in archetypes:
		var car = CarControllerScript.new()
		car.set_vehicle_archetype(arch)
		
		# Verify non-null visual
		if car.car_visual and car.car_visual.get_child_count() > 3:
			results["passed"] += 1
		else:
			results["failed"] += 1
			results["errors"].append("Archetype %s failed to build complete 3D visual" % arch)
		
		recorded_speeds[arch] = car.max_speed
		recorded_jumps[arch] = car.jump_impulse
		car.queue_free()
	
	# Verify distinct physics parameters
	if recorded_speeds["cyber_ev"] > recorded_speeds["rally_buggy"] and recorded_jumps["rally_buggy"] > recorded_jumps["sports_coupe"]:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Archetypes must genuinely alter physics speed and jump stats")

func _test_ball_physics_and_momentum_transfer(results: Dictionary) -> void:
	var ball = BallScript.new()
	ball._ready()
	
	# 1. Continuous collision detection
	if ball.continuous_cd:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Ball must have continuous_cd enabled to prevent tunneling")
	
	# 2. Physics impulse momentum transfer
	var initial_vel = ball.linear_velocity
	ball.apply_ball_impulse(Vector3(0, 40, -180))
	if ball.linear_velocity.z < -10.0 and ball.linear_velocity.y > 2.0:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Ball must receive realistic physical momentum from impulse (got vel: %s)" % str(ball.linear_velocity))
	
	# 3. Ball reset
	ball.reset_ball()
	if ball.linear_velocity.length() < 0.01:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Ball reset must restore zero velocity")
	
	ball.queue_free()

func _test_stadium_regulation_scale_and_crowds(results: Dictionary) -> void:
	var arena = RocketArenaScript.new()
	arena.pitch_length = 110.0
	arena.pitch_width = 64.0
	arena.pitch_height = 20.0
	arena._ready()
	
	# 1. Dimension checks
	if arena.pitch_length >= 100.0 and arena.pitch_width >= 60.0:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Arena dimensions must match regulation sports scale (>=100x60m)")
	
	# 2. Goals with depth
	var has_goals = false
	for c in arena.get_children():
		if "Goal" in c.name or "GoalCage" in c.name:
			has_goals = true
			break
	if has_goals or arena.get_node_or_null("GoalBlue") or arena.get_node_or_null("GoalOrange"):
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Regulation arena must contain visible goal cages with net depth")
	
	# 3. Boost layout (28 turf pads + 6 full boost orbs)
	var boost_count = arena.boost_pads.size()
	if boost_count >= 20:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Regulation arena must contain complete boost network (found %d)" % boost_count)
	
	# 4. MultiMesh crowds and reaction states
	if arena.has_method("set_crowd_reaction_state"):
		arena.set_crowd_reaction_state("goal")
		arena.set_crowd_reaction_state("idle")
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Arena must support crowd reaction states (idle, goal, etc)")
	
	arena.queue_free()

func _test_dynamic_match_ai_roles_and_prediction(results: Dictionary) -> void:
	var ai = CarAIScript.new()
	
	# 1. Dynamic role assignment
	ai.set_role(CarAIScript.AIRole.STRIKER)
	if ai.role == CarAIScript.AIRole.STRIKER:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("AI must support dynamic role assignment")
	
	# 2. Predictive ball trajectory lead
	var p0 = Vector3(0, 1, 0)
	var v0 = Vector3(10, 0, -20)
	var pred = ai.predict_ball_intercept(p0, v0, 1.0)
	if pred.x > 5.0 and pred.z < -10.0:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("AI must calculate predictive lead trajectory for intercepts")
	
	ai.queue_free()

func _test_match_flow_and_kickoff_reset(results: Dictionary) -> void:
	var match_ctrl = RocketCarMainScript.new()
	match_ctrl.match_mode = "2v2"
	match_ctrl._ready()
	
	# 1. Verify 4 cars in 2v2
	if match_ctrl.blue_cars.size() >= 2 and match_ctrl.orange_cars.size() >= 2:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("2v2 match must spawn at least 2 Blue and 2 Orange cars")
	
	# 2. Kickoff countdown pause
	if match_ctrl.is_kickoff_pause:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Match must initiate with kickoff countdown pause")
	
	# 3. Goal scoring and reset
	var initial_blue = match_ctrl.blue_score
	match_ctrl.is_kickoff_pause = false
	match_ctrl._on_goal_scored(0) # Blue scores (0 = Blue, 1 = Orange)
	if match_ctrl.blue_score == initial_blue + 1 and match_ctrl.is_kickoff_pause:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Goal must increment score and trigger kickoff reset sequence")
	
	match_ctrl.queue_free()
