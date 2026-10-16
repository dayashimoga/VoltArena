class_name FloatingOrigin
extends Node

## Coordinated Floating Origin System.
## Rebases the world when player displacement exceeds 5,000 meters.
## Preserves velocities, momentum, relative transforms, mission waypoints,
## and visual continuity without physics explosions or contact discontinuities.

signal world_shifted(shift_vector: Vector3, cumulative_offset: Vector3)

@export var target_node: Node3D
@export var rebase_threshold_meters: float = 5000.0
@export var shift_vertical_axis: bool = false ## True for full 3D shift; false for XZ planar rebase

var cumulative_offset: Vector3 = Vector3.ZERO
var total_shifts_performed: int = 0
var _registered_nodes: Array[Node3D] = []

func _ready() -> void:
	if not target_node:
		var parent = get_parent()
		if parent is Node3D:
			target_node = parent

func register_shifting_node(node: Node3D) -> void:
	if node and not node in _registered_nodes:
		_registered_nodes.append(node)

func unregister_shifting_node(node: Node3D) -> void:
	_registered_nodes.erase(node)

func _physics_process(_delta: float) -> void:
	if not target_node or not is_instance_valid(target_node):
		return

	var current_pos = target_node.global_position
	var dist = current_pos.length() if shift_vertical_axis else Vector2(current_pos.x, current_pos.z).length()

	if dist >= rebase_threshold_meters:
		rebase_world(current_pos)

## Executes a synchronized physics-safe shift across all world nodes and the target.
func rebase_world(displacement: Vector3) -> void:
	var shift_vector = displacement
	if not shift_vertical_axis:
		shift_vector.y = 0.0 # Maintain MSL altitude datum

	cumulative_offset += shift_vector
	total_shifts_performed += 1

	# Shift target RigidBody preserving velocity and angular momentum
	if target_node is RigidBody3D:
		var rb = target_node as RigidBody3D
		var lin_vel = rb.linear_velocity
		var ang_vel = rb.angular_velocity
		if rb.is_inside_tree():
			rb.global_position -= shift_vector
		else:
			rb.position -= shift_vector
		rb.linear_velocity = lin_vel
		rb.angular_velocity = ang_vel
	elif target_node:
		if target_node.is_inside_tree():
			target_node.global_position -= shift_vector
		else:
			target_node.position -= shift_vector

	# Shift all registered world scenery, terrain, runway, and props
	for node in _registered_nodes:
		if is_instance_valid(node):
			if node.is_inside_tree():
				node.global_position -= shift_vector
			else:
				node.position -= shift_vector

	world_shifted.emit(shift_vector, cumulative_offset)

## Converts local coordinates to absolute world coordinates
func to_absolute_position(local_pos: Vector3) -> Vector3:
	return local_pos + cumulative_offset

## Converts absolute world coordinates to current local coordinates
func to_local_position(absolute_pos: Vector3) -> Vector3:
	return absolute_pos - cumulative_offset
