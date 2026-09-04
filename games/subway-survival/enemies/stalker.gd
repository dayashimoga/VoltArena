class_name SubwayStalker
extends EnemyBase

var projectile_cooldown: float = 0.0

func _init() -> void:
	enemy_name = "Subway Stalker"
	enemy_type = "Stalker"
	score_value = 80
	move_speed = 4.8
	turn_speed = 7.0
	attack_damage = 18.0
	attack_rate_sec = 2.0
	attack_range = 14.0 # Ranged engagement distance

func setup_visuals() -> void:
	# Slender upright body
	var body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 1.2, 0.4)
	body_mesh.mesh = box
	body_mesh.position = Vector3(0, 0.8, 0)
	body_mesh.material_override = MaterialGenerator.get_material("dark_hull")
	add_child(body_mesh)

	# Glowing green bioluminescent spots
	var glow = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.2, 0.6, 0.1)
	glow.mesh = g_box
	glow.position = Vector3(0, 0.9, -0.21)
	glow.material_override = MaterialGenerator.get_material("neon_green")
	add_child(glow)

	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0, 0.8, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 90.0
		health_component.max_armor = 20.0
		health_component.reset()

func perform_attack() -> void:
	if not target_player or not is_instance_valid(target_player):
		return

	# Fire spit projectile towards player
	var dir = ((target_player.global_position + Vector3.UP * 1.0) - (global_position + Vector3.UP * 1.0)).normalized()
	var proj = Projectile.new()
	proj.direction = dir
	proj.speed = 24.0
	proj.damage = attack_damage
	proj.shooter = self
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree and tree.root:
		tree.root.add_child(proj)
		proj.global_position = global_position + Vector3.UP * 1.0 + dir * 0.8
	else:
		proj.queue_free()

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		var pos = global_position if is_inside_tree() else position
		am.play_sound_3d("laser_fire", pos, 0.7)
