#!/usr/bin/env bash
# VoltArena Build All Standalone Games (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: BUILD STANDALONE GAMES          "
echo "=================================================="

bash scripts/build-desktop.sh
bash scripts/build-web.sh

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py standalone

echo "All standalone game packages created in export/dist/standalone/."
