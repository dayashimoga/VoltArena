# VoltArena Run Local Web (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: RUN LOCAL WEB SERVER            " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/web/index.html")) {
    Write-Host "Building web package..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
}

Write-Host "Serving VoltArena Web on http://localhost:8080 (Press Ctrl+C to stop)..." -ForegroundColor Green
podman run --rm -it -p 8080:8080 -v "${PWD}/export/web:/web:ro,Z" -w /web docker.io/library/python:3.12-alpine python3 -m http.server 8080
