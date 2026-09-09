class_name ScatterCannon
extends WeaponBase

@export var pellets_count: int = 8

func _init() -> void:
	weapon_name = "Scatter Cannon"
	damage_per_shot = 9.0
	fire_rate_rpm = 90.0
	max_clip_ammo = 8
	current_clip_ammo = 8
	max_reserve_ammo = 48
	current_reserve_ammo = 32
	reload_time_sec = 2.2
	is_automatic = false
	spread_angle_deg = 4.5
	recoil_kick_pitch = 0.06
	recoil_kick_yaw = 0.02
	is_hitscan = true
	sound_name = "shotgun_fire"

func trigger_fire(camera_ray_origin: Vector3, camera_ray_dir: Vector3) -> bool:
	if not can_fire():
		return false

	last_fire_time = Time.get_ticks_msec() / 1000.0
	current_clip_ammo -= 1
	ammo_updated.emit(current_clip_ammo, max_clip_ammo, current_reserve_ammo)
	fired.emit()

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound(sound_name)

	# Fire multiple pellets
	var fwd = camera_ray_dir.normalized()
	var up = Vector3.UP if absf(fwd.y) < 0.99 else Vector3.RIGHT
	var right = fwd.cross(up).normalized()
	var cam_up = right.cross(fwd).normalized()
	var spread_rad = deg_to_rad(spread_angle_deg)

	for i in range(pellets_count):
		var ox = randf_range(-spread_rad, spread_rad)
		var oy = randf_range(-spread_rad, spread_rad)
		var pellet_dir = (fwd + right * ox + cam_up * oy).normalized()
		perform_hitscan(camera_ray_origin, pellet_dir)

	if owner_entity and owner_entity.has_method("apply_recoil"):
		owner_entity.apply_recoil(recoil_kick_pitch, randf_range(-recoil_kick_yaw, recoil_kick_yaw))

	return true
