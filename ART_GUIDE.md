# VoltArena — Art Direction & Technical Art Guide

## 1. Vision & Core Philosophy
VoltArena delivers four commercially polished, visually dense 3D game experiences unified by high aesthetic standards, believable environmental storytelling, and rigorous optimization.

### Key Tenets:
1. **Zero Geometric Blockouts**: Every scene is dressed with authentic architectural, prop, and vehicle geometry. No untextured boxes, plain cubes, or primitive cylinders.
2. **PBR Material Coherence**: All surfaces utilize physically based rendering with albedo, roughness, metallic, normal, and ambient occlusion parameters tuned to real-world material responses.
3. **Atmospheric Depth**: Scenes incorporate directional lighting, volumetric fog, color grading, particle emitters, and bloom to establish depth and mood.
4. **Target Reference Alignment**: Every title specifically addresses its reference aesthetic target.

---

## 2. Game-Specific Visual Direction

### 2.1 Iron Crucible — Sci-Fi Cyber Arena (Reference 1)
* **Visual Identity**: High-contrast, nocturnal tactical sci-fi arena reminiscent of high-end competitive arena shooters and cyber-dystopian combat simulations.
* **Floor & Geometry**:
  * Glowing cyan regular hexagonal grid floor (`texture_synthesizer.gd`), rendered via exact geometric hexagonal boundary calculation with a 2-pixel glowing emission band (`emission_energy = 3.8`).
  * Dark matte monolith pillars and catwalk columns (`metallic = 0.85`, `roughness = 0.25`) framing tactical corridors.
  * Warm amber gateway portal archway (`Color(1.0, 0.6, 0.1)`) serving as a focal navigational landmark.
* **Lighting & Atmosphere**:
  * Deep midnight sky with procedural aurora borealis curtains and volumetric fog (`density = 0.003`).
  * Ambient light boosted to `1.45` energy to preserve deep blue shadows without crushing blacks.
  * Floating atmospheric dust particles drifting across catwalks.
* **Player Weapon & Silhouette**:
  * Detailed first-person weapon model with optical sights, textured receiver, and magazine socket.
  * Spring-interpolated weapon sway, recoil kickback, and muzzle flash light emission.

### 2.2 Metro Siege — Subterranean Wave FPS (Reference 2)
* **Visual Identity**: Gritty, claustrophobic subterranean transit station with emergency fluorescent illumination and decaying urban infrastructure.
* **Platform Architecture**:
  * Ceramic subway wall tiles with mortar grout lines generated procedurally at $512 \times 512$ resolution.
  * High-visibility yellow tactile safety hazard edge strip along platform drop-off.
  * Fluted cast-iron load-bearing columns spaced every 8 meters down the platform length.
  * Suspended fluorescent light fixtures casting cool green-white illumination (`Color(0.85, 0.95, 0.9)`).
  * 24-meter passenger train model resting on ballasted steel rails.
* **Environmental Dressing**:
  * Wall-mounted transit route maps, warning posters, and advertising boards.
  * Beverage vending machines, ticketing kiosks, and steel passenger benches.
  * Scattered trash, rusted maintenance pipes, and electrical conduit trunks.
* **Enemy Presentation**:
  * Rigged mutant humanoid combatants, low-slung predatory crawlers, and armored brutes.

### 2.3 Nitro Kick — Enclosed Rocket Stadium (Reference 3)
* **Visual Identity**: Electrifying enclosed sports colosseum built specifically for high-speed rocket car football.
* **Pitch & Markings**:
  * Alternating two-tone green turf bands (`Color(0.18, 0.52, 0.22)` and `Color(0.14, 0.44, 0.18)`).
  * Painted white touchlines, penalty boxes, corner arcs, and center circle.
  * Luminous circular boost pads recessed into the turf with rotating amber glow rings.
* **Stadium Infrastructure**:
  * Tiered spectator grandstands with dense crowd texturing surrounding the perimeter.
  * Overhead steel space-frame roof trusses and high-intensity stadium floodlight towers.
  * Cyan and orange illuminated goal frames with high-speed ball-entry sensor netting.
  * Giant elevated Jumbotron scoreboards displaying real-time match time and scores.
* **Vehicle & Ball Presentation**:
  * Production rocket cars with distinct chassis, spoilers, wheels, and dual booster exhausts.
  * Truncated icosahedron soccer sphere with pentagonal seam textures and dynamic shadow projection.

### 2.4 Drift Storm — Grand Prix Circuit (Reference 4)
* **Visual Identity**: Vibrant, sunlit arcade circuit racing with professional motorsport track dressing and dynamic competition.
* **Track Construction**:
  * Multi-lane asphalt racing surface with tire wear marks and apex racing lines.
  * Alternating red/white and blue/white ripple kerbs along corner apexes and exit runoffs.
  * Continuous Armco corrugated steel and stacked rubber tire safety barriers.
* **Course Dressing**:
  * Overhead start/finish truss gantry with checkered racing banner and 5-lamp start lights sequence.
  * Pit lane structures, flag marshal stations, and trackside sponsor hoardings.
  * Tiered spectator grandstands filled with cheering crowds.
