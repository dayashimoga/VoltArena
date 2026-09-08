class_name MissionManager
extends Node

## Manages active mission runtime, objectives, timer, scoring, and end-of-mission grading in Strike Vector.

signal mission_started(mission_index: int, mission_name: String)
signal objective_updated(objective_text: String, current_step: int, total_steps: int)
signal mission_completed(mission_index: int, results: Dictionary)
signal mission_failed(reason: String)

const CheckpointManagerScript = preload("res://games/strike-vector/campaign/checkpoint_manager.gd")

@export var mission_index: int = 1
@export var mission_name: String = "Urban Blackout"
@export var biome: String = "urban"

var mission_streamer: Node3D = null
var checkpoint_mgr: Node = null

var elapsed_time: float = 0.0
var total_kills: int = 0
var total_deaths: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var mission_score: int = 0
var is_active: bool = false
var is_completed: bool = false

func _init() -> void:
	checkpoint_mgr = CheckpointManagerScript.new()
	checkpoint_mgr.name = "CheckpointManager"
	add_child(checkpoint_mgr)

func _ready() -> void:
	if checkpoint_mgr == null:
		checkpoint_mgr = CheckpointManagerScript.new()
		checkpoint_mgr.name = "CheckpointManager"
		add_child(checkpoint_mgr)

func start_mission(m_idx: int, m_name: String, streamer: Node3D) -> void:
	mission_index = m_idx
	mission_name = m_name
	mission_streamer = streamer
	elapsed_time = 0.0
	total_kills = 0
	total_deaths = 0
	mission_score = 0
	is_active = true
	is_completed = false

	mission_started.emit(mission_index, mission_name)

func _process(delta: float) -> void:
	if is_active and not is_completed:
		elapsed_time += delta

func record_kill(score_val: int) -> void:
	total_kills += 1
	mission_score += score_val

func record_death() -> void:
	total_deaths += 1

func complete_mission() -> void:
	if is_completed:
		return
	is_completed = true
	is_active = false

	var grade = calculate_grade()
	var results = {
		"mission_index": mission_index,
		"mission_name": mission_name,
		"score": mission_score,
		"time": elapsed_time,
		"kills": total_kills,
		"deaths": total_deaths,
		"grade": grade
	}

	# Persist via SaveManager
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm and sm.has_method("record_strike_vector_mission"):
		sm.record_strike_vector_mission(mission_index, mission_score, grade, true)

	mission_completed.emit(mission_index, results)

func calculate_grade() -> String:
	if total_deaths == 0 and mission_score >= 12000 and elapsed_time <= 240.0:
		return "S"
	elif total_deaths <= 1 and mission_score >= 8000:
		return "A"
	elif total_deaths <= 3:
		return "B"
	else:
		return "C"
