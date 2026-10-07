class_name AeroChaseCamera
extends Camera3D

## High-performance 3D chase camera for AeroRush: Impossible Circuit.
## Implements speed-sensitive FOV & distance, look-back, terrain collision avoidance,
## jump & landing compression feedback, and restrained trauma camera shake.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

var target_vehicle: CharacterBody3D = null

@export var base_distance: float = 6.2
@export var base_height: float = 2.2
@export var base_fov: float = 75.0
@export var max_fov: float = 94.0

var current_distance: float = 6.2
var look_back: bool = false
var trauma: float = 0.0

var collision_ray: RayCast3D = null

func _ready() -> void:
	current = true
	fov = base_fov

	collision_ray = RayCast3D.new()
	collision_ray.name = "CamCollisionRay"
	collision_ray.collision_mask = AeroConstants.LAYER_WORLD
	add_child(collision_ray)

func setup_target(p_vehicle: CharacterBody3D) -> void:
	target_vehicle = p_vehicle
	if target_vehicle:
		if target_vehicle.has_signal("landing_performed"):
			target_vehicle.landing_performed.connect(_on_landing)
		if target_vehicle.has_signal("vehicle_crashed"):
			target_vehicle.vehicle_crashed.connect(func(): add_shake(0.85))

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or not target_vehicle or not is_instance_valid(target_vehicle):
		return

	_update_camera_transform(delta)
	_update_shake(delta)

func _update_camera_transform(delta: float) -> void:
	var v_pos = target_vehicle.global_position
	var v_basis = target_vehicle.global_basis
	var forward_dir = -v_basis.z.normalized()
	var up_dir = v_basis.y.normalized()

	var spd = target_vehicle.get("forward_speed")
	var cur_speed = absf(float(spd)) if spd != null else 0.0
	var speed_ratio = clampf(cur_speed / 58.0, 0.0, 1.0)

	# 1. Dynamic Speed-Sensitive FOV & Distance
	var is_boosting = target_vehicle.get("is_boost_active")
	var boost_mult = 1.15 if (is_boosting != null and bool(is_boosting)) else 1.0
	var target_fov = lerpf(base_fov, max_fov, speed_ratio) * boost_mult
	fov = lerpf(fov, target_fov, delta * 8.0)

	var target_dist = base_distance + speed_ratio * 1.6
	current_distance = lerpf(current_distance, target_dist, delta * 6.0)

	# 2. Position Calculation
	var back_dir = forward_dir if look_back else -forward_dir
	var ideal_cam_pos = v_pos + back_dir * current_distance + up_dir * base_height

	# 3. Collision Avoidance (Prevent clipping through world geometry)
	collision_ray.global_position = v_pos + up_dir * 1.4
	collision_ray.target_position = collision_ray.to_local(ideal_cam_pos)
	collision_ray.force_raycast_update()

	var final_cam_pos = ideal_cam_pos
	if collision_ray.is_colliding():
		var col_pt = collision_ray.get_collision_point()
		var col_norm = collision_ray.get_collision_normal()
		final_cam_pos = col_pt + col_norm * 0.45

	global_position = global_position.lerp(final_cam_pos, delta * 14.0)

	# 4. Look-At Target (ahead of vehicle)
	var look_target = v_pos + forward_dir * 8.0 + up_dir * 1.2
	if look_back:
		look_target = v_pos - forward_dir * 8.0 + up_dir * 1.2

	# Stable up reference during loops
	var up_ref = up_dir if absf(forward_dir.y) < 0.8 else Vector3.UP
	look_at(look_target, up_ref)

func add_shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _on_landing(quality: String, angle_deg: float, bonus: int) -> void:
	if quality == "perfect":
		add_shake(0.20)
	elif quality == "rough":
		add_shake(0.45)

func _update_shake(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 1.4)
		var shake_p = trauma * trauma * 0.06
		h_offset = randf_range(-shake_p, shake_p)
		v_offset = randf_range(-shake_p, shake_p)
	else:
		h_offset = 0.0
		v_offset = 0.0
