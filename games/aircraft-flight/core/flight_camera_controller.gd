class_name FlightCameraController
extends Node3D

## FlightCameraController: Hard Screen-Space Locked Dynamic Aviation Camera Rig.
## Features:
## - Tight wingspan-calibrated framing: distance = 1.35 * wingspan (~16.5m for F/A-18), height +3.2m
## - Zero off-screen drift constraint: rotation stiffness 14.0, hard clamped deviation <= 6.0 deg
## - Bank-follow horizon blending: 65% horizon reference in level flight, 100% aircraft Y in loops/steep banks
## - 4 Selectable camera modes: (1) Stabilized Chase Cam, (2) Cockpit Interior, (3) Aerobatic Cam, (4) Free Orbit

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")

@export var target_aircraft: CharacterBody3D
@export var default_view_mode: FlightConst.CameraViewMode = FlightConst.CameraViewMode.CHASE

# Chase Camera Rig Tuning
@export var rotation_stiffness: float = 14.0
@export var position_stiffness: float = 16.0
@export var base_fov: float = 65.0
@export var max_fov: float = 76.0
@export var max_angular_deviation_deg: float = 6.0

# Cockpit Camera Tuning
@export var cockpit_eye_offset: Vector3 = Vector3(0.0, 1.25, 0.45)
@export var cockpit_fov: float = 75.0

var camera: Camera3D
var current_mode: FlightConst.CameraViewMode = FlightConst.CameraViewMode.CHASE

# Filtered Positions & Orientations
var _smoothed_pos: Vector3 = Vector3.ZERO
var _smoothed_forward: Vector3 = Vector3.FORWARD
var _look_offset: Vector2 = Vector2.ZERO
var _orbit_angle: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "ActiveFlightCamera"
	camera.fov = base_fov
	camera.near = 0.1
	camera.far = 32000.0 # 32 km render distance for open skies
	add_child(camera)
	current_mode = default_view_mode

func toggle_camera_mode() -> void:
	match current_mode:
		FlightConst.CameraViewMode.CHASE:
			current_mode = FlightConst.CameraViewMode.COCKPIT
		FlightConst.CameraViewMode.COCKPIT:
			current_mode = FlightConst.CameraViewMode.AEROBATIC
		FlightConst.CameraViewMode.AEROBATIC:
			current_mode = FlightConst.CameraViewMode.FREE
		FlightConst.CameraViewMode.FREE:
			current_mode = FlightConst.CameraViewMode.CHASE

func set_camera_mode(mode: FlightConst.CameraViewMode) -> void:
	current_mode = mode

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or camera == null or not camera.is_inside_tree():
		return
	if not is_instance_valid(target_aircraft) or delta <= 0.0:
		return

	var ac_pos = target_aircraft.global_position
	var ac_basis = target_aircraft.global_transform.basis
	var fwd = -ac_basis.z.normalized()
	var up = ac_basis.y.normalized()
	var speed_ratio = clampf(target_aircraft.indicated_airspeed_ms / 250.0, 0.0, 1.0)

	match current_mode:
		FlightConst.CameraViewMode.CHASE:
			_update_chase_camera(delta, ac_pos, fwd, up, speed_ratio)
		FlightConst.CameraViewMode.COCKPIT:
			_update_cockpit_camera(delta, ac_pos, ac_basis)
		FlightConst.CameraViewMode.AEROBATIC:
			_update_aerobatic_camera(delta, ac_pos, fwd, up)
		FlightConst.CameraViewMode.FREE:
			_update_free_camera(delta, ac_pos, fwd)

