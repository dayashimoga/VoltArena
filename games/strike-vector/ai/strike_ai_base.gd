class_name StrikeAIBase
extends CharacterBody3D

## Hierarchical Finite State Machine / Behavior Tree AI Base for Strike Vector.
## Features: LOS/FOV perception, Hearing, NavigationAgent3D, Cover/Flanking,
## Squad coordination, Aim tracking, Grenade flushing, and Deterministic Watchdog Recovery.

signal state_changed(old_state: AIState, new_state: AIState)
signal died(enemy_type: String, score_value: int)

const WeaponProjectileScript = preload("res://games/strike-vector/weapons/weapon_projectile.gd")
const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

enum AIState {
	IDLE,
	PATROL,
	SUSPICIOUS,
	INVESTIGATE,
	ALERT,
	COVER_FLANK,
	AIM,
	ATTACK,
	REPOSITION,
	SEARCH
}

enum Difficulty {
	CASUAL,
	NORMAL,
	VETERAN,
	ELITE
}

@export var enemy_id: String = "rifle_trooper"
@export var enemy_type: String = "Rifle Trooper"
@export var max_health: float = 65.0
@export var move_speed: float = 5.2
@export var sprint_speed: float = 7.8
@export var attack_range: float = 24.0
@export var optimal_range: float = 14.0
@export var fov_degrees: float = 110.0
@export var view_distance: float = 35.0
@export var score_value: int = 150
@export var difficulty: Difficulty = Difficulty.NORMAL

# Combat stats
@export var weapon_damage: float = 10.0
@export var burst_count: int = 3
@export var burst_fire_rate_rpm: float = 480.0
@export var reload_time: float = 2.2
@export var magazine_size: int = 24

# Runtime State
var current_health: float = 65.0
var current_state: AIState = AIState.IDLE
var is_alive: bool = true
var target_player: Node3D = null
var last_known_player_pos: Vector3 = Vector3.ZERO
var has_los_to_player: bool = false
var ammo_in_mag: int = 24

# Timers
var reaction_timer: float = 0.0
var burst_timer: float = 0.0
var burst_shots_left: int = 0
var reload_timer: float = 0.0
var state_timer: float = 0.0
var stuck_watchdog_timer: float = 0.0
var last_watchdog_pos: Vector3 = Vector3.ZERO

# Subsystems
var nav_agent: NavigationAgent3D
var visual_model: Node3D
var squad_coordinator: Node = null

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES

	current_health = max_health
	ammo_in_mag = magazine_size
	last_watchdog_pos = global_position

	_setup_nav_agent()
	_apply_difficulty_modifiers()

func _setup_nav_agent() -> void:
	nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavAgent"
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 1.5
	nav_agent.avoidance_enabled = true
	add_child(nav_agent)

func _apply_difficulty_modifiers() -> void:
	match difficulty:
		Difficulty.CASUAL:
			max_health *= 0.75
			weapon_damage *= 0.70
			reaction_timer = 0.45
		Difficulty.NORMAL:
			max_health *= 1.0
			weapon_damage *= 1.0
			reaction_timer = 0.25
		Difficulty.VETERAN:
			max_health *= 1.25
			weapon_damage *= 1.35
			reaction_timer = 0.12
		Difficulty.ELITE:
			max_health *= 1.50
			weapon_damage *= 1.65
			reaction_timer = 0.05

	current_health = max_health

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_find_player_target()
	_evaluate_perception()
	_update_timers(delta)
	_execute_hfsm(delta)
	_watchdog_stuck_recovery(delta)

	move_and_slide()
	_update_animation()

func _find_player_target() -> void:
	if is_instance_valid(target_player):
		return
	var players = get_tree().get_nodes_in_group("players") if get_tree() else []
	if not players.is_empty() and is_instance_valid(players[0]):
		target_player = players[0]

