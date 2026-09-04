#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: RELEASE PACKAGING               "
echo "=================================================="

mkdir -p export/dist
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 scripts/packager.py
