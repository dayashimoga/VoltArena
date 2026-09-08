class_name StrikeWeaponBase
extends Node3D

## Base weapon class for Strike Vector arsenal.
## Supports ballistic, energy, shotgun spreads, charged bursts, recoil, ADS spread modifiers,
## reload cycles, attachments, and audio triggers.

signal weapon_fired(weapon_name: String, ammo_in_mag: int, reserve_ammo: int)
signal weapon_reloaded(weapon_name: String, ammo_in_mag: int, reserve_ammo: int)
signal reload_started(weapon_name: String, duration: float)

@export var weapon_id: String = "vx7_assault"
@export var weapon_name: String = "VX-7 Assault Rifle"
@export var damage: float = 24.0
@export var fire_rate_rpm: float = 650.0
@export var magazine_capacity: int = 30
@export var max_reserve_ammo: int = 150
@export var reload_time_sec: float = 2.0
@export var base_spread_deg: float = 1.2
@export var recoil_pitch_deg: float = 1.4
@export var recoil_yaw_deg: float = 0.5
@export var projectile_speed: float = 140.0
@export var projectile_color: Color = Color(0.1, 0.9, 1.0)
@export var is_hitscan: bool = true
@export var is_automatic: bool = true
@export var is_burst: bool = false
@export var burst_count: int = 3
@export var burst_delay: float = 0.08
@export var pellets_per_shot: int = 1
@export var is_charged: bool = false
@export var charge_time_sec: float = 0.6
@export var is_explosive: bool = false
@export var explosion_radius: float = 0.0
@export var is_penetrating: bool = false
@export var sound_fire_key: String = "laser_fire"

# Runtime State
var ammo_in_mag: int = 30
var reserve_ammo: int = 150
var is_reloading: bool = false
var reload_timer: float = 0.0
var fire_cooldown: float = 0.0
var current_charge: float = 0.0
var is_charging: bool = false

# Attachments / Upgrades
var has_extended_mag: bool = false
var has_suppressor: bool = false
var has_optic: bool = false
var has_tactical_grip: bool = false
var has_damage_upgrade: bool = false
var has_rapid_reload: bool = false

# Arcade Power Modules
var rapid_fire_active: bool = false
var spread_module_active: bool = false
var piercing_module_active: bool = false

# Node references
var muzzle_point: Marker3D
var weapon_mesh: Node3D
var owner_player: Node3D

func _ready() -> void:
	ammo_in_mag = magazine_capacity
	reserve_ammo = max_reserve_ammo
	_setup_muzzle()

func _setup_muzzle() -> void:
	if not muzzle_point:
		muzzle_point = Marker3D.new()
		muzzle_point.name = "MuzzlePoint"
		muzzle_point.position = Vector3(0, 0.05, -0.65)
		add_child(muzzle_point)

