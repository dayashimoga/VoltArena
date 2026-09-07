class_name QuestManager
extends Node

## Reusable Quest & Objective Management Subsystem for VoltArena
## Supports data-driven multi-stage quests, objectives, prerequisites, rewards,
## and complete state persistence.

enum QuestStatus {
	LOCKED = 0,
	AVAILABLE = 1,
	ACTIVE = 2,
	COMPLETED = 3,
	FAILED = 4
}

signal quest_added(quest_id: String)
signal quest_started(quest_id: String)
signal objective_updated(quest_id: String, obj_id: String, current: int, required: int)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_failed(quest_id: String)

class Objective:
	var id: String = ""
	var description: String = ""
	var required_count: int = 1
	var current_count: int = 0
	var is_completed: bool = false
	var target_tag: String = "" # e.g. "shard", "photo", "switch"

	func _init(p_id: String, p_desc: String, p_req: int = 1, p_tag: String = "") -> void:
		id = p_id
		description = p_desc
		required_count = p_req
		current_count = 0
		is_completed = false
		target_tag = p_tag

	func advance(amount: int = 1) -> bool:
		if is_completed:
			return true
		current_count = mini(required_count, current_count + amount)
		if current_count >= required_count:
			is_completed = true
		return is_completed

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"description": description,
			"required_count": required_count,
			"current_count": current_count,
			"is_completed": is_completed,
			"target_tag": target_tag
		}

	static func from_dict(d: Dictionary) -> Objective:
		var obj = Objective.new(d.get("id", ""), d.get("description", ""), d.get("required_count", 1), d.get("target_tag", ""))
		obj.current_count = d.get("current_count", 0)
		obj.is_completed = d.get("is_completed", false)
		return obj

class Quest:
	var id: String = ""
	var title: String = ""
	var description: String = ""
	var status: int = QuestStatus.LOCKED
	var prerequisites: Array = []
	var objectives: Array = []
	var rewards: Dictionary = {} # e.g. {"shards": 5, "unlock": "glider"}

	func is_all_objectives_complete() -> bool:
		for obj in objectives:
			if not obj.is_completed:
				return false
		return true

	func to_dict() -> Dictionary:
		var objs_arr = []
		for o in objectives:
			objs_arr.append(o.to_dict())
		return {
			"id": id,
			"title": title,
			"description": description,
			"status": status,
			"prerequisites": prerequisites,
			"rewards": rewards,
			"objectives": objs_arr
		}

	static func from_dict(d: Dictionary) -> Quest:
		var q = Quest.new()
		q.id = d.get("id", "")
		q.title = d.get("title", "")
		q.description = d.get("description", "")
		q.status = d.get("status", QuestStatus.LOCKED)
		q.prerequisites = d.get("prerequisites", [])
		q.rewards = d.get("rewards", {})
		q.objectives = []
		for obj_data in d.get("objectives", []):
			q.objectives.append(Objective.from_dict(obj_data))
		return q

var _quests: Dictionary = {} # id -> Quest

func register_quest(quest: Quest) -> void:
	_quests[quest.id] = quest
	_evaluate_availability()
	quest_added.emit(quest.id)

func create_and_register_quest(p_id: String, p_title: String, p_desc: String, p_objectives: Array, p_rewards: Dictionary = {}, p_prereqs: Array = []) -> Quest:
	var q = Quest.new()
	q.id = p_id
	q.title = p_title
	q.description = p_desc
	q.rewards = p_rewards
	q.prerequisites = []
	for pr in p_prereqs:
		q.prerequisites.append(str(pr))
	q.status = QuestStatus.LOCKED
	for o in p_objectives:
		if o is Objective:
			q.objectives.append(o)
		elif o is Dictionary:
			q.objectives.append(Objective.from_dict(o))
	register_quest(q)
	return q

func start_quest(quest_id: String) -> bool:
	if not _quests.has(quest_id):
		return false
	var q: Quest = _quests[quest_id]
	for prereq in q.prerequisites:
		if not is_quest_completed(prereq):
			return false
	q.status = QuestStatus.ACTIVE
	quest_started.emit(quest_id)
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("NEW QUEST: " + q.title, Color(0.2, 0.9, 1.0))
	return true

func advance_objective(quest_id: String, obj_id: String, amount: int = 1) -> bool:
	if not _quests.has(quest_id):
		return false
	var q: Quest = _quests[quest_id]
	if q.status != QuestStatus.ACTIVE:
		return false

	var found = false
	for obj in q.objectives:
		if obj.id == obj_id or obj.target_tag == obj_id:
			var just_finished = obj.advance(amount)
			objective_updated.emit(quest_id, obj.id, obj.current_count, obj.required_count)
			found = true
			if just_finished and q.is_all_objectives_complete():
				complete_quest(quest_id)
			break
	return found

func complete_quest(quest_id: String) -> void:
	if not _quests.has(quest_id):
		return
	var q: Quest = _quests[quest_id]
	if q.status == QuestStatus.COMPLETED:
		return
	q.status = QuestStatus.COMPLETED
	_evaluate_availability()
	quest_completed.emit(quest_id, q.rewards)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.show_toast_requested.emit("QUEST COMPLETE: " + q.title, Color(0.2, 1.0, 0.4))
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("pickup_ammo", 1.2, 1.5)

func fail_quest(quest_id: String) -> void:
	if not _quests.has(quest_id):
		return
	var q: Quest = _quests[quest_id]
	q.status = QuestStatus.FAILED
	quest_failed.emit(quest_id)

func get_quest(quest_id: String) -> Quest:
	return _quests.get(quest_id, null)

func get_active_quests() -> Array[Quest]:
	var result: Array[Quest] = []
	for q in _quests.values():
		if q.status == QuestStatus.ACTIVE:
			result.append(q)
	return result

func get_completed_quests() -> Array[Quest]:
	var result: Array[Quest] = []
	for q in _quests.values():
		if q.status == QuestStatus.COMPLETED:
			result.append(q)
	return result

func is_quest_completed(quest_id: String) -> bool:
	var q = _quests.get(quest_id, null)
	return q != null and q.status == QuestStatus.COMPLETED

func _evaluate_availability() -> void:
	for q in _quests.values():
		if q.status == QuestStatus.LOCKED:
			var all_prereqs_met = true
			for prereq in q.prerequisites:
				if not is_quest_completed(prereq):
					all_prereqs_met = false
					break
			if all_prereqs_met:
				q.status = QuestStatus.AVAILABLE

func serialize_save_data() -> Dictionary:
	var out = {}
	for k in _quests.keys():
		out[k] = _quests[k].to_dict()
	return out

func deserialize_save_data(data: Dictionary) -> void:
	for k in data.keys():
		_quests[k] = Quest.from_dict(data[k])
	_evaluate_availability()
