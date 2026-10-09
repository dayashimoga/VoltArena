# VOLTARENA — MASTER GAMEPLAY DESIGN DOCUMENT (GDD)
## Comprehensive Systems, Mechanics, Loops & Progression Architecture (v8.0.0)

---

## 1. Executive Summary & Monorepo Taxonomy

**VoltArena** is an omnibus, multi-genre gaming ecosystem built on **Godot 4.3 Stable** using the high-performance `gl_compatibility` renderer. The monorepo unites **10 complete, native 3D arcade games** under a shared core runtime while providing full standalone independence for every individual title.

```
                              VOLTARENA MONOREPO
                                      |
       +------------------------------+------------------------------+
       |                                                             |
SHARED GAME CORE                                              GAME MODULES (10)
- InputManager (KBM/Pad/Touch)                                 1. AeroRush: Impossible Circuit
- PhysicsHelpers & Fixed 60Hz                                  2. Chroma Rush: The Color Chase
- QualityManager & Profiles                                    3. Drift Storm (Kart Racing)
- AudioManager & Synthesizers                                  4. Strike Vector (Run-and-Gun)
- SaveManager & Isolated Namespaces                            5. NitroKick (Rocket Car Soccer)
- Telemetry & EventBus                                         6. MetroSiege (Subway Survival)
                                                               7. IronCrucible (Arena FPS)
                                                               8. RoboForge Arena (Mech Action)
                                                               9. WildCircuit (Ranger Safari)
                                                              10. Skybound Odyssey (Island Explorer)
```

---

## 2. P0 Feature Deep Dive: AeroRush — Impossible Circuit

### 2.1 Game Overview & High Concept
**AeroRush** is an extreme-speed 3D stunt platform racing game where players pilot futuristic high-downforce craft across physically disconnected elevated tracks, traversing massive aerial chasms, 360° vertical loops, 75° skyscraper wall-rides, and kinetic obstacle courses.

```text
                    AERORUSH STUNT COURSE FLOW

 [START GRID]
      |
      v
+------------------+
| Acceleration     | ===> Turbo Boost Pad (+22 m/s)
| Launch Zone      |
+------------------+
        \
         \    JUMP GAP 1 (Ballistic Arc: V >= 26 m/s)
          \       .......
           \           +--------------------+
            ---------->| Landing Apron      | ===> Catch Barriers (Flanking)
                       | Island B           |
                       +--------------------+
                                 |
                           360° VERTICAL LOOP
                           (Centrifugal Adhesion)
                                 |
                       +--------------------+
                       | Rooftop Platform C |
                       | 75° Wall Ride      |
                       +--------------------+
                                 \
                                  \   JUMP GAP 2 (Elevation Drop)
                                   \      .......
                                    \           +--------------------+
                                     ---------->| Moving / Split     |
                                                | Stunt Island D     |
                                                +--------------------+
                                                          |
                                                    STUNT COMBOS
                                                          |
                                                +--------------------+
                                                | Finish Stadium E   |
                                                | Victory Dossier    |
                                                +--------------------+
```

### 2.2 Vehicle Fleet & Dynamics Specs
Located in `games/aero-rush/vehicles/aero_vehicle_catalog.gd`:

| Vehicle Identifier | Class Archetype | Top Speed ($m/s$) | Accel ($m/s^2$) | Grip Factor | Mass ($kg$) | Air Authority (Pitch / Yaw / Roll) | Stunt Specialization |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Apex Zephyr** | Hypercar Prototype | 64.0 (230 km/h) | 46.0 | 1.15 | 950 | 3.8 / 4.0 / 4.5 rad/s | High-speed aerial leaps & barrel rolls |
| **Torque Stryker** | High-Downforce GT | 58.0 (208 km/h) | 42.0 | 1.30 | 1,120 | 3.5 / 3.8 / 4.0 rad/s | 360° loops & high-G wall rides |
| **Vanguard Dune** | Stunt Trophy Buggy | 52.0 (187 km/h) | 40.0 | 1.05 | 1,280 | 4.2 / 4.2 / 4.8 rad/s | Rough terrain, landing stability, chasm drops |
| **Quantum Phantom** | Mag-Lev Exotic | 62.0 (223 km/h) | 48.0 | 1.25 | 980 | 4.0 / 4.2 / 5.0 rad/s | Precision acrobatic spins & multi-axis combos |

