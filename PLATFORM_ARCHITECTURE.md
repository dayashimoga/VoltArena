# VoltArena — Global Cross-Platform Architecture

## 1. Overview & Architectural Principles

VoltArena is engineered with a strict **Platform-Independent Core Architecture**. Gameplay logic, physics simulations, AI behaviors, and progression state are fully decoupled from platform-specific APIs, input devices, and display constraints.

```
+-------------------------------------------------------------------------+
|                              VoltArena                                  |
|     (Launcher + 8 Distinct 3D Action, Racing & Sports Game Titles)      |
+-------------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          |                         |                         |
          v                         v                         v
+--------------------+    +--------------------+    +--------------------+
| PlatformCapability |    |    InputProfile    |    |  GraphicsProfile   |
|   (Display/OS)     |    | (Semantic Input)   |    | (Rendering Presets)|
+--------------------+    +--------------------+    +--------------------+
          |                         |                         |
+--------------------+    +--------------------+    +--------------------+
| DisplayServer Inset|    | Desktop KBM / Pad  |    | Viewport Scale     |
| Safe-Area Margins  |    | Adaptive Touch UI  |    | Shadow Atlas / AA  |
| Performance Tiers  |    | >=48dp Touch Area  |    | Fixed 60Hz Physics |
+--------------------+    +--------------------+    +--------------------+
```

### Core Invariants
1. **Gameplay Invariance**: Physical rules, collision metrics, AI navigation, and difficulty tuning remain 100% identical regardless of rendering frame rate or graphics preset. `Engine.physics_ticks_per_second` is locked strictly at 60 Hz.
2. **Deterministic State Synchronization**: Save data schema (`SaveManager`) is unified across Web, Windows, Linux, and Android.
3. **No Platform-Reduced Editions**: Android and Web targets expose the exact same game titles, levels, vehicle classes, campaign encounters, and progression rewards as Desktop.

---

## 2. PlatformCapabilities Subsystem

Located at `res://shared/platform/platform_capabilities.gd`, `PlatformCapabilities` acts as the single source of truth for platform identity, screen geometry, and hardware tiers.

### 2.1 Supported Targets
- **Web**: Chrome, Edge, Firefox, Safari (Godot GL Compatibility / WASM).
- **Windows**: x86_64 native binaries with Direct3D12 / OpenGL fallback.
- **Android**: ARM64 and x86_64 devices, spanning Android 8.0 (API 26) through Android 15 (API 35).
- **Linux**: x86_64 native binaries with X11/Wayland.
- **macOS / iOS**: Supported via platform abstraction wrappers.

### 2.2 Safe Area Insets & Responsive Metrics
`PlatformCapabilities.get_safe_area_margins(viewport_size: Vector2)` calculates pixel-accurate insets for camera punch-holes, display notches, and system navigation bars. The helper `PlatformCapabilities.apply_safe_area_margins(control: Control)` automatically applies offset anchors to prevent UI clipping.

### 2.3 Hardware Performance Tiers
`PlatformCapabilities.get_device_tier()` automatically maps host capability:
- `TIER_LOW`: Budget mobile devices ($\le 4$ CPU cores, low memory). Uses `PRESET_LOW`.
- `TIER_MEDIUM`: Mid-range mobile and standard Web exports. Uses `PRESET_MEDIUM`.
- `TIER_HIGH`: High-end mobile and standard desktop hardware. Uses `PRESET_HIGH`.
- `TIER_ULTRA`: High-performance gaming PCs ($\ge 8$ cores, dedicated GPU). Uses `PRESET_ULTRA`.

---

## 3. Input Abstraction & Adaptive Genre Controls

Located at `res://shared/platform/input_profile.gd` and `res://shared/input/touch_controls.gd`.

### 3.1 Input Profiles
- `DESKTOP_KEYBOARD_MOUSE`: Mouse-look, WASD movement, contextual key prompts (`[W/S]`, `[SPACE]`, `[LMB]`, `[RMB]`).
- `DESKTOP_CONTROLLER`: Gamepad left-stick movement, right-stick look, trigger firing, button prompts (`(A)`, `(B)`, `RT`, `LT`).
- `TOUCH_PHONE`: Dual virtual thumb zones, floating action buttons, touch prompts (`[JOYSTICK]`, `[TAP FIRE]`, `[BOOST]`).
- `TOUCH_TABLET`: Scaled tablet touch interface with expanded ergonomics.

### 3.2 Genre-Adaptive Touch Layouts
Every touch action button strictly enforces a minimum touch target size of **$\ge 48\times 48\text{dp}$** (conforming to Material Design and Apple Human Interface Guidelines).
- **Racing (Drift Storm)**: Large Gas (`[GAS]`, $80\times 72\text{px}$) and Brake (`[BRAKE]`, $72\times 64\text{px}$), Drift (`[DRIFT]`), and Boost (`[BOOST]`). Left side hosts steering joystick.
- **Rocket-Sports (Nitro Kick)**: Throttle, Reverse, Jump / Double-Jump, Boost, Drift, and Ball Cam Toggle.
- **FPS / Third-Person Action (Iron Crucible, Metro Siege, Strike Vector)**: Prominent Fire button, ADS / Alt-Fire, Reload, Jump, Crouch, and Weapon Switch. Right half of the screen acts as an unrestricted drag-to-aim look surface.

### 3.3 Automatic Desktop Hiding
Touch controls automatically hide on desktop environments where no active touchscreen is detected (`PlatformCapabilities.has_touchscreen() == false`), while remaining force-activatable for testing and accessibility.

---

## 4. Scalable Graphics Profiles

Located at `res://shared/platform/graphics_profile.gd`.

| Parameter | Low (Performance) | Medium (Balanced) | High (Quality) | Ultra (Maximum) |
| :--- | :---: | :---: | :---: | :---: |
| **Viewport Render Scale** | 0.75 | 0.85 | 1.00 | 1.00 |
| **Shadow Atlas Size** | 512 | 1024 | 2048 | 4096 |
| **MSAA 3D** | Disabled | 2X | 4X | 8X |
| **Screen-Space AA** | Disabled | FXAA | FXAA | FXAA |
| **Particle Multiplier** | 0.50 | 0.75 | 1.00 | 1.00 |
| **LOD Distance Bias** | 0.60 | 0.80 | 1.00 | 1.20 |
| **Atmospheric Fog** | Disabled | Enabled | Enabled | Enabled |
| **Physics Step Invariant** | **60 Hz** | **60 Hz** | **60 Hz** | **60 Hz** |

---

## 5. Automated 9-Viewport Verification Gates

VoltArena continuously verifies all UI layouts against 9 canonical resolution gates in `tests/responsive/test_responsive_ui.gd`:
1. `360x800` (Modern Android Phone Portrait, 20:9)
2. `393x852` (iPhone 14/15/16 Portrait, 19.5:9)
3. `412x915` (Google Pixel / Galaxy Portrait, 20:9)
4. `600x960` (7-inch Tablet / Foldable, 16:10)
5. `800x1280` (10-inch Android Tablet, 16:10)
6. `1280x720` (Standard HD 720p, 16:9)
7. `1366x768` (Budget Laptop / Scaled Window, 16:9)
8. `1920x1080` (Desktop Full HD 1080p, 16:9)
9. `2560x1440` (Desktop QHD 1440p, 16:9)

All dialogs, HUD elements, game cards, and action buttons are validated to maintain positive bounds, zero off-screen clipping, and 100% click/touch reachability.
