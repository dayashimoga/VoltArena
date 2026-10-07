#!/usr/bin/env bash
# VoltArena Run All Automated Tests (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: RUN ALL AUTOMATED TESTS         "
echo "=================================================="

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
echo "All automated tests passed successfully."
