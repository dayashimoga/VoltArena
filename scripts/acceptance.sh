#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: PLATFORM ACCEPTANCE TESTS       "
echo "=================================================="

# Run test runner which includes full acceptance suite
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
echo "Acceptance tests validated successfully."
