# IMPLEMENTATION PLAN: VOLTARENA COMPREHENSIVE PRODUCTION REMEDIATION, GAMEPLAY REBUILD & VISUAL OVERHAUL

**Role**: Principal Godot Game Engineer, AAA Gameplay/Physics Designer, Technical Artist, UI/UX Architect, Performance Engineer, QA Lead  
**Repository**: `dayashimoga/VoltArena`  
**Engine & Target**: Godot 4.3 Stable (Desktop Windows/Linux, Web, Mobile)  
**Date**: October 2026  
**Status**: ACTIVE EXECUTION PLAN (IN PROGRESS)

---

## 1. Executive Summary & Authoritative Defect Evidence

The VoltArena suite consists of 10 commercial-grade 3D games and a unified launcher. Recent forensic audits, player feedback, and authoritatively supplied packaged runtime screenshots and videos demonstrate that despite previously passing unit tests, **AeroRush** and **Chroma Rush** suffer from critical gameplay identity, physics, camera, and visual defects that prevent them from reaching commercial quality.

### Authoritative Defect Evidence (Screenshots 1-5 & Packaged Runtime)

1. **Defect Evidence 1 (AeroRush Screenshot 1: Dark Void, Barren Floor & Pitch-Black Shadows)**:
   - *Observation*: The player vehicle sits on a pitch-black surface registering 0 KM/H, looking out across an empty, barren expanse. A few distant orange and beige monolithic rectangular towers stand isolated in the void under a flat gradient sunset sky. Shadows are 100% crushed pitch-black. The vehicle is a crude kart-like box model with oversized exposed wheels.
   - *Diagnosis*: AeroRush lacks coherent ambient lighting, atmospheric depth, terrain, and road contrast. Surfaces in shadow fall into total blackness because Godot 4's Compatibility renderer lacks proper ambient sky configuration. The environment looks like an untextured technical prototype.

2. **Defect Evidence 2 (AeroRush Screenshot 2: Oversized Blinding White Checkpoint / Barrier Obscuring View)**:
   - *Observation*: At the race starting line, an enormous, blindingly bright solid white rectangular box completely covers the center of the viewport, blocking forward visibility and reflecting heavily on the glossy track deck.
   - *Diagnosis*: `AeroCheckpoint` start gate / holographic barrier had blown-out emission and an opaque rectangular geometry/quad facing the camera at vehicle eye level. The portal must be completely open and unobstructed, with sleek overhead carbon-steel gantry framing, suspended signal clusters, and zero blinding white opaque blockers.

3. **Defect Evidence 3 (AeroRush Screenshot 3: Track Appearing Continuous Instead of Disconnected Stunt Platforms)**:
   - *Observation*: Track appears as a single continuous elevated roadway with basic neon arches and narrow repeated towers in empty terrain. Courses 2-12 have no gap partitioning at all.
   - *Diagnosis*: Courses lacked genuinely physically separated platform islands with distinct entry kickers, ballistic trajectories, wide landing aprons, and open airspace. Geometry was treated as an uninterrupted Catmull-Rom spline.

4. **Defect Evidence 4 (AeroRush Screenshot 4: UI Text Clipped Offscreen 'BO BANKED!')**:
   - *Observation*: Top-left HUD displays clipped text `BO BANKED!` with `+X COM` cut off by the viewport edge.
   - *Diagnosis*: In `aero_hud.gd`, `stunt_toast` and `countdown_label` use `set_anchors_preset(PRESET_CENTER)` followed by hardcoded negative local position `Vector2(-200, 40)`, displacing the control into negative coordinate space (off-screen left). Proper anchoring and layout containers are required.

5. **Defect Evidence 5 (AeroRush Screenshot 5: Fragmented Backface Geometry Floating in Sky & Vehicle Boundary Escape)**:
   - *Observation*: On physical TV display, the vehicle has escaped intended course bounds onto a flat orange plane, with black inverted shards and fragmented track underside faces floating in the sky.
   - *Diagnosis*: Underside track faces lacked double-sided collision/rendering or proper solid extrusion geometry, causing backface culling to show black shards when viewed from below/off-track. Vehicle out-of-bounds detection was too permissive (>95m from last checkpoint or Y < -30m), allowing uncontrolled flight into void space.

6. **Defect Evidence 6 (Chroma Rush Camera Vibration & Sidewalk Wedging)**:
   - *Observation*: Camera shakes uncontrollably; FOV and distance rapidly oscillate while driving; cars wedge against thin streetlight posts and sidewalk curbs.
   - *Diagnosis*: `chroma_rush_main.gd` camera updates had discrete deadzone speed steps (`CAM_SPEED_DEADZONE`), look-ahead target was magnified 7m ahead of oscillating chassis pitch, and streetlights/trees were placed at $\pm 9.5\text{m}$ (only 2m from road edge) with rigid static collision bodies.

