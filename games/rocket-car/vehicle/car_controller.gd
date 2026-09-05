class_name CarController
extends CharacterBody3D

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

signal boost_updated(current_boost: float, max_boost: float)

@export var max_speed: float = 24.0
@export var boost_speed: float = 38.0
@export var acceleration: float = 28.0
@export var brake_deceleration: float = 35.0
@export var reverse_speed: float = 14.0
@export var steer_speed: float = 2.8
@export var jump_impulse: float = 11.0
@export var gravity: float = 28.0
@export var max_boost: float = 100.0
@export var current_boost: float = 100.0
@export var boost_consumption_rate: float = 33.0
@export var boost_recharge_rate: float = 8.0

@export var team_id: int = 0 # 0: Blue Team, 1: Orange Team
@export var is_player_controlled: bool = true

var car_visual: Node3D
var is_boosting: bool = false
var forward_speed: float = 0.0
var hit_cooldown: float = 0.0

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player_controlled else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	setup_car_visual()

func setup_car_visual() -> void:
	# Production-quality 3D vehicle model
	var v_id = "truck_red" if team_id == 0 else "truck_yellow"
	car_visual = ModelCacheScript.get_vehicle(v_id)
	if not car_visual:
		car_visual = MeshBuilder.build_rocket_car(team_id)
	add_child(car_visual)

	# Main physics collider
	var col = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(2.2, 1.3, 3.8)
	col.shape = b_shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

	# Front impact bumper for responsive ball contact
	var bumper = Area3D.new()
	bumper.name = "FrontBumper"
	bumper.collision_layer = 0
	bumper.collision_mask = GameConstants.LAYER_BALL
	var b_col = CollisionShape3D.new()
	var b_box = BoxShape3D.new()
	b_box.size = Vector3(2.4, 1.2, 1.2)
	b_col.shape = b_box
	b_col.position = Vector3(0, 0.7, -1.9)
	bumper.add_child(b_col)
	add_child(bumper)

	bumper.body_entered.connect(func(b: Node3D):
		if b.is_in_group("balls"):
			_apply_ball_hit(b, -global_transform.basis.z)
	)

func _physics_process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta

	if not is_inside_tree():
		if is_player_controlled:
			handle_player_input(delta)
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_player_controlled:
		var main = get_parent()
		if not (main and main.get("is_kickoff_pause") == true):
			handle_player_input(delta)

	move_and_slide()

	# Check slide collisions with ball
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("balls"):
			_apply_ball_hit(collider, -col.get_normal())

func _apply_ball_hit(ball_node: Node3D, contact_normal: Vector3) -> void:
	if hit_cooldown > 0.0:
		return
	hit_cooldown = 0.08

	var hit_speed = maxf(velocity.length(), 10.0)
	if is_boosting:
		hit_speed *= 1.45
	var fwd = -global_transform.basis.z
	var launch_dir = (fwd * 0.75 + contact_normal * 0.25 + Vector3.UP * 0.32).normalized()
	var impulse = launch_dir * (hit_speed * 1.9)

	if ball_node.has_method("apply_ball_impulse"):
		ball_node.apply_ball_impulse(impulse, global_position + fwd * 1.5)
	elif ball_node.has_method("apply_central_impulse"):
		ball_node.apply_central_impulse(impulse)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sfx("car_hit_ball")

func handle_player_input(delta: float) -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	var throttle = 0.0
	var steer = 0.0

	if Input.is_action_pressed("move_forward"): throttle += 1.0
	if Input.is_action_pressed("move_back"): throttle -= 1.0
	if Input.is_action_pressed("move_left"): steer += 1.0
	if Input.is_action_pressed("move_right"): steer -= 1.0

	if im and im.virtual_move_vector.length_squared() > 0.01:
		steer = -im.virtual_move_vector.x
		throttle = -im.virtual_move_vector.y

	apply_driving_controls(throttle, steer, delta)

	# Jump
	var on_floor = is_on_floor() if is_inside_tree() else true
	if Input.is_action_just_pressed("jump") and on_floor:
		velocity.y = jump_impulse
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump", 0.9)

	# Boost
	is_boosting = Input.is_action_pressed("boost") and current_boost > 0.0
	var bus = GameConstants.get_autoload(self, "EventBus")
	if is_boosting:
		current_boost = max(0.0, current_boost - boost_consumption_rate * delta)
		forward_speed = lerpf(forward_speed, boost_speed, delta * 5.0)
		if bus:
			bus.boost_amount_changed.emit(current_boost, max_boost)
	else:
		current_boost = min(max_boost, current_boost + boost_recharge_rate * delta)
		if bus:
			bus.boost_amount_changed.emit(current_boost, max_boost)

	boost_updated.emit(current_boost, max_boost)

func apply_driving_controls(throttle: float, steer: float, delta: float) -> void:
	# Steering rotates vehicle around Y axis
	if abs(forward_speed) > 0.5:
		var on_floor = is_on_floor() if is_inside_tree() else true
		var steer_dir = sign(forward_speed) if on_floor else 1.0
		rotate_y(steer * steer_speed * delta * steer_dir)

	# Acceleration / Braking
	var top_speed = boost_speed if is_boosting else max_speed
	if throttle > 0.0:
		forward_speed = move_toward(forward_speed, top_speed, acceleration * delta)
	elif throttle < 0.0:
		forward_speed = move_toward(forward_speed, -reverse_speed, brake_deceleration * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 12.0 * delta)

	# Apply forward direction velocity
	var fwd = -transform.basis.z
	velocity.x = fwd.x * forward_speed
	velocity.z = fwd.z * forward_speed

func replenish_boost(amount: float) -> void:
	current_boost = min(max_boost, current_boost + amount)
	boost_updated.emit(current_boost, max_boost)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.boost_amount_changed.emit(current_boost, max_boost)
