# VoltArena Performance Benchmark (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: PERFORMANCE BENCHMARK           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/benchmark/test_benchmark.gd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Performance benchmarks failed with code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "Performance benchmarks completed successfully." -ForegroundColor Green
