class_name ArenaBot
extends AIBase

var health_component: HealthComponent

var weapon: WeaponBase
var patrol_target: Vector3 = Vector3.ZERO
var bot_name: String = "Bot Alpha"
var fire_cooldown: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	add_to_group("bots")
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES

	setup_bot_visual()
	setup_health()
	setup_weapon()
	pick_random_patrol()

@export var archetype: String = "assault" # "skirmisher", "assault", "sentinel"

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

var character_model: Node3D = null

func setup_bot_visual() -> void:
	if get_node_or_null("BotCollision"):
		return

	character_model = ModelCacheScript.get_character(archetype)
	if not character_model:
		var accent_color = Color(0.2, 0.6, 1.0)
		match archetype:
			"skirmisher":
				accent_color = Color(1.0, 0.4, 0.1)
			"sentinel":
				accent_color = Color(0.8, 0.2, 0.9)
			_:
				accent_color = Color(0.2, 0.6, 1.0)
		character_model = MeshBuilder.build_cyber_soldier(true, accent_color)

	character_model.position = Vector3(0, 0, 0)
	add_child(character_model)
	ModelCacheScript.play_animation(character_model, "Idle")

	var col = CollisionShape3D.new()
	col.name = "BotCollision"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

var move_speed: float:
	get: return movement_speed
	set(v): movement_speed = v

func setup_health() -> void:
	if health_component:
		return
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"

	match archetype:
		"skirmisher":
			health_component.max_health = 75.0
			health_component.max_armor = 25.0
			movement_speed = 7.5
		"sentinel":
			health_component.max_health = 130.0
			health_component.max_armor = 80.0
			movement_speed = 4.5
		_:
			health_component.max_health = 100.0
			health_component.max_armor = 50.0
			movement_speed = 6.0

	add_child(health_component)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(func(_cur, _max_hp):
		if not health_component.is_dead and character_model:
			ModelCacheScript.play_animation(character_model, "Hit_A", 0.1)
	)

func setup_weapon() -> void:
	if weapon:
		return
	weapon = WeaponBase.new()
	weapon.name = "BotWeapon"
	weapon.owner_entity = self

	match archetype:
		"skirmisher":
			weapon.weapon_name = "Scatter Cannon"
			weapon.damage_per_shot = 9.0
			weapon.fire_rate_rpm = 200.0
			attack_range = 14.0
		"sentinel":
			weapon.weapon_name = "Rail Driver"
			weapon.damage_per_shot = 35.0
			weapon.fire_rate_rpm = 90.0
			attack_range = 35.0
		_:
			weapon.weapon_name = "Pulse Rifle"
			weapon.damage_per_shot = 14.0
			weapon.fire_rate_rpm = 400.0
			attack_range = 22.0

	add_child(weapon)
	weapon.position = Vector3(0.3, 0.9, -0.4)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	if health_component.is_dead:
		move_and_slide()
		return

	# State evaluation
	current_target = find_nearest_target_in_group("players")

	if current_target and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		if dist < attack_range and has_line_of_sight(current_target):
			current_state = AIState.ATTACK
		else:
			current_state = AIState.SEEK
	else:
		current_state = AIState.PATROL

	match current_state:
		AIState.PATROL:
			steer_towards(patrol_target, delta)
			if character_model:
				ModelCacheScript.play_animation(character_model, "Walking_A")
			if global_position.distance_to(patrol_target) < 2.0:
				pick_random_patrol()
		AIState.SEEK:
			if current_target:
				steer_towards(current_target.global_position, delta)
				if character_model:
					ModelCacheScript.play_animation(character_model, "Running_A")
		AIState.ATTACK:
			if current_target:
				var aim_point = current_target.global_position + Vector3.UP * 1.2
				# Add jitter based on difficulty
				aim_point += Vector3(randf_range(-aim_jitter_amount, aim_jitter_amount), randf_range(-aim_jitter_amount, aim_jitter_amount), 0)
				var dir = (aim_point - (global_position + Vector3.UP * 1.0)).normalized()
				var target_basis = Basis.looking_at(dir, Vector3.UP)
				basis = basis.slerp(target_basis, turn_speed * delta)

				# Strafe gently
				var side = basis.x * sin(Time.get_ticks_msec() / 1000.0 * 2.0) * (movement_speed * 0.5)
				velocity.x = side.x
				velocity.z = side.z

				if character_model:
					ModelCacheScript.play_animation(character_model, "2H_Ranged_Aiming")

				# Fire weapon
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					weapon.trigger_fire(global_position + Vector3.UP * 1.0, dir)
					if character_model:
						ModelCacheScript.play_animation(character_model, "2H_Ranged_Shoot", 0.08)
					fire_cooldown = 60.0 / weapon.fire_rate_rpm + randf_range(0.05, 0.2)

	move_and_slide()

func pick_random_patrol() -> void:
	patrol_target = Vector3(
		randf_range(-25.0, 25.0),
		0.0,
		randf_range(-25.0, 25.0)
	)

func _on_died(killer: Node) -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		var pos = global_position if is_inside_tree() else position
		am.play_sound_3d("explosion", pos)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.emit("Arena Bot", 100)

	if character_model:
		ModelCacheScript.play_animation(character_model, "Death_A", 0.1)
	collision_layer = 0

	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(1.2).timeout.connect(func():
			visible = false
		)
		tree.create_timer(4.0).timeout.connect(respawn)

func respawn() -> void:
	pick_random_patrol()
	global_position = patrol_target + Vector3.UP * 1.0
	health_component.reset()
	visible = true
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES
