# VoltArena — Troubleshooting & Diagnostic Guide

## 1. Container & Podman Diagnostics

### Symptom: `podman: permission denied` on volume mount
* **Cause**: SELinux or file permissions preventing container process from accessing host directory.
* **Resolution**: Ensure the `:Z` flag is appended to the volume argument:
  ```bash
  podman run --rm -v "${PWD}:/workspace:Z" -w /workspace ...
  ```

### Symptom: PowerShell terminates on native command output (`NativeCommandError`)
* **Cause**: In PowerShell, native applications writing warnings to stderr trigger terminating errors if `$ErrorActionPreference = "Stop"` is combined with `2>&1`.
* **Resolution**: All VoltArena `.ps1` scripts configure:
  ```powershell
  $ErrorActionPreference = "Continue"
  $PSNativeCommandUseErrorActionPreference = $false
  ```

---

## 2. Web & Cloudflare Pages Issues

### Symptom: Cloudflare Pages upload fails with `Asset exceeds 25MB maximum`
* **Cause**: Unchunked `index.wasm` ($33.74$ MB) was uploaded directly.
* **Resolution**: Run `scripts/build-web.sh` (or `build-web.ps1`). This automatically splits `index.wasm` into `index.wasm.part00` ($18.0$ MB) and `index.wasm.part01` ($15.7$ MB), both strictly $\le 25$ MB.

### Symptom: Web game shows black screen or fails to load WASM
* **Cause**: Web server is not serving `application/wasm` MIME type or COOP/COEP headers.
* **Resolution**: Ensure `platform/web/_headers` is present in your deploy folder, or run the local preview via `scripts/bring-up.sh`.

### Symptom: No audio on Web
* **Cause**: Modern web browsers block audio playback until the user interacts with the canvas (Autoplay Policy).
* **Resolution**: Click anywhere inside the game canvas to resume the Web Audio context.

---

## 3. Headless Testing & Godot Gotchas

### Gotcha: `get_world_3d()` returns `null` in isolated tests
* **Cause**: Calling physics raycasts on a node that is not attached to an active `Viewport` or `SceneTree`.
* **Resolution**: Always guard physics calls defensively:
  ```gdscript
  var w3d = get_world_3d()
  if not w3d:
      return
  var space = w3d.direct_space_state
  ```

### Gotcha: Autoload singleton vs `class_name` conflicts
* **Cause**: In Godot 4.3, scripts registered as Autoload singletons in `project.godot` must NOT declare `class_name <SameName>`, as it causes duplicate symbol collisions in the global script cache.
* **Resolution**: Keep `class_name` on instanced entity classes, and omit `class_name` on autoloaded singletons.

### Gotcha: Screen-space unprojection behind camera
* **Cause**: `camera.unproject_position()` inverts coordinates if the 3D position is behind the camera plane.
* **Resolution**: Always verify `camera.is_position_behind(target_pos)`. If true, invert the screen direction vector before clamping to border margins.

### Gotcha: Kickoff state assertions in tests
* **Cause**: Checking `is_kickoff_pause` immediately following a goal event must be synchronous.
* **Resolution**: `reset_kickoff()` must be invoked synchronously inside `_on_goal_scored()` with `is_kickoff_pause = true` set immediately, while scene timers manage the visual countdown hold.

---

## 4. Strike Vector 3D Character, Rigging & Camera Gotchas

### Gotcha: Mixamo Hips Position Track Units vs Character Scale
* **Cause**: Mixamo animations (e.g. `Aim`, `Fire`, `Reload`) authored in meters $(0, 0.91, 0)$ collapse skeletal rigs into the ground when played on character models imported at $0.01$ scale.
* **Resolution**: `ModelCache` detects and normalizes position tracks in `_normalize_rig_tracks()` by converting keys from meters to centimeters: `Vector3(val.x * 100, -val.z * 100, val.y * 100)`.

