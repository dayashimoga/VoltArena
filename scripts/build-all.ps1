# VoltArena Build All: Standalone Games + Full Suite (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD ALL MULTI-PLATFORM        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Build Desktop and Web Binaries
powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1
powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1

# 2. Package Modular Standalone and Suite Distributions
powershell -ExecutionPolicy Bypass -File scripts/package-all.ps1

Write-Host "==================================================" -ForegroundColor Green
Write-Host "ALL STANDALONE GAMES AND SUITE BUILDS COMPLETED   " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
