class_name CameraDirector
extends Node3D

## Dynamic multi-mode camera director for Strike Vector.
## Smoothly interpolates between Third-Person Combat, Tight Shoulder ADS,
## 2.5D Side-Scrolling, Corridor Chase, Vehicle/Set-Piece, Boss, and Cinematic modes.

enum CameraMode {
	THIRD_PERSON_COMBAT,
	TIGHT_ADS,
	SIDE_SCROLL_25D,
	CORRIDOR_FORWARD,
	VEHICLE_SETPIECE,
	BOSS_CAM,
	CINEMATIC
}

@export var target_player: Node3D
@export var target_boss: Node3D
@export var current_mode: CameraMode = CameraMode.THIRD_PERSON_COMBAT
@export var base_fov: float = 75.0
@export var ads_fov: float = 50.0

var spring_arm: SpringArm3D
var camera: Camera3D

# Sensitivity & Inversion settings
var mouse_sensitivity: float = 0.0025
var invert_y: bool = false
var yaw: float = 0.0
var pitch: float = 0.0
const PITCH_MIN: float = -75.0
const PITCH_MAX: float = 75.0

# Camera offset presets
var offset_third_person: Vector3 = Vector3(0.55, 1.45, 2.8)
var offset_ads: Vector3 = Vector3(0.35, 1.35, 1.5)
var offset_corridor: Vector3 = Vector3(0.0, 1.55, 3.2)
var offset_vehicle: Vector3 = Vector3(0.0, 2.8, 6.5)
var offset_sidescroll: Vector3 = Vector3(0.0, 2.0, 8.5)

# Camera Shake
var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	_setup_camera_rig()
	_load_settings()

func _setup_camera_rig() -> void:
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm"
	spring_arm.collision_mask = GameConstants.LAYER_WORLD
	spring_arm.spring_length = 2.8
	spring_arm.margin = 0.2
	add_child(spring_arm)

	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.current = true
	camera.fov = base_fov
	spring_arm.add_child(camera)

func _load_settings() -> void:
	var sm = GameConstants.get_autoload(self, "SettingsManager")
	if sm and sm.has_method("get_setting"):
		mouse_sensitivity = sm.get_setting("controls", "mouse_sensitivity", 0.0025)
		invert_y = sm.get_setting("controls", "invert_y", false)
		base_fov = sm.get_setting("video", "fov", 75.0)
		if is_instance_valid(camera):
			camera.fov = base_fov

func _unhandled_input(event: InputEvent) -> void:
	if current_mode == CameraMode.SIDE_SCROLL_25D or current_mode == CameraMode.CINEMATIC:
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or not OS.has_feature("editor"):
			var y_dir = 1.0 if invert_y else -1.0
			yaw -= event.relative.x * mouse_sensitivity
			pitch = clampf(pitch + event.relative.y * mouse_sensitivity * y_dir, deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player):
		return

	_update_shake(delta)

	match current_mode:
		CameraMode.THIRD_PERSON_COMBAT:
			_process_third_person(delta, offset_third_person, base_fov)
		CameraMode.TIGHT_ADS:
			_process_third_person(delta, offset_ads, ads_fov)
		CameraMode.CORRIDOR_FORWARD:
			_process_corridor(delta)
		CameraMode.SIDE_SCROLL_25D:
			_process_side_scroll(delta)
		CameraMode.VEHICLE_SETPIECE:
			_process_vehicle(delta)
		CameraMode.BOSS_CAM:
			_process_boss_cam(delta)
		CameraMode.CINEMATIC:
			_process_cinematic(delta)

func _process_third_person(delta: float, target_offset: Vector3, target_fov: float) -> void:
	# Follow player position smoothly
	var target_pos = target_player.global_position
	global_position = global_position.lerp(target_pos, 18.0 * delta)

	# Apply rotation around player
	rotation.y = yaw
	rotation.x = pitch

	# Local spring arm target offset
	spring_arm.position = spring_arm.position.lerp(Vector3(target_offset.x, target_offset.y, 0), 12.0 * delta)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_offset.z, 12.0 * delta)

	# Dynamic FOV interpolation
	camera.fov = lerpf(camera.fov, target_fov, 10.0 * delta)

func _process_corridor(delta: float) -> void:
	var target_pos = target_player.global_position
	global_position = global_position.lerp(target_pos, 14.0 * delta)

	# Lock yaw to forward corridor direction
	var player_fwd_yaw = target_player.rotation.y
	yaw = lerp_angle(yaw, player_fwd_yaw, 8.0 * delta)
	rotation.y = yaw
	rotation.x = lerpf(rotation.x, deg_to_rad(-8.0), 8.0 * delta)

	spring_arm.position = spring_arm.position.lerp(Vector3(0, offset_corridor.y, 0), 10.0 * delta)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, offset_corridor.z, 10.0 * delta)
	camera.fov = lerpf(camera.fov, base_fov, 8.0 * delta)

func _process_side_scroll(delta: float) -> void:
	# Fixed side-scroller perspective looking perpendicular to player travel
	var target_pos = target_player.global_position + Vector3(0, offset_sidescroll.y, offset_sidescroll.z)
	global_position = global_position.lerp(target_pos, 8.0 * delta)
	look_at(target_player.global_position + Vector3(0, 1.2, 0), Vector3.UP)
	spring_arm.position = Vector3.ZERO
	spring_arm.spring_length = 0.0
	camera.fov = lerpf(camera.fov, base_fov + 5.0, 6.0 * delta)

func _process_vehicle(delta: float) -> void:
	var target_pos = target_player.global_position + Vector3(0, offset_vehicle.y, offset_vehicle.z)
	global_position = global_position.lerp(target_pos, 10.0 * delta)
	look_at(target_player.global_position + Vector3(0, 1.0, -3.0), Vector3.UP)
	spring_arm.position = Vector3.ZERO
	spring_arm.spring_length = 0.0
	camera.fov = lerpf(camera.fov, base_fov + 10.0, 8.0 * delta)

func _process_boss_cam(delta: float) -> void:
	if not is_instance_valid(target_boss):
		_process_third_person(delta, offset_third_person, base_fov)
		return

	# Frame both player and boss by centering on their midpoint
	var midpoint = (target_player.global_position + target_boss.global_position) * 0.5
	var dist = target_player.global_position.distance_to(target_boss.global_position)
	var cam_dist = clampf(dist * 0.9 + 4.0, 6.0, 20.0)

	var target_cam_pos = midpoint + Vector3(0, 3.5, cam_dist)
	global_position = global_position.lerp(target_cam_pos, 8.0 * delta)
	look_at(midpoint + Vector3(0, 1.5, 0), Vector3.UP)
	spring_arm.position = Vector3.ZERO
	spring_arm.spring_length = 0.0

func _process_cinematic(delta: float) -> void:
	yaw += delta * 0.35
	rotation.y = yaw
	rotation.x = deg_to_rad(-12.0)
	global_position = global_position.lerp(target_player.global_position, 6.0 * delta)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, 4.5, 6.0 * delta)

func set_mode(mode: CameraMode) -> void:
	current_mode = mode

func add_shake(amount: float) -> void:
	shake_intensity = clampf(shake_intensity + amount, 0.0, 2.5)

func _update_shake(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_intensity = maxf(0.0, shake_intensity - shake_decay * delta)
		var shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity) * 0.08,
			randf_range(-shake_intensity, shake_intensity) * 0.08,
			0.0
		)
		camera.position = shake_offset
	else:
		camera.position = Vector3.ZERO
