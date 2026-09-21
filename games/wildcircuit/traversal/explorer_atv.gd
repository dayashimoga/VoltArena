class_name ExplorerATV
extends CharacterBody3D

## ExplorerATV: High-traction expedition vehicle for WildCircuit.
## Features realistic acceleration, steering, night survey headlights, and mount/dismount.

signal mounted_state_changed(is_mounted: bool)

@export var max_speed: float = 16.0
@export var reverse_speed: float = 8.0
@export var acceleration: float = 24.0
@export var steer_speed: float = 2.6

var is_occupied: bool = false
var forward_speed: float = 0.0
var driver: Node3D = null
var headlight: SpotLight3D

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER
	collision_mask = GameConstants.LAYER_WORLD
	setup_visuals()

func setup_visuals() -> void:
	var visual = MeshBuilder.build_safari_atv_vehicle()
	add_child(visual)

	# Headlight for night expeditions
	headlight = SpotLight3D.new()
	headlight.position = Vector3(0, 0.8, -1.4)
	headlight.spot_range = 30.0
	headlight.spot_angle = 38.0
	headlight.light_energy = 3.0
	add_child(headlight)

	var col = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(2.0, 1.4, 2.8)
	col.shape = bs
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 24.0 * delta

	if is_occupied and driver:
		handle_driving(delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 20.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)

	move_and_slide()

func handle_driving(delta: float) -> void:
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

	if abs(forward_speed) > 0.5:
		var steer_dir = sign(forward_speed)
		rotate_y(steer * steer_speed * delta * steer_dir)

	if throttle > 0.0:
		forward_speed = move_toward(forward_speed, max_speed, acceleration * delta)
	elif throttle < 0.0:
		forward_speed = move_toward(forward_speed, -reverse_speed, acceleration * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 15.0 * delta)

	var fwd = -transform.basis.z
	velocity.x = fwd.x * forward_speed
	velocity.z = fwd.z * forward_speed

	if driver:
		driver.global_position = global_position + Vector3(0, 0.7, 0)

func mount(p_driver: Node3D) -> void:
	driver = p_driver
	is_occupied = true
	if "visible" in driver:
		driver.visible = false
	mounted_state_changed.emit(true)

func dismount() -> void:
	if driver:
		if "visible" in driver:
			driver.visible = true
		driver.global_position = global_position + global_transform.basis.x * 2.0 + Vector3.UP * 0.5
		driver = null
	is_occupied = false
	mounted_state_changed.emit(false)
