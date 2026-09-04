# VoltArena Platform Acceptance Tests (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: PLATFORM ACCEPTANCE TESTS       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Platform acceptance tests failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "Acceptance tests validated successfully." -ForegroundColor Green
