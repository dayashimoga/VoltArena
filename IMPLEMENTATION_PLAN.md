# VOLTARENA — MASTER PRODUCTION IMPLEMENTATION PLAN
## Dual Title Rebuild & Productionization: AeroRush & Chroma Rush (v10.0.0)

**Roles**: Principal Godot Game Architect, Vehicle Physics/Gameplay Engineer, Technical Artist, 3D Environment Designer, UI/UX Lead, Performance Engineer, QA and DevOps Lead  
**Repository**: `dayashimoga/VoltArena` (`games/aero-rush`, `games/chroma-rush`, `shared/`, `platform/`, `launcher/`)  
**Engine & Target Platforms**: Godot 4.3 Stable (Windows x86_64, Linux x86_64, macOS, WebGL/WASM Cloudflare Pages, Android ARM64, iOS)  
**Date**: October 2026  
**Status**: ACTIVE PHASED EXECUTION — PHASE P0 FORENSIC AUDIT COMPLETE

---

## 1. Executive Summary & Forensic Audit Matrix

This master production implementation plan establishes the architectural specifications, prioritized tasks, root-cause fixes, quantitative gates, and verification evidence required to audit, fix, rebuild, visually overhaul, enhance, optimize, and productionize **AeroRush** and **Chroma Rush**, while preserving all 10 VoltArena titles without regressions.

### 1.1 Forensic Defect Forensics & Traceability Matrix