func _update_chase_camera(delta: float, ac_pos: Vector3, fwd: Vector3, up: Vector3, speed_ratio: float) -> void:
	# 1. Hard Screen-Space Framing: follow distance = 1.35 * wingspan (~16.5m for F/A-18)
	var span = target_aircraft.wingspan if target_aircraft.get("wingspan") != null else 12.3
	var base_dist = span * 1.35
	var target_dist = base_dist * (1.0 + speed_ratio * 0.12)
	var target_height = 3.2 + speed_ratio * 0.35

	# FOV scaling: 65.0 deg base to 76.0 deg at AB 100%
	var ab_active = target_aircraft.has_afterburner and target_aircraft.afterburner_active and target_aircraft.throttle >= 0.95
	var target_fov = max_fov if ab_active else lerpf(base_fov, 72.0, speed_ratio)
	camera.fov = lerpf(camera.fov, target_fov, delta * 8.0)

	# 2. Bank-Follow Horizon Blending:
	# Interpolate between Vector3.UP (65% in normal flight) and aircraft basis.y
	# When pitch > +-60 deg or roll > +-75 deg, blends to 100% aircraft up to avoid gimbal lock flips
	var pitch_deg = absf(rad_to_deg(asin(clampf(fwd.y, -1.0, 1.0))))
	var roll_deg = absf(rad_to_deg(atan2(target_aircraft.global_transform.basis.x.y, up.y)))
	var steep_factor = clampf(maxf((pitch_deg - 50.0) / 20.0, (roll_deg - 65.0) / 20.0), 0.0, 1.0)
	var up_blend_weight = lerpf(0.35, 1.0, steep_factor)
	var cam_up = Vector3.UP.slerp(up, up_blend_weight).normalized()

	# Ideal camera position anchored behind aircraft
	var ideal_pos = ac_pos - (fwd * target_dist) + (cam_up * target_height)
	if ideal_pos.y < ac_pos.y + 0.8:
		ideal_pos.y = ac_pos.y + 0.8

	# Exponential spring position smoothing
	var pos_weight = 1.0 - exp(-position_stiffness * delta)
	if _smoothed_pos == Vector3.ZERO:
		_smoothed_pos = ideal_pos
	_smoothed_pos = _smoothed_pos.lerp(ideal_pos, pos_weight)
	camera.global_position = _smoothed_pos

	# 3. Zero Off-Screen Drift Constraint:
	# Direction to aircraft center of mass:
	var com_target = ac_pos + up * 0.4
	var to_com = (com_target - camera.global_position).normalized()

	if _smoothed_forward == Vector3.FORWARD or _smoothed_forward == Vector3.ZERO:
		_smoothed_forward = to_com

	# Smooth rotation toward aircraft with exponential stiffness = 14.0
	var rot_weight = 1.0 - exp(-rotation_stiffness * delta)
	_smoothed_forward = _smoothed_forward.slerp(to_com, rot_weight).normalized()

	# Hard angular deviation clamp: <= 6.0 degrees at all times
	var max_dev_rad = deg_to_rad(max_angular_deviation_deg)
	var dev_angle = acos(clampf(_smoothed_forward.dot(to_com), -1.0, 1.0))
	if dev_angle > max_dev_rad:
		var rot_axis = _smoothed_forward.cross(to_com)
		if rot_axis.length_squared() > 0.0001:
			_smoothed_forward = _smoothed_forward.rotated(rot_axis.normalized(), dev_angle - max_dev_rad)
		else:
			_smoothed_forward = to_com

	# Lock camera view direction strictly centered on aircraft COM
	camera.look_at(camera.global_position + _smoothed_forward * 50.0, cam_up)

func _update_aerobatic_camera(delta: float, ac_pos: Vector3, fwd: Vector3, up: Vector3) -> void:
	# Rigid aerobatic chase camera: 100% locked to aircraft pitch, roll, and yaw axes
	var span = target_aircraft.wingspan if target_aircraft.get("wingspan") != null else 12.3
	var dist = span * 1.35
	var height = 3.2
	camera.fov = 70.0
	var rigid_pos = ac_pos - (fwd * dist) + (up * height)
	camera.global_position = rigid_pos
	camera.look_at(ac_pos + (fwd * (span * 0.20)) + (up * 0.4), up)

func _update_cockpit_camera(delta: float, ac_pos: Vector3, ac_basis: Basis) -> void:
	camera.fov = cockpit_fov

	# Cockpit eye anchored inside canopy with subtle G-force displacement
	var g_disp = Vector3(0.0, -clampf((target_aircraft.g_force_current - 1.0) * 0.02, -0.06, 0.08), 0.0)
	var local_eye = cockpit_eye_offset + g_disp
	var world_eye = ac_pos + (ac_basis * local_eye)

	camera.global_position = world_eye

	# Look forward along aircraft longitudinal axis with mouse look offset
	var fwd_look = -ac_basis.z.normalized()
	var up_look = ac_basis.y.normalized()
	var right_look = ac_basis.x.normalized()
	var look_dir = (fwd_look + right_look * _look_offset.x + up_look * _look_offset.y).normalized()

	camera.look_at(world_eye + look_dir * 50.0, up_look)

func _update_free_camera(delta: float, ac_pos: Vector3, fwd: Vector3) -> void:
	camera.fov = base_fov
	var span = target_aircraft.wingspan if target_aircraft.get("wingspan") != null else 12.0
	var orbit_radius = span * 2.2

	_orbit_angle += delta * 0.25
	var orbit_offset = Vector3(cos(_orbit_angle) * orbit_radius, span * 0.6, sin(_orbit_angle) * orbit_radius)
	var free_pos = ac_pos + orbit_offset
	camera.global_position = camera.global_position.lerp(free_pos, delta * 4.5)
	camera.look_at(ac_pos + Vector3.UP * (span * 0.15), Vector3.UP)

func add_look_input(delta_x: float, delta_y: float) -> void:
	_look_offset.x = clampf(_look_offset.x + delta_x * 0.003, -1.2, 1.2)
	_look_offset.y = clampf(_look_offset.y + delta_y * 0.003, -0.8, 0.8)
