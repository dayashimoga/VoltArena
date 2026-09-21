# VoltArena Suite: Forensic Redesign, Completion & Production-Hardening Plan

## Overview
A comprehensive, production-grade overhaul of the entire 8-game **VoltArena** suite in Godot 4.3. This pass resolves all identified prototype/gray-box deficiencies, rebuilds broken vehicle physics and race simulations, completes campaign progression loops with genuine stage variety, transforms prototype configurators into full engineering games, builds living adventure and wildlife exploration worlds, and establishes an automated forensic validation pipeline backed by clean packaged-runtime evidence.

---

## 1. Forensic Audit & Gap Analysis Matrix

| Game | Intended Fantasy | Core Loop | Current State | Missing / Broken Systems | Visual & Content Gaps | Priority | Remediation Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Drift Storm** (`kart-racing`) | High-speed Grand Prix arcade kart racing | Grid -> Countdown -> Race & Drift -> Checkpoints/Laps -> Podium -> Next Circuit | Prototype race controller with basic waypoint/spline following | AI stops in track or teleports; steering is excessively sharp; lack of speed sensitivity; wall clipping; primitive box pickups; detached vehicle shadows | Primitive cubes for pickups; potential racing line obstructions; ungrounded wheels | **P0 / P1** | Rebuild vehicle physics with speed-sensitive steering, progressive keyboard ramping, lateral grip/slip; spline lookahead AI with corner braking & dynamic overtaking; continuous validated circuits with 0 obstructions; contextual 3D pickups |
| **Strike Vector** (`strike-vector`) | Cinematic run-and-gun sci-fi campaign | Briefing -> Deploy -> Traversal & Combat -> Objectives -> Extraction -> Results -> Next Stage | Linear segmented corridor shooter with mock results | **P0:** Player reaches extraction circle and nothing progresses; repetitive corridor layouts across missions; excessive darkness and black voids; lack of interactive tactical map | Identical corridor structures across 8 missions; unlit voids; missing environmental storytelling | **P0 / P1** | Fix extraction trigger with one-time completion lock, stats calculation, save persistence, and loading distinct subsequent stages; build unique biomes (City, Rail, Harbor, Desert, Arctic, Factory, Sky Fortress, Citadel); interactive tactical map screen |
| **RoboForge Arena** (`roboforge-arena`) | Physics robot engineering & challenge trials | Workshop Build -> Stat Tradeoffs -> Test Dyno -> Challenge Course -> Rewards/Unlocks -> Upgrade | Prototype boxy robot with basic slab courses | No rotatable/zoomable workshop camera; component tradeoffs lack clear visualization; challenges are plain slabs without moving hazards; lacks progression unlock loop | Black box robot with primitive cylinders; grey-box obstacle courses | **P0 / P1** | Rebuild robot visuals with stylized modular parts (scout/titan/spider chassis, tread/wheel/leg assemblies, tools & weapons); interactive workshop camera with live stats; dynamic challenge arenas with moving obstacles & cargo goals; component progression unlocks |
| **Skybound Odyssey** (`skybound-odyssey`) | Floating archipelago 3D exploration adventure | Explore -> Traverse -> Solve Ruins -> Collect Shards -> Awaken Altar -> Next Island | Primitive box character on flat box islands | Box character with basic box cape; islands are plain flat boxes; shards are floating cubes without lore or VFX; lacks island transition cinematic | Extreme gray-box prototype geometry; flat rectangular islands; primitive shard cubes | **P0 / P1** | Build stylized articulated explorer with procedural animations (walk/run/jump/glide/mantle); multi-tier sculpted floating islands with ruins, temples, flora, and waterfalls; lore-imbued 3D crystal artifacts with VFX; portal transitions to new regions |
| **WildCircuit** (`wildcircuit`) | Wildlife ranger conservation expedition | Briefing -> Track Clues -> Observe Behavior -> Scored Photo -> Complete Dossier -> Next Biome | Capsule player with boxy 5-cube animals in flat world | Capsule player; crude box animals; photo scoring does not verify specific behaviors; lacks usable ranger vehicle handling; biomes feel empty | Plain capsule player; primitive box animals; flat featureless terrain | **P0 / P1** | Build ranger character with field gear; rugged 4x4 ranger ATV; articulated wildlife species (Gazelle, Lion, Elephant, Zebra) with behavioral AI (graze, drink, alert, flee); strict photo scoring verifying behavior; distinct living biomes (Savannah, Forest, Wetlands) |
| **Iron Crucible** (`arena-fps`) | Fast-paced tactical arena FPS | Countdown -> Weapon Scavenge -> Combat Bots -> Escalation -> Victory -> Next Arena | Functional arena shooter | Bot difficulty tuning; map boundary verification; spawn point safety checks | Fine-tune lighting and environmental props; ensure 0 void exposure | **P1 / P2** | Verify weapon projectiles, bot combat behavior, map colliders, and match result flow |
| **Nitro Kick** (`rocket-car`) | Supersonic rocket vehicle arena sports | Kickoff -> Boost/Aerial -> Ball Physics -> Goal -> Replay -> Results -> Next Match | Functional vehicle soccer | Ball physics edge-case bounces; goal detection triggers; AI goalkeeper and striker roles | Enhance stadium crowd, floodlights, and goal particle VFX | **P1 / P2** | Harden vehicle collision with ball and walls; refine aerial boost handling; polish goal celebrations |
| **Metro Siege** (`subway-survival`) | Underground wave survival horror | Wave Start -> Monster Swarm -> Combat -> Scrap Scavenge -> Upgrade -> Extraction Wave | Functional wave survival | Wave director pacing; scrap upgrade kiosk balance; extraction train departure event | Ensure subterranean atmosphere without pitch-black unnavigable areas | **P1 / P2** | Validate mutant monster archetypes (Crawler, Spitter, Stalker, Brute, Colossus); polish train extraction |