---

## 2. Root Cause Analysis (RC-18 through RC-29)

| Defect ID | Surface Symptom | Deep Technical Root Cause |
| :--- | :--- | :--- |
| **RC-18: Continuous Spline Geometry vs Physical Islands** | AeroRush tracks appear continuous instead of consisting of distinct separated stunt sections | `aero_course_database.gd` defined courses 2-12 without `islands` or `is_jump_gap`; `aero_track_generator.gd` grouped all waypoints into a single continuous ribbon if `is_jump_gap` was false. Reference circuit and course definitions require explicit physically disconnected island definitions with entry kickers, ballistic air gaps, and wide catch aprons. |
| **RC-19: Oversized Blinding White Checkpoint / Barrier** | Screenshot 2 shows blinding solid white rectangular box blocking forward view | `AeroCheckpoint` start gate / holographic barrier had blown-out emission and opaque rectangular geometry/quad facing camera at vehicle eye level. The portal must be completely open and unobstructed, with sleek overhead carbon-steel gantry framing, suspended signal clusters, and zero blinding white opaque blockers. |
| **RC-20: Reverse Model Orientation & Exposed Floating Wheels** | Vehicles look like crude karts with backwards bodies and wheels floating in space | In `aero_vehicle_visuals.gd`, `body_model` was imported from `car_race_future.glb` without 180° Y rotation (`rotation.y = PI`), causing the vehicle body to face backwards. Wheels were placed at $X = \pm 0.76$ when the vehicle body wells were at $X = \pm 0.46$, leaving wheels and brake discs floating in mid-air. |
| **RC-21: HUD Notification Coordinate Clipping ('BO BANKED!')** | Stunt toast text is clipped off-screen to the left (Screenshot 4) | In `aero_hud.gd`, `stunt_toast` and `countdown_label` use `set_anchors_preset(PRESET_CENTER)` followed by direct `position = Vector2(-200, 40)`, placing the first 200 pixels at negative screen coordinates. |
| **RC-22: Backface Culling & Fragmented Sky Geometry** | Underside of track shows broken black shards against sky; vehicle escapes course (Screenshot 5) | Underside surface tool used `cull_back` without double-sided or solid slab extrusion geometry; vehicle boundary checking permitted vehicles to fly >95m before recovering. |
| **RC-23: Crushed Black Shadows & Barren Void Terrain** | Road and ground surfaces appear pitch black; scene looks like technical prototype (Screenshot 1) | `aero_world_megacity.gd` placed an empty 1800m flat grey polygon with 20 distant scattered towers and isolated trees; `WorldEnvironment` lacked balanced ambient sky lighting in Godot 4 Compatibility renderer. |
| **RC-24: Chroma Rush Camera Vibration, Jitter & FOV Pumping** | Camera shakes uncontrollably; FOV and distance rapidly oscillate while driving | In `chroma_rush_main.gd`, camera updates had discrete deadzone speed steps (`CAM_SPEED_DEADZONE`), look-ahead target was magnified 7m ahead of oscillating chassis pitch, and double-smoothed position lerps caused phase-lag oscillation. |
| **RC-25: Street Obstacle Trapping & Sidewalk Wedging** | Cars get stuck against thin streetlight posts and curbs on sidewalks | Streetlights and trees were placed at $\pm 9.5\text{m}$ (immediately adjacent to the 15m road verge) with rigid static cylinder collision bodies without deflection buffers or soft collision layers. |
| **RC-26: Procedural Cylindrical/Box Towers in Chroma Rush** | Background city consists of smooth glossy cylinders and primitive cubes | `neon_city.gd` generates distant skyline using procedural multi-mesh boxes and cylinders rather than instancing real authored GLB skyscraper models (`building_skyscraper_a.glb` through `e.glb`) with PBR textures. |
| **RC-27: Unconstrained Airborne Tumbling & Hard Landings** | Vehicles spin uncontrollably off jumps, flip upside down, or crash unpredictably | In `aero_vehicle.gd`, angular damping was insufficient during ballistic flight; steering inputs applied unconstrained torque; vehicle lacked automatic horizon stabilization bias and predictive landing deck alignment. |
| **RC-28: Universal ESC / Pause Navigation Incompleteness & Conflicts** | ESC does not reliably expose full navigation across all games; players get trapped | `shared/ui/pause_menu.gd` input handling competed with individual game HUD pause dialogs; `pause_menu.show_pause()` was not called uniformly, leading to unpaused tree or invisible panels. |
| **RC-29: Standalone PCK Isolation & Verification** | Standalone exports require verification against clean build manifests | `scripts/modular_packager.py` and GitHub Actions require explicit standalone validation to ensure zero cross-game asset leakage. |

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