| Defect ID | Game | Observed Symptom | Severity | Root-Cause Analysis | Corrective Architectural Task | Verification Test & Quantitative Gate |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| **DEF-CR-01** | Chroma Rush | Sluggish / Disconnected Acceleration | P1 | In `chroma_vehicle.gd`, catalog acceleration was set to raw 28–34 m/s² with instant arcade lerp instead of realistic power-curve gearing, torque-band slip, and progressive throttle curves; in low framerates or wheel slip, forward speed was hard clamped by slide collision normals (`normal.dot(fwd) < -0.35`). | Implement speed-sensitive torque curve, progressive gearing, longitudinal tire friction slip model, and decouple drive force from micro-snag collision normals. Calibrate default car (Apex Striker) 0–60 km/h acceleration target strictly within 4.0–8.0 seconds. | Seeded acceleration benchmark `test_chroma_vehicle_physics.gd`: 0–60 km/h in 4.0–8.0 s; P95 throttle-to-acceleration response $\le 100\text{ ms}$. |
| **DEF-CR-02** | Chroma Rush | Camera Zoom Oscillation & FOV Drift | P1 | In `chroma_rush_main.gd:554-565`, camera FOV was dynamically recalculated from instantaneous noisy speed without deadband filtering, and camera distance was subject to linear spring arm updates causing breathing/pumping artifacts during acceleration and curb hops. | Architect dual-stage low-pass filtered camera tracking with a dedicated 1.2 m/s deadband, fixed authoritative chase distance, rate-limited FOV transition ($\le 3.5^\circ/\text{s}$), and decoupled vertical chassis pitch chatter. | `test_chroma_camera_stability.gd`: Camera-distance oscillation $\le 1.0\%$; unintended FOV drift $\le 0.5^\circ$ across 600 steady driving frames. |
| **DEF-CR-03** | Chroma Rush | Poor Steering Response & Cornering Snapping | P1 | In `chroma_vehicle.gd:312-328`, steering used crude linear smoothing rate with step-damped cornering ratios that caused input lag at low speeds and sudden twitching at high speeds. | Implement speed-sensitive Ackermann-approximated steering curve with exponential smoothing ($1.0 - e^{-k\Delta t}$) ensuring snappy response at low speeds and high-speed directional stability. | Input telemetry verification: P95 steering response $\le 100\text{ ms}$; zero oscillation on straight line driving. |
| **DEF-CR-04** | Chroma Rush | Sparse Miniature City, Tiny Trees & Empty Terrain | P0 | In `neon_city.gd:320-350`, single buildings were spawned at sparse 12-sample intervals (60–80m apart) alternating sides with a massive 28m setback from road curbs, leaving vast empty green voids (`PlaneMesh 1800m`); trees were placed as tiny 1.2m props without urban tree grates; lack of multi-tier street grid, dense city blocks, facades, sidewalks, storefronts, and perimeter skyscrapers. | Completely rebuild metropolis generation: Implement dense multi-tier urban blocks, continuous sidewalk infrastructure, $\ge 12$ distinct building archetypes, $\ge 30$ facade variations, $\ge 6$ vegetation archetypes (oak, palm, pine, maple, birch, cypress) scaled believably ($6\text{m}–14\text{m}$), urban streetlights, crosswalks, detailed district plazas, and 360° layered skyline. | Visual audit gate: $\ge 12$ building archetypes, $\ge 30$ facade variations, $\ge 6$ vegetation archetypes; scale within $\pm 15\%$ of specifications; $\ge 95\%$ forward-driving frames show route; zero unexplained empty terrain in approved camera views. |
| **DEF-CR-05** | Chroma Rush | Obstructive HUD Overlays & Screen Clutter | P1 | In `chroma_hud.gd:84-180`, giant centered panels (`TargetColorBadge` + `GuidanceBanner` + bottom `SwapReticleBanner` + large minimap) obstructed $> 32\%$ of the active viewport, blocking the forward road line of sight and vehicle chassis. | Redesign HUD into an adaptive, ultra-clean glassmorphism telemetry layout: Compact unified top bar ($\le 12\%$ viewport obstruction), minimal bottom status indicator, non-obtrusive radar, and auto-dismissing contextual hints. | Viewport obstruction metric: Persistent HUD $\le 15\%$ of viewport area across all supported aspect ratios ($16:9$, $16:10$, $21:9$, $4:3$, mobile $19.5:9$). |
| **DEF-CR-06** | Chroma Rush | Trapped Sidewalk Spawns & Corrupted Recovery | P0 | In `neon_city.gd`, overlapping `SidewalkApron` geometry and flawed `_is_clear_of_spline` allowed off-road placement; in `chroma_vehicle.gd`, `last_valid_track_pos` recorded off-road positions whenever grounded, locking the player on sidewalks upon pressing `[R]`. | Decouple recovery from raw ground collision; query `active_world.get_nearest_safe_road_transform()` on authoritative spline centerline with forward tangent alignment; enforce strict $\ge 12\text{m}$ prop setback. | 100/100 seeded safe spawns and recoveries per game on drivable asphalt road corridor facing traffic direction. |
| **DEF-CR-07** | Chroma Rush | Core Gameplay Loop Completion & Invariants | P0 | Full gameplay chain: Find target $\to$ chase & match speed $\to$ atomic bidirectional swap $\to$ deliver to gate $\to$ score & reward $\to$ progress. | Harden `ColorSwapEngine` with atomic mutex semantics, strict validation of proximity ($<8\text{m}$), relative speed ($<12.5\text{ m/s}$), parallel alignment ($<38^\circ$), bidirectional state exchange, and reliable mission gates across all 24 missions. | 1,000/1,000 atomic swap trials without desync; $\ge 99\%$ AI route success over 1,000 seeded trials; 100% release-gating missions completable. |
| **DEF-AR-01** | AeroRush | Unintended Acceleration & Unstable Speeds | P1 | In `aero_vehicle.gd:717`, respawning hardcoded `forward_speed = 18.0` even when player had zero throttle input; boost pads and airtime multipliers accumulated without speed-cap damping, leading to uncontrollable cornering speeds ($> 85\text{ m/s}$). | Zero initial velocity on recovery; enforce progressive throttle curve, calibrated top speeds per vehicle class ($48–66\text{ m/s}$), aerodynamic drag, and speed-sensitive grip damping. | Zero unintended acceleration on spawn/recovery; speed stays within vehicle class spec envelope $\pm 5\%$. |
| **DEF-AR-02** | AeroRush | Recurring Stunt & Checkpoint Loops | P0 | In `aero_vehicle.gd:697-700`, `last_safe_checkpoint_pos` was dynamically updated every frame during normal driving whenever speed $> 10\text{ m/s}$, overwriting safe checkpoint data right at jump launch edges or moving platforms. Missing a jump caused respawn on the edge with 18 m/s speed, flying off repeatedly in an infinite loop. | Restrict `last_safe_checkpoint_pos` updates exclusively to authoritative `AeroCheckpoint` volumes and validated island entry aprons; never update on jump lips or kinetic platforms. | 100/100 test runs with missed jumps recover safely to previous stable platform with $2.5\text{s}$ safe grace; zero recurring loops. |
| **DEF-AR-03** | AeroRush | Track-Obstructing Skybridges & Flanking Buildings | P0 | In `aero_world_megacity.gd:218-232`, `TransMetropolitanSkybridge` was placed at $Y = 24.0\text{m}, Z = -130\text{m}$ across the track directly where Island 1 ramps up ($Y = 14–22\text{m}$), causing the car to crash into a 4.5m thick girder at eye level (`input_file_3.png`); commercial shops scaled 26x penetrated track clearance envelopes. | Elevate all architectural skybridges to $Y \ge 58.0\text{m}$ or relocate outside jump corridors; enforce $\ge 45\text{m}$ setback for all flanking skyscrapers; remove all miniature shops used as skyscrapers. | Automated track corridor probe: Zero track/scenery intersections; $\ge 10\text{m}$ vertical and $\ge 25\text{m}$ lateral clearance envelope across all 12 courses. |
| **DEF-AR-04** | AeroRush | Blinding Bloom & Overexposure Blowout | P1 | In `aero_world_base.gd:64-68`, ACES tonemap exposure was 1.15 with glow bloom 0.03, while `KICKER_SHADER_CODE` and `URBAN_GROUND_SHADER` used high emissive multipliers ($4.5\times$ and $2.8\times$), causing complete whiteout/yellow washouts on ramps and track faces (`input_file_4.png`). | Re-tune tonemapping and lighting: Set tonemap exposure to balanced 1.0, clamp shader emissions to $\le 2.0$, tune directional sun energy to 1.8 with ambient sky fill, and implement proper auto-exposure / bloom thresholds. | Visual luminance audit: Zero forward-driving frames exceed luminance threshold $> 0.92$ over $> 5\%$ of screen; clear road texture and boundary visibility. |
| **DEF-AR-05** | AeroRush | Camera Clipping into Elevated Decks & Buildings | P1 | In `aero_chase_camera.gd:157-170`, single raycast collision check failed when camera entered acute angles underneath elevated tracks or near wall-rides, causing the camera to snap or clip inside geometry. | Implement sphere-cast / multi-ray collision envelope with spring-damping and minimum near-plane clearance ($\ge 0.8\text{m}$) from any static track or world collider. | 1,000-frame camera collision stress test: Zero near-plane clipping through geometry; camera distance oscillation $\le 1\%$. |
| **DEF-AR-06** | AeroRush | Predominantly Continuous Tracks vs Disconnected Platforms | P0 | Courses 1–12 had islands defined but lacked genuine disconnected physical gap validation, distinct orientation changes, loops, wall-rides, corkscrews, kinetic moving platforms, and dynamic track-relative OOB kill planes. | Rebuild courses into genuinely disconnected floating platforms in 3D space with physically achievable ballistic jump gaps, launch kickers with animated chevrons, wide hazard-marked landing aprons, 360° loops, 75° wall rides, moving platforms, and dynamic OOB kill plane ($>8\text{m}$ below deck elevation). | Course audit: Reference course has $\ge 3$ separated platforms, $\ge 2$ real gaps, $\ge 1$ loop/banked curve; 100% mandatory jumps reachable; $\ge 95\%$ traversal success. |
| **DEF-AR-07** | AeroRush | Playable Diverse Biome Courses | P0 | Only 4 base worlds were implemented with prototype assets, failing to provide the full spectrum of distinct playable environments. | Author all 10 advertised distinct themes: City (Neo-Cascade Megacity), Snow (Snowbound Peaks), Beach (Tropical Coastal), Forest (Wild Forest), Mountain (Alpine Ridge), Desert/Canyon (Desert Extreme), Sky (Stratosphere Circuit), Alien Planet (Xenon Nebula), Space (Orbital Station), and Volcanic Underworld (Magma Core), each with unique shaders, atmosphere, track assets, and physics modifiers. | Every advertised theme independently loadable and playable with unique visual identity and verified completion. |

