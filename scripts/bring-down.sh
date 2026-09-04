#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: BRING-DOWN CONTAINERS           "
echo "=================================================="

echo "Stopping and removing voltarena-web-server..."
podman rm -f voltarena-web-server 2>/dev/null || true
echo "Containers successfully stopped."
