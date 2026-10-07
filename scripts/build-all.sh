#!/usr/bin/env bash
# VoltArena Build All: Standalone Games + Full Suite (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: BUILD ALL MULTI-PLATFORM        "
echo "=================================================="

bash scripts/build-desktop.sh
bash scripts/build-web.sh
bash scripts/package-all.sh

echo "=================================================="
echo "ALL STANDALONE GAMES AND SUITE BUILDS COMPLETED   "
echo "=================================================="
