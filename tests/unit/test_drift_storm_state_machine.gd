class_name TestDriftStormStateMachine
extends RefCounted

## Dedicated unit and integration test suite for Drift Storm Scene State Machine
## Validates complete menu-to-race lifecycle, zero race entities before start,
## 6 circuits metadata, 5 vehicle archetypes, and countdown-to-race transitions.

const KartRacingMainScript = preload("res://games/kart-racing/kart_racing_main.gd")
const DriftStormHUDScript = preload("res://games/kart-racing/ui/drift_storm_hud.gd")
const TrackRegistryScript = preload("res://games/kart-racing/tracks/track_registry.gd")

func run_tests() -> Dictionary:
	var results = {"passed": 0, "failed": 0, "errors": []}
	run(results)
	return results

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/kart-racing/kart_racing_main.gd",
			["setup_scene", "_set_race_world_active", "start_race", "reposition_karts_on_grid", "_on_race_started", "select_track", "select_kart"]
		],
		[
			"res://games/kart-racing/ui/drift_storm_hud.gd",
			["setup_onboarding_overlay", "transition_menu_state", "_build_track_select_view", "_build_vehicle_select_view", "_build_race_setup_view", "_build_confirm_view", "_on_continue_step_pressed", "_on_prev_step_pressed", "_select_track_ui", "_select_vehicle_ui", "_on_start_race_clicked", "dismiss_onboarding", "set_in_race_hud_visible"]
		]
	]

func run(results: Dictionary) -> void:
	_test_initial_dormant_pre_race_state(results)
	_test_menu_state_machine_navigation(results)
	_test_circuit_definitions_and_metadata(results)
	_test_vehicle_archetypes_and_radar_stats(results)
	_test_start_race_activation_and_countdown(results)

func _test_initial_dormant_pre_race_state(results: Dictionary) -> void:
	var main = KartRacingMainScript.new()
	main._ready()

	# 1. Main begins in PRE_RACE
	if main.current_state == KartRacingMainScript.State.PRE_RACE:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("KartRacingMain must begin in PRE_RACE state")

	# 2. Race entities must be hidden and dormant before start
	if main.player_kart and not main.player_kart.visible and main.player_kart.process_mode == Node.PROCESS_MODE_DISABLED:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Player kart must be hidden and process disabled during PRE_RACE")

	if main.track_generator and not main.track_generator.visible:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Track generator must be hidden during PRE_RACE")

	for ai in main.ai_karts:
		if not ai.visible and ai.process_mode == Node.PROCESS_MODE_DISABLED:
			results["passed"] += 1
		else:
			results["failed"] += 1
			results["errors"].append("AI karts must be hidden and process disabled during PRE_RACE")

	# 3. In-race HUD must be strictly hidden during pre-race menus
	var hud = main.hud as DriftStormHUD
	if hud and hud.in_race_hud_root and not hud.in_race_hud_root.visible:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("In-race HUD root must be hidden during pre-race menus")

	# 4. Pre-race onboarding overlay must be visible and open
	if hud and hud.onboarding_overlay and hud.onboarding_overlay.visible:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Onboarding pre-race menu overlay must be visible in PRE_RACE")

	main.queue_free()

func _test_menu_state_machine_navigation(results: Dictionary) -> void:
	var hud = DriftStormHUDScript.new()
	hud._ready()

	# 1. Verify default view is TRACK_SELECT
	if hud.current_menu_state == DriftStormHUD.MenuState.TRACK_SELECT:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("DriftStormHUD must default to TRACK_SELECT menu state")

	# 2. Step through navigation flow: TRACK -> VEHICLE -> SETUP -> CONFIRM
	hud._on_continue_step_pressed()
	if hud.current_menu_state == DriftStormHUD.MenuState.VEHICLE_SELECT:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Continue from TRACK_SELECT must transition to VEHICLE_SELECT")

	hud._on_continue_step_pressed()
	if hud.current_menu_state == DriftStormHUD.MenuState.RACE_SETUP:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Continue from VEHICLE_SELECT must transition to RACE_SETUP")

	hud._on_continue_step_pressed()
	if hud.current_menu_state == DriftStormHUD.MenuState.CONFIRM:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Continue from RACE_SETUP must transition to CONFIRM")

	# 3. Step backwards flow: CONFIRM -> SETUP -> VEHICLE -> TRACK
	hud._on_prev_step_pressed()
	if hud.current_menu_state == DriftStormHUD.MenuState.RACE_SETUP:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Previous from CONFIRM must transition to RACE_SETUP")

	hud._on_prev_step_pressed()
	if hud.current_menu_state == DriftStormHUD.MenuState.VEHICLE_SELECT:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Previous from RACE_SETUP must transition to VEHICLE_SELECT")

	hud._on_prev_step_pressed()
	if hud.current_menu_state == DriftStormHUD.MenuState.TRACK_SELECT:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Previous from VEHICLE_SELECT must transition to TRACK_SELECT")

	hud.queue_free()

