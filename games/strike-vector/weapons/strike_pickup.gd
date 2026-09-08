class_name StrikePickup
extends Area3D

## World pickups for Strike Vector:
## Ammo, Health, Armor, Grenades, and 6 Arcade Power Modules.

signal picked_up(pickup_type: String, value: int, player: Node)

enum PickupCategory {
	AMMO,
	HEALTH,
	ARMOR,
	GRENADES,
	ARCADE_MODULE
}

@export var pickup_category: PickupCategory = PickupCategory.AMMO
@export var pickup_type: String = "ammo_pack" # "ammo_pack", "health_pack", "armor_pack", "grenade_pack", "mod_rapid_fire", "mod_spread", "mod_piercing", "mod_shield", "mod_overdrive", "mod_drone"
@export var pickup_value: int = 50
@export var respawn_time_sec: float = 0.0 # 0.0 means single-use per mission

var is_active: bool = true
var visual_mesh: Node3D
var rotation_speed: float = 2.4
var bob_speed: float = 3.0
var bob_height: float = 0.15
var base_y: float = 0.0
var elapsed: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = GameConstants.LAYER_PICKUPS
	collision_mask = GameConstants.LAYER_PLAYER
	base_y = position.y

	_setup_collision()
	_setup_visual()
	body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.2
	col.shape = sphere
	add_child(col)

func _setup_visual() -> void:
	visual_mesh = Node3D.new()
	visual_mesh.name = "Visual"

	var color = Color(0.2, 0.9, 1.0)
	match pickup_category:
		PickupCategory.HEALTH: color = Color(0.2, 1.0, 0.4) # Green
		PickupCategory.ARMOR: color = Color(0.1, 0.6, 1.0) # Blue
		PickupCategory.AMMO: color = Color(1.0, 0.75, 0.1) # Amber
		PickupCategory.GRENADES: color = Color(1.0, 0.3, 0.2) # Red
		PickupCategory.ARCADE_MODULE: color = Color(0.9, 0.2, 1.0) # Magenta/Purple

	var mi = MeshInstance3D.new()
	if pickup_category == PickupCategory.ARCADE_MODULE:
		var prism = PrismMesh.new()
		prism.size = Vector3(0.6, 0.7, 0.6)
		mi.mesh = prism
	else:
		var box = BoxMesh.new()
		box.size = Vector3(0.5, 0.5, 0.5)
		mi.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat

	visual_mesh.add_child(mi)
	add_child(visual_mesh)

func _process(delta: float) -> void:
	if not is_active:
		return
	elapsed += delta
	if is_instance_valid(visual_mesh):
		visual_mesh.rotate_y(rotation_speed * delta)
		visual_mesh.position.y = sin(elapsed * bob_speed) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body.is_in_group("players") or body.has_method("apply_pickup"):
		_apply_to_player(body)

func _apply_to_player(player: Node3D) -> void:
	is_active = false
	visible = false

	if player.has_method("apply_pickup"):
		player.apply_pickup(pickup_type, pickup_value)

	picked_up.emit(pickup_type, pickup_value, player)

	# Audio chime
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("pickup", 1.0)

	if respawn_time_sec > 0.0:
		var tree = get_tree()
		if tree:
			tree.create_timer(respawn_time_sec).timeout.connect(_respawn)
	else:
		queue_free()

func _respawn() -> void:
	is_active = true
	visible = true