---

## 2. Quantitative Acceptance Criteria & Gates

Execution strictly follows these measurable PASS/FAIL gates:

```
[P0: AUDIT & TRACEABILITY] ➔ [P1: PHYSICS & CAMERA] ➔ [P2: CORE GAMEPLAY]
                                      ➔ [P3: 3D WORLD OVERHAUL] ➔ [P4: UX & CONTROLS]
                                      ➔ [P5: PERFORMANCE] ➔ [P6: PLATFORM BUILDS] ➔ [P7: QA & RELEASE]
```

### Gate P0: Forensic Audit Baseline (PASS)
- 100% of known issues traced to severity, reproduction, root-cause hypothesis, corrective tasks, and tests.
- Baseline recordings, architecture, gap analysis, and requirements traceability documented.

### Gate P1: Critical Physics & Camera Fixes
- **Spawns & Recoveries**: 100/100 seeded safe spawns and recoveries per game on valid road corridor.
- **Unintended Acceleration**: Zero unintended throttle/boost or speed drift at 0 throttle.
- **Track Intersections**: Zero track/scenery intersections or girder collisions in all 12 courses.
- **Checkpoint Loops**: Zero recurring event/checkpoint loops in 100 drop/crash scenarios.
- **Camera Distance Oscillation**: $\le 1.0\%$ steady-state variation; unintended FOV drift $\le 0.5^\circ$.
- **Steering Latency**: P95 input-to-steering response $\le 100\text{ ms}$.
- **Chroma Rush Acceleration**: Default car (Apex Striker) 0–60 km/h in 4.0–8.0 seconds, tunable by class.

