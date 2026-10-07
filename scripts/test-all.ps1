# VoltArena Run All Automated Tests (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: RUN ALL AUTOMATED TESTS         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Automated test suite failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "All automated tests passed successfully." -ForegroundColor Green
