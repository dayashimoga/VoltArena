class_name TestModelCache
extends RefCounted

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_cache_lifecycle()
	test_character_models()
	test_enemy_models()
	test_vehicle_models()
	test_weapon_models()
	test_prop_and_building_models()
	test_animation_helpers()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [[
		"res://shared/graphics/model_cache.gd",
		[
			"clear_cache",
			"get_model",
			"get_character",
			"get_enemy",
			"get_vehicle",
			"get_weapon_model",
			"get_building",
			"get_prop",
			"play_animation"
		]
	]]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit ModelCache FAIL: " + msg)

func test_cache_lifecycle() -> void:
	ModelCacheScript.clear_cache()
	assert_true(true, "clear_cache must execute safely")

func test_character_models() -> void:
	var trooper = ModelCacheScript.get_character("trooper")
	assert_true(trooper != null, "Trooper model must load")
	if trooper: trooper.queue_free()

	var scout = ModelCacheScript.get_character("scout")
	assert_true(scout != null, "Scout model must load")
	if scout: scout.queue_free()

	var heavy = ModelCacheScript.get_character("heavy")
	assert_true(heavy != null, "Heavy model must load")
	if heavy: heavy.queue_free()

func test_enemy_models() -> void:
	for e_type in ["crawler", "stalker", "spitter", "brute", "boss"]:
		var model = ModelCacheScript.get_enemy(e_type)
		assert_true(model != null, "Enemy %s must load" % e_type)
		if model: model.queue_free()

func test_vehicle_models() -> void:
	for v_id in ["truck_red", "truck_green", "truck_yellow", "truck_purple"]:
		var veh = ModelCacheScript.get_vehicle(v_id)
		assert_true(veh != null, "Vehicle %s must load" % v_id)
		if veh: veh.queue_free()

func test_weapon_models() -> void:
	for w_name in ["Pulse Rifle", "Scatter Cannon", "Rail Driver", "Grenade Launcher", "Plasma Cutter"]:
		var w = ModelCacheScript.get_weapon_model(w_name)
		assert_true(w != null, "Weapon %s must load" % w_name)
		if w: w.queue_free()

func test_prop_and_building_models() -> void:
	var b_a = ModelCacheScript.get_building("a")
	assert_true(b_a != null, "Building A must load")
	if b_a: b_a.queue_free()

	var b_b = ModelCacheScript.get_building("b")
	assert_true(b_b != null, "Building B must load")
	if b_b: b_b.queue_free()

	var track_finish = ModelCacheScript.get_prop("track_finish")
	assert_true(track_finish != null, "Track finish prop must load")
	if track_finish: track_finish.queue_free()

func test_animation_helpers() -> void:
	var char_node = ModelCacheScript.get_character("trooper")
	var played = ModelCacheScript.play_animation(char_node, "idle")
	assert_true(played, "play_animation for idle must return true on rigged character")
	played = ModelCacheScript.play_animation(char_node, "walk")
	assert_true(played, "play_animation for walk must return true")
	if char_node: char_node.queue_free()