### Gate P2: Core Gameplay Mechanics
- **AeroRush Course Topology**: Reference course has $\ge 3$ separated platforms, $\ge 2$ real ballistic gaps, $\ge 1$ loop/banked curve; 100% mandatory jumps and checkpoints reachable; $\ge 95\%$ calibrated-controller traversal success.
- **Chroma Rush Swap Engine**: 1,000/1,000 atomic color swaps without desync or missed triggers; $\ge 99\%$ AI route success over 1,000 seeded trials; 100% release-gating missions completable.
- **Packaged Runtime Loop**: Verified start $\to$ play $\to$ objective $\to$ reward loop in real web and desktop builds.

### Gate P3: Complete 3D Visual & World Overhaul
- **Placeholders & Clipping**: Zero unapproved placeholders, zero track clipping, zero blinding overexposure.
- **Architectural Scale**: Scale within $\pm 15\%$ of specifications ($3.5\text{m}$ floor-to-ceiling, proportional towers).
- **Urban Diversity**: Reference metropolis has $\ge 12$ building archetypes, $\ge 30$ facade variations, $\ge 6$ vegetation archetypes ($6\text{m}–14\text{m}$ tall).
- **Visual Guidance**: $\ge 95\%$ of sampled forward-driving frames show the route or clear visual guidance; zero unexplained empty terrain in approved camera views.
- **Themes**: All advertised AeroRush themes (City, Snow, Beach, Forest, Mountain, Desert, Sky, Alien, Space, Volcanic) independently playable.

