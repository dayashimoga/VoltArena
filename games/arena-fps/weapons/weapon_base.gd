class_name WeaponBase
extends Node3D

signal ammo_updated(current_ammo: int, max_clip: int, reserve_ammo: int)
signal fired()

@export var weapon_name: String = "Pulse Rifle"
@export var damage_per_shot: float = 18.0
@export var fire_rate_rpm: float = 550.0
@export var max_clip_ammo: int = 30
@export var current_clip_ammo: int = 30
@export var max_reserve_ammo: int = 150
@export var current_reserve_ammo: int = 90
@export var reload_time_sec: float = 1.6
@export var is_automatic: bool = true
@export var spread_angle_deg: float = 1.2
@export var recoil_kick_pitch: float = 0.02
@export var recoil_kick_yaw: float = 0.01
@export var is_hitscan: bool = true
@export var sound_name: String = "laser_fire"

var time_between_shots: float = 0.1
var last_fire_time: float = -999.0
var is_reloading: bool = false
var reload_timer: float = 0.0
var owner_entity: Node3D = null

func _ready() -> void:
	time_between_shots = 60.0 / fire_rate_rpm
	current_clip_ammo = max_clip_ammo
	setup_weapon_visual()

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func setup_weapon_visual() -> void:
	for c in get_children():
		if c is Node3D and c.name == "WeaponModel":
			c.queue_free()

	var model: Node3D = ModelCacheScript.get_weapon_model(weapon_name)
	if not model:
		match weapon_name:
			"Pulse Rifle":
				model = MeshBuilder.build_pulse_rifle()
			"Scatter Cannon":
				model = MeshBuilder.build_scatter_cannon()
			"Rail Driver":
				model = MeshBuilder.build_rail_driver()
			"Grenade Launcher":
				model = MeshBuilder.build_grenade_launcher()
			"Plasma Cutter":
				model = MeshBuilder.build_plasma_cutter()
			_:
				model = MeshBuilder.build_pulse_rifle()

	if model:
		model.name = "WeaponModel"
		add_child(model)

func _process(delta: float) -> void:
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			finish_reload()

func can_fire() -> bool:
	if is_reloading:
		return false
	var now = Time.get_ticks_msec() / 1000.0
	if (now - last_fire_time) < time_between_shots:
		return false
	if current_clip_ammo <= 0:
		start_reload()
		return false
	return true

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

	# Calculate spread
	var spread_rad = deg_to_rad(spread_angle_deg)
	var spread_offset = Vector3(
		randf_range(-spread_rad, spread_rad),
		randf_range(-spread_rad, spread_rad),
		0.0
	)
	var final_dir = (camera_ray_dir + spread_offset).normalized()

	if is_hitscan:
		perform_hitscan(camera_ray_origin, final_dir)
	else:
		var spawn_p = global_position if is_inside_tree() else position
		spawn_projectile(spawn_p, final_dir)

	# Apply recoil kick to camera if owner is FPS Player
	if owner_entity and owner_entity.has_method("apply_recoil"):
		owner_entity.apply_recoil(recoil_kick_pitch, randf_range(-recoil_kick_yaw, recoil_kick_yaw))

	# Physical weapon model recoil kick animation
	var wm = get_node_or_null("WeaponModel")
	if wm and is_inside_tree():
		var tw = create_tween()
		tw.tween_property(wm, "position:z", 0.06, 0.04)
		tw.tween_property(wm, "position:z", 0.0, 0.08)

	return true

func perform_hitscan(origin: Vector3, dir: Vector3) -> void:
	if not is_inside_tree():
		return
	var w3d = get_world_3d()
	if not w3d:
		return
	var space = w3d.direct_space_state
	var end_point = origin + dir * 200.0
	var query = PhysicsRayQueryParameters3D.create(origin, end_point, GameConstants.LAYER_WORLD | GameConstants.LAYER_ENEMIES | GameConstants.LAYER_PLAYER, [owner_entity.get_rid()] if owner_entity else [])
	var result = space.intersect_ray(query)

	if not result.is_empty():
		var col = result.collider
		var is_head = false
		# Check if hit was higher up on target
		if col is Node3D:
			var relative_y = result.position.y - col.global_position.y
			if relative_y > 1.4:
				is_head = true

		if col.has_node("HealthComponent"):
			col.get_node("HealthComponent").take_damage(damage_per_shot, owner_entity, is_head)
		elif col.has_method("take_damage"):
			col.take_damage(damage_per_shot, owner_entity)

		# Spawn hit impact effect
		spawn_impact_fx(result.position, result.normal)

func spawn_projectile(spawn_pos: Vector3, dir: Vector3) -> void:
	var proj = Projectile.new()
	proj.direction = dir
	proj.shooter = owner_entity
	proj.damage = damage_per_shot
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		var parent_node = tree.current_scene if tree.current_scene else tree.root
		parent_node.add_child(proj)
		proj.global_position = spawn_pos + dir * 0.8
	else:
		proj.free()

func spawn_impact_fx(pos: Vector3, normal: Vector3) -> void:
	# Small visual spark impact
	var spark = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.08)
	spark.mesh = box
	spark.material_override = MaterialGenerator.get_material("neon_orange")
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if not tree or not tree.root:
		spark.free()
		return
	tree.root.add_child(spark)
	spark.global_position = pos + normal * 0.04
	# Auto remove after 0.2s
	tree.create_timer(0.2).timeout.connect(func():
		if is_instance_valid(spark):
			spark.queue_free()
	)

func start_reload() -> void:
	if is_reloading or current_clip_ammo >= max_clip_ammo or current_reserve_ammo <= 0:
		return
	is_reloading = true
	reload_timer = reload_time_sec
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("reload")

func finish_reload() -> void:
	is_reloading = false
	var needed = max_clip_ammo - current_clip_ammo
	var amount = min(needed, current_reserve_ammo)
	current_clip_ammo += amount
	current_reserve_ammo -= amount
	ammo_updated.emit(current_clip_ammo, max_clip_ammo, current_reserve_ammo)

func add_reserve_ammo(amount: int) -> void:
	current_reserve_ammo = min(max_reserve_ammo, current_reserve_ammo + amount)
	ammo_updated.emit(current_clip_ammo, max_clip_ammo, current_reserve_ammo)
