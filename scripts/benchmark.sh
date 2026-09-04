#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: PERFORMANCE BENCHMARK           "
echo "=================================================="

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/benchmark/test_benchmark.gd
