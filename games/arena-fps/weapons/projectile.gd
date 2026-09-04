class_name Projectile
extends Area3D

@export var speed: float = 45.0
@export var damage: float = 35.0
@export var lifetime: float = 4.0
@export var is_explosive: bool = false
@export var blast_radius: float = 5.0
@export var has_gravity: bool = false
@export var gravity_scale: float = 12.0

var direction: Vector3 = Vector3.FORWARD
var shooter: Node = null
var current_lifetime: float = 0.0
var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PROJECTILES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	body_entered.connect(_on_body_entered)
	velocity = direction * speed
	setup_mesh()

func setup_mesh() -> void:
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh_inst.mesh = sphere
	mesh_inst.material_override = MaterialGenerator.get_material("neon_orange" if is_explosive else "neon_cyan")
	add_child(mesh_inst)

func _physics_process(delta: float) -> void:
	current_lifetime += delta
	if current_lifetime >= lifetime:
		explode_or_free()
		return

	if has_gravity:
		velocity.y -= gravity_scale * delta

	global_position += velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return

	if is_explosive:
		explode_or_free()
	else:
		if body.has_node("HealthComponent"):
			body.get_node("HealthComponent").take_damage(damage, shooter)
		elif body.has_method("take_damage"):
			body.take_damage(damage, shooter)
		queue_free()

func explode_or_free() -> void:
	if is_explosive:
		if get_node_or_null("/root/AudioManager"):
			get_node("/root/AudioManager").play_sound_3d("explosion", global_position)

		# Area damage query
		var w3d = get_world_3d()
		if w3d:
			var space = w3d.direct_space_state
			var shape = SphereShape3D.new()
			shape.radius = blast_radius
			var params = PhysicsShapeQueryParameters3D.new()
			params.shape = shape
			params.transform = Transform3D(Basis(), global_position)
			params.collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

			var hits = space.intersect_shape(params)
			for h in hits:
				var col = h.collider
				if col and col != shooter:
					var dist = global_position.distance_to(col.global_position)
					var falloff = clampf(1.0 - (dist / blast_radius), 0.1, 1.0)
					var dmg = damage * falloff
					if col.has_node("HealthComponent"):
						col.get_node("HealthComponent").take_damage(dmg, shooter, false)
					elif col.has_method("take_damage"):
						col.take_damage(dmg, shooter)

	queue_free()
