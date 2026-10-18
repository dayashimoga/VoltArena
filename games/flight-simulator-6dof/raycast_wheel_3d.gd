class_name RaycastWheel3D
extends RayCast3D

## Raycast-based aircraft landing gear suspension and tire friction model.
## Simulates spring-damper reaction, Coulomb friction clamp, rolling resistance,
## braking, and speed-sensitive nosewheel steering.

@export var is_steerable: bool = false
@export var has_brakes: bool = false
@export var rest_length: float = 0.55         ## Uncompressed strut rest length (m)
@export var spring_stiffness: float = 65000.0  ## Suspension spring rate k (N/m)
@export var damping_rate: float = 4800.0       ## Strut damping coefficient c (N*s/m)
@export var wheel_radius: float = 0.28         ## Tire radius (m)
@export var tire_friction_mu: float = 0.85     ## Peak tire friction coefficient mu
@export var lateral_stiffness: float = 45000.0 ## Tire cornering stiffness (N/rad or N/(m/s))
@export var rolling_resistance_coeff: float = 0.02 ## Free rolling resistance Cr
@export var max_steer_angle_deg: float = 25.0  ## Low-speed taxi steer authority (deg)
@export var brake_torque_max: float = 4500.0   ## Maximum braking torque capacity (N*m)

var current_steer_angle_rad: float = 0.0
var current_compression: float = 0.0
var is_contacting: bool = false
var normal_force: float = 0.0
var prev_spring_len: float = 0.55

func _ready() -> void:
	enabled = true
	target_position = Vector3(0, -(rest_length + wheel_radius), 0)
	prev_spring_len = rest_length
	var parent_body = get_parent_body()
	if parent_body:
		add_exception(parent_body)

func get_parent_body() -> RigidBody3D:
	var n = get_parent()
	while n and not (n is RigidBody3D):
		n = n.get_parent()
	return n as RigidBody3D

## Updates steering angle based on pilot rudder input and ground speed.
## Implements speed-sensitive steering reduction to prevent high-speed rollover.
func set_steering_input(rudder_input: float, ground_speed_mps: float) -> void:
	if not is_steerable:
		current_steer_angle_rad = 0.0
		return

	# Speed reduction curve: full authority at < 4 m/s, drops smoothly to 3.5 deg at > 25 m/s
	var speed_factor = clamp(1.0 - (ground_speed_mps / 28.0), 0.14, 1.0)
	var max_rad = deg_to_rad(max_steer_angle_deg) * speed_factor
	current_steer_angle_rad = -rudder_input * max_rad # Coordinate convention: steer turns nose

	# Rotate raycast local heading to track steer angle
	rotation.y = current_steer_angle_rad

