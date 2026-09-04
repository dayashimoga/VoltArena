# VoltArena Build Desktop (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD DESKTOP EXPORTS           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/linux")) { New-Item -ItemType Directory -Force -Path "export/linux" | Out-Null }
if (-not (Test-Path "export/windows")) { New-Item -ItemType Directory -Force -Path "export/windows" | Out-Null }

Write-Host "[1/2] Exporting Linux x86_64 binary..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/linux && godot --headless --export-release 'Linux' export/linux/VoltArena.x86_64"

Write-Host "[2/2] Exporting Windows x86_64 executable..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/windows && godot --headless --export-release 'Windows' export/windows/VoltArena.exe"

Write-Host "Desktop builds successfully created in export/linux and export/windows." -ForegroundColor Green
