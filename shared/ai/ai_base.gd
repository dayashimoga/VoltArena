class_name AIBase
extends CharacterBody3D

enum AIState {
	IDLE,
	PATROL,
	SEEK,
	ATTACK,
	RETREAT,
	FLEE
}

@export var current_state: AIState = AIState.IDLE
@export var movement_speed: float = 6.0
@export var turn_speed: float = 8.0
@export var detection_range: float = 30.0
@export var attack_range: float = 18.0
@export var retreat_health_threshold: float = 25.0

var current_target: Node3D = null
var difficulty: int = GameConstants.Difficulty.NORMAL

var reaction_timer: float = 0.0
var aim_jitter_amount: float = 0.05

func _ready() -> void:
	configure_difficulty(difficulty)

func configure_difficulty(diff: int) -> void:
	difficulty = diff
	match diff:
		GameConstants.Difficulty.EASY:
			movement_speed *= 0.8
			aim_jitter_amount = 0.12
		GameConstants.Difficulty.NORMAL:
			aim_jitter_amount = 0.05
		GameConstants.Difficulty.HARD:
			movement_speed *= 1.15
			aim_jitter_amount = 0.02
		GameConstants.Difficulty.NIGHTMARE:
			movement_speed *= 1.3
			aim_jitter_amount = 0.005

func find_nearest_target_in_group(group_name: String) -> Node3D:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if not tree:
		return null
	var members = tree.get_nodes_in_group(group_name)
	var best_target: Node3D = null
	var min_dist = INF
	for m in members:
		if m is Node3D and m != self and is_instance_valid(m):
			# Skip dead targets
			if m.has_method("is_dead") and m.is_dead():
				continue
			var d = global_position.distance_to(m.global_position)
			if d < min_dist and d <= detection_range:
				min_dist = d
				best_target = m
	return best_target

func has_line_of_sight(target: Node3D) -> bool:
	if not target or not is_instance_valid(target):
		return false
	var w3d = get_world_3d()
	if not w3d:
		return false
	var space = w3d.direct_space_state
	var start = global_position + Vector3.UP * 1.5
	var finish = target.global_position + Vector3.UP * 1.5
	var query = PhysicsRayQueryParameters3D.create(start, finish, GameConstants.LAYER_WORLD, [get_rid()])
	var res = space.intersect_ray(query)
	return res.is_empty()

func steer_towards(target_pos: Vector3, delta: float) -> void:
	var dir = (target_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		var target_basis = Basis.looking_at(dir, Vector3.UP)
		basis = basis.slerp(target_basis, turn_speed * delta)
		velocity.x = dir.x * movement_speed
		velocity.z = dir.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, movement_speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, movement_speed * delta * 5.0)
