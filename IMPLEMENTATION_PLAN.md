# Chroma Rush: Forensic Audit, Road/Physics Overhaul & Quality Certification — Implementation Plan

## 1. System Audit & Requirement Traceability Matrix

Following forensic investigation of running builds, source code, collision geometry, and user feedback/screenshot evidence:

| # | Requirement Domain | Target Specification | Status | Reproduction Evidence & Root Cause | Plan & Action |
| :- | :--- | :--- | :---: | :--- | :--- |
| 1 | **Road Geometry & Collisions** | Continuous smooth road surfaces, zero step seams, flush intersections, no curbs crossing driveable lanes. | **BROKEN** | Cars blocked at waypoint intersections. Root cause: `WorldBase.add_road_segment` generated disconnected BoxMesh/BoxShape3D segments with unchamfered endcaps. Curbs were 0.6m high boxes extending full length into intersecting lanes. `_ready()` called twice duplicated all colliders. | Replace with authoritative continuous road ribbon generator with Catmull-Rom spline sampling, flush seamless ConcavePolygonShape3D trimesh collision, realistic 0.12m beveled curbs following outer curve. Prevent duplicate `_ready()`. |
| 2 | **Vehicle Movement & Telemetry** | Displayed speed derived from physical velocity; no 108 km/h while stationary at 0 km/h; reliable acceleration/braking/reversal. | **BROKEN** | Telemetry showed 108 km/h while car was jammed against a wall. Root cause: `forward_speed` integrated purely from throttle without collision feedback; `speed_kph` read `forward_speed * 3.6` instead of `get_real_velocity()`. | Reconcile `forward_speed` with collision slide normals; derive `speed_kph` from `get_real_velocity().length() * 3.6`. Ensure reverse works reliably and collision shape has proper clearance. |
| 3 | **Realistic Car Visuals & Paint** | Believable full-bodied cars with visible hood, roof, doors, fenders; authoritative color drives body paint; separate glass/rubber/trim. | **BROKEN** | HUD says "Crimson Red" while car body appears dark blue-gray with pink stripes. Root cause: `VehicleVisuals` hardcoded body paint to `Color(0.18, 0.22, 0.28)`; `apply_gameplay_color` only tinted emissive stripes with 2.4x bloom. | Bind authoritative color to main car body panels (hood, roof, doors, fenders, trunk); use high-grade PBR automotive lacquer (clearcoat, metallic); keep glass, rubber, chrome, and carbon trim distinct. |
| 4 | **Realistic Scenery & Lighting** | Natural daylight, balanced exposure, coherent buildings, vegetation, signs, landmarks; no washed-out bloom or stark white edges. | **BROKEN** | Washed-out scenery with intensely white glowing road markings. Root cause: Duplicate `WorldEnvironment` and duplicate `DirectionalLight3D` in `ChromaRushMain` and `WorldBase`; bloom intensity 0.8 / 0.25; road markings unattenuated pure white. | Consolidate single balanced WorldEnvironment (Filmic tonemap, exposure 1.0, subtle bloom 0.08, ambient 0.85); realistic PBR road markings; rich urban architecture, street lightposts, barriers, and landmarks in all 4 worlds. |
| 5 | **Live Minimap & Radar** | Road lines stay strictly within minimap bounds; no overlap with HUD badges; clear legend and orientation. | **BROKEN** | Road lines draw outside radar boundaries onto HUD; minimap overlaps "Current Color" panel on smaller/scaled displays. Root cause: `map_canvas` lacked clipping; lines drawn to $1.4 \times radius$; minimap `offset_top = 80` collided with badge at `offset_top = 16`. | Enable `clip_contents = true`; clip road line segments to circular radar radius; position minimap with responsive margin (safe gap below top badges); add target blips and heading arrow. |
| 6 | **Tactical Objectives & State Flow** | Explicit mission state machine: Find Target -> Approach & Align -> Match Speed -> Swap -> Deliver -> Reward. Target cycling & device prompts. | **PARTIAL** | Target gates existed, but navigation path was unclear; generic "SEARCHING FOR TARGETS..."; missing clear device prompts for keyboard/gamepad/touch. | Implement 6-state mission machine with dynamic HUD guidance, target cycling ([Tab] / HUD button), device-specific prompts ([E] / Gamepad X / Tap), route path to target, and clear player-facing rejection messages. |
| 7 | **4 Handcrafted Worlds** | Neon City, Coastal Rush, Prism Canyon, Sky Circuit with believable visual treatment and distinct biomes. | **VERIFIED** | 4 worlds present with waypoints and checkpoints; road generation overhauled to be smooth and continuous. | Upgrade scenery, props, barriers, and lighting across all 4 worlds. Verify traversability in both directions. |
| 8 | **6 Distinct Vehicles** | Apex Striker, Vortex Drift, Titan Vanguard, Pulse Cyber, Dune Nomad, Quantum Phantom with authentic stats. | **VERIFIED** | 6 distinct archetypes defined in `VehicleCatalog` and modeled in `VehicleVisuals`. | Upgrade mesh details, full-body paint shaders, and wheel suspension dynamics. |
| 9 | **Game Modes & Content** | Color Hunt, Chroma Sprint, Puzzle Drive, Chroma Championship; 24 handcrafted missions with solvability proofs. | **VERIFIED** | 24 missions in `MissionDatabase` with schema validation and solvability proofs. | Ensure all 4 modes transition smoothly with countdown, pause, retry, and results. |
| 10 | **Suite-Wide Responsiveness & Performance** | Adaptive layout across resolutions (mobile, tablet, desktop, ultra-wide); 60 FPS desktop / 30+ FPS mobile; clean resource resets. | **PARTIAL** | Responsive UI test passed, but touch controls and HUD needed layout hardening for multi-aspect displays. | Harden responsive anchoring, safe areas, touch targets, and resource pooling across all screens and modes. |
| 11 | **Test Suite & CI Quality Gates** | >90% code coverage, 100% test pass rate, empirical visual audits, benchmark verification. | **VERIFIED** | 64 suites passed with 92.8% coverage. | Extend tests to assert continuous road traversability, physical velocity telemetry, authoritative paint, and minimap bounds. |

