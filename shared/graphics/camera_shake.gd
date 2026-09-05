class_name CameraShake
extends RefCounted

## Trauma-based camera shake algorithm
## Provides smooth non-linear trauma decay and rotational + translational shake offsets

var trauma: float = 0.0
var trauma_power: int = 2
var decay_rate: float = 1.2
var max_pitch: float = 0.08
var max_yaw: float = 0.08
var max_roll: float = 0.1
var max_offset_x: float = 0.15
var max_offset_y: float = 0.15

var time_accum: float = 0.0

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func get_trauma() -> float:
	return trauma

func update(delta: float) -> Dictionary:
	if trauma <= 0.001:
		trauma = 0.0
		return {
			"offset": Vector3.ZERO,
			"rotation": Vector3.ZERO
		}

	trauma = max(0.0, trauma - decay_rate * delta)
	var shake: float = pow(trauma, trauma_power)
	time_accum += delta * 25.0

	var offset_x = sin(time_accum * 1.1) * max_offset_x * shake
	var offset_y = cos(time_accum * 1.3) * max_offset_y * shake
	var rot_pitch = sin(time_accum * 0.9) * max_pitch * shake
	var rot_yaw = cos(time_accum * 1.2) * max_yaw * shake
	var rot_roll = sin(time_accum * 1.5) * max_roll * shake

	return {
		"offset": Vector3(offset_x, offset_y, 0.0),
		"rotation": Vector3(rot_pitch, rot_yaw, rot_roll)
	}

func reset() -> void:
	trauma = 0.0
	time_accum = 0.0
