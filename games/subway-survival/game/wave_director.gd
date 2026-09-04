class_name WaveDirector
extends Node

signal wave_started(wave_num: int, total_enemies: int)
signal wave_completed(wave_num: int, score_bonus: int)
signal all_waves_defeated()

enum WaveState {
	INTERMISSION,
	IN_PROGRESS,
	COMPLETED
}

@export var max_waves: int = 10
@export var intermission_duration: float = 6.0

var current_wave: int = 0
var current_state: WaveState = WaveState.INTERMISSION
var state_timer: float = 0.0

var enemies_to_spawn: Array[String] = []
var active_enemies: Array[EnemyBase] = []
var spawn_cooldown: float = 0.0

# Spawn point coordinates along the subway tunnel ends
var spawn_positions = [
	Vector3(6.0, -1.0, -26.0),
	Vector3(4.0, -1.0, -26.0),
	Vector3(7.5, -1.0, -26.0),
	Vector3(6.0, -1.0, 26.0),
	Vector3(4.0, -1.0, 26.0),
	Vector3(7.5, -1.0, 26.0)
]

func _ready() -> void:
	state_timer = 3.0 # Initial preparation time

func _process(delta: float) -> void:
	match current_state:
		WaveState.INTERMISSION:
			state_timer -= delta
			if state_timer <= 0.0:
				start_next_wave()
		WaveState.IN_PROGRESS:
			process_spawning(delta)
			clean_dead_enemies()
			if enemies_to_spawn.is_empty() and active_enemies.is_empty():
				finish_current_wave()

func start_next_wave() -> void:
	current_wave += 1
	current_state = WaveState.IN_PROGRESS
	build_wave_composition(current_wave)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.wave_started.emit(current_wave, enemies_to_spawn.size())
		bus.show_toast_requested.emit("WAVE %d INCOMING!" % current_wave, Color(1.0, 0.2, 0.2))

	wave_started.emit(current_wave, enemies_to_spawn.size())

func build_wave_composition(wave_num: int) -> void:
	enemies_to_spawn.clear()
	# Base crawlers
	var crawler_count = 5 + wave_num * 2
	for i in range(crawler_count):
		enemies_to_spawn.append("crawler")

	# Stalkers enter on wave 2+
	if wave_num >= 2:
		var stalker_count = wave_num + 1
		for i in range(stalker_count):
			enemies_to_spawn.append("stalker")

	# Brutes enter on wave 3+
	if wave_num >= 3:
		var brute_count = (wave_num - 2)
		for i in range(brute_count):
			enemies_to_spawn.append("brute")

	enemies_to_spawn.shuffle()

func process_spawning(delta: float) -> void:
	if enemies_to_spawn.is_empty():
		return

	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		var enemy_type = enemies_to_spawn.pop_front()
		spawn_enemy(enemy_type)
		spawn_cooldown = randf_range(0.8, 1.8)

func spawn_enemy(type: String) -> void:
	var enemy: EnemyBase = null
	match type:
		"crawler":
			enemy = SubwayCrawler.new()
		"stalker":
			enemy = SubwayStalker.new()
		"brute":
			enemy = SubwayBrute.new()

	if not enemy:
		return

	var sp = spawn_positions.pick_random()
	enemy.position = sp
	if get_parent():
		get_parent().add_child(enemy)
	active_enemies.append(enemy)

func clean_dead_enemies() -> void:
	var alive: Array[EnemyBase] = []
	for e in active_enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			alive.append(e)
	active_enemies = alive

func finish_current_wave() -> void:
	current_state = WaveState.INTERMISSION
	state_timer = intermission_duration

	var bonus = current_wave * 250
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.wave_completed.emit(current_wave, bonus)
		bus.show_toast_requested.emit("WAVE %d SURVIVED! +%d PTS" % [current_wave, bonus], Color(0.0, 1.0, 0.5))

	wave_completed.emit(current_wave, bonus)

	# Spawn intermission health & ammo drop on the platform
	var p_health = PickupBase.new()
	p_health.pickup_type = PickupBase.PickupType.HEALTH
	p_health.amount = 50
	p_health.position = Vector3(-5.0, 0.5, randf_range(-10, 10))

	var p_ammo = PickupBase.new()
	p_ammo.pickup_type = PickupBase.PickupType.AMMO
	p_ammo.amount = 100
	p_ammo.position = Vector3(-5.0, 0.5, randf_range(-10, 10))

	if get_parent():
		get_parent().add_child(p_health)
		get_parent().add_child(p_ammo)
	else:
		p_health.queue_free()
		p_ammo.queue_free()
