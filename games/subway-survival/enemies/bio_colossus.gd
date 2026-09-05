class_name BioColossus
extends EnemyBase

signal boss_defeated()

func _init() -> void:
	enemy_name = "Bio-Colossus"
	enemy_type = "Boss"
	score_value = 1000
	move_speed = 3.6
	turn_speed = 3.0
	attack_damage = 50.0
	attack_rate_sec = 2.2
	attack_range = 4.2

func setup_visuals() -> void:
	var boss_model = MeshBuilder.build_colossus_boss_mesh()
	add_child(boss_model)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.6, 3.8, 2.4)
	col.shape = box
	col.position = Vector3(0, 1.9, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 1200.0
		health_component.max_armor = 400.0
		health_component.reset()

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("colossus_roar", 0.9, 3.0)

func perform_attack() -> void:
	super.perform_attack()
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		var pos = global_position if is_inside_tree() else position
		am.play_sound_3d("colossus_stomp", pos, 0.8, 4.0)

func _on_died(killer: Node) -> void:
	boss_defeated.emit()
	super._on_died(killer)
