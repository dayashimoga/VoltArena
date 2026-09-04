#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: CLEAN WORKSPACE                 "
echo "=================================================="

rm -rf export/web export/linux export/windows export/android export/dist
echo "Cleaned export/ directories."

rm -f tests/test_output.log
echo "Cleaned test logs."

echo "Workspace clean completed."
