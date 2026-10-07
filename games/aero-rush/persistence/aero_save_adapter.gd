class_name AeroSaveAdapter
extends RefCounted

## Namespaced persistence adapter for AeroRush: Impossible Circuit.
## Integrates cleanly with VoltArena's SaveManager without corrupting other games.
## Manages vehicle unlocks, tier progression, medals, best times, and records.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

const SAVE_KEY: String = "aero_rush"
const SCHEMA_VERSION: int = 1

static func get_default_data() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"credits": 1000,
		"selected_vehicle": AeroConstants.VEHICLE_APEX,
		"unlocked_vehicles": [AeroConstants.VEHICLE_APEX],
		"unlocked_tiers": [1],
		"course_medals": {},       # course_id -> int (1=Bronze, 2=Silver, 3=Gold, 4=Platinum)
		"best_times": {},          # course_id -> float (fastest seconds)
		"highest_scores": {},      # course_id -> int
		"ghost_records": {},       # course_id -> Array[Dictionary]
		"total_stunts_performed": 0,
		"total_distance_driven": 0.0
	}

static var _cached_data: Dictionary = {}

static func load_aero_data() -> Dictionary:
	var sm = _get_save_manager()
	if sm:
		var custom_val = sm.get_custom_data(SAVE_KEY, null)
		if custom_val != null and typeof(custom_val) == TYPE_DICTIONARY:
			_cached_data = _migrate_and_verify(custom_val)
			return _cached_data.duplicate(true)
	if not _cached_data.is_empty():
		return _cached_data.duplicate(true)
	# Disk fallback if SaveManager is unmounted or in isolated test
	if FileAccess.file_exists("user://voltarena_save.json"):
		var f = FileAccess.open("user://voltarena_save.json", FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(txt) == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
				var root_dict = json.get_data()
				if root_dict.has(SAVE_KEY) and typeof(root_dict[SAVE_KEY]) == TYPE_DICTIONARY:
					_cached_data = _migrate_and_verify(root_dict[SAVE_KEY])
					return _cached_data.duplicate(true)
	_cached_data = get_default_data()
	return _cached_data.duplicate(true)

static func save_aero_data(data: Dictionary) -> void:
	_cached_data = data.duplicate(true)
	var sm = _get_save_manager()
	if sm:
		sm.set_custom_data(SAVE_KEY, data)
	else:
		# Direct disk fallback if SaveManager autoload not mounted
		var save_dict: Dictionary = {}
		if FileAccess.file_exists("user://voltarena_save.json"):
			var f_in = FileAccess.open("user://voltarena_save.json", FileAccess.READ)
			if f_in:
				var txt = f_in.get_as_text()
				f_in.close()
				var json = JSON.new()
				if json.parse(txt) == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
					save_dict = json.get_data()
		save_dict[SAVE_KEY] = data
		var f_out = FileAccess.open("user://voltarena_save.json", FileAccess.WRITE)
		if f_out:
			f_out.store_string(JSON.stringify(save_dict, "  "))
			f_out.close()

static func record_course_result(
	course_id: String,
	time_taken: float,
	score: int,
	medal_earned: int,
	credits_base: int = 500
) -> Dictionary:
	var data = load_aero_data()

	# 1. Update Medal (Keep highest)
	var prev_medal = data["course_medals"].get(course_id, AeroConstants.Medal.NONE) as int
	var new_medal = maxi(prev_medal, medal_earned)
	data["course_medals"][course_id] = new_medal

	# 2. Update Best Time
	if time_taken > 0.0:
		var prev_time = data["best_times"].get(course_id, 9999.0) as float
		if time_taken < prev_time:
			data["best_times"][course_id] = time_taken

	# 3. Update Highest Score
	var prev_score = data["highest_scores"].get(course_id, 0) as int
	if score > prev_score:
		data["highest_scores"][course_id] = score

	# 4. First-time Medal Bonus Credits to prevent infinite duplicate reward farming
	var first_time_medal_bonus = 0
	if new_medal > prev_medal:
		first_time_medal_bonus = (new_medal - prev_medal) * 400

	var total_granted = credits_base + first_time_medal_bonus
	data["credits"] += total_granted

	# 5. Check Tier Unlocks
	_check_and_unlock_tiers(data)

	save_aero_data(data)

	return {
		"total_credits": data["credits"],
		"credits_granted": total_granted,
		"new_medal": new_medal,
		"is_new_best_time": time_taken < data["best_times"].get(course_id, 9999.0),
		"is_new_high_score": score > prev_score
	}

static func unlock_vehicle(v_id: String, cost: int) -> bool:
	var data = load_aero_data()
	if v_id in data["unlocked_vehicles"]:
		return true

	if data["credits"] >= cost:
		data["credits"] -= cost
		data["unlocked_vehicles"].append(v_id)
		save_aero_data(data)
		return true
	return false

static func _check_and_unlock_tiers(data: Dictionary) -> void:
	var total_medals = 0
	for m in data["course_medals"].values():
		if int(m) >= AeroConstants.Medal.BRONZE:
			total_medals += 1

	if total_medals >= 3 and not (2 in data["unlocked_tiers"]):
		data["unlocked_tiers"].append(2)
	if total_medals >= 6 and not (3 in data["unlocked_tiers"]):
		data["unlocked_tiers"].append(3)
	if total_medals >= 9 and not (4 in data["unlocked_tiers"]):
		data["unlocked_tiers"].append(4)

static func _migrate_and_verify(data: Dictionary) -> Dictionary:
	var defaults = get_default_data()
	for k in defaults.keys():
		if not data.has(k):
			data[k] = defaults[k]
	return data

static func _get_save_manager() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("SaveManager")
	return null
