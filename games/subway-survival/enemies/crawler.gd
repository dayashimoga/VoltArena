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
	# Quadruped / Low hunch visual
	var body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.4, 0.9)
	body_mesh.mesh = box
	body_mesh.position = Vector3(0, 0.35, 0)
	body_mesh.material_override = MaterialGenerator.get_material("enemy_crawler")
	add_child(body_mesh)

	# Glowing red eyes
	var eyes = MeshInstance3D.new()
	var eye_box = BoxMesh.new()
	eye_box.size = Vector3(0.28, 0.08, 0.1)
	eyes.mesh = eye_box
	eyes.position = Vector3(0, 0.45, -0.46)
	eyes.material_override = MaterialGenerator.get_material("neon_magenta")
	add_child(eyes)

	# Collision
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.45
	col.shape = sphere
	col.position = Vector3(0, 0.45, 0)
	add_child(col)

	if health_component:
		health_component.max_health = 40.0
		health_component.max_armor = 0.0
		health_component.reset()
