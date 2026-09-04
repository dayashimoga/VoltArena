class_name RailDriver
extends WeaponBase

func _init() -> void:
	weapon_name = "Rail Driver"
	damage_per_shot = 95.0
	fire_rate_rpm = 45.0
	max_clip_ammo = 1
	current_clip_ammo = 1
	max_reserve_ammo = 15
	current_reserve_ammo = 10
	reload_time_sec = 1.4
	is_automatic = false
	spread_angle_deg = 0.0 # Pinpoint accuracy
	recoil_kick_pitch = 0.08
	recoil_kick_yaw = 0.0
	is_hitscan = true
	sound_name = "railgun_fire"
