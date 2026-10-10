# VOLTARENA — MASTER PRODUCTION IMPLEMENTATION PLAN
## Dual Game Overhaul: AeroRush & Chroma Rush (v9.0.0)

**Roles**: Principal Godot Game Architect, Gameplay/Physics Engineer, Technical Artist, 3D Environment Designer, UI/UX Lead, QA & DevOps Engineer  
**Repository**: `dayashimoga/VoltArena` (`games/aero-rush`, `games/chroma-rush`)  
**Engine & Target**: Godot 4.3 Stable (Windows x86_64, Linux x86_64, macOS, WebGL/WASM Cloudflare Pages, Android ARM64)  
**Date**: October 2026  
**Status**: ACTIVE EXECUTION PLAN (PHASE P0 AUDIT COMPLETE)

---

## 1. Executive Summary & Forensic Defect Analysis

A deep forensic inspection of the repository, scenes, scripts, collision geometries, camera controllers, and the user's latest 5 in-game screenshots reveals critical root causes that must be architecturally fixed in both **AeroRush** and **Chroma Rush**:

### 1.1 Chroma Rush Defect Forensics (Screenshots 1 & 2)

1. **Defect CR-1: Off-Road Trapped Spawns & Corrupted Reset Point (`input_file_0.png`)**:
   - *Observation*: In Screenshot 1, the player car is sitting at 0 km/h on a flat concrete plaza/sidewalk facing a building wall, completely off the road. The road is isolated to the left behind a curb.
   - *Root Cause (RC-CR01)*: In `neon_city.gd`, `_build_urban_block_parcel()` places `SidewalkApron` (`BoxMesh 26m x 0.14m x 18m`) at local $Z = -18.0\text{m}$ rotated $-90^\circ$, causing an overlapping 14cm slab that covers the roadway from $X = -18.5\text{m}$ to $X = -0.5\text{m}$. Furthermore, in `chroma_vehicle.gd:375`, `last_valid_track_pos` is updated whenever `is_grounded` is true and $Y\text{-up} > 0.7$. When a player veers or spawns off-road onto a flat plaza, `is_grounded` remains true, overwriting `last_valid_track_pos` with the off-road plaza coordinates. Consequently, pressing `[R]` (Reset to Road) resets the car *right back onto the sidewalk trap*, making recovery impossible.
   - *Architectural Resolution*:
     1. In `chroma_vehicle.gd`, decouple recovery from raw ground collision: `last_valid_track_pos` must only record positions within the drivable road corridor ($\text{dist\_to\_spline} \le \text{road\_width} \times 0.5$).
     2. Hardcode `recover_vehicle()` and `reset_to_road()` to query `world.get_nearest_safe_road_transform()` on the authoritative spline centerline with proper forward tangent alignment, with an absolute fallback to `waypoints[0]`.
     3. Remove overlapping `SidewalkApron` geometry and strictly set back all building parcels so they terminate outside the $15\text{m}$ road clearance envelope ($\ge 11.5\text{m}$ from road centerline).

2. **Defect CR-2: Streetlight & Tree Obstacles in Driving Corridors (`input_file_1.png`)**:
   - *Observation*: In Screenshot 2, the car is driving along a sidewalk directly into a streetlight post and a tree.
   - *Root Cause (RC-CR02)*: Road curbs in `world_base.gd` are only 10cm high and beveled, allowing vehicles to drift off-road effortlessly. Additionally, `_is_clear_of_spline` had `ignore_window = 6`, ignoring clearance checks against the adjacent road segment. Props were placed at $\pm 13.8\text{m}$ where roadway branches or curves brought them into travel envelopes.
   - *Architectural Resolution*:
     1. Implement solid barrier verges and 35cm upright curbs along high-speed corridors.
     2. Fix `_is_clear_of_spline` to verify clearance against ALL spline segments without ignoring nearby samples.
     3. Ensure a minimum lateral clearance of $\ge 12.0\text{m}$ for trees and $\ge 10.5\text{m}$ for light poles from the road centerline.

---

### 1.2 AeroRush Defect Forensics (Screenshots 3, 4, 5)

1. **Defect AR-1: HUD Telemetry Coordinate Overlap (`input_file_2.png`, `input_file_3.png`, `input_file_4.png`)**:
   - *Observation*: In Screenshots 3, 4, and 5, "KICKER ahead" and "LANDING ahead" (cyan) are rendered directly on top of "SPEED 0 km/h" (white) in the top-left corner.
   - *Root Cause (RC-AR01)*: In `aero_hud.gd`, `next_stunt_card` was assigned `anchor_left = 0.5, anchor_right = 0.5`, but because `set_anchors_and_offsets_preset(PRESET_TOP_WIDE)` or a centered container layout was omitted, its position collapsed to $(0, 20)$ during dynamic scene initialization, directly colliding with `speed_card` at $(24, 20)$.
   - *Architectural Resolution*: Re-architect the HUD root using a standard responsive container hierarchy:
     - Wrap top cards in an `HBoxContainer` anchored across the top (`PRESET_TOP_WIDE`) with margins, placing `SpeedCard` on the left, `NextStuntCard` in a center-aligned container, and `CourseCard` on the right.
     - Enforce `grow_horizontal = GROW_DIRECTION_BOTH` on `next_stunt_card` so it remains perfectly centered at all aspect ratios and resolutions.

