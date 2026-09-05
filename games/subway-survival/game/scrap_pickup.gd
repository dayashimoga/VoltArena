class_name ScrapPickup
extends Area3D

@export var scrap_amount: int = 25
var is_collected: bool = false
var gear_mesh: Node3D
var bob_time: float = 0.0
var base_y: float = 0.5

func _ready() -> void:
	add_to_group("pickups")
	add_to_group("scrap_pickups")
	collision_layer = GameConstants.LAYER_PICKUPS
	collision_mask = GameConstants.LAYER_PLAYER

	gear_mesh = MeshBuilder.build_scrap_gear_mesh()
	add_child(gear_mesh)

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.4
	col.shape = sphere
	add_child(col)

	base_y = position.y
	body_entered.connect(_on_body_entered)

	# Auto despawn after 35s
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.create_timer(35.0).timeout.connect(func():
			if is_instance_valid(self) and not is_collected:
				queue_free()
		)

func _process(delta: float) -> void:
	if is_collected:
		return

	bob_time += delta * 3.0
	if is_instance_valid(gear_mesh):
		gear_mesh.rotation.y += delta * 2.5
		gear_mesh.position.y = sin(bob_time) * 0.12

	# Magnetize toward player within 4 meters
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		var players = tree.get_nodes_in_group("players")
		if not players.is_empty():
			var p = players[0]
			if is_instance_valid(p):
				var dist = global_position.distance_to(p.global_position)
				if dist < 4.0:
					var fly_dir = (p.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
					global_position += fly_dir * delta * 12.0

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body.is_in_group("players"):
		is_collected = true
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			am.play_sound("pickup")

		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree and tree.current_scene and tree.current_scene.has_method("_on_enemy_killed"):
			# Increment scrap in SubwayMain
			if "total_scrap" in tree.current_scene:
				tree.current_scene.total_scrap += scrap_amount
				if tree.current_scene.hud and tree.current_scene.hud.has_method("update_scrap"):
					tree.current_scene.hud.update_scrap(tree.current_scene.total_scrap)

		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.show_toast_requested.emit("+%d SCRAP SALVAGED!" % scrap_amount, Color(1.0, 0.85, 0.2))

		queue_free()
