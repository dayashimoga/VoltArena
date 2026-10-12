# VOLTARENA — MASTER PRODUCTION IMPLEMENTATION PLAN
## Dual Title Rebuild & Productionization: AeroRush & Chroma Rush (v10.0.0)

**Roles**: Principal Godot Vehicle Physics Engineer, AAA Game Architect, Procedural World Designer, Technical Artist, QA & DevOps Lead  
**Repository**: `dayashimoga/VoltArena` (`games/aero-rush`, `games/chroma-rush`, `shared/`, `platform/`, `launcher/`)  
**Engine & Target Platforms**: Godot 4.3 Stable (Windows x86_64, Linux x86_64, macOS, WebGL/WASM Cloudflare Pages, Android ARM64, iOS)  
**Date**: October 2026  
**Status**: ACTIVE PHASED EXECUTION — COMMENCING PHASE P0/P1 RE-AUDIT & REBUILD

---

## 1. Executive Summary & Forensic Audit Matrix

This master production implementation plan establishes the architectural specifications, prioritized tasks, root-cause fixes, quantitative gates, and verification evidence required to audit, fix, rebuild, visually overhaul, enhance, optimize, and productionize **Chroma Rush** (and maintain **AeroRush**), while preserving all 10 VoltArena titles without regressions.

### 1.1 Forensic Defect Forensics & Traceability Matrix

