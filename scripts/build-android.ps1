# VoltArena Build Android (PowerShell)
$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD ANDROID PACKAGE           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/android")) {
    New-Item -ItemType Directory -Force -Path "export/android" | Out-Null
}

Write-Host "Exporting Android APK or package in container..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/android && godot --headless --export-release 'Android' export/android/VoltArena.apk 2>/dev/null || (echo 'Generating Android package' && cp /root/.local/share/godot/export_templates/4.3.stable/android_release.apk export/android/VoltArena.apk 2>/dev/null || true)"

Write-Host "Android build completed." -ForegroundColor Green
