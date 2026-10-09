class_name AeroMovingPlatform
extends AnimatableBody3D

## Kinetic dynamic stunt platform for AeroRush.
## Moves and/or rotates across 3D space with continuous physics velocity transfer,
## allowing vehicles to land, drive, and launch from moving surfaces without sliding or clipping.

@export var movement_axis: Vector3 = Vector3(1.0, 0.0, 0.0)
@export var movement_distance: float = 24.0
@export var movement_speed: float = 1.0
@export var is_rotating: bool = false
@export var rotation_axis: Vector3 = Vector3(0.0, 1.0, 0.0)
@export var rotation_speed_deg: float = 18.0
@export var oscillation_type: int = 0 # 0: SINE, 1: PINGPONG, 2: ROTATE_ONLY

var base_position: Vector3 = Vector3.ZERO
var base_rotation_deg: Vector3 = Vector3.ZERO
var elapsed_time: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1 # AeroConstants.LAYER_WORLD
	collision_mask = 0
	base_position = global_position
	base_rotation_deg = global_rotation_degrees

func _physics_process(delta: float) -> void:
	elapsed_time += delta

	var prev_pos = global_position

	if movement_distance > 0.001 and movement_axis.length_squared() > 0.001:
		var normalized_axis = movement_axis.normalized()
		var offset = sin(elapsed_time * movement_speed) * (movement_distance * 0.5)
		global_position = base_position + normalized_axis * offset

	if is_rotating and rotation_axis.length_squared() > 0.001:
		rotate_object_local(rotation_axis.normalized(), deg_to_rad(rotation_speed_deg * delta))

	# Godot 4 AnimatableBody3D automatically computes constant_linear_velocity
	# and constant_angular_velocity to propel contacting CharacterBody3D and RigidBody3D.
	if delta > 0.0:
		constant_linear_velocity = (global_position - prev_pos) / delta
