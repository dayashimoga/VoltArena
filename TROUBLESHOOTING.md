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
