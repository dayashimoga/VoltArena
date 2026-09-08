# VoltArena — User Guide & Platform Manual

## 1. Welcome to VoltArena
**VoltArena** is a unified 3D gaming arcade featuring eight distinct titles accessible through an interactive cyberpunk launcher.

---

## 2. Navigating the Launcher

Upon launching VoltArena, you are greeted by the 3D Holographic Menu:
* **Game Carousel**: The 8 games are displayed as interactive holographic cards:
  1. **Iron Crucible** (Tactical Arena FPS)
  2. **Metro Siege** (Subway Survival FPS)
  3. **Nitro Kick** (Rocket-Car Football)
  4. **Drift Storm** (Arcade Kart Racing)
  5. **Skybound Odyssey** (3D Open-Air Adventure Platformer)
  6. **RoboForge Arena** (Combat Robot Builder & Physics Battler)
  7. **WildCircuit** (Wildlife Safari & Photography Traversal)
  8. **Strike Vector** (Forward-Moving Run-and-Gun Shooter)
* **Launching a Game**: Click on any game card or press the corresponding **PLAY** button. The game assets will instantly load without scene hitches.
* **Global Settings**: Click the **SETTINGS** button in the upper-right corner to configure graphics quality presets (Low, Medium, High, Ultra), audio volume sliders (Master, Music, SFX), and mouse sensitivity.

---

## 3. In-Game Interface (HUD) & Onboarding

Each game features an immediate pre-match onboarding sequence and high-contrast HUD:
* **Pre-Match Onboarding Overlay**:
  * On first launching any game, a dedicated modal presents the game premise, victory objective, and a 2-column controls guide.
  * Dismisses automatically after a brief preview or immediately upon pressing any key, `Space`, or mouse button.
* **Active Objective Badges (Top-Center)**:
  * **Iron Crucible**: `RACE TO 20 FRAGS | YOU: X vs ENEMIES: Y`
  * **Metro Siege**: `OBJECTIVE: SURVIVE 10 WAVES & EXTRACT` (with real-time threat count)
  * **Nitro Kick**: `OBJECTIVE: SCORE 3 GOALS IN ORANGE GOAL`
  * **Drift Storm**: `OBJECTIVE: COMPLETE 3 LAPS — FINISH 1ST`
* **Off-Screen Ball Tracker (Nitro Kick)**:
  * An intelligent screen-space arrow (`▲`, `▼`, `◄`, `►`) tracks the ball position around the screen border when out of view.
  * Real-time distance label shows Euclidean distance (e.g. `BALL 28m`) for optimal positioning.
* **Health & Armor Bars (Bottom-Left)**:
  * **Cyan / Red Bar**: Current health status ($0-100\%$). Turns red when in critical danger.
  * **Blue / Magenta Bar**: Shield armor status ($0-100\%$). Armor absorbs $65\%$ of incoming damage.
* **Ammunition & Boost (Bottom-Right)**:
  * **FPS Games**: Shows current clip rounds and reserve ammo pool (e.g. `30 / 120`). Displays a blinking `RELOADING...` indicator during reload cycles.
  * **Vehicular Games**: Shows current nitrous boost reserves ($0-100\%$).
* **Notification Toasts (Top-Left)**:
  * Displays dynamic messages such as `"WAVE 1 STARTED"`, `"KICKOFF!"`, `"LAP 2 / 3"`, and `"YOU WERE ELIMINATED!"`.

---

## 4. Pause Menu & In-Game Options

Pressing `Escape` (or the `Pause / Start` button on a controller) opens the unified **Pause Menu**:
* **Resume**: Closes the pause overlay and returns instantly to gameplay.
* **Restart Match**: Restarts the active game round from the beginning.
* **Quit to Launcher**: Gracefully cleans up scene entities and returns to the master launcher menu.

---

## 5. Post-Match Results Screen

When a match concludes (time runs out, all waves survived, race finished, or goal limit reached), the **Results Screen** displays:
* **Victory / Defeat Status**: Highlighting performance metrics.
* **Stats Breakdown**: Kills, deaths, score, waves survived, goals scored, best lap time, and accuracy.
* **Actions**: One-click buttons to **PLAY AGAIN** or **QUIT TO LAUNCHER**.

---

## 6. In-Depth Tactical Strategy Guides

### 6.1 Iron Crucible
* **Weapon Synergy**: Open with Rail Driver at long range through catwalk corridors, then hot-swap (`1` or `2`) to Pulse Rifle or Scatter Cannon as enemies close in.
* **Verticality**: Exploit jump pads to reach elevated sniper roosts and control health pickup nodes.

### 6.2 Metro Siege
* **Platform Defense**: Hold the central station platform between the cast-iron columns. Do not get trapped in dead-end track pits.
* **Scrap Economy**: Prioritize collecting glowing scrap gears between waves. Visit the kiosk terminal before the 10-second intermission ends to purchase damage and shield upgrades.

### 6.3 Nitro Kick
* **Boost Pathing**: Maintain possession by driving over the glowing boost rings around the perimeter.
* **Aerial Interceptions**: Use the double-jump mechanic with pitch-up rotation to block high shots and spike the ball into the opponent net.

### 6.4 Drift Storm
* **Mini-Turbo Timing**: Initiate drifts early before hairpin bends; hold drift angle until purple sparks erupt for a tier-3 speed surge down the following straight.
* **Powerup Management**: Hold the Plasma Shield powerup when leading the pack to counter incoming Seeker Missiles.

### 6.5 Strike Vector
* **Forward Momentum**: Never linger in cleared zones. Advancing into the next sector triggers segment preloading and route progression.
* **Slide-Fire & Dodge-Roll**: Combine sprint with crouch (`Shift` + `C`) to slide-fire underneath incoming projectile barrages. Tap `Ctrl` or double-tap direction to dodge-roll away from grenade blast radii.
* **Weakpoint Prioritization**: Aim for glowing head units and heat sinks on Elites and Mechs for $2.0\times$ to $2.5\times$ damage multipliers.
* **Power Module Combos**: Stacking Piercing Module with Overdrive turns high-density enemy choke-points into instant multi-kill score bonuses.

