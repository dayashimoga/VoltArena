# VoltArena — User Guide & Platform Manual

## 1. Welcome to VoltArena
**VoltArena** is a unified 3D gaming arcade featuring four distinct titles accessible through an interactive cyberpunk launcher.

---

## 2. Navigating the Launcher

Upon launching VoltArena, you are greeted by the 3D Holographic Menu:
* **Game Carousel**: The 4 games are displayed as interactive holographic cards:
  1. **Iron Crucible** (Tactical Arena FPS)
  2. **Metro Siege** (Subway Survival FPS)
  3. **Nitro Kick** (Rocket-Car Football)
  4. **Drift Storm** (Arcade Kart Racing)
* **Launching a Game**: Click on any game card or press the corresponding **PLAY** button. The game assets will instantly load without scene hitches.
* **Global Settings**: Click the **SETTINGS** button in the upper-right corner to configure graphics quality presets (Low, Medium, High, Ultra), audio volume sliders (Master, Music, SFX), and mouse sensitivity.

---

## 3. In-Game Interface (HUD)

Each game shares a standardized, high-contrast neon HUD designed for maximum readability:
* **Health & Armor Bars (Bottom-Left)**:
  * **Cyan / Red Bar**: Current health status ($0-100\%$). Turns red when in critical danger.
  * **Blue / Magenta Bar**: Shield armor status ($0-100\%$). Armor absorbs $65\%$ of incoming damage.
* **Ammunition & Boost (Bottom-Right)**:
  * **FPS Games**: Shows current clip rounds and reserve ammo pool (e.g. `30 / 120`). Displays a blinking `RELOADING...` indicator during reload cycles.
  * **Vehicular Games**: Shows current nitrous boost reserves ($0-100\%$).
* **Match Status (Top-Center)**:
  * Shows remaining match time, current wave number, score, or lap countdown.
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
