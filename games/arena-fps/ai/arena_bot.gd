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

func setup_bot_visual() -> void:
	if get_node_or_null("BotCollision"):
		return
	# Torso
	var torso = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.6, 0.9, 0.4)
	torso.mesh = box
	torso.position = Vector3(0, 0.9, 0)
	torso.material_override = MaterialGenerator.get_material("dark_hull")
	add_child(torso)

	# Visor (glowing red)
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.35, 0.12, 0.1)
	visor.mesh = v_box
	visor.position = Vector3(0, 1.45, -0.21)
	visor.material_override = MaterialGenerator.get_material("neon_magenta")
	add_child(visor)

	# Collision
	var col = CollisionShape3D.new()
	col.name = "BotCollision"
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

func setup_health() -> void:
	if health_component:
		return
	health_component = HealthComponent.new()
	health_component.name = "HealthComponent"
	health_component.max_health = 100.0
	health_component.max_armor = 50.0
	add_child(health_component)
	health_component.died.connect(_on_died)

func setup_weapon() -> void:
	if weapon:
		return
	weapon = WeaponBase.new()
	weapon.name = "BotWeapon"
	weapon.owner_entity = self
	weapon.damage_per_shot = 12.0
	weapon.fire_rate_rpm = 320.0
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
			if global_position.distance_to(patrol_target) < 2.0:
				pick_random_patrol()
		AIState.SEEK:
			if current_target:
				steer_towards(current_target.global_position, delta)
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

				# Fire weapon
				fire_cooldown -= delta
				if fire_cooldown <= 0.0:
					weapon.trigger_fire(global_position + Vector3.UP * 1.0, dir)
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
	# Hide and queue respawn in 4 seconds
	visible = false
	collision_layer = 0
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(4.0).timeout.connect(respawn)

func respawn() -> void:
	pick_random_patrol()
	global_position = patrol_target + Vector3.UP * 1.0
	health_component.reset()
	visible = true
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES
