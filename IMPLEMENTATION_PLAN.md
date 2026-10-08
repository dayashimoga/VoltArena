# IMPLEMENTATION PLAN: VOLTARENA COMPREHENSIVE PRODUCTION REMEDIATION, GAMEPLAY REBUILD & VISUAL OVERHAUL

**Role**: Principal Godot Game Engineer, AAA Gameplay/Physics Designer, Technical Artist, UI/UX Architect, Performance Engineer, QA Lead  
**Repository**: `dayashimoga/VoltArena`  
**Engine & Target**: Godot 4.3 Stable (Desktop Windows/Linux, Web, Mobile)  
**Date**: October 2026  
**Status**: ACTIVE EXECUTION PLAN (IN PROGRESS)

---

## 1. Executive Summary & Authoritative Defect Evidence

The VoltArena suite consists of 10 commercial-grade 3D games and a unified launcher. Recent forensic audits, player feedback, and authoritatively supplied packaged runtime screenshots and videos demonstrate that despite previously passing unit tests, **AeroRush** and **Chroma Rush** suffer from critical gameplay identity, physics, camera, and visual defects that prevent them from reaching commercial quality.

### Authoritative Defect Evidence (Screenshots 1-3 & Runtime Video)

1. **Defect Evidence 1 (AeroRush Screenshot 1: Dark Void, Barren Floor & Pitch-Black Shadows)**:
   - *Observation*: The player vehicle sits on a pitch-black surface registering 0 KM/H, looking out across an empty, barren expanse. A few distant orange and beige monolithic rectangular towers stand isolated in the void under a flat gradient sunset sky. Shadows are 100% crushed pitch-black. The vehicle is a crude kart-like box model with oversized exposed wheels.
   - *Diagnosis*: AeroRush lacks coherent ambient lighting, atmospheric depth, terrain, and road contrast. Surfaces in shadow fall into total blackness because Godot 4's Compatibility renderer lacks proper ambient sky configuration. The environment looks like an untextured technical prototype.

2. **Defect Evidence 2 (AeroRush Screenshot 2: Continuous Road Masquerading as Stunt Track)**:
   - *Observation*: Starting grid on a dark flat surface leading straight down a continuous road with a few white goal arches, leading toward a basic elevated ramp. Distant background consists of scattered rectangular monoliths.
   - *Diagnosis*: AeroRush is failing its core gameplay identity: **high-speed aerial stunt traversal across physically disconnected tracks and platforms**. It is currently built as an ordinary continuous elevated road with decorative discontinuities rather than genuinely separated platforms with varied elevations, orientations, banking, loops, wall rides, and calculated ballistic air gaps.

3. **Defect Evidence 3 (Chroma Rush Screenshot 3: Car Wedged on Sidewalk Pole, Blocky Trees & Toy City)**:
   - *Observation*: The player car is wedged against a thin metal streetlight post on the sidewalk curb, completely trapped. Next to the curb stands an extremely simplistic low-poly block tree (green cubes attached to a brown stick). The background skyline consists of giant smooth, glossy cylindrical and capsule procedural monoliths. The road is a flat grey texture with basic lines.
   - *Diagnosis*: Chroma Rush city composition is simplistic and toy-like. Rigid static streetlight posts with cylinder collision are placed right against the road/curb with zero vehicle deflection, trapping cars. The distant skyline relies on procedural rounded blocks rather than authored PBR skyscrapers. Furthermore, runtime video reveals severe camera vibration, rapid zoom-in/out, and FOV pumping while driving.

---

## 2. Root Cause Analysis (RC-18 through RC-26)

| Defect ID | Surface Symptom | Deep Technical Root Cause |
| :--- | :--- | :--- |
| **RC-18: Continuous Spline Geometry vs Physical Islands** | AeroRush track is a continuous elevated highway with minor holes; fails stunt identity | `aero_course_database.gd` and `aero_track_generator.gd` treat the track as a single uninterrupted Catmull-Rom spline. Gaps are implemented merely by skipping quad generation along the continuous curve rather than generating genuinely separated, individually oriented physical platform islands with distinct entry kickers, ballistic trajectories, wide landing aprons, and open airspace. |
| **RC-19: Lack of Automated Ballistic Trajectory Validation** | Gaps are either unreachable or lack discoverable launch/landing routes | Trajectory solver was an analytical approximation that did not account for actual vehicle mass, drag, gravity, launch kicker angle, landing apron width, and orientation matching at 30, 60, and 120 FPS. |
| **RC-20: Unconstrained Airborne Tumbling & Hard Landings** | Vehicles spin uncontrollably off jumps, flip upside down, or crash unpredictably | In `aero_vehicle.gd`, when ungrounded, angular damping is insufficient; ordinary steering inputs apply direct angular torque causing tumbling; vehicle lacks active horizon stabilization bias, dedicated stunt rotation mode, and predictive landing alignment assistance. |
| **RC-21: Crushed Black Shadows & Dark Untextured Surfaces** | Road and ground surfaces appear pitch black; shadows are 100% black; scene looks barren | In `aero_world_base.gd`, `WorldEnvironment` uses `ProceduralSkyMaterial` without setting `ambient_light_source = AMBIENT_SOURCE_SKY`, `ambient_light_energy = 1.2`, and `ambient_light_sky_contribution = 0.85`. In Godot 4 Compatibility renderer, missing ambient sky parameters cause all shadowed surfaces to render pitch black. |
| **RC-22: Prototype Kart Visuals Instead of Detailed Fictional Stunt Cars** | Vehicles look like low-poly karts with toy-like block wheels | `aero_vehicle_visuals.gd` and `vehicle_catalog.gd` use simple procedural primitives or generic kart models instead of authentic fictional sports/stunt vehicles with PBR materials, transparent tinted glass, active aero wings, LED lighting, brake calipers, and animated suspension. |
| **RC-23: Chroma Rush Camera Vibration, Jitter & FOV Pumping** | Camera shakes uncontrollably; FOV and distance rapidly oscillate while driving | In `chroma_rush_main.gd`, camera updates were run in `_physics_process(delta)` rather than `_process(delta)`, creating framerate-physics cadence mismatch; camera look-at target was tied directly to chassis pitch oscillations; FOV calculation used a discrete deadzone step (`CAM_SPEED_DEADZONE`) that caused abrupt FOV jumps. |
| **RC-24: Street Obstacle Trapping & Sidewalk Wedging** | Cars get stuck against thin streetlight posts and curbs on sidewalks | Streetlights and secondary props are instantiated with rigid static cylinder collision bodies placed at $10.8\text{m}$ (immediately adjacent to the $9.35\text{m}$ sidewalk curb) without deflection buffers or breakable/pass-through collision layers. |
| **RC-25: Procedural Cylindrical/Box Towers in Chroma Rush** | Background city consists of smooth glossy cylinders and primitive cubes | `neon_city.gd` generates distant skyline using procedural multi-mesh boxes and cylinders (`_create_stepped_skyline_mesh`, etc.) rather than instancing real authored GLB skyscraper models (`building_skyscraper_a.glb` through `e.glb`) with PBR textures, architectural setbacks, and distinct district styling. |
| **RC-26: Universal ESC / Pause Navigation Incompleteness** | ESC does not reliably expose full navigation across all games; players get trapped | `shared/ui/pause_menu.gd` lacks unified submenus for Controls, Audio, Graphics, Accessibility, and actions for Resume, Restart Checkpoint, Restart Event, Main Menu, Launcher, and Quit. |

---

## 3. Prioritized Remediation Framework (P0 - P3)

### Priority P0: Game-Breaking Gameplay, Physics & Camera Architecture
- **P0-AERO-01**: **Rebuild Core Stunt Gameplay & Disconnected Island Circuit**:
  - Implement a reference circuit (`Apex Circuit / Neon Stunt Odyssey`) featuring genuinely physically separated track segments across 3D space:
    1. Acceleration Launch Track with speed boost pads & upward launch kicker ramp.
    2. [Ballistic Air Gap 1 - 50m]: Airborne flight over urban basin.
    3. Elevated Landing Deck B: Wide funnel apron, hazard curbs, and 35° banked sweeping turn.
    4. 360° Vertical Stunt Loop: Smooth parallel-transport loop arch with magnetic downforce.
    5. Angled Launch Ramp: High-speed trajectory launch.
    6. [Elevated Air Transfer Gap 2 - 45m]: Soaring transfer to elevated rooftop.
    7. Rooftop Platform C & 75° Skyscraper Wall Ride: Magnetic adhesion and high-speed wall traversal.
    8. Corkscrew Jump: Helical launch with rotational twist.
    9. [Air Gap 3 - 40m]: Corkscrew gap transfer.
    10. Split Route Platform D:
        - Route 1 (Precision Stunt Route): Narrow elevated beam with double stunt multiplier.
        - Route 2 (High-Speed Route): Wide banked perimeter bypass with boost recharge.
    11. Checkpoint Gantry & Pre-Mega Launch Runway.
    12. Final Mega Jump Ramp: Soaring mega jump across stadium airspace.
    13. Finish Stadium Platform: Checkered arch, floodlight pylons, crowd grandstands, and podium.
  - Zero fake gaps: Platforms and collision surfaces are 100% physically disconnected.
- **P0-AERO-02**: **Automated Trajectory Validator**:
  - Implement dynamic trajectory simulation verifying launch speed (min/target/max), gravity, airtime, jump distance, landing alignment, and landing apron width for every gap. Reject impossible course geometry.
- **P0-AERO-03**: **Arcade Airborne Physics & Predictive Landing Assistance**:
  - Responsive arcade steering, acceleration, braking, drift mini-turbos, and nitro boost.
  - Speed-sensitive steering and controlled lateral traction to prevent unintentional sliding off tracks.
  - Bounded airborne angular velocity (pitch, yaw, roll); angular damping; automatic horizon stabilization bias.
  - Dedicated stunt mode (Shift/Handbrake) for intentional controlled flips, flat spins, and barrel rolls.
  - Predictive landing assistance: Projects landing surface normal and smoothly guides vehicle orientation without visible teleporting or snapping.
  - Fair touchdown impact, suspension compression, rebound, crash detection ($v > 18\text{ m/s}$ and angle $> 75^\circ$), and smooth checkpoint recovery.
- **P0-CHROMA-01**: **Permanent Camera Stabilization & FOV Smoothing**:
  - Move camera pipeline to `_process(delta)` using frame-rate independent critically damped smoothing.
  - Decouple look-ahead target from high-frequency chassis pitching and collision impulses.
  - Eliminate discrete deadzone FOV jumps; use continuous rate-limited low-pass filter with bounded range [70°, 78°].
  - Completely fixed camera distance (no dynamic distance stretching).
- **P0-CHROMA-02**: **Street Furniture Collision & Clearance Fix**:
  - Relocate streetlights and roadside props to safe setbacks ($\ge 13.5\text{m}$ on straights, $\ge 15.5\text{m}$ on curves).
  - Use soft/breakable collision shapes for streetlamps and small props so vehicles can never wedge or get permanently trapped.

### Priority P1: Visual Overhaul & Environmental Reconstruction
- **P1-AERO-01**: **AeroRush Complete Visual & Environmental Reconstruction**:
  - Balanced lighting presets: Coherent Daylight, Golden Sunset, and Cyberpunk Dusk with calibrated ambient sky light (`ambient_light_energy = 1.2`), fill light, balanced ACES tonemapper (exposure 1.15), and clear atmospheric perspective.
  - Eliminate pitch-black surfaces and crushed shadows.
  - Track aesthetics: Dark textured slate asphalt, high-contrast orange/white curbs, emissive cyan/magenta guide rails, glowing launch chevrons, landing catch markings, and architectural support pillars extending down to the ground.
  - Environment: Believable large-scale urban basin, grandstands, floodlights, commercial plazas, realistic palms and oak trees, transit skybridges, and 360° layered perimeter skyline.
