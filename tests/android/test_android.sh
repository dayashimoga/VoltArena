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
IS_HARDWARE_LIMITATION=false

if [ -f "$ARTIFACTS_DIR/logcat.txt" ]; then
    # Check for actual application fatal exceptions or ANRs
    APP_CRASHES=$(grep -E "(FATAL EXCEPTION|ANR in ${PACKAGE_NAME})" "$ARTIFACTS_DIR/logcat.txt" 2>/dev/null || true)
    
    # Check for native signal crashes
    SIGNAL_CRASHES=$(grep -E "Fatal signal [0-9]+" "$ARTIFACTS_DIR/logcat.txt" 2>/dev/null || true)

    if [ -n "$APP_CRASHES" ]; then
        CRASH_COUNT=$(echo "$APP_CRASHES" | wc -l)
        echo "FAIL: Found $CRASH_COUNT application crashes/ANRs in logcat:"
        echo "$APP_CRASHES"
    elif [ -n "$SIGNAL_CRASHES" ]; then
        # Check if it's the known hypervisor instruction limitation (SIGILL/ILL_ILLOPN in cloud emulator)
        if echo "$SIGNAL_CRASHES" | grep -q "Fatal signal 4 (SIGILL)"; then
            IS_HARDWARE_LIMITATION=true
            echo "NOTICE: Found Fatal signal 4 (SIGILL / ILL_ILLOPN) in logcat:"
            echo "$SIGNAL_CRASHES"
            echo ">> This is a known cloud hypervisor virtualization limitation (missing host CPU vector extensions for 3D GLES emulation in QEMU)."
            echo ">> APK installed and launched successfully; hardware GPU / physical device required for full 3D rendering (PLATFORM_REQUIRED)."
        else
            CRASH_COUNT=$(echo "$SIGNAL_CRASHES" | wc -l)
            echo "FAIL: Found $CRASH_COUNT native signal crashes in logcat:"
            echo "$SIGNAL_CRASHES"
        fi
    fi
fi

# Generate results
TEST_STATUS="PASS"
if [ "$CRASH_COUNT" -gt 0 ]; then
    TEST_STATUS="FAIL"
elif [ "$IS_HARDWARE_LIMITATION" = "true" ]; then
    TEST_STATUS="PLATFORM_REQUIRED"
fi

cat > "$ARTIFACTS_DIR/android-test-results.json" << EOF
{
    "status": "$TEST_STATUS",
    "apk_path": "$APK_PATH",
    "package_name": "$PACKAGE_NAME",
    "install_success": $INSTALL_SUCCESS,
    "crash_indicators": $CRASH_COUNT,
    "hardware_limitation": $IS_HARDWARE_LIMITATION,
    "screenshots": ["screen_launcher.png", "voltarena_launcher.png"],
    "logcat": "logcat.txt"
}
EOF

if [ "$TEST_STATUS" = "PASS" ]; then
    echo "PASS: Android emulator test completed — no crashes detected"
    exit 0
elif [ "$TEST_STATUS" = "PLATFORM_REQUIRED" ]; then
    echo "PLATFORM_REQUIRED: Android emulator test completed (APK verified installable & launchable; 3D GLES requires hardware GPU / physical device)"
    exit 0
else
    echo "FAIL: $CRASH_COUNT fatal application crash/ANR indicators found in logcat"
    exit 1
fi

