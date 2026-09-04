class_name RocketBall
extends CharacterBody3D

signal goal_scored(team_id: int)

@export var radius: float = 1.4
@export var gravity: float = 18.0
@export var bounciness: float = 0.82
@export var drag: float = 0.985

var ball_mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("balls")
	collision_layer = GameConstants.LAYER_BALL
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

	setup_visuals()

func setup_visuals() -> void:
	ball_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	ball_mesh.mesh = sphere
	ball_mesh.material_override = MaterialGenerator.get_material("energy_ball")
	add_child(ball_mesh)

	var col = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius
	col.shape = sphere_shape
	add_child(col)

func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta
	velocity.x *= drag
	velocity.z *= drag

	# Rotate ball mesh proportionally to speed
	var speed = velocity.length()
	if speed > 0.1 and is_instance_valid(ball_mesh):
		var rot_axis = Vector3(-velocity.z, 0, velocity.x).normalized()
		ball_mesh.rotate(rot_axis, (speed / radius) * delta)

	if not is_inside_tree():
		return

	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * bounciness
		if speed > 4.0:
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am:
				var pos = global_position if is_inside_tree() else position
				am.play_sound_3d("hit", pos, clampf(speed / 20.0, 0.6, 1.4))

func apply_ball_impulse(impulse: Vector3) -> void:
	velocity += impulse

func reset_to_center() -> void:
	if is_inside_tree():
		global_position = Vector3(0, radius + 0.5, 0)
	else:
		position = Vector3(0, radius + 0.5, 0)
	velocity = Vector3.ZERO
