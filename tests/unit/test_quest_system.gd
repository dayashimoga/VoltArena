class_name TestQuestSystem
extends RefCounted

## Unit tests for QuestSystem (shared/gameplay/quest_system.gd)

const QuestManagerScript = preload("res://shared/gameplay/quest_system.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_quest_creation_and_registration()
	test_objective_advancement()
	test_quest_prerequisites()
	test_quest_completion_and_rewards()
	test_serialization()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/gameplay/quest_system.gd",
		[
			"register_quest", "create_and_register_quest", "start_quest",
			"advance_objective", "complete_quest", "fail_quest",
			"get_quest", "get_active_quests", "get_completed_quests",
			"is_quest_completed", "serialize_save_data", "deserialize_save_data",
			"advance", "to_dict", "from_dict", "is_all_objectives_complete"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit QuestSystem FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_quest_creation_and_registration() -> void:
	var qm = QuestManagerScript.new()
	var q = qm.create_and_register_quest("q_test_1", "Test Quest", "A quest to test", [])
	assert_true(q != null, "Created quest should not be null")
	assert_eq(q.id, "q_test_1", "Quest ID should match")
	assert_eq(qm.get_quest("q_test_1"), q, "get_quest should retrieve registered quest")
	qm.queue_free()

func test_objective_advancement() -> void:
	var qm = QuestManagerScript.new()
	var obj_data = [{"id": "gather_wood", "description": "Gather 5 wood", "required_count": 5}]
	var q = qm.create_and_register_quest("q_obj_1", "Gathering Quest", "Gather items", obj_data)

	qm.start_quest("q_obj_1")
	assert_true(q.status == 2, "Quest should be active (QuestStatus.ACTIVE = 2)")

	qm.advance_objective("q_obj_1", "gather_wood", 3)
	var obj = q.get_objective("gather_wood")
	assert_true(obj != null, "Objective should exist")
	assert_eq(obj.current_count, 3, "Current count should be 3")
	assert_true(not obj.is_completed, "Objective should not yet be complete")

	qm.advance_objective("q_obj_1", "gather_wood", 2)
	assert_eq(obj.current_count, 5, "Current count should be 5")
	assert_true(obj.is_completed, "Objective should now be complete")
	assert_true(q.status == 3, "Quest should auto-complete when all objectives done (COMPLETED = 3)")
	qm.queue_free()

func test_quest_prerequisites() -> void:
	var qm = QuestManagerScript.new()
	var obj1 = [{"id": "step1", "description": "Step 1", "required_count": 1}]
	var q1 = qm.create_and_register_quest("q_root", "Root Quest", "First quest", obj1)

	var obj2 = [{"id": "step2", "description": "Step 2", "required_count": 1}]
	var q2 = qm.create_and_register_quest("q_locked", "Locked Quest", "Second quest", obj2, {}, ["q_root"])

	# Try starting locked quest before root is completed
	var started_locked = qm.start_quest("q_locked")
	assert_true(not started_locked, "Should not be able to start quest without prerequisites met")

	# Complete root quest
	qm.start_quest("q_root")
	qm.advance_objective("q_root", "step1", 1)
	assert_true(q1.status == 3, "Root quest should be complete")

	# Now locked quest can start
	started_locked = qm.start_quest("q_locked")
	assert_true(started_locked, "Quest should start now that prerequisites are met")
	qm.queue_free()

func test_quest_completion_and_rewards() -> void:
	var qm = QuestManagerScript.new()
	var obj = [{"id": "task", "description": "Finish task", "required_count": 1}]
	var q = qm.create_and_register_quest("q_rewards", "Reward Quest", "Rewards test", obj, {"gold": 100, "xp": 500})

	qm.start_quest("q_rewards")
	qm.complete_quest("q_rewards")
	assert_true(q.status == 3, "Quest status should be completed")

	var completed = qm.get_completed_quests()
	assert_true(completed.size() > 0, "Completed quests array should not be empty")
	assert_true(qm.is_quest_completed("q_rewards"), "is_quest_completed should return true")
	qm.queue_free()

func test_serialization() -> void:
	var qm = QuestManagerScript.new()
	var obj = [{"id": "step", "description": "Step", "required_count": 10}]
	var q = qm.create_and_register_quest("q_save", "Save Quest", "Saving state", obj)
	qm.start_quest("q_save")
	qm.advance_objective("q_save", "step", 4)

	var saved_data = qm.serialize_save_data()
	assert_true(saved_data.has("q_save"), "Serialized data should have q_save entry")

	var qm2 = QuestManagerScript.new()
	qm2.deserialize_save_data(saved_data)

	var q_restored = qm2.get_quest("q_save")
	assert_true(q_restored != null, "Restored quest should exist")
	assert_eq(q_restored.get_objective("step").current_count, 4, "Restored objective progress should be 4")

	# Test direct Quest and Objective serialization and helper methods
	var raw_dict = q.to_dict()
	assert_true(raw_dict.has("id"), "Quest to_dict should contain id")
	assert_true(not q.is_all_objectives_complete(), "q should not be all complete yet")

	var single_obj = q.get_objective("step")
	assert_true(single_obj != null, "Objective step should exist")
	var obj_dict = single_obj.to_dict()
	var restored_obj = QuestManagerScript.Objective.from_dict(obj_dict)
	assert_eq(restored_obj.current_count, 4, "Objective restored count should match")
	restored_obj.advance(6)
	assert_true(restored_obj.is_completed, "Advancing objective to req should complete it")

	qm.queue_free()
	qm2.queue_free()
