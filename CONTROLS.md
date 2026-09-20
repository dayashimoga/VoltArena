# VoltArena — Control Schemes & Input Mappings

## 1. Universal Keyboard & Mouse Controls

### 1.1 FPS Games (Iron Crucible & Metro Siege)
| Action | Key / Mouse Binding | Description |
| :--- | :--- | :--- |
| **Move Forward** | `W` / `Up Arrow` | Walk forward |
| **Move Backward** | `S` / `Down Arrow` | Walk backward |
| **Strafe Left** | `A` / `Left Arrow` | Step left |
| **Strafe Right** | `D` / `Right Arrow` | Step right |
| **Look / Aim** | `Mouse Movement` | Adjust camera pitch & yaw |
| **Primary Fire** | `Left Mouse Button` | Fire active weapon |
| **Aim Down Sights** | `Right Mouse Button` | Zoom camera / tighten weapon spread |
| **Sprint** | `Left Shift` | Increase movement speed to 11.5 m/s |
| **Crouch** | `C` or `Left Ctrl` | Lower stance and reduce hitbox size |
| **Jump** | `Space` | Jump vertically with air control |
| **Reload** | `R` | Reload weapon magazine |
| **Select Weapon 1** | `1` | Equip Pulse Rifle |
| **Select Weapon 2** | `2` | Equip Scatter Cannon |
| **Select Weapon 3** | `3` | Equip Rail Driver |
| **Select Weapon 4** | `4` | Equip Grenade Launcher |
| **Select Weapon 5** | `5` | Equip Plasma Cutter |
| **Next / Prev Weapon** | `Mouse Wheel Up / Down` | Cycle weapon inventory |
| **Pause Menu** | `Escape` | Open in-game menu |

### 1.2 Rocket-Car (Nitro Kick)
| Action | Key / Mouse Binding | Description |
| :--- | :--- | :--- |
| **Throttle / Accelerate** | `W` / `Up Arrow` | Drive forward |
| **Reverse / Brake** | `S` / `Down Arrow` | Decelerate or drive in reverse |
| **Steer Left / Right** | `A` / `D` | Turn front wheels |
| **Jump** | `Space` | Hop; press again mid-air to Double Jump |
| **Air Pitch / Roll** | `W/S` (Pitch), `A/D` (Roll) | Orient vehicle in mid-air |
| **Nitrous Boost** | `Shift` or `Right Mouse Button` | Engage rocket thrusters |
| **Handbrake** | `Left Ctrl` / `Space` | Execute sharp powerslides |

### 1.3 Kart Racing (Drift Storm)
| Action | Key / Mouse Binding | Description |
| :--- | :--- | :--- |
| **Accelerate** | `W` / `Up Arrow` | Full throttle |
| **Brake / Reverse** | `S` / `Down Arrow` | Apply brakes or reverse |
| **Steer** | `A` / `D` | Turn kart left or right |
| **Drift** | `Space` or `Left Mouse Button` | Hold while turning to enter drift mode |
| **Use Powerup** | `E` or `Right Mouse Button` | Fire or deploy collected powerup item |
| **Look Back** | `C` | Glance backward at trailing racers |

### 1.4 Third-Person Run-and-Gun (Strike Vector)
| Action | Key / Mouse Binding | Description |
| :--- | :--- | :--- |
| **Move Forward** | `W` / `Up Arrow` | Move forward along camera heading |
| **Move Backward** | `S` / `Down Arrow` | Move backward along camera heading |
| **Strafe Left / Right** | `A` / `D` | Step left or right |
| **Camera Look / Aim** | `Mouse Movement` | Orbit third-person shoulder camera (click to lock cursor) |
| **Primary Fire** | `Left Mouse Button` | Fire active weapon with crosshair convergence |
| **Aim Down Sights (ADS)**| `Right Mouse Button` | Shoulder zoom, tightens spread, locks character yaw to aim |
| **Sprint** | `Left Shift` | Sprint forward at $9.2\text{ m/s}$ |
| **Crouch / Slide** | `C` or `Left Ctrl` | Crouch; trigger slide-fire when running fast |
| **Jump** | `Space` | Jump vertically with 0.15s coyote & input buffering |
| **Dodge Roll** | `Q` or `Shift` + Direction | Rapid evasive roll |
| **Ledge Mantle** | `Auto` | Mantle onto elevated cover or container edges |
| **Reload** | `R` | Reload weapon magazine |
| **Grenade** | `G` | Throw offensive fragmentation grenade |
| **Select Weapons 1–9** | `1` through `9` | Instant access to 9 distinct firearms |
| **Cycle Weapon** | `Mouse Wheel Up / Down` | Cycle weapon inventory |
| **Tactical Satellite Map**| `M` | Toggle full-screen tactical mission schematic |
| **Pause Menu** | `Escape` | Open in-game menu and release mouse cursor |

