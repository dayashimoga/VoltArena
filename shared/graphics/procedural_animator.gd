class_name ProceduralAnimator
extends RefCounted

## Procedural Animator for multi-part compound 3D meshes
## Provides organic limb swinging, locomotion bobbing, weapon recoil, and death dynamics
## without requiring heavy external skeletal rigs.

static func animate_biped(
	time_sec: float,
	speed: float,
	left_arm: Node3D,
	right_arm: Node3D,
	left_leg: Node3D,
	right_leg: Node3D,
	torso: Node3D = null,
	is_moving: bool = false,
	is_attacking: bool = false
) -> void:
	var move_factor: float = clampf(speed / 6.0, 0.0, 1.5)
	var freq: float = 9.0 if is_moving else 2.0

	if is_moving and move_factor > 0.05:
		var cycle: float = time_sec * freq
		var leg_swing: float = sin(cycle) * 0.7 * move_factor
		var arm_swing: float = sin(cycle) * 0.6 * move_factor

		if left_leg:
			left_leg.rotation.x = leg_swing
		if right_leg:
			right_leg.rotation.x = -leg_swing
		if left_arm and not is_attacking:
			left_arm.rotation.x = -arm_swing
		if right_arm and not is_attacking:
			right_arm.rotation.x = arm_swing

		if torso:
			torso.position.y = 0.9 + abs(sin(cycle * 2.0)) * 0.08 * move_factor
			torso.rotation.y = sin(cycle) * 0.08 * move_factor
	else:
		# Idle breathing
		var breathe: float = sin(time_sec * 2.5) * 0.03
		if left_arm and not is_attacking:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, breathe, 0.1)
			left_arm.rotation.z = lerp_angle(left_arm.rotation.z, 0.1, 0.1)
		if right_arm and not is_attacking:
			right_arm.rotation.x = lerp_angle(right_arm.rotation.x, -breathe, 0.1)
			right_arm.rotation.z = lerp_angle(right_arm.rotation.z, -0.1, 0.1)
		if left_leg:
			left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, 0.1)
		if right_leg:
			right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, 0.1)
		if torso:
			torso.position.y = lerp(torso.position.y, 0.9, 0.1)
			torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, 0.1)

	if is_attacking and right_arm:
		right_arm.rotation.x = lerp_angle(right_arm.rotation.x, -PI * 0.45, 0.2)

static func animate_crawler(
	time_sec: float,
	speed: float,
	legs: Array[Node3D],
	body: Node3D = null,
	is_moving: bool = false
) -> void:
	var move_factor: float = clampf(speed / 5.0, 0.0, 1.5)
	var freq: float = 14.0 if is_moving else 3.0
	var cycle: float = time_sec * freq

	for i in range(legs.size()):
		var leg = legs[i]
		if not is_instance_valid(leg):
			continue
		var phase_offset: float = float(i) * (PI * 0.5)
		if is_moving and move_factor > 0.05:
			var swing_z: float = sin(cycle + phase_offset) * 0.45 * move_factor
			var lift_y: float = max(0.0, cos(cycle + phase_offset)) * 0.25 * move_factor
			leg.rotation.z = swing_z
			leg.position.y = lift_y
		else:
			leg.rotation.z = lerp_angle(leg.rotation.z, sin(time_sec * 2.0 + phase_offset) * 0.05, 0.1)

	if body:
		if is_moving and move_factor > 0.05:
			body.position.y = 0.35 + sin(cycle * 2.0) * 0.05 * move_factor
		else:
			body.position.y = 0.35

static func animate_vehicle_suspension(
	car_body: Node3D,
	wheels: Array[Node3D],
	steering_angle: float,
	wheel_rot_speed: float,
	bounce_offset: float,
	delta: float
) -> void:
	if not is_instance_valid(car_body):
		return

	# Body roll and pitch based on bounce
	car_body.position.y = lerp(car_body.position.y, bounce_offset, clampf(delta * 12.0, 0.0, 1.0))

	for i in range(wheels.size()):
		var wheel = wheels[i]
		if not is_instance_valid(wheel):
			continue
		# Spin around X axis
		wheel.rotate_x(wheel_rot_speed * delta)
		# Steer front wheels (indices 0 and 1)
		if i < 2:
			wheel.rotation.y = steering_angle

static func calculate_weapon_sway(
	mouse_motion: Vector2,
	sway_amount: float = 0.002,
	max_sway: float = 0.04
) -> Vector3:
	var sway_x: float = clampf(-mouse_motion.x * sway_amount, -max_sway, max_sway)
	var sway_y: float = clampf(mouse_motion.y * sway_amount, -max_sway, max_sway)
	return Vector3(sway_x, sway_y, 0.0)

static func calculate_weapon_bob(
	time_sec: float,
	speed: float,
	bob_amount: float = 0.015
) -> Vector3:
	if speed < 0.2:
		return Vector3.ZERO
	var factor: float = clampf(speed / 7.0, 0.0, 1.0)
	var bob_x: float = cos(time_sec * 8.0) * bob_amount * factor
	var bob_y: float = abs(sin(time_sec * 8.0)) * bob_amount * factor
	return Vector3(bob_x, -bob_y, 0.0)
