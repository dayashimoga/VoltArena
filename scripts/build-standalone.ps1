# VoltArena Build All Standalone Games (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD STANDALONE GAMES          " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1
powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py standalone

Write-Host "All standalone game packages created in export/dist/standalone/." -ForegroundColor Green
