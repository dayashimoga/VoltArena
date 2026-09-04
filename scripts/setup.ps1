# VoltArena Environment Setup (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: CONTAINER ENVIRONMENT SETUP     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Error "Podman is not installed or not available in PATH."
    exit 1
}

Write-Host "[1/3] Pulling Godot CI container image..." -ForegroundColor Yellow
podman pull docker.io/barichello/godot-ci:4.3

Write-Host "[2/3] Pulling Web Server preview container image..." -ForegroundColor Yellow
podman pull docker.io/library/python:3.12-alpine

Write-Host "[3/3] Initializing Godot project cache inside container..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless --import --quit

Write-Host "Setup completed successfully." -ForegroundColor Green
