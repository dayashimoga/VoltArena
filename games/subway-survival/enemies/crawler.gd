class_name SubwayCrawler
extends EnemyBase

func _init() -> void:
	enemy_name = "Subway Crawler"
	enemy_type = "Crawler"
	score_value = 40
	move_speed = 7.5 # Very fast
	turn_speed = 9.0
	attack_damage = 12.0
	attack_rate_sec = 0.7
	attack_range = 1.8

func setup_visuals() -> void:
	creature_model = ModelCacheScript.get_enemy("crawler")
	if not creature_model:
		creature_model = ModelCacheScript.get_enemy("infected_human")
	add_child(creature_model)
	ModelCacheScript.play_animation(creature_model, "Idle")

	# Upright Humanoid Collision
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.40
	cap.height = 1.75
	col.shape = cap
	col.position = Vector3(0, 0.88, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 40.0
		health_component.max_armor = 0.0
		health_component.reset()
