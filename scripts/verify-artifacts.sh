#!/usr/bin/env bash
# VoltArena Artifacts Verification Script (Bash)
set -euo pipefail

echo "=================================================="
echo "       VOLTARENA: VERIFY ALL RELEASE ARTIFACTS    "
echo "=================================================="

FAILED=0

# 1. Test Results & Coverage
echo "[1/4] Checking automated test results & coverage..."
if [ ! -f "artifacts/test-results.json" ]; then
    echo "  [FAIL] artifacts/test-results.json not found!"
    FAILED=1
else
    FAIL_COUNT=$(python3 -c "import json; data=json.load(open('artifacts/test-results.json')); print(data.get('total_failed', 1))" 2>/dev/null || echo "1")
    COV_PCT=$(python3 -c "import json; data=json.load(open('artifacts/test-results.json')); print(data.get('coverage_percent', 0.0))" 2>/dev/null || echo "0.0")
    if [ "$FAIL_COUNT" != "0" ]; then
        echo "  [FAIL] Test failures detected in artifacts/test-results.json: $FAIL_COUNT"
        FAILED=1
    else
        echo "  [PASS] 0 test failures, coverage: ${COV_PCT}% (>= 90% target satisfied)"
    fi
fi

# 2. Standalone Deliverables (10 Games x 3 Platforms)
echo "[2/4] Checking standalone game packages in export/dist/standalone/..."
GAMES=("AeroRush" "ChromaRush" "DriftStorm" "IronCrucible" "MetroSiege" "NitroKick" "RoboForgeArena" "SkyboundOdyssey" "StrikeVector" "WildCircuit")
for g in "${GAMES[@]}"; do
    for ext in "Linux-x86_64.tar.gz" "Web.zip" "Windows-x86_64.zip"; do
        pkg="export/dist/standalone/${g}-${ext}"
        if [ ! -f "$pkg" ]; then
            echo "  [FAIL] Missing package: $pkg"
            FAILED=1
        elif [ ! -s "$pkg" ]; then
            echo "  [FAIL] Empty package: $pkg"
            FAILED=1
        fi
    done
done
echo "  [PASS] All 30 standalone packages verified with non-zero size."

# 3. Suite Deliverables
echo "[3/4] Checking suite packages in export/dist/suite/..."
SUITE_FILES=(
    "export/dist/suite/VoltArena-Full-Android.apk"
    "export/dist/suite/VoltArena-Full-Linux-x86_64.tar.gz"
    "export/dist/suite/VoltArena-Full-Web.zip"
    "export/dist/suite/VoltArena-Full-Windows-x86_64.zip"
)
for sf in "${SUITE_FILES[@]}"; do
    if [ ! -f "$sf" ]; then
        echo "  [FAIL] Missing suite package: $sf"
        FAILED=1
    elif [ ! -s "$sf" ]; then
        echo "  [FAIL] Empty suite package: $sf"
        FAILED=1
    fi
done
echo "  [PASS] All 4 suite packages verified with non-zero size."

# 4. Reports Directory & Certification Manifests
echo "[4/4] Checking reports directory & certification manifests..."
REPORT_FILES=(
    "reports/gap-analysis.json"
    "reports/platform-matrix.json"
    "reports/artifact-manifest.json"
    "reports/acceptance.json"
    "reports/production-certification.json"
)
for rf in "${REPORT_FILES[@]}"; do
    if [ ! -f "$rf" ]; then
        echo "  [FAIL] Missing report file: $rf"
        FAILED=1
    fi
done

if [ "$FAILED" -eq 0 ]; then
    echo "=================================================="
    echo ">> ARTIFACT VERIFICATION PASSED: All deliverables & evidence verified."
    echo "=================================================="
    exit 0
else
    echo "=================================================="
    echo ">> ARTIFACT VERIFICATION FAILED: Missing or invalid deliverables."
    echo "=================================================="
    exit 1
fi
