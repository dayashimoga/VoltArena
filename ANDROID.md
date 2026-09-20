# VoltArena — Android Platform Architecture & Release Engineering

## 1. Executive Statement: Android As A First-Class Target

In VoltArena, Android is treated as a tier-1 primary platform rather than a degraded port. The mobile build delivers **100% feature and content parity** with desktop builds:
- Same 8 distinct 3D action, racing, platforming, and sandbox titles.
- Same full campaigns, all 6 Drift Storm circuits, all 5 vehicle classes, and 10-wave horde escalation in Metro Siege.
- Same progression schemas and local save state (`SaveManager`).
- Same procedural mesh generation and PBR shader materials.

---

## 2. Android Lifecycle & System Integration

### 2.1 Cold Launch to Game Loop
1. **Activity Launch**: `com.godot.game.GodotApp` launches via `Intent.ACTION_MAIN`.
2. **Platform Initialization**: `PlatformCapabilities` registers `PlatformCategory.ANDROID` and queries system safe-area insets via `DisplayServer.get_display_safe_area()`.
3. **Audio Routing**: Background music and SFX players attach to the Android media stream. Interruption protocols (`MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT`) immediately pause audio playback and mute engine sounds.
4. **Window Insets & Cutouts**: Notch margins and software navigation bars are queried and accounted for on all UI screens.

### 2.2 Backgrounding, Pausing, and Resume
- **Focus Loss / Home Button (`NOTIFICATION_APPLICATION_FOCUS_OUT`)**:
  - Automatically triggers in-game pause menu in active gameplay scenes (`PauseMenu.show_pause()`).
  - Halts physics loops and timers cleanly.
  - Stops dynamic loop sounds (`AudioManager.stop_engine_sound()`).
- **Resumption (`NOTIFICATION_APPLICATION_FOCUS_IN`)**:
  - Restores OpenGL rendering context without texture corruption.
  - Re-evaluates viewport aspect ratio and adjusts UI layouts if orientation changed.
- **Android System Back Navigation (`KEY_BACK` / Android Back Gesture)**:
  - If inside active gameplay: opens `PauseMenu`.
  - If inside `PauseMenu`: closes pause menu and returns to gameplay.
  - If in pre-race/match configuration hub: navigates to previous step or launcher.
  - If in Universal Launcher: confirms exit dialog.

---

## 3. Touch Input Ergonomics & Minimum Target Sizing

### 3.1 48dp Minimum Touch Target Rule
Following Material Design and Apple Human Interface Guidelines, all interactive touch zones on mobile satisfy:
$$\text{Touch Target Size} \ge 48\text{dp} \times 48\text{dp}$$
In the scaled canvas ($1280\times 720$), action buttons are sized between $52\text{px}$ and $80\text{px}$ to guarantee zero touch misses.

### 3.2 Genre-Adaptive Layouts
1. **Racing (Drift Storm)**:
   - Left hand: Smooth steering virtual joystick or directional buttons with configurable sensitivity.
   - Right hand: Large primary Gas button ($80\times 72\text{px}$), Brake/Reverse button ($72\times 64\text{px}$), and Drift/Boost actions.
2. **Rocket-Sports (Nitro Kick)**:
   - Primary driving pedals + immediate thumb access to Jump and Boost for aerial maneuvers.
   - Dedicated Ball Cam toggle button.
3. **Shooters & Action (Iron Crucible, Metro Siege, Strike Vector)**:
   - Left thumb: Virtual joystick for omnidirectional movement.
   - Right thumb: Unrestricted touch-drag look zone for high-precision aiming.
   - Primary Fire, ADS, Reload, Jump, Crouch, and Weapon Switch buttons placed on comfortable radial arcs.

---

## 4. Build Packaging & CI/CD Pipeline

### 4.1 Artifact Configuration
- **Package ID**: `org.voltarena.gamesuite`
- **Application Label**: `VoltArena`
- **Min SDK**: API 26 (Android 8.0 Oreo)
- **Target SDK**: API 35 (Android 15)
- **Architecture**: ARM64-v8a (production APK/AAB) + x86_64 (emulator CI support).
- **Signing**: Automated v1, v2, and v3 signature schemes via `apksigner` with automated debug/release keystores.

### 4.2 Automated Headless Testing in Container CI
Every commit triggers an automated Android validation pipeline:
1. Compiles APK artifact via Godot headless export.
2. Signs artifact with standard keystore.
3. Spins up Android QEMU emulator in GitHub Actions.
4. Executes `tests/android/test_android.sh`: installs APK, starts main activity, captures logcat, asserts zero fatal process crashes (`FATAL EXCEPTION`, `SIGSEGV`, `ANR`), and exits cleanly.
