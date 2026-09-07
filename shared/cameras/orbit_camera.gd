class_name OrbitCamera3D
extends Node3D

## Reusable 3D Third-Person Orbit Camera with Collision Avoidance
## Features smooth spring-arm raycast clipping prevention, gamepad & mouse control,
## auto-recentering, and configurable sensitivity & FOV.

@export var target: Node3D
@export var target_offset: Vector3 = Vector3(0, 1.6, 0)
@export var distance: float = 5.0
@export var min_distance: float = 1.0
@export var max_distance: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var gamepad_sensitivity: float = 2.5
@export var smooth_speed: float = 12.0
@export var collision_margin: float = 0.25

var yaw: float = 0.0
var pitch: float = -0.2 # Slight downward angle
var camera: Camera3D

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	add_child(camera)
	top_level = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.3, 1.1)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# Handle gamepad right stick orbit
	var stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(stick_x) > 0.15:
		yaw -= stick_x * gamepad_sensitivity * delta
	if abs(stick_y) > 0.15:
		pitch = clampf(pitch - stick_y * gamepad_sensitivity * delta, -1.3, 1.1)

	var target_center = target.global_position + target_offset
	global_position = global_position.lerp(target_center, delta * smooth_speed)

	# Calculate desired camera position based on yaw and pitch
	var rot_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var desired_cam_dir = rot_basis * Vector3.BACK
	var desired_cam_pos = target_center + desired_cam_dir * distance

	# Collision raycast to prevent wall clipping
	var actual_distance = distance
	var space_state = get_world_3d().direct_space_state
	if space_state:
		var ray_query = PhysicsRayQueryParameters3D.create(target_center, desired_cam_pos)
		ray_query.collision_mask = GameConstants.LAYER_WORLD
		ray_query.exclude = [target.get_rid() if target is CollisionObject3D else RID()]
		var hit = space_state.intersect_ray(ray_query)
		if not hit.is_empty():
			var hit_dist = target_center.distance_to(hit.position) - collision_margin
			actual_distance = clampf(hit_dist, min_distance, distance)

	var final_cam_pos = target_center + desired_cam_dir * actual_distance
	camera.global_position = final_cam_pos
	camera.look_at(target_center, Vector3.UP)

func set_target(p_target: Node3D) -> void:
	target = p_target
	if is_instance_valid(target):
		global_position = target.global_position + target_offset

func recenter() -> void:
	if is_instance_valid(target):
		yaw = target.rotation.y + PI
		pitch = -0.2