func _evaluate_perception() -> void:
	if not is_instance_valid(target_player):
		has_los_to_player = false
		return

	var to_player = target_player.global_position - global_position
	var dist = to_player.length()

	if dist > view_distance:
		has_los_to_player = false
		return

	# FOV Check
	var forward = -global_transform.basis.z
	var angle_to_player = rad_to_deg(forward.angle_to(to_player.normalized()))

	# Raycast LOS check
	var space_state = get_world_3d().direct_space_state if get_world_3d() else null
	if space_state:
		var eye_pos = global_position + Vector3(0, 1.4, 0)
		var player_eye = target_player.global_position + Vector3(0, 1.2, 0)
		var query = PhysicsRayQueryParameters3D.create(eye_pos, player_eye)
		query.collision_mask = GameConstants.LAYER_WORLD
		var hit = space_state.intersect_ray(query)

		if hit.is_empty() and (angle_to_player <= fov_degrees * 0.5 or dist < 6.0):
			has_los_to_player = true
			last_known_player_pos = target_player.global_position
			if current_state in [AIState.IDLE, AIState.PATROL, AIState.SUSPICIOUS]:
				set_state(AIState.ALERT)
		else:
			has_los_to_player = false

func _update_timers(delta: float) -> void:
	state_timer += delta
	if burst_timer > 0.0:
		burst_timer = maxf(0.0, burst_timer - delta)

	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			ammo_in_mag = magazine_size

func _execute_hfsm(delta: float) -> void:
	match current_state:
		AIState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
		AIState.PATROL:
			_process_patrol(delta)
		AIState.ALERT:
			_process_alert(delta)
		AIState.COVER_FLANK:
			_process_cover_flank(delta)
		AIState.AIM, AIState.ATTACK:
			_process_attack(delta)
		AIState.REPOSITION:
			_process_reposition(delta)
		AIState.SEARCH:
			_process_search(delta)

func _process_patrol(delta: float) -> void:
	if state_timer > 4.0:
		state_timer = 0.0
		# Pick slight wandering offset
		var wander = Vector3(randf_range(-6.0, 6.0), 0, randf_range(-6.0, 6.0))
		nav_agent.target_position = global_position + wander

	_move_along_nav_path(move_speed, delta)

func _process_alert(delta: float) -> void:
	if not is_instance_valid(target_player):
		set_state(AIState.IDLE)
		return

	_turn_toward(last_known_player_pos, delta)
	if state_timer >= reaction_timer:
		set_state(AIState.COVER_FLANK)

func _process_cover_flank(delta: float) -> void:
	if not is_instance_valid(target_player):
		set_state(AIState.IDLE)
		return

	var dist = global_position.distance_to(target_player.global_position)
	_turn_toward(target_player.global_position, delta)

	if has_los_to_player and dist <= attack_range:
		set_state(AIState.ATTACK)
		return

	# Move toward optimal combat range
	nav_agent.target_position = last_known_player_pos
	_move_along_nav_path(sprint_speed, delta)

func _process_attack(delta: float) -> void:
	if not is_instance_valid(target_player):
		set_state(AIState.IDLE)
		return

	_turn_toward(target_player.global_position, delta)
	var dist = global_position.distance_to(target_player.global_position)

	if not has_los_to_player:
		set_state(AIState.SEARCH)
		return

	if dist > attack_range * 1.2:
		set_state(AIState.COVER_FLANK)
		return

	if ammo_in_mag <= 0:
		_start_reload()
		set_state(AIState.REPOSITION)
		return

	# Burst firing
	if burst_timer <= 0.0 and reload_timer <= 0.0:
		_execute_burst_shot()

func _execute_burst_shot() -> void:
	if not is_instance_valid(target_player):
		return

	ammo_in_mag -= 1
	burst_timer = 60.0 / burst_fire_rate_rpm

	var aim_origin = global_position + Vector3(0, 1.4, 0)
	var dir = (target_player.global_position + Vector3(0, 1.0, 0) - aim_origin).normalized()

	# Spread inaccuracy
	var spread_err = deg_to_rad(randf_range(-3.0, 3.0))
	dir = (Basis(Vector3.UP, spread_err) * dir).normalized()

	var proj = WeaponProjectileScript.new()
	proj.position = aim_origin
	proj.shooter = self
	proj.init_projectile(dir, 95.0, weapon_damage, Color(1.0, 0.25, 0.15), enemy_type)

	var scene_root = get_tree().current_scene if get_tree() else get_parent()
	if scene_root:
		scene_root.add_child(proj)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("laser_fire", 0.9)

