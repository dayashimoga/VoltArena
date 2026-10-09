# VoltArena & AeroRush Build & Packaging Guide

## 1. Architecture & Zero-Host Toolchain Philosophy
VoltArena and all its individual games (including the newly overhauled **AeroRush: Impossible Circuit**) follow a strict **zero-host-pollution** build methodology. No local installations of the Godot Engine, Emscripten, Android SDK, or native compilers are required.

All builds, packaging, and certifications are executed deterministically inside containerized OCI images using **Podman** (or Docker):
- **Engine & Exports:** `docker.io/barichello/godot-ci:4.3` (Headless Godot 4.3 + all official export templates).
- **Tooling & Certifier:** Python 3.11/3.12 (Pillow, Playwright, NumPy).

---

## 2. Standalone vs. Suite Distribution Architecture

```text
                        GODOT MONOREPO
                              |
                  +-----------+-----------+
                  |                       |
             SHARED CORE              GAME MODULES
          UI/Input/Save/Audio      AeroRush/ChromaRush/...
                  |                       |
                  +-----------+-----------+
                              |
                        BUILD MATRIX
                              |
                  +-----------+-----------+
                  |                       |
             VOLTARENA SUITE        STANDALONE GAMES
                  |                       |
                  +-----------+-----------+
                              |
                Windows / Linux / macOS
                  Android / iOS / Web
                              |
                     RELEASE ARTIFACTS
```

### Standalone Games
Each game in the VoltArena suite can be built and distributed as a standalone binary or PCK package.
For AeroRush:
- **Preset:** `Windows-AeroRush`
- **Output:** `export/standalone/AeroRush.pck`
- **Main Scene:** `res://games/aero-rush/aero_rush_main.tscn`
- Launches directly into AeroRush with dedicated menus, garage, course select, telemetry HUD, and career progression without requiring the VoltArena suite launcher.

---

## 3. Build & Export Commands

### A. Standalone PCK Export
To export the isolated standalone PCK package for AeroRush:

```bash
# PowerShell / Bash:
python scripts/export_standalone_pcks.py aero-rush
```

To export all 10 games as isolated standalone packages:
```bash
python scripts/export_standalone_pcks.py all
```

Output directory: `export/standalone/`
- `AeroRush.pck` (~103 MB)
- `ChromaRush.pck`
- `DriftStorm.pck`
- `StrikeVector.pck`
- `RoboForgeArena.pck`
- `WildCircuit.pck`
- `SkyboundOdyssey.pck`
- `NitroKick.pck`
- `MetroSiege.pck`
- `IronCrucible.pck`

### B. Web Build (Cloudflare Pages Ready)
To build the complete web distribution with WebAssembly, WebGL 2.0, chunking (<18 MB per file for Cloudflare limit), and reassembly hooks:

```powershell
# Windows PowerShell:
powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
```

```bash
# Linux / macOS / WSL:
bash scripts/build-web.sh
```

Output directory: `export/web/`
- `index.html` (Reassembler hook injected)
- `index.js` (Emscripten WebGL loader)
- `index.wasm.part00`, `index.wasm.part01` (Chunked WebAssembly)
- `index.pck.part00` - `part05` (Chunked package assets)
- `_headers` (COOP/COEP headers for SharedArrayBuffer)

### C. Desktop Export (Windows / Linux / macOS)
```powershell
# Windows PowerShell:
powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1
```

```bash
# Linux / macOS / WSL:
bash scripts/build-desktop.sh
```

---

## 4. Empirical Testing & Production Certification

### A. Comprehensive 80-Suite Headless Test Runner
Runs all 80 unit, integration, and E2E suites inside the container:
```bash
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
```
- Passing requirement: 100% assertions passed (3,051/3,051), 0 failures.
- Minimum code coverage: >= 90.0% (current: 90.6%).

### B. Playwright Runtime Empirical Visual Capture
Serves `export/web` and drives headless Chromium through real gameplay scenarios:
```bash
python scripts/capture_aero_rush_evidence.py
```
Outputs 14 HD screenshots to `artifacts/screenshots/aero_*.png`.

### C. Production Release Certifier
Audits test results, visual luminance/contrast/black-percentage, package sizes, and generates formal compliance artifacts:
```bash
python scripts/certifier.py
```
Generated release gates:
- `artifacts/production-certification.json`
- `artifacts/production-certification.html`
- `artifacts/acceptance.json`
- `artifacts/acceptance.html`
- `artifacts/visual-audit.json`
- `artifacts/screenshots/visual_contact_sheet.png`
- `artifacts/screenshots/contact_sheet_aero_rush.png`
- `artifacts/screenshots/contact_sheet.html`
