class_name AeroGravityBody
extends RefCounted

## AeroGravityBody: Surface-Normal Relative Gravity & Centrifugal Adhesion Physics
## Implements continuous surface-normal solver, 4-corner ground raycasts,
## centrifugal downforce, and singularity-free quaternion slerp chassis alignment.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

const DEFAULT_GRAVITY: float = 9.81
const SURFACE_GRAVITY_INVERTED: float = 24.5 # 2.5G on inverted track sections
const DOWNFORCE_COEFF: float = 0.85 # C_downforce
const GROUND_PROXIMITY_THRESHOLD: float = 1.2 # h <= 1.2m
const MIN_ADHESION_SPEED: float = 16.0 # v >= 16.0 m/s
const ALIGNMENT_STIFFNESS_DEFAULT: float = 16.0

## Evaluates the dynamic effective gravity vector relative to the track surface normal.
## On inverted or vertical track sections, applies positive track adhesion gravity (24.5 m/s²).
static func calculate_effective_gravity(
	ground_normal: Vector3,
	forward_speed: float,
	is_grounded: bool,
	base_gravity: float = DEFAULT_GRAVITY
) -> Vector3:
	if not is_grounded:
		# Detached in free flight: pure world gravity
		return Vector3(0.0, -base_gravity, 0.0)

	var normal_dot_up: float = ground_normal.dot(Vector3.UP)

	# Inverted track section or wall ride (loops, corkscrews, 90° wall rides)
	if normal_dot_up <= 0.75:
		# Positive track adhesion: 24.5 m/s² (2.5G)
		return -ground_normal.normalized() * SURFACE_GRAVITY_INVERTED
	else:
		# Standard upright roadway
		return Vector3(0.0, -base_gravity, 0.0)

## Computes aerodynamic and centrifugal downforce:
## F_down = -n_track * (m * g_surface + C_downforce * v^2)
static func calculate_downforce(
	track_normal: Vector3,
	vehicle_mass: float,
	forward_speed: float,
	is_inverted: bool = false
) -> Vector3:
	var g_surf: float = SURFACE_GRAVITY_INVERTED if is_inverted else DEFAULT_GRAVITY
	var v_sq: float = forward_speed * forward_speed
	var downforce_mag: float = (vehicle_mass * g_surf * 0.25) + (DOWNFORCE_COEFF * v_sq)
	return -track_normal.normalized() * downforce_mag

## Casts and updates 4-corner suspension/adhesion rays, returning average surface normal and ground proximity.
static func sample_4corner_rays(rays: Array[RayCast3D]) -> Dictionary:
	var contact_count: int = 0
	var sum_normal: Vector3 = Vector3.ZERO
	var min_distance: float = 999.0

	for ray in rays:
		if not is_instance_valid(ray) or not ray.is_inside_tree():
			continue
		ray.force_raycast_update()
		if ray.is_colliding():
			contact_count += 1
			sum_normal += ray.get_collision_normal()
			var dist: float = ray.global_position.distance_to(ray.get_collision_point())
			if dist < min_distance:
				min_distance = dist

	var avg_normal: Vector3 = Vector3.UP
	var is_grounded: bool = contact_count >= 1

	if contact_count > 0:
		avg_normal = (sum_normal / float(contact_count)).normalized()

	return {
		"contact_count": contact_count,
		"avg_normal": avg_normal,
		"is_grounded": is_grounded,
		"min_distance": min_distance if contact_count > 0 else 999.0,
		"within_ground_proximity": (min_distance <= GROUND_PROXIMITY_THRESHOLD)
	}

## Quaternion Alignment (Singularity-Free Slerp):
## Aligns vehicle chassis +Y basis to avg_surface_normal using quaternion rotation
## to eliminate Euler angle flips, gimbal lock, and NaN crashes during full 360° loops,
## corkscrews, and 90° wall rides.
static func align_chassis_to_normal(
	current_basis: Basis,
	avg_surface_normal: Vector3,
	alignment_stiffness: float,
	delta: float
) -> Basis:
	if avg_surface_normal.length_squared() < 0.001 or delta <= 0.0:
		return current_basis

	var cur_up: Vector3 = current_basis.y
	var tgt_up: Vector3 = avg_surface_normal.normalized()
	var dot: float = clampf(cur_up.dot(tgt_up), -1.0, 1.0)

	if dot < 0.9999:
		var axis: Vector3 = cur_up.cross(tgt_up)
		if axis.length_squared() < 0.0001:
			axis = current_basis.x
		var angle: float = acos(dot)
		var q_rot := Quaternion(axis.normalized(), angle * minf(1.0, alignment_stiffness * delta))
		var new_basis: Basis = Basis(q_rot) * current_basis
		return new_basis.orthonormalized()

	return current_basis
