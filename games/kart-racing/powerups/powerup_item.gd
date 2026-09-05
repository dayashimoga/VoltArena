class_name PowerUpItem
extends Area3D

enum ItemType {
	TURBO_BOOST,
	EMP_SHIELD,
	SHOCK_MINE
}

var is_active: bool = true
var respawn_timer: float = 0.0
var box_mesh: Node3D

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PICKUPS
	collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	body_entered.connect(_on_body_entered)
	setup_visual()

func setup_visual() -> void:
	box_mesh = MeshBuilder.build_item_box()
	box_mesh.position = Vector3(0, 0.9, 0)
	add_child(box_mesh)

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.2
	col.shape = sphere
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

func _process(delta: float) -> void:
	if not is_active:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			is_active = true
			visible = true
		return

	# Spin & bob animation
	box_mesh.rotate_y(delta * 2.5)
	box_mesh.position.y = 0.9 + sin(Time.get_ticks_msec() / 1000.0 * 3.5) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	if body is KartController:
		is_active = false
		visible = false
		respawn_timer = 10.0

		# Apply powerup to kart
		body.apply_item_boost(3.0)

		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			var pos = global_position if is_inside_tree() else position
			am.play_sound_3d("pickup", pos)
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus and body.is_player:
			bus.show_toast_requested.emit("TURBO BOOST ACQUIRED!", Color(1.0, 0.8, 0.0))