- **P1-AERO-02**: **AeroRush Fictional Performance Stunt Vehicles**:
  - Integrate detailed fictional performance/stunt vehicles (`car_race_future.glb`, `car_race.glb`, etc.) with sleek bodywork, tinted glass canopy, functional active aero wings, front splitters, rear diffusers, multi-piece wheels with ventilated brake discs and red calipers, LED projector headlights, dynamic brake lights, and PBR automotive metallic paint.
  - Animate wheel spin, steering yaw, suspension compression/travel, body roll, braking dive, and restrained VFX (sparks, tire smoke, boost flames, wingtip air ribbons).
- **P1-CHROMA-01**: **Chroma Rush City & Vehicle Reconstruction**:
  - 6 distinct urban districts: Downtown Financial Core, Commercial Promenade, Industrial Logistics Viaduct, Neon Entertainment Strip, Waterfront Marina, Historic Old Town.
  - Authored PBR architecture: Replace procedural cylinder/box monoliths with real authored GLB models (`building_skyscraper_a.glb` through `e.glb`, `building_comm_a.glb` through `f.glb`, `building_a.glb` through `d.glb`).
  - Organic foliage: Scaled trees with trunks, branches, and lush leaf canopies (`tree_oak.glb`, `tree_palm.glb`, `tree_pine.glb`, `tree_tall.glb`) with botanical PBR materials, shrubs, and sidewalk planters.
  - Believable roads: Multi-lane markings, dashed centerlines, crosswalks, stop lines, curbs, and realistic street furniture.
  - Detailed modern cars: PBR automotive paint, glass, lights, and animated suspension. Color swaps alter paint appearance while preserving metallic, roughness, and material details.

### Priority P2: UI/UX, Modes & Multi-Game Preservation
- **P2-UNIV-01**: **Universal Modern UI/UX & ESC Pause Navigation**:
  - Glassmorphic, responsive, resolution-independent layouts.
  - Quick Play 1-click to countdown across both games.
  - Universal ESC/Gamepad Pause Menu: Resume, Restart Checkpoint, Restart Event, Controls, Graphics (Low/Med/High/Ultra), Audio (Master/Music/SFX), Accessibility, Main Menu, Launcher / Quit.
- **P2-AERO-01**: **AeroRush Game Modes & Stunt Progression**:
  - Modes: Stunt Race, Gap Master, Time Attack, Precision Landing, Air Combo, Championship.
  - Real-time scoring: airtime, jump distance, flips, spins, rolls, wall rides, drifts, precision landings.
- **P2-CHROMA-01**: **Atomic Bidirectional Color Swap UX**:
  - Energy swap particle arc, dynamic light pulse, HUD target indicator, smooth delivery checkpoint navigation.
- **P2-VOLT-01**: **Suite-Wide Regression Protection**:
  - Guarantee zero regressions across Arena FPS, Subway Survival, Rocket Car, Kart Racing, RoboForge, Skybound Odyssey, Strike Vector, and WildCircuit.

### Priority P3: Optimization, Packaging & CI/CD
- **P3-OPT-01**: Performance optimization: MultiMesh instancing for skyline, LODs, frustum culling, object pooling, solid 60 FPS target.
- **P3-PKG-01**: Standalone and full-suite packaging verification via `modular_packager.py` and GitHub Actions CI.

---

## 4. File-Level Change Matrix

