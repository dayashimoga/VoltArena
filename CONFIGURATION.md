# VoltArena — Configuration & Tuning Reference

## 1. Engine Configuration (`project.godot`)

The root engine settings are defined in `project.godot`:
* **Application Title**: `VoltArena`
* **Main Scene**: `res://launcher/launcher.tscn`
* **Renderer**: `gl_compatibility` (WebGL2 / OpenGL ES 3.0 compatible)
* **Window Dimensions**: $1280 \times 720$ (Base Design Resolution)
* **Window Stretch Mode**: `canvas_items` (Aspect: `expand`)
* **Physics Tick Rate**: 60 Hz (`physics/common/physics_ticks_per_second=60`)

---

## 2. Graphics Quality Presets (`QualityManager`)

VoltArena includes 4 dynamic graphics presets managed by `shared/graphics/quality_manager.gd`:

| Setting | Low | Medium | High | Ultra |
| :--- | :---: | :---: | :---: | :---: |
| **Viewport Scale** | $0.75\times$ | $1.0\times$ | $1.0\times$ | $1.0\times$ |
| **MSAA 3D** | Disabled | $2\times$ | $4\times$ | $8\times$ |
| **Shadow Resolution** | 512 | 1024 | 2048 | 4096 |
| **SSAO** | Disabled | Low | Medium | High |
| **Glow / Bloom** | Disabled | Enabled | Enabled | Enabled |
| **Target FPS** | 30 / 60 | 60 | 60 | 120+ |

Presets can be changed in real-time through the UI or programmatically:
```gdscript
QualityManager.set_quality_preset(QualityManager.QualityPreset.HIGH)
```

---

## 3. Audio Configuration (`AudioManager`)

Volume levels are controlled across 3 independent audio buses:
* **Master**: Overall application sound envelope ($0.0 - 1.0$).
* **Music**: Background electronic synth themes ($0.0 - 1.0$).
* **SFX**: Weapons, engines, explosions, and impact chimes ($0.0 - 1.0$).

The procedural synthesizer parameters can be tuned in `shared/audio/audio_manager.gd`:
* **Laser Duration**: $0.15\text{s}$ (Frequency sweep: $1200\text{Hz} \to 200\text{Hz}$).
* **Explosion Decay**: $0.45\text{s}$ (Exponential low-pass filtered noise).
* **Engine Modulation**: Sawtooth wave dynamically pitched between $60\text{Hz}$ (idle) and $480\text{Hz}$ (max throttle).

---

## 4. Input & Control Configuration (`InputManager`)

Input actions are registered dynamically and mapped to multiple hardware devices:

| Action Name | Default Keyboard / Mouse | Gamepad Mapping |
| :--- | :--- | :--- |
| `move_forward` | `W` / `Up Arrow` | Left Stick Up |
| `move_backward` | `S` / `Down Arrow` | Left Stick Down |
| `move_left` | `A` / `Left Arrow` | Left Stick Left |
| `move_right` | `D` / `Right Arrow` | Left Stick Right |
| `jump` | `Space` | Cross / `A` Button |
| `sprint` | `Shift` | Left Stick Click |
| `crouch` | `C` / `Ctrl` | Right Stick Click / `B` Button |
| `fire` | Left Mouse Button | Right Trigger (R2 / RT) |
| `aim_secondary` | Right Mouse Button | Left Trigger (L2 / LT) |
| `reload` | `R` | Square / `X` Button |
| `boost` | `Shift` / Right Mouse Button | Circle / `B` Button / R1 |
| `drift` | `Space` / Left Mouse Button | Left Shoulder (L1 / LB) |
| `pause` | `Escape` | Start / Menu Button |

---

## 5. Persistence & Save Format (`SaveManager`)

All user progress, career statistics, and high scores are saved locally:
* **Save Path**: `user://savegame.json`
* **Settings Path**: `user://settings.cfg`
* On Web (Cloudflare Pages), Godot automatically maps `user://` to the browser's persistent `IndexedDB` storage via Emscripten `IDBFS`, ensuring progress persists across browser restarts!
