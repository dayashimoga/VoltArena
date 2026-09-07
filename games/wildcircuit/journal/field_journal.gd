class_name FieldJournal
extends Node

## FieldJournal: Wildlife Encyclopedia, Photograph Gallery, and Conservation Progress
## Tracks discovered species, scored photographs, behaviors, and biome completion.

const AnimalDataScript = preload("res://games/wildcircuit/animals/animal_data.gd")

signal species_discovered(species_id: String)
signal photo_logged(photo_entry: Dictionary)
signal conservation_updated(biome_name: String, percentage: float)

var _entries: Dictionary = {} # species_id -> Dictionary (best photo record)
var _observed_behaviors: Dictionary = {} # species_id -> Array[String]

func log_photo(photo_record: Dictionary) -> bool:
	if not photo_record.get("valid", false):
		return false

	var sp_id = photo_record.get("species_id", "")
	var is_first_discovery = not _entries.has(sp_id)

	var prev_score = 0
	if not is_first_discovery:
		prev_score = _entries[sp_id].get("score", 0)

	var new_score = photo_record.get("score", 0)
	if is_first_discovery or new_score > prev_score:
		_entries[sp_id] = photo_record.duplicate()

	# Track observed behaviors
	if not _observed_behaviors.has(sp_id):
		_observed_behaviors[sp_id] = []
	var b_name = photo_record.get("behavior", "")
	if not _observed_behaviors[sp_id].has(b_name) and not b_name.is_empty():
		_observed_behaviors[sp_id].append(b_name)

	photo_logged.emit(photo_record)
	if is_first_discovery:
		species_discovered.emit(sp_id)

	# Save progress
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_wildcircuit_photo(sp_id, new_score, photo_record.get("grade", "Bronze"))

	return is_first_discovery or new_score > prev_score

func get_best_photo(species_id: String) -> Dictionary:
	return _entries.get(species_id, {})

func get_all_entries() -> Dictionary:
	return _entries.duplicate()

func get_total_discovered() -> int:
	return _entries.size()

func calculate_biome_completion(biome_name: String) -> float:
	var total_in_biome = 0
	var found_in_biome = 0
	for sp in AnimalDataScript.SPECIES.values():
		if sp.get("biome") == biome_name:
			total_in_biome += 1
			if _entries.has(sp.get("id")):
				found_in_biome += 1

	if total_in_biome == 0:
		return 100.0
	return (float(found_in_biome) / float(total_in_biome)) * 100.0
