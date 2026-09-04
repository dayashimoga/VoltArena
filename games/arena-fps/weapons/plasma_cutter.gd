class_name PlasmaCutter
extends WeaponBase

func _init() -> void:
	weapon_name = "Plasma Cutter"
	damage_per_shot = 12.0
	fire_rate_rpm = 900.0
	max_clip_ammo = 50
	current_clip_ammo = 50
	max_reserve_ammo = 250
	current_reserve_ammo = 150
	reload_time_sec = 1.8
	is_automatic = true
	spread_angle_deg = 2.0
	recoil_kick_pitch = 0.012
	recoil_kick_yaw = 0.008
	is_hitscan = true
	sound_name = "laser_fire"
