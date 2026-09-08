class_name DestructibleProp
extends StaticBody3D

## Authored destructible prop for Strike Vector:
## Crates, explosive barrels, barriers, doors, and weak walls.

signal destroyed(prop_name: String)

enum PropType {
	CRATE,
	EXPLOSIVE_BARREL,
	GLASS_PANEL,
	BARRIER,
	WEAK_WALL
}

@export var prop_type: PropType = PropType.CRATE
@export var max_health: float = 40.0
@export var explosion_damage: float = 60.0
@export var explosion_radius: float = 4.5

var current_health: float = 40.0
var is_destroyed: bool = false

func _ready() -> void:
	add_to_group("destructibles")
	collision_layer = GameConstants.LAYER_WORLD
	collision_mask = GameConstants.LAYER_PROJECTILES | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	current_health = max_health
	_build_visual_and_collision()

func _build_visual_and_collision() -> void:
	var mi = MeshInstance3D.new()
	var col = CollisionShape3D.new()

	match prop_type:
		PropType.EXPLOSIVE_BARREL:
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.4
			cyl.bottom_radius = 0.4
			cyl.height = 1.1
			mi.mesh = cyl
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.25, 0.1) # Bright Red
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.2, 0.1)
			mat.emission_energy_multiplier = 0.5
			mi.material_override = mat

			var c_shape = CylinderShape3D.new()
			c_shape.radius = 0.45
			c_shape.height = 1.1
			col.shape = c_shape
			col.position = Vector3(0, 0.55, 0)
			mi.position = Vector3(0, 0.55, 0)

		PropType.BARRIER, PropType.WEAK_WALL:
			var box = BoxMesh.new()
			box.size = Vector3(3.0, 2.2, 0.6)
			mi.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.38, 0.45)
			mat.metallic = 0.6
			mi.material_override = mat

			var c_box = BoxShape3D.new()
			c_box.size = Vector3(3.0, 2.2, 0.6)
			col.shape = c_box
			col.position = Vector3(0, 1.1, 0)
			mi.position = Vector3(0, 1.1, 0)

		_: # CRATE
			var box = BoxMesh.new()
			box.size = Vector3(1.2, 1.2, 1.2)
			mi.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.55, 0.40, 0.25)
			mat.roughness = 0.8
			mi.material_override = mat

			var c_box = BoxShape3D.new()
			c_box.size = Vector3(1.2, 1.2, 1.2)
			col.shape = c_box
			col.position = Vector3(0, 0.6, 0)
			mi.position = Vector3(0, 0.6, 0)

	add_child(mi)
	add_child(col)

func take_damage(amount: float, _dealer_name: String = "", _weapon: String = "") -> void:
	if is_destroyed:
		return
	current_health -= amount
	if current_health <= 0.0:
		_destroy()

func _destroy() -> void:
	is_destroyed = true
	destroyed.emit(name)

	if prop_type == PropType.EXPLOSIVE_BARREL:
		_explode()
	else:
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("play_sound"):
			am.play_sound("hit", 1.0)

	collision_layer = 0
	collision_mask = 0
	visible = false
	queue_free()

func _explode() -> void:
	var tree = get_tree()
	if not tree:
		return

	var targets = tree.get_nodes_in_group("enemies") + tree.get_nodes_in_group("players") + tree.get_nodes_in_group("destructibles")
	for target in targets:
		if is_instance_valid(target) and target is Node3D and target != self:
			var dist = global_position.distance_to(target.global_position)
			if dist <= explosion_radius:
				var falloff = 1.0 - (dist / explosion_radius)
				if target.has_method("take_damage"):
					target.take_damage(explosion_damage * falloff, "ExplosiveBarrel", "Explosion")

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("explosion", 1.0)