2. **Defect AR-2: Giant Cartoon Orange/Green Buildings & Track Encroachment (`input_file_2.png`, `input_file_3.png`)**:
   - *Observation*: In Screenshot 3, the track is flanked by giant orange and green structures with massive cartoon windows and doors. In Screenshot 4, the vehicle is wedged directly against the wall of one of these buildings next to a ramp.
   - *Root Cause (RC-AR02)*: In `aero_world_megacity.gd` and `aero_world_skyline.gd`, `_build_flanking_skyscrapers()` spawned `building_comm_a.glb` (a 1.29m tall miniature 2-story shop with a modeled door and small windows) scaled by $16\times–26\times$ at $X = \pm 35\text{m}$. At $26\times$ scale, this toy shop expands to 25m wide with a 25m tall front door, looking like an absurd cartoon dollhouse right next to the roadway, and penetrating track collision envelopes on curved sections.
   - *Architectural Resolution*:
     1. Discontinue using miniature commercial shop models (`building_comm_*.glb`, `building_a.glb`) as giant towers.
     2. Use authentic architectural skyscraper models (`building_skyscraper_a.glb` through `building_skyscraper_e.glb`) or procedural textured towers with believable floor-to-ceiling heights ($3.5\text{m}$ per floor).
     3. Enforce a minimum setback of $\ge 45\text{m}$ from the nearest track ribbon sample, completely eliminating track encroachment and car trapping.

3. **Defect AR-3: Car Falling to Ground Plane Without Out-of-Bounds Recovery (`input_file_3.png`, `input_file_4.png`)**:
   - *Observation*: In Screenshots 4 and 5, the vehicle is driving on the ground basin below elevated tracks, surrounded by pillars and trapped against building foundations.
   - *Root Cause (RC-AR03)*: The kill plane was placed at fixed $Y < -30\text{m}$ regardless of track height, and elevated tracks sit at $Y \in [10, 35]\text{m}$, while the ground plane sits at $Y = -6.5\text{m}$. When a vehicle misses a jump, it falls only 16 meters, lands on the ground plane, and continues driving indefinitely under the tracks without triggering a checkpoint reset.
   - *Architectural Resolution*:
     1. Implement a dynamic out-of-bounds detector: if the vehicle drops more than $8.0\text{m}$ below the current track segment elevation OR leaves the track lateral corridor by $> 22\text{m}$, immediately trigger recovery.
     2. Zero vehicle linear and angular velocities and restore transform to the last safe checkpoint deck with $2.5\text{s}$ safe grace.

---

## 2. Requirements & Gap Matrix

| ID | Title | Current State | Target State | Priority |
| :--- | :--- | :--- | :--- | :---: |
| **GAP-CR-01** | Chroma Rush Safe Road Spawning | Spawns on pedestrian sidewalk in some missions | Spawns strictly in center of road lane facing tangent | **P0** |
| **GAP-CR-02** | Chroma Rush Valid Road Recovery | `last_valid_track_pos` saved on sidewalk | Recovery strictly queries authoritative road centerline | **P0** |
| **GAP-CR-03** | Chroma Rush Driving Obstacles | Streetlights/trees at $\pm 13.8\text{m}$ intrude on turns | Strict clearance $\ge 12\text{m}$; raised curbs & barriers | **P1** |
| **GAP-CR-04** | Chroma Rush Camera Stability | Minor zoom steps during speed spikes | Smooth filtered camera pipeline with deadband | **P1** |
| **GAP-CR-05** | Chroma Rush Mission Solvability | 24 missions defined | 100% solvable with reachable targets & gates | **P2** |
| **GAP-AR-01** | AeroRush HUD Telemetry Overlap | "KICKER ahead" overlaps "0 km/h" in top-left | Responsive Top-Center Stunt Card via HBox layout | **P0** |
| **GAP-AR-02** | AeroRush Building Scale & Intrusion | 24x scaled toy shops flank and penetrate track | Authentic skyscraper assets with $\ge 45\text{m}$ setback | **P1** |
| **GAP-AR-03** | AeroRush Dynamic OOB Kill-Plane | Fixed $Y < -30\text{m}$ allows driving on ground | Track-relative drop detector ($>8\text{m}$ below deck) | **P0** |
| **GAP-AR-04** | AeroRush Modular Disconnected Graph | 12 circuits with loops, wall-rides, kinetic platforms | 100% verified jump reachability & landing safety | **P0** |
| **GAP-SYS-01**| Monorepo Test Pass Rate | 80 suites pass | 100% pass rate, 0 failures, $\ge 90\%$ coverage | **P0** |
| **GAP-SYS-02**| Cross-Platform Standalone Packages | Standalone PCKs exported | Verified standalone PCKs for all 10 games | **P2** |