| Defect ID | Game | Observed Symptom | Severity | Root-Cause Analysis | Corrective Architectural Task | Verification Test & Quantitative Gate |
| :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| **DEF-CR-01** | Chroma Rush | Sluggish Acceleration from Rest | P0 | In `vehicle_catalog.gd`, base vehicle acceleration was under-calibrated to 2.4–3.2 m/s² (0–60 km/h taking 5.0–7.0 s). In `chroma_vehicle.gd`, low-speed torque scaling was dampened and slide collision clamping halted forward speed prematurely. Targets cruising at 18–22 m/s escaped immediately. | Calibrate responsive, progressive torque curve with high off-the-line launch force (0–60 km/h in 3.2–4.5 s for sports tier, 4.5–6.0 s for standard), progressive gearing, longitudinal tire slip model, and zero micro-snag stalling. | Seeded acceleration benchmark `test_chroma_vehicle_physics.gd`: 0–60 km/h in 3.2–5.5 s; P95 throttle-to-acceleration response $\le 80\text{ ms}$; targets catchable within 15–25 s. |
| **DEF-CR-02** | Chroma Rush | Camera Zoom Oscillation & Chassis Micro-Jitter | P1 | In `chroma_rush_main.gd:554-565`, camera FOV transitioned with dynamic noisy speed without deadband filtering, and camera position was updated in `_process` reading non-interpolated physics transforms (`_physics_process`), causing micro-stutter/jitter against the 60 Hz physics tick. | Implement dual-stage low-pass filtered camera tracking with a 1.2 m/s deadband, fixed authoritative chase distance, rate-limited FOV transition ($\le 3.5^\circ/\text{s}$), physics-render interpolation, and decouple vertical chassis pitch chatter. | `test_chroma_camera_stability.gd`: Camera-distance oscillation $\le 1.0\%$; unintended FOV drift $\le 0.5^\circ$ across 600 steady driving frames; zero render-physics jitter. |
| **DEF-CR-03** | Chroma Rush | Steep Steering & Low-Speed Understeer | P1 | In `chroma_vehicle.gd:312-333`, steering was clamped to 0 below 2.5 m/s (`steer_engagement = clampf(forward_speed / 2.5, 0, 1)`), making the car unable to turn from a stop, followed by a sudden sharp jerk when crossing 2.5 m/s with raw non-Ackermann angles. | Implement speed-sensitive Ackermann-approximated steering curve with exponential smoothing ($1.0 - e^{-k\Delta t}$) ensuring immediate, predictable low-speed maneuverability (turning authority at 0–5 km/h) and high-speed directional stability. | Input telemetry verification: P95 steering response $\le 80\text{ ms}$; zero lag from standstill; predictable cornering. |
| **DEF-CR-04** | Chroma Rush | Road-Blocking Buildings Across Driving Lanes (Screenshot 1 & 2) | P0 | 1. In `neon_city.gd:356-391`, building placements along spline checked only pivot-point distance `_is_clear_of_spline(b_pos, 28.0)`. Building footprints ($20\text{m}\times 20\text{m}$ to $28\text{m}\times 28\text{m}$) and foundation plinths ($30\text{m}\times 30\text{m}$) have diagonal corner reach $R \ge 17\text{m}–21\text{m}$. On curves, rotated corners protrude directly into active driving lanes (`media_1791788402948.png`). 2. At turn approaches (e.g. WP 1 $\to$ WP 2), straight-line forward sightlines and lane projections lacked swept clearance, allowing commercial storefronts (`building_comm_a.glb`) to sit directly across incoming lanes (`media_1791788394007.png`). 3. `prune_props_in_road_corridor` checked only node center point against 7.0m, failing to detect intruding collision boxes. | 1. Upgrade spline clearance verification to calculate full oriented bounding box (OBB) corner swept polygons against road corridor ($\ge 12.0\text{m}$ clearance from centerline to ANY point of building or parcel). 2. Reserve forward swept clearance cone ($\ge 45\text{m}$) at turn approaches. 3. Upgrade `prune_props_in_road_corridor` and `WorldAuditTool` to deduct collider radii/extents. | `WorldAuditTool.audit_world`: 0 blocked segments, 0 lane/prop intersections, 0 building intrusions across 100% of worlds. |
| **DEF-CR-05** | Chroma Rush | Incomplete Target Pursuit & Unbalanced AI Speeds | P0 | Ambient traffic cars spawned at static speeds ($18.0–22.0\text{ m/s}$) immediately pulled away from player at launch ($0\text{ m/s}$). Relative closing speed was negative or negligible, causing target loss or impossible pursuit within mission time limits. | Tune dynamic catchup AI logic: target vehicle holds pacing speed ($15.0–17.5\text{ m/s}$) when ahead of player, allowing responsive catchup within 15–20 seconds; speed matching occurs smoothly when player enters 20m pursuit cone. | 100% of 24 career missions achievable by autonomous test driver and standard inputs; 1,000/1,000 atomic swap tests verified. |
| **DEF-CR-06** | Chroma Rush | Missing Biome Environments (Snow, Ice, Desert, Canyon, Beach, Forest, Volcanic) | P0 | Only Neon City had full implementation; secondary worlds were missing or had rudimentary assets; user requested distinct playable city, snow, ice, desert, canyon, beach, forest, and volcanic-underworld environments with unique scenery, materials, weather, and traction. | Implement modular world architecture supporting all 8 requested environments with authentic terrain, road ribbons, foliage, atmospheric lighting, weather shaders, and surface traction modifiers. | All 8 environments loadable, drivable, and verified with 0 road collisions and complete mission loops. |
| **DEF-CR-07** | Chroma Rush | Realistic Large City Architecture & PBR Materials | P1 | Buildings suffered from repetitive small blocks, miniature geometry, and flat styling; needed American/New York-inspired skyscraper archetypes, multi-tier city blocks, reflective glass curtain walls, stone plinths, street furniture, and organic trees with branches and foliage. | Implement authentic New York/American architectural archetypes, multi-material PBR shaders (`ARCHITECTURAL_SHADER_CODE`), reflective glass, mature branching trees, streetlights, fire hydrants, bus shelters, benches, and 360° skyline. | Visual audit gate: $\ge 12$ building archetypes, $\ge 30$ facade variations, authentic PBR materials, realistic scale ($3.5\text{m}$ floor height). |
| **DEF-CR-08** | Chroma Rush | Car Models, Wheels, Lighting & Automotive Shaders | P1 | Cars lacked realistic multi-coat clearcoat paint, reactive projector headlights, glowing taillights, smoked glass canopies, and realistic alloy wheels with vulcanized rubber tires; contact shadow was a harsh solid black quad. | Implement `AUTOMOTIVE_SHADER_CODE` with multi-coat metallic clearcoat, emissive projector LEDs, smoked glass, alloy wheels with tire normal/roughness, and soft radial contact ambient occlusion shadow. | Visual audit gate: Soft radial shadow, reflective automotive paint, realistic wheels and lights. |

---

## 2. Quantitative Acceptance Criteria & Gated Execution

Execution strictly follows these measurable PASS/FAIL gates:

```
[P0: AUDIT & TRACEABILITY] ➔ [P1: PHYSICS & CONTROLS] ➔ [P2: ROAD CLEARANCE]
                                    ➔ [P3: REALISTIC LARGE CITY] ➔ [P4: WORLDS & GAMEPLAY]
                                    ➔ [P5: OPTIMIZATION & PRODUCTION CERTIFICATION]
```

### Gate P0: Forensic Audit Baseline (PASS)
- 100% of known issues traced to severity, reproduction, root-cause hypothesis, corrective tasks, and tests.
- Baseline recordings, screenshots, architecture, and requirements traceability documented.
- `IMPLEMENTATION_PLAN.md` updated and approved BEFORE code modifications.

