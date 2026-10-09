# IMPLEMENTATION PLAN: VOLTARENA AERORUSH PRODUCTION OVERHAUL

**Role**: Principal Game Architect, Senior Godot Engineer, Physics/Vehicle Simulation Engineer, Technical Artist, Level Designer, Gameplay Designer, UI/UX Director, Performance Engineer, QA Lead & Release Engineer  
**Repository**: `dayashimoga/VoltArena` (`games/aero-rush`)  
**Engine & Target**: Godot 4.3 Stable (Desktop Windows/Linux/macOS, Web, Mobile)  
**Date**: October 2026  
**Status**: ACTIVE EXECUTION PLAN (IN PROGRESS)

---

## 1. Executive Summary & Forensic Defect Analysis

AeroRush is VoltArena's premier 3D arcade stunt-driving game. Forensic inspection of actual packaged builds, gameplay logs, and user-supplied screenshots reveals deep architectural defects that prevent AeroRush from functioning as a true commercial-grade arcade stunt game:

### Defect Evidence & Forensic Audit

1. **Defect 1: Continuous Highway Dependency & Absence of Genuine Gaps (`input_file_3.png` Gap Concept)**:
   - *Observation*: Tracks largely consist of continuous elevated highways. Only Course 1 had an experimental island partition; Courses 2–12 used single continuous Catmull-Rom ribbons without genuine physical gaps.
   - *Root Cause (RC-34)*: `aero_course_database.gd` defined courses 2–12 without `islands` definitions. `aero_track_generator.gd` generated continuous collision and meshes. The core gameplay loop lacked genuine platform-to-platform ballistic jumps where the vehicle must traverse empty airspace without invisible bridges.
   - *Required Solution*: Modular stunt platform graph with explicit islands: Launch Platforms, Upward Kicker Ramps, Genuine Ballistic Gaps (no collision/mesh in air), Wide Catch Landing Aprons with hazard stripes, 360° Vertical Loops, Banked/Wall-Ride Sections, Moving/Rotating Platforms, Precision Jumps, and Grand Finish Stadium Platforms.

2. **Defect 2: Floating Sky Beacons & Repetitive Miniature Architecture (`input_file_0.png`, `input_file_1.png`)**:
   - *Observation*: The sky contains an arc of 6–7 glowing orbs floating in mid-air looking like duplicate moons. The ground basin is populated by miniature low-poly dollhouse buildings with tiny doors and windows scattered on an empty flat plane below an enormous highway on giant pillars.
   - *Root Cause (RC-35)*: In `aero_world_megacity.gd` lines 288–301, perimeter skyline buildings were spawned with `beacon.position = Vector3(0, 45.0, 0)` under a building scale of 5.5x, causing beacons to float isolated 247m in the sky with no visible structure attached. Ground buildings used low-poly house models (`building_a.glb`) scaled down to 2.5m–3.5m, looking absurdly tiny under a 16m-wide highway.
   - *Required Solution*: Eliminate rogue floating beacons completely. Enforce sky composition with exactly ONE coherent sun (and ONE moon for night). Replace miniature dollhouse buildings with proportional skyscrapers (50m–140m), commercial plazas, grandstands, and realistic trees.

3. **Defect 3: Missing Biomes & Environmental Monotony**:
   - *Observation*: Only 4 generic environments were implemented, and they lacked visual identity, terrain variety, and weather effects.
   - *Root Cause (RC-36)*: `AeroConstants.EnvironmentType` only had 4 types. Missing the 6 required distinct biomes specified in the prompt:
     1. **Snowbound Peaks**: Snow mountains, alpine forests, frozen lakes, icy cliffs, snowfall, suspended mountain tracks.
     2. **Coastal Velocity**: Beaches, tropical vegetation, oceans, cliffs, resorts, coastal bridges, sea spray.
     3. **Wild Forest**: Dense realistic forests, mountains, waterfalls, rocks, rivers, greenery, natural terrain.
     4. **Skyline Rush**: Believable modern cities, varied architecture, rooftop routes, skyscrapers, roads, urban landmarks.
     5. **Desert Extreme**: Canyons, dunes, rock formations, desert highways, dust effects, cliff jumps.
     6. **Neon Afterdark**: Detailed futuristic urban environments with controlled neon illumination and night-time stunt tracks.
   - *Required Solution*: Implement full procedural/PBR world generators for all 6 biomes with tailored terrain shaders, lighting, sky, vegetation, architecture, audio, and weather particles.

