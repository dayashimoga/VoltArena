# VoltArena Teardown (PowerShell)
$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: TEARDOWN CONTAINERS & RUNTIMES  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "Stopping and removing VoltArena preview & background containers..." -ForegroundColor Yellow
podman rm -f voltarena-web-server 2>$null
podman rm -f voltarena-dev-runner 2>$null

Write-Host "Pruning temporary runtime containers..." -ForegroundColor Yellow
podman container prune -f 2>$null

Write-Host "Teardown completed successfully." -ForegroundColor Green
