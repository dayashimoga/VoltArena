class_name TestEventBus
extends RefCounted

const EventBusScript = preload("res://shared/core/event_bus.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_signal_declarations()
	test_signal_emission()
	test_signal_connections()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [["res://shared/core/event_bus.gd", []]]

func assert_true(cond: bool, msg: String) -> void:
	if cond: assertions_passed += 1
	else: assertions_failed += 1; push_error("Unit EventBus FAIL: " + msg)

func test_signal_declarations() -> void:
	var bus = EventBusScript.new()
	var required_signals = [
		"game_state_changed", "game_selected", "game_loaded",
		"return_to_launcher_requested", "game_restart_requested",
		"match_started", "match_paused", "match_ended",
		"score_updated", "round_timer_updated",
		"player_spawned", "player_health_changed", "player_armor_changed",
		"player_ammo_changed", "player_weapon_switched",
		"player_died", "enemy_died", "pickup_collected",
		"wave_started", "wave_completed",
		"ball_hit", "goal_scored", "boost_amount_changed",
		"race_countdown", "checkpoint_passed", "lap_completed",
		"race_position_updated", "powerup_acquired",
		"settings_updated", "play_sound_requested", "show_toast_requested"
	]
	for sig_name in required_signals:
		assert_true(bus.has_signal(sig_name), "EventBus must declare signal: %s" % sig_name)

func test_signal_emission() -> void:
	var bus = EventBusScript.new()
	var received = [false]

	bus.score_updated.connect(func(_team, _score): received[0] = true)
	bus.score_updated.emit(0, 100)
	assert_true(received[0], "score_updated signal must be emittable and receivable")

	var toast_received = [false]
	bus.show_toast_requested.connect(func(_msg, _color): toast_received[0] = true)
	bus.show_toast_requested.emit("Test", Color.WHITE)
	assert_true(toast_received[0], "show_toast_requested must work")

func test_signal_connections() -> void:
	var bus = EventBusScript.new()
	var counter = [0]
	var callback = func(_a, _b): counter[0] += 1

	bus.player_health_changed.connect(callback)
	bus.player_health_changed.emit(80.0, 100.0)
	bus.player_health_changed.emit(60.0, 100.0)
	assert_true(counter[0] == 2, "Signal must fire to all connected callbacks")
