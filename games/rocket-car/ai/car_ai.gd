class_name CarAI
extends Node

@export var car: CarController
@export var ball: RocketBall
@export var is_orange_team: bool = true

var steer_error_filter: float = 0.0

func _ready() -> void:
	if not car:
		car = get_parent() as CarController
	if car:
		car.is_player_controlled = false
func _physics_process(delta: float) -> void:
	if not car or not is_instance_valid(car) or not ball or not is_instance_valid(ball):
		return

	var main = car.get_parent()
	if main and main.get("is_kickoff_pause") == true:
		car.apply_driving_controls(0.0, 0.0, delta)
		return

	var car_pos = car.global_position
	var ball_pos = ball.global_position

	# Target goal to score in:
	# Orange team attacks South Goal (+Z), Blue team attacks North Goal (-Z)
	var target_goal_z = 52.0 if is_orange_team else -52.0
	var own_goal_z = -52.0 if is_orange_team else 52.0

	# Calculate desired strike angle
	# Position behind the ball relative to target goal
	var ball_to_goal = (Vector3(0, 0, target_goal_z) - ball_pos).normalized()
	var strike_spot = ball_pos - ball_to_goal * 2.8

	# Decide target destination
	var target_destination = strike_spot
	# If ball is behind us heading towards our goal, defend own goal!
	var is_defending = false
	if (is_orange_team and ball_pos.z < car_pos.z) or (not is_orange_team and ball_pos.z > car_pos.z):
		is_defending = true
		target_destination = Vector3(clampf(ball_pos.x * 0.7, -12.0, 12.0), 0.5, own_goal_z * 0.8)

	var to_target = (target_destination - car_pos)
	to_target.y = 0.0
	var dist = to_target.length()

	var fwd = -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var right = car.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var dir_to_dest = to_target.normalized() if dist > 0.1 else fwd
	var dot_fwd = fwd.dot(dir_to_dest)
	var dot_right = right.dot(dir_to_dest)

	# Steer towards target destination
	var steer_input = clampf(dot_right * 2.5, -1.0, 1.0)
	var throttle_input = 1.0

	# If facing wrong way, slow down or reverse
	if dot_fwd < -0.2 and dist < 8.0:
		throttle_input = -0.5
		steer_input = -steer_input

	# Boost when aligned and charging forward
	if dot_fwd > 0.85 and dist > 10.0 and car.current_boost > 20.0 and not is_defending:
		car.is_boosting = true
		car.current_boost = max(0.0, car.current_boost - car.boost_consumption_rate * delta)
	else:
		car.is_boosting = false

	# Jump if close to ball and ball is in the air
	if car_pos.distance_to(ball_pos) < 6.0 and ball_pos.y > 2.0 and ball_pos.y < 5.0 and car.is_on_floor():
		car.velocity.y = car.jump_impulse

	car.apply_driving_controls(throttle_input, steer_input, delta)