func _test_circuit_definitions_and_metadata(results: Dictionary) -> void:
	var hud = DriftStormHUDScript.new()
	hud._ready()

	var required_tracks = ["speedway", "sunset_coast", "canyon", "skyline", "alpine_rush", "storm_harbor"]
	for t_id in required_tracks:
		if hud.TRACK_METADATA.has(t_id):
			var meta = hud.TRACK_METADATA[t_id]
			var valid_meta = (
				meta.has("name") and not meta["name"].is_empty() and
				meta.has("location") and not meta["location"].is_empty() and
				meta.has("theme") and not meta["theme"].is_empty() and
				meta.has("length") and not meta["length"].is_empty() and
				meta.has("laps") and not meta["laps"].is_empty() and
				meta.has("diff") and not meta["diff"].is_empty() and
				meta.has("surface") and not meta["surface"].is_empty() and
				meta.has("weather") and not meta["weather"].is_empty() and
				meta.has("record") and not meta["record"].is_empty() and
				meta.has("reward") and not meta["reward"].is_empty()
			)
			if valid_meta:
				results["passed"] += 1
			else:
				results["failed"] += 1
				results["errors"].append("Circuit '%s' is missing required metadata fields" % t_id)
		else:
			results["failed"] += 1
			results["errors"].append("DriftStormHUD is missing required circuit '%s'" % t_id)

	# Verify TrackRegistry also has all 6 tracks
	var reg_tracks = TrackRegistryScript.get_all_tracks()
	if reg_tracks.size() == 6:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("TrackRegistry must provide exactly 6 circuit definitions")

	hud.queue_free()

func _test_vehicle_archetypes_and_radar_stats(results: Dictionary) -> void:
	var hud = DriftStormHUDScript.new()
	hud._ready()

	var required_vehicles = ["speeder", "phantom", "enforcer", "turbo_demon", "formula"]
	for v_id in required_vehicles:
		if hud.VEHICLE_STATS.has(v_id):
			var stats = hud.VEHICLE_STATS[v_id]
			var valid_stats = (
				stats.has("name") and not stats["name"].is_empty() and
				stats.has("class") and not stats["class"].is_empty() and
				stats.has("desc") and not stats["desc"].is_empty() and
				stats.has("speed") and stats["speed"] > 0 and
				stats.has("accel") and stats["accel"] > 0 and
				stats.has("handling") and stats["handling"] > 0 and
				stats.has("drift") and stats["drift"] > 0 and
				stats.has("boost") and stats["boost"] > 0
			)
			if valid_stats:
				results["passed"] += 1
			else:
				results["failed"] += 1
				results["errors"].append("Vehicle archetype '%s' has incomplete performance radar metrics" % v_id)
		else:
			results["failed"] += 1
			results["errors"].append("DriftStormHUD is missing required vehicle archetype '%s'" % v_id)

	hud.queue_free()

func _test_start_race_activation_and_countdown(results: Dictionary) -> void:
	var main = KartRacingMainScript.new()
	main._ready()

	# Select track and kart
	main.select_track("sunset_coast")
	main.select_kart("phantom")

	# Launch race explicitly
	main.start_race()

	# 1. State must transition to COUNTDOWN
	if main.current_state == KartRacingMainScript.State.COUNTDOWN:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("start_race() must transition state to COUNTDOWN")

	# 2. Race entities must now be visible and active
	if main.player_kart and main.player_kart.visible and main.player_kart.process_mode == Node.PROCESS_MODE_INHERIT:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Player kart must be visible and active after start_race()")

	if main.track_generator and main.track_generator.visible:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Track generator must be visible after start_race()")

	# 3. In-race HUD must now be active
	var hud = main.hud as DriftStormHUD
	if hud and hud.in_race_hud_root and hud.in_race_hud_root.visible:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("In-race HUD root must become visible after start_race()")

	if hud and hud.onboarding_overlay and not hud.onboarding_overlay.visible:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("Onboarding pre-race menu overlay must be dismissed after start_race()")

	# 4. Trigger race started
	main._on_race_started()
	if main.current_state == KartRacingMainScript.State.RACING:
		results["passed"] += 1
	else:
		results["failed"] += 1
		results["errors"].append("_on_race_started() must transition state to RACING")

	main.queue_free()
