# VOLTARENA v14.0.0 — APEX FLIGHT & URBAN LEGENDS TARGETED PRODUCTION REMEDIATION PLAN

**Role**: Principal Godot 4.3 Engineer, Flight/Vehicle Physics Specialist, 3D Artist and QA Architect  
**Repository**: `dayashimoga/VoltArena`  
**Engine & Rendering**: Godot 4.3 Stable (`gl_compatibility` across Windows, Linux, WebGL/WASM, Android)  
**Target Scope**: Fix **Apex Flight** and **Urban Legends** exclusively; preserve all working features and prevent regressions across the 12-game suite.  
**Date**: October 2026  
**Status**: APPROVED IMPLEMENTATION PLAN — READY FOR SEQUENTIAL EXECUTION (P0–P5)

---

## 1. Forensic Audit & Root Cause Analysis

Based on comprehensive runtime inspection, telemetry, container execution, and user defect screenshots:

### 1.1 Urban Legends Defects
1. **Reversed Steering Geometry (P0)**:
   - *Symptom*: Pressing Right (`D` / `Right Arrow` / Gamepad stick right) turns the car Left; pressing Left turns the car Right.
   - *Root Cause*: In `games/urban-legends/vehicles/urban_vehicle.gd` line 352, `rotate_object_local(Vector3.UP, yaw_rate * delta)` is called with `yaw_rate = current_steer_angle * speed_scale * 3.2`. By Godot 3D right-hand coordinate convention (+Y up, -Z forward, +X right), a positive rotation around `Vector3.UP` rotates the nose counter-clockwise (towards -X, Left). When the driver steers Right (`steer_input = +1.0`), `current_steer_angle > 0`, producing positive `yaw_rate` which turns the car Left!
   - *Remediation*: Invert the yaw application to `-yaw_rate * delta` (or `-current_steer_angle`) in both ground steering (`rotate_object_local(Vector3.UP, -yaw_rate * delta)`) and air stunt yaw (`rotate_object_local(Vector3.UP, -air_yaw)`).
2. **Primitive Box Cars (P1)**:
   - *Symptom*: The player and traffic vehicles are crude, boxy geometry consisting of three stacked `BoxMesh` slabs and a stick spoiler (Screenshots 4 & 5).
   - *Root Cause*: `urban_vehicle_visuals.gd` assembles vehicles entirely from raw `BoxMesh` and `CylinderMesh` primitives, completely ignoring the production-grade GLTF models in `res://assets/models/vehicles/` (`car_sedan_sports.glb`, `car_race.glb`, `car_race_future.glb`, `car_suv_luxury.glb`, `car_hatchback_sports.glb`, etc.).
   - *Remediation*: Rebuild `urban_vehicle_visuals.gd` to instantiate authentic 3D vehicle models with animated spinning alloy wheels (`car_wheel_racing.glb`), suspension compression, PBR automotive clearcoat paint shader, working projector LED headlights, reactive brake lights, and visible tinted glass.
3. **Empty Desert Void & Sparse Monolith Blocks (P2)**:
   - *Symptom*: The city consists of a barren flat brown expanse with only 9 identical black box towers placed miles apart (Screenshots 4 & 5).
   - *Root Cause*: `urban_world_generator.gd` placed only 9 hardcoded `build_skyscraper` boxes in Downtown, with vast empty areas between districts.
   - *Remediation*: Overhaul `urban_world_generator.gd` and `urban_prop_factory.gd` into a dense, connected New York-inspired metropolis featuring authentic skyscrapers (`building_skyscraper_a.glb` through `e.glb`), commercial blocks (`building_comm_a.glb` through `f.glb`), row buildings, continuous streetlights (`road_lightposts.glb`), street trees (`tree_detailed.glb`, `tree_palm.glb`, `tree_oak.glb`), curbs, sidewalks, and active traffic AI without road penetrations.

