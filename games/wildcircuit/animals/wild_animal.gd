class_name WildAnimal
extends CharacterBody3D

## WildAnimal: Autonomous Wildlife Entity with State Machine AI for WildCircuit.
## Implements IDLE, ROAM, GRAZE_FEED, DRINK, SLEEP, SOCIALIZE, INVESTIGATE, and FLEE.

enum State {
	IDLE = 0,
	ROAM = 1,
	GRAZE_FEED = 2,
	DRINK = 3,
	SLEEP = 4,
	SOCIALIZE = 5,
	INVESTIGATE = 6,
	FLEE = 7
}

signal state_changed(old_state: int, new_state: int)
signal photographed(score: int, grade: String)

const AnimalDataScript = preload("res://games/wildcircuit/animals/animal_data.gd")

@export var species_id: String = "gazelle"
@export var move_speed: float = 3.2
@export var flee_speed: float = 8.5

var current_state: int = State.IDLE
var state_timer: float = 3.0
var target_wander_pos: Vector3 = Vector3.ZERO
var home_pos: Vector3 = Vector3.ZERO
var species_info: Dictionary = {}

var visual_node: Node3D
var head_node: Node3D
var obstacle_ray: RayCast3D

func _ready() -> void:
	add_to_group("animals")
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER

	home_pos = global_position
	species_info = AnimalDataScript.get_species(species_id)
	setup_visuals()
	setup_nav_sensors()

func setup_visuals() -> void:
	visual_node = Node3D.new()
	visual_node.name = "AnimalVisual"
	add_child(visual_node)

	var s_scale: Vector3 = species_info.get("scale", Vector3(1.0, 1.0, 1.0))
	var s_color: Color = species_info.get("color", Color(0.7, 0.5, 0.3))

	var mat = StandardMaterial3D.new()
	mat.albedo_color = s_color
	mat.roughness = 0.85

	# 1. Torso Body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.7 * s_scale.x, 0.7 * s_scale.y, 1.4 * s_scale.z)
	body.mesh = b_box
	body.material_override = mat
	body.position = Vector3(0, 0.8 * s_scale.y, 0)
	visual_node.add_child(body)

	# 2. Neck & Head
	head_node = Node3D.new()
	head_node.position = Vector3(0, 1.1 * s_scale.y, -0.6 * s_scale.z)
	var head_mesh = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.4 * s_scale.x, 0.45 * s_scale.y, 0.55 * s_scale.z)
	head_mesh.mesh = h_box
	head_mesh.material_override = mat
	head_mesh.position = Vector3(0, 0.25 * s_scale.y, -0.2 * s_scale.z)
	head_node.add_child(head_mesh)

	# Horns if applicable
	if species_info.get("has_horns", false):
		for side in [-1.0, 1.0]:
			var horn = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.02
			cyl.bottom_radius = 0.06
			cyl.height = 0.5 * s_scale.y
			horn.mesh = cyl
			var mat_horn = StandardMaterial3D.new()
			mat_horn.albedo_color = species_info.get("horn_color", Color(0.2, 0.2, 0.2))
			horn.material_override = mat_horn
			horn.position = Vector3(side * 0.15 * s_scale.x, 0.6 * s_scale.y, -0.1 * s_scale.z)
			horn.rotation_degrees.x = 20.0
			head_node.add_child(horn)

	visual_node.add_child(head_node)

	# 3. Four Legs
	for side in [-1.0, 1.0]:
		for fwd in [-1.0, 1.0]:
			var leg = MeshInstance3D.new()
			var l_box = BoxMesh.new()
			l_box.size = Vector3(0.18 * s_scale.x, 0.8 * s_scale.y, 0.18 * s_scale.z)
			leg.mesh = l_box
			leg.material_override = mat
			leg.position = Vector3(side * 0.3 * s_scale.x, 0.4 * s_scale.y, fwd * 0.45 * s_scale.z)
			visual_node.add_child(leg)

	# Collision
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.0 * s_scale.x, 1.2 * s_scale.y, 1.6 * s_scale.z)
	col.shape = box_shape
	col.position = Vector3(0, 0.7 * s_scale.y, 0)
	add_child(col)