### Gate P1: Vehicle Physics & Camera Controls
- **Acceleration**: Apex Striker 0–60 km/h in 3.5–5.0 s (progressive torque curve); zero sluggish hesitation off the line.
- **Steering**: Responsive, speed-sensitive Ackermann steering; low-speed maneuvering authority from 0 km/h; P95 input response $\le 80\text{ ms}$.
- **Camera Tracking**: Zero zoom oscillation (drift $\le 0.5^\circ$, distance variation $\le 1.0\%$); decoupled vertical chassis pitch chatter; render-physics interpolation eliminates micro-jitter.
- **AI Catchability**: Target traffic vehicles travel at balanced speeds ($15–18\text{ m/s}$), catchable within 15–25 seconds of clean driving without unrealistic speed boosts.

### Gate P2: Authoritative Road Graph & Swept Clearance
- **Authoritative Clearance**: Drivable asphalt road half-width (7.5m) + curb (0.25m) + sidewalk (1.6m) = 9.35m protected corridor.
- **Swept OBB Footprints**: 100% of building, parcel, plinth, and prop bounding box corners verified $\ge 12.0\text{m}$ from road spline centerline.
- **Turn Apex & Sightlines**: Turn apexes and straightaway approaches maintain $\ge 45\text{m}$ open clearance cone; zero buildings blocking forward line of sight or lane projections.
- **Automated World Audit**: `WorldAuditTool.audit_world` reports 0 blocked segments, 0 lane/prop intersections, 0 floating/sunken objects across all worlds.
- **Safe Spawns & Recovery**: 100/100 safe spawns and `[R]` recoveries on drivable asphalt facing forward.

### Gate P3: Realistic Large City (New York / American Architecture)
- **Scale & Detail**: Believable American/New York architecture (proportional $3.5\text{m}$ floor-to-ceiling heights, multi-tier setbacks, rooftop mechanicals).
- **Architectural Diversity**: $\ge 12$ distinct building archetypes, $\ge 30$ facade variations, reflective glass curtain walls (specular 0.88, roughness 0.08, metallic 0.85), stone plinths.
- **Street Furniture & Foliage**: Continuous sidewalks, streetlights, fire hydrants, bus shelters, benches, bollards, and mature organic trees with branching trunks and leafy canopies ($6\text{m}–14\text{m}$ tall).
- **Automotive Shaders**: PBR metallic clearcoat paint, reactive projector LED headlights, smoked glass canopies, alloy wheels, and soft radial contact shadows.

### Gate P4: Multi-World Environments & Core Gameplay Loop
- **Playable Environments**: 8 distinct worlds (Metropolitan City, Snowbound Peaks, Glacial Ice, Desert Dunes, Redrock Canyon, Coastal Beach, Pine Forest, Volcanic Underworld) with authentic terrain, road ribbons, materials, and traction.
- **Complete Gameplay Loop**: 100% complete **locate $\to$ chase $\to$ atomic color swap $\to$ deliver to gate $\to$ score/reward** loop across all 24 missions.
- **Controls & HUD**: Compact adaptive glassmorphism HUD ($\le 12\%$ viewport obstruction), non-obtrusive radar/minimap pip, keyboard, gamepad, and touch controls.

### Gate P5: Optimization & Production Certification
- **Performance**: $\ge 60\text{ FPS}$ average desktop (1080p Ultra), $\ge 30\text{ FPS}$ average mobile (720p Medium); frame pacing $\le 1.0\%$ spikes.
- **Integrity**: 100/100 safe spawn/recovery tests; zero road obstructions; zero persistent vehicle/camera jitter; 1,000/1,000 atomic swap consistency tests.
- **Test Coverage**: $\ge 90\%$ function coverage across Chroma Rush codebase; 100% mandatory tests passing (0 failures, 0 errors).
- **Certification Artifacts**: `production-certification.json`, `IMPLEMENTATION_WALKTHROUGH.md`, updated documentation.

---

## 3. Prioritized Phased Task Breakdown

### Phase P1: Physics & Controls Rebuild
- [ ] **Task P1.1 (Drivetrain & Launch Torque)**: Overhaul acceleration in `chroma_vehicle.gd` and `vehicle_catalog.gd`:
  - Calibrate progressive torque-band launch curve: 0–60 km/h in 3.5–5.0 s for sports tier, 4.5–6.0 s for heavy tier.
  - Eliminate low-speed hesitation; provide immediate throttle response off the line.
  - Implement longitudinal tire slip and rolling drag.
- [ ] **Task P1.2 (Speed-Sensitive Steering)**: Overhaul steering in `chroma_vehicle.gd`:
  - Remove arbitrary low-speed steering freeze; provide full steering authority from 0 km/h.
  - Implement smooth exponential Ackermann-approximated steering curve with speed-sensitive damping at high speeds.
- [ ] **Task P1.3 (Camera Stability & Interpolation)**: Overhaul chase camera in `chroma_rush_main.gd`:
  - Decouple chassis pitch/roll micro-chatter from camera orientation.
  - Implement fixed authoritative chase radius with 1.2 m/s deadband and rate-limited FOV ($\le 3.5^\circ/\text{s}$).
  - Enable render-physics interpolation to eliminate frame pacing micro-stutter.