## Evaluates contact forces and applies suspension, friction, and braking to body.
func evaluate_and_apply_forces(
	body: RigidBody3D,
	com_world: Vector3,
	delta: float,
	brake_input: float = 0.0,
	parking_brake: bool = false
) -> Dictionary:
	if not enabled:
		is_contacting = false
		current_compression = 0.0
		normal_force = 0.0
		return {"in_contact": false, "normal_force": 0.0}

	if is_inside_tree():
		force_raycast_update()
	is_contacting = is_colliding()

	var contact_pt: Vector3 = Vector3.ZERO
	var ground_normal: Vector3 = Vector3.UP
	var dist: float = rest_length + wheel_radius

	if is_contacting:
		contact_pt = get_collision_point()
		ground_normal = get_collision_normal()
		var my_world_pos = global_position if is_inside_tree() else position
		dist = my_world_pos.distance_to(contact_pt)
	else:
		# Ground plane fallback for runway (y=0 datum) or headless direct simulation
		var my_world_pos = global_position if is_inside_tree() else position
		var strut_bottom = my_world_pos.y - (rest_length + wheel_radius)
		if strut_bottom <= 0.05:
			is_contacting = true
			contact_pt = Vector3(my_world_pos.x, 0.0, my_world_pos.z)
			ground_normal = Vector3.UP
			dist = max(0.001, my_world_pos.y)

	if not is_contacting:
		current_compression = 0.0
		normal_force = 0.0
		prev_spring_len = rest_length
		return {"in_contact": false, "normal_force": 0.0}

	# 1. Spring Compression: x = L_rest - L_current
	var current_spring_len = dist - wheel_radius
	var x = rest_length - current_spring_len
	current_compression = max(0.0, x)

	# Compression velocity: v_normal = (L_prev - L_curr) / delta
	var v_normal = (prev_spring_len - current_spring_len) / max(delta, 0.001)
	prev_spring_len = current_spring_len

	# 2. Suspension Force: F_n = max(0, k*x - c*v_normal)
	var f_suspension_mag = spring_stiffness * current_compression + damping_rate * v_normal
	f_suspension_mag = max(0.0, f_suspension_mag)
	normal_force = f_suspension_mag

	var f_suspension = ground_normal * f_suspension_mag

	# 3. Contact-Patch Velocity: v = v_linear + omega.cross(p_contact - p_COM)
	var r_contact = contact_pt - com_world
	var v_contact = body.linear_velocity + body.angular_velocity.cross(r_contact)

	# Wheel coordinate axes:
	# Local forward: -Z of this wheel node (takes steering into account)
	# Local right/lateral: +X of this wheel node
	var wheel_basis = global_transform.basis if is_inside_tree() else transform.basis
	var fwd_proj = (wheel_basis * Vector3(0, 0, -1)).slide(ground_normal)
	var wheel_forward_world = fwd_proj.normalized() if fwd_proj.length_squared() > 0.0001 else (wheel_basis * Vector3(0, 0, -1))
	var lat_proj = (wheel_basis * Vector3(1, 0, 0)).slide(ground_normal)
	var wheel_lateral_world = lat_proj.normalized() if lat_proj.length_squared() > 0.0001 else (wheel_basis * Vector3(1, 0, 0))

	var v_longitudinal = v_contact.dot(wheel_forward_world)
	var v_lateral = v_contact.dot(wheel_lateral_world)

	# 4. Lateral Friction (Tire Grip): F_lat = -clamp(v_lat * stiffness, -mu*Fn, +mu*Fn)
	var max_friction_force = tire_friction_mu * f_suspension_mag
	var f_lat_mag = -v_lateral * lateral_stiffness
	f_lat_mag = clamp(f_lat_mag, -max_friction_force, max_friction_force)
	var f_lateral = wheel_lateral_world * f_lat_mag

	# 5. Longitudinal Force (Rolling Resistance + Braking)
	var effective_brake = brake_input
	if parking_brake:
		effective_brake = 1.0

	var f_rolling_res = -sign(v_longitudinal) * rolling_resistance_coeff * f_suspension_mag

	var f_brake_mag = 0.0
	if has_brakes and effective_brake > 0.01:
		var max_brake_force = (brake_torque_max * effective_brake) / max(wheel_radius, 0.1)
		max_brake_force = min(max_brake_force, max_friction_force)
		f_brake_mag = -sign(v_longitudinal) * max_brake_force

	var f_longitudinal_mag = f_rolling_res + f_brake_mag
	# Prevent friction from causing backwards oscillation at near-zero velocity
	if abs(v_longitudinal) < 0.2:
		f_longitudinal_mag *= (abs(v_longitudinal) / 0.2)

	var f_longitudinal = wheel_forward_world * f_longitudinal_mag

	# 6. Apply Total Force at Contact Patch
	var f_total_wheel = f_suspension + f_lateral + f_longitudinal
	var body_pos = body.global_position if body.is_inside_tree() else body.position
	var force_offset = contact_pt - body_pos
	if not is_nan(f_total_wheel.x) and not is_inf(f_total_wheel.x) and not is_nan(force_offset.x):
		body.apply_force(f_total_wheel, force_offset)

	return {
		"in_contact": true,
		"normal_force": f_suspension_mag,
		"lateral_force": f_lateral,
		"longitudinal_force": f_longitudinal,
		"compression": current_compression,
		"contact_pt": contact_pt
	}