---

## 2. Game-Specific Engineering Specifications

### 2.1 Drift Storm — Vehicle Physics & Race Simulation Rebuild
- **Vehicle Physics Model (`kart_controller.gd`)**:
  - **Speed-Sensitive Steering**: At low speeds (< 10 km/h), allow high steer angle (up to 32°); at high speeds (> 60 km/h), smoothly interpolate down to 14° to eliminate abrupt jerkiness.
  - **Progressive Keyboard Ramping**: Replace instant maximum turn with an exponential input ramp (`steer_blend = move_toward(steer_blend, target_steer, steer_rate * delta)`).
  - **Lateral Grip & Drift Physics**: Calculate lateral velocity vs forward velocity; apply tire grip curve. In drift mode, preserve forward momentum while rotating yaw with counter-steer control and mini-turbo charge levels (Blue -> Orange -> Purple).
  - **Grounding & Shadows**: Calibrate 4-wheel suspension raycasts so wheel meshes sit flush on the road surface with dynamic contact shadow decals.
- **AI Racing Line Driver (`kart_ai.gd`)**:
  - **Spline Lookahead & Speed Planning**: Compute multi-horizon curvature (mid & far). Calculate target corner entry speeds; apply progressive braking before turn apex.
  - **Overtaking & Collision Avoidance**: Raycast and distance query other racers; apply smooth lateral lane offsets (-2.8m to +2.8m) to pass cleanly.
  - **Stuck Watchdog & Recovery**: Physical displacement tracker (< 1.5 m/s for > 2.0s triggers reverse maneuver; > 3.5s triggers recovery to nearest valid checkpoint).
  - **Deterministic Standings**: Standings calculated via `lap * 10000.0 + checkpoint_index * 100.0 + spline_progress`.
- **Circuit Validation (`track_generator.gd`)**:
  - Continuous closed circuits with 0 dead ends, gaps, or walls penetrating the racing line.
  - Replace primitive glowing cubes with contextual 3D pickups: Turbo Canisters, Energy Shield Rings, and EMP Mines.

### 2.2 Strike Vector — Campaign Progression & Level Design Overhaul
- **Extraction Trigger Fix (`strike_vector_main.gd`, `segment_manager.gd`)**:
  - Detect player entering extraction helipad/beacon.
  - One-time completion lock (`is_completing_mission = true`), disable combat inputs, trigger extraction landing VFX/audio.
  - Compute accuracy, kills, score, time, and rank.
  - Persist progress via `SaveManager.record_strike_vector_mission(m_idx, score, time, true)`.
  - Display Results Screen with enabled "NEXT MISSION" button.
  - Next mission dynamically loads a **genuinely distinct biome** with unique layout, architecture, and lighting.
