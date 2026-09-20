extends SceneTree

## VoltArena Comprehensive Test Runner v2.0
## Integrates: unit tests, E2E gameplay tests, save corruption tests
## Tracks: real function-level coverage via CoverageRegistry

# --- Unit Test Suites ---
const TestHealthScript = preload("res://tests/unit/test_health_component.gd")
const TestWeaponsScript = preload("res://tests/unit/test_weapons.gd")
const TestCarPhysicsScript = preload("res://tests/unit/test_car_physics.gd")
const TestRaceManagerScript = preload("res://tests/unit/test_race_manager.gd")
const TestSaveManagerScript = preload("res://tests/unit/test_save_manager.gd")
const TestWaveDirectorScript = preload("res://tests/unit/test_wave_director.gd")
const TestInputManagerScript = preload("res://tests/unit/test_input_manager.gd")
const TestAudioManagerScript = preload("res://tests/unit/test_audio_manager.gd")
const TestQualityManagerScript = preload("res://tests/unit/test_quality_manager.gd")
const TestEventBusScript = preload("res://tests/unit/test_event_bus.gd")
const TestMaterialGenScript = preload("res://tests/unit/test_material_generator.gd")
const TestArenaBotScript = preload("res://tests/unit/test_arena_bot.gd")
const TestEnemyBaseScript = preload("res://tests/unit/test_enemy_base.gd")
const TestKartCtrlScript = preload("res://tests/unit/test_kart_controller.gd")
const TestBallPhysicsScript = preload("res://tests/unit/test_ball_physics.gd")
const TestSaveCorruptionScript = preload("res://tests/unit/test_save_corruption.gd")
const TestSettingsManagerScript = preload("res://tests/unit/test_settings_manager.gd")
const TestTelemetryManagerScript = preload("res://tests/unit/test_telemetry_manager.gd")
const TestPlatformAdapterScript = preload("res://tests/unit/test_platform_adapter.gd")
const TestPhysicsHelpersScript = preload("res://tests/unit/test_physics_helpers.gd")
const TestAIBaseScript = preload("res://tests/unit/test_ai_base.gd")
const TestProjectileScript = preload("res://tests/unit/test_projectile.gd")
const TestPickupBaseScript = preload("res://tests/unit/test_pickup_base.gd")
const TestMapGeneratorsScript = preload("res://tests/unit/test_map_generators.gd")
const TestUISystemsScript = preload("res://tests/unit/test_ui_systems.gd")
const TestGameManagerScript = preload("res://tests/unit/test_game_manager.gd")
const TestFXFactoryScript = preload("res://tests/unit/test_fx_factory.gd")
const TestMeshBuilderScript = preload("res://tests/unit/test_mesh_builder.gd")
const TestLauncherArtScript = preload("res://tests/unit/test_launcher_art.gd")
const TestNodePoolScript = preload("res://tests/unit/test_node_pool.gd")
const TestProceduralAnimatorScript = preload("res://tests/unit/test_procedural_animator.gd")
const TestModelCacheScript = preload("res://tests/unit/test_model_cache.gd")
const TestNitroKickP0GatesScript = preload("res://tests/unit/test_nitro_kick_p0_gates.gd")
const TestDriftStormCorridorGatesScript = preload("res://tests/unit/test_drift_storm_corridor_gates.gd")
const TestDriftStormStateMachineScript = preload("res://tests/unit/test_drift_storm_state_machine.gd")
const TestCrossPlatformArchitectureScript = preload("res://tests/unit/test_cross_platform_architecture.gd")

# --- New Subsystems & 3 New Games (Unit) ---
const TestQuestSystemScript = preload("res://tests/unit/test_quest_system.gd")
const TestInventorySystemScript = preload("res://tests/unit/test_inventory_system.gd")
const TestPuzzleElementsScript = preload("res://tests/unit/test_puzzle_elements.gd")
const TestSkyboundScript = preload("res://tests/unit/test_skybound.gd")
const TestRoboForgeScript = preload("res://tests/unit/test_roboforge.gd")
const TestWildCircuitScript = preload("res://tests/unit/test_wildcircuit.gd")
const TestEngineSubsystemsScript = preload("res://tests/unit/test_engine_subsystems.gd")

