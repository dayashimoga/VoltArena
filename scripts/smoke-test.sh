#!/usr/bin/env bash
# VoltArena Headless Smoke Test (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: HEADLESS SMOKE TEST             "
echo "=================================================="

SCENES=(
    "res://launcher/launcher.tscn"
    "res://games/aero-rush/aero_rush_main.tscn"
    "res://games/aircraft-flight/aircraft_flight_main.tscn"
    "res://games/arena-fps/arena_fps_main.tscn"
    "res://games/chroma-rush/chroma_rush_main.tscn"
    "res://games/flight-simulator-6dof/flight_sim_standalone.tscn"
    "res://games/kart-racing/kart_racing_main.tscn"
    "res://games/roboforge-arena/roboforge_main.tscn"
    "res://games/rocket-car/rocket_car_main.tscn"
    "res://games/skybound-odyssey/skybound_main.tscn"
    "res://games/strike-vector/strike_vector_main.tscn"
    "res://games/subway-survival/subway_main.tscn"
    "res://games/urban-legends/urban_legends_main.tscn"
    "res://games/wildcircuit/wildcircuit_main.tscn"
)

echo "[1/2] Headless Scene Smoke Tests (14 Scenes: 13 Games + Launcher)..."
for sc in "${SCENES[@]}"; do
    echo "  Testing scene: $sc..."
    podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless "$sc" --quit-after 20
done

echo "[2/2] Acceptance Test Gate Verification..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd -- --filter=acceptance

echo "=================================================="
echo ">> SMOKE TEST PASSED: All 14 scenes boot cleanly & acceptance gates valid."
echo "=================================================="
