class_name RaceManager
extends Node

signal countdown_tick(count: int)
signal race_started()
signal race_finished(winner_kart: Node)

enum RaceState {
	COUNTDOWN,
	RACING,
	FINISHED
}

@export var total_laps: int = 3

var current_state: RaceState = RaceState.COUNTDOWN
var countdown_timer: float = 3.9
var race_time: float = 0.0
var racers: Array = []
var checkpoints: Array = []

func _ready() -> void:
	pass

func initialize_race(all_racers: Array, all_checkpoints: Array) -> void:
	racers = all_racers
	checkpoints = all_checkpoints

	for cp in checkpoints:
		if not cp.checkpoint_hit.is_connected(_on_checkpoint_hit):
			cp.checkpoint_hit.connect(_on_checkpoint_hit)

	current_state = RaceState.COUNTDOWN
	countdown_timer = 5.0
	countdown_tick.emit(5)
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("countdown_tick", 1.0)

func _process(delta: float) -> void:
	match current_state:
		RaceState.COUNTDOWN:
			var prev_count = int(ceil(countdown_timer))
			countdown_timer -= delta
			var new_count = int(ceil(countdown_timer))
			if new_count != prev_count:
				if new_count > 0:
					countdown_tick.emit(new_count)
					var am = GameConstants.get_autoload(self, "AudioManager")
					if am:
						am.play_sound("countdown_tick", 1.0)
					var bus = GameConstants.get_autoload(self, "EventBus")
					if bus:
						bus.show_toast_requested.emit(str(new_count), Color(1.0, 0.8, 0.0))
				elif new_count <= 0:
					start_race()
		RaceState.RACING:
			race_time += delta
			update_race_positions()

func start_race() -> void:
	current_state = RaceState.RACING
	race_started.emit()
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("countdown_go", 1.2)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("GO!", Color(0.0, 1.0, 0.5))

func _on_checkpoint_hit(kart: Node, cp_index: int) -> void:
	if current_state != RaceState.RACING or (kart and kart.race_finished):
		return

	# Sequential checkpoint validation
	var cp_count = checkpoints.size() if not checkpoints.is_empty() else 1
	var expected_cp = kart.next_checkpoint_index
	if cp_index == expected_cp:
		kart.next_checkpoint_index = (expected_cp + 1) % cp_count
		kart.total_checkpoints_hit += 1
		if cp_index < checkpoints.size():
			kart.last_valid_checkpoint_pos = checkpoints[cp_index].global_position
			kart.last_valid_checkpoint_rot = checkpoints[cp_index].rotation.y

		# Lap complete when wrapping to 0
		if kart.next_checkpoint_index == 0:
			var lap_time = race_time - kart.lap_start_time
			kart.lap_start_time = race_time
			if lap_time < kart.best_lap_time:
				kart.best_lap_time = lap_time
			kart.current_lap += 1

			var bus = GameConstants.get_autoload(self, "EventBus")
			if bus and kart.is_player:
				bus.show_toast_requested.emit("LAP %d / %d" % [min(kart.current_lap, total_laps), total_laps], Color(0.0, 1.0, 1.0))

			if kart.current_lap > total_laps:
				kart.race_finished = true
				if kart.is_player:
					finish_race(kart)

func on_kart_hit_checkpoint(kart: Node, checkpoint_idx: int) -> void:
	_on_checkpoint_hit(kart, checkpoint_idx)

func update_race_positions() -> void:
	# Sort racers by total progress score
	racers.sort_custom(func(a, b):
		return a.total_checkpoints_hit > b.total_checkpoints_hit
	)
	var bus = GameConstants.get_autoload(self, "EventBus")
	for i in range(racers.size()):
		var r = racers[i]
		if r.is_player and bus:
			bus.race_position_updated.emit(r.racer_id, i + 1, racers.size())

func finish_race(winner: Node) -> void:
	current_state = RaceState.FINISHED
	race_finished.emit(winner)
