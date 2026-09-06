# VoltArena — Automated Testing & Quality Assurance Guide

## 1. Testing Philosophy
VoltArena enforces strict quality gates:
1. **100% Pass Rate**: No failed assertions are permitted.
2. **>90% Code Coverage**: Core gameplay, combat, physics, and state machines must exceed 90.0% test coverage.
3. **Headless Execution**: All tests execute in headless Godot within a Podman container.
4. **Hermetic Preloading**: Test scripts use `const Script = preload(...)` to ensure test execution is resilient even before autoload tree attachment.

---

## 2. Test Architecture

The automated test runner is located at `tests/runner.gd`. When executed, it runs:

```
tests/runner.gd
├── Unit Test Suites (31 Suites, 530 assertions)
│   ├── TestHealthComponent, TestWeapons, TestCarPhysics, TestRaceManager, TestSaveManager
│   ├── TestWaveDirector, TestInputManager, TestAudioManager, TestQualityManager, TestEventBus
│   ├── TestMaterialGenerator, TestArenaBot, TestEnemyBase, TestKartController, TestBallPhysics
│   ├── TestSaveCorruption, TestSettingsManager, TestTelemetryManager, TestPlatformAdapter
│   ├── TestPhysicsHelpers, TestAIBase, TestProjectile, TestPickupBase, TestMapGenerators
│   ├── TestUISystems, TestGameManager, TestFXFactory, TestMeshBuilder, TestLauncherArt
│   ├── TestNodePool, TestProceduralAnimator, TestModelCache
├── Responsive & Soak Suites (2 Suites, 100 assertions)
│   ├── TestResponsiveUI (95 assertions across 5 resolutions)
│   └── TestSoak (5 full lifecycle clean runs)
├── E2E Gameplay Test Suites (6 Suites, 208 assertions)
│   ├── TestArenaE2E (48 assertions)
│   ├── TestSubwayE2E (29 assertions)
│   ├── TestRocketE2E (29 assertions)
│   ├── TestKartE2E (31 assertions)
│   ├── TestLauncherE2E (56 assertions)
│   └── TestGameplayScreens (32 assertions)
└── Legacy Acceptance Suite (2 Suites, 19 assertions)
    └── TestPlatformAcceptance (19 assertions)
─────────────────────────────────────────────────────────────
Total: 41 Suites, 857 Assertions (100% Success, 94.35% Function Coverage: 401/425)
```

---

## 3. Test Suites Overview

### 3.1 Unit Test Suites (`tests/unit/`)
* **`test_health_component.gd`**: Validates health and armor initialization, damage absorption formula ($65\%$ absorbed by shield), lethal damage transition, death signal emission, healing clamp, and reset states.
* **`test_weapons.gd`**: Validates all 5 weapon configurations:
  * Ammo consumption per shot.
  * Reload timings and clip refill from reserve.
  * Empty clip firing prevention.
  * Hitscan raycast validation.
  * Projectile spawning and explosive area damage falloff.
* **`test_car_physics.gd`**: Validates forward driving acceleration, emergency braking, speed clamping, nitrous boost consumption rate, and vertical jump impulses.
* **`test_race_manager.gd`**: Validates sequential checkpoint enforcement, rejection of out-of-order checkpoints, lap increments, wrong-way detection, and race completion triggers.
* **`test_save_manager.gd`**: Validates profile serialization to `user://savegame.json`, high-score tracking, round stat recording, and corruption recovery.
* **`test_wave_director.gd`**: Validates wave count escalation, spawn budget scaling ($6 \times 1.25^{\text{wave}}$), intermission phase transitions, and survival completion.

### 3.2 Acceptance Test Suite (`tests/acceptance/`)
* **`test_platform_acceptance.gd`**: Instantiates and validates all 4 main game scenes headlessly:
  * Boots `ArenaFPSMain`, verifies player and 3 bot instantiations, fires active weapon, confirms ammo decrement, applies lethal damage to bot, and verifies bot death state.
  * Boots `SubwayMain`, verifies subway generator, initializes `WaveDirector`, and triggers wave progression.
  * Boots `RocketCarMain`, checks player car and AI car spawn states, launches ball, and tests goal triggers.
  * Boots `KartRacingMain`, checks circuit track generation, spawns participant karts, and advances checkpoints.