### 1.2 Apex Flight Defects
1. **Unstable Ground Attitude & 30° Runway Roll (P0)**:
   - *Symptom*: When stationary on the runway (Airspeed: 0 km/h), the aircraft is tilted 30° sideways, banking its wing directly into the tarmac (Screenshot 1).
   - *Root Cause*: In `games/aircraft-flight/core/flight_physics.gd`, `_compute_ground_reaction_forces()` only exerts a single vertical force at the aircraft center of gravity with ZERO roll or pitch restoring moments. Furthermore, `_integrate_aerodynamic_moments()` allows aileron roll torque and residual roll angular velocity even while resting on the ground at 0 km/h. When `move_and_slide()` executes, the aircraft rolls onto the edge of its collision box and remains wedged sideways.
   - *Remediation*: Implement multi-point landing gear ground stabilization. When wheels are on the ground (`ground_contact` or `is_on_floor()`), enforce wings-level attitude relative to the runway surface (`angular_velocity.z` critically damped to 0, roll angle actively stabilized to 0°). Restrict ground pitch to authentic gear attitude limits (-2° to +12° for takeoff rotation). Implement responsive nose-wheel / tailwheel ground steering linked to rudder input and ground speed. Prevent weight-on-wheels gear retraction.
2. **Aircraft-Specific Handling & Flight Dynamics (P0)**:
   - *Symptom*: Aircraft feel identical and helicopters lack true rotary-wing physics.
   - *Root Cause*: Fighter, airliner, aerobatic, and helicopter profiles shared simplistic fixed-wing approximations.
   - *Remediation*: Implement aircraft-specific aerodynamics:
     - **F/A-18C & F-22A**: Supersonic afterburner, high-alpha LEX vortex lift, 2D thrust-vectoring pitch authority (F-22A), high roll rates.
     - **A320 SkyLiner**: High inertia, realistic turbofan spool-up, multi-stage flaps with authentic pitch trim, ground spoilers/reversers.
     - **Extra 330SC Aerobatic**: Extreme roll agility (up to 400°/s), zero trim drag, immediate stick response, taildragger ground steering.
     - **UH-60 BlackHawk**: True 4-axis rotorcraft simulation (collective vertical thrust, cyclic longitudinal/lateral tilt, anti-torque tail rotor yaw rate, hover ground effect).
3. **Controls Guides & Interactive Tutorial (P0)**:
   - *Symptom*: No visible controls guide on screen or in-game flight tutorial.
   - *Remediation*: Add a responsive On-Screen Controls Reference HUD overlay and interactive flight training director (takeoff, climb, turn, landing cues).
4. **Crude Geometric Primitive Aircraft Models (P1)**:
   - *Symptom*: Aircraft in flight and hangar are crude block/cylinder toys with sticks for landing gear and flat slabs for wings/rotors (Screenshots 1, 2, 3).
   - *Root Cause*: `aircraft_mesh_builder.gd` used primitive `BoxMesh` and `CylinderMesh` shapes.
   - *Remediation*: Rebuild all 5 aircraft in `aircraft_mesh_builder.gd` with high-polygon contoured fuselages, authentic cambered wings, canopies with cockpit interiors, multi-blade articulated rotors/propellers, realistic landing gear struts/wheels, exhaust nozzles with afterburner glow, and animated control surfaces (ailerons, elevators, rudders, flaps).
5. **Environment & Airport Overhaul (P2)**:
   - *Symptom*: Flat, sparse airport and world geometry with simple grey boxes in the distance.
   - *Remediation*: Rebuild airport with paved runways (09L/09R), taxiways with centerline guides, apron ramps, passenger terminal with jetways, hangars with open bays, control tower with radar beacon, PAPI lights, dense coastal city skyline, mountains, and volumetric clouds.
6. **Hangar Framing & Visual Lighting (P3)**:
   - *Symptom*: Hangar turntable was dark or pitch-black void (Screenshots 2 & 3).
   - *Remediation*: Add multi-point studio lighting (key, fill, rim), illuminated pedestal, camera framing matching aircraft dimensions, and smooth 3D rotation.

---

## 2. Phased Implementation Plan

### Phase P0: Controls & Playability Remediation
- [ ] **P0.1 Urban Legends Reversed Steering Fix**:
  - Correct yaw rotation sign in `urban_vehicle.gd`: `rotate_object_local(Vector3.UP, -yaw_rate * delta)`.
  - Invert mid-air yaw stunt authority: `var air_yaw = -steer_input * 2.8 * delta`.
  - Validate that Left input steers Left and Right input steers Right across keyboard, gamepad, and touch.
  - Verify acceleration, progressive braking, handbrake drift, suspension stability, camera tracking, and recovery.
- [ ] **P0.2 Apex Flight Ground Handling & Stability Fix**:
  - Implement 3-point landing gear ground stabilization in `flight_physics.gd`:
    - Enforce wings-level ground attitude: lock/damp roll when wheels contact runway (`roll = 0.0`, `angular_velocity.z = 0.0`).
    - Pitch restriction on ground: clamp pitch between -2° (nose down) and +14° (takeoff rotation).
    - Implement low-speed nose-wheel / tailwheel taxi steering via rudder input: `yaw_rate = -cmd_yaw * ground_steer_speed`.
    - Weight-on-wheels safety: disallow retracting landing gear while compressed on the ground.
