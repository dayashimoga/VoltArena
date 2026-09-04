# VoltArena Bring-Up (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BRING-UP LOCAL WEB SERVER       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/web/index.html")) {
    Write-Host "Web export not found. Running build-web.ps1..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
}

Write-Host "Cleaning up existing container..." -ForegroundColor Yellow
podman rm -f voltarena-web-server 2>$null | Out-Null

Write-Host "Starting voltarena-web-server on port 8080..." -ForegroundColor Yellow
podman run -d --name voltarena-web-server -p 8080:8080 -v "${PWD}/export/web:/web:ro,Z" -w /web docker.io/library/python:3.12-alpine python3 -m http.server 8080

Write-Host "VoltArena Web preview active at: http://localhost:8080" -ForegroundColor Green
