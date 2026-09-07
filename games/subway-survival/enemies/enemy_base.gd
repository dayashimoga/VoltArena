class_name EnemyBase
extends CharacterBody3D

const ScrapPickupScript = preload("res://games/subway-survival/game/scrap_pickup.gd")

signal enemy_died(enemy_type: String, score_value: int)

@export var enemy_name: String = "Subway Mutant"
@export var enemy_type: String = "Generic"
@export var score_value: int = 50
@export var move_speed: float = 5.0
@export var turn_speed: float = 6.0
@export var attack_damage: float = 15.0
@export var attack_rate_sec: float = 1.0
@export var attack_range: float = 2.2

var health_component: HealthComponent

var target_player: Node3D = null
var attack_cooldown: float = 0.0
var kill_plane_y: float = -6.0
var last_safe_grounded_transform: Transform3D = Transform3D.IDENTITY

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES

	setup_health()
	setup_visuals()
	attach_enemy_weapon()

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")
var creature_model: Node3D = null
var weapon_visual: Node3D = null

func attach_enemy_weapon(w_type: String = "pulse_rifle") -> void:
	if weapon_visual and is_instance_valid(weapon_visual):
		return
	weapon_visual = ModelCacheScript.get_weapon_model(w_type)
	if weapon_visual:
		weapon_visual.name = "EnemyWeapon"
		weapon_visual.position = Vector3(0.25, 0.95, -0.35)
		weapon_visual.scale = Vector3(0.9, 0.9, 0.9)
		add_child(weapon_visual)

func setup_health() -> void:
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(func(_cur, _max_hp):
		if not health_component.is_dead and creature_model:
			ModelCacheScript.play_animation(creature_model, "Idle", 0.1)
	)

func setup_visuals() -> void:
	# Default shape; subclasses customize
	pass

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
		if global_position.y > kill_plane_y:
			last_safe_grounded_transform = global_transform

	if global_position.y < kill_plane_y:
		recover_from_out_of_bounds()
		return

	if health_component.is_dead:
		move_and_slide()
		return

	if not target_player or not is_instance_valid(target_player):
		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree:
			var players = tree.get_nodes_in_group("players")
			if not players.is_empty():
				target_player = players[0]

	if target_player and is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist > attack_range:
			steer_to_target(target_player.global_position, delta)
		else:
			# Within attack range
			velocity.x = 0.0
			velocity.z = 0.0
			attack_cooldown -= delta
			if attack_cooldown <= 0.0:
				perform_attack()
				attack_cooldown = attack_rate_sec

	move_and_slide()

func steer_to_target(target_pos: Vector3, delta: float) -> void:
	var dir = (target_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		var target_basis = Basis.looking_at(dir, Vector3.UP)
		basis = basis.slerp(target_basis, turn_speed * delta)
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if creature_model:
			ModelCacheScript.play_animation(creature_model, "Walk")

func perform_attack() -> void:
	if creature_model:
		ModelCacheScript.play_animation(creature_model, "Run", 0.1)
	if target_player and is_instance_valid(target_player):
		if target_player.has_node("HealthComponent"):
			target_player.get_node("HealthComponent").take_damage(attack_damage, self)
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			var pos = global_position if is_inside_tree() else position
			am.play_sound_3d("hit", pos)

func _on_died(_source: Node) -> void:
	if creature_model:
		ModelCacheScript.play_animation(creature_model, "Idle", 0.1)
	var drop_pos = global_position if is_inside_tree() else position
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound_3d("explosion", drop_pos, 1.2)

	# Spawn physical scrap drop
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		var parent_node = tree.current_scene if tree.current_scene else get_parent()
		if parent_node:
			var scrap = ScrapPickupScript.new()
			scrap.scrap_amount = int(score_value * 0.5)
			scrap.position = drop_pos + Vector3(0, 0.4, 0)
			parent_node.add_child(scrap)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.emit(enemy_name, score_value)
	enemy_died.emit(enemy_name, score_value)
	queue_free()

func recover_from_out_of_bounds() -> void:
	if last_safe_grounded_transform != Transform3D.IDENTITY:
		global_transform = last_safe_grounded_transform
		global_position.y += 0.3
	else:
		global_position = Vector3(-5.0, 0.6, 0.0)
	velocity = Vector3.ZERO
