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
@export var vehicle_archetype: String = "sports_coupe"

var car_visual: Node3D
var is_boosting: bool = false
var is_drifting: bool = false
var can_double_jump: bool = true
var forward_speed: float = 0.0
var hit_cooldown: float = 0.0

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player_controlled else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	setup_car_visual()

func set_vehicle_archetype(new_archetype: String) -> void:
	vehicle_archetype = new_archetype
	setup_car_visual()

func apply_archetype_stats() -> void:
	match vehicle_archetype.to_lower():
		"rally_buggy", "dune_raider", "buggy":
			max_speed = 25.0
			boost_speed = 38.0
			acceleration = 26.0
			brake_deceleration = 36.0
			steer_speed = 3.4
			jump_impulse = 13.5
			boost_consumption_rate = 30.0
			boost_recharge_rate = 10.0
		"muscle_gt", "titan_enforcer", "muscle", "turbo_truck":
			max_speed = 26.5
			boost_speed = 40.0
			acceleration = 32.0
			brake_deceleration = 38.0
			steer_speed = 2.7
			jump_impulse = 10.5
			boost_consumption_rate = 35.0
			boost_recharge_rate = 8.0
		"cyber_ev", "volt_pulse", "phantom", "cyber":
			max_speed = 29.5
			boost_speed = 44.0
			acceleration = 30.0
			brake_deceleration = 35.0
			steer_speed = 3.2
			jump_impulse = 11.5
			boost_consumption_rate = 28.0
			boost_recharge_rate = 15.0
		_: # "sports_coupe" / "apex_spectre" / "speed_demon"
			max_speed = 28.0
			boost_speed = 42.0
			acceleration = 28.0
			brake_deceleration = 35.0
			steer_speed = 3.0
			jump_impulse = 11.0
			boost_consumption_rate = 32.0
			boost_recharge_rate = 9.0

func setup_car_visual() -> void:
	if car_visual and is_instance_valid(car_visual):
		car_visual.queue_free()

	# Production-quality 3D rocket car model matching archetype and canonical orientation
	car_visual = MeshBuilder.build_rocket_car(team_id, vehicle_archetype)
	add_child(car_visual)
	apply_archetype_stats()

	# Main physics collider if not already added
	var col = get_node_or_null("CarCollision") as CollisionShape3D
	if not col:
		col = CollisionShape3D.new()
		col.name = "CarCollision"
		var b_shape = BoxShape3D.new()
		b_shape.size = Vector3(2.2, 1.3, 3.8)
		col.shape = b_shape
		col.position = Vector3(0, 0.7, 0)
		add_child(col)

	# Front impact bumper for responsive ball contact (canonical forward is -Z)
	var bumper = get_node_or_null("FrontBumper") as Area3D
	if not bumper:
		bumper = Area3D.new()
		bumper.name = "FrontBumper"
		bumper.position = Vector3(0, 0.7, -1.9)
		bumper.collision_layer = 0
		bumper.collision_mask = GameConstants.LAYER_BALL
		var b_col = CollisionShape3D.new()
		var b_box = BoxShape3D.new()
		b_box.size = Vector3(2.4, 1.2, 1.2)
		b_col.shape = b_box
		b_col.position = Vector3.ZERO
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

	var on_ground = is_on_floor()
	if on_ground:
		can_double_jump = true
	else:
		velocity.y -= gravity * delta

	if is_player_controlled:
		var main = get_parent()
		if not (main and main.get("is_kickoff_pause") == true):
			handle_player_input(delta)

	if is_inside_tree():
		if global_position.y < -4.0 or abs(global_position.x) > 60.0 or abs(global_position.z) > 85.0:
			velocity = Vector3.ZERO
			global_position = Vector3(-12.0 if team_id == 0 else 12.0, 0.5, 32.0 if team_id == 0 else -32.0)

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
		hit_speed *= 1.40
	var fwd = -global_transform.basis.z
	var launch_dir = (fwd * 0.72 + contact_normal * 0.28 + Vector3.UP * 0.30).normalized()
	# Authoritative momentum transfer to ball RigidBody3D
	var impulse = launch_dir * (hit_speed * 18.0)

	if ball_node.has_method("apply_ball_impulse"):
		ball_node.apply_ball_impulse(impulse, global_position + fwd * 1.5)
	elif ball_node.has_method("apply_central_impulse"):
		ball_node.apply_central_impulse(impulse)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sfx("car_hit_ball")