### Gate P4: UX, Controls & Engagement
- **Viewport Layout**: Zero essential UI clipping or overlap across $360\times 800$ to $2560\times 1440$.
- **HUD Obstruction**: Persistent HUD area $\le 15\%$ of total viewport area.
- **Input Latency**: P95 input-to-visible-response $\le 100\text{ ms}$.
- **Input Accessibility**: 100% required actions accessible via Keyboard/Mouse, Gamepad, and Touch.
- **Save Integrity**: 100/100 save/load round trips without data loss or corruption.
- **Game Modes**: All advertised modes have tested start $\to$ objective $\to$ success/failure $\to$ reward flows.

### Gate P5: Performance Optimization
- **Desktop (1080p Ultra)**: $\ge 60\text{ FPS}$ average, $\ge 50\text{ FPS}$ 1% low.
- **Mobile (720p Medium)**: $\ge 30\text{ FPS}$ average, $\ge 25\text{ FPS}$ 1% low.
- **Frame Pacing**: $\le 1.0\%$ of frames exceed $2\times$ target frame time.
- **Memory Stability**: $\le 5.0\%$ sustained memory growth across repeated load/unload cycles.
- **Load Times**: Desktop gameplay load $\le 10\text{ s}$; mobile gameplay load $\le 20\text{ s}$.
- **Stability**: Zero crashes or hangs during 30-minute soak test.

### Gate P6: Cross-Platform Standalone Builds
- **Monorepo Suite**: Full VoltArena launcher build functional.
- **Standalone Builds**: 10 independently playable standalone builds exported for Windows, Linux, WebGL, Android.
- **CI Automation**: GitHub Actions workflows for Windows, Linux, macOS, Android APK, Web.
- **Verification**: Checksums, commit IDs, and launch smoke tests passing.

### Gate P7: Comprehensive QA & Production Certification
- **Automated Coverage**: $\ge 90\%$ function coverage across all game logic and shared subsystems.
- **Pass Rate**: 100% mandatory tests passing, 0 failed, 0 skipped release-blocking tests.
- **Defects Remaining**: P0 = 0, P1 = 0.
- **Certification**: `production-certification.json` with reproducible test commands and evidence paths.

---

## 3. Prioritized Phased Task Breakdown

### Phase P1: Critical Physics & Camera Fixes
- [ ] **Task P1.1 (CR-Physics)**: Refactor `chroma_vehicle.gd`:
  - Implement calibrated torque-band acceleration curve yielding 0–60 km/h in 4.0–8.0 s for Apex Striker (tunable per class).
  - Add progressive gearing, rolling drag, speed-sensitive braking ($36\text{ m/s}^2$), and longitudinal tire traction.
  - Fix wall collision clipping so vertical normals do not stall forward momentum on curbs.
- [ ] **Task P1.2 (CR-Steering)**: Implement speed-sensitive Ackermann steering curve with smooth exponential rate ($1.0 - e^{-12\Delta t}$) and P95 response $\le 100\text{ ms}$.
- [ ] **Task P1.3 (CR-Camera)**: Refactor Chroma Rush chase camera in `chroma_rush_main.gd`:
  - Fix camera distance to constant authoritative radius with deadband filter ($\pm 1.2\text{ m/s}$).
  - Rate-limit FOV transitions ($\le 3.5^\circ/\text{s}$) to eliminate zoom pumping (oscillation $\le 1\%$, drift $\le 0.5^\circ$).
  - Decouple chassis pitch/roll micro-chatter from camera orientation.
- [ ] **Task P1.4 (CR-Spawns/Recovery)**: Harden vehicle spawning and `[R]` recovery in `chroma_vehicle.gd` and `neon_city.gd`:
  - Always spawn and recover strictly on the road spline centerline facing tangent.
  - Never record sidewalk or off-road positions in `last_valid_track_pos`.
- [ ] **Task P1.5 (AR-Physics)**: Refactor `aero_vehicle.gd`:
  - Eliminate unintended acceleration: Zero forward speed on respawn/recovery unless user holds throttle.
  - Calibrate vehicle classes ($48–66\text{ m/s}$ top speed, progressive throttle, stable airborne pitch/yaw/roll authority).