---

## 4. Running Tests with Podman

### Run Full Test Suite:
```bash
# Bash
bash scripts/test.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```

### Run Code Coverage Audit:
```bash
# Bash
bash scripts/coverage.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/coverage.ps1
```

### Run Platform Acceptance Tests:
```bash
# Bash
bash scripts/acceptance.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/acceptance.ps1
```

---

## 5. Adding New Tests

To add a new unit test suite:
1. Create `tests/unit/test_<feature>.gd` inheriting `RefCounted`.
2. Implement `run_tests() -> Dictionary` returning `{"passed": int, "failed": int}`.
3. Register the suite in `tests/runner.gd`:
   ```gdscript
   const TestFeatureScript = preload("res://tests/unit/test_feature.gd")
   # In _init():
   run_suite("Feature Unit Tests", TestFeatureScript.new())
   ```
4. Re-run `bash scripts/test.sh` to ensure all gates remain at 100% pass!

---

## 6. Empirical Packaged-Runtime Acceptance & Visual Semantic Gates

Rather than declaring production readiness solely from headless tests, code presence, or function coverage, VoltArena enforces authoritative **Packaged-Runtime Behavioral Acceptance**:

```bash
# Capture full 48-state packaged runtime evidence (Playwright Chromium against WebGL2 engine):
python scripts/capture_real_runtime_evidence.py

# Audit all 53 real hardware-accelerated frames against empirical visual gates:
python scripts/certifier.py
```

### 6.1 Packaged Runtime Render-Health Gates (G9):
1. **Resolution**: Framebuffer dimensions $\ge 1280 \times 720$.
2. **Mean Luminance**: $\mu_{\text{lum}} \in [15.0, 220.0]$ (prevents total render darkness or blinding whiteouts).
3. **RMS Contrast**: $\sigma_{\text{lum}} \ge 18.0$ (guarantees dynamic illumination and material separation).
4. **Black Pixel Ceiling**: $P(\text{lum} < 10.0) \le 65.0\%$ (calibrated for nocturnal sci-fi skyboxes and atmospheric subway tunnels).
5. **HUD Lifecycle Isolation**: Active overlay dismissal cleanly unloads onboarding canvas without blocking gameplay viewports.

### 6.2 Human Reference-Board Visual Acceptance (G10):
Per project quality mandates, automated luminance and pixel tests are **render-health tests only** and do not constitute visual certification. G10 mandates human reference-board comparison against the 4 expected reference targets:
* **Reference 1 vs `iron_01_spawn.png`**: Glowing cyan regular hex grid, monolith columns, warm amber portal archway, first-person sci-fi weapon.
* **Reference 2 vs `metro_01_station_spawn.png`**: Grimy subway tiles, yellow safety edge, fluted cast-iron columns, fluorescent lighting, 24m passenger train, mutant spawns.
* **Reference 3 vs `nitro_01_kickoff.png`**: Manicured turf stripes, goal nets, elevated spectator stands, floodlights, detailed rocket cars.
* **Reference 4 vs `drift_01_start_grid.png`**: Start/finish gantry with checkered banner, 5-lamp start sequence, ripple kerbs, grandstands, racing karts with helmeted drivers.
* **Status**: G0–G9 **RUNTIME_VERIFIED**; G10 **HUMAN-VALIDATION-REQUIRED**.

### 6.3 Test & Verification Summary:
- **Total Test Suites**: 41
- **Total Assertions**: 857 passed, 0 failed (100% pass rate)
- **Function Coverage**: 93.91% (401 / 427 functions covered)
- **Sim Benchmark FPS**: 986.2 FPS (P50: 1.01ms, P95: 1.66ms, P99: 2.14ms, 0 stutters)
- **Packaged Screenshots**: 53 / 53 passed render-health thresholds
- **Contact Sheets Generated**:
  - `artifacts/screenshots/visual_contact_sheet.png` (Flagship 5-screen composite)
  - `artifacts/screenshots/contact_sheet.html` (Full interactive visual audit dossier)
- **Overall Certification Exit Code**: 0 (`scripts/certifier.py`)



