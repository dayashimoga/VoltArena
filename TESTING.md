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
├── Unit Test Suites (46 Suites)
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
│   ├── TestDriftStormStateMachine (35 assertions: 11-stage state machine transitions, menu race world isolation, 6 circuits metadata, 5 vehicle radar stats, countdown start)
│   ├── TestCrossPlatformArchitecture (19 assertions: PlatformCapabilities, InputProfile, GraphicsProfile, TouchControls)
│   ├── TestStrikeCampaignUnit (65 assertions)
│   ├── TestStrikePlayerUnit (60 assertions)
│   ├── TestStrikeAIUnit (85 assertions)
│   ├── TestStrikeTraversalProbes (98 assertions)
│   ├── TestStrikeVisualInvariants (100 assertions: transforms, rigs, sockets, nav mesh, HUD)
│   └── TestStrikeRuntimeAcceptance (25 assertions: 100-shot firing pose stability, weapon grip alignment, physical projectile damage, obstacle blocking, metric scale, HUD threat indicator, roadway continuity)
├── Responsive & Soak Suites (2 Suites)
│   ├── TestResponsiveUI (297 assertions across all 9 canonical viewport gates from 360x800 to 2560x1440)
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
│   ├── TestStrikeVectorE2E (224 assertions across Missions 1–8)
│   └── AeroRush Dedicated Suites (6 Suites, 197 assertions)
│       ├── test_aero_physics_unit.gd (34 assertions)
│       ├── test_aero_stunt_and_combo_unit.gd (33 assertions)
│       ├── test_aero_tracks_and_worlds_unit.gd (40 assertions)
│       ├── test_aero_ai_and_modes.gd (20 assertions)
│       ├── test_aero_e2e.gd (45 assertions)
│       └── test_packaged_aerorush_e2e.gd (25 assertions)
└── Legacy Acceptance Suite (1 Suite, 19 assertions)
    └── TestPlatformAcceptance
