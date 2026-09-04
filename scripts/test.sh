#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: RUN AUTOMATED TEST SUITE        "
echo "=================================================="

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd
