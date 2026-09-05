class_name SubwayBrute
extends EnemyBase

var is_charging: bool = false
var charge_timer: float = 0.0
var charge_direction: Vector3 = Vector3.ZERO

func _init() -> void:
	enemy_name = "Subway Brute"
	enemy_type = "Brute"
	score_value = 200
	move_speed = 3.2
	turn_speed = 3.5
	attack_damage = 40.0
	attack_rate_sec = 2.5
	attack_range = 3.0

func setup_visuals() -> void:
	# Detailed massive armored brute model
	var brute_model = MeshBuilder.build_brute_mesh()
	add_child(brute_model)

	var col = CollisionShape3D.new()
	var cap = BoxShape3D.new()
	cap.size = Vector3(1.4, 2.2, 1.2)
	col.shape = cap
	col.position = Vector3(0, 1.1, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 250.0
		health_component.max_armor = 100.0
		health_component.reset()

func perform_attack() -> void:
	# Heavy slam attack
	super.perform_attack()
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		var pos = global_position if is_inside_tree() else position
		am.play_sound_3d("explosion", pos, 0.8)