─────────────────────────────────────────────────────────────
Total: 80 Suites, 3,051 Assertions (100% Pass, 0 Failures, 90.6% Real Function Coverage)
```

---

## 3. Test Suites Overview

### 3.1 Shared Subsystem Suites
* **`test_quest_system.gd`**: Validates `QuestManager` lifecycle: registration, prerequisite enforcement, multi-stage objective updates, stage completion events, reward dispatches, and serialization/deserialization.
* **`test_inventory_system.gd`**: Validates `InventorySystem`: stack limits, item additions/removals, weight limits, gear slot equipment, and traversal capability unlocks.
* **`test_puzzle_elements.gd`**: Validates physics-driven `PressurePlate` activation, `PuzzleSwitch` toggling, `PuzzleDoor` locking/unlocking, and `WindCurrent` lift impulses.
* **`test_engine_subsystems.gd`**: Validates `OrbitCamera3D` raycasting collision avoidance, `DayNightCycle3D` 24-hour celestial orbit and lighting transitions, and `InteractionArea3D` prompt triggering.
* **`test_cross_platform_architecture.gd`**: Validates `PlatformCapabilities` (OS detection, safe-area insets, aspect ratio categorization, performance tiering, minimum 48dp touch target enforcement), `InputProfile` (genre input mappings and dynamic action prompt resolution), `GraphicsProfile` (Low, Medium, High, Ultra, Auto presets and strict 60Hz physics invariant), and `TouchControls` (adaptive genre layouts and desktop auto-hide).

### 3.2 8-Game Unit & E2E Suites
* **Iron Crucible (`test_weapons_system.gd`, `test_arena_bot.gd`, `test_arena_e2e.gd`)**: Validates all 5 weapon ballistics, bot navigation/firing/kill-plane recovery, Citadel/Foundry/Sektor perimeter seals, and 5 game modes.
* **Metro Siege (`test_enemy_archetypes.gd`, `test_wave_director.gd`, `test_subway_e2e.gd`)**: Validates 5 mutant archetypes (including BioColossus 1,200 HP boss), 10-wave horde escalation, scrap economy, kiosk upgrades, and train evacuation.
* **Nitro Kick (`test_car_physics.gd`, `test_ball_physics.gd`, `test_nitro_kick_p0_gates.gd`, `test_nitro_kick_e2e.gd`)**: Validates canonical $-Z$ coordinate hierarchy, normalized imported GLTF meshes under `VisualRoot`, 4 authentic vehicle archetypes (Apex Spectre, Dune Raider, Titan Enforcer, Volt Pulse), single-impulse CCD ball physics without double-velocity glitches, regulation $110\text{m} \times 64\text{m} \times 20\text{m}$ stadium with $45^\circ$ octagonal corners, net cages, 34 boost pads, MultiMesh crowd, and dynamic role-based AI (Striker/Support/Defender/Goalkeeper) with predictive lead intercept convergence.
* **Drift Storm (`test_kart_controller.gd`, `test_race_manager.gd`, `test_drift_storm_state_machine.gd`, `test_drift_storm_corridor_gates.gd`, `test_drift_storm_runtime_acceptance.gd`, `test_drift_storm_e2e.gd`)**: Validates the 11-stage scene state machine (`DriftHome` to `Finished`), strict visual and processing isolation of 3D race entities during pre-race menus, 4-wheel raycast suspension telemetry, single `RaceSpline` authority model, 6 global production circuits with automated corridor clearance verification (0 intrusions), 5 vehicle classes, responsive Championship Pre-Race Hub with vector track spline preview canvas, always-visible bottom navigation bar across all 9 canonical viewports, authoritative wrong-way detection with hysteresis, and continuous progress sorting.
* **Skybound Odyssey (`test_skybound.gd`, `test_skybound_e2e.gd`)**: Validates locomotion, variable jump, double jump, ledge mantling, glider flight aerodynamics, grapple mechanics, 5 interconnected regions, and shard collection.
* **RoboForge Arena (`test_roboforge.gd`, `test_roboforge_e2e.gd`)**: Validates 3 chassis types, 3 drive types, 3 power cores, 5 functional tools, dynamic mass/speed/torque recalculation, 3D workshop bay, and 7 challenge courses.
* **WildCircuit (`test_wildcircuit.gd`, `test_wildcircuit_e2e.gd`)**: Validates 5 biomes, 9 animal species with 8-state finite state machines, optical viewfinder photography (24-300mm zoom), deterministic photo scoring, and expedition ATV traversal.
* **Strike Vector (`test_strike_campaign_unit.gd`, `test_strike_player_unit.gd`, `test_strike_ai_unit.gd`, `test_strike_visual_invariants.gd`, `test_strike_runtime_acceptance.gd`, `test_strike_vector_e2e.gd`)**: Validates continuous forward progression across Missions 1–8, level streaming residency, 7-state segment state machine, 28s watchdog encounter recovery, 9 original weapons with ballistic/projectile physics, 6 arcade modules, 10-state AI HFSM with squad coordination tokens, 8 multi-phase bosses, interactive set-pieces, checkpoint persistence, and grading calculator.
* **Universal Launcher (`test_launcher_e2e.gd`, `test_responsive_ui.gd`)**: Validates 8-game carousel navigation, game metadata previews, responsive screen scaling across 9 viewports (360x800 to 2560x1440), and hot-swapping.
* **Chroma Rush (`test_color_swap_engine.gd`, `test_chroma_vehicle_physics.gd`, `test_chroma_ai_and_traffic.gd`, `test_chroma_worlds_and_integration.gd`, `test_mission_solvability.gd`, `test_chroma_modes_and_progression.gd`, `test_chroma_e2e.gd`)**:
  - Validates atomic bidirectional color conservation in `ColorSwapEngine` (41 assertions).
  - Validates 4-wheel suspension raycast dynamics, PBR clearcoat shaders, reactive brake ($4.8\times$) and reverse lights, and auto-righting rollover recovery in `ChromaVehicle` (44 assertions).
  - Validates waypoint tracking across 32 waypoints, traffic yields, dynamic pursuit evasion ($<35\text{m}$), and rival AI racing in `TrafficAgent` and `RivalAI` (21 assertions).
  - Validates continuous spline road ribbons, 24m gantry clearance, 12m organic tree setbacks, 6 distinct districts (Downtown, Commercial, Industrial, Neon, Waterfront, Historic), 64-building GPU MultiMesh perimeter ring ($R=540\text{m}$), `WorldAuditTool` 0-obstruction scans (0 blocked, 0 intruding), and forward/reverse autonomous bot driving traversals in `NeonCity` (45 assertions).
  - Validates solvability of all 24 handcrafted missions across 4 modes in `MissionDatabase` (35 assertions).
  - Validates mission briefing cards, bottom-center auto-fading reticle, and camera FOV shockwave VFX in `ChromaRushMain` and `ChromaHUD`.
  - Validates full end-to-end driving, swap execution, scoring, and persistence in `ChromaRush` (53 assertions).
* **AeroRush: Impossible Circuit (`test_aero_physics_unit.gd`, `test_aero_stunt_and_combo_unit.gd`, `test_aero_tracks_and_worlds_unit.gd`, `test_aero_ai_and_modes.gd`, `test_aero_e2e.gd`, `test_packaged_aerorush_e2e.gd`)**:
  - Validates 4-wheel raycast suspension kinematics, boost acceleration, handbrake drift, mid-air gyroscopic pitch/roll/yaw attitude control, and fall recovery cooldown grace in `AeroVehicle` (34 assertions).
  - Validates stunt detection (barrel rolls, flips, airtime, loops, wall-rides) and dynamic combo multipliers ($x1.0 - x5.0$) in `AeroStuntTracker` (33 assertions).
  - Validates modular platform island mesh synthesis, launch kickers, flared landing aprons, kinetic `AnimatableBody3D` moving platforms, and all 6 biome environments (Snow, Forest, Skyline, Desert, Neon, Megacity) in `AeroTrackGenerator` and world classes (40 assertions).
  - Validates 200 Hz numerical ballistic solver reachability, trajectory banking rotation, ascent safeguards, and curve angle thresholds ($<85^\circ$) across all 12 circuits in `AeroTrackValidator` and `AeroCourseDatabase` (20 assertions).
  - Validates decoupled 3-mode camera transitions (Chase, Hood, Orbit), glass-card HUD telemetry, and campaign progression in `AeroRushMain` and `AeroHUD` (45 assertions).
  - Validates packaged standalone runtime PCK launch integrity, zero missing dependencies, and full mission cycle in `TestPackagedAeroRushE2E` (25 assertions).

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
- **Total Test Suites**: 80 suites
- **Total Assertions**: 3,051 passed, 0 failed (**100% pass rate**)
- **Function Coverage**: **90.6% (1,085 / 1,198 functions covered)**
- **Measured Sim FPS**: **728.9 FPS** (P50: 1.37ms, P95: 2.36ms, P99: 3.10ms)
- **Static Heap Memory**: 21.3 MB (well within 500 MB budget)
- **Procedural Generation**:
  - Arena Map: 75.8 ms
  - Subway Tunnel: 540.4 ms
  - Kart Track: 362.6 ms
  - Skybound World: 3.4 ms
  - RoboForge Workshop: 0.6 ms
  - WildCircuit Biomes: 3.4 ms
  - Rocket Stadium: 1.2 ms
  - Neon City Metropolis: 42.1 ms
  - AeroRush Modular Islands & Biomes: 38.2 ms
- **Certification Status**: `RUNTIME_VERIFIED` (0 failures across all verification gates)


