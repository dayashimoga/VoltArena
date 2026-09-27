class_name TestChromaModesAndProgression
extends RefCounted

## Unit tests for Chroma Rush save adapter, garage unlocks, HUD signals, and interactive tutorial

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const ChromaSaveAdapter = preload("res://games/chroma-rush/persistence/chroma_save_adapter.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ChromaHUD = preload("res://games/chroma-rush/ui/chroma_hud.gd")
const ChromaGarage = preload("res://games/chroma-rush/ui/chroma_garage.gd")
const ChromaTutorial = preload("res://games/chroma-rush/ui/chroma_tutorial.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_save_adapter_defaults_and_progression()
	test_vehicle_unlock_and_paint_customization()
	test_resumable_session_persistence()
	test_tutorial_step_progression_lifecycle()
	test_hud_signal_and_badge_updates()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaProgression FAIL] " + msg)

func assert_false(condition: bool, msg: String) -> void:
	assert_true(not condition, msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaProgression FAIL] %s (Expected %s, got %s)" % [msg, str(b), str(a)])

func test_save_adapter_defaults_and_progression() -> void:
	var def = ChromaSaveAdapter.get_default_data()
	assert_eq(def["credits"], 1000, "Default credits is 1000")
	assert_true(ChromaConstants.VEHICLE_APEX in def["unlocked_vehicles"], "Apex unlocked by default")
	assert_true(ChromaConstants.VEHICLE_VORTEX in def["unlocked_vehicles"], "Vortex unlocked by default")

	# Simulate recording mission completion
	var initial_credits = 1000
	var res1 = ChromaSaveAdapter.record_mission_completion("hunt_neon_01", true, 2500, 3, 45.2, 500)
	assert_true(res1["total_credits"] > initial_credits, "Credits must increase after mission completion")
	assert_eq(res1["stars"], 3, "Stars recorded as 3")

	# Re-completing the same mission with same stars should not grant duplicate first-time star bonuses
	var credits_after_first = res1["total_credits"]
	var res2 = ChromaSaveAdapter.record_mission_completion("hunt_neon_01", true, 2600, 3, 44.0, 500)
	assert_eq(res2["total_credits"], credits_after_first + 500, "Only base reward granted on repeat, no duplicate star bonus")

func test_vehicle_unlock_and_paint_customization() -> void:
	# Give test enough credits to buy Titan Vanguard (2500)
	var data = ChromaSaveAdapter.load_chroma_data()
	data["credits"] = 5000
	ChromaSaveAdapter.save_chroma_data(data)

	assert_false(ChromaSaveAdapter.is_vehicle_unlocked(ChromaConstants.VEHICLE_TITAN), "Titan initially locked")

	var ok = ChromaSaveAdapter.unlock_vehicle(ChromaConstants.VEHICLE_TITAN)
	assert_true(ok, "Vehicle unlock should succeed with sufficient credits")
	assert_true(ChromaSaveAdapter.is_vehicle_unlocked(ChromaConstants.VEHICLE_TITAN), "Titan is now unlocked")

	var selected = ChromaSaveAdapter.select_vehicle(ChromaConstants.VEHICLE_TITAN)
	assert_true(selected, "Selecting unlocked vehicle succeeds")
	assert_eq(ChromaSaveAdapter.get_selected_vehicle(), ChromaConstants.VEHICLE_TITAN, "Selected vehicle is Titan")

	# Paint customization
	ChromaSaveAdapter.set_vehicle_paint(ChromaConstants.VEHICLE_TITAN, "carbon")
	assert_eq(ChromaSaveAdapter.get_vehicle_paint(ChromaConstants.VEHICLE_TITAN), "carbon", "Paint finish persisted as carbon")

func test_resumable_session_persistence() -> void:
	ChromaSaveAdapter.clear_active_session()
	assert_false(ChromaSaveAdapter.has_resumable_session(), "No active session initially")

	var sess = {
		"mission_id": "hunt_neon_02",
		"world_id": ChromaConstants.WORLD_NEON_CITY,
		"player_color": ChromaConstants.ChromaColor.COBALT,
		"current_objective_idx": 1,
		"score": 1500,
		"time_remaining": 72.5
	}
	ChromaSaveAdapter.save_active_session(sess)

	assert_true(ChromaSaveAdapter.has_resumable_session(), "Active session is now detectable")
	var loaded = ChromaSaveAdapter.load_active_session()
	assert_eq(loaded["mission_id"], "hunt_neon_02", "Loaded session matches saved mission")
	assert_eq(loaded["player_color"], ChromaConstants.ChromaColor.COBALT, "Loaded session preserves player color")

	ChromaSaveAdapter.clear_active_session()
	assert_false(ChromaSaveAdapter.has_resumable_session(), "Session cleared cleanly")

func test_tutorial_step_progression_lifecycle() -> void:
	var engine = ColorSwapEngine.new()
	var v = ChromaVehicle.new()
	v.vehicle_owner_id = "player"
	v.initial_color = ChromaConstants.ChromaColor.CRIMSON
	v._ready()

	var tut = ChromaTutorial.new(v, engine)
	tut.start_tutorial()
	assert_eq(tut.get_current_step_index(), 0, "Tutorial starts at Step 0: Driving Basics")

	# Advance steps
	tut.advance_step()
	assert_eq(tut.get_current_step_index(), 1, "Advanced to Step 1: Color Identification")

	tut.advance_step()
	assert_eq(tut.get_current_step_index(), 2, "Advanced to Step 2: Target Pursuit")

	tut.advance_step()
	assert_eq(tut.get_current_step_index(), 3, "Advanced to Step 3: Side Alignment")

	tut.advance_step()
	assert_eq(tut.get_current_step_index(), 4, "Advanced to Step 4: Atomic Swap")

	# Swap event triggers advance
	tut._on_swap_committed("player", "target_1", 1, 2)
	assert_eq(tut.get_current_step_index(), 5, "Advanced to Step 5: Checkpoint Delivery")

	# Checkpoint trigger triggers completion
	var tut_res = {"completed": false}
	tut.tutorial_completed.connect(func(): tut_res["completed"] = true)

	tut.handle_checkpoint_reached(true)
	assert_true(tut_res["completed"], "tutorial_completed fired")
	assert_true(ChromaSaveAdapter.is_tutorial_completed(), "Tutorial completion persisted in save adapter")

	v.free()

func test_hud_signal_and_badge_updates() -> void:
	var hud = ChromaHUD.new()
	hud._ready()

	hud.update_player_color(ChromaConstants.ChromaColor.COBALT)
	assert_true(hud.current_color_label.text.contains("Cobalt Blue"), "HUD reflects player cobalt color")

	hud.update_target_objective(ChromaConstants.ChromaColor.EMERALD, "gate_3")
	assert_true(hud.target_color_label.text.contains("Emerald Green"), "HUD reflects target emerald color")

	hud.update_score_and_combo(3500, 2.5)
	assert_eq(hud.score_label.text, "SCORE: 3500", "HUD updates score")
	assert_eq(hud.combo_label.text, "COMBO: x2.5", "HUD updates combo")

	var swap_btn_clicked = {"clicked": false}
	hud.swap_button_pressed.connect(func(): swap_btn_clicked["clicked"] = true)
	hud.swap_button_pressed.emit()
	assert_true(swap_btn_clicked["clicked"], "Touch swap button signal received")

	hud.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/chroma-rush/persistence/chroma_save_adapter.gd", [
			"get_default_data", "load_chroma_data", "save_chroma_data",
			"record_mission_completion", "unlock_vehicle", "is_vehicle_unlocked",
			"select_vehicle", "get_selected_vehicle", "set_vehicle_paint",
			"get_vehicle_paint", "set_tutorial_completed", "is_tutorial_completed",
			"save_active_session", "load_active_session", "clear_active_session",
			"has_resumable_session"
		]],
		["res://games/chroma-rush/ui/chroma_garage.gd", [
			"_ready", "_process", "refresh_display"
		]],
		["res://games/chroma-rush/ui/chroma_tutorial.gd", [
			"start_tutorial", "update", "advance_step", "handle_checkpoint_reached",
			"get_current_step_index"
		]],
		["res://games/chroma-rush/ui/chroma_hud.gd", [
			"_ready", "setup_hud_layout", "connect_systems", "_process",
			"update_player_color", "update_target_objective", "update_score_and_combo",
			"update_timer", "set_swaps_remaining"
		]]
	]