# --- Strike Vector Test Suites ---
const TestStrikeCampaignScript = preload("res://games/strike-vector/tests/test_strike_campaign_unit.gd")
const TestStrikePlayerScript = preload("res://games/strike-vector/tests/test_strike_player_unit.gd")
const TestStrikeAIScript = preload("res://games/strike-vector/tests/test_strike_ai_unit.gd")
const TestStrikeVectorE2EScript = preload("res://games/strike-vector/tests/test_strike_vector_e2e.gd")
const TestStrikeTraversalProbesScript = preload("res://games/strike-vector/tests/test_strike_traversal_probes.gd")
const TestStrikeVisualInvariantsScript = preload("res://games/strike-vector/tests/test_strike_visual_invariants.gd")
const TestStrikeRuntimeAcceptanceScript = preload("res://games/strike-vector/tests/test_strike_runtime_acceptance.gd")

# --- Responsive & Soak ---
const TestResponsiveUIScript = preload("res://tests/responsive/test_responsive_ui.gd")
const TestSoakScript = preload("res://tests/performance/test_soak.gd")

# --- E2E Gameplay Tests ---
const TestArenaE2EScript = preload("res://tests/e2e/test_arena_e2e.gd")
const TestSubwayE2EScript = preload("res://tests/e2e/test_subway_e2e.gd")
const TestRocketE2EScript = preload("res://tests/e2e/test_rocket_e2e.gd")
const TestKartE2EScript = preload("res://tests/e2e/test_kart_e2e.gd")
const TestDriftStormRuntimeAcceptanceScript = preload("res://games/kart-racing/tests/test_drift_storm_runtime_acceptance.gd")
const TestSkyboundE2EScript = preload("res://tests/e2e/test_skybound_e2e.gd")
const TestRoboForgeE2EScript = preload("res://tests/e2e/test_roboforge_e2e.gd")
const TestWildCircuitE2EScript = preload("res://tests/e2e/test_wildcircuit_e2e.gd")
const TestLauncherE2EScript = preload("res://tests/e2e/test_launcher_e2e.gd")
const TestGameplayScreensScript = preload("res://tests/e2e/test_gameplay_screens.gd")

# --- Acceptance ---
const TestAcceptanceScript = preload("res://tests/acceptance/test_platform_acceptance.gd")

# --- Coverage ---
const CoverageRegistryScript = preload("res://tests/coverage_registry.gd")

