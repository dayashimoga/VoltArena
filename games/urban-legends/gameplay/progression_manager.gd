class_name ProgressionManager
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanSaveData = preload("res://games/urban-legends/core/urban_save_data.gd")
const UrbanVehicleCatalog = preload("res://games/urban-legends/vehicles/urban_vehicle_catalog.gd")

## Career progression, garage inventory, and vehicle upgrade manager for Urban Legends.
## Governs wallet cash, upgrade purchasing (Levels 1-5), vehicle unlocking, and achievements.

signal cash_balance_changed(new_balance: int, delta: int)
signal vehicle_unlocked_event(vehicle_id: String)
signal upgrade_purchased(vehicle_id: String, category: String, new_level: int)
signal achievement_unlocked(achievement_id: String, title: String)

var save_data: UrbanSaveData = null

const UPGRADE_BASE_COSTS: Dictionary = {
	"engine": 1200,
	"tires": 900,
	"nitro": 1500,
	"suspension": 800,
	"armor": 1000
}

const ACHIEVEMENTS: Dictionary = {
	"first_burnout": {"title": "First Burnout", "desc": "Perform your first power drift"},
	"crest_aviator": {"title": "Crest Aviator", "desc": "Launch off the Colinas crest ramp"},
	"millionaire": {"title": "Apex Tycoon", "desc": "Accumulate $25,000 career cash"},
	"fleet_master": {"title": "Fleet Master", "desc": "Unlock all 5 vehicle archetypes"},
	"cartographer": {"title": "Master Cartographer", "desc": "Discover all 8 open-world districts"}
}

func _init(save: UrbanSaveData = null) -> void:
	if save:
		save_data = save
	else:
		save_data = UrbanSaveData.new()

func get_cash() -> int:
	return save_data.career_cash if save_data else 0

func add_cash(amount: int) -> void:
	if save_data and amount > 0:
		save_data.add_cash(amount)
		cash_balance_changed.emit(save_data.career_cash, amount)

		if save_data.career_cash >= 25000:
			unlock_achievement("millionaire")

func can_afford(amount: int) -> bool:
	return get_cash() >= amount

func spend_cash(amount: int) -> bool:
	if not can_afford(amount) or not save_data:
		return false
	save_data.career_cash -= amount
	cash_balance_changed.emit(save_data.career_cash, -amount)
	return true

func is_vehicle_unlocked(vehicle_id: String) -> bool:
	return save_data.is_vehicle_unlocked(vehicle_id) if save_data else false

func unlock_vehicle(vehicle_id: String) -> bool:
	if not save_data:
		return false
	if is_vehicle_unlocked(vehicle_id):
		return true

	var def = UrbanVehicleCatalog.get_vehicle_def(vehicle_id)
	var price = def.get("price", 0)

	if price > 0 and not spend_cash(price):
		return false

	save_data.unlock_vehicle(vehicle_id)
	vehicle_unlocked_event.emit(vehicle_id)

	# Check if all unlocked
	var all_unlocked = true
	for v_id in UrbanVehicleCatalog.get_vehicle_ids():
		if not is_vehicle_unlocked(v_id):
			all_unlocked = false
			break
	if all_unlocked:
		unlock_achievement("fleet_master")

	return true

func get_upgrade_cost(category_or_lvl, opt_lvl: int = -1) -> int:
	var category: String = "engine"
	var current_level: int = 1
	if category_or_lvl is String:
		category = category_or_lvl
		current_level = opt_lvl if opt_lvl >= 0 else 1
	elif category_or_lvl is int or category_or_lvl is float:
		current_level = int(category_or_lvl)
	var base = UPGRADE_BASE_COSTS.get(category, 1000)
	return int(base * (1.0 + float(current_level) * 0.65))

func buy_upgrade(vehicle_id: String, category: String) -> bool:
	if not save_data:
		return false

	var curr_lvl = save_data.get_upgrade_level(vehicle_id, category)
	if curr_lvl >= 5:
		return false # Already maxed

	var cost = get_upgrade_cost(category, curr_lvl)
	if not spend_cash(cost):
		return false

	save_data.set_upgrade_level(vehicle_id, category, curr_lvl + 1)
	upgrade_purchased.emit(vehicle_id, category, curr_lvl + 1)
	return true

func unlock_achievement(achievement_id: String) -> void:
	if not save_data:
		return
	if not save_data.achievements_unlocked.has(achievement_id):
		save_data.achievements_unlocked.append(achievement_id)
		var meta = ACHIEVEMENTS.get(achievement_id, {"title": achievement_id})
		achievement_unlocked.emit(achievement_id, meta["title"])

func register_district_discovery(district_id: String) -> void:
	if not save_data:
		return
	save_data.discover_district(district_id)
	if save_data.districts_discovered.size() >= 8:
		unlock_achievement("cartographer")