- [ ] **P0.3 Aircraft-Specific Flight Dynamics**:
  - Tune and calibrate aerodynamics for all 5 aircraft classes:
    - F/A-18C: High-alpha carrier fighter, twin-engine afterburner.
    - F-22A: 5th-gen stealth air superiority, supercruise, 2D thrust-vectoring pitch nozzle integration.
    - A320: Commercial jetliner, high inertia, progressive turbofan spool, multi-stage flaps.
    - Extra 330SC: Unlimited competition aerobatic monoplane, extreme roll rate, taildragger handling.
    - UH-60: True 4-axis rotorcraft (collective, cyclic, anti-torque pedals, hover ground effect).
- [ ] **P0.4 Controls Guide & Interactive Flight Tutorial**:
  - Add visible keyboard/gamepad/touch controls guide overlay to `flight_hud.gd`.
  - Implement interactive flight tutorial hints for takeoff, climb, roll, and landing.

### Phase P1: Realistic 3D Assets Overhaul
- [ ] **P1.1 Apex Flight 5 High-Fidelity Aircraft Models (`aircraft_mesh_builder.gd`)**:
  - **F/A-18C Hornet**: Contoured fuselage, radome nose, bubble canopy with pilot helmet, LEX strakes, trapezoidal wings, twin canted vertical tails with rudders, horizontal stabs, afterburner nozzles, tricycle landing gear with twin nosewheels, arrestor hook, wingtip missile rails.
  - **F-22A Raptor**: Faceted stealth chined fuselage, diamond-delta wings, golden indium canopy, twin 28° canted vertical stabilizers with rudders, 2D vectoring pitch nozzles with reheat plumes, trapezoidal intakes.
  - **A320 SkyLiner**: Cylindrical airliner fuselage, cockpit windscreen, passenger window rows, swept low-wing with sharklets, twin CFM56 turbofan engines on pylons with fan spinners, vertical fin with rudder, multi-wheel bogies.
  - **Extra 330SC Aerobatic**: Composite monoplane fuselage, teardrop canopy, engine cowling with air scoops, 3-blade propeller with spinner, tapered wings with full-span ailerons, large rudder/elevator, wheel pants/spats and tailwheel.
  - **UH-60 BlackHawk**: Detailed utility cabin with cockpit glazing, sliding doors, sponsons with oleo gear, 4-blade articulated main rotor, canted vertical fin with 4-blade canted tail rotor, twin turboshaft nacelles, horizontal stabilator, rescue hoist.
- [ ] **P1.2 Urban Legends Realistic Vehicles (`urban_vehicle_visuals.gd`)**:
  - Replace `BoxMesh` slabs with high-detail models mapping each archetype:
    - `street_tuner` (Vortex GT): `car_sedan_sports.glb` / `car_race.glb` with racing spoiler and alloy rims.
    - `muscle_classic` (Thunderbolt V8): muscular American GT with chrome trim and wide tires.
    - `super_exotic` (Specter R): `car_race_future.glb` / `rocket_car_spectre.glb` with active aero and LED lights.
    - `urban_suv` (Ridgeback 4x4): `car_suv_luxury.glb` with roof rails and all-terrain stance.
    - `drift_special` (Valiant Coupe): `car_hatchback_sports.glb` with widebody stance and drift wheels.
  - Add animated rotating wheels (`car_wheel_racing.glb`), suspension compression, PBR clearcoat paint, illuminated LED headlights, and reactive taillights.

### Phase P2: Environment & World Overhaul
- [ ] **P2.1 Apex Flight World & Airport Overhaul**:
  - Airport: Paved runways 09L/09R with threshold stripes, centerlines, touchdown zones, connecting taxiways, apron ramps, passenger terminal with jetways, hangars, control tower with beacon radar, PAPI glide-slope indicators, runway end lights.
  - Surrounding World: Coastal harbor with container ships and cranes, twin-tower suspension bridge, Manhattan-style high-rise district, mountain ranges, and volumetric clouds.
