class_name TestInventorySystem
extends RefCounted

## Unit tests for InventorySystem (shared/gameplay/inventory_system.gd)

const InventorySystemScript = preload("res://shared/gameplay/inventory_system.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_add_and_remove_items()
	test_equipment_slots()
	test_serialization()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/gameplay/inventory_system.gd",
		[
			"add_item", "remove_item", "has_item", "get_item_count",
			"get_all_items", "unlock_equipment", "is_equipment_unlocked",
			"equip", "get_equipped", "serialize_save_data", "deserialize_save_data"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit InventorySystem FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_add_and_remove_items() -> void:
	var inv = InventorySystemScript.new()
	var added = inv.add_item("ancient_key", 1)
	assert_true(added, "Should add item successfully")
	assert_true(inv.has_item("ancient_key", 1), "Should have item in inventory")
	assert_eq(inv.get_item_count("ancient_key"), 1, "Count should be 1")

	var removed = inv.remove_item("ancient_key", 1)
	assert_true(removed, "Should remove item successfully")
	assert_eq(inv.get_item_count("ancient_key"), 0, "Count should be 0")
	assert_true(not inv.has_item("ancient_key"), "Should not have item anymore")
	inv.queue_free()

func test_equipment_slots() -> void:
	var inv = InventorySystemScript.new()
	inv.unlock_equipment("back", "glider_wings")
	assert_true(inv.is_equipment_unlocked("back", "glider_wings"), "Equipment should be unlocked")
	assert_eq(inv.get_equipped("back"), "glider_wings", "Should auto-equip into empty slot")

	inv.unlock_equipment("back", "cape_of_wind")
	assert_true(inv.is_equipment_unlocked("back", "cape_of_wind"), "Second equipment unlocked")

	var equipped = inv.equip("back", "cape_of_wind")
	assert_true(equipped, "Should switch equipped item")
	assert_eq(inv.get_equipped("back"), "cape_of_wind", "Active equipment should now be cape_of_wind")
	inv.queue_free()

func test_serialization() -> void:
	var inv = InventorySystemScript.new()
	inv.add_item("sky_shard", 15)
	inv.unlock_equipment("head", "scout_visor")

	var serialized = inv.serialize_save_data()
	assert_true(serialized.has("items"), "Serialized data should include items")
	assert_true(serialized.has("unlocked_equipment"), "Serialized data should include unlocked_equipment")

	var inv2 = InventorySystemScript.new()
	inv2.deserialize_save_data(serialized)
	assert_true(inv2.is_equipment_unlocked("head", "scout_visor"), "Restored equipment should be unlocked")
	assert_eq(inv2.get_item_count("sky_shard"), 15, "Restored item count should match")
	inv.queue_free()
	inv2.queue_free()
