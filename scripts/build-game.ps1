# VoltArena Build Single Standalone Game (PowerShell)
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$GameName,
    [Parameter(Mandatory=$false, Position=1)]
    [string]$Platform = "all"
)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD STANDALONE GAME: $GameName ($Platform)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py "$GameName" "$Platform"

Write-Host "Standalone package for $GameName created in export/dist/standalone/." -ForegroundColor Green