- [ ] **P2.2 Urban Legends Metropolis Overhaul**:
  - Build dense New York-inspired city: integrate `building_skyscraper_a.glb`–`e.glb` and `building_comm_a.glb`–`f.glb`.
  - Connect road network with avenues, cross streets, viaduct bridges, streetlights (`road_lightposts.glb`), crosswalks, trees (`tree_detailed.glb`, `tree_palm.glb`), and civilian traffic AI (`car_sedan.glb`, `car_taxi.glb`, `truck_yellow.glb`).
  - Eliminate all empty voids and ensure zero building-road collisions.

### Phase P3: Visuals, Animation & UX Polish
- [ ] Calibrate exposure, daytime, sunset, and nighttime lighting across both games (prevent dark scenes and overexposure).
- [ ] Polish animations: control surface deflections, landing gear retraction/extension, spinning propellers and rotors, afterburner plumes, car wheel spinning and suspension tilt.
- [ ] Calibrate Hangar 3D turntable preview: 3-point lighting, clean camera framing for all aircraft, responsive layout.
- [ ] Polish HUDs: responsive layouts, clear mission objectives, key guides.

### Phase P4: Evidence-Based Validation & Regression Testing
- [ ] Automated validation:
  - Urban Legends: Test that Left steering turns Left (negative yaw) and Right steering turns Right (positive yaw), test driving, braking, drifting, and mission completion.
  - Apex Flight: Test all 5 aircraft take off, maneuver, climb, descend, land, gear toggle, flaps cycle, and complete missions.
- [ ] Full regression testing: Run all 93 test suites in podman container (verify 100% pass rate, 0 failures).
- [ ] Code coverage: Maintain $\ge 90\%$ function coverage.
- [ ] Packaging verification: Verify standalone and suite exports across Windows, Linux, Web, Android.
- [ ] Telemetry & Performance: Verify $> 60\text{ FPS}$ and stable frame times.

### Phase P5: Delivery & Certification
- [ ] Document all before/after changes, test results, and evidence in `IMPLEMENTATION_WALKTHROUGH.md`.
- [ ] Update `CHANGELOG.md` and `TODO.md` in append-only fashion.

---

## 3. Quantitative Acceptance Criteria

| ID | Component | Requirement | Target Metric | Status |
| :--- | :--- | :--- | :---: | :---: |
| **AC-P0-01** | Urban Legends | Right steering input turns vehicle clockwise to the Right (+X) | $\Delta \text{yaw} < 0\text{ rad}$ around UP | **PENDING** |
| **AC-P0-02** | Urban Legends | Left steering input turns vehicle counter-clockwise to the Left (-X) | $\Delta \text{yaw} > 0\text{ rad}$ around UP | **PENDING** |
| **AC-P0-03** | Apex Flight | Aircraft stationary on runway maintains wings-level attitude | Roll angle $\approx 0.0^\circ \pm 0.5^\circ$ | **PENDING** |
| **AC-P0-04** | Apex Flight | Rudder input on ground produces smooth taxi steering | Ground turn rate $> 0.2\text{ rad/s}$ | **PENDING** |
| **AC-P0-05** | Apex Flight | All 5 aircraft classes possess authentic specialized flight handling | 5 aircraft verified | **PENDING** |
| **AC-P0-06** | Apex Flight | On-screen visible flight controls guide overlay | 100% visible on desktop/mobile | **PENDING** |
| **AC-P1-01** | Apex Flight | F/A-18C, F-22A, A320, Extra 330, UH-60 realistic 3D models | 0 crude placeholder boxes | **PENDING** |
| **AC-P1-02** | Apex Flight | Moving control surfaces, retractable gear, spinning rotors/props | All 5 animated | **PENDING** |
| **AC-P1-03** | Urban Legends | Realistic production-grade 3D car models with wheels & lights | 0 crude placeholder boxes | **PENDING** |
| **AC-P2-01** | Apex Flight | Rebuilt airport with dual runways, taxiways, hangars, terminal | 100% navigable | **PENDING** |
| **AC-P2-02** | Urban Legends | Dense NYC-style metropolis with skyscrapers, streetlights, trees | 0 empty desert regions | **PENDING** |
| **AC-P3-01** | Visuals & UX | Exposure & lighting calibrated across day/sunset/night | Luminance $\in [0.15, 0.95]$ | **PENDING** |
| **AC-P4-01** | Test Suite | 100% pass rate across entire suite | 0 failures, 100% pass | **PENDING** |
| **AC-P4-02** | Coverage | Testable function coverage maintained | $\ge 90.0\%$ | **PENDING** |
| **AC-P4-03** | Packaging | Standalone packages export cleanly with zero foreign leakage | 36 packages valid | **PENDING** |
