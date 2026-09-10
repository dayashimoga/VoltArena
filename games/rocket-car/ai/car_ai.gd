class_name CarAI
extends Node

## CarAI: Competitive sports AI for Nitro Kick.
## Implements dynamic team roles (Striker, Support, Defender, Goalkeeper),
## predictive ball trajectory interception, physics-based aerial jumps,
## kickoff sprint protocol, boost management, and wall/unstuck self-recovery.

enum AIRole { STRIKER, SUPPORT, DEFENDER, GOALKEEPER }

@export var car: CarController
@export var ball: RocketBall
@export var is_orange_team: bool = true
@export var role: AIRole = AIRole.STRIKER
@export var role_name: String = "Striker"

var reaction_timer: float = 0.0
var stuck_timer: float = 0.0
var reverse_timer: float = 0.0
var preferred_lane_x: float = 0.0

func _ready() -> void:
	if not car:
		car = get_parent() as CarController
	if car:
		car.is_player_controlled = false
	_update_role_name()

func _update_role_name() -> void:
	match role:
		AIRole.STRIKER: role_name = "Striker"
		AIRole.SUPPORT: role_name = "Support"
		AIRole.DEFENDER: role_name = "Defender"
		AIRole.GOALKEEPER: role_name = "Goalkeeper"

func set_role(new_role: AIRole) -> void:
	role = new_role
	_update_role_name()

func _physics_process(delta: float) -> void:
	if not car or not is_instance_valid(car) or not ball or not is_instance_valid(ball):
		return

	var main = car.get_parent()
	if main and main.get("is_kickoff_pause") == true:
		car.apply_driving_controls(0.0, 0.0, delta)
		return

	# Recovery check: self-righting if flipped upside down
	if car.is_inside_tree():
		var up_dot = car.global_transform.basis.y.dot(Vector3.UP)
		if up_dot < 0.25:
			car.perform_jump()
			car.rotate_object_local(Vector3.FORWARD, 3.5 * delta)
			return

	# Handle stuck / wall reversal
	if reverse_timer > 0.0:
		reverse_timer -= delta
		car.apply_driving_controls(-1.0, 0.8 if preferred_lane_x >= 0 else -0.8, delta)
		return

	if absf(car.velocity.length()) < 1.2 and not car.is_on_floor():
		stuck_timer += delta
		if stuck_timer > 1.2:
			reverse_timer = 0.75
			stuck_timer = 0.0
			return
	else:
		stuck_timer = maxf(0.0, stuck_timer - delta * 2.0)

	var car_pos = car.global_position
	var ball_pos = ball.global_position
	var ball_vel = ball.linear_velocity if "linear_velocity" in ball else Vector3.ZERO

	# Orange attacks South (+Z, z = +55), defends North (-Z, z = -55)
	# Blue attacks North (-Z, z = -55), defends South (+Z, z = +55)
	var target_goal_z = 55.0 if is_orange_team else -55.0
	var own_goal_z = -55.0 if is_orange_team else 55.0

	# 1. Predictive Interception: P_pred = P_ball + V_ball * t
	var dist_to_ball = car_pos.distance_to(ball_pos)
	var est_speed = maxf(car.velocity.length(), 15.0)
	var lead_time = clampf(dist_to_ball / est_speed, 0.1, 1.4)
	var pred_ball_pos = predict_ball_intercept(ball_pos, ball_vel, lead_time)

	# 2. Role-Based Target Destination
	var target_dest = Vector3.ZERO
	var attack_dir = (Vector3(0, 1.2, target_goal_z) - pred_ball_pos).normalized()

	match role:
		AIRole.STRIKER:
			# Strike spot: Position behind ball relative to opponent goal
			target_dest = pred_ball_pos - attack_dir * 2.2
			# If ball is behind us heading towards our goal, peel back to avoid own-goals
			if (is_orange_team and ball_pos.z < car_pos.z - 3.0) or (not is_orange_team and ball_pos.z > car_pos.z + 3.0):
				target_dest = Vector3(pred_ball_pos.x * 0.75, 0.5, own_goal_z * 0.65)

		AIRole.SUPPORT:
			# Midfield coverage and second-ball positioning
			var mid_z = pred_ball_pos.z * 0.55
			var lane_x = clampf(pred_ball_pos.x + preferred_lane_x * 12.0, -22.0, 22.0)
			target_dest = Vector3(lane_x, 0.5, mid_z)
			# If striker is far or ball is loose, press forward
			if dist_to_ball < 18.0:
				target_dest = pred_ball_pos - attack_dir * 3.0

		AIRole.DEFENDER, AIRole.GOALKEEPER:
			# Goalmouth patrol between posts (width 16m -> clamp x within [-6.5, 6.5])
			var goal_clamp_x = clampf(pred_ball_pos.x * 0.55, -6.5, 6.5)
			var patrol_z = own_goal_z * 0.86
			target_dest = Vector3(goal_clamp_x, 0.5, patrol_z)

			# If ball enters defensive penalty box (within 24m of own goal), charge to clear!
			var dist_ball_to_own_goal = absf(ball_pos.z - own_goal_z)
			if dist_ball_to_own_goal < 26.0 and absf(ball_pos.x) < 22.0:
				target_dest = pred_ball_pos - attack_dir * 2.0

	# 3. Steering & Throttle Computation (Canonical Forward is -Z)
	var to_target = target_dest - car_pos
	to_target.y = 0.0
	var dist_dest = to_target.length()

	var fwd = -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var right = car.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var dir_to_dest = to_target.normalized() if dist_dest > 0.2 else fwd
	var dot_fwd = fwd.dot(dir_to_dest)
	var dot_right = right.dot(dir_to_dest)

	# Proportional steering
	var steer_input = clampf(dot_right * 2.6, -1.0, 1.0)
	var throttle_input = 1.0

	# Sharp cornering / 180 turnaround: reverse if destination is behind and close
	if dot_fwd < -0.35 and dist_dest < 10.0:
		throttle_input = -0.7
		steer_input = -steer_input

	# 4. Boost Activation Logic
	# Boost when charging forward on ball / open pitch
	var should_boost = (dot_fwd > 0.85 and dist_dest > 8.0 and car.current_boost > 15.0)
	if role == AIRole.GOALKEEPER and dist_dest < 12.0:
		should_boost = false # Conserve boost in net

	if should_boost:
		car.is_boosting = true
		car.current_boost = maxf(0.0, car.current_boost - car.boost_consumption_rate * delta)
	else:
		car.is_boosting = false

	# 5. Jump / Aerial Header Strike
	# If close to ball, ball is in the air, and car is on ground
	if dist_to_ball < 6.0 and ball_pos.y > 1.8 and ball_pos.y < 5.0 and car.is_on_floor():
		car.perform_jump()
	elif dist_to_ball < 4.0 and ball_pos.y > 2.5 and car.can_double_jump and not car.is_on_floor():
		car.perform_jump()

	car.apply_driving_controls(throttle_input, steer_input, delta)

func predict_ball_intercept(p_ball: Vector3, v_ball: Vector3, lead_t: float) -> Vector3:
	var pred = p_ball + v_ball * lead_t
	pred.y = maxf(0.8, pred.y)
	return pred

