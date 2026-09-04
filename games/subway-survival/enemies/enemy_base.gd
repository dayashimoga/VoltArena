class_name EnemyBase
extends CharacterBody3D

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

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES

	setup_health()
	setup_visuals()

func setup_health() -> void:
	if not health_component:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)
	health_component.died.connect(_on_died)

func setup_visuals() -> void:
	# Default shape; subclasses customize
	pass

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if not is_on_floor():
		velocity.y -= 20.0 * delta

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

func perform_attack() -> void:
	if target_player and is_instance_valid(target_player):
		if target_player.has_node("HealthComponent"):
			target_player.get_node("HealthComponent").take_damage(attack_damage, self)
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			var pos = global_position if is_inside_tree() else position
			am.play_sound_3d("hit", pos)

func _on_died(_source: Node) -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		var pos = global_position if is_inside_tree() else position
		am.play_sound_3d("explosion", pos, 1.2)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.emit(enemy_name, score_value)
	enemy_died.emit(enemy_name, score_value)
	queue_free()