- [ ] **Task P1.6 (AR-Recovery)**: Fix checkpoint loop defect in `aero_vehicle.gd`:
  - Record checkpoints ONLY when crossing dedicated `AeroCheckpoint` volumes and landing aprons.
  - Never record checkpoint on jump launch lips, ramps, or moving platforms.
  - Enforce dynamic OOB drop detection ($>8\text{m}$ below current island elevation).
- [ ] **Task P1.7 (AR-Camera)**: Refactor `aero_chase_camera.gd`:
  - Eliminate zoom oscillation during airtime/landing: Use continuous smooth exponential interpolation.
  - Implement multi-ray/sphere collision envelope preventing near-plane clipping through tracks and buildings.
- [ ] **Task P1.8 (AR-Obstructions)**: Fix track collision envelopes in `aero_world_megacity.gd`:
  - Elevate or remove `TransMetropolitanSkybridge` at $Z = -130\text{m}$ so flight corridors have $\ge 25\text{m}$ vertical clearance.
  - Enforce $\ge 45\text{m}$ setback for all flanking skyscrapers; remove miniature commercial shops from track margins.
- [ ] **Task P1.9 (AR-Exposure)**: Rebalance lighting and shaders in `aero_world_base.gd` and `aero_track_generator.gd`:
  - Normalize ACES tonemap exposure to 1.0, clamp bloom intensity to 0.15, clamp shader emissions to $\le 2.0$.
  - Eliminate blinding white/yellow blowouts on launch kickers and track surfaces.

### Phase P2: Core Gameplay Mechanics
- [ ] **Task P2.1 (AR-Courses)**: Verify and complete modular disconnected island graph for all 12 courses:
  - Reference course (Neon Express): $\ge 3$ disconnected platforms, $\ge 2$ real ballistic gaps, 360° vertical loop, 75° wall ride, kinetic moving platform.
  - 200 Hz ballistic validation ensuring 100% of jumps and landings are reachable within calibrated speed envelopes.
  - Provide protected driving corridors with containment curbs and glowing chevrons.
- [ ] **Task P2.2 (CR-Gameplay)**: Complete atomic color swap and mission progression:
  - Mutual alignment detection: Distance $<8\text{m}$, speed delta $<12.5\text{ m/s}$, angle $<38^\circ$, continuous lock $\ge 0.55\text{s}$.
  - Bidirectional atomic color exchange between player and target.
  - Delivery to checkpoint gates, scoring, combo multipliers, and mission completion.
  - Verify all 24 missions across Color Hunt, Chroma Sprint, Puzzle Drive, and Championship.

### Phase P3: Complete 3D Visual & World Overhaul
- [ ] **Task P3.1 (CR-Metropolis)**: Overhaul Neon City into a dense, coherent American-inspired metropolis:
  - Generate dense multi-tier urban blocks with connected sidewalks, commercial storefronts, and crosswalks.
  - Spawn $\ge 12$ distinct building archetypes using PBR materials (sapphire glass, limestone bronze, slate tech, brick masonry, art deco, concrete brutalist).
  - Add $\ge 30$ facade variations and $\ge 6$ realistic vegetation archetypes ($6–14\text{m}$ tall trees in sidewalk grates and parks).
  - Add street furniture: streetlights, traffic signals, fire hydrants, bus stops, benches, trash cans, billboards.
  - Eliminate all empty green voids: replace with textured urban asphalt, plaza paving, and distant 360° skyline.
