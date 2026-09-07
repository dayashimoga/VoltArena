class_name InventorySystem
extends Node

## Reusable Inventory, Equipment, & Collectible Subsystem for VoltArena
## Handles item stacks, equipment unlocks, currency/shards, and serialization.

signal item_added(item_id: String, count: int, total: int)
signal item_removed(item_id: String, count: int, total: int)
signal equipment_unlocked(slot: String, equip_id: String)
signal inventory_changed()

var _items: Dictionary = {} # item_id -> int
var _unlocked_equipment: Dictionary = {} # slot -> Array of equip_id
var _equipped: Dictionary = {} # slot -> equip_id
var _metadata: Dictionary = {} # item_id -> Dictionary

func add_item(item_id: String, count: int = 1, meta: Dictionary = {}) -> bool:
	if count <= 0:
		return false
	var prev = _items.get(item_id, 0)
	var new_total = prev + count
	_items[item_id] = new_total
	if not meta.is_empty():
		_metadata[item_id] = meta

	item_added.emit(item_id, count, new_total)
	inventory_changed.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	if count <= 0 or not has_item(item_id, count):
		return false
	var prev = _items[item_id]
	var new_total = prev - count
	if new_total <= 0:
		_items.erase(item_id)
		_metadata.erase(item_id)
	else:
		_items[item_id] = new_total

	item_removed.emit(item_id, count, new_total)
	inventory_changed.emit()
	return true

func has_item(item_id: String, count: int = 1) -> bool:
	return _items.get(item_id, 0) >= count

func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

func get_all_items() -> Dictionary:
	return _items.duplicate()

func unlock_equipment(slot: String, equip_id: String) -> void:
	if not _unlocked_equipment.has(slot):
		_unlocked_equipment[slot] = []
	var arr: Array = _unlocked_equipment[slot]
	if not arr.has(equip_id):
		arr.append(equip_id)
		equipment_unlocked.emit(slot, equip_id)
		# Auto-equip if slot is empty
		if not _equipped.has(slot) or _equipped[slot] == "":
			equip(slot, equip_id)

func is_equipment_unlocked(slot: String, equip_id: String) -> bool:
	if _unlocked_equipment.has(slot):
		var arr: Array = _unlocked_equipment[slot]
		return arr.has(equip_id)
	return false

func equip(slot: String, equip_id: String) -> bool:
	if is_equipment_unlocked(slot, equip_id):
		_equipped[slot] = equip_id
		inventory_changed.emit()
		return true
	return false

func get_equipped(slot: String) -> String:
	return _equipped.get(slot, "")

func serialize_save_data() -> Dictionary:
	return {
		"items": _items.duplicate(),
		"unlocked_equipment": _unlocked_equipment.duplicate(),
		"equipped": _equipped.duplicate()
	}

func deserialize_save_data(data: Dictionary) -> void:
	_items = data.get("items", {}).duplicate()
	_unlocked_equipment = data.get("unlocked_equipment", {}).duplicate()
	_equipped = data.get("equipped", {}).duplicate()
	inventory_changed.emit()
