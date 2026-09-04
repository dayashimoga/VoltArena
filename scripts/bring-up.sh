#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: BRING-UP LOCAL WEB SERVER       "
echo "=================================================="

# Ensure export/web exists
if [ ! -d "export/web" ]; then
    echo "Web export not found. Running build-web..."
    bash scripts/build-web.sh
fi

echo "Stopping any existing container named 'voltarena-web-server'..."
podman rm -f voltarena-web-server 2>/dev/null || true

echo "Starting container 'voltarena-web-server' on port 8080..."
podman run -d --name voltarena-web-server -p 8080:8080 -v "${PWD}/export/web:/usr/share/nginx/html:ro,Z" -v "${PWD}/platform/web/nginx.conf:/etc/nginx/conf.d/default.conf:ro,Z" docker.io/library/nginx:alpine 2>/dev/null || \
podman run -d --name voltarena-web-server -p 8080:8080 -v "${PWD}/export/web:/web:ro,Z" -w /web docker.io/library/python:3.12-alpine python3 -m http.server 8080

echo "VoltArena Web is now running at: http://localhost:8080"
