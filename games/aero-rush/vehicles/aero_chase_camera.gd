class_name AeroChaseCamera
extends Camera3D

## High-performance, vibration-free 3D chase camera for AeroRush: Impossible Circuit.
## Implements decoupled physics-interpolated tracking, speed-sensitive FOV & distance,
## 3D loop & wall-ride orientation stability, look-back, terrain collision avoidance,
## and strictly event-driven polynomial trauma shake (zero continuous vibration).

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

var target_vehicle: CharacterBody3D = null

@export var base_distance: float = 6.4
@export var base_height: float = 2.4
@export var base_fov: float = 75.0
@export var max_fov: float = 96.0

var view_mode: int = 0 # 0: CHASE, 1: HOOD, 2: ORBIT
var current_distance: float = 6.4
var look_back: bool = false
var trauma: float = 0.0
var landing_dip: float = 0.0

var smoothed_pos: Vector3 = Vector3.ZERO
var smoothed_fwd: Vector3 = Vector3.FORWARD
var smoothed_up: Vector3 = Vector3.UP

var collision_ray: RayCast3D = null
var is_initialized: bool = false

func cycle_view_mode() -> int:
	view_mode = (view_mode + 1) % 3
	return view_mode

func _ready() -> void:
	current = true
	make_current()
	fov = base_fov

	collision_ray = RayCast3D.new()
	collision_ray.name = "CamCollisionRay"
	collision_ray.collision_mask = AeroConstants.LAYER_WORLD
	add_child(collision_ray)

func setup_target(p_vehicle: CharacterBody3D) -> void:
	target_vehicle = p_vehicle
	if not target_vehicle:
		return

	if collision_ray:
		collision_ray.add_exception(target_vehicle)

	if target_vehicle.has_signal("landing_performed") and not target_vehicle.landing_performed.is_connected(_on_landing):
		target_vehicle.landing_performed.connect(_on_landing)
	if target_vehicle.has_signal("vehicle_crashed") and not target_vehicle.vehicle_crashed.is_connected(_on_crashed):
		target_vehicle.vehicle_crashed.connect(_on_crashed)
	if target_vehicle.has_signal("vehicle_respawned") and not target_vehicle.vehicle_respawned.is_connected(_on_vehicle_respawned):
		target_vehicle.vehicle_respawned.connect(_on_vehicle_respawned)

	# Instant snap on initial setup
	var v_pos = target_vehicle.global_position if target_vehicle.is_inside_tree() else target_vehicle.position
	var v_basis = target_vehicle.global_basis if target_vehicle.is_inside_tree() else target_vehicle.transform.basis
	smoothed_pos = v_pos
	smoothed_fwd = -v_basis.z.normalized()
	smoothed_up = v_basis.y.normalized()

	var ideal_pos = v_pos - smoothed_fwd * base_distance + smoothed_up * base_height
	if is_inside_tree():
		global_position = ideal_pos
		look_at(v_pos + smoothed_fwd * 8.0 + smoothed_up * 1.2, smoothed_up)
	else:
		position = ideal_pos

	make_current()
	is_initialized = true

func _on_crashed() -> void:
	add_shake(0.85)

func _on_vehicle_respawned(_respawn_pos: Vector3) -> void:
	if not target_vehicle:
		return
	var v_pos = target_vehicle.global_position if target_vehicle.is_inside_tree() else target_vehicle.position
	var v_basis = target_vehicle.global_basis if target_vehicle.is_inside_tree() else target_vehicle.transform.basis
	smoothed_pos = v_pos
	smoothed_fwd = -v_basis.z.normalized()
	smoothed_up = v_basis.y.normalized()
	var ideal_pos = v_pos - smoothed_fwd * base_distance + smoothed_up * base_height
	if is_inside_tree():
		global_position = ideal_pos
		look_at(v_pos + smoothed_fwd * 8.0 + smoothed_up * 1.2, smoothed_up)
	else:
		position = ideal_pos

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or not target_vehicle or not is_instance_valid(target_vehicle):
		return

	if not is_initialized:
		setup_target(target_vehicle)

	_update_camera_transform(delta)
	_update_shake(delta)

