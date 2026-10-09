# VoltArena Headless Smoke Test (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: HEADLESS SMOKE TEST             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$scenes = @(
    "res://launcher/launcher.tscn",
    "res://games/aero-rush/aero_rush_main.tscn",
    "res://games/chroma-rush/chroma_rush_main.tscn",
    "res://games/kart-racing/kart_racing_main.tscn",
    "res://games/strike-vector/strike_vector_main.tscn",
    "res://games/roboforge-arena/roboforge_main.tscn",
    "res://games/wildcircuit/wildcircuit_main.tscn",
    "res://games/skybound-odyssey/skybound_main.tscn",
    "res://games/rocket-car/rocket_car_main.tscn",
    "res://games/subway-survival/subway_main.tscn",
    "res://games/arena-fps/arena_fps_main.tscn"
)

Write-Host "`n[1/2] Headless Scene Smoke Tests (11 Scenes)..." -ForegroundColor Yellow
foreach ($sc in $scenes) {
    Write-Host "  Testing scene: $sc..." -ForegroundColor DarkCyan
    podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless "$sc" --quit-after 20
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Smoke test failed for scene: $sc"
    }
}

Write-Host "`n[2/2] Acceptance Test Gate Verification..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd -- --filter=acceptance
if ($LASTEXITCODE -ne 0) {
    Write-Error "Acceptance smoke tests failed!"
}

Write-Host "`n>> SMOKE TEST PASSED: All 11 scenes boot cleanly & acceptance gates valid." -ForegroundColor Green
