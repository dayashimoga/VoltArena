# VoltArena Bring-Down (PowerShell)
$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BRING-DOWN CONTAINERS           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

podman rm -f voltarena-web-server 2>$null | Out-Null
Write-Host "Containers stopped and cleaned up." -ForegroundColor Green
