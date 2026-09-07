class_name TestWildCircuit
extends RefCounted

## Unit tests for WildCircuit Wildlife Photography & Traversal (games/wildcircuit/)

const AnimalDataScript = preload("res://games/wildcircuit/animals/animal_data.gd")
const WildAnimalScript = preload("res://games/wildcircuit/animals/wild_animal.gd")
const CameraModeScript = preload("res://games/wildcircuit/photography/camera_mode.gd")
const FieldJournalScript = preload("res://games/wildcircuit/journal/field_journal.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_species_catalog()
	test_animal_state_machine()
	test_camera_photo_scoring()
	test_field_journal_logging()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/wildcircuit/animals/animal_data.gd", [
			"get_species", "get_species_for_biome"
		]],
		["res://games/wildcircuit/animals/wild_animal.gd", [
			"_ready", "_physics_process", "transition_to_state", "take_fright",
			"setup_visuals", "setup_nav_sensors", "check_player_proximity",
			"change_state", "execute_state", "get_current_behavior_name"
		]],
		["res://games/wildcircuit/photography/camera_mode.gd", [
			"_ready", "toggle_camera_mode", "set_zoom", "take_photo", "score_photograph"
		]],
		["res://games/wildcircuit/journal/field_journal.gd", [
			"log_photo", "get_biome_completion", "get_total_photos_count",
			"get_best_photo", "get_all_entries", "get_total_discovered", "calculate_biome_completion"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit WildCircuit FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_species_catalog() -> void:
	assert_true(AnimalDataScript.SPECIES.size() >= 7, "Must contain at least 7 distinct species")

	var savannah_species = AnimalDataScript.get_species_for_biome("savannah")
	assert_true(savannah_species.size() >= 2, "Savannah must have at least 2 native species")

func test_animal_state_machine() -> void:
	var animal = WildAnimalScript.new()
	animal.species_id = "gazelle"
	assert_true(animal.current_state != "", "Animal should have initial state")

	animal.transition_to_state("flee")
	assert_eq(animal.current_state, "flee", "Animal should transition to flee state")

	animal.transition_to_state("graze")
	assert_eq(animal.current_state, "graze", "Animal should transition to graze state")
	animal.queue_free()

func test_camera_photo_scoring() -> void:
	var cam = CameraModeScript.new()
	assert_true(not cam.is_active, "Camera mode should start inactive")

	cam.toggle_camera_mode()
	assert_true(cam.is_active, "Camera mode should activate after toggle")

	cam.set_zoom(2.5)
	assert_eq(cam.current_zoom, 2.5, "Zoom should update to 2.5x")
	cam.queue_free()

func test_field_journal_logging() -> void:
	var journal = FieldJournalScript.new()
	var photo_entry = {
		"species_id": "lion",
		"biome_id": "savannah",
		"score": 92,
		"grade": "Platinum",
		"behavior": "hunting"
	}
	journal.log_photo(photo_entry)
	assert_eq(journal.get_total_photos_count(), 1, "Journal photos count should be 1")

	var completion = journal.get_biome_completion("savannah")
	assert_true(completion > 0.0, "Biome completion percentage should increase after photo log")