4. **Defect 4: UI Clipping & Outdated Telemetry (`input_file_2.png`, `input_file_4.png`)**:
   - *Observation*: `input_file_2.png` shows yellow text `RUSH!` cropped and overlapping `0 KM/H` at the top left of the screen. The telemetry display was basic and lacked modern game UI aesthetics.
   - *Root Cause (RC-37)*: In `aero_hud.gd`, countdown and toast labels had inappropriate anchor offsets displacing text into negative viewport space.
   - *Required Solution*: Full UI redesign matching the modern glass card HUD in `input_file_4.png`:
     - Top-Left: Speedometer (`182 KM/H`) + Nitro gauge.
     - Top-Center: Next Stunt / Jump (`NEXT: MEGA JUMP 240 m ahead`).
     - Top-Right: Course / Lap (`COURSE 4 / 12`).
     - Bottom-Left: Stunt Combo (`STUNT COMBO x3.5 · 1,250`).
     - Bottom-Right: Checkpoint progress bar (`NEXT CHECKPOINT 66% progress`).
     - Forward navigation chevrons guiding the player to the next platform.

5. **Defect 5: Airborne Physics Authority, Wall Rides, Loops & Landing Assistance**:
   - *Observation*: Vehicle air controls needed tight arcade responsiveness without tumbling, flipping backwards, or getting trapped in reset loops. Wall rides and loops needed explicit centrifugal downforce.
   - *Root Cause (RC-38)*: Lack of multi-point predictive landing alignment and centrifugal downforce rules.
   - *Required Solution*: Dedicated Stunt Mode (Shift/handbrake) for deliberate flips, spins, and rolls; automatic horizon stabilization bias in normal flight; predictive multi-point raycast landing guidance; centrifugal downforce for loops and wall rides; safe one-shot checkpoint recovery.

---

## 2. Requirements & Gap Matrix

| Requirement ID | Description | Current State | Target State | Priority |
| :--- | :--- | :--- | :--- | :--- |
| **REQ-TRK-01** | Modular disconnected stunt platform graph | Partial (only Course 1) | All 12 courses with explicit platform islands, ballistic air gaps, kicker ramps, catch aprons, loops, wall rides, and finish stadiums | **P0** |
| **REQ-TRK-02** | Flagship stunt course with multiple stunt types | Basic prototype | Flagship Course 1 ("Neon Stunt Odyssey") with genuine 50m gaps, 360° vertical loop, 75° wall ride, moving platform, and precision jumps | **P0** |
| **REQ-TRK-03** | Automated trajectory & reachability validator | Basic kinematic simulation | Full ballistic solver validating $v_{min}, v_{target}, v_{max}$, flight duration, apron width, and safe recovery | **P0** |
| **REQ-PHY-01** | Arcade vehicle physics & suspension | Working baseline | Refined grounded suspension, weight transfer, drift mini-turbos, and nitro boost | **P0** |
| **REQ-PHY-02** | Airborne trick authority & horizon stabilization | Basic rotation | Dual-mode flight: Stunt Mode (flips/spins/rolls) + Normal Mode (horizon stabilization & landing deck alignment) | **P0** |
| **REQ-PHY-03** | Centrifugal loop & wall-ride adhesion | Basic normal lerp | Explicit centrifugal normal downforce maintaining contact on loops and 75° wall rides | **P0** |
| **REQ-PHY-04** | Predictive landing assistance & shock feedback | Basic raycast | Multi-point forward-looking landing prediction smoothly guiding chassis without visual snapping | **P0** |
| **REQ-PHY-05** | Checkpoint recovery & out-of-bounds guard | 65m jump abort fixed | Reliable transform restoration, velocity reset to 18 m/s, 2.5s cooldown, zero infinite respawn loops | **P0** |
| **REQ-ENV-01** | Eliminate sky beacons & multiple moons | Buggy beacons in sky | Exactly 1 coherent sun/moon, 0 floating spheres in sky, balanced ACES tonemapper | **P1** |
| **REQ-ENV-02** | 6 Distinct Selectable Biomes | Only 4 partial worlds | Snowbound Peaks, Coastal Velocity, Wild Forest, Skyline Rush, Desert Extreme, Neon Afterdark | **P1** |
| **REQ-ENV-03** | Believable architectural & foliage scale | Miniature buildings | Real-scale 50m–140m skyscrapers, commercial plazas, grandstands, organic tree clusters | **P1** |
| **REQ-UI-01** | Modern Glass Card HUD (`input_file_4.png`) | Raw text labels | Speed card, Next Stunt card, Course card, Combo card, Checkpoint progress card, 3D chevron | **P1** |
| **REQ-UI-02** | Eliminate text clipping ('RUSH!') | Cut off at top-left | Resolution-independent containers, centered countdowns, safe margins | **P1** |
| **REQ-CAM-01** | Multi-mode camera & jump cinematic | Basic chase camera | Chase, Jump Airtime, Landing Spring, Hood/Cockpit, and Orbit view modes with collision avoidance | **P1** |
| **REQ-GMP-01** | Career, Modes & Progression | Basic Quick Play | 12 courses, 3 tiers, Career, Time Attack with Ghost, Stunt Challenge, Medals, Vehicle Unlocks | **P2** |
| **REQ-AUD-01** | Comprehensive Sound Design | Engine hum only | Engine RPM modulation, boost whoosh, tire screech, air rush, landing thud, stunt fanfare | **P2** |
| **REQ-TST-01** | Automated Test Suite (100% Pass) | 80 suites pass | Extended AeroRush test suites verifying all 6 biomes, 12 courses, physics, gaps, and UI | **P3** |
| **REQ-REL-01** | Standalone & Suite Packaging & Evidence | Windows/Linux/Web | Real runtime screenshot capture (`capture_aero_rush_evidence.py`), contact sheet, certification | **P3** |

