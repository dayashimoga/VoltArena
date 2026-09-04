#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: UNIFIED MULTI-PLATFORM BUILD    "
echo "=================================================="

bash scripts/build-web.sh
bash scripts/build-desktop.sh
bash scripts/build-android.sh

echo "=================================================="
echo "ALL PLATFORM EXPORTS BUILT SUCCESSFULLY           "
echo "=================================================="
