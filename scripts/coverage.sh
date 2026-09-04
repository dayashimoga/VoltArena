#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: CODE COVERAGE AUDIT             "
echo "=================================================="

OUTPUT=$(podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd 2>&1)
echo "$OUTPUT"

COVERAGE=$(echo "$OUTPUT" | grep "Code Coverage Metric:" | awk '{print $4}' | tr -d '%')
if [ -z "$COVERAGE" ]; then
    echo "ERROR: Could not parse Code Coverage Metric from test runner output."
    exit 1
fi

echo "Parsed Coverage: ${COVERAGE}%"
# Compare with 90.0
COMPARE=$(python3 -c "print(1 if float('$COVERAGE') >= 90.0 else 0)" 2>/dev/null || podman run --rm docker.io/library/python:3.12-alpine python3 -c "print(1 if float('$COVERAGE') >= 90.0 else 0)")

if [ "$COMPARE" -eq 1 ]; then
    echo "COVERAGE GATE PASSED: ${COVERAGE}% >= 90.0%"
    exit 0
else
    echo "ERROR: Coverage ${COVERAGE}% is below 90% requirement."
    exit 1
fi
