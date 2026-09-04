# VoltArena — Developer & Container Setup Guide

## 1. Zero Host Installation Philosophy
VoltArena is engineered to ensure **zero host machine pollution**. You do not need to install:
* Godot Engine
* Android SDK / NDK / JDK
* Web build tools / Emscripten
* Compilers or native build tools

All operations run hermetically inside official OCI container images managed by **Podman**.

---

## 2. Prerequisites
The only prerequisite on the host system is **Podman**:
* **Windows**: Podman Desktop or Podman CLI via WSL2 (Podman 4.x or 5.x).
* **Linux**: Podman via system package manager (`apt install podman` or `dnf install podman`).
* **macOS**: Podman via Homebrew (`brew install podman`).

---

## 3. Automated Initial Setup

Run the automated setup script to pull the required container images and initialize the project cache:

### Using Bash (Linux / macOS / WSL2):
```bash
bash scripts/setup.sh
```

### Using PowerShell (Windows):
```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

### What Setup Does:
1. Validates `podman` availability in system `PATH`.
2. Pulls `docker.io/barichello/godot-ci:4.3` (~1.7 GB uncompressed, contains complete Godot 4.3 headless engine and all export templates).
3. Pulls `docker.io/library/python:3.12-alpine` (~50 MB, used for packager, certifier, and web preview).
4. Executes `godot --headless --import --quit` inside the container to generate `.godot/global_script_class_cache.cfg` and import metadata.

---

## 4. Container Volume Mounting (`:Z` Flag)
When running Podman commands on SELinux systems or rootless WSL2, the volume mount flag `:Z` is applied automatically in all scripts:
```bash
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace barichello/godot-ci:4.3 <command>
```
The `:Z` flag configures the container engine to relabel the directory volume for private unshared container access, preventing permission denied errors.

---

## 5. Verifying Your Setup
Run the automated test runner to ensure the environment is 100% operational:
```bash
bash scripts/test.sh
# Or PowerShell:
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```
Expected output:
```
==================================================
TEST RESULTS SUMMARY:
  Total Assertions Passed: 63
  Total Assertions Failed: 0
  Code Coverage Metric:    94.4% (Required: >90%)
==================================================
ALL TEST GATES PASSED [100% SUCCESS]
```
