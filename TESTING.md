# VoltArena — Automated Testing & Quality Assurance Guide

## 1. Testing Philosophy
VoltArena enforces strict quality gates:
1. **100% Pass Rate**: No failed assertions are permitted under any circumstances.
2. **>90% Code Coverage**: Core gameplay, combat, physics, kinematics, and state machines must exceed 90.0% function-level test coverage.
3. **Headless Execution**: All tests execute in headless Godot within a Podman container (`docker.io/barichello/godot-ci:4.3`).
4. **Hermetic Preloading**: Test scripts use `const Script = preload(...)` to ensure test execution is resilient even before autoload tree attachment.

---

## 2. Test Architecture

The master automated test runner is located at `tests/runner.gd`. When executed, it executes 56 modular test suites:

```
tests/runner.gd
├── Unit Test Suites (44 Suites)
│   ├── TestHealthComponent, TestWeapons, TestCarPhysics, TestRaceManager, TestSaveManager
│   ├── TestWaveDirector, TestInputManager, TestAudioManager, TestQualityManager, TestEventBus
│   ├── TestMaterialGenerator, TestArenaBot, TestEnemyArchetypes, TestKartController, TestBallPhysics
│   ├── TestSaveCorruption, TestSettingsManager, TestTelemetryManager, TestPlatformAdapter
│   ├── TestPhysicsHelpers, TestAISystems, TestProjectilesWeapons, TestPickupsPowerups, TestMapGenerators
│   ├── TestUISystems, TestGameManager, TestFXFactory, TestMeshBuilder, TestLauncherArt
│   ├── TestNodePool, TestProceduralAnimator, TestModelCache
│   ├── TestQuestSystem, TestInventorySystem, TestPuzzleElements, TestEngineSubsystems
│   ├── TestSkybound, TestRoboForge, TestWildCircuit
│   ├── TestNitroKickP0Gates (21 assertions: coordinates, archetypes, ball impulse, goal attribution, arena containment, AI lead intercept)
│   ├── TestDriftStormCorridorGates (15 assertions: 6-circuit corridor clearance, persistent pre-race hub, modal lock, turntable camera)
│   ├── TestStrikeCampaignUnit (65 assertions)
│   ├── TestStrikePlayerUnit (60 assertions)
│   ├── TestStrikeAIUnit (85 assertions)
│   ├── TestStrikeTraversalProbes (98 assertions)
│   ├── TestStrikeVisualInvariants (94 assertions: transforms, rigs, sockets, nav mesh, HUD)
│   └── TestStrikeRuntimeAcceptance (25 assertions: 100-shot firing pose stability, weapon grip alignment, physical projectile damage, obstacle blocking, metric scale, HUD threat indicator, roadway continuity)
├── Responsive & Soak Suites (2 Suites)
│   ├── TestResponsiveUI (135 assertions across 5 responsive screen profiles)
│   └── TestSoak (5 full lifecycle clean runs)
├── E2E Gameplay Test Suites (14 Suites)
│   ├── TestArenaE2E (76 assertions)
│   ├── TestSubwayE2E (36 assertions)
│   ├── TestRocketE2E (46 assertions)
│   ├── TestKartE2E (67 assertions)
│   ├── TestDriftStormRuntimeAcceptance (100 assertions across 10 P0 gate tests)
│   ├── TestLauncherE2E (84 assertions)
│   ├── TestGameplayScreens (32 assertions)
│   ├── TestSkyboundE2E (14 assertions)
│   ├── TestRoboForgeE2E (2 assertions)
│   ├── TestWildCircuitE2E (2 assertions)
│   └── TestStrikeVectorE2E (224 assertions across Missions 1–8)
└── Legacy Acceptance Suite (1 Suite, 19 assertions)
    └── TestPlatformAcceptance
─────────────────────────────────────────────────────────────
Total: 61 Suites, 1,886 Assertions (100% Pass, 0 Failures, 95.04% Real Function Coverage: 785/826)
```

---

## 3. Test Suites Overview

### 3.1 Shared Subsystem Suites
* **`test_quest_system.gd`**: Validates `QuestManager` lifecycle: registration, prerequisite enforcement, multi-stage objective updates, stage completion events, reward dispatches, and serialization/deserialization.
* **`test_inventory_system.gd`**: Validates `InventorySystem`: stack limits, item additions/removals, weight limits, gear slot equipment, and traversal capability unlocks.
* **`test_puzzle_elements.gd`**: Validates physics-driven `PressurePlate` activation, `PuzzleSwitch` toggling, `PuzzleDoor` locking/unlocking, and `WindCurrent` lift impulses.
* **`test_engine_subsystems.gd`**: Validates `OrbitCamera3D` raycasting collision avoidance, `DayNightCycle3D` 24-hour celestial orbit and lighting transitions, and `InteractionArea3D` prompt triggering.