---

## 3. Phased Implementation Roadmap

### Phase P0: Forensic Audit & Defect Baseline (COMPLETED)
- Inspect user screenshots 1–5; identify exact coordinate and scene origins of all 5 defects.
- Audit `neon_city.gd`, `world_base.gd`, `chroma_vehicle.gd`, `aero_hud.gd`, `aero_world_megacity.gd`.

### Phase P1: Critical Stability & Recovery Hardening
- **Chroma Rush**:
  - Fix `chroma_vehicle.gd`: `last_valid_track_pos` only updates when within road corridor.
  - Fix `reset_to_road()` to always fetch spline centerline from `active_world`.
  - Fix `neon_city.gd`: remove overlapping `SidewalkApron`, enforce $\ge 12\text{m}$ prop clearance.
  - Implement 35cm upright curbs to prevent accidental off-roading.
- **AeroRush**:
  - Fix `aero_hud.gd`: top-center layout using `HBoxContainer` / `PRESET_TOP_WIDE` with `GROW_DIRECTION_BOTH`.
  - Fix `aero_vehicle.gd`: dynamic track-relative OOB kill-plane ($Y < \text{current\_deck\_Y} - 8.0\text{m}$).
  - Remove intrusive commercial shop models in `aero_world_megacity.gd` and `aero_world_skyline.gd`; enforce $\ge 45\text{m}$ skyscraper setback.

### Phase P2: Core Gameplay & Mechanics
- **AeroRush**:
  - Verify all 12 circuits in `aero_course_database.gd` with 200 Hz ballistic validator.
  - Validate 360° loops, 75° wall-rides, and kinetic `AeroMovingPlatform` synchronization.
- **Chroma Rush**:
  - Complete find target $\to$ match speed $\to$ atomic bidirectional swap $\to$ deliver $\to$ reward loop.
  - Validate all 24 missions across 4 modes (Color Hunt, Chroma Sprint, Puzzle Drive, Rival Battle).

### Phase P3: Visual & World Overhaul
- **AeroRush**:
  - Ensure all 6 biomes (Snow, Coastal, Forest, Skyline, Desert, Neon) exhibit authentic terrain, lighting, and vegetation.
  - Ensure zero miniature buildings, zero floating beacon spheres, and single-sun skybox composition.
- **Chroma Rush**:
  - Enhance urban skyline with diverse districts, realistic street furniture, and PBR clearcoat vehicles.

### Phase P4: UX, Camera & Controls
- Verify responsive HUD layouts across viewports from $360\times 800$ to $2560\times 1440$.
- Verify camera view modes (Chase, Hood, Orbit in AeroRush; filtered chase cam in Chroma Rush).

### Phase P5: Engagement, Modes & Progression
- Ensure career saves, unlockable vehicle rosters, medals, and high scores persist via `SaveManager`.

### Phase P6: Optimization & Profiling
- Validate GPU instancing, draw call budgets, memory usage ($< 500\text{MB}$), and 60+ FPS performance.

### Phase P7: Cross-Platform Packaging & Distribution
- Verify standalone PCK exports for all 10 titles (`export/standalone/`).
- Verify Cloudflare-compliant chunked Web export (`export/web/`).

### Phase P8: QA & Automated Test Suite
- Execute all 80+ test suites via Podman CI container; require 100% pass rate.
- Run Playwright Chromium visual audit capturing high-definition gameplay evidence.

### Phase P9: Documentation, Certification & Final Sign-Off
- Update `IMPLEMENTATION_WALKTHROUGH.md`, `CHANGELOG.md`, `TODO.md`.
- Run `scripts/certifier.py` to produce `acceptance.json` and `production-certification.json`.

---

## 4. Measurable Acceptance Criteria

1. **Chroma Rush Safe Spawning & Recovery**:
   - Spawns strictly in road lane facing direction of travel across all 24 missions.
   - Pressing `[R]` instantly restores vehicle to the center of the nearest drivable road segment.
   - Driving along road curves has zero tree or light-post collisions.
2. **AeroRush HUD Resolution & Anchoring**:
   - "NEXT: STUNT" card is centered at the top; zero overlap with "SPEED" or "0 km/h".
3. **AeroRush Environmental Scale & Clearance**:
   - Zero miniature toy shops scaled to giant proportions; zero buildings within $45\text{m}$ of track centerline.
   - Falling off elevated platforms immediately triggers checkpoint recovery within $1.5\text{s}$, preventing driving on the ground basin.
4. **Monorepo Integrity**:
   - All 80 test suites pass with 100% success rate, $\ge 90\%$ function coverage.
   - Zero regressions across the other 8 VoltArena games or universal launcher.
5. **Packaged Verification**:
   - Standalone PCKs and chunked web builds launch and function independently.
