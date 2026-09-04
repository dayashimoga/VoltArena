#!/bin/bash
set -euo pipefail

# VoltArena Android Emulator Test Script
# Requires: Android SDK, ADB, emulator already running or AVD configured

echo "=================================================="
echo "   VOLTARENA ANDROID EMULATOR TEST                "
echo "=================================================="

APK_PATH="${1:-export/android/VoltArena.apk}"
ARTIFACTS_DIR="${2:-artifacts}"
PACKAGE_NAME="org.voltarena.gamesuite"

mkdir -p "$ARTIFACTS_DIR"

# Check APK exists
if [ ! -f "$APK_PATH" ]; then
    echo "FAIL: APK not found at $APK_PATH"
    echo '{"status": "FAIL", "reason": "APK not found"}' > "$ARTIFACTS_DIR/android-test-results.json"
    exit 1
fi

echo "[1/6] Installing APK..."
adb install -r "$APK_PATH" 2>&1 || { echo "FAIL: APK install failed"; exit 1; }

echo "[2/6] Launching application..."
adb shell am start -n "$PACKAGE_NAME/.GodotApp" 2>&1 || { echo "FAIL: App launch failed"; exit 1; }

echo "[3/6] Waiting 15 seconds for app startup..."
sleep 15

echo "[4/6] Capturing screenshot..."
adb shell screencap -p /sdcard/voltarena_launcher.png
adb pull /sdcard/voltarena_launcher.png "$ARTIFACTS_DIR/" 2>/dev/null || true

echo "[5/6] Capturing logcat..."
adb logcat -d > "$ARTIFACTS_DIR/logcat.txt" 2>&1 || true

echo "[6/6] Checking for crashes/ANR..."
CRASH_COUNT=0
if grep -qi "FATAL\|ANR\|CRASH\|NullPointerException\|SIGSEGV" "$ARTIFACTS_DIR/logcat.txt" 2>/dev/null; then
    CRASH_COUNT=$(grep -ci "FATAL\|ANR\|CRASH\|NullPointerException\|SIGSEGV" "$ARTIFACTS_DIR/logcat.txt" 2>/dev/null || echo "0")
    echo "WARNING: Found $CRASH_COUNT crash/error indicators in logcat"
fi

# Generate results
cat > "$ARTIFACTS_DIR/android-test-results.json" << EOF
{
    "status": "$([ "$CRASH_COUNT" -eq 0 ] && echo 'PASS' || echo 'FAIL')",
    "apk_path": "$APK_PATH",
    "package_name": "$PACKAGE_NAME",
    "crash_indicators": $CRASH_COUNT,
    "screenshots": ["voltarena_launcher.png"],
    "logcat": "logcat.txt"
}
EOF

if [ "$CRASH_COUNT" -eq 0 ]; then
    echo "PASS: Android emulator test completed — no crashes detected"
    exit 0
else
    echo "FAIL: $CRASH_COUNT crash/error indicators found in logcat"
    exit 1
fi
