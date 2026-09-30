class_name ChromaSaveAdapter
extends RefCounted

## Namespaced persistence adapter for Chroma Rush
## Integrates cleanly with VoltArena's SaveManager without corrupting other games.
## Manages versioned progression, vehicle unlocks, records, and resumable sessions.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const VehicleCatalog = preload("res://games/chroma-rush/vehicles/vehicle_catalog.gd")

const SAVE_KEY: String = "chroma_rush"
const SCHEMA_VERSION: int = 1

static func get_default_data() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"credits": 1000,
		"unlocked_vehicles": [ChromaConstants.VEHICLE_APEX, ChromaConstants.VEHICLE_VORTEX],
		"selected_vehicle": ChromaConstants.VEHICLE_APEX,
		"custom_paints": {
			ChromaConstants.VEHICLE_APEX: "metallic",
			ChromaConstants.VEHICLE_VORTEX: "gloss"
		},
		"mission_stars": {},        # mission_id -> int (1-3)
		"best_times": {},          # mission_id -> float
		"highest_scores": {},      # mission_id -> int
		"championship_trophies": {
			"stage_1": 0,
			"stage_2": 0,
			"stage_3": 0,
			"stage_4": 0
		},
		"achievements": [],
		"tutorial_completed": false,
		"active_session": {}       # Resumable session data
	}

static var _cache_data: Dictionary = {}

static func load_chroma_data() -> Dictionary:
	var sm = _get_save_manager()
	if sm:
		var custom_val = sm.get_custom_data(SAVE_KEY, null)
		if custom_val != null and typeof(custom_val) == TYPE_DICTIONARY:
			_cache_data = _migrate_and_verify(custom_val)
			return _cache_data.duplicate(true)
	if not _cache_data.is_empty():
		return _cache_data.duplicate(true)
	_cache_data = get_default_data()
	return _cache_data.duplicate(true)

static func save_chroma_data(data: Dictionary) -> void:
	_cache_data = data.duplicate(true)
	var sm = _get_save_manager()
	if sm:
		sm.set_custom_data(SAVE_KEY, data)

static func record_mission_completion(mission_id: String, victory: bool = true, score: int = 0, stars: int = 1, time_taken: float = 0.0, credits_earned: int = 0) -> Dictionary:
	var data = load_chroma_data()

	var previous_stars = data["mission_stars"].get(mission_id, 0)
	var new_stars = maxi(previous_stars, stars)
	data["mission_stars"][mission_id] = new_stars

	# Best time (lower is better for victory)
	if victory:
		var prev_time = data["best_times"].get(mission_id, 9999.0)
		if time_taken < prev_time:
			data["best_times"][mission_id] = time_taken

	# Highest score
	var prev_score = data["highest_scores"].get(mission_id, 0)
	if score > prev_score:
		data["highest_scores"][mission_id] = score

	# Credits award: only award first-time star bonuses to prevent infinite duplicate reward farming
	var first_time_star_delta = new_stars - previous_stars
	var adjusted_credits = credits_earned
	if first_time_star_delta > 0:
		adjusted_credits += first_time_star_delta * 250

	data["credits"] += adjusted_credits

	# Clear any active session on mission completion
	data["active_session"] = {}

	save_chroma_data(data)

	return {
		"total_credits": data["credits"],
		"stars": new_stars,
		"credits_granted": adjusted_credits,
		"credits_earned": adjusted_credits
	}

static func unlock_vehicle(v_id: String, cost_override: int = -1) -> bool:
	var data = load_chroma_data()
	if v_id in data["unlocked_vehicles"]:
		return true # Already unlocked

	var def = VehicleCatalog.get_vehicle_definition(v_id)
	var cost = cost_override if cost_override >= 0 else def.get("credit_cost", 0)

	if data["credits"] >= cost:
		data["credits"] -= cost
		data["unlocked_vehicles"].append(v_id)
		save_chroma_data(data)
		return true

	return false

static func is_vehicle_unlocked(v_id: String) -> bool:
	var data = load_chroma_data()
	return v_id in data.get("unlocked_vehicles", [])

static func select_vehicle(v_id: String) -> bool:
	if not is_vehicle_unlocked(v_id):
		return false
	var data = load_chroma_data()
	data["selected_vehicle"] = v_id
	save_chroma_data(data)
	return true

static func get_selected_vehicle() -> String:
	var data = load_chroma_data()
	return data.get("selected_vehicle", ChromaConstants.VEHICLE_APEX)

static func set_vehicle_paint(v_id: String, paint_style: String) -> void:
	var data = load_chroma_data()
	if not data.has("custom_paints"):
		data["custom_paints"] = {}
	data["custom_paints"][v_id] = paint_style
	save_chroma_data(data)

static func get_vehicle_paint(v_id: String) -> String:
	var data = load_chroma_data()
	return data.get("custom_paints", {}).get(v_id, "metallic")

static func set_tutorial_completed(completed: bool = true) -> void:
	var data = load_chroma_data()
	data["tutorial_completed"] = completed
	save_chroma_data(data)

static func is_tutorial_completed() -> bool:
	var data = load_chroma_data()
	return data.get("tutorial_completed", false)

# --- RESUMABLE SESSION SERIALIZATION ---
static func save_active_session(session_data: Dictionary) -> void:
	var data = load_chroma_data()
	data["active_session"] = session_data
	save_chroma_data(data)

static func load_active_session() -> Dictionary:
	var data = load_chroma_data()
	return data.get("active_session", {})

static func clear_active_session() -> void:
	var data = load_chroma_data()
	data["active_session"] = {}
	save_chroma_data(data)

static func has_resumable_session() -> bool:
	var sess = load_active_session()
	return not sess.is_empty() and sess.get("mission_id", "") != ""

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

func get_profile_data() -> Dictionary:
	return load_chroma_data()

func save_resumable_session(session_data: Dictionary) -> void:
	save_active_session(session_data)

func reset_all_data() -> void:
	save_chroma_data(get_default_data())
