#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: RUN LOCAL WEB SERVER            "
echo "=================================================="

if [ ! -d "export/web" ]; then
    echo "Exporting web bundle first..."
    bash scripts/build-web.sh
fi

echo "Serving VoltArena Web on http://localhost:8080 (Press Ctrl+C to stop)..."
podman run --rm -it -p 8080:8080 -v "${PWD}/export/web:/web:ro,Z" -w /web docker.io/library/python:3.12-alpine python3 -m http.server 8080
