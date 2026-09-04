# VoltArena — Multi-Platform Build & Release Guide

## 1. Overview
VoltArena supports multi-platform compilation targeting Web, Linux x86_64, Windows x86_64, and Android ARM64 without requiring local toolchains. All compilation is executed via the `barichello/godot-ci:4.3` container image.

---

## 2. Compiling Platform Releases

### 2.1 Web Build (Cloudflare Pages Compatible)
Exports the single-threaded GL Compatibility WebAssembly package, creates $\le 18$MB chunks, and configures headers:
```bash
# Bash
bash scripts/build-web.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
```
Output directory: `export/web/`
* `index.html` (Custom shell with transparent stream reassembler)
* `index.js` (Emscripten JavaScript glue)
* `index.pck` (Compiled game resources)
* `index.wasm.part00` (WASM Chunk 1, 18.0 MB)
* `index.wasm.part01` (WASM Chunk 2, 15.7 MB)
* `_headers` (Cloudflare caching & security headers)

### 2.2 Desktop Builds (Linux & Windows)
Exports standalone embedded binaries:
```bash
# Bash
bash scripts/build-desktop.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1
```
Output files:
* `export/linux/VoltArena.x86_64` (Executable Linux binary with embedded PCK)
* `export/windows/VoltArena.exe` (Executable Windows 64-bit binary with embedded PCK)

### 2.3 Android Build
Generates Android release package:
```bash
# Bash
bash scripts/build-android.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/build-android.ps1
```
Output file: `export/android/VoltArena.apk`

---

## 3. Unified Multi-Platform Compilation
To compile all platforms in a single automated pass:
```bash
# Bash
bash scripts/build.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
```

---

## 4. Release Packaging (`export/dist/`)
To package production distributions into compressed archives:
```bash
# Bash
bash scripts/package.sh

# PowerShell
powershell -ExecutionPolicy Bypass -File scripts/package.ps1
```
The packaging pipeline generates:
* `export/dist/VoltArena-Web.zip` ($\sim 15.6$ MB, zip archive ready for manual upload)
* `export/dist/VoltArena-Linux-x86_64.tar.gz` (gzipped tarball with executable permissions preserved)
* `export/dist/VoltArena-Windows-x86_64.zip` (zip archive containing `VoltArena.exe`)
* `export/dist/VoltArena-Android.apk` (Android package)

---

## 5. Build Verification Checklist
* [x] Every file in `export/web/` is strictly $\le 25.0$ MB.
* [x] `_headers` file exists with `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`.
* [x] Linux and Windows binaries have embedded `.pck` enabled for single-file portability.
* [x] Release archives in `export/dist/` are valid and extract cleanly.
