class_name CampaignManager
extends Node

## Oversees the 8-mission campaign sequence, mission unlocks, and overall progression in Strike Vector.

signal campaign_completed(total_score: int, best_grades: Dictionary)
signal mission_selected(mission_index: int)

const TOTAL_MISSIONS: int = 8

var current_mission_index: int = 1
var highest_unlocked_mission: int = 1
var campaign_score: int = 0
var mission_grades: Dictionary = {}

func _ready() -> void:
	load_campaign_state()

func load_campaign_state() -> void:
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm and sm.has_method("get_strike_vector_stats"):
		var stats = sm.get_strike_vector_stats()
		highest_unlocked_mission = stats.get("highest_mission", 1)
		campaign_score = stats.get("total_score", 0)
		mission_grades = stats.get("best_grades", {})

func start_mission(m_idx: int) -> void:
	current_mission_index = clampi(m_idx, 1, TOTAL_MISSIONS)
	mission_selected.emit(current_mission_index)

func on_mission_completed(m_idx: int, results: Dictionary) -> void:
	var score = results.get("score", 0)
	var grade = results.get("grade", "C")
	campaign_score += score
	mission_grades[str(m_idx)] = grade

	if m_idx >= highest_unlocked_mission and m_idx < TOTAL_MISSIONS:
		highest_unlocked_mission = m_idx + 1

	if m_idx == TOTAL_MISSIONS:
		campaign_completed.emit(campaign_score, mission_grades)
	else:
		current_mission_index = m_idx + 1

func get_next_mission_index() -> int:
	return mini(TOTAL_MISSIONS, current_mission_index + 1)
