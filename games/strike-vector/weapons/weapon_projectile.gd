class_name WeaponProjectile
extends Node3D

## High-speed ballistic, energy, and explosive projectile for Strike Vector.
## Features: hitscan-sweep hybrid, raycasting, penetration, splash damage, particle trails, and impact decals.

@export var speed: float = 120.0
@export var damage: float = 25.0
@export var max_range: float = 150.0
@export var is_explosive: bool = false
@export var explosion_radius: float = 5.0
@export var is_penetrating: bool = false
@export var max_penetrations: int = 3
@export var shooter: Node = null
@export var projectile_color: Color = Color(0.1, 0.95, 1.0)
@export var weapon_name: String = "Weapon"

var current_distance: float = 0.0
var direction: Vector3 = Vector3.FORWARD
var penetrations_done: int = 0
var visual_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("projectiles")
	setup_visuals()

func setup_visuals() -> void:
	visual_mesh = MeshInstance3D.new()
	var cap = BoxMesh.new()
	cap.size = Vector3(0.06, 0.06, 0.45)
	visual_mesh.mesh = cap

	var mat = StandardMaterial3D.new()
	mat.albedo_color = projectile_color
	mat.emission_enabled = true
	mat.emission = projectile_color
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual_mesh.material_override = mat
	add_child(visual_mesh)

func init_projectile(dir: Vector3, spd: float, dmg: float, col: Color, wep_name: String = "", explosive: bool = false, radius: float = 0.0, penetrating: bool = false) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	projectile_color = col
	weapon_name = wep_name
	is_explosive = explosive
	explosion_radius = radius
	is_penetrating = penetrating

	if is_instance_valid(visual_mesh) and visual_mesh.material_override is StandardMaterial3D:
		var mat = visual_mesh.material_override as StandardMaterial3D
		mat.albedo_color = projectile_color
		mat.emission = projectile_color

	# Align with flight direction
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	var move_dist = speed * delta
	var next_pos = global_position + direction * move_dist

	# Continuous raycast sweep to prevent tunneling through high-speed targets
	var space_state = get_world_3d().direct_space_state if get_world_3d() else null
	if space_state:
		var query = PhysicsRayQueryParameters3D.create(global_position, next_pos)
		query.collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
		if is_instance_valid(shooter) and shooter is CollisionObject3D:
			query.exclude = [shooter.get_rid()]

		var result = space_state.intersect_ray(query)
		if result:
			_handle_hit(result)
			return

	global_position = next_pos
	current_distance += move_dist
	if current_distance >= max_range:
		queue_free()

func _handle_hit(hit_result: Dictionary) -> void:
	var collider = hit_result.get("collider")
	var hit_pos: Vector3 = hit_result.get("position", global_position)
	var hit_normal: Vector3 = hit_result.get("normal", Vector3.UP)

	# Direct impact damage
	if is_instance_valid(collider):
		var weak_multiplier = 1.0
		# Check if headshot or weakpoint
		if collider.has_meta("is_weakpoint") or (collider.name.to_lower().contains("head")):
			weak_multiplier = 2.0

		var total_dmg = damage * weak_multiplier
		if collider.has_method("take_damage"):
			collider.take_damage(total_dmg, is_instance_valid(shooter) and shooter.name or "Player", weapon_name)
		elif collider.get_parent() and collider.get_parent().has_method("take_damage"):
			collider.get_parent().take_damage(total_dmg, is_instance_valid(shooter) and shooter.name or "Player", weapon_name)

	# Explosive Splash Damage
	if is_explosive and explosion_radius > 0.0:
		_trigger_splash_damage(hit_pos)

	# Spawn visual impact FX
	_spawn_impact_fx(hit_pos, hit_normal)

	# Penetration check
	if is_penetrating and penetrations_done < max_penetrations:
		penetrations_done += 1
		damage *= 0.75 # Slight damage reduction per penetration
		global_position = hit_pos + direction * 0.4 # step forward
	else:
		queue_free()

func _trigger_splash_damage(epicenter: Vector3) -> void:
	var tree = get_tree()
	if not tree:
		return
	var targets = tree.get_nodes_in_group("enemies") + tree.get_nodes_in_group("destructibles")
	for target in targets:
		if is_instance_valid(target) and target is Node3D and target != shooter:
			var dist = epicenter.distance_to(target.global_position)
			if dist <= explosion_radius:
				var falloff = 1.0 - (dist / explosion_radius)
				var splash_dmg = damage * falloff
				if target.has_method("take_damage"):
					target.take_damage(splash_dmg, is_instance_valid(shooter) and shooter.name or "Player", weapon_name)

	# Audio explosion
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("explosion", 1.0)

func _spawn_impact_fx(pos: Vector3, normal: Vector3) -> void:
	var root = get_parent()
	if not root:
		return

	# Impact Spark Flash
	var spark = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.15
	s_mesh.height = 0.30
	spark.mesh = s_mesh

	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = projectile_color
	s_mat.emission_enabled = true
	s_mat.emission = projectile_color
	s_mat.emission_energy_multiplier = 5.0
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark.material_override = s_mat

	spark.global_position = pos + normal * 0.05
	root.add_child(spark)

	# Quick fade out
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(spark.queue_free)