### 2.3 Physics & Flight Kinematics
- **Surface-Normal Relative Gravity**:
  $$\vec{g}_{\text{eff}} = -\hat{n}_{\text{track}} \cdot g_{\text{surface}}$$
  When forward velocity $v \ge 16\text{ m/s}$ on banked tracks or vertical loops, centrifugal downforce adheres the craft to the track normal.
- **Air Attitude Thrusters**: In flight, directional steering inputs seamlessly transition to attitude thrusters allowing 360° spins, front/backflips, and barrel rolls without uncontrolled tumble.
- **Ballistic Jump Validation**: Jump trajectories follow kinematic projectile equations:
  $$x(t) = v_0 \cos(\theta) t, \quad y(t) = v_0 \sin(\theta) t - \frac{1}{2} g t^2$$
  All 12 courses enforce $v_{\text{launch}} \ge v_{\text{min}}$ via preceding straightaways and turbo boost pads (+22 m/s).
- **Landing Evaluation**:
  - Alignment angle $\le 18^\circ$: **PERFECT LANDING** (+500 pts, nitro refill, shockwave VFX).
  - Alignment angle $18^\circ - 38^\circ$: **CLEAN LANDING** (+150 pts, suspension absorption).
  - Alignment angle $> 65^\circ$: **CRASH / ROLLOVER** (One-shot safe respawn at last safe checkpoint with 2.5s cooldown).

---

## 3. P0 Feature Deep Dive: Chroma Rush — The Color Chase

### 3.1 Game Overview & High Concept
**Chroma Rush** is a high-octane open-city vehicular heist and delivery game. Players race through an architecturally detailed neon metropolis, hunting target vehicles of specific color frequencies, pulling alongside at matched speed to trigger an atomic bidirectional color swap, and delivering the acquired color to active district delivery beacons before time expires.

```text
                 CHROMA RUSH CORE GAMEPLAY LOOP

      [START MISSION]
             |
             v
      [SAFE ROAD SPAWN]  (Elevation probed, curbs cleared)
             |
             v
      [LOCATE TARGET COLOR]  (Compass indicator & radar blip)
             |
             v
      [PURSUIT & PROXIMITY MATCH]  (Distance < 8.0m, relative speed matched)
             |
             v
      [ATOMIC COLOR SWAP]  (Bidirectional exchange, cooldown 1.5s)
             |
             v
      [NAVIGATE TO DELIVERY BEACON]  (Dynamic waypoint guidance)
             |
             v
      [DELIVERY VALIDATION & SCORE]  (Combo multiplier, time bonus)
             |
             v
      [NEXT MISSION / ESCALATION]
```

### 3.2 Mission Types
1. **Color Hunt**: Standard sequential chase. Locate 3 specific target colors in order.
2. **Chroma Sprint**: High-speed time attack requiring rapid swaps under strict time limits.
3. **Puzzle Drive**: Match specific color-blending logic (e.g., Red + Blue $\to$ Purple delivery).
4. **Color Heist**: Steal high-value chromatic cargo from guarded escort convoys.
5. **Competitive Challenge**: Rival AI vehicles contest colors and attempt counter-swaps.

---

## 4. Complete Catalog of Monorepo Titles (3 through 10)

### 4.1 Drift Storm (Arcade Kart Racing)
- **Genre**: Arcade Kart Racing.
- **Circuits**: 6 diverse tracks (Speedway, Sunset Coast, Red Rock Canyon, Metro Night, Alpine Rush, Storm Harbor).
- **Mechanics**: Powerslide drifting, 3-tier mini-turbo boosts (Blue/Orange/Purple), dynamic item pickups (Homing Rockets, Speed Mushrooms, EMP Mines, Shields), 5 AI rivals.
- **Progression**: Grand Prix cups, Time Trials with ghost replay, kart cosmetic unlocks.

