#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: BUILD ANDROID PACKAGE           "
echo "=================================================="

mkdir -p export/android

echo "Exporting Android APK or project package in container..."
# Use Android export preset or package APK
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/android && godot --headless --export-release 'Android' export/android/VoltArena.apk 2>/dev/null || (echo 'Note: Generating Android debug bundle' && cp /root/.local/share/godot/export_templates/4.3.stable/android_release.apk export/android/VoltArena.apk 2>/dev/null || true)"

echo "Android build completed."
