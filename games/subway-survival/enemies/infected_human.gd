class_name SubwayInfectedHuman
extends EnemyBase

func _init() -> void:
	enemy_name = "Infected Commuter"
	enemy_type = "Infected"
	score_value = 50
	move_speed = 5.2
	turn_speed = 7.0
	attack_damage = 16.0
	attack_rate_sec = 1.0
	attack_range = 2.0

func setup_visuals() -> void:
	creature_model = ModelCacheScript.get_enemy("infected")
	if not creature_model:
		creature_model = ModelCacheScript.get_character("assault")
	add_child(creature_model)
	ModelCacheScript.play_animation(creature_model, "Idle")

	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 60.0
		health_component.max_armor = 0.0
		health_component.reset()
