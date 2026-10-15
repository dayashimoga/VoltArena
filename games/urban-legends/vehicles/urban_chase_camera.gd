class_name UrbanChaseCamera
extends Camera3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## Adaptive third-person chase, free orbit, and stunt camera controller for Urban Legends.
## Features:
## - Critically damped target interpolation with zero jitter
## - Steep-hill pitch compensation (Las Colinas grade alignment)
## - Dynamic speed-sensitive FOV expansion without oscillation
## - Obstacle collision clipping prevention (Spring-arm raycasting)
## - Seamless camera mode switching (Chase, Free, Bumper, Stunt)

@export var target_vehicle: Node3D = null
@export var camera_mode: int = UrbanConstants.CAM_CHASE

# Base Chase Offsets
var follow_distance: float = 5.2
var follow_height: float = 2.1
var target_look_height: float = 1.15
var position_damping: float = 10.0
var rotation_damping: float = 8.5

# Hill & Elevation Adaptation
var pitch_compensation_factor: float = 0.55
var current_elevation_offset: float = 0.0

# Dynamic FOV Zoom
var base_fov: float = 68.0
var max_fov: float = 84.0
var current_fov: float = 68.0
var fov_damp_speed: float = 4.0

# Free Orbit Mode
var orbit_yaw: float = 0.0
var orbit_pitch: float = deg_to_rad(-12.0)
var is_orbiting: bool = false
var orbit_reset_timer: float = 0.0

# Internal Nodes
var obstacle_ray: RayCast3D = null
var filtered_target_pos: Vector3 = Vector3.ZERO
var filtered_target_yaw: float = 0.0

func _get_target_pos() -> Vector3:
	if not target_vehicle:
		return Vector3.ZERO
	return target_vehicle.global_position if target_vehicle.is_inside_tree() else target_vehicle.position

func _get_target_rot() -> Vector3:
	if not target_vehicle:
		return Vector3.ZERO
	return target_vehicle.global_rotation if target_vehicle.is_inside_tree() else target_vehicle.rotation

func _get_target_basis() -> Basis:
	if not target_vehicle:
		return Basis.IDENTITY
	return target_vehicle.global_basis if target_vehicle.is_inside_tree() else target_vehicle.transform.basis

func _set_cam_pos(p: Vector3) -> void:
	if is_inside_tree():
		global_position = p
	else:
		position = p

func _get_cam_pos() -> Vector3:
	return global_position if is_inside_tree() else position

func _ready() -> void:
	current = true
	fov = base_fov

	obstacle_ray = get_node_or_null("ObstacleRay")
	if not obstacle_ray:
		obstacle_ray = RayCast3D.new()
		obstacle_ray.name = "ObstacleRay"
		obstacle_ray.collision_mask = UrbanConstants.LAYER_WORLD
		obstacle_ray.enabled = true
		add_child(obstacle_ray)

	if target_vehicle:
		filtered_target_pos = _get_target_pos()
		filtered_target_yaw = _get_target_rot().y

func set_target(vehicle: Node3D) -> void:
	target_vehicle = vehicle
	if target_vehicle:
		filtered_target_pos = _get_target_pos()
		filtered_target_yaw = _get_target_rot().y

func set_camera_mode(mode: int) -> void:
	camera_mode = mode
	if mode == UrbanConstants.CAM_FREE:
		orbit_reset_timer = 0.0
	elif mode == UrbanConstants.CAM_BUMPER:
		fov = 78.0

func cycle_camera_mode() -> void:
	var next_mode = (camera_mode + 1) % 3
	set_camera_mode(next_mode)

func handle_orbit_input(delta_yaw: float, delta_pitch: float) -> void:
	if camera_mode != UrbanConstants.CAM_BUMPER:
		camera_mode = UrbanConstants.CAM_FREE
		orbit_yaw += delta_yaw
		orbit_pitch = clampf(orbit_pitch + delta_pitch, deg_to_rad(-45.0), deg_to_rad(35.0))
		orbit_reset_timer = 4.0 # Returns to chase after 4s idle

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_vehicle):
		return

	_update_fov(delta)

	match camera_mode:
		UrbanConstants.CAM_CHASE:
			_update_chase_camera(delta)
		UrbanConstants.CAM_FREE:
			_update_free_camera(delta)
		UrbanConstants.CAM_BUMPER:
			_update_bumper_camera(delta)
		UrbanConstants.CAM_STUNT:
			_update_stunt_camera(delta)

func _update_fov(delta: float) -> void:
	var speed = 0.0
	if target_vehicle.has_method("get_speed_kmh"):
		speed = target_vehicle.get_speed_kmh()

	var speed_ratio = clampf(speed / 200.0, 0.0, 1.0)
	var target_fov = lerpf(base_fov, max_fov, speed_ratio)

	# Critically damped smooth zoom without stepping or oscillation
	current_fov = move_toward(current_fov, target_fov, fov_damp_speed * delta * 8.0)
	fov = current_fov