func perform_jump() -> bool:
	var on_ground = (is_on_floor() and velocity.y <= 0.1) if is_inside_tree() else true
	if on_ground:
		velocity.y = jump_impulse
		can_double_jump = true
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump", 0.9)
		return true
	elif can_double_jump:
		velocity.y = jump_impulse * 0.9
		can_double_jump = false
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump", 1.2)
		return true
	return false

func perform_dodge(direction: Vector2) -> void:
	if can_double_jump:
		velocity.y = jump_impulse * 0.6
		var dodge_dir = (-global_transform.basis.z * direction.y + global_transform.basis.x * direction.x).normalized()
		velocity += dodge_dir * 14.0
		can_double_jump = false
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump", 1.3)

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

	is_drifting = Input.is_action_pressed("drift")

	apply_driving_controls(throttle, steer, delta)

	# Jump and Double Jump
	if Input.is_action_just_pressed("jump"):
		var on_ground = is_on_floor() if is_inside_tree() else true
		if on_ground:
			perform_jump()
		elif can_double_jump:
			if abs(throttle) > 0.1 or abs(steer) > 0.1:
				perform_dodge(Vector2(-steer, throttle))
			else:
				perform_jump()

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
	var on_ground = (is_on_floor() and velocity.y <= 0.1 and global_position.y < 1.0) if is_inside_tree() else true

	# Update visual wheel steering yaw (front wheels steer with turn)
	if car_visual and is_instance_valid(car_visual):
		var steer_target = steer * 0.42
		for w_name in ["Wheel_0", "Wheel_1", "wheel-front-left", "wheel-front-right"]:
			var w = car_visual.find_child(w_name, true, false)
			if w is Node3D:
				w.rotation.y = lerpf(w.rotation.y, steer_target, delta * 14.0)

		# Animate boost flames
		var flame_scale = Vector3(1.4, 1.4, 1.6) if is_boosting else Vector3(0.5, 0.5, 0.5)
		for child in car_visual.get_children():
			if "ThrusterFlame" in child.name or "ThrusterGlow" in child.name:
				if child is Node3D:
					child.scale = child.scale.lerp(flame_scale, delta * 12.0)

	if on_ground:
		# Ground Driving & Drift
		if abs(forward_speed) > 0.5:
			var steer_dir = sign(forward_speed)
			var drift_multiplier = 1.75 if is_drifting else 1.0
			rotate_y(steer * steer_speed * drift_multiplier * delta * steer_dir)

		# Acceleration / Braking
		var top_speed = boost_speed if is_boosting else max_speed
		if throttle > 0.0:
			forward_speed = move_toward(forward_speed, top_speed, acceleration * delta)
		elif throttle < 0.0:
			forward_speed = move_toward(forward_speed, -reverse_speed, brake_deceleration * delta)
		else:
			forward_speed = move_toward(forward_speed, 0.0, 12.0 * delta)

		# Apply forward direction velocity (canonical forward is -Z)
		var fwd = -transform.basis.z
		velocity.x = fwd.x * forward_speed
		velocity.z = fwd.z * forward_speed
	else:
		# Aerial Pitch, Yaw, and Roll
		# Pitch: forward/back pitch tilt
		if abs(throttle) > 0.05:
			rotate_object_local(Vector3.RIGHT, throttle * 2.8 * delta)

		# Yaw / Roll:
		if abs(steer) > 0.05:
			if is_drifting or Input.is_action_pressed("crouch"):
				# Aerial Roll
				rotate_object_local(Vector3.FORWARD, steer * 3.5 * delta)
			else:
				# Aerial Yaw
				rotate_object_local(Vector3.UP, steer * 2.8 * delta)

		# Aerial thrust when boosting mid-air
		if is_boosting:
			var fwd = -global_transform.basis.z
			velocity += fwd * (acceleration * 0.7 * delta)

func replenish_boost(amount: float) -> void:
	current_boost = min(max_boost, current_boost + amount)
	boost_updated.emit(current_boost, max_boost)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.boost_amount_changed.emit(current_boost, max_boost)

