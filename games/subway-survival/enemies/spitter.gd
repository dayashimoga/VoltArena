class_name SubwaySpitter
extends EnemyBase

var spit_cooldown: float = 0.0
var last_attack_time: float = 0.0

func _init() -> void:
	enemy_name = "Acid Spitter"
	enemy_type = "Spitter"
	score_value = 80
	move_speed = 4.8
	turn_speed = 6.0
	attack_damage = 18.0
	attack_rate_sec = 2.0
	attack_range = 16.0

func setup_visuals() -> void:
	creature_model = ModelCacheScript.get_enemy("spitter")
	if not creature_model:
		creature_model = MeshBuilder.build_spitter_mesh()
	add_child(creature_model)
	ModelCacheScript.play_animation(creature_model, "Idle")

	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.3
	col.shape = cap
	col.position = Vector3(0, 0.7, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 65.0
		health_component.max_armor = 10.0
		health_component.reset()

func perform_attack() -> void:
	if not target_player or not is_instance_valid(target_player):
		return

	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time < attack_rate_sec:
		return
	last_attack_time = now

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		var pos = global_position if is_inside_tree() else position
		am.play_sound_3d("acid_spit", pos, 1.1)

	# Direct caustic spit projectile / damage
	if global_position.distance_to(target_player.global_position) <= attack_range:
		var health = target_player.get_node_or_null("HealthComponent")
		if health and health.has_method("take_damage"):
			health.take_damage(attack_damage, "Acid Spitter")