func _process(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown = maxf(0.0, fire_cooldown - delta)

	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

func can_fire() -> bool:
	if is_reloading:
		return false
	if fire_cooldown > 0.0:
		return false
	if ammo_in_mag <= 0:
		return false
	return true

func trigger_pull(aim_origin: Vector3, aim_direction: Vector3, is_ads: bool = false, is_moving: bool = false, is_airborne: bool = false) -> bool:
	if not can_fire():
		if ammo_in_mag <= 0 and not is_reloading and reserve_ammo > 0:
			start_reload()
		return false

	if is_charged:
		is_charging = true
		return false # wait for release or charge completion

	return _execute_shot(aim_origin, aim_direction, is_ads, is_moving, is_airborne)

func trigger_release(aim_origin: Vector3, aim_direction: Vector3, is_ads: bool = false, is_moving: bool = false, is_airborne: bool = false) -> bool:
	if is_charged and is_charging:
		is_charging = false
		if current_charge >= charge_time_sec:
			current_charge = 0.0
			return _execute_shot(aim_origin, aim_direction, is_ads, is_moving, is_airborne)
		current_charge = 0.0
	return false

func update_charge(delta: float) -> void:
	if is_charged and is_charging:
		current_charge = minf(charge_time_sec, current_charge + delta)

func _execute_shot(aim_origin: Vector3, aim_direction: Vector3, is_ads: bool, is_moving: bool, is_airborne: bool) -> bool:
	ammo_in_mag -= 1
	var actual_rpm = fire_rate_rpm * (1.5 if rapid_fire_active else 1.0)
	fire_cooldown = 60.0 / actual_rpm

	var actual_damage = damage * (1.2 if has_damage_upgrade else 1.0)
	var count = pellets_per_shot + (2 if spread_module_active else 0)

	# Calculate dynamic spread cone
	var effective_spread = base_spread_deg
	if is_ads:
		effective_spread *= 0.35
	if is_moving:
		effective_spread *= 1.4
	if is_airborne:
		effective_spread *= 2.2
	if has_tactical_grip:
		effective_spread *= 0.75

	for i in range(count):
		var spread_dir = _apply_spread(aim_direction, effective_spread)
		_spawn_bullet(aim_origin, spread_dir, actual_damage)

	_trigger_muzzle_fx()
	_play_fire_audio()
	weapon_fired.emit(weapon_name, ammo_in_mag, reserve_ammo)

	# Auto-reload if empty
	if ammo_in_mag <= 0 and reserve_ammo > 0:
		start_reload()

	return true

func _apply_spread(dir: Vector3, spread_deg: float) -> Vector3:
	if spread_deg <= 0.01:
		return dir.normalized()
	var yaw = deg_to_rad(randf_range(-spread_deg, spread_deg))
	var pitch = deg_to_rad(randf_range(-spread_deg, spread_deg))
	var basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	return (basis * dir).normalized()

func _spawn_bullet(origin: Vector3, dir: Vector3, dmg: float) -> void:
	var proj = WeaponProjectile.new()
	var spawn_pos = muzzle_point.global_position if is_instance_valid(muzzle_point) else global_position
	proj.position = spawn_pos
	proj.shooter = owner_player

	var eff_penetrating = is_penetrating or piercing_module_active
	proj.init_projectile(dir, projectile_speed, dmg, projectile_color, weapon_name, is_explosive, explosion_radius, eff_penetrating)

	var scene_root = get_tree().current_scene if get_tree() else get_parent()
	if scene_root:
		scene_root.add_child(proj)

func _trigger_muzzle_fx() -> void:
	if not is_instance_valid(muzzle_point):
		return
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	flash.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = projectile_color
	mat.emission_enabled = true
	mat.emission = projectile_color
	mat.emission_energy_multiplier = 6.0
	flash.material_override = mat

	muzzle_point.add_child(flash)
	var tween = flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ZERO, 0.06)
	tween.tween_callback(flash.queue_free)

func _play_fire_audio() -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound(sound_fire_key, 0.9 if has_suppressor else 1.0)

func start_reload() -> void:
	if is_reloading or ammo_in_mag >= get_effective_magazine_capacity() or reserve_ammo <= 0:
		return
	is_reloading = true
	var dur = reload_time_sec * (0.7 if has_rapid_reload else 1.0)
	reload_timer = dur
	reload_started.emit(weapon_name, dur)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("reload", 1.0)

func _finish_reload() -> void:
	is_reloading = false
	var needed = get_effective_magazine_capacity() - ammo_in_mag
	var actual_add = mini(needed, reserve_ammo)
	ammo_in_mag += actual_add
	reserve_ammo -= actual_add
	weapon_reloaded.emit(weapon_name, ammo_in_mag, reserve_ammo)

func get_effective_magazine_capacity() -> int:
	return int(magazine_capacity * 1.5) if has_extended_mag else magazine_capacity

func add_ammo(amount: int) -> void:
	reserve_ammo = mini(max_reserve_ammo, reserve_ammo + amount)

func apply_upgrade(upgrade_type: String) -> void:
	match upgrade_type:
		"extended_mag": has_extended_mag = true
		"suppressor": has_suppressor = true
		"optic": has_optic = true
		"tactical_grip": has_tactical_grip = true
		"damage_boost": has_damage_upgrade = true
		"rapid_reload": has_rapid_reload = true