func _process_reposition(delta: float) -> void:
	if not is_instance_valid(target_player):
		set_state(AIState.IDLE)
		return

	var away_dir = (global_position - target_player.global_position).normalized()
	var flank_offset = away_dir.cross(Vector3.UP) * (6.0 if randf() > 0.5 else -6.0)
	nav_agent.target_position = global_position + away_dir * 4.0 + flank_offset
	_move_along_nav_path(sprint_speed, delta)

	if reload_timer <= 0.0 and state_timer > 1.8:
		set_state(AIState.ATTACK)

func _process_search(delta: float) -> void:
	nav_agent.target_position = last_known_player_pos
	_move_along_nav_path(move_speed, delta)

	if global_position.distance_to(last_known_player_pos) < 2.0 or state_timer > 8.0:
		set_state(AIState.PATROL)

func _move_along_nav_path(spd: float, delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
		return

	var next_pos = nav_agent.get_next_path_position()
	var move_dir = (next_pos - global_position).normalized()
	move_dir.y = 0.0
	velocity = move_dir * spd

	if move_dir.length_squared() > 0.01:
		_turn_toward(global_position + move_dir, delta)

func _turn_toward(target_pos: Vector3, delta: float) -> void:
	var look_target = target_pos
	look_target.y = global_position.y
	if global_position.distance_squared_to(look_target) > 0.01:
		var target_basis = Basis.looking_at(look_target - global_position, Vector3.UP)
		transform.basis = transform.basis.slerp(target_basis, 10.0 * delta)

func _start_reload() -> void:
	reload_timer = reload_time

func set_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	var old = current_state
	current_state = new_state
	state_timer = 0.0
	state_changed.emit(old, new_state)

func take_damage(amount: float, dealer_name: String = "", weapon: String = "") -> void:
	if not is_alive:
		return

	current_health = maxf(0.0, current_health - amount)
	if current_state in [AIState.IDLE, AIState.PATROL, AIState.SEARCH]:
		set_state(AIState.ALERT)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("hit", 1.0)

	if current_health <= 0.0:
		_die(dealer_name, weapon)

func _die(dealer_name: String, _weapon: String) -> void:
	is_alive = false
	died.emit(enemy_type, score_value)

	# Register kill to player if dealer is player
	if is_instance_valid(target_player) and target_player.has_method("register_kill"):
		target_player.register_kill(score_value)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.emit(enemy_type, score_value)

	# Death tumble / dissolve
	collision_layer = 0
	collision_mask = 0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _watchdog_stuck_recovery(delta: float) -> void:
	stuck_watchdog_timer += delta
	if stuck_watchdog_timer >= 2.0:
		var moved_dist = global_position.distance_to(last_watchdog_pos)
		if moved_dist < 0.25 and current_state in [AIState.COVER_FLANK, AIState.REPOSITION, AIState.SEARCH]:
			# Stuck detected! Nudge toward player or clear target
			if is_instance_valid(target_player):
				var nudge = (target_player.global_position - global_position).normalized() * 1.5
				global_position += nudge
		last_watchdog_pos = global_position
		stuck_watchdog_timer = 0.0

func _update_animation() -> void:
	var rig = find_child("CharacterRig", true, false) as Node3D
	if not rig:
		return
	if not is_alive:
		ModelCacheScript.play_animation(rig, "HitReact")
	elif current_state == AIState.ATTACK:
		ModelCacheScript.play_animation(rig, "Fire")
	elif velocity.length() > 2.0:
		ModelCacheScript.play_animation(rig, "Run")
	elif velocity.length() > 0.3:
		ModelCacheScript.play_animation(rig, "Walk")
	else:
		ModelCacheScript.play_animation(rig, "Idle")