| Component | Target File | Action | Key Functions & Responsibilities |
| :--- | :--- | :--- | :--- |
| **AeroRush Track Gen** | `games/aero-rush/tracks/aero_track_generator.gd` | Modify | Generate genuinely physically disconnected track platform islands (`build_disconnected_stunt_circuit`); build launch ramps with kickers and emissive chevron guides; build landing aprons with catch barriers and hazard striping; build architectural support pillars under elevated platforms connecting to ground; generate double-sided collision meshes per island. |
| **AeroRush Courses** | `games/aero-rush/tracks/aero_course_database.gd` | Modify | Rebuild reference circuit (`neon_express` / `apex_horizon`) into an authoritative multi-island stunt course: Start Track -> Launch Ramp A -> [Air Gap 1] -> Landing Platform B -> Banked Turn -> 360° Loop -> Angled Launch -> [Air Transfer Gap 2] -> Rooftop Platform C -> 75° Wall Ride -> Corkscrew Launch -> [Air Gap 3] -> Split Route Platform D (Precision vs High-Speed) -> Checkpoint Deck -> Final Mega Jump Ramp -> [Mega Air Gap 4] -> Finish Stadium Platform. Update course definitions with explicit island boundaries. |
| **AeroRush Validator** | `games/aero-rush/tracks/aero_track_validator.gd` | Modify | Automated trajectory validation: simulate ballistic trajectory across all gap islands at min/target/max speeds, validating airtime, gravity, jump distance, landing apron dimensions, and landing normal alignment. Reject impossible geometry. |
| **AeroRush Vehicle Physics** | `games/aero-rush/vehicles/aero_vehicle.gd` | Modify | Implement speed-sensitive steering, controlled lateral grip, suspension travel, bounded airborne angular velocity, angular damping, automatic horizon stabilization bias, dedicated stunt rotation mode (Shift/Handbrake), predictive landing alignment assistance, fair touchdown impact/crash detection ($v > 18\text{ m/s}$ and angle $> 75^\circ$), and smooth checkpoint recovery. |
| **AeroRush Physics Helpers** | `games/aero-rush/vehicles/aero_physics_helpers.gd` | Modify | Update landing evaluation, predictive landing raycasting, horizon stabilization math, and effective gravity on loops/wall rides. |
| **AeroRush Vehicle Visuals** | `games/aero-rush/vehicles/aero_vehicle_visuals.gd` | Modify | Replace prototype kart visuals with detailed fictional performance stunt cars (`car_race_future.glb`, `car_race.glb`); PBR metallic paint shader with clearcoat, tinted glass canopy, active articulated aero wings, splitters, diffusers, disc brakes with red calipers, LED headlights/taillights, animated wheel roll, steering yaw, suspension travel, and restrained VFX. |
| **AeroRush Vehicle Catalog** | `games/aero-rush/vehicles/aero_vehicle_catalog.gd` | Modify | Configure 4 distinct performance stunt vehicle archetypes (Apex Striker, Stryker Turbo, Dune Crusher, Quantum GT) with tuned speed, handling, mass, and aero specs. |
| **AeroRush Environment** | `games/aero-rush/worlds/aero_world_base.gd` | Modify | Calibrate lighting and environment: add ambient sky lighting (`ambient_light_source = AMBIENT_SOURCE_SKY`, `ambient_light_energy = 1.2`, `ambient_light_sky_contribution = 0.85`), directional key sunlight with soft shadows, balanced ACES tonemapper (exposure 1.15), and clear atmospheric depth. Completely eliminate pitch-black shadows. |
| **AeroRush Megacity World** | `games/aero-rush/worlds/aero_world_megacity.gd` | Modify | Rebuild urban environment: grandstands, floodlight towers, authored skyscrapers flanking boulevards, reflective water canal, transit skybridges, avenue trees, and 360° layered perimeter skyline. |
| **AeroRush Coordinator** | `games/aero-rush/aero_rush_main.gd` | Modify | Coordinate multi-island track instantiation, safe spawn surface probing, checkpoint sequence, stunt combo scoring, HUD telemetry, and universal ESC pause menu. |
| **Chroma Rush Camera** | `games/chroma-rush/chroma_rush_main.gd` | Modify | Move camera update pipeline to `_process(delta)`; implement critically damped frame-rate-independent smoothing on vehicle visual transform; decouple look-ahead from chassis pitch chatter; rate-limit FOV changes with continuous low-pass filter (eliminate deadzone FOV pumping); maintain fixed camera distance. |
| **Chroma Rush City World** | `games/chroma-rush/worlds/neon_city.gd` | Modify | Rebuild city with 6 distinct districts: Downtown Financial Core, Commercial Promenade, Industrial Logistics Viaduct, Neon Entertainment Strip, Waterfront Marina, Historic Old Town. Replace procedural cylinder/box monoliths with authored PBR skyscraper models (`building_skyscraper_a.glb` through `e.glb`, `building_comm_a.glb` through `f.glb`). Move streetlights and props to safe setbacks ($\ge 13.5\text{m}$). Add breakable/soft collision for secondary street furniture. Add botanical PBR trees (`tree_oak.glb`, `tree_palm.glb`, `tree_tall.glb`). Add multi-lane road markings. |
| **Chroma Rush Road Base** | `games/chroma-rush/worlds/world_base.gd` | Modify | Update road network with clear lane markings, pedestrian sidewalks, and safe prop setback zones. |
| **Chroma Rush Vehicles** | `games/chroma-rush/vehicles/vehicle_visuals.gd` | Modify | Replace block toy cars with detailed modern fictional vehicles (`car_sedan_sports.glb`, `car_hatchback_sports.glb`, `car_suv_luxury.glb`, etc.) with PBR metallic paint, glass, wheels, and animated suspension. Ensure color swap preserves materials. |
| **Universal Pause Menu** | `shared/ui/pause_menu.gd` | Modify | Complete universal pause menu: Resume, Restart Checkpoint, Restart Event, Controls, Graphics presets (Low/Med/High/Ultra), Audio sliders (Master/Music/SFX), Accessibility, Main Menu, Launcher / Quit. Full keyboard, mouse, and gamepad navigation. |
| **Automated Tests** | `tests/runner.gd` & new test files | Modify/Create | Add deterministic test suites for: disconnected track island continuity, ballistic trajectory reachability, airborne vehicle stabilization, camera jitter/FOV stability, and universal pause menu navigation. |