func _update_chase_camera(delta: float) -> void:
	var v_pos = _get_target_pos()
	var v_rot = _get_target_rot()
	var v_yaw = v_rot.y
	var v_pitch = v_rot.x

	# Positional low-pass filtering
	filtered_target_pos = filtered_target_pos.lerp(v_pos, clampf(position_damping * delta, 0.0, 1.0))

	# Yaw rotation interpolation (handles wrap-around)
	var diff_yaw = wrapf(v_yaw - filtered_target_yaw, -PI, PI)
	filtered_target_yaw += diff_yaw * clampf(rotation_damping * delta, 0.0, 1.0)

	# Steep-hill pitch leveling: when ascending or descending a steep hill (Las Colinas style),
	# pitch the camera slightly to maintain visibility of the road ahead
	current_elevation_offset = lerpf(current_elevation_offset, v_pitch * pitch_compensation_factor, delta * 4.0)

	var rot_basis = Basis(Vector3.UP, filtered_target_yaw)
	var behind_dir = rot_basis * Vector3.BACK
	var up_dir = Vector3.UP

	var desired_cam_pos = filtered_target_pos + (behind_dir * follow_distance) + (up_dir * (follow_height + current_elevation_offset))
	var target_look_at = filtered_target_pos + (up_dir * target_look_height)

	# Obstacle Raycast Check (Prevents clipping into buildings, flyover viaducts, tunnel arches)
	if obstacle_ray and obstacle_ray.is_inside_tree():
		obstacle_ray.global_position = target_look_at
		obstacle_ray.target_position = obstacle_ray.to_local(desired_cam_pos)
		obstacle_ray.force_raycast_update()
		if obstacle_ray.is_colliding():
			var hit_pt = obstacle_ray.get_collision_point()
			var hit_dist = target_look_at.distance_to(hit_pt)
			desired_cam_pos = target_look_at + (desired_cam_pos - target_look_at).normalized() * maxf(1.2, hit_dist - 0.35)

	_set_cam_pos(desired_cam_pos)
	_safe_look_at(target_look_at, Vector3.UP)

func _update_free_camera(delta: float) -> void:
	orbit_reset_timer -= delta
	if orbit_reset_timer <= 0.0:
		camera_mode = UrbanConstants.CAM_CHASE

	var v_pos = _get_target_pos()
	var target_look_at = v_pos + Vector3(0, target_look_height, 0)

	# Spherical orbit calculation
	var orbit_basis = Basis(Vector3.UP, orbit_yaw) * Basis(Vector3.RIGHT, orbit_pitch)
	var offset = orbit_basis * Vector3(0, 0, follow_distance)
	var desired_cam_pos = target_look_at + offset

	if obstacle_ray and obstacle_ray.is_inside_tree():
		obstacle_ray.global_position = target_look_at
		obstacle_ray.target_position = obstacle_ray.to_local(desired_cam_pos)
		obstacle_ray.force_raycast_update()
		if obstacle_ray.is_colliding():
			var hit_pt = obstacle_ray.get_collision_point()
			desired_cam_pos = hit_pt + (target_look_at - hit_pt).normalized() * 0.3

	_set_cam_pos(desired_cam_pos)
	_safe_look_at(target_look_at, Vector3.UP)

func _update_bumper_camera(_delta: float) -> void:
	var v_basis = _get_target_basis()
	var v_pos = _get_target_pos()
	var bumper_pos = v_pos + (v_basis * Vector3(0, 0.72, -1.8))
	_set_cam_pos(bumper_pos)
	var look_target = bumper_pos + (v_basis * Vector3(0, -0.05, -15.0))
	_safe_look_at(look_target, v_basis.y)

func _update_stunt_camera(delta: float) -> void:
	# Cinematic wide-angle follow during major jumps
	var v_pos = _get_target_pos()
	filtered_target_pos = filtered_target_pos.lerp(v_pos, delta * 3.5)
	var target_look_at = v_pos + Vector3(0, 0.8, 0)
	var desired_cam_pos = filtered_target_pos + Vector3(0, 4.0, 7.5)

	_set_cam_pos(desired_cam_pos)
	_safe_look_at(target_look_at, Vector3.UP)

func _safe_look_at(look_pos: Vector3, up_vec: Vector3 = Vector3.UP) -> void:
	var my_pos = _get_cam_pos()
	var forward = look_pos - my_pos
	if forward.length_squared() < 0.001:
		return
	var f_norm = forward.normalized()
	if absf(f_norm.dot(up_vec.normalized())) > 0.95:
		up_vec = Vector3.FORWARD

	if is_inside_tree():
		look_at(look_pos, up_vec)
	else:
		transform = Transform3D().looking_at(f_norm, up_vec)

func get_camera() -> Camera3D:
	return self
