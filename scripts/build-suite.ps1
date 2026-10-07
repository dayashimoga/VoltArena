# VoltArena Build Full Suite (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD FULL SUITE                " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1
powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py suite

Write-Host "Full suite build created in export/dist/suite/." -ForegroundColor Green
