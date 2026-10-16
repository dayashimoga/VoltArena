class_name FlightCameraController
extends Node3D

## FlightCameraController: Dynamic Wingspan-Calibrated Aviation Camera Controller.
## Provides stable 3rd-person Chase camera calibrated to 1.4x-1.8x aircraft wingspan,
## 1st-person Cockpit camera, Nose camera, and exterior Free Orbit camera
## with smooth spring-arm lag, banking follow, and terrain clearance.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")

@export var target_aircraft: CharacterBody3D
@export var default_view_mode: FlightConst.CameraViewMode = FlightConst.CameraViewMode.CHASE

# Chase Camera Tuning (Dynamically scaled by wingspan)
@export var chase_damping: float = 6.5
@export var chase_rot_damping: float = 8.0
@export var base_fov: float = 72.0
@export var max_fov: float = 88.0

# Cockpit Camera Tuning
@export var cockpit_eye_offset: Vector3 = Vector3(0.0, 1.25, 0.45)
@export var cockpit_fov: float = 75.0

var camera: Camera3D
var current_mode: FlightConst.CameraViewMode = FlightConst.CameraViewMode.CHASE

# Filtered Positions
var _smoothed_pos: Vector3 = Vector3.ZERO
var _smoothed_target_pos: Vector3 = Vector3.ZERO
var _look_offset: Vector2 = Vector2.ZERO # Mouse look in cockpit / free
var _orbit_angle: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "ActiveFlightCamera"
	camera.fov = base_fov
	camera.near = 0.1
	camera.far = 25000.0 # 25 km render distance for open skies
	add_child(camera)
	current_mode = default_view_mode

func toggle_camera_mode() -> void:
	match current_mode:
		FlightConst.CameraViewMode.CHASE:
			current_mode = FlightConst.CameraViewMode.COCKPIT
		FlightConst.CameraViewMode.COCKPIT:
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
		FlightConst.CameraViewMode.FREE:
			_update_free_camera(delta, ac_pos, fwd)

func _update_chase_camera(delta: float, ac_pos: Vector3, fwd: Vector3, up: Vector3, speed_ratio: float) -> void:
	# Wingspan-calibrated framing: 1.4x - 1.8x aircraft wingspan (default 1.6x)
	var span = target_aircraft.wingspan if target_aircraft.get("wingspan") != null else 12.0
	var dynamic_chase_dist = clampf(span * 1.6, 9.5, 52.0)
	var dynamic_chase_height = clampf(span * 0.35, 2.6, 12.0)

	# Speed-reactive distance and FOV
	var target_dist = dynamic_chase_dist + speed_ratio * (dynamic_chase_dist * 0.25)
	var target_height = dynamic_chase_height + speed_ratio * (dynamic_chase_height * 0.20)
	var target_fov = lerpf(base_fov, max_fov, speed_ratio)

	if target_aircraft.has_afterburner and target_aircraft.afterburner_active:
		target_fov = minf(max_fov + 4.0, 96.0)

	camera.fov = lerpf(camera.fov, target_fov, delta * 3.5)

	# Banking follow: roll camera subtly with aircraft banking for visceral aviation immersion
	var bank_up = up.slerp(Vector3.UP, 0.55).normalized()
	var ideal_cam_pos = ac_pos - (fwd * target_dist) + (bank_up * target_height)

	# Ground clearance / terrain collision safety
	if ideal_cam_pos.y < ac_pos.y + 0.8:
		ideal_cam_pos.y = ac_pos.y + 0.8

	if _smoothed_pos == Vector3.ZERO:
		_smoothed_pos = ideal_cam_pos

	var pos_weight = 1.0 - exp(-chase_damping * delta)
	_smoothed_pos = _smoothed_pos.lerp(ideal_cam_pos, pos_weight)
	camera.global_position = _smoothed_pos

	# Aim toward aircraft center + slight forward lookahead
	var look_target = ac_pos + (fwd * (span * 0.32)) + (up * (span * 0.08))
	if _smoothed_target_pos == Vector3.ZERO:
		_smoothed_target_pos = look_target
	_smoothed_target_pos = _smoothed_target_pos.lerp(look_target, pos_weight)

	camera.look_at(_smoothed_target_pos, bank_up)

func _update_cockpit_camera(delta: float, ac_pos: Vector3, ac_basis: Basis) -> void:
	camera.fov = cockpit_fov

	# Cockpit eye anchored inside fuselage with subtle G-force displacement
	var g_disp = Vector3(0.0, -clampf((target_aircraft.g_force_current - 1.0) * 0.02, -0.06, 0.08), 0.0)
	var local_eye = cockpit_eye_offset + g_disp
	var world_eye = ac_pos + (ac_basis * local_eye)

	camera.global_position = world_eye

	# Look forward along aircraft longitudinal axis with mouse look offset
	var fwd_look = -ac_basis.z.normalized()
	var up_look = ac_basis.y.normalized()
	var target_look = world_eye + fwd_look * 50.0

	camera.look_at(target_look, up_look)

func _update_free_camera(delta: float, ac_pos: Vector3, fwd: Vector3) -> void:
	camera.fov = base_fov
	var span = target_aircraft.wingspan if target_aircraft.get("wingspan") != null else 12.0
	var orbit_radius = span * 2.2

	_orbit_angle += delta * 0.25
	var orbit_offset = Vector3(cos(_orbit_angle) * orbit_radius, span * 0.6, sin(_orbit_angle) * orbit_radius)
	var free_pos = ac_pos + orbit_offset
	camera.global_position = camera.global_position.lerp(free_pos, delta * 3.5)
	camera.look_at(ac_pos + Vector3.UP * (span * 0.15), Vector3.UP)

func add_look_input(delta_x: float, delta_y: float) -> void:
	_look_offset.x = clampf(_look_offset.x + delta_x * 0.003, -1.2, 1.2)
	_look_offset.y = clampf(_look_offset.y + delta_y * 0.003, -0.8, 0.8)