---

## 5. Execution Sequence & Dependencies

```
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: AERORUSH CORE STUNT TRACK & DISCONNECTED ISLAND ARCHITECTURE │
│ - Implement multi-island track generator (aero_track_generator.gd)     │
│ - Author reference circuit with 6 distinct islands & 4 physical gaps   │
│ - Implement dynamic ballistic trajectory validator (aero_track_val...) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: AERORUSH ARCADE VEHICLE PHYSICS & AIRBORNE CONTROL            │
│ - Speed-sensitive steering, lateral traction, suspension dynamics      │
│ - Bounded angular velocity, angular damping, horizon stabilization     │
│ - Dedicated stunt maneuvers (flips, spins, rolls) & combo system       │
│ - Predictive landing alignment assistance & fair touchdown impact      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: AERORUSH VISUAL & ENVIRONMENTAL RECONSTRUCTION                │
│ - Calibrate lighting (ambient sky, fill light, ACES tonemap, no black) │
│ - Track aesthetics (asphalt, neon rails, launch chevrons, supports)    │
│ - Fictional performance stunt vehicles (car_race_future.glb, PBR paint)│
│ - Layered Megacity environment (grandstands, skyscrapers, skybridges)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: CHROMA RUSH CAMERA STABILITY & OBSTACLE CLEARANCE             │
│ - Move camera to _process(delta) with critically damped smoothing      │
│ - Decouple look-ahead target; eliminate deadzone FOV pumping           │
│ - Relocate streetlights to >=13.5m setback; soften secondary collision │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: CHROMA RUSH CITY RECONSTRUCTION & VEHICLE OVERHAUL            │
│ - 6 distinct districts with authored PBR skyscraper models             │
│ - Organic botanical trees, street life, and multi-lane road markings   │
│ - Detailed fictional modern vehicles with material-preserving swaps   │
│ - Atomic color swap audio-visual feedback polish                       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: UNIVERSAL MODERN UI/UX, MODES & PROGRESSION                   │
│ - Complete universal PauseMenu (Resume, Restart, Controls, Settings)  │
│ - 1-action Quick Play across both games; modernized HUDs               │
│ - AeroRush event modes (Stunt Race, Gap Master, Time Attack, etc.)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: AUTOMATED VERIFICATION, REGRESSION GATES & DOCUMENTATION      │
│ - Execute 100% passing test battery across all 10 VoltArena titles    │
│ - Validate standalone & suite packages in container environment        │
│ - Capture packaged runtime screenshots & video evidence                │
│ - Update IMPLEMENTATION_WALKTHROUGH.md, CHANGELOG.md, and TODO.md      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Measurable Acceptance Criteria & Verification Gates

| Gate ID | Target | Pass Criteria |
| :--- | :--- | :--- |
| **GATE-AERO-ISLANDS** | Disconnected Track Geometry | Course consists of at least 5 physically separated track platform islands with distinct elevations ($Y=1\text{m}$ to $38\text{m}$), banking ($0^\circ$ to $75^\circ$), and zero collision mesh beneath air gaps. |
| **GATE-AERO-TRAJECTORY** | Ballistic Reachability | Trajectory solver certifies 100% of mandatory gaps are reachable at attainable vehicle speeds ($26$ to $48\text{ m/s}$) with landing alignment error $< 15^\circ$ and landing apron clearance $> 4.0\text{m}$. |
| **GATE-AERO-AIRBORNE** | Flight Control & Stabilization | In-flight vehicle obeys bounded angular velocity ($\le 4.5\text{ rad/s}$); automatic horizon stabilization pulls vehicle wheels-down; predictive landing assistance aligns vehicle with landing normal; fair touchdown detects crashes only at severe angles ($>75^\circ$) and high speeds ($>18\text{ m/s}$). |
| **GATE-AERO-LIGHTING** | Visual Visibility & Lighting | Shadows have non-zero ambient illumination (min surface luminance $> 0.12$); no pitch-black surfaces; track edges and upcoming gaps clearly discernible at $200\text{ km/h}$. |
| **GATE-AERO-VEHICLE** | Vehicle Model & Animation | Vehicle has authentic proportions, PBR metallic paint, tinted glass canopy, active aero wing, ventilated disc brakes with calipers, animated wheel spin, steering, and suspension. |
| **GATE-CHROMA-CAMERA** | Camera Stability & Telemetry | Straight driving FOV variance $< 0.02^\circ$; zero high-frequency vibration; no FOV pumping; fixed camera distance; stable behavior at 30, 60, and 120 FPS. |
| **GATE-CHROMA-CITY** | Urban Realism & Obstacles | Streetlights and props have safe setback ($\ge 13.5\text{m}$); zero vehicles trapped against poles; 6 distinct districts; authored PBR skyscraper models; botanical organic trees. |
| **GATE-UNIV-PAUSE** | Universal Navigation | ESC / Gamepad opens pause menu in every game with Resume, Restart Checkpoint, Restart Event, Controls, Settings, Main Menu, and Launcher/Quit. |
| **GATE-SUITE-ZERO-REG** | VoltArena Suite Integrity | 100% tests passing across all 10 games with zero functional or visual regressions. |
| **GATE-STANDALONE-PKG** | Independent Packaging | Standalone packages for AeroRush and ChromaRush build cleanly with distinct sizes and standalone manifests. |
