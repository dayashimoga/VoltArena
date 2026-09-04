class_name GrenadeLauncher
extends WeaponBase

func _init() -> void:
	weapon_name = "Grenade Launcher"
	damage_per_shot = 80.0
	fire_rate_rpm = 75.0
	max_clip_ammo = 4
	current_clip_ammo = 4
	max_reserve_ammo = 24
	current_reserve_ammo = 16
	reload_time_sec = 2.5
	is_automatic = false
	spread_angle_deg = 0.5
	recoil_kick_pitch = 0.05
	is_hitscan = false
	sound_name = "shotgun_fire"

func spawn_projectile(spawn_pos: Vector3, dir: Vector3) -> void:
	var proj = Projectile.new()
	proj.direction = dir
	proj.speed = 28.0
	proj.shooter = owner_entity
	proj.damage = damage_per_shot
	proj.is_explosive = true
	proj.blast_radius = 6.0
	proj.has_gravity = true
	proj.gravity_scale = 14.0
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.root.add_child(proj)
		proj.global_position = spawn_pos + dir * 0.8
	else:
		proj.free()
