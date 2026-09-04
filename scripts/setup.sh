#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: CONTAINER ENVIRONMENT SETUP     "
echo "=================================================="

# Verify Podman installation
if ! command -v podman &> /dev/null; then
    echo "ERROR: Podman is not found in PATH."
    exit 1
fi

echo "[1/3] Pulling Godot CI container image..."
podman pull docker.io/barichello/godot-ci:4.3

echo "[2/3] Pulling Web Server preview container image..."
podman pull docker.io/library/python:3.12-alpine

echo "[3/3] Initializing Godot project cache inside container..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless --import --quit

echo "Setup completed successfully."
