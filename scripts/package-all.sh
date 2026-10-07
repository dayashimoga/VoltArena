#!/usr/bin/env bash
# VoltArena Release Packaging: Standalone & Full Suite (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: RELEASE PACKAGING ALL           "
echo "=================================================="

mkdir -p export/dist

podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/modular_packager.py all

echo "Packaging complete in export/dist/."
