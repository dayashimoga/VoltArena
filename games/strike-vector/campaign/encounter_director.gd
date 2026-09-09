class_name EncounterDirector
extends Node3D

## Forward Encounter Director for Strike Vector.
## Manages localized firefights: entry triggers, locked exits, enemy wave spawns,
## reinforcement logic, watchdog stuck recovery, and exit barrier unlocking.

signal encounter_started(encounter_id: String, objective_text: String)
signal encounter_completed(encounter_id: String, score_reward: int)
signal route_cleared()

const AIArchetypesScript = preload("res://games/strike-vector/ai/ai_archetypes.gd")
const SquadCoordinatorScript = preload("res://games/strike-vector/ai/squad_coordinator.gd")

@export var encounter_id: String = "enc_plaza"
@export var objective_text: String = "ELIMINATE PATROL & SECURE PLAZA"
@export var score_reward: int = 1000
@export var enemy_spawns: Array = [] # [{ "archetype": "rifle_trooper", "pos": Vector3(...) }]
@export var reinforcement_waves: Array = []

var is_active: bool = false
var is_completed: bool = false
var active_enemies: Array = []
var exit_barriers: Array = []
var watchdog_timer: float = 0.0
const WATCHDOG_MAX_TIME: float = 28.0

var squad_coord: Node = null

func _init() -> void:
	squad_coord = SquadCoordinatorScript.new()
	squad_coord.name = "SquadCoordinator"
	add_child(squad_coord)

func _ready() -> void:
	if squad_coord == null:
		squad_coord = SquadCoordinatorScript.new()
		squad_coord.name = "SquadCoordinator"
		add_child(squad_coord)

func add_exit_barrier(barrier: Node3D) -> void:
	exit_barriers.append(barrier)
	barrier.visible = false
	if barrier is CollisionObject3D:
		barrier.set_collision_layer_value(1, false)

func trigger_encounter() -> void:
	if is_active or is_completed:
		return
	is_active = true
	watchdog_timer = 0.0

	# Lock exit barriers
	_set_barriers_locked(true)

	encounter_started.emit(encounter_id, objective_text)

	# Spawn initial wave
	_spawn_initial_wave()

	# Audio combat escalation
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("countdown_tick", 1.0)

func _spawn_initial_wave() -> void:
	if squad_coord == null:
		squad_coord = SquadCoordinatorScript.new()
		squad_coord.name = "SquadCoordinator"
		add_child(squad_coord)

	for spawn_info in enemy_spawns:
		var arch = spawn_info.get("archetype", "rifle_trooper")
		var pos = spawn_info.get("pos", global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
		var enemy = AIArchetypesScript.create_enemy(arch)
		enemy.position = pos
		add_child(enemy)
		active_enemies.append(enemy)
		squad_coord.register_member(enemy)
		enemy.died.connect(func(_type, _score): _on_enemy_defeated(enemy))

func _on_enemy_defeated(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if is_instance_valid(squad_coord):
		squad_coord.unregister_member(enemy)

	if active_enemies.is_empty():
		if not reinforcement_waves.is_empty():
			_spawn_next_reinforcement_wave()
		else:
			complete_encounter()

func _spawn_next_reinforcement_wave() -> void:
	var next_wave = reinforcement_waves.pop_front()
	for spawn_info in next_wave:
		var arch = spawn_info.get("archetype", "combat_drone")
		var pos = spawn_info.get("pos", global_position + Vector3(0, 1.5, -6.0))
		var enemy = AIArchetypesScript.create_enemy(arch)
		enemy.position = pos
		add_child(enemy)
		active_enemies.append(enemy)
		squad_coord.register_member(enemy)
		enemy.died.connect(func(_type, _score): _on_enemy_defeated(enemy))

func complete_encounter() -> void:
	if is_completed:
		return
	is_active = false
	is_completed = true

	# Unlock exit barriers
	_set_barriers_locked(false)

	encounter_completed.emit(encounter_id, score_reward)
	route_cleared.emit()

	# Route Clear audio chime
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("goal", 1.0)

func _set_barriers_locked(locked: bool) -> void:
	for barrier in exit_barriers:
		if is_instance_valid(barrier):
			barrier.visible = locked
			if barrier is CollisionObject3D:
				barrier.set_collision_layer_value(1, locked)

func _process(delta: float) -> void:
	if not is_active:
		return

	watchdog_timer += delta
	# Deterministic Watchdog Recovery: if only 1 or 2 enemies remain and encounter duration exceeds watchdog threshold,
	# eliminate or auto-resolve stuck enemies to ensure the player's forward progression is never halted.
	if watchdog_timer >= WATCHDOG_MAX_TIME and not active_enemies.is_empty():
		var stuck_enemy = active_enemies[0]
		if is_instance_valid(stuck_enemy) and stuck_enemy.has_method("take_damage"):
			stuck_enemy.take_damage(999.0, "WatchdogRecovery", "System")
		watchdog_timer = 0.0
