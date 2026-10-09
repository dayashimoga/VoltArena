# VOLTARENA — UNIVERSAL PLATFORM SUPPORT MATRIX & RUNTIME GUIDE
## Comprehensive Cross-Platform Engineering, Hardware Tiers & Input Standards (v8.0.0)

---

## 1. Executive Platform Matrix & Release Targets

VoltArena provides genuine multiplatform distribution across Desktop, Web, and Mobile architectures from a single, unified Godot 4.3 codebase.

| Platform Target | Release Status | Standalone Deliverables (10 Games) | Suite Deliverable | Render Backend | Tested Environment |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Windows x86_64** | **PROVEN** | 10 Portable ZIPs (`*-Windows-x86_64.zip`) | `VoltArena-Full-Windows-x86_64.zip` | Direct3D12 / GL Compatibility | Windows 11 x64, 60+ FPS |
| **Linux x86_64** | **PROVEN** | 10 Portable Tarballs (`*-Linux-x86_64.tar.gz`) | `VoltArena-Full-Linux-x86_64.tar.gz` | Vulkan / GL Compatibility | Ubuntu 22.04 LTS / Container |
| **Web (HTML5/WASM)** | **PROVEN** | 10 Deployable ZIPs (`*-Web.zip`) | `VoltArena-Full-Web.zip` | WebGL 2.0 / GL Compatibility | Chrome, Edge, Firefox, Safari |
| **Android (ARM64/x64)** | **PROVEN** | Export Preset Configured | `VoltArena-Full-Android.apk` | OpenGL ES 3.0 / GL Compatibility | Android API 26 through 35 |
| **macOS (Apple Silicon/x64)** | **HARDWARE_REQUIRED** | Export Preset Configured | Export Preset Configured | Metal / GL Compatibility | macOS Runner + Apple Dev ID required |
| **iOS (ARM64)** | **HARDWARE_REQUIRED** | Export Preset Configured | Export Preset Configured | Metal / GL Compatibility | macOS Xcode + Provisioning profile required |

---

## 2. Hardware Performance Tiers & Graphics Profiles

Located in `res://shared/graphics/graphics_profile.gd` and `res://shared/graphics/quality_manager.gd`:

```
+-----------------------------------------------------------------------------------+
| PRESET LOW     | 720p Scaled   | Shadows OFF  | MSAA OFF | Particles: 30% budget  |
+-----------------------------------------------------------------------------------+
| PRESET MEDIUM  | 1080p Dynamic | Shadows MED  | FXAA     | Particles: 65% budget  |
+-----------------------------------------------------------------------------------+
| PRESET HIGH    | 1080p Native  | Shadows HIGH | 2x MSAA  | Particles: 100% budget |
+-----------------------------------------------------------------------------------+
| PRESET ULTRA   | 1440p / 4K    | Shadows MAX  | 4x MSAA  | Full Volumetrics & PBR |
+-----------------------------------------------------------------------------------+
```

### 2.1 Quality Invariants
1. **Physics Invariance**: `Engine.physics_ticks_per_second` is permanently locked to 60 Hz across all quality presets. Graphic fidelity adjustments alter only visual parameters (shadow map size, SSAO, bloom, mesh LOD distance) with zero physics divergence.
2. **Memory Budgets**:
   - Web bundle heap budget: $\le 512\text{ MB}$.
   - Mobile RAM budget: $\le 1.2\text{ GB}$.
   - Desktop VRAM budget: $\le 2.5\text{ GB}$.

---

## 3. Universal Input & Device Adaptation

### 3.1 Device Abstraction Layer (`InputManager` & `InputProfile`)
- **Keyboard & Mouse**:
  - Steering / Movement: `W`, `A`, `S`, `D` / Arrow Keys.
  - Throttle / Accelerate: `W` / `Up Arrow`.
  - Brake / Reverse: `S` / `Down Arrow`.
  - Drift / Handbrake: `Spacebar`.
  - Nitro Boost: `Shift` / `E`.
  - Color Swap / Action: `E` / `F`.
  - Pause / Menu: `Escape`.
- **Gamepad / Controller**:
  - Left Analog Stick: Steering / Traversal vector.
  - Right Analog Stick: Camera look / Stunt air attitude.
  - Right Trigger ($RT$ / $R2$): Progressive Throttle.
  - Left Trigger ($LT$ / $L2$): Progressive Brake / Reverse.
  - Bottom Face Button ($A$ / $\times$): Handbrake / Drift.
  - Left Shoulder ($LB$ / $L1$): Nitro Boost.
  - Top Face Button ($Y$ / $\Delta$): Reset to Track / Road.
  - Start / Menu: Modal Pause Menu.
- **Mobile Touch Overlay (`TouchControls`)**:
  - Dynamically activates on touchscreen devices or mobile user agents.
  - Floating virtual joystick with dynamic origin and thumb deadzone.
  - Sized for minimum $48\times 48\text{dp}$ touch targets with tactile visual feedback.

### 3.2 Safe Area Insets & Responsive Scaling
`PlatformCapabilities.apply_safe_area_margins()` queries the display hardware for cutouts (camera notches, home indicator bars, dynamic islands):
```gdscript
var safe_rect = DisplayServer.get_display_safe_area()
# Automatically applies anchor offsets to HUD, preventing clipped timers or speedometer gauges
```

---

## 4. Web Engine & Cloudflare Pages Delivery

### 4.1 Cloudflare 25 MB Single-File Limit Compliance
Cloudflare Pages imposes a hard 25 MB per-asset limit. VoltArena web builds automatically execute the chunking pipeline:
1. `index.wasm` ($35.3\text{ MB}$) is split into $\le 18\text{ MB}$ parts (`index.wasm.part00`, `index.wasm.part01`).
2. `index.pck` ($98.9\text{ MB}$) is split into $\le 18\text{ MB}$ parts (`index.pck.part00` through `index.pck.part05`).
3. [inject_web_hook.sh](file:///h:/gamesmodern/scripts/inject_web_hook.sh) embeds `platform/web/reassembler_hook.html` into `index.html`, transparently recombining chunks into memory streams before WebAssembly instantiation.
4. `platform/web/_headers` injects strict Cross-Origin Isolation headers (`COOP: same-origin`, `COEP: require-corp`) required for `SharedArrayBuffer` and high-resolution timers.