---

## 2. Gamepad / Controller Mappings (Xbox / PlayStation)

| Action | Xbox Controller | PlayStation DualShock / DualSense |
| :--- | :--- | :--- |
| **Movement / Steering** | Left Thumbstick | Left Thumbstick |
| **Aiming / Camera** | Right Thumbstick | Right Thumbstick |
| **Primary Fire / Drift** | Right Trigger (`RT`) | `R2` Trigger |
| **Aim / Secondary / Boost** | Left Trigger (`LT`) | `L2` Trigger |
| **Jump / Handbrake** | `A` Button | Cross ($\times$) Button |
| **Sprint / Nitro** | Left Stick Click (`LSB`) | `L3` Click |
| **Crouch** | `B` Button / Right Stick Click | Circle ($\bigcirc$) Button / `R3` Click |
| **Reload / Use Powerup** | `X` Button | Square ($\square$) Button |
| **Cycle Weapon** | `Y` Button / Bumpers (`LB`/`RB`) | Triangle ($\bigtriangleup$) / `L1`/`R1` |
| **Pause Game** | `Menu` / `Start` Button | `Options` Button |

---

## 3. Touch Screen Controls (Mobile & Tablets)

When running on mobile browsers, Android phones, or touchscreen tablets, VoltArena deploys **Genre-Adaptive Touch Layouts** through `TouchControls` (`shared/input/touch_controls.gd`). All interactive touch buttons strictly respect the **$\ge 48\times 48\text{dp}$ minimum touch target** rule (52px to 80px on standard viewports) to eliminate touch misses.

### 3.1 Racing Genre Layout (Drift Storm)
- **Steering Control (Bottom-Left)**: Virtual thumb joystick or left/right steering pads.
- **Action Cluster (Bottom-Right)**:
  - **GAS (Accelerate)**: Prominent green acceleration pedal ($80\times 72\text{px}$).
  - **BRAKE (Reverse / Decel)**: Coral brake button ($72\times 64\text{px}$).
  - **DRIFT**: High-leverage amber drift button for corner power-slides.
  - **BOOST**: Cyan nitrous burst trigger.

### 3.2 Rocket-Sports Genre Layout (Nitro Kick)
- **Drive Controls (Bottom-Right)**: GAS and BRAKE buttons.
- **Aerial & Jump Controls**:
  - **JUMP**: Azure jump button; double-tap in mid-air to trigger directional double jump.
  - **BOOST**: Rocket thruster propulsion button.
  - **DRIFT**: Sharp handbrake powerslide button.
  - **BALL CAM**: Toggle tracking camera locked to the ball.

### 3.3 FPS & Action Genre Layout (Iron Crucible, Metro Siege, Strike Vector)
- **Movement (Bottom-Left)**: Omnidirectional `VirtualJoystick` ($48\text{px}$ deadzone with dynamic centering).
- **Camera Look (Right Half Screen)**: Free-drag swipe zone for responsive target acquisition and fine aiming.
- **Combat Cluster (Bottom-Right)**:
  - **FIRE**: Large primary trigger button with instant response.
  - **ADS**: Aim down sights toggle / shoulder zoom.
  - **RELOAD**: Magazine refresh button.
  - **JUMP / CROUCH**: Vertical mobility and sliding toggles.
  - **WEAPON**: Fast circular weapon switch toggle.

### 3.4 Automatic Desktop Hiding
Touch controls automatically hide on desktop environments when no touchscreen is present (`PlatformCapabilities.has_touchscreen() == false`), and automatically display on mobile/tablet platforms or when simulated in testing.

---

## 4. InputProfile Semantic Action Resolution

VoltArena decouples game input from hardware-specific keys via `InputProfile` (`shared/platform/input_profile.gd`). In-game prompts dynamically reflect the player's active input method:

| Action | Desktop Keyboard & Mouse | Desktop Gamepad | Mobile & Tablet Touch |
| :--- | :--- | :--- | :--- |
| **Movement** | `W / A / S / D` | `Left Stick` | `Virtual Joystick` |
| **Primary Fire / Gas** | `LMB` | `Right Trigger (RT)` | `[FIRE]` / `[GAS]` |
| **Aim / Secondary / Brake** | `RMB` | `Left Trigger (LT)` | `[ADS]` / `[BRAKE]` |
| **Jump** | `Space` | `(A) Button` | `[JUMP]` |
| **Boost / Nitro** | `Shift` / `Space` | `(B) Button` | `[BOOST]` |
| **Drift / Slide** | `Shift` / `C` | `(X) Button` | `[DRIFT]` |
| **Reload / Interact** | `R` / `E` | `(X) Button` | `[RELOAD]` |
| **Pause** | `Escape` | `Start / Menu` | `[PAUSE]` |

