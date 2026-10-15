class_name UrbanSaveData
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## Persistent user state and career progression serialization for Urban Legends.
## Saves and loads player wallet, garage inventory, customization, and district records.

const SAVE_KEY: String = "urban_legends_career"

var cash: int = 50000 # Starting wallet
var career_cash: int:
	get: return cash
	set(val): cash = val

var active_vehicle_id: String = UrbanConstants.VEHICLE_VORTEX_GT
var current_vehicle_id: String:
	get: return active_vehicle_id
	set(val): active_vehicle_id = val

var unlocked_vehicles: Array[String] = [UrbanConstants.VEHICLE_VORTEX_GT]
var discovered_districts: Array[String] = [UrbanConstants.DISTRICT_COLINAS]
var districts_discovered: Array[String]:
	get: return discovered_districts
	set(val): discovered_districts = val
var achievements_unlocked: Array[String] = []

# Vehicle upgrades: { "vehicle_id": { "engine": 1, "tires": 1, "nitro": 1, "suspension": 1, "armor": 1 } }
var vehicle_upgrades: Dictionary = {}

# Vehicle paints: { "vehicle_id": Color }
var vehicle_colors: Dictionary = {}

# Completed missions: { "mission_id": { "best_time": float, "best_score": int, "rank": String } }
var mission_records: Dictionary = {}

# Stunt records
var best_stunt_score: int = 0
var total_stunts_performed: int = 0
var max_air_time: float = 0.0
var max_jump_distance: float = 0.0

func _init() -> void:
	_init_defaults()

func _init_defaults() -> void:
	var default_vehicles = [
		UrbanConstants.VEHICLE_VORTEX_GT,
		UrbanConstants.VEHICLE_THUNDERBOLT_V8,
		UrbanConstants.VEHICLE_SPECTER_R,
		UrbanConstants.VEHICLE_RIDGEBACK_4X4,
		UrbanConstants.VEHICLE_VALIANT_COUPE
	]
	for v_id in default_vehicles:
		if not vehicle_upgrades.has(v_id):
			vehicle_upgrades[v_id] = {
				"engine": 1,
				"tires": 1,
				"nitro": 1,
				"suspension": 1,
				"armor": 1
			}
		if not vehicle_colors.has(v_id):
			if v_id == UrbanConstants.VEHICLE_VORTEX_GT:
				vehicle_colors[v_id] = Color(0.08, 0.45, 0.95) # Sleek blue like reference
			elif v_id == UrbanConstants.VEHICLE_THUNDERBOLT_V8:
				vehicle_colors[v_id] = Color(0.9, 0.15, 0.1) # Aggressive crimson
			elif v_id == UrbanConstants.VEHICLE_SPECTER_R:
				vehicle_colors[v_id] = Color(0.95, 0.85, 0.1) # Racing yellow
			elif v_id == UrbanConstants.VEHICLE_RIDGEBACK_4X4:
				vehicle_colors[v_id] = Color(0.2, 0.55, 0.25) # Forest green
			else:
				vehicle_colors[v_id] = Color(0.85, 0.85, 0.88) # Silver platinum

func to_dict() -> Dictionary:
	var colors_serialized: Dictionary = {}
	for k in vehicle_colors.keys():
		var col: Color = vehicle_colors[k]
		colors_serialized[k] = [col.r, col.g, col.b, col.a]

	return {
		"cash": cash,
		"active_vehicle_id": active_vehicle_id,
		"unlocked_vehicles": unlocked_vehicles,
		"discovered_districts": discovered_districts,
		"vehicle_upgrades": vehicle_upgrades,
		"vehicle_colors": colors_serialized,
		"mission_records": mission_records,
		"best_stunt_score": best_stunt_score,
		"total_stunts_performed": total_stunts_performed,
		"max_air_time": max_air_time,
		"max_jump_distance": max_jump_distance
	}

func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	cash = data.get("cash", 50000)
	active_vehicle_id = data.get("active_vehicle_id", UrbanConstants.VEHICLE_VORTEX_GT)
	unlocked_vehicles = Array(data.get("unlocked_vehicles", [UrbanConstants.VEHICLE_VORTEX_GT]))
	discovered_districts = Array(data.get("discovered_districts", [UrbanConstants.DISTRICT_COLINAS]))
	vehicle_upgrades = data.get("vehicle_upgrades", vehicle_upgrades)
	best_stunt_score = data.get("best_stunt_score", 0)
	total_stunts_performed = data.get("total_stunts_performed", 0)
	max_air_time = data.get("max_air_time", 0.0)
	max_jump_distance = data.get("max_jump_distance", 0.0)
	mission_records = data.get("mission_records", {})

	var colors_serialized = data.get("vehicle_colors", {})
	for k in colors_serialized.keys():
		var arr = colors_serialized[k]
		if arr is Array and arr.size() >= 3:
			vehicle_colors[k] = Color(arr[0], arr[1], arr[2], arr[3] if arr.size() > 3 else 1.0)

	_init_defaults()

func add_cash(amount: int) -> void:
	cash = maxi(0, cash + amount)

func unlock_vehicle(v_id: String) -> bool:
	if not unlocked_vehicles.has(v_id):
		unlocked_vehicles.append(v_id)
		return true
	return false

func is_vehicle_unlocked(v_id: String) -> bool:
	return unlocked_vehicles.has(v_id)

func get_upgrade_level(v_id: String, upgrade_type: String) -> int:
	if vehicle_upgrades.has(v_id) and vehicle_upgrades[v_id].has(upgrade_type):
		return vehicle_upgrades[v_id][upgrade_type]
	return 1

func set_upgrade_level(v_id: String, upgrade_type: String, level: int) -> void:
	if not vehicle_upgrades.has(v_id):
		vehicle_upgrades[v_id] = {}
	vehicle_upgrades[v_id][upgrade_type] = clampi(level, 1, 5)

func get_vehicle_color(v_id: String) -> Color:
	if vehicle_colors.has(v_id):
		return vehicle_colors[v_id]
	return Color(0.08, 0.45, 0.95)

func set_vehicle_color(v_id: String, color: Color) -> void:
	vehicle_colors[v_id] = color

func discover_district(d_id: String) -> bool:
	if not discovered_districts.has(d_id):
		discovered_districts.append(d_id)
		return true
	return false