### 4.2 Strike Vector (3D Tactical Run-and-Gun)
- **Genre**: Forward-advancing 3D Tactical Action Shooter.
- **Missions**: 8 campaign theaters (Urban Blackout, High-Speed Rail, Harbor Assault, Desert Convoy, Arctic Installation, Megafactory, Sky Fortress, Final Citadel).
- **Combat**: 5 distinct weapons (Pulse Rifle, Scatter Cannon, Rail Driver, Grenade Launcher, Plasma Cutter), squad tactics, directional damage indicators, multi-phase boss encounters, authored extraction helipads.

### 4.3 NitroKick (Rocket Car Soccer)
- **Genre**: Vehicular Sports / Rocket Car Soccer.
- **Arena**: Enclosed high-tech stadium with floodlights, goal nets, grandstands, dynamic jumbotron scoreboard.
- **Mechanics**: Physical soccer ball with bouncy restitution, rocket booster thrusters for aerial maneuvers, stadium ground boost pads, overtime sudden-death rules.

### 4.4 MetroSiege (Subway Wave Survival)
- **Genre**: Procedural Wave Defense / Survival Action.
- **Setting**: Atmospheric subterranean transit hub with volumetric fog, flickering strip lights, and grimy tile.
- **Mechanics**: 10-wave horde escalation against bio-crawler variants (Vanguard Crawlers, Acid Spitters, Armored Brutes), scrap gear currency drops, ticket kiosk weapon upgrade terminals, and the BioColossus apex boss encounter.

### 4.5 IronCrucible (Arena FPS Tournament)
- **Genre**: Fast-Paced Arena Deathmatch FPS.
- **Environment**: Multi-level industrial arena with catwalks, jump pads, dusk sky, and dynamic floodlights.
- **Mechanics**: 20-frag tournament objective, 5 cyber weapons, rotating health/armor/ammo pickup stations, combat killfeed, intelligent bot navigation.

### 4.6 RoboForge Arena (Modular Mech Platformer/Combat)
- **Genre**: Robotic Obstacle Platformer & Kinetic Combat.
- **Features**: Modular robot assemblies with articulated limbs, continuous ramp obstacle courses, wall climbing, kinetic traps, and energy core collection.

### 4.7 WildCircuit (Savannah Ranger Exploration)
- **Genre**: 3D Eco-Ranger Safari & Wildlife Photography.
- **Features**: Forward-facing ranger character, off-road ATV vehicle, procedural savannah biome with acacia trees and granite kopjes, camera photography scoring, and contextual wildlife encounters.

### 4.8 Skybound Odyssey (Floating Island Explorer)
- **Genre**: Third-Person Fantasy Archipelago Adventure.
- **Features**: Floating island chain connected by light bridges, third-person orbit camera, ancient energy shard artifacts, jump-pad elevation transitions, and environmental puzzles.

---

## 5. Universal Adaptive UI/UX & Controls Standard

### 5.1 Input Abstraction Architecture
Every title interfaces through `InputManager` and `PlatformCapabilities`, automatically supporting:
- **Desktop (Keyboard & Mouse)**: Full WASD / Arrow keys, Mouse Look, remappable key bindings.
- **Controller / Gamepad**: Standard Xbox/PlayStation layout (Left Stick steer/move, Right Stick look/camera, Triggers throttle/brake/shoot, Face buttons action/jump/boost). Full gamepad navigation across menus.
- **Mobile Touch**: Context-aware virtual joystick and on-screen touch buttons with $\ge 48\text{dp}$ touch targets and safe-area notch insets.

### 5.2 Universal Pause & Navigation Invariant
Pressing `ESC`, `Gamepad Back/Start`, or the HUD Pause button consistently opens the modal menu:
- **RESUME**
- **RESTART CHECKPOINT**
- **RESTART MISSION / RACE**
- **CONTROLS / SETTINGS**
- **GRAPHICS PRESETS** (Low / Medium / High / Ultra)
- **AUDIO CONTROLS** (Master / SFX / Music)
- **ACCESSIBILITY** (High contrast, scalable fonts, reduced motion)
- **MAIN MENU**
- **VOLTARENA LAUNCHER** (Appears only when launched via full suite)
- **QUIT**