---

## 2. Playable Milestones & Execution Plan

### Milestone 1: Authoritative Continuous Road Generator & Physics Seam Repair
- **File**: `games/chroma-rush/worlds/world_base.gd`
- Implement `build_continuous_road_network(waypoints: Array[Vector3], road_width: float, ...)`:
  - Generate smooth spline samples between waypoints using Catmull-Rom interpolation.
  - Build continuous road ribbon SurfaceTool mesh (asphalt surface, dashed yellow centerlines, solid white shoulder lines).
  - Build continuous 0.12m beveled curbs and sidewalks hugging outer boundaries without ever crossing lanes.
  - Generate 1:1 matching physical collider via `ConcavePolygonShape3D` (`set_faces`).
  - Add `_is_ready_initialized` guard to prevent double-initialization.
- Update `neon_city.gd`, `coastal_rush.gd`, `prism_canyon.gd`, and `sky_circuit.gd` to use continuous road generation.
- Remove redundant manual `._ready()` calls in `chroma_rush_main.gd`.

### Milestone 2: Vehicle Physics, Physical Velocity Telemetry & Collision Hardening
- **File**: `games/chroma-rush/vehicles/chroma_vehicle.gd`
- Derive displayed speed (`speed_kph` and `get_speed_kmh()`) from actual physical displacement (`get_real_velocity()`).
- Reconcile `forward_speed` with collision slide contacts: if blocked in front by an obstacle, clamp `forward_speed` to actual physical movement.
- Ensure collision shape bottom has adequate clearance above wheels so tires make contact first.
- Support unstuck/recovery hotkey ([R] / recovery control) and automatic reset on rollover or falling out of world.

### Milestone 3: Full-Bodied Realistic Automotive Visuals & Authoritative Painting
- **File**: `games/chroma-rush/vehicles/vehicle_visuals.gd`
- Separate vehicle visual components into distinct material groups:
  - `BodyPaintPanels`: Hood, roof, doors, front/rear quarter panels, trunk, front/rear bumper covers.
  - `GlassPanels`: Windshield, rear window, side windows (translucent dark specular glass).
  - `TrimPanels`: Carbon fiber front splitter, rear diffuser, spoilers, grille mesh.
  - `WheelAssemblies`: Rubber tires, alloy rims, center hubs, brake calipers.
  - `LightingAssemblies`: LED headlights, taillight lightbars.
- In `apply_gameplay_color(vehicle_visual, color_id)`:
  - Create dynamic high-gloss/metallic automotive paint material with the authoritative `color_id`.
  - Apply to ALL `BodyPaintPanels`.
  - Update accent strips and accessibility 3D billboard symbol with matching tone.

### Milestone 4: Lighting & Scenery Production Pass
- **Files**: `chroma_rush_main.gd`, `world_base.gd`, `neon_city.gd`, `coastal_rush.gd`, `prism_canyon.gd`, `sky_circuit.gd`
- Remove duplicate `WorldEnvironment` and `DirectionalLight3D` in `ChromaRushMain`.
- Establish balanced single PBR lighting:
  - Tonemap Filmic, exposure 1.0, subtle glow (bloom 0.08, intensity 0.35).
  - Sun directional light energy 1.15 with soft shadow bias.
  - Realistic road marking albedo (`Color(0.85, 0.87, 0.90)`).
- Populate `Neon City` with varied commercial architecture (`building_a.glb` through `building_garage.glb`), street lightposts, sidewalk barriers, trees, and signage.
- Enrich `Coastal Rush`, `Prism Canyon`, and `Sky Circuit` with appropriate thematic environment assets.

### Milestone 5: Live Minimap Boundary Containment & HUD Layout Overhaul
- **Files**: `games/chroma-rush/ui/chroma_mini_map.gd`, `games/chroma-rush/ui/chroma_hud.gd`
- In `ChromaMiniMap`:
  - Set `clip_contents = true`.
  - Clip road line drawings strictly to the radar circular boundary.
  - Render live player heading arrow, traffic markers with color badges, active checkpoint/target beacon, and radar rings.
- In `ChromaHUD`:
  - Reposition `mini_map` below the top objective bar with safe separation (`offset_top = 96`) preventing any overlap with color badges.
  - Add explicit mission step guidance ("STEP 1: PURSUE & ALIGN", "STEP 2: SWAP COLOR", "STEP 3: DELIVER").
  - Add device-specific input prompts (Keyboard [E], Gamepad (X), Touch [SWAP]).
  - Implement target cycling support ([Tab] / Target Icon).
  - Provide concise player-facing rejection feedback ("TOO FAR", "SPEED MISMATCH", "ALIGN ALONGSIDE").

### Milestone 6: Suite-Wide Responsiveness, Performance & Comprehensive Tests
- Extend test suites in `games/chroma-rush/tests/`:
  - Verify continuous road geometry without steps/gaps.
  - Verify physical velocity telemetry (0 km/h when blocked, climbing only when moving).
  - Verify full-bodied vehicle paint application.
  - Verify minimap boundary containment and HUD non-overlap.
  - Verify 4 modes, 24 missions, and restart/retry lifecycle.
- Run full test suite, verify 100% pass and >90% coverage.
- Update `IMPLEMENTATION_WALKTHROUGH.md`, `TODO.md`, and `CHANGELOG.md`.