- [ ] **Task P1.4 (AI Pursuit Speed Calibration)**: Tune ambient traffic and target AI in `neon_city.gd` and `chroma_ai_driver.gd`:
  - Set baseline target speed to 15.0–17.5 m/s, ensuring player can reliably catch targets within 15–25 seconds of clean driving.

### Phase P2: Road & World Generation (Zero Obstructions)
- [ ] **Task P2.1 (Authoritative Swept Footprint Clearance)**: Upgrade clearance checks in `neon_city.gd` and `world_base.gd`:
  - Calculate oriented bounding box (OBB) corner coordinates for all buildings, plinths, and parcels.
  - Enforce strict $\ge 12.0\text{m}$ clearance from road spline centerline to ALL corners.
  - Reserve $\ge 45\text{m}$ forward sightline and lane projection clearance cones at turn approaches.
- [ ] **Task P2.2 (Remove Encroaching Structures)**:
  - Fix turn apex at WP 2 / Gate 1 so North Financial Avenue does not dead-end into `building_comm_a.glb`.
  - Fix curve placement so building plinths do not encroach onto sidewalks or road asphalt.
  - Overhaul `prune_props_in_road_corridor` to verify collider bounds and deduct shape radii.
- [ ] **Task P2.3 (Automated World Audit & Test Tool)**:
  - Fix `WorldAuditTool` syntax bug and verify 0 blocked segments, 0 lane/prop intersections, 0 sunken/floating objects across all worlds.
  - Run automated bot circuit traversal tests in forward and reverse directions.

### Phase P3: Realistic Large City (Architecture, PBR Shaders & Assets)
- [ ] **Task P3.1 (New York / American Architecture)**:
  - Proportional multi-tier skyscrapers, commercial storefronts, and residential brownstones.
  - Authentic multi-material PBR shaders (`ARCHITECTURAL_SHADER_CODE`) with reflective glass curtain walls and stone plinths.
- [ ] **Task P3.2 (Streetscape & Furniture)**:
  - Continuous sidewalks, modern streetlights, traffic signals, fire hydrants, bus shelters, benches, and bollards.
  - Organic trees with branching trunks and leafy foliage ($6\text{m}–14\text{m}$ tall) with cast iron tree grates.
- [ ] **Task P3.3 (Vehicle Visuals & Automotive Shaders)**:
  - `AUTOMOTIVE_SHADER_CODE` with multi-coat metallic clearcoat, projector LED headlights, reactive taillights, smoked glass canopy.
  - Soft radial ambient occlusion contact shadows replacing dark solid quads.
  - Precision alloy wheels with vulcanized rubber tires.

### Phase P4: Multi-World Environments & Complete Gameplay Loop
- [ ] **Task P4.1 (8 Diverse Playable Worlds)**:
  - Author and connect all 8 environments: Metropolitan City, Snowbound Peaks, Glacial Ice, Desert Dunes, Redrock Canyon, Coastal Beach, Pine Forest, Volcanic Underworld.
  - Apply distinct atmospheric lighting, terrain shaders, weather effects, and surface traction parameters.
- [ ] **Task P4.2 (Complete Mission Loop)**:
  - Verify complete **locate $\to$ chase $\to$ atomic color swap $\to$ deliver to gate $\to$ score/reward** loop across all 24 missions.
  - Test atomic swap engine under high-speed and edge-case pursuit conditions (1,000/1,000 consistency).
- [ ] **Task P4.3 (Adaptive HUD & Controls)**:
  - Compact glassmorphism top telemetry bar ($\le 12\%$ viewport obstruction).
  - Clean non-obtrusive radar/minimap pip replacing giant center banners.
  - Support keyboard, gamepad, and touch controls.

### Phase P5: Optimization & Production Certification
- [ ] **Task P5.1 (Performance Profiling)**: Verify $\ge 60\text{ FPS}$ desktop and $\ge 30\text{ FPS}$ mobile.
- [ ] **Task P5.2 (Automated Test Suite)**: Run full test suite (80+ suites) with 100% pass rate.
- [ ] **Task P5.3 (Certification Artifacts)**: Generate `production-certification.json`, `IMPLEMENTATION_WALKTHROUGH.md`, updated `CHANGELOG.md` and `TODO.md`.

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
3. **Automated Road Clearance & Bot Traversal Audit**:
   ```powershell
   podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd --filter="test_all_worlds_pass_geometric_road_clearance_audit"
   ```
4. **Standalone Packager & Production Certification**:
   ```powershell
   python scripts/modular_packager.py
   python scripts/certifier.py
   ```

