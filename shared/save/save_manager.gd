extends Node

const SAVE_FILE_PATH: String = "user://voltarena_save.json"
const SAVE_VERSION: int = 1

var save_data: Dictionary = {}

func _ready() -> void:
	load_save()

func get_default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"statistics": {
			"arena_fps": {
				"matches_played": 0,
				"kills": 0,
				"deaths": 0,
				"highest_score": 0,
				"wins": 0
			},
			"subway_survival": {
				"runs_played": 0,
				"highest_wave": 0,
				"total_kills": 0,
				"highest_score": 0
			},
			"rocket_car": {
				"matches_played": 0,
				"goals_scored": 0,
				"saves": 0,
				"wins": 0
			},
			"kart_racing": {
				"races_finished": 0,
				"podiums": 0,
				"best_lap_canyon": 999.0,
				"best_lap_city": 999.0,
				"best_lap_mountain": 999.0
			}
		},
		"unlocked_items": {
			"arena_weapons": ["pulse_rifle", "scatter_cannon", "rail_driver"],
			"karts": ["speeder_v1", "turbo_beast"],
			"cars": ["nitro_standard"]
		}
	}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		save_data = get_default_save()
		save_to_disk()
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		save_data = get_default_save()
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(content)
	if err != OK or typeof(json.get_data()) != TYPE_DICTIONARY:
		push_warning("Corrupted save file detected, restoring defaults safely.")
		save_data = get_default_save()
		save_to_disk()
		return

	save_data = json.get_data()
	# Ensure statistics structure
	var defaults = get_default_save()
	if not save_data.has("statistics"):
		save_data["statistics"] = defaults["statistics"]
	else:
		for game in defaults["statistics"].keys():
			if not save_data["statistics"].has(game):
				save_data["statistics"][game] = defaults["statistics"][game]

func save_to_disk() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "  "))
		file.close()

func record_arena_match(kills: int, deaths: int, score: int, won: bool) -> void:
	var stats = save_data["statistics"]["arena_fps"]
	stats["matches_played"] += 1
	stats["kills"] += kills
	stats["deaths"] += deaths
	if score > stats["highest_score"]:
		stats["highest_score"] = score
	if won:
		stats["wins"] += 1
	save_to_disk()

func record_subway_run(wave: int, kills: int, score: int) -> void:
	var stats = save_data["statistics"]["subway_survival"]
	stats["runs_played"] += 1
	stats["total_kills"] += kills
	if wave > stats["highest_wave"]:
		stats["highest_wave"] = wave
	if score > stats["highest_score"]:
		stats["highest_score"] = score
	save_to_disk()

func record_rocket_match(goals: int, saves: int, won: bool) -> void:
	var stats = save_data["statistics"]["rocket_car"]
	stats["matches_played"] += 1
	stats["goals_scored"] += goals
	stats["saves"] += saves
	if won:
		stats["wins"] += 1
	save_to_disk()

func record_kart_race(track_id: String, lap_time: float, finished_first: bool) -> void:
	var stats = save_data["statistics"]["kart_racing"]
	stats["races_finished"] += 1
	if finished_first:
		stats["podiums"] += 1
	var key = "best_lap_" + track_id
	if not stats.has(key) or lap_time < stats[key]:
		stats[key] = lap_time
	save_to_disk()