- **Campaign Stages & Biomes (`strike_environment_builder.gd`, `mission_definitions.gd`)**:
  1. *Stage 1: Urban Blackout* — City streets, commercial plazas, and rooftops.
  2. *Stage 2: High-Speed Rail* — Moving express train, carriage interiors, and suspension bridges.
  3. *Stage 3: Harbor Assault* — Shipping container labyrinth, gantry cranes, and cargo ship decks.
  4. *Stage 4: Desert Convoy* — Redrock canyon pass, armored refinery, and pipeline terminals.
  5. *Stage 5: Arctic Installation* — Whiteout blizzard, underground research labs, and radar installations.
  6. *Stage 6: Megafactory* — Automated assembly lines, hydraulic crushers, and smelting furnaces.
  7. *Stage 7: Sky Fortress* — High-altitude catwalks, antenna spires, and aerial hangar decks.
  8. *Stage 8: Final Citadel* — Fortified siege trenches, grand citadel halls, and apex extraction helipad.
- **Atmosphere & Lighting**:
  - Eliminate black voids by providing procedural skyboxes, horizon city silhouettes, atmospheric depth fog, and balanced directional/ambient lighting.
- **Tactical Operations Map Screen**:
  - Press 'M' to bring up tactical uplink with live player marker, objective location, cleared checkpoints, and navigation route.

### 2.3 RoboForge Arena — Modular Robot Engineering & Challenge Courses
- **Modular Robot Architecture (`modular_robot.gd`, `MeshBuilder`)**:
  - **Chassis**: Scout (lightweight, nimble), Medium (balanced), Titan (heavy armor, high payload).
  - **Locomotion**: All-Terrain Radial Wheels, Heavy Caterpillar Tracks, Articulated Quad Walker Legs.
  - **Power Cores**: Standard Battery, High-Output Reactor, Fast-Recharge Supercapacitor.
  - **Tools & Modules**: Hydraulic Grabber Claw, High-Power Magnetic Arm, Rocket Thruster Boosters, Kinetic Shield Emitter, Cargo Bed.
  - **Real Physics & Stats**: Mass, acceleration, top speed, turning torque, energy draw, traction, stability, and durability all dynamically calculated from blueprint parts.
- **Interactive Workshop Bay (`workshop_3d.gd`)**:
  - Rotatable/zoomable turntable camera (mouse drag / stick orbit, wheel zoom).
  - Visual component sockets with highlight indicators.
  - Live stat HUD comparing changes against previous blueprint.
- **Challenge Courses (`challenge_manager.gd`)**:
  - *Test Dyno*: Speed traps, incline traction ramps, turning slalom.
  - *Obstacle Course*: Moving hazards, speed bumps, tilting ramps, jump gaps.
  - *Cargo Delivery*: Physical crates to grab/tow to target depots across narrow bridges.
  - *Energy Challenge*: Scattered energy cores requiring magnetic harvesting.
  - *Combat Arena*: Target drones and breakable barriers.
- **Progression Loop**:
  - Completing challenges awards components and unlocks subsequent challenge tiers.

### 2.4 Skybound Odyssey — Complete Adventure & Island Progression
- **Player Character & Locomotion (`sky_character.gd`, `MeshBuilder`)**:
  - Stylized articulated explorer model with adventurer pack, cape, and glider wings.
  - Procedural movement states: Idle, Walk, Run, Jump, Double Jump, Glide, Ledge Mantle, Fall.
- **Floating Island Worlds (`skybound_world.gd`)**:
  - Multi-tier sculpted floating islands with rock strata, grass overhangs, ancient stone ruins, archways, and bridges.
  - Distinct realms: Emerald Isles, Crystal Caverns, Sunken Sky Temple, Frost Peaks, Storm Citadel.
- **Ancient Shards & Environmental Puzzles**:
  - Designed 3D crystal artifacts with spinning core, glow shaders, particle rings, and pickup chimes.
  - Environmental mechanisms: pressure plates, wind updrafts for glider flight, grapple anchors across chasms.
- **Progression & Altar Activation**:
  - Gathering required shards activates the central ruin altar, playing an awakening sequence that unlocks the sky portal to the next island realm.
  - Mission journal & compass HUD.

### 2.5 WildCircuit — Living Wildlife & Conservation Photography
- **Ranger Character & Vehicle (`wildcircuit_main.gd`, `explorer_atv.gd`, `MeshBuilder`)**:
  - Articulated Ranger model with binoculars and camera.
  - Usable Safari 4x4 ATV with real suspension, steerable front wheels, and headlight illumination.