func _init() -> void:
	print("==================================================")
	print("   VOLTARENA COMPREHENSIVE TEST RUNNER v2.0       ")
	print("==================================================")

	var start_time = Time.get_ticks_msec()
	var total_passed: int = 0
	var total_failed: int = 0
	var suite_results: Dictionary = {}

	# Initialize project autoloads into root so /root/... paths and InputMap actions exist
	_setup_autoloads()

	# Initialize coverage tracking
	var coverage = CoverageRegistryScript.new()
	coverage.build_inventory()

	# Build test suites
	var test_suites = [
		# Unit Tests
		{"name": "HealthComponent Unit", "instance": TestHealthScript.new()},
		{"name": "Weapons System Unit", "instance": TestWeaponsScript.new()},
		{"name": "Car Physics Unit", "instance": TestCarPhysicsScript.new()},
		{"name": "Race Manager Unit", "instance": TestRaceManagerScript.new()},
		{"name": "Save Manager Unit", "instance": TestSaveManagerScript.new()},
		{"name": "Wave Director Unit", "instance": TestWaveDirectorScript.new()},
		{"name": "Input Manager Unit", "instance": TestInputManagerScript.new()},
		{"name": "Audio Manager Unit", "instance": TestAudioManagerScript.new()},
		{"name": "Quality Manager Unit", "instance": TestQualityManagerScript.new()},
		{"name": "EventBus Unit", "instance": TestEventBusScript.new()},
		{"name": "MaterialGenerator Unit", "instance": TestMaterialGenScript.new()},
		{"name": "ArenaBot Unit", "instance": TestArenaBotScript.new()},
		{"name": "Enemy Archetypes Unit", "instance": TestEnemyBaseScript.new()},
		{"name": "KartController Unit", "instance": TestKartCtrlScript.new()},
		{"name": "Ball Physics Unit", "instance": TestBallPhysicsScript.new()},
		{"name": "Save Corruption & Recovery", "instance": TestSaveCorruptionScript.new()},
		{"name": "Settings Manager Unit", "instance": TestSettingsManagerScript.new()},
		{"name": "Telemetry Manager Unit", "instance": TestTelemetryManagerScript.new()},
		{"name": "Platform Adapter Unit", "instance": TestPlatformAdapterScript.new()},
		{"name": "Physics Helpers Unit", "instance": TestPhysicsHelpersScript.new()},
		{"name": "AI Systems Unit", "instance": TestAIBaseScript.new()},
		{"name": "Projectiles & Weapons Unit", "instance": TestProjectileScript.new()},
		{"name": "Pickups & Powerups Unit", "instance": TestPickupBaseScript.new()},
		{"name": "Map Generators Unit", "instance": TestMapGeneratorsScript.new()},
		{"name": "UI Systems & Controls Unit", "instance": TestUISystemsScript.new()},
		{"name": "GameManager & Loader Unit", "instance": TestGameManagerScript.new()},
		{"name": "FXFactory & Particles Unit", "instance": TestFXFactoryScript.new()},
		{"name": "MeshBuilder 3D Assets Unit", "instance": TestMeshBuilderScript.new()},
		{"name": "LauncherArt Vector Graphics Unit", "instance": TestLauncherArtScript.new()},
		{"name": "NodePool Centralized Service Unit", "instance": TestNodePoolScript.new()},
		{"name": "Procedural Animator & Shake Unit", "instance": TestProceduralAnimatorScript.new()},
		{"name": "ModelCache 3D glTF Assets Unit", "instance": TestModelCacheScript.new()},
		# Subsystems & New Games (Unit)
		{"name": "Quest System Unit", "instance": TestQuestSystemScript.new()},
		{"name": "Inventory System Unit", "instance": TestInventorySystemScript.new()},
		{"name": "Puzzle Elements Unit", "instance": TestPuzzleElementsScript.new()},
		{"name": "Skybound Odyssey Unit", "instance": TestSkyboundScript.new()},
		{"name": "RoboForge Arena Unit", "instance": TestRoboForgeScript.new()},
		{"name": "WildCircuit Unit", "instance": TestWildCircuitScript.new()},
		{"name": "Engine Subsystems Unit", "instance": TestEngineSubsystemsScript.new()},
		# Responsive & Soak
		{"name": "Responsive UI Multi-Resolution", "instance": TestResponsiveUIScript.new()},
		{"name": "Soak & Stability Lifecycle", "instance": TestSoakScript.new()},
		# E2E Gameplay Tests
		{"name": "Iron Crucible E2E", "instance": TestArenaE2EScript.new()},
		{"name": "Metro Siege E2E", "instance": TestSubwayE2EScript.new()},
		{"name": "Nitro Kick E2E", "instance": TestRocketE2EScript.new()},
		{"name": "Nitro Kick P0 Forensic Gates", "instance": TestNitroKickP0GatesScript.new()},
		{"name": "Drift Storm E2E", "instance": TestKartE2EScript.new()},
		{"name": "Drift Storm Corridor & Pre-Race Gates", "instance": TestDriftStormCorridorGatesScript.new()},
		{"name": "Drift Storm State Machine & Pre-Race Hub", "instance": TestDriftStormStateMachineScript.new()},
		{"name": "Global Cross-Platform Architecture Unit", "instance": TestCrossPlatformArchitectureScript.new()},
		{"name": "Drift Storm Runtime Acceptance (P0 Gates)", "instance": TestDriftStormRuntimeAcceptanceScript.new()},
		{"name": "Skybound Odyssey E2E", "instance": TestSkyboundE2EScript.new()},
		{"name": "RoboForge Arena E2E", "instance": TestRoboForgeE2EScript.new()},
		{"name": "WildCircuit E2E", "instance": TestWildCircuitE2EScript.new()},
		{"name": "Launcher E2E", "instance": TestLauncherE2EScript.new()},
		{"name": "Gameplay Screens Certification E2E", "instance": TestGameplayScreensScript.new()},
		# Strike Vector Suites
		{"name": "Strike Vector Campaign Unit", "instance": TestStrikeCampaignScript.new()},
		{"name": "Strike Vector Player Unit", "instance": TestStrikePlayerScript.new()},
		{"name": "Strike Vector AI & Bosses Unit", "instance": TestStrikeAIScript.new()},
		{"name": "Strike Vector Campaign E2E", "instance": TestStrikeVectorE2EScript.new()},
		{"name": "Strike Vector Traversal & Collision Probes", "instance": TestStrikeTraversalProbesScript.new()},
		{"name": "Strike Vector Visual Invariants", "instance": TestStrikeVisualInvariantsScript.new()},
		{"name": "Strike Vector Runtime Acceptance (P0 Gates)", "instance": TestStrikeRuntimeAcceptanceScript.new()},
		# Legacy Acceptance
		{"name": "Platform Acceptance (Legacy)", "instance": TestAcceptanceScript.new()},
	]

	for suite in test_suites:
		var s_name = suite["name"]
		var inst = suite["instance"]
		print("\n[TEST SUITE] Running: %s..." % s_name)
		var res = inst.run_tests()
		var p = res.get("passed", 0)
		var f = res.get("failed", 0)
		total_passed += p
		total_failed += f
		var status = "PASS" if f == 0 else "FAIL"
		suite_results[s_name] = {"passed": p, "failed": f, "status": status}
		var color_prefix = "  ✓" if f == 0 else "  ✗"
		print("%s %s: %d passed, %d failed [%s]" % [color_prefix, s_name, p, f, status])

		# Register coverage entries if available
		if inst.has_method("get_coverage_entries"):
			var entries = inst.get_coverage_entries()
			for entry in entries:
				coverage.register_class_tested(entry[0], entry[1])

	var elapsed_sec = (Time.get_ticks_msec() - start_time) / 1000.0

	# Compute real coverage
	coverage.print_summary()
	var cov_report = coverage.compute_coverage()
	var coverage_pct = cov_report["overall_coverage_pct"]

	print("\n==================================================")
	print("TEST RESULTS SUMMARY:")
	print("  Total Suites:        %d" % test_suites.size())
	print("  Total Passed:        %d" % total_passed)
	print("  Total Failed:        %d" % total_failed)
	print("  Function Coverage:   %.1f%% (%d/%d functions)" % [coverage_pct, cov_report["tested_functions"], cov_report["total_functions"]])
	print("  Execution Time:      %.3fs" % elapsed_sec)
	print("==================================================")

	# Save JSON report to artifacts
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")

	var report = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"total_suites": test_suites.size(),
		"total_passed": total_passed,
		"total_failed": total_failed,
		"coverage_percent": coverage_pct,
		"coverage_tested_functions": cov_report["tested_functions"],
		"coverage_total_functions": cov_report["total_functions"],
		"execution_seconds": elapsed_sec,
		"suites": suite_results,
		"status": "PASS" if total_failed == 0 else "FAIL"
	}

	var report_file = FileAccess.open("res://artifacts/test-results.json", FileAccess.WRITE)
	if report_file:
		report_file.store_string(JSON.stringify(report, "  "))
		report_file.close()

	# Save coverage report
	coverage.save_report("res://artifacts/coverage-report.json")

	if total_failed == 0:
		print("\nALL TEST GATES PASSED [%d/%d ASSERTIONS, 100%% SUCCESS]" % [total_passed, total_passed])
		quit(0)
	else:
		push_error("\nTEST FAILURES DETECTED: %d assertions failed!" % total_failed)
		quit(1)

