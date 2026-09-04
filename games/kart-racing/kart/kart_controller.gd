class_name KartController
extends CharacterBody3D

signal drift_boost_triggered(boost_level: int)

@export var base_speed: float = 26.0
@export var boost_top_speed: float = 38.0
@export var acceleration: float = 24.0
@export var brake_deceleration: float = 32.0
@export var steer_speed: float = 3.2
@export var drift_steer_speed: float = 4.2
@export var gravity: float = 25.0

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

var kart_visual: Node3D
var front_wheels: Array[MeshInstance3D] = []

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES | GameConstants.LAYER_CHECKPOINTS

	setup_kart_visual()

func setup_kart_visual() -> void:
	kart_visual = Node3D.new()
	kart_visual.name = "KartVisual"
	add_child(kart_visual)

	# Main aerodynamic chassis
	var body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 0.45, 2.4)
	body_mesh.mesh = box
	body_mesh.position = Vector3(0, 0.35, 0)
	var mat_name = "neon_cyan" if is_player else ("neon_orange" if racer_id == 1 else "neon_green")
	body_mesh.material_override = MaterialGenerator.get_material(mat_name)
	kart_visual.add_child(body_mesh)

	# Rear Spoiler
	var spoiler = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(1.4, 0.1, 0.4)
	spoiler.mesh = s_box
	spoiler.position = Vector3(0, 0.75, 1.1)
	spoiler.material_override = MaterialGenerator.get_material("dark_hull")
	kart_visual.add_child(spoiler)

	# Driver Helmet
	var helmet = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	helmet.mesh = sphere
	helmet.position = Vector3(0, 0.7, -0.1)
	helmet.material_override = MaterialGenerator.get_material("gold_pickup")
	kart_visual.add_child(helmet)

	# Wheels
	var wheel_offsets = [
		Vector3(-0.7, 0.25, -0.8),
		Vector3(0.7, 0.25, -0.8),
		Vector3(-0.75, 0.28, 0.8),
		Vector3(0.75, 0.28, 0.8)
	]
	for i in range(wheel_offsets.size()):
		var w = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.28
		cyl.bottom_radius = 0.28
		cyl.height = 0.22
		w.mesh = cyl
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = wheel_offsets[i]
		w.material_override = MaterialGenerator.get_material("dark_hull")
		kart_visual.add_child(w)
		if i < 2:
			front_wheels.append(w)

	# Collision
	var col = CollisionShape3D.new()
	var b_shape = BoxShape3D.new()
	b_shape.size = Vector3(1.5, 0.8, 2.5)
	col.shape = b_shape
	col.position = Vector3(0, 0.45, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_player and not race_finished:
		handle_player_input(delta)

	# Process boost timer
	if boost_timer > 0.0:
		boost_timer -= delta

	move_and_slide()

func handle_player_input(delta: float) -> void:
	var im = get_node_or_null("/root/InputManager")
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
			if get_node_or_null("/root/AudioManager"):
				get_node("/root/AudioManager").play_sound("drift_screech", 1.2)
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
	if drift_charge_time >= 2.0:
		boost_level = 2 # Super Boost
		boost_timer = 2.2
	elif drift_charge_time >= 0.8:
		boost_level = 1 # Regular Boost
		boost_timer = 1.2

	if boost_level > 0:
		drift_boost_triggered.emit(boost_level)
		if get_node_or_null("/root/AudioManager"):
			get_node("/root/AudioManager").play_sound("jump", 1.4)
		if get_node_or_null("/root/EventBus"):
			get_node("/root/EventBus").show_toast_requested.emit("DRIFT BOOST!", Color(0.0, 1.0, 1.0))
	drift_charge_time = 0.0

func apply_item_boost(duration: float) -> void:
	boost_timer = max(boost_timer, duration)
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").play_sound("jump", 1.5)
