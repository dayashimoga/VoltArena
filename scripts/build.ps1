# VoltArena Unified Multi-Platform Build (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: UNIFIED MULTI-PLATFORM BUILD    " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
powershell -ExecutionPolicy Bypass -File scripts/build-desktop.ps1
powershell -ExecutionPolicy Bypass -File scripts/build-android.ps1

Write-Host "==================================================" -ForegroundColor Green
Write-Host "ALL PLATFORM EXPORTS BUILT SUCCESSFULLY           " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
