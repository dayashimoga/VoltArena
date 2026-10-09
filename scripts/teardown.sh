#!/usr/bin/env bash
# VoltArena Teardown (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: TEARDOWN CONTAINERS & RUNTIMES  "
echo "=================================================="

echo "Stopping and removing VoltArena preview & background containers..."
podman rm -f voltarena-web-server 2>/dev/null || true
podman rm -f voltarena-dev-runner 2>/dev/null || true

echo "Pruning temporary runtime containers..."
podman container prune -f 2>/dev/null || true

echo "Teardown completed successfully."
