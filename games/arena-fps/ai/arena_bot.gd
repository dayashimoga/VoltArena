class_name ArenaBot
extends AIBase

## ArenaBot: Production tactical combat humanoid AI.
## Uses authentic Mixamo soldier with skeletal locomotion and firearm socketing.
## Perceives players, faces threats directly, strafes/flanks, uses cover,
## and never continuously exposes its back while in combat.

var health_component: HealthComponent
var weapon: WeaponBase
var patrol_target: Vector3 = Vector3.ZERO
var bot_name: String = "Bot Alpha"
var fire_cooldown: float = 0.0
var strafe_timer: float = 0.0
var strafe_dir: float = 1.0
var character_model: Node3D = null
var weapon_socket: Node3D = null

@export var archetype: String = "assault" # "skirmisher", "assault", "sentinel"

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

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

func setup_bot_visual() -> void:
	if get_node_or_null("BotCollision"):
		return

	character_model = ModelCacheScript.get_character(archetype)
	if not character_model:
		character_model = MeshBuilder.build_cyber_soldier(true)

	character_model.position = Vector3(0, 0, 0)
	add_child(character_model)
	ModelCacheScript.play_animation(character_model, "Idle")

	var col = CollisionShape3D.new()
	col.name = "BotCollision"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.85
	col.shape = cap
	col.position = Vector3(0, 0.92, 0)
	add_child(col)

func setup_health() -> void:
	if health_component:
		return
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"

	match archetype:
		"skirmisher":
			health_component.max_health = 80.0
			health_component.max_armor = 30.0
			movement_speed = 7.0
		"sentinel":
			health_component.max_health = 140.0
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
			ModelCacheScript.play_animation(character_model, "HitReact", 0.08)
	)

func setup_weapon() -> void:
	if weapon:
		return
	weapon = WeaponBase.new()
	weapon.name = "BotWeapon"
	weapon.owner_entity = self

	var wname = "Pulse Rifle"
	match archetype:
		"skirmisher":
			wname = "Scatter Cannon"
			weapon.weapon_name = wname
			weapon.damage_per_shot = 10.0
			weapon.fire_rate_rpm = 220.0
			attack_range = 14.0
		"sentinel":
			wname = "Rail Driver"
			weapon.weapon_name = wname
			weapon.damage_per_shot = 38.0
			weapon.fire_rate_rpm = 85.0
			attack_range = 35.0
		_:
			wname = "Pulse Rifle"
			weapon.weapon_name = wname
			weapon.damage_per_shot = 14.0
			weapon.fire_rate_rpm = 420.0
			attack_range = 24.0

	add_child(weapon)
	# Hand socketing
	weapon.position = Vector3(0.28, 1.05, -0.45)
	weapon.rotation_degrees = Vector3(0, 0, 0)

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
		if health_component.current_health < retreat_health_threshold:
			current_state = AIState.RETREAT
		elif dist < attack_range and has_line_of_sight(current_target):
			current_state = AIState.ATTACK
		else:
			current_state = AIState.SEEK
	else:
		current_state = AIState.PATROL

	match current_state:
		AIState.PATROL:
			steer_towards(patrol_target, delta)
			if character_model:
				ModelCacheScript.play_animation(character_model, "Walk")
			if global_position.distance_to(patrol_target) < 2.0:
				pick_random_patrol()

		AIState.SEEK:
			if current_target:
				steer_towards(current_target.global_position, delta)
				if character_model:
					ModelCacheScript.play_animation(character_model, "Run")

		AIState.ATTACK:
			if current_target:
				var aim_point = current_target.global_position + Vector3.UP * 1.2
				aim_point += Vector3(randf_range(-aim_jitter_amount, aim_jitter_amount), randf_range(-aim_jitter_amount, aim_jitter_amount), 0)
				var to_target = (aim_point - (global_position + Vector3.UP * 1.1)).normalized()

				# Maintain direct face-to-face line of sight (forward is -basis.z)
				var target_basis = Basis.looking_at(to_target, Vector3.UP)
				basis = basis.slerp(target_basis, turn_speed * delta * 1.5)

				# Dynamic strafe and combat movement
				strafe_timer -= delta
				if strafe_timer <= 0.0:
					strafe_timer = randf_range(1.5, 3.0)
					strafe_dir = -strafe_dir if randf() < 0.7 else strafe_dir

				var dist = global_position.distance_to(current_target.global_position)
				var forward_push = 0.0
				if dist > attack_range * 0.7:
					forward_push = 0.4 # Close in
				elif dist < 5.0:
					forward_push = -0.3 # Keep comfortable tactical distance

				# Lateral strafe velocity
				var strafe_vec = basis.x * strafe_dir * (movement_speed * 0.6)
				var forward_vec = -basis.z * forward_push * (movement_speed * 0.4)
				velocity.x = strafe_vec.x + forward_vec.x
				velocity.z = strafe_vec.z + forward_vec.z

				# Play appropriate combat locomotion animation
				if character_model:
					if strafe_dir > 0:
						ModelCacheScript.play_animation(character_model, "StrafeRight", 0.15)
					else:
						ModelCacheScript.play_animation(character_model, "StrafeLeft", 0.15)

				# Fire weapon with aim alignment check
				fire_cooldown -= delta
				var dot = (-basis.z).dot(to_target)
				if fire_cooldown <= 0.0 and dot > 0.8: # Must face player within ~35 degrees
					weapon.trigger_fire(global_position + Vector3.UP * 1.1, to_target)
					if character_model:
						ModelCacheScript.play_animation(character_model, "Fire", 0.06)
					fire_cooldown = 60.0 / weapon.fire_rate_rpm + randf_range(0.04, 0.15)

		AIState.RETREAT:
			if current_target:
				# Backpedal while keeping gun trained on player
				var to_target = (current_target.global_position - global_position).normalized()
				var target_basis = Basis.looking_at(to_target, Vector3.UP)
				basis = basis.slerp(target_basis, turn_speed * delta)

				# Move backwards away from player
				var away = basis.z * (movement_speed * 0.75)
				velocity.x = away.x
				velocity.z = away.z

				if character_model:
					ModelCacheScript.play_animation(character_model, "WalkBack", 0.15)

				# Retaliatory fire while retreating
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					weapon.trigger_fire(global_position + Vector3.UP * 1.1, to_target)
					fire_cooldown = (60.0 / weapon.fire_rate_rpm) * 1.5

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
		ModelCacheScript.play_animation(character_model, "Death", 0.1)
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