- **Articulated Wildlife AI (`wild_animal.gd`, `MeshBuilder`)**:
  - Anatomically styled animal models: Gazelle, African Lion, Savanna Elephant, Plains Zebra.
  - Behavior State Machine: `IDLE`, `WANDER`, `GRAZE_FEED`, `DRINK`, `SLEEP`, `ALERT`, `FLEE`.
  - Herd cohesion and player avoidance dynamics.
- **Photography & Research System (`camera_mode.gd`, `field_journal.gd`)**:
  - First-person viewfinder with zoom, focus, and framing reticle.
  - Strict objective scoring: checks species, line-of-sight visibility, distance, centering, and required active behavior (e.g. Gazelle actively grazing).
  - Photo logged in Field Journal with rating (Bronze, Silver, Gold, Platinum), awarding conservation stars that unlock new biomes.

---

## 3. Shared Systems & Production Quality Pass

### 3.1 Standardized Game Loop States across All 8 Games
Every game in VoltArena implements explicit state transitions:
`LOADING -> BRIEFING -> COUNTDOWN/START -> PLAYING -> PAUSED -> SUCCESS/FAILURE -> RESULTS -> REWARD -> TRANSITION -> NEXT_STAGE -> RETRY/EXIT`.

### 3.2 Contextual Game Rewards
Eliminate floating rectangular boxes. All rewards become interactive 3D contextual assets:
- **Trophies & Medals**: Grand Prix podium trophies in Drift Storm.
- **Energy Cores & Weapon Unlock Cards**: In Strike Vector and Iron Crucible.
- **Modular Components & Blueprints**: In RoboForge Arena.
- **Ancient Relics & Shards**: In Skybound Odyssey.
- **Field Badges & Research Stars**: In WildCircuit.

### 3.3 Audio / Feedback Polish
- Vehicle engine RPM curves, tire squeal, and impact thuds.
- Weapon fire, recharge, dry fire, and hitmarkers.
- Wildlife calls, ambient wind, footsteps on different surfaces (grass, metal, rock, sand).

---

## 4. Proposed File Changes

### Shared Core & Graphics
- `[MODIFY] shared/graphics/mesh_builder.gd`: Add production 3D builders for:
  - Modular robot chassis, wheels, tracks, legs, grabber claws, magnetic arms, thrusters.
  - Articulated Skybound explorer character and ancient crystal shard artifacts.
  - Articulated WildCircuit ranger character, Safari ATV, and wildlife animals (gazelle, lion, elephant, zebra).
  - Contextual reward objects (trophies, medals, components, relics).
  - Biome scenery props (ruins, bridges, vegetation, factory machinery).
- `[MODIFY] shared/graphics/material_generator.gd`: Add PBR materials for wildlife coats, ancient stone runes, robot chassis carbon, and industrial metals.
- `[MODIFY] shared/ui/results_screen.gd`: Enhance with contextual 3D reward rendering, breakdown statistics, and Next Stage navigation buttons.

### Drift Storm (`games/kart-racing`)
- `[MODIFY] games/kart-racing/kart/kart_controller.gd`: Implement speed-sensitive steering, progressive input ramping, lateral grip/slip curve, calibrated suspension grounding.
- `[MODIFY] games/kart-racing/ai/kart_ai.gd`: Implement physical lookahead speed planning, corner braking, dynamic overtaking, stuck recovery state machine.
- `[MODIFY] games/kart-racing/tracks/track_generator.gd`: Eliminate racing line obstructions; continuous verified circuits; replace box pickups with 3D energy items.
- `[MODIFY] games/kart-racing/kart_racing_main.gd`: Ensure seamless grid -> countdown -> race -> podium -> next race flow.

### Strike Vector (`games/strike-vector`)
- `[MODIFY] games/strike-vector/strike_vector_main.gd`: Fix P0 extraction trigger lock, compute statistics, persist progress, and transition to genuinely distinct stages.
- `[MODIFY] games/strike-vector/missions/mission_definitions.gd`: Define unique layouts and objectives for all 8 stages.
- `[MODIFY] games/strike-vector/environment/strike_environment_builder.gd`: Build distinct environmental biomes (City, Rail, Harbor, Desert, Arctic, Factory, Sky Fortress, Citadel); eliminate black voids.
- `[MODIFY] games/strike-vector/ui/strike_hud.gd`: Enhance tactical map uplink with live player, route, and checkpoint tracking.

