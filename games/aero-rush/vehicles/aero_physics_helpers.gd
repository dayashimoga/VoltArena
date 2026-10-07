class_name AeroPhysicsHelpers
extends RefCounted

## Math and physics utilities for 3D stunt driving: surface-normal gravity alignment,
## loop adhesion, centrifugal forces, airborne rotation, and landing shock analysis.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

## Computes the effective gravity vector given current ground normal and vehicle velocity.
## When grounded on steep walls or loops at sufficient speed, gravity aligns with the surface normal.
static func calculate_effective_gravity(
	ground_normal: Vector3,
	forward_speed: float,
	is_grounded: bool,
	base_gravity: float = AeroConstants.DEFAULT_GRAVITY
) -> Vector3:
	if not is_grounded:
		# Pure world gravity when completely detached in air
		return Vector3(0, -base_gravity, 0)

	var normal_dot_up = ground_normal.dot(Vector3.UP)

	# If relatively flat or gentle slope, standard gravity applies
	if normal_dot_up > 0.75:
		return Vector3(0, -base_gravity, 0)

	# If driving on steep wall (normal_dot_up <= 0.75) or inverted loop (normal_dot_up < 0.0):
	# Adhesion requires speed >= MIN_LOOP_SPEED
	if absf(forward_speed) >= AeroConstants.MIN_LOOP_SPEED:
		# Effective down direction is opposite to surface normal
		# Scale adhesion downforce with speed (centrifugal grip)
		var adhesion_mult = clampf(absf(forward_speed) / 25.0, 1.0, 2.2)
		return -ground_normal * (base_gravity * adhesion_mult)
	else:
		# If speed drops below threshold, blend between surface down and world down (vehicle falls off)
		var speed_ratio = clampf(absf(forward_speed) / AeroConstants.MIN_LOOP_SPEED, 0.0, 1.0)
		var surface_down = -ground_normal * base_gravity
		var world_down = Vector3(0, -base_gravity, 0)
		return world_down.lerp(surface_down, speed_ratio)

## Evaluates landing quality based on the angle between vehicle local up and track ground normal.
static func evaluate_landing(vehicle_up: Vector3, ground_normal: Vector3) -> Dictionary:
	var dot_prod = clampf(vehicle_up.dot(ground_normal), -1.0, 1.0)
	var angle_deg = rad_to_deg(acos(dot_prod))

	if angle_deg <= AeroConstants.PERFECT_LANDING_MAX_ANGLE_DEG:
		return {
			"quality": "perfect",
			"angle_deg": angle_deg,
			"score_bonus": 500,
			"boost_refill": 0.35, # 35% boost instant refund
			"stunt_id": AeroConstants.StuntType.PERFECT_LANDING,
			"is_crash": false
		}
	elif angle_deg <= AeroConstants.CLEAN_LANDING_MAX_ANGLE_DEG:
		return {
			"quality": "clean",
			"angle_deg": angle_deg,
			"score_bonus": 150,
			"boost_refill": 0.10,
			"stunt_id": -1,
			"is_crash": false
		}
	elif angle_deg >= AeroConstants.CRASH_LANDING_MIN_ANGLE_DEG:
		return {
			"quality": "crash",
			"angle_deg": angle_deg,
			"score_bonus": 0,
			"boost_refill": 0.0,
			"stunt_id": -1,
			"is_crash": true
		}
	else:
		return {
			"quality": "rough",
			"angle_deg": angle_deg,
			"score_bonus": 50,
			"boost_refill": 0.0,
			"stunt_id": -1,
			"is_crash": false
		}

## Calculates smooth quaternion / basis alignment towards target surface normal
## preserving vehicle forward driving heading as closely as possible.
static func align_basis_to_normal(current_basis: Basis, target_normal: Vector3, weight: float) -> Basis:
	if target_normal.length_squared() < 0.001 or weight <= 0.0:
		return current_basis

	var cur_up = current_basis.y.normalized()
	var tgt_up = target_normal.normalized()

	if cur_up.is_equal_approx(tgt_up) or not cur_up.is_finite() or not tgt_up.is_finite():
		return current_basis

	# Cross product gives axis of rotation
	var rot_axis = cur_up.cross(tgt_up)
	if rot_axis.length_squared() < 0.0001:
		rot_axis = current_basis.x.normalized()
		if rot_axis.length_squared() < 0.0001:
			rot_axis = Vector3.RIGHT
	else:
		rot_axis = rot_axis.normalized()

	if not rot_axis.is_finite():
		return current_basis

	var dot_val = clampf(cur_up.dot(tgt_up), -1.0, 1.0)
	var angle = acos(dot_val) * clampf(weight, 0.0, 1.0)
	if is_nan(angle) or absf(angle) < 0.0001:
		return current_basis

	var q_rot = Quaternion(rot_axis, angle)
	var new_basis = Basis(q_rot) * current_basis
	return new_basis.orthonormalized()

## Projects velocity vector along ground plane normal to ensure smooth incline traversal
## and completely eliminate collision lip snagging.
static func project_velocity_on_plane(velocity: Vector3, plane_normal: Vector3) -> Vector3:
	var n = plane_normal.normalized()
	var v_len = velocity.length()
	if v_len < 0.001:
		return Vector3.ZERO
	var projected = velocity - n * velocity.dot(n)
	# Retain kinetic energy along tangent
	if projected.length_squared() > 0.0001:
		return projected.normalized() * v_len
	return projected

## Predicts landing surface along trajectory or downward.
static func predict_landing(space_state: PhysicsDirectSpaceState3D, origin: Vector3, velocity: Vector3, max_dist: float = 20.0) -> Dictionary:
	if not space_state:
		return {"found": false}

	var ray_dir = Vector3.DOWN
	if velocity.length_squared() > 1.0:
		ray_dir = (velocity.normalized() + Vector3.DOWN * 0.5).normalized()

	var query = PhysicsRayQueryParameters3D.create(origin, origin + ray_dir * max_dist, AeroConstants.LAYER_WORLD)
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		# Try straight down fallback
		var down_query = PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * max_dist, AeroConstants.LAYER_WORLD)
		result = space_state.intersect_ray(down_query)
		if result.is_empty():
			return {"found": false}

	var hit_pos = result.get("position", Vector3.ZERO) as Vector3
	var hit_normal = result.get("normal", Vector3.UP) as Vector3
	var dist = origin.distance_to(hit_pos)

	return {
		"found": true,
		"position": hit_pos,
		"normal": hit_normal,
		"distance": dist
	}

## Calculates horizon stabilization tending toward wheels-down landing.
static func calculate_horizon_stabilization(current_basis: Basis, target_up: Vector3, weight: float) -> Basis:
	return align_basis_to_normal(current_basis, target_up, weight)