### 3.2 8-Game Unit & E2E Suites
* **Iron Crucible (`test_weapons_system.gd`, `test_arena_bot.gd`, `test_arena_e2e.gd`)**: Validates all 5 weapon ballistics, bot navigation/firing/kill-plane recovery, Citadel/Foundry/Sektor perimeter seals, and 5 game modes.
* **Metro Siege (`test_enemy_archetypes.gd`, `test_wave_director.gd`, `test_subway_e2e.gd`)**: Validates 5 mutant archetypes (including BioColossus 1,200 HP boss), 10-wave horde escalation, scrap economy, kiosk upgrades, and train evacuation.
* **Nitro Kick (`test_car_physics.gd`, `test_ball_physics.gd`, `test_nitro_kick_p0_gates.gd`, `test_nitro_kick_e2e.gd`)**: Validates canonical $-Z$ coordinate hierarchy, normalized imported GLTF meshes under `VisualRoot`, 4 authentic vehicle archetypes (Apex Spectre, Dune Raider, Titan Enforcer, Volt Pulse), single-impulse CCD ball physics without double-velocity glitches, regulation $110\text{m} \times 64\text{m} \times 20\text{m}$ stadium with $45^\circ$ octagonal corners, net cages, 34 boost pads, MultiMesh crowd, and dynamic role-based AI (Striker/Support/Defender/Goalkeeper) with predictive lead intercept convergence.
* **Drift Storm (`test_kart_controller.gd`, `test_race_manager.gd`, `test_drift_storm_corridor_gates.gd`, `test_drift_storm_runtime_acceptance.gd`, `test_drift_storm_e2e.gd`)**: Validates 4-wheel raycast suspension telemetry, single `RaceSpline` authority model, 6 global production circuits with automated corridor clearance verification (0 intrusions), 5 vehicle classes, persistent Championship Pre-Race Hub with modal lock and turntable camera, authoritative wrong-way detection with hysteresis, and continuous progress sorting.
* **Skybound Odyssey (`test_skybound.gd`, `test_skybound_e2e.gd`)**: Validates locomotion, variable jump, double jump, ledge mantling, glider flight aerodynamics, grapple mechanics, 5 interconnected regions, and shard collection.
* **RoboForge Arena (`test_roboforge.gd`, `test_roboforge_e2e.gd`)**: Validates 3 chassis types, 3 drive types, 3 power cores, 5 functional tools, dynamic mass/speed/torque recalculation, 3D workshop bay, and 7 challenge courses.
* **WildCircuit (`test_wildcircuit.gd`, `test_wildcircuit_e2e.gd`)**: Validates 5 biomes, 9 animal species with 8-state finite state machines, optical viewfinder photography (24-300mm zoom), deterministic photo scoring, and expedition ATV traversal.
* **Strike Vector (`test_strike_campaign_unit.gd`, `test_strike_player_unit.gd`, `test_strike_ai_unit.gd`, `test_strike_visual_invariants.gd`, `test_strike_runtime_acceptance.gd`, `test_strike_vector_e2e.gd`)**: Validates continuous forward progression across Missions 1–8, level streaming residency, 7-state segment state machine, 28s watchdog encounter recovery, 9 original weapons with ballistic/projectile physics, 6 arcade modules, 10-state AI HFSM with squad coordination tokens, 8 multi-phase bosses, interactive set-pieces, checkpoint persistence, and grading calculator.
* **Universal Launcher (`test_launcher_e2e.gd`, `test_responsive_ui.gd`)**: Validates 8-game carousel navigation, game metadata previews, responsive screen scaling, and hot-swapping.

---

## 4. Running Tests with Podman

### Run Full Test Suite:
```bash
# PowerShell
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd

# Or via helper script
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```

### Run Performance Benchmarks:
```bash
# PowerShell
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/benchmark/test_benchmark.gd

# Or via helper script
powershell -ExecutionPolicy Bypass -File scripts/benchmark.ps1
```

### Run Full Production Certification:
```bash
# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/validate-production.ps1
```

---

## 5. Coverage Registry & Verification Matrix

VoltArena implements an explicit `CoverageRegistry` in `tests/runner.gd` that scans all `.gd` production files, counts callable functions and lifecycle hooks, and cross-references them against test coverage registrations.

### Test & Verification Summary:
- **Total Test Suites**: 61 suites
- **Total Assertions**: 1,886 passed, 0 failed (**100% pass rate**)
- **Function Coverage**: **95.04% (785 / 826 functions covered)**
- **Measured Sim FPS**: **1028.8 FPS** (P50: 0.97ms, P95: 1.47ms, P99: 1.79ms, 0 stutters)
- **Static Heap Memory**: 22.3 MB (well within 500 MB budget)
- **Procedural Generation**:
  - Arena Map: 75.8 ms
  - Subway Tunnel: 540.4 ms
  - Kart Track: 362.6 ms
  - Skybound World: 3.4 ms
  - RoboForge Workshop: 0.6 ms
  - WildCircuit Biomes: 3.4 ms
  - Rocket Stadium: 1.2 ms
- **Time-To-Playable (All 8 Games)**:
  - ArenaFPS: 317.2 ms
  - KartRacing: 0.4 ms
  - RoboForgeArena: 1.0 ms
  - RocketCar: 0.6 ms
  - SkyboundOdyssey: 0.7 ms
  - SubwaySurvival: 437.1 ms
  - WildCircuit: 0.7 ms
  - StrikeVector: 2.1 ms
- **Certification Status**: `RUNTIME_VERIFIED` (0 failures across all 61 automated gates)