func _update_camera_transform(delta: float) -> void:
	var v_pos = target_vehicle.global_position
	var v_basis = target_vehicle.global_basis
	var raw_fwd = -v_basis.z.normalized()
	var raw_up = v_basis.y.normalized()

	var spd = target_vehicle.get("forward_speed")
	var cur_speed = absf(float(spd)) if spd != null else 0.0
	var speed_ratio = clampf(cur_speed / 58.0, 0.0, 1.0)

	# 1. Physics Interpolation of target vectors (Decouples suspension chatter & high-frequency vibration)
	var pos_lerp = clampf(delta * 14.0, 0.0, 1.0)
	var rot_lerp = clampf(delta * 10.0, 0.0, 1.0)

	smoothed_pos = smoothed_pos.lerp(v_pos, pos_lerp)
	smoothed_fwd = smoothed_fwd.slerp(raw_fwd, rot_lerp).normalized()
	smoothed_up = smoothed_up.slerp(raw_up, rot_lerp).normalized()

	# 2. Dynamic Speed-Sensitive FOV & Distance with Airborne Jump Expansion
	var is_grounded_val = target_vehicle.get("is_grounded")
	var is_airborne = is_grounded_val != null and not bool(is_grounded_val)
	var airtime = target_vehicle.get("airtime_duration")
	var is_high_jump = is_airborne and airtime != null and float(airtime) > 0.4

	var is_boosting = target_vehicle.get("is_boost_active")
	var boost_mult = 1.12 if (is_boosting != null and bool(is_boosting)) else 1.0
	var target_fov = lerpf(base_fov, max_fov, speed_ratio) * boost_mult
	fov = lerpf(fov, target_fov, delta * 8.0)

	landing_dip = lerpf(landing_dip, 0.0, delta * 9.0)

	var target_dist = base_distance + speed_ratio * 1.8
	var target_h = base_height - landing_dip
	if is_high_jump:
		target_dist = base_distance * 1.35 + speed_ratio * 2.2
		target_h = base_height * 1.28
	elif view_mode == 1:
		# HOOD / BUMPER VIEW
		target_dist = -1.4
		target_h = 0.65
	elif view_mode == 2:
		# COMPACT ORBIT VIEW
		target_dist = 4.8
		target_h = 1.85

	current_distance = lerpf(current_distance, target_dist, delta * 6.0)

	# 3. Position Calculation
	var back_dir = smoothed_fwd if look_back else -smoothed_fwd
	var ideal_cam_pos = smoothed_pos + back_dir * current_distance + smoothed_up * target_h

	# 4. Collision Avoidance (Avoid clipping through track geometry)
	if collision_ray and is_instance_valid(collision_ray) and view_mode == 0:
		collision_ray.global_position = smoothed_pos + smoothed_up * 1.4
		collision_ray.target_position = collision_ray.to_local(ideal_cam_pos)
		collision_ray.force_raycast_update()

		var final_cam_pos = ideal_cam_pos
		if collision_ray.is_colliding():
			var col_pt = collision_ray.get_collision_point()
			var col_norm = collision_ray.get_collision_normal()
			final_cam_pos = col_pt + col_norm * 0.50

		global_position = global_position.lerp(final_cam_pos, clampf(delta * 16.0, 0.0, 1.0))
	else:
		global_position = ideal_cam_pos

	# 5. Look-At Target (ahead of vehicle along trajectory)
	var fwd_lead = 16.0 if view_mode == 1 else 8.0
	var look_target = smoothed_pos + smoothed_fwd * fwd_lead + smoothed_up * (target_h * 0.6)
	if look_back:
		look_target = smoothed_pos - smoothed_fwd * 8.0 + smoothed_up * 1.2

	# In inverted loops, stabilize up reference
	var up_ref = smoothed_up if absf(smoothed_fwd.y) < 0.85 else Vector3.UP
	look_at(look_target, up_ref)

func add_shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _on_landing(quality: String, _angle_deg: float, _bonus: int) -> void:
	landing_dip = 0.28
	if quality == "perfect":
		add_shake(0.22)
	elif quality == "rough":
		add_shake(0.48)
	elif quality == "crash":
		add_shake(0.85)

func _update_shake(delta: float) -> void:
	if trauma > 0.0:
		# Strictly event-driven polynomial falloff: trauma^2
		trauma = maxf(0.0, trauma - delta * 1.8)
		var shake_p = trauma * trauma * 0.055
		h_offset = randf_range(-shake_p, shake_p)
		v_offset = randf_range(-shake_p, shake_p)
	else:
		h_offset = 0.0
		v_offset = 0.0