func setup_nav_sensors() -> void:
	obstacle_ray = RayCast3D.new()
	obstacle_ray.target_position = Vector3(0, 0, -2.5)
	obstacle_ray.position = Vector3(0, 0.5, 0)
	obstacle_ray.collision_mask = GameConstants.LAYER_WORLD
	add_child(obstacle_ray)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 22.0 * delta

	state_timer -= delta
	check_player_proximity()

	if state_timer <= 0.0 and current_state != State.FLEE:
		_transition_to_next_state()

	execute_state(delta)
	move_and_slide()

func check_player_proximity() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var player = players[0]
	var dist = global_position.distance_to(player.global_position)
	var flee_thresh = species_info.get("flee_dist", 7.0)

	var p_speed = player.velocity.length() if "velocity" in player else 0.0

	if dist < flee_thresh and p_speed > 3.0: # Player sprinting or driving close!
		if current_state != State.FLEE:
			change_state(State.FLEE)
			state_timer = 4.0
			# Set wander direction away from player
			var away_dir = (global_position - player.global_position).normalized()
			target_wander_pos = global_position + away_dir * 18.0
	elif dist < flee_thresh * 1.5 and p_speed < 1.0 and current_state == State.IDLE:
		if randf() < 0.2:
			change_state(State.INVESTIGATE)
			state_timer = 3.5

func _transition_to_next_state() -> void:
	var r = randf()
	if r < 0.35:
		change_state(State.ROAM)
		state_timer = randf_range(4.0, 8.0)
		_pick_new_wander_target()
	elif r < 0.65:
		change_state(State.GRAZE_FEED)
		state_timer = randf_range(5.0, 10.0)
	elif r < 0.85:
		change_state(State.IDLE)
		state_timer = randf_range(3.0, 6.0)
	else:
		change_state(State.DRINK)
		state_timer = randf_range(4.0, 7.0)

func change_state(new_state: int) -> void:
	if new_state == current_state:
		return
	var old = current_state
	current_state = new_state
	state_changed.emit(old, new_state)

	# Animation / Pose adjustments
	if head_node:
		match current_state:
			State.GRAZE_FEED, State.DRINK:
				head_node.rotation_degrees.x = 35.0 # head lowered to ground
			State.INVESTIGATE:
				head_node.rotation_degrees.x = -15.0 # alert raised head
			State.SLEEP:
				head_node.rotation_degrees.x = 45.0
			_:
				head_node.rotation_degrees.x = 0.0

func execute_state(delta: float) -> void:
	match current_state:
		State.IDLE, State.GRAZE_FEED, State.DRINK, State.SLEEP:
			velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		State.ROAM:
			_navigate_towards(target_wander_pos, move_speed, delta)
		State.FLEE:
			_navigate_towards(target_wander_pos, flee_speed, delta)
		State.INVESTIGATE:
			var players = get_tree().get_nodes_in_group("players")
			if not players.is_empty():
				_turn_towards(players[0].global_position, delta * 3.0)
			velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)

func _navigate_towards(target_pt: Vector3, spd: float, delta: float) -> void:
	var to_target = target_pt - global_position
	to_target.y = 0.0
	var dist = to_target.length()

	if dist < 1.0:
		velocity.x = 0.0
		velocity.z = 0.0
		if current_state == State.FLEE:
			change_state(State.IDLE)
		return

	var move_dir = to_target.normalized()
	# Avoid obstacle walls
	if obstacle_ray and obstacle_ray.is_colliding():
		move_dir = move_dir.rotated(Vector3.UP, PI * 0.5)

	velocity.x = move_dir.x * spd
	velocity.z = move_dir.z * spd
	_turn_towards(global_position + move_dir, delta * 5.0)

func _turn_towards(look_pt: Vector3, rate: float) -> void:
	var to_pt = look_pt - global_position
	to_pt.y = 0.0
	if to_pt.length_squared() > 0.01:
		var target_angle = atan2(-to_pt.x, -to_pt.z)
		visual_node.rotation.y = lerp_angle(visual_node.rotation.y, target_angle, rate)

func _pick_new_wander_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(6.0, 16.0)
	target_wander_pos = home_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func get_current_behavior_name() -> String:
	match current_state:
		State.IDLE: return "Resting / Idle"
		State.ROAM: return "Roaming Habitat"
		State.GRAZE_FEED: return "Grazing / Feeding"
		State.DRINK: return "Drinking Water"
		State.SLEEP: return "Sleeping"
		State.SOCIALIZE: return "Socializing"
		State.INVESTIGATE: return "Investigating Observer"
		State.FLEE: return "Alert / Fleeing"
		_: return "Active"
