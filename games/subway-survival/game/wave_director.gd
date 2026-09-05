class_name WaveDirector
extends Node

const SubwayCrawlerScript = preload("res://games/subway-survival/enemies/crawler.gd")
const SubwayStalkerScript = preload("res://games/subway-survival/enemies/stalker.gd")
const SubwayBruteScript = preload("res://games/subway-survival/enemies/brute.gd")
const SubwaySpitterScript = preload("res://games/subway-survival/enemies/spitter.gd")
const BioColossusScript = preload("res://games/subway-survival/enemies/bio_colossus.gd")

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
	state_timer = 0.5 # Fast preparation time

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

	var total_initial_threats = enemies_to_spawn.size()
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.wave_started.emit(current_wave, total_initial_threats)
		var wave_msg = "SURVIVE — %d HOSTILES INCOMING!" % total_initial_threats
		if current_wave == 10:
			wave_msg = "WARNING: BIOGIGAS COLOSSUS DETECTED! FINAL WAVE!"
		elif current_wave == 5:
			wave_msg = "ALERT: ENRAGED MINIBOSSES INCOMING!"
		bus.show_toast_requested.emit(wave_msg, Color(1.0, 0.25, 0.25))

	wave_started.emit(current_wave, total_initial_threats)

	# Immediately spawn vanguard enemies so threats are visibly on screen right away
	if not enemies_to_spawn.is_empty():
		spawn_enemy(enemies_to_spawn.pop_front())
	if not enemies_to_spawn.is_empty():
		spawn_enemy(enemies_to_spawn.pop_front())
	spawn_cooldown = 0.8

func build_wave_composition(wave_num: int) -> void:
	enemies_to_spawn.clear()
	if wave_num == 10:
		# Final Boss Wave: Bio-Colossus + Escorts
		enemies_to_spawn.append("boss")
		for i in range(4):
			enemies_to_spawn.append("spitter")
		for i in range(6):
			enemies_to_spawn.append("crawler")
		return

	if wave_num == 5:
		# Miniboss Wave: Twin Enraged Brutes + Spitters
		enemies_to_spawn.append("brute")
		enemies_to_spawn.append("brute")
		for i in range(3):
			enemies_to_spawn.append("spitter")
		for i in range(8):
			enemies_to_spawn.append("crawler")
		return

	# Standard Escalating Waves (1-4, 6-9)
	var crawler_count = 5 + wave_num * 2
	for i in range(crawler_count):
		enemies_to_spawn.append("crawler")

	if wave_num >= 2:
		var stalker_count = wave_num
		for i in range(stalker_count):
			enemies_to_spawn.append("stalker")

	if wave_num >= 4:
		var spitter_count = wave_num - 2
		for i in range(spitter_count):
			enemies_to_spawn.append("spitter")

	if wave_num >= 3:
		var brute_count = 1 if wave_num < 6 else (wave_num - 4)
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
			enemy = SubwayCrawlerScript.new()
		"stalker":
			enemy = SubwayStalkerScript.new()
		"brute":
			enemy = SubwayBruteScript.new()
		"spitter":
			enemy = SubwaySpitterScript.new()
		"boss":
			enemy = BioColossusScript.new()

	if not enemy:
		return

	var sp = spawn_positions.pick_random()
	if type == "boss":
		sp = Vector3(0.0, -1.0, 110.0) # Spawn in Zone 3 Hive Arena
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
	var bonus = current_wave * 250
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.wave_completed.emit(current_wave, bonus)
		bus.show_toast_requested.emit("WAVE %d SURVIVED! +%d PTS" % [current_wave, bonus], Color(0.0, 1.0, 0.5))

	wave_completed.emit(current_wave, bonus)

	if current_wave >= max_waves:
		if bus:
			bus.show_toast_requested.emit("ALL 10 WAVES DEFEATED — REACH EXTRACTION TRAIN!", Color(0.1, 1.0, 0.8))
		all_waves_defeated.emit()
		return

	current_state = WaveState.INTERMISSION
	state_timer = intermission_duration

	if current_wave == 3 and bus:
		bus.show_toast_requested.emit("SECTOR 2 (MAINTENANCE BAY) UNLOCKED! SUPPLY CRATE ARRIVED!", Color(0.2, 0.85, 1.0))
	elif current_wave == 7 and bus:
		bus.show_toast_requested.emit("SECTOR 3 (HIGHLINE JUNCTION) UNLOCKED! UPGRADE TERMINAL READY!", Color(1.0, 0.85, 0.2))

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
