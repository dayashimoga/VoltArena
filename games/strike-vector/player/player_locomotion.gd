class_name PlayerLocomotion
extends RefCounted

## Locomotion state and physics calculation engine for Strike Vector.
## Implements: Walk, Run, Sprint, Crouch, Slide, Jump (with Coyote/Buffer), Dodge/Roll, and Ladder/Zipline physics.

enum LocomotionState {
	WALK,
	RUN,
	SPRINT,
	CROUCH,
	SLIDE,
	AIRBORNE,
	DODGE,
	LADDER,
	ZIPLINE,
	MANTLE
}

# Speed profiles (m/s)
var speed_walk: float = 4.5
var speed_run: float = 7.5
var speed_sprint: float = 10.5
var speed_crouch: float = 2.8
var speed_slide_initial: float = 12.5
var speed_slide_decay: float = 8.0
var speed_dodge: float = 14.0

var jump_velocity: float = 7.8
var gravity: float = 20.0
var acceleration: float = 38.0
var deceleration: float = 30.0
var air_control_factor: float = 0.45

# Jump buffer & Coyote timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
const COYOTE_TIME: float = 0.15
const JUMP_BUFFER_TIME: float = 0.15

# Runtime State
var current_state: LocomotionState = LocomotionState.RUN
var slide_speed: float = 0.0
var dodge_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var is_sliding: bool = false
var is_dodging: bool = false
var is_on_ladder: bool = false
var is_on_zipline: bool = false

func update_timers(delta: float, is_on_floor: bool) -> void:
	if is_on_floor:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)

	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_dodging = false

	if is_sliding:
		slide_speed = maxf(speed_crouch, slide_speed - speed_slide_decay * delta)
		if slide_speed <= speed_crouch + 0.5:
			is_sliding = false

func buffer_jump() -> void:
	jump_buffer_timer = JUMP_BUFFER_TIME

func can_jump(is_on_floor: bool) -> bool:
	return (is_on_floor or coyote_timer > 0.0) and (jump_buffer_timer > 0.0)

func consume_jump() -> float:
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	return jump_velocity

func start_dodge(dir: Vector3) -> void:
	is_dodging = true
	dodge_timer = 0.28
	dodge_direction = dir.normalized() if dir.length_squared() > 0.01 else Vector3.FORWARD

func start_slide(forward_dir: Vector3) -> void:
	is_sliding = true
	slide_speed = speed_slide_initial

func calculate_horizontal_velocity(current_vel: Vector3, input_dir: Vector3, is_sprinting: bool, is_crouching: bool, is_ads: bool, is_on_floor: bool, delta: float) -> Vector3:
	if is_dodging:
		return dodge_direction * speed_dodge

	if is_sliding:
		var s_dir = current_vel.normalized()
		if s_dir.length_squared() < 0.01:
			s_dir = input_dir.normalized()
		return s_dir * slide_speed

	var target_speed = speed_run
	if is_crouching:
		target_speed = speed_crouch
	elif is_sprinting and input_dir.dot(Vector3.FORWARD) < 0.1: # moving forward
		target_speed = speed_sprint

	if is_ads:
		target_speed *= 0.65

	var target_vel = input_dir.normalized() * target_speed
	var accel = acceleration if is_on_floor else acceleration * air_control_factor
	var decel = deceleration if is_on_floor else deceleration * air_control_factor

	var rate = accel if input_dir.length_squared() > 0.01 else decel
	return current_vel.move_toward(target_vel, rate * delta)
