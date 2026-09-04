#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: BUILD DESKTOP EXPORTS           "
echo "=================================================="

mkdir -p export/linux export/windows

echo "[1/2] Exporting Linux x86_64 binary..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/linux && godot --headless --export-release 'Linux' export/linux/VoltArena.x86_64"

echo "[2/2] Exporting Windows x86_64 executable..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/windows && godot --headless --export-release 'Windows' export/windows/VoltArena.exe"

echo "Desktop builds successfully created in export/linux and export/windows."
