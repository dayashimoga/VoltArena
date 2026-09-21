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

var current_state: String = "idle"
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
	if visual_node:
		visual_node.queue_free()

	visual_node = MeshBuilder.build_wildlife_animal_model(species_id)
	add_child(visual_node)

	head_node = visual_node.find_child("HeadNode", true, false)

	# Collision
	for c in get_children():
		if c is CollisionShape3D:
			c.queue_free()

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	var s_scale: Vector3 = species_info.get("scale", Vector3(1.0, 1.0, 1.0))
	box_shape.size = Vector3(1.0 * s_scale.x, 1.2 * s_scale.y, 1.8 * s_scale.z)
	col.shape = box_shape
	col.position = Vector3(0, 0.6 * s_scale.y, 0)
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

	if state_timer <= 0.0 and current_state != "flee":
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
		if current_state != "flee":
			take_fright(player.global_position)
	elif dist < flee_thresh * 1.5 and p_speed < 1.0 and current_state == "idle":
		if randf() < 0.2:
			change_state("investigate")
			state_timer = 3.5

func _transition_to_next_state() -> void:
	var r = randf()
	if r < 0.35:
		change_state("roam")
		state_timer = randf_range(4.0, 8.0)
		_pick_new_wander_target()
	elif r < 0.65:
		change_state("graze")
		state_timer = randf_range(5.0, 10.0)
	elif r < 0.85:
		change_state("idle")
		state_timer = randf_range(3.0, 6.0)
	else:
		change_state("drink")
		state_timer = randf_range(4.0, 7.0)

func transition_to_state(new_state_name: String) -> void:
	change_state(new_state_name)

func take_fright(threat_pos: Vector3 = Vector3.ZERO) -> void:
	change_state("flee")
	state_timer = 4.0
	if threat_pos != Vector3.ZERO:
		var away_dir = (global_position - threat_pos).normalized()
		target_wander_pos = global_position + away_dir * 18.0
	else:
		var angle = randf() * TAU
		target_wander_pos = global_position + Vector3(cos(angle), 0, sin(angle)) * 18.0

func _state_to_str(s) -> String:
	if s is String:
		var s_lower = s.to_lower()
		if s_lower == "graze_feed":
			return "graze"
		return s_lower
	match s:
		State.IDLE: return "idle"
		State.ROAM: return "roam"
		State.GRAZE_FEED: return "graze"
		State.DRINK: return "drink"
		State.SLEEP: return "sleep"
		State.SOCIALIZE: return "socialize"
		State.INVESTIGATE: return "investigate"
		State.FLEE: return "flee"
		_: return "idle"

func _str_to_state(s: String) -> int:
	match s.to_lower():
		"idle": return State.IDLE
		"roam": return State.ROAM
		"graze", "graze_feed": return State.GRAZE_FEED
		"drink": return State.DRINK
		"sleep": return State.SLEEP
		"socialize": return State.SOCIALIZE
		"investigate": return State.INVESTIGATE
		"flee": return State.FLEE
		_: return State.IDLE

func change_state(new_state) -> void:
	var next_str = _state_to_str(new_state)
	if next_str == current_state:
		return
	var old_str = current_state
	current_state = next_str
	state_changed.emit(_str_to_state(old_str), _str_to_state(next_str))

	# Animation / Pose adjustments
	if head_node:
		match current_state:
			"graze", "drink":
				head_node.rotation_degrees.x = 35.0 # head lowered to ground
			"investigate":
				head_node.rotation_degrees.x = -15.0 # alert raised head
			"sleep":
				head_node.rotation_degrees.x = 45.0
			_:
				head_node.rotation_degrees.x = 0.0

func execute_state(delta: float) -> void:
	match current_state:
		"idle", "graze", "drink", "sleep":
			velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		"roam":
			_navigate_towards(target_wander_pos, move_speed, delta)
		"flee":
			_navigate_towards(target_wander_pos, flee_speed, delta)
		"investigate":
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
		if current_state == "flee":
			change_state("idle")
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
		"idle": return "Resting / Idle"
		"roam": return "Roaming Habitat"
		"graze": return "Grazing / Feeding"
		"drink": return "Drinking Water"
		"sleep": return "Sleeping"
		"socialize": return "Socializing"
		"investigate": return "Investigating Observer"
		"flee": return "Alert / Fleeing"
		_: return "Active"