func _setup_autoloads() -> void:
	# Ensure InputMap default actions are registered immediately for all suites
	var im_script = load("res://shared/input/input_manager.gd")
	if im_script:
		var temp_im = im_script.new()
		temp_im.setup_default_actions()
		temp_im.free()

	var autoloads = [
		{"name": "EventBus", "path": "res://shared/core/event_bus.gd"},
		{"name": "SettingsManager", "path": "res://shared/settings/settings_manager.gd"},
		{"name": "SaveManager", "path": "res://shared/save/save_manager.gd"},
		{"name": "AudioManager", "path": "res://shared/audio/audio_manager.gd"},
		{"name": "InputManager", "path": "res://shared/input/input_manager.gd"},
		{"name": "PlatformAdapter", "path": "res://shared/platform/platform_adapter.gd"},
		{"name": "QualityManager", "path": "res://shared/graphics/quality_manager.gd"},
		{"name": "TelemetryManager", "path": "res://shared/telemetry/telemetry_manager.gd"},
		{"name": "AssetLoader", "path": "res://shared/loading/asset_loader.gd"},
		{"name": "GameManager", "path": "res://shared/core/game_manager.gd"}
	]
	for al in autoloads:
		if not root.has_node(al.name):
			var script = load(al.path)
			if script:
				var node = script.new()
				node.name = al.name
				root.add_child(node)