---

## 3. Architecture & Affected Files

```text
                        AERORUSH ARCHITECTURE
                                  |
      +---------------------------+---------------------------+
      |                           |                           |
  TRACK & STUNT               VEHICLE & CAMERA            ENVIRONMENT & WORLDS
- aero_course_database.gd   - aero_vehicle.gd           - aero_world_base.gd
- aero_track_generator.gd   - aero_physics_helpers.gd   - aero_world_snow.gd (NEW)
- aero_track_validator.gd   - aero_chase_camera.gd      - aero_world_coastal.gd
- aero_moving_platform.gd   - aero_vehicle_visuals.gd   - aero_world_forest.gd (NEW)
- aero_checkpoint.gd                                    - aero_world_skyline.gd (NEW)
                                                        - aero_world_desert.gd (NEW)
                                                        - aero_world_neon.gd (NEW)
      |                           |                           |
      +---------------------------+---------------------------+
                                  |
                             UI & HUD
                         - aero_hud.gd (Redesign to input_file_4.png)
                         - aero_course_select.gd (6 Biomes)
                         - aero_garage.gd
                         - aero_results_screen.gd
                         - aero_rush_main.gd
```

### Detailed Affected Files:
1. `games/aero-rush/core/aero_constants.gd` — Add 6 biome enums, camera modes, stunt definitions.
2. `games/aero-rush/tracks/aero_course_database.gd` — Handcraft all 12 courses with modular disconnected stunt islands, launch kickers, gaps, landing aprons, loops, wall-rides, and moving platforms.
3. `games/aero-rush/tracks/aero_track_generator.gd` — Support moving/rotating kinetic platform islands, multi-tier landing aprons, and launch kickers.
4. `games/aero-rush/tracks/aero_track_validator.gd` — Ballistic reachability solver and course graph integrity checks.
5. `games/aero-rush/worlds/aero_world_base.gd` — Shared PBR lighting, sun/moon composition, atmospheric fog, terrain generation.
6. `games/aero-rush/worlds/aero_world_megacity.gd` / `aero_world_neon.gd` — Remove floating beacons, add coherent moon, cyber street grid, realistic towers.
7. `games/aero-rush/worlds/aero_world_snow.gd` (NEW) — Snow mountains, alpine forests, frozen lakes, snowfall particle weather.
8. `games/aero-rush/worlds/aero_world_coastal.gd` — Tropical ocean, beaches, palm groves, seaside cliffs, resort architecture.
9. `games/aero-rush/worlds/aero_world_forest.gd` (NEW) — Dense temperate forest, giant trees, waterfalls, rivers, natural boulders.
10. `games/aero-rush/worlds/aero_world_skyline.gd` (NEW) — Modern day/sunset metropolis, proportional skyscrapers, commercial plazas.
11. `games/aero-rush/worlds/aero_world_desert.gd` (NEW) — Sandstone mesas, dunes, chasm jumps, dust weather.
12. `games/aero-rush/vehicles/aero_vehicle.gd` — Flight stabilization, predictive landing assistance, loop/wall downforce, stunt controls, recovery.
13. `games/aero-rush/vehicles/aero_chase_camera.gd` — Multi-mode chase/jump/landing/hood/orbit camera with collision avoidance.
14. `games/aero-rush/ui/aero_hud.gd` — Full modern card redesign matching `input_file_4.png`, fix clipping, add navigation cues.
15. `games/aero-rush/ui/aero_course_select.gd` — 6 biome selector tabs, 12 courses, difficulty tiers, medal rewards.
16. `games/aero-rush/aero_rush_main.gd` — Coordinate 6 biomes, camera view toggle, moving platform updates, HUD integration.
17. `games/aero-rush/tests/` — Comprehensive test suites verifying all systems.
18. `scripts/capture_aero_rush_evidence.py` — Real runtime screenshot capture tool.
19. `BUILD.md` — New build and standalone export guide.