### RoboForge Arena (`games/roboforge-arena`)
- `[MODIFY] games/roboforge-arena/robot/modular_robot.gd`: Rebuild robot geometry using stylized modular assets; compute real statistical tradeoffs.
- `[MODIFY] games/roboforge-arena/workshop/workshop_3d.gd`: Implement rotatable/zoomable orbit camera, socket inspection, and live stat comparisons.
- `[MODIFY] games/roboforge-arena/challenges/challenge_manager.gd`: Build designed challenge courses with moving obstacles, ramps, and cargo goals.
- `[MODIFY] games/roboforge-arena/roboforge_main.gd`: Implement full Build -> Test -> Challenge -> Reward -> Upgrade progression loop.

### Skybound Odyssey (`games/skybound-odyssey`)
- `[MODIFY] games/skybound-odyssey/character/sky_character.gd`: Implement stylized adventurer model with procedural animations (idle, walk, run, jump, glide, mantle).
- `[MODIFY] games/skybound-odyssey/world/skybound_world.gd`: Rebuild floating islands with multi-tier sculpted rock, ruins, flora, and environmental puzzles; replace box shards with designed artifacts.
- `[MODIFY] games/skybound-odyssey/skybound_main.gd`: Implement altar awakening and portal transitions to unlocked island regions.

### WildCircuit (`games/wildcircuit`)
- `[MODIFY] games/wildcircuit/animals/wild_animal.gd`: Implement stylized multi-part animal meshes (gazelle, lion, elephant, zebra) with behavioral state machine (graze, drink, wander, alert, flee).
- `[MODIFY] games/wildcircuit/photography/camera_mode.gd`: Enforce strict photo scoring verifying species, framing, distance, and required behavior.
- `[MODIFY] games/wildcircuit/world/wild_biomes.gd`: Build distinct living biomes (Savannah, Forest, Wetlands, Desert) with biome-specific vegetation and lighting.
- `[MODIFY] games/wildcircuit/traversal/explorer_atv.gd`: Build detailed Safari ATV with usable physics and suspension.
- `[MODIFY] games/wildcircuit/wildcircuit_main.gd`: Implement Ranger character model, viewfinder HUD, and conservation progression.

### Automated Testing & Certification
- `[MODIFY] tests/e2e/test_kart_e2e.gd`: Automated multi-racer AI-only race completing all laps on all tracks.
- `[MODIFY] tests/e2e/test_roboforge_e2e.gd`: Automated blueprint build -> dyno -> challenge -> reward flow.
- `[MODIFY] tests/e2e/test_skybound_e2e.gd`: Automated explore -> puzzle -> shard collection -> region unlock flow.
- `[MODIFY] tests/e2e/test_wildcircuit_e2e.gd`: Automated track -> observe -> photograph grazing behavior -> score -> dossier flow.
- `[MODIFY] games/strike-vector/tests/test_strike_vector_e2e.gd`: Automated mission combat -> extraction trigger -> results -> next stage loading flow.
- `[MODIFY] scripts/certifier.py`: Update automated certification script to validate all 8 games with runtime evidence.

---

## 5. Verification Plan

### Automated Tests
1. **Full Headless Suite Run**:
   `podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd`
   - Verify >90% coverage and 100% test pass rate across all unit, integration, and E2E suites.
2. **Individual Game E2E Suites**:
   - `test_kart_e2e.gd`: 6 karts race 3 full laps, verify 0 stuck, correct finish order.
   - `test_strike_vector_e2e.gd`: Player clears encounter, steps onto extraction helipad, results screen appears, next mission loads stage 2 with different biome.
   - `test_roboforge_e2e.gd`: Change blueprint parts, verify mass/speed stats change, complete obstacle course, receive part reward.
   - `test_skybound_e2e.gd`: Traversal mechanics, collect 3 shards, solve puzzle, unlock region 2.
   - `test_wildcircuit_e2e.gd`: Approach gazelle, wait for grazing state, capture photo, verify score > 70 and objective complete.

### Runtime Packaged Visual Validation
- Capture real runtime screenshots across all games using Playwright / headless captures showing:
  - Drift Storm: Controllable drifting, grounded wheels, active AI grid.
  - Strike Vector: Distinct stage 1 & stage 2 environments, working extraction helipad, results screen.
  - RoboForge Arena: Detailed modular robot in workshop turntable, obstacle course with moving hazards.
  - Skybound Odyssey: Sculpted floating islands, stylized adventurer gliding, glowing shard artifacts.
  - WildCircuit: Ranger ATV, gazelle grazing, camera viewfinder photo score.
- Generate `artifacts/acceptance.json` and `artifacts/acceptance.html` with full platform matrix and test results.
