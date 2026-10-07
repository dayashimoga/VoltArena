#!/usr/bin/env bash
# VoltArena Build Full Suite (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: BUILD FULL SUITE                "
echo "=================================================="

bash scripts/build-desktop.sh
bash scripts/build-web.sh

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py suite

echo "Full suite build created in export/dist/suite/."