---

## 4. Implementation Phases & Sequence

- **Phase 1 (P0: Track & Course Graph Architecture)**:
  - Implement modular platform island graph with genuine ballistic gaps in `aero_track_generator.gd` and `aero_course_database.gd`.
  - Build Flagship Course 1 ("Neon Stunt Odyssey") featuring launch ramps, 52m gap, 360° vertical loop, drop transfer, 75° wall ride, moving platform, and finish platform.
  - Upgrade `aero_track_validator.gd` with projectile reachability solver.

- **Phase 2 (P0: Vehicle Simulation & Flight Control)**:
  - Implement dual-mode airborne controls in `aero_vehicle.gd`: Stunt Mode (Pitch/Roll/Yaw) and Normal Mode (Horizon stabilization).
  - Implement predictive landing guidance raycasts in `aero_physics_helpers.gd`.
  - Implement centrifugal adhesion for vertical loops and wall rides.
  - Implement safe one-shot checkpoint recovery with transform restoration and 2.5s cooldown.
  - Upgrade `AeroChaseCamera` with dynamic jump distance, landing compression, and view mode switching.

- **Phase 3 (P1: Complete Environment & 6 Biomes)**:
  - Fix sky composition in `aero_world_base.gd`: exactly 1 sun, 0 rogue floating beacons.
  - Implement all 6 biomes: Snowbound Peaks, Coastal Velocity, Wild Forest, Skyline Rush, Desert Extreme, Neon Afterdark.
  - Scale architecture and vegetation to realistic proportions.

- **Phase 4 (P1: UI/UX Redesign)**:
  - Complete redesign of `aero_hud.gd` matching `input_file_4.png`: Speed Card, Next Stunt Card, Course Card, Stunt Combo Card, Checkpoint Progress Card.
  - Fix countdown text clipping.
  - Add 3D navigation chevron pointing to next landing platform.
  - Update `aero_course_select.gd` with 6 biome tabs and tier previews.

- **Phase 5 (P2: Gameplay, Audio & Progression)**:
  - Expand career progression across all 12 courses and 3 tiers.
  - Add procedural engine audio modulation, boost audio, landing audio, and stunt audio.

- **Phase 6 (P3: Automated Testing, Packaging & Release Certification)**:
  - Run full test suite via Godot CI container; ensure 100% pass rate.
  - Run `scripts/capture_aero_rush_evidence.py` to capture real runtime screenshots.
  - Package standalone `AeroRush.pck` and full suite distribution.
  - Run `certifier.py` to update `acceptance.json` and `production-certification.json`.
  - Update `IMPLEMENTATION_WALKTHROUGH.md`, `CHANGELOG.md`, `TODO.md`.

---

## 5. Acceptance Criteria

1. **Disconnected Stunt Platform Graph**: Flagship course and all 12 courses consist of genuinely physically disconnected platform islands with verified ballistic air gaps (no collision in mid-air).
2. **Flagship Course**: Complete flagship course traversing launch ramps, 52m jump, 360° loop, 75° wall ride, moving platform, and finish stadium platform using actual vehicle physics.
3. **Environment & Visual Coherence**: Zero rogue floating beacons or duplicate moon spheres. Exactly 1 sun/moon. 6 distinct biomes with authentic terrain, vegetation, architecture, and weather.
4. **Vehicle Control & Physics**: Responsive steering, drift mini-turbos, nitro boost; Stunt Mode allows flips/rolls/spins; Normal flight aligns wheels-down; predictive landing assistance; centrifugal loop adhesion.
5. **No Trapping / Safe Recovery**: No clipping through platforms, zero infinite respawn loops, safe transform restoration at 18 m/s.
6. **Modern HUD (`input_file_4.png`)**: Speed card, Next Stunt card, Course card, Combo card, Checkpoint progress card with progress bar, and 3D navigation chevron. Zero text clipping.
7. **Regression-Free Monorepo**: All 80+ test suites across all 10 VoltArena titles pass with 100% success rate.
8. **Real Packaged Evidence**: Packaged runtime screenshots captured and verified across spawn, driving, jumps, loops, wall-rides, and all 6 biomes.
