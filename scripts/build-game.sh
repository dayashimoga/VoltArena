#!/usr/bin/env bash
# VoltArena Build Single Standalone Game (Bash)
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <game_name>"
    exit 1
fi

GAME_NAME="$1"

echo "=================================================="
echo "       VOLTARENA: BUILD STANDALONE GAME: $GAME_NAME"
echo "=================================================="

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py "$GAME_NAME"

echo "Standalone package for $GAME_NAME created in export/dist/standalone/."
