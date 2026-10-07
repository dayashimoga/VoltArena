# VoltArena Release Packaging: Standalone & Full Suite (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: RELEASE PACKAGING ALL           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/dist")) {
    New-Item -ItemType Directory -Force -Path "export/dist" | Out-Null
}

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py all

Write-Host "Packaging complete in export/dist/." -ForegroundColor Green
