class_name ModularRobot
extends CharacterBody3D

## ModularRobot: Physically simulated customizable robot entity.
## Assembles chassis, locomotion, power core, and modules from blueprints.
## Real physics: mass, acceleration, traction, grabbing, boosting, and self-righting.

signal power_updated(current: float, max_pwr: float)
signal object_grabbed(obj: Node3D)
signal object_released()

const RobotDataScript = preload("res://games/roboforge-arena/robot/robot_data.gd")

@export var is_player_controlled: bool = true

var blueprint: Dictionary = {}
var stats: Dictionary = {}

var current_power: float = 100.0
var forward_speed: float = 0.0
var is_boosting: bool = false
var is_magnetic_active: bool = false
var grabbed_object: RigidBody3D = null

# Visual & Attachment Nodes
var visual_root: Node3D
var front_socket: Marker3D
var top_socket: Marker3D
var rear_socket: Marker3D
var grab_area: Area3D
var magnet_area: Area3D

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player_controlled else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PICKUPS | GameConstants.LAYER_BALL
	if blueprint.is_empty():
		load_blueprint(RobotDataScript.get_default_blueprint())

func load_blueprint(bp: Dictionary) -> void:
	blueprint = bp.duplicate()
	stats = RobotDataScript.calculate_stats(blueprint)
	current_power = stats.get("power_capacity", 100.0)
	rebuild_visuals()

func rebuild_visuals() -> void:
	if visual_root:
		visual_root.queue_free()

	visual_root = MeshBuilder.build_modular_robot_model(blueprint)
	add_child(visual_root)

	var ch_id = blueprint.get("chassis", "scout")
	var modules: Array = blueprint.get("modules", [])

	var ch_size = Vector3(1.8, 0.7, 2.4)
	if ch_id == "titan":
		ch_size = Vector3(2.4, 0.9, 3.2)
	elif ch_id == "scout":
		ch_size = Vector3(1.4, 0.55, 1.8)

	front_socket = visual_root.get_node_or_null("FrontSocket") as Marker3D
	top_socket = visual_root.get_node_or_null("TopSocket") as Marker3D
	rear_socket = visual_root.get_node_or_null("RearSocket") as Marker3D

	if front_socket == null:
		front_socket = Marker3D.new()
		front_socket.position = Vector3(0, 0.58, -ch_size.z * 0.5 - 0.15)
		visual_root.add_child(front_socket)
	if top_socket == null:
		top_socket = Marker3D.new()
		top_socket.position = Vector3(0, 0.65 + ch_size.y * 0.5 + 0.1, 0)
		visual_root.add_child(top_socket)
	if rear_socket == null:
		rear_socket = Marker3D.new()
		rear_socket.position = Vector3(0, 0.65, ch_size.z * 0.5 + 0.15)
		visual_root.add_child(rear_socket)

	# Setup Grabber Area if hydraulic grabber is equipped
	if modules.has("hydraulic_grabber"):
		grab_area = Area3D.new()
		grab_area.collision_layer = 0
		grab_area.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL | GameConstants.LAYER_PICKUPS
		var col_g = CollisionShape3D.new()
		var b_g = BoxShape3D.new()
		b_g.size = Vector3(1.4, 1.0, 1.4)
		col_g.shape = b_g
		col_g.position = Vector3(0, 0, -0.6)
		grab_area.add_child(col_g)
		front_socket.add_child(grab_area)
	else:
		grab_area = null

	# Setup Magnetic Area if magnetic arm is equipped
	if modules.has("magnetic_arm"):
		magnet_area = Area3D.new()
		magnet_area.collision_layer = 0
		magnet_area.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_BALL | GameConstants.LAYER_PICKUPS
		var col_m = CollisionShape3D.new()
		var s_m = SphereShape3D.new()
		s_m.radius = 6.0
		col_m.shape = s_m
		magnet_area.add_child(col_m)
		top_socket.add_child(magnet_area)
	else:
		magnet_area = null

	# Update collision shape
	for c in get_children():
		if c is CollisionShape3D:
			c.queue_free()

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(ch_size.x + 0.4, ch_size.y + 0.8, ch_size.z + 0.4)
	col.shape = box_shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 24.0 * delta

	# Regenerate power
	var rech = stats.get("recharge_rate", 15.0)
	var max_p = stats.get("power_capacity", 100.0)
	current_power = minf(max_p, current_power + rech * delta)
	power_updated.emit(current_power, max_p)

	if is_player_controlled:
		handle_player_input(delta)

	# Handle grabbed object physical tracking
	if grabbed_object and is_instance_valid(grabbed_object):
		var hold_pos = front_socket.global_position - global_transform.basis.z * 0.8
		grabbed_object.global_position = grabbed_object.global_position.lerp(hold_pos, delta * 18.0)
		grabbed_object.linear_velocity = velocity

	# Magnetic attraction field
	if is_magnetic_active and magnet_area:
		for b in magnet_area.get_overlapping_bodies():
			if b is RigidBody3D and b != grabbed_object:
				var to_magnet = (top_socket.global_position - b.global_position).normalized()
				b.apply_central_force(to_magnet * 45.0)

	move_and_slide()

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

	# Steer
	var turn_rate = stats.get("turning_speed", 2.8)
	if abs(forward_speed) > 0.2 or is_on_floor():
		rotate_y(steer * turn_rate * delta)

	# Acceleration & Braking
	var top_spd = stats.get("top_speed", 18.0)
	var accel = stats.get("acceleration", 25.0)
	if is_boosting and current_power > 15.0:
		top_spd *= 1.65
		current_power = maxf(0.0, current_power - 40.0 * delta)

	if throttle > 0.0:
		forward_speed = move_toward(forward_speed, top_spd, accel * delta)
	elif throttle < 0.0:
		forward_speed = move_toward(forward_speed, -top_spd * 0.5, accel * 1.2 * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 18.0 * delta)

	var fwd = -transform.basis.z
	velocity.x = fwd.x * forward_speed
	velocity.z = fwd.z * forward_speed

	# Jump (legs locomotion)
	var j_force = stats.get("jump_force", 0.0)
	if Input.is_action_just_pressed("jump") and is_on_floor() and j_force > 0.0:
		velocity.y = j_force
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("jump", 0.9, 1.1)

	# Tool / Module inputs
	if Input.is_action_just_pressed("fire"):
		toggle_grab()

	is_boosting = Input.is_action_pressed("boost") and blueprint.get("modules", []).has("rocket_booster")
	is_magnetic_active = Input.is_action_pressed("crouch") and blueprint.get("modules", []).has("magnetic_arm")

	# Self-righting recovery
	if Input.is_action_just_pressed("interact"):
		self_right()

func toggle_grab() -> void:
	if grabbed_object:
		release_object()
	else:
		try_grab_object()

func try_grab_object() -> void:
	if not grab_area:
		return
	for b in grab_area.get_overlapping_bodies():
		if b is RigidBody3D and b != self:
			grabbed_object = b
			grabbed_object.freeze = false
			object_grabbed.emit(b)
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am:
				am.play_sound("pickup_ammo", 1.2, 1.2)
			break

func release_object() -> void:
	if grabbed_object:
		grabbed_object.linear_velocity = -global_transform.basis.z * 5.0 + Vector3.UP * 2.0
		grabbed_object = null
		object_released.emit()
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("pickup_health", 0.9, 1.0)

func self_right() -> void:
	rotation.x = 0.0
	rotation.z = 0.0
	velocity = Vector3.ZERO
	global_position.y += 0.5
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("respawn", 1.2, 1.0)
