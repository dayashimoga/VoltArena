class_name KartController
extends CharacterBody3D

signal drift_boost_triggered(boost_level: int)

@export var kart_type: String = "speeder" # "speeder", "phantom", "enforcer"
@export var base_speed: float = 26.0
@export var boost_top_speed: float = 38.0
@export var acceleration: float = 24.0
@export var brake_deceleration: float = 32.0
@export var steer_speed: float = 3.2
@export var drift_steer_speed: float = 4.2
@export var gravity: float = 25.0

# Aliases for compatibility with tests and external callers
var max_speed: float:
	get: return base_speed
	set(v): base_speed = v

var acceleration_force: float:
	get: return acceleration
	set(v): acceleration = v

var steering_speed: float:
	get: return steer_speed
	set(v): steer_speed = v

@export var racer_id: int = 0
@export var racer_name: String = "Player"
@export var is_player: bool = true

# Drift & Boost Mechanics
var is_drifting: bool = false
var drift_direction: float = 0.0 # -1 left, +1 right
var drift_charge_time: float = 0.0
var boost_timer: float = 0.0
var forward_speed: float = 0.0

# Race Progression
var current_lap: int = 1
var next_checkpoint_index: int = 0
var total_checkpoints_hit: int = 0
var lap_start_time: float = 0.0
var best_lap_time: float = 999.0
var race_finished: bool = false
var last_valid_checkpoint_pos: Vector3 = Vector3.ZERO
var last_valid_checkpoint_rot: float = 0.0

var kart_visual: Node3D
var front_wheels: Array[MeshInstance3D] = []

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES | GameConstants.LAYER_CHECKPOINTS

	add_to_group("karts")
	if is_player:
		add_to_group("players")
	else:
		add_to_group("ai_racers")

	last_valid_checkpoint_pos = global_position
	last_valid_checkpoint_rot = rotation.y

	setup_kart_archetype()
	setup_kart_visual()

func setup_kart_archetype() -> void:
	match kart_type:
		"phantom":
			base_speed = 28.5
			boost_top_speed = 42.0
			acceleration = 21.0
			steer_speed = 3.0
		"enforcer":
			base_speed = 24.5
			boost_top_speed = 36.0
			acceleration = 28.0
			steer_speed = 3.6
		_:
			base_speed = 26.0
			boost_top_speed = 38.0
			acceleration = 24.0
			steer_speed = 3.2

func setup_kart_visual() -> void:
	var kart_col = Color(0.2, 1.0, 0.5) if is_player else (Color(1.0, 0.5, 0.0) if racer_id == 1 else (Color(0.8, 0.2, 1.0) if racer_id == 2 else Color(0.0, 0.85, 1.0)))
	kart_visual = MeshBuilder.build_drift_kart(kart_col, kart_type)
	add_child(kart_visual)

	for child in kart_visual.get_children():
		if child.name.begins_with("FrontWheel") and child is MeshInstance3D:
			front_wheels.append(child)

	# Collision
	var col = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(1.5, 0.8, 2.5)
	col.shape = b_shape
	col.position = Vector3(0, 0.45, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		if is_player and not race_finished:
			handle_player_input(delta)
		return

	# Automatic recovery if fallen off track or out of bounds
	if global_position.y < -3.5 or global_position.distance_to(last_valid_checkpoint_pos) > 120.0:
		recover_to_checkpoint()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Only accept controls if race has started
	var rm = get_tree().root.find_child("RaceManager", true, false)
	var is_countdown = (rm and rm.get("current_state") == 0) # RaceState.COUNTDOWN

	if is_player and not race_finished and not is_countdown:
		handle_player_input(delta)

	# Process boost timer
	if boost_timer > 0.0:
		boost_timer -= delta

	move_and_slide()

func recover_to_checkpoint() -> void:
	global_position = last_valid_checkpoint_pos + Vector3(0, 0.6, 0)
	rotation.y = last_valid_checkpoint_rot
	velocity = Vector3.ZERO
	forward_speed = 0.0
	is_drifting = false
	drift_charge_time = 0.0
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and is_player:
		bus.show_toast_requested.emit("RECOVERED TO TRACK", Color(1.0, 0.8, 0.2))

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

	var want_drift = Input.is_action_pressed("drift") or Input.is_action_pressed("jump")
	apply_kart_controls(throttle, steer, want_drift, delta)

func apply_kart_controls(throttle: float, steer: float, want_drift: bool, delta: float) -> void:
	# Drift mechanics handling
	if want_drift and abs(steer) > 0.2 and is_on_floor() and forward_speed > 10.0:
		if not is_drifting:
			is_drifting = true
			drift_direction = sign(steer)
			drift_charge_time = 0.0
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am:
				am.play_sound("drift_screech", 1.2)
		drift_charge_time += delta
	else:
		if is_drifting:
			# Release drift to trigger boost!
			trigger_drift_boost()
			is_drifting = false

	# Steering
	var effective_steer_speed = drift_steer_speed if is_drifting else steer_speed
	var steer_multiplier = 1.0
	if is_drifting:
		# During drift, kart slides sideways
		steer_multiplier = 1.35 * drift_direction

	if abs(forward_speed) > 0.5:
		rotate_y(steer * effective_steer_speed * steer_multiplier * delta)

	# Target top speed
	var max_active_speed = base_speed
	if boost_timer > 0.0:
		max_active_speed = boost_top_speed
	elif is_drifting:
		max_active_speed = base_speed * 0.92 # Slight scrub while drifting

	if throttle > 0.0:
		forward_speed = move_toward(forward_speed, max_active_speed, acceleration * delta)
	elif throttle < 0.0:
		forward_speed = move_toward(forward_speed, -10.0, brake_deceleration * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 10.0 * delta)

	var fwd = -transform.basis.z
	velocity.x = fwd.x * forward_speed
	velocity.z = fwd.z * forward_speed

	# Visual wheel turning
	for fw in front_wheels:
		fw.rotation_degrees.y = -steer * 28.0

func trigger_drift_boost() -> void:
	var boost_level = 0
	var am = GameConstants.get_autoload(self, "AudioManager")
	var bus = GameConstants.get_autoload(self, "EventBus")

	if drift_charge_time >= 2.5:
		boost_level = 3 # Tier 3: Ultra Mini-Turbo (Purple sparks)
		boost_timer = 3.2
		if am:
			am.play_sound("drift_turbo_3", 1.0, 1.8)
		if bus and is_player:
			bus.show_toast_requested.emit("ULTRA MINI-TURBO! +++", Color(1.0, 0.2, 0.9))
	elif drift_charge_time >= 1.5:
		boost_level = 2 # Tier 2: Super Mini-Turbo (Orange sparks)
		boost_timer = 2.0
		if am:
			am.play_sound("drift_screech", 1.4, 1.2)
		if bus and is_player:
			bus.show_toast_requested.emit("SUPER MINI-TURBO! ++", Color(1.0, 0.6, 0.1))
	elif drift_charge_time >= 0.7:
		boost_level = 1 # Tier 1: Mini-Turbo (Blue sparks)
		boost_timer = 1.0
		if am:
			am.play_sound("jump", 1.4)
		if bus and is_player:
			bus.show_toast_requested.emit("MINI-TURBO! +", Color(0.2, 0.8, 1.0))

	if boost_level > 0:
		drift_boost_triggered.emit(boost_level)
	drift_charge_time = 0.0

func apply_item_boost(duration: float) -> void:
	boost_timer = max(boost_timer, duration)
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("jump", 1.5)