* **Vehicle Presentation**:
  * Low-center-of-gravity racing karts with front splitters, side pods, and exposed engines.
  * Rigged racer drivers with white safety helmets and tinted reflective black visors.

### 2.5 Strike Vector — Urban Blackout & Campaign Biomes
* **Visual Identity**: Nocturnal military blackout cityscape under hostile electronic warfare. The aesthetic balances deep shadows with selective emergency illumination: blinking hazard beacons, amber streetlights, disabled transport vehicles, and emergency barricades against weathered concrete and dark asphalt.
* **Metric Scale Hierarchy (1 Godot unit = 1 Metre)**:
  * Human operative: $1.80\text{m}$ height, $0.40\text{m}$ radius capsule.
  * Vehicles: Authentic full-scale proportions: Enforcer patrol cruiser at $1.6\times$ scale ($4.56\text{m}$ length, $2.08\text{m}$ width, $2.0\text{m}$ height) and heavy utility trucks at $2.2\times$ scale ($6.16\text{m}$ length, $3.3\text{m}$ width, $3.19\text{m}$ height).
  * Street Hierarchy: $14.0\text{m}$ wide two-lane roadway with $3.5\text{m}$ sidewalks ($21.0\text{m}$ total canyon width), lined by $14\text{m}\text{--}24\text{m}$ multi-story buildings with physical box colliders.
* **Materials & Blackout Palette**:
  * Dark grimy concrete facades (`grimy_concrete`) and weathered carbon steel (`sci_fi_metal`) replacing bright pastel townhouses.
  * Blinking orange/red hazard beacons (`_add_beacon`) mounted on concrete road barriers and emergency vehicles.
  * Deep midnight sky lighting (ambient energy $0.35$, directional moonlight $0.85$) with atmospheric distance fog ($0.0035$).
* **Operative & Firearm Aesthetics**:
  * Skinned cybernetic operative with normalized skeletal proportions and upright combat stance ($1.02\text{m}$ shooting height).
  * Firing animation isolation: `_normalize_rig_tracks()` strips `mixamorig_Hips` and leg bone tracks from combat actions, maintaining upright posture across 100+ consecutive shots (`min_up_dot = 1.0`).
  * 9 authentic 3D modeled firearms attached to right-hand `WeaponGrip` with calibrated rotation `Vector3(90, 90, 0)` and palm offset, aligning barrel strictly forward down-range along $-Z$ ($0.027^\circ$ angular error).
  * 5 standardized sockets (`MuzzleSocket`, `MagazineSocket`, `ScopeSocket`, `ShellEjectionSocket`, `LeftHandIKTarget`).
  * Crosshair raycast convergence aligning muzzle projectile velocity with third-person reticle.

---

## 3. PBR Texture Synthesis & Material Architecture

To ensure zero disk I/O stalls during runtime while maintaining high visual density, `texture_synthesizer.gd` generates deterministic PBR textures at launch:

| Texture Type | Resolution | Channels | Generation Algorithm |
| :--- | :---: | :---: | :--- |
| **Hex Grid** | $256 \times 256$ | Albedo + Emission | Regular hexagonal boundary distance calculation |
| **Subway Tile** | $512 \times 512$ | Albedo + Normal | Staggered brick masonry grid with grout indentation |
| **Stadium Turf** | $512 \times 512$ | Albedo + Roughness | Alternating mowed grass stripe frequency modulator |
| **Circuit Asphalt** | $512 \times 512$ | Albedo + Normal | Simplex noise aggregate with micro-grain roughness |
| **Ripple Kerb** | $256 \times 256$ | Albedo | Alternating chromatic bands (red/white, blue/white) |
| **Hazard Stripe** | $256 \times 256$ | Albedo | 45-degree diagonal black and yellow safety chevron generator |

---

## 4. Camera Dynamics & Presentation

Each game implements customized third-person or first-person camera controllers:
1. **FPS Camera (Iron Crucible, Metro Siege)**:
   - Spring-damper view bobbing synchronized with player velocity.
   - Separate rotational pitch/yaw spring to simulate weapon recoil kick and recovery.
   - Field of View: 75° (Default) / 55° (ADS zoom).
2. **Chase Camera (Nitro Kick)**:
   - Dual-target tracking interpolating between player car orientation and soccer ball trajectory.
   - High-speed FOV expansion (+15° under nitrous boost).
3. **Racing Chase Camera (Drift Storm)**:
   - Dynamic look-ahead orienting toward the next track spline waypoint.
   - Lateral roll banking into sharp drift turns.

---

## 5. Performance Budgets & Draw Call Targets
* **Maximum Static Draw Calls**: $\le 250$ per frame (achieved via mesh merging and material instancing).
* **Maximum Triangles**: $\le 150,000$ active in frustum.
* **Texture Memory**: $\le 64\text{ MB}$ total VRAM allocated for procedural and loaded textures.
* **Target Frame Rate**: 60 FPS locked on desktop (1080p), 60 FPS on Web (720p).
