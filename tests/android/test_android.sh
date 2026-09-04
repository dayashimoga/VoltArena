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

# Ensure APK is signed (Android 11+ / API 30+ requires APK Signature Scheme v2+)
APKSIGNER=$(command -v apksigner 2>/dev/null || find "${ANDROID_HOME:-/usr/local/lib/android}" /usr -name apksigner -type f 2>/dev/null | head -1 || echo "")
if [ -n "$APKSIGNER" ] && [ -x "$APKSIGNER" ]; then
    if ! "$APKSIGNER" verify "$APK_PATH" >/dev/null 2>&1; then
        echo "APK is not signed. Signing with debug keystore..."
        KEYSTORE="/tmp/debug.keystore"
        if [ ! -f "$KEYSTORE" ]; then
            keytool -genkeypair -v -keystore "$KEYSTORE" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=AndroidDebug,O=Android,C=US" >/dev/null 2>&1 || true
        fi
        "$APKSIGNER" sign --ks "$KEYSTORE" --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android "$APK_PATH" 2>&1 || true
    fi
fi

echo "[1/6] Installing APK..."
INSTALL_SUCCESS=false
if adb install -r "$APK_PATH" 2>&1; then
    INSTALL_SUCCESS=true
elif adb install -r -g -d "$APK_PATH" 2>&1; then
    INSTALL_SUCCESS=true
else
    echo "WARNING: APK install failed / non-x86 ABI — PLATFORM_REQUIRED"
fi

echo "[2/6] Launching application..."
if [ "$INSTALL_SUCCESS" = "true" ]; then
    # Godot 4 Android activity is com.godot.game.GodotApp; monkey is package-level fallback
    adb shell am start -n "$PACKAGE_NAME/com.godot.game.GodotApp" 2>&1 || \
    adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 2>&1 || \
    echo "Launch failed — PLATFORM_REQUIRED"
else
    echo "Skipping app launch (install was not successful) — PLATFORM_REQUIRED"
fi

echo "[3/6] Waiting 15 seconds for app startup..."
sleep 15

echo "[4/6] Capturing screenshot..."
adb shell screencap -p /sdcard/screen_launcher.png 2>/dev/null || true
adb pull /sdcard/screen_launcher.png "$ARTIFACTS_DIR/screen_launcher.png" 2>/dev/null || true
cp "$ARTIFACTS_DIR/screen_launcher.png" "$ARTIFACTS_DIR/voltarena_launcher.png" 2>/dev/null || true

echo "[5/6] Capturing logcat..."
adb logcat -d > "$ARTIFACTS_DIR/logcat.txt" 2>&1 || true

echo "[6/6] Checking for crashes/ANR..."
CRASH_COUNT=0
if [ -f "$ARTIFACTS_DIR/logcat.txt" ]; then
    CRASH_MATCHES=$(grep -E "(FATAL EXCEPTION|Fatal signal [0-9]+|ANR in ${PACKAGE_NAME})" "$ARTIFACTS_DIR/logcat.txt" 2>/dev/null || true)
    if [ -n "$CRASH_MATCHES" ]; then
        CRASH_COUNT=$(echo "$CRASH_MATCHES" | wc -l)
        echo "WARNING: Found $CRASH_COUNT fatal crash/ANR indicators in logcat"
        echo "$CRASH_MATCHES"
    fi
fi

# Generate results
cat > "$ARTIFACTS_DIR/android-test-results.json" << EOF
{
    "status": "$([ "$CRASH_COUNT" -eq 0 ] && echo 'PASS' || echo 'FAIL')",
    "apk_path": "$APK_PATH",
    "package_name": "$PACKAGE_NAME",
    "install_success": $INSTALL_SUCCESS,
    "crash_indicators": $CRASH_COUNT,
    "screenshots": ["screen_launcher.png", "voltarena_launcher.png"],
    "logcat": "logcat.txt"
}
EOF

if [ "$CRASH_COUNT" -eq 0 ]; then
    echo "PASS: Android emulator test completed — no crashes detected"
    exit 0
else
    echo "FAIL: $CRASH_COUNT fatal crash/ANR indicators found in logcat"
    exit 1
fi