### Gotcha: BoneAttachment3D Child Scale Inheritance
* **Cause**: Skeletons inside $0.01$-scaled root nodes propagate that scale down to `BoneAttachment3D`. Any weapon attached directly shrinks to microscopic size near the operative's feet.
* **Resolution**: Create an intermediate `WeaponGrip` (`Marker3D`) under `BoneAttachment3D` with scale `Vector3(100.0, 100.0, 100.0)` and rotation $Y=90.0^\circ$ to restore true human scale and align the barrel strictly with character forward $-Z$.

### Gotcha: Third-Person Crosshair Raycast Parallax
* **Cause**: In third-person shoulder view, projecting projectiles straight along the weapon barrel forward vector causes bullets to hit nearby railings or low cover instead of the crosshair target.
* **Resolution**: Raycast from camera center into the 3D world to determine the target impact point, then converge muzzle projectile velocity toward that target point.

### Gotcha: Hexagonal Grid Boundary Rendering
* **Cause**: Checking Euclidean distance only from hexagon vertices (`>= side - 4.0`) leaves flat edges unrendered.
* **Resolution**: Use exact distance to the hexagon edge plane: `24.25 - max(dx*0.866025, dx*0.433013 + dy*0.75)`.

### Gotcha: Subway Station Longitudinal Orientation
* **Cause**: Spawning player at Z=0 looking level into cross-beams hides the 45m corridor perspective.
* **Resolution**: Spawn player at `Z = 20.0` facing `-Z` (north) along the platform length to capture columns, tracks, 24m train, and incoming mutant spawns.

### Gotcha: Top-Level Camera Recoil Overwrite
* **Cause**: Physics loop overwriting `camera.rotation` directly resets spring recoil whenever `camera.top_level == true`.
* **Resolution**: Guard rotation resets with `if not camera.top_level:`.

### Gotcha: Cloudflare 25MB Limit with Full 3D Asset Package
* **Cause**: Exporting 49 production 3D models increases `index.pck` to 64.9MB, exceeding Cloudflare Pages' 25MB limit.
* **Resolution**: Split `index.pck` into 18MB chunks (`index.pck.part00` to `index.pck.part04`) and reassemble via client-side fetch streaming before WASM boot.

---

## 5. Drift Storm & Cross-Platform UI Gotchas

### Gotcha: Pre-Race Overlay Floating Over Active 3D Race World
* **Cause**: In `kart_racing_main.gd`, initializing the 3D track, player kart, AI racers, and in-race HUD immediately inside `_ready()` causes the pre-race configuration hub to render on top of an already running 3D world, leading to visual confusion and background processing.
* **Resolution**: Re-architect into an 11-stage scene state machine (`DriftHome` to `Finished`). In pre-race menu states, `_set_race_world_active(false)` disables and hides the track generator, player kart, and AI karts (`process_mode = PROCESS_MODE_DISABLED`, `visible = false`). The in-race HUD is hidden until countdown release.

### Gotcha: Action Buttons Clipped on Screen Heights $\le 800\text{px}$
* **Cause**: Using fixed-pixel offsets (`offset_bottom = 280`) on pre-race dialogs causes buttons to extend past the bottom edge of screens on standard laptops or mobile viewports $\le 800\text{px}$ in height.
* **Resolution**: Convert dialogs to responsive full-screen containers (`anchor_right = 1.0, anchor_bottom = 1.0`) with vertical scrolling for content cards and a fixed bottom navigation bar containing $\ge 48\text{dp}$ touch targets guaranteed within safe-area boundaries.

### Gotcha: Headless GDScript `class_name` Cache Staleness
* **Cause**: In Godot 4.3 headless mode, newly created `class_name` scripts are not immediately registered in `.godot/global_script_class_cache.cfg` unless an editor scan occurs.
* **Resolution**: Include explicit `const ... = preload(...)` references in consumer scripts and test harnesses to guarantee hermetic headless compilation without depending on cache scans.