- [ ] **Task P3.2 (AR-Themes)**: Complete 10 distinct playable themed environments in AeroRush:
  - 1. Megacity / Neon Afterdark (Cyberpunk skyscrapers, illuminated canals)
  - 2. Snowbound Peaks (Alpine snow, ice lakes, pine forests, snowfall)
  - 3. Tropical Coastal (Beaches, palm trees, ocean waves, coastal cliffs)
  - 4. Wild Forest (Dense redwood/oak forests, waterfalls, mossy boulders)
  - 5. Desert Extreme / Canyon (Red rock mesas, sandstone arches, sand dunes)
  - 6. Stratosphere Sky Circuit (Cloud decks, floating atmospheric pylons, solar arrays)
  - 7. Alpine Mountain Ridge (Sharp granite peaks, windy passes, avalanche sheds)
  - 8. Xenon Alien Planet (Bioluminescent flora, purple skies, crystal spires)
  - 9. Orbital Space Station (Zero-g starfield, solar sails, docking rings)
  - 10. Magma Core / Volcanic (Lava rivers, obsidian pillars, ember storms)

### Phase P4: UX, Controls & Engagement
- [ ] **Task P4.1 (CR-HUD)**: Redesign Chroma Rush HUD:
  - Compact glassmorphism top telemetry bar combining current color, target color, time, and score.
  - Non-obtrusive target locator arrow / radar pip replacing giant center banners ($\le 12\%$ viewport obstruction).
  - Mobile touch controls overlay with virtual stick and responsive swap button.
- [ ] **Task P4.2 (AR-HUD)**: Audit and polish AeroRush HUD:
  - Speedometer card, top-center stunt indicator, and course progression bar cleanly separated.
  - Combo badge and checkpoint progress bar with responsive anchoring across all screen resolutions.
- [ ] **Task P4.3 (Controls & Settings)**: Verify unified input mapping, gamepad controller support, configurable sensitivity, audio volume sliders, graphics presets, pause/retry menus, and persistent career saves.

### Phase P5: Performance Optimization
- [ ] **Task P5.1 (Profiling & LOD)**: Implement distance-based LOD and mesh culling for distant city blocks and trees.
- [ ] **Task P5.2 (Batching & Shaders)**: Consolidate materials, use MultiMeshInstance3D for repetitive street furniture and foliage.
- [ ] **Task P5.3 (Presets & Soak)**: Configure Low, Medium, High, Ultra graphics presets; run 30-minute soak test verifying zero memory leaks ($< 500\text{ MB}$).

### Phase P6: Cross-Platform Builds & CI
- [ ] **Task P6.1 (Standalone Packages)**: Verify `scripts/modular_packager.py` exports standalone PCKs for all 10 titles.
- [ ] **Task P6.2 (Web Export)**: Verify chunked WebGL build ($\le 18\text{ MB}$ per file) compatible with Cloudflare Pages.
- [ ] **Task P6.3 (CI Workflows)**: Audit GitHub Actions workflows for multi-platform builds and smoke tests.

### Phase P7: Comprehensive QA & Release Certification
- [ ] **Task P7.1 (Test Suites)**: Run all 80+ automated unit, integration, and E2E test suites with 100% pass rate.
- [ ] **Task P7.2 (Visual & Gameplay Evidence)**: Run Playwright runtime capture suites recording real screenshots and telemetry.
- [ ] **Task P7.3 (Certification)**: Update `production-certification.json`, `IMPLEMENTATION_WALKTHROUGH.md`, `CHANGELOG.md`, `TODO.md`.

---

## 4. Verification & Testing Commands

1. **Automated Test Suite (Full Monorepo)**:
   ```powershell
   podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
   ```
2. **Chroma Rush Dedicated Unit & E2E Suites**:
   ```powershell
   podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd --filter="Chroma"
   ```
3. **AeroRush Dedicated Unit & E2E Suites**:
   ```powershell
   podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd --filter="Aero"
   ```
4. **Playwright Real-Device Visual Evidence Capture**:
   ```powershell
   python scripts/capture_chroma_rush_evidence.py
   python scripts/capture_aero_rush_evidence.py
   python scripts/capture_overhauled_games_evidence.py
   ```
5. **Standalone Packager & Production Certification**:
   ```powershell
   python scripts/modular_packager.py
   python scripts/certifier.py
   ```
