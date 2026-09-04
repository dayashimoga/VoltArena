class_name PickupBase
extends Area3D

enum PickupType {
	HEALTH,
	ARMOR,
	AMMO
}

@export var pickup_type: PickupType = PickupType.HEALTH
@export var amount: int = 25
@export var respawn_time_sec: float = 15.0

var is_active: bool = true
var respawn_timer: float = 0.0
var visual_mesh: MeshInstance3D
var base_y: float = 0.0

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PICKUPS
	collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	body_entered.connect(_on_body_entered)
	base_y = position.y
	setup_visual()

func setup_visual() -> void:
	visual_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	visual_mesh.mesh = box

	match pickup_type:
		PickupType.HEALTH:
			visual_mesh.material_override = MaterialGenerator.get_material("health_red")
		PickupType.ARMOR:
			visual_mesh.material_override = MaterialGenerator.get_material("neon_cyan")
		PickupType.AMMO:
			visual_mesh.material_override = MaterialGenerator.get_material("gold_pickup")

	add_child(visual_mesh)

	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.8
	col.shape = sphere
	add_child(col)

func _process(delta: float) -> void:
	if not is_active:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()
		return

	# Idle bobbing and rotating animation
	var time = Time.get_ticks_msec() / 1000.0
	visual_mesh.rotation.y += delta * 2.0
	visual_mesh.position.y = sin(time * 3.0) * 0.15

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return

	var applied = false
	if pickup_type == PickupType.HEALTH and body.has_node("HealthComponent"):
		var hp = body.get_node("HealthComponent")
		if hp.current_health < hp.max_health:
			hp.heal(amount)
			applied = true
	elif pickup_type == PickupType.ARMOR and body.has_node("HealthComponent"):
		var hp = body.get_node("HealthComponent")
		if hp.current_armor < hp.max_armor:
			hp.add_armor(amount)
			applied = true
	elif pickup_type == PickupType.AMMO and body.has_method("add_ammo"):
		body.add_ammo(amount)
		applied = true

	if applied:
		consume()

func consume() -> void:
	is_active = false
	visible = false
	respawn_timer = respawn_time_sec
	if get_node_or_null("/root/AudioManager"):
		get_node("/root/AudioManager").play_sound_3d("pickup", global_position)
	if get_node_or_null("/root/EventBus"):
		get_node("/root/EventBus").pickup_collected.emit(str(pickup_type), amount)

func respawn() -> void:
	is_active = true
	visible = true
