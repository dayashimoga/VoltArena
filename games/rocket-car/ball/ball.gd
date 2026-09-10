class_name RocketBall
extends RigidBody3D

## RocketBall: Production soccer ball with continuous collision detection,
## anti-tunneling physics constraints, and real 3D soccer ball geometry.

signal goal_scored(team_id: int)

@export var radius: float = 1.4
@export var ball_mass: float = 12.0
@export var bounciness: float = 0.85
@export var friction_val: float = 0.25

var ball_mesh: Node3D
var last_hit_team: int = 0
var last_hit_speed: float = 0.0

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

# Property alias for compatibility with test assertions and AI
var velocity: Vector3:
	get: return linear_velocity
	set(v): linear_velocity = v

func _ready() -> void:
	add_to_group("balls")
	collision_layer = GameConstants.LAYER_BALL
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	mass = ball_mass
	continuous_cd = true # Prevents tunneling at supersonic car/ball speeds
	contact_monitor = true
	max_contacts_reported = 4
	linear_damp = 0.35
	angular_damp = 0.55
	gravity_scale = 1.25

	var mat = PhysicsMaterial.new()
	mat.bounce = bounciness
	mat.friction = friction_val
	physics_material_override = mat

	setup_visuals()

func setup_visuals() -> void:
	# Production-quality 3D soccer ball model
	ball_mesh = ModelCacheScript.get_prop("soccer_ball")
	if not ball_mesh:
		ball_mesh = MeshBuilder.build_energy_ball()
	else:
		ball_mesh.scale = Vector3(2.8, 2.8, 2.8)
	add_child(ball_mesh)

	var col = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius
	col.shape = sphere_shape
	add_child(col)

func _physics_process(_delta: float) -> void:
	# Safety out-of-bounds bounds check
	if is_inside_tree():
		if global_position.y < -4.0 or abs(global_position.x) > 55.0 or abs(global_position.z) > 75.0:
			reset_to_center()

func apply_ball_impulse(impulse: Vector3, contact_pos: Vector3 = Vector3.ZERO) -> void:
	if is_inside_tree() and contact_pos != Vector3.ZERO:
		apply_impulse(impulse, contact_pos - global_position)
	elif is_inside_tree():
		apply_central_impulse(impulse)
	else:
		linear_velocity += impulse / mass

	var speed = impulse.length()
	last_hit_speed = speed
	if speed > 6.0 and is_inside_tree():
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am:
			var p = global_position if is_inside_tree() else position
			am.play_sound_3d("hit", p, clampf(speed / 25.0, 0.7, 1.5))

func reset_to_center() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	if is_inside_tree():
		global_position = Vector3(0, radius + 0.6, 0)
	else:
		position = Vector3(0, radius + 0.6, 0)

func reset_ball() -> void:
	reset_to_center()
