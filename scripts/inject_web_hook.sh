#!/usr/bin/env bash
set -e

HTML_FILE="${1:-export/web/index.html}"
HOOK_FILE="${2:-platform/web/reassembler_hook.html}"

if [ ! -f "$HTML_FILE" ]; then
  echo "Error: HTML file '$HTML_FILE' not found."
  exit 1
fi

if grep -q "VoltArena Cloudflare Chunk Reassembler Hook" "$HTML_FILE"; then
  echo "Reassembler hook already injected into $HTML_FILE."
  exit 0
fi

if [ ! -f "$HOOK_FILE" ]; then
  echo "Error: Hook fragment '$HOOK_FILE' not found."
  exit 1
fi

echo "Injecting chunk reassembler hook from $HOOK_FILE into $HTML_FILE..."

awk -v hook_file="$HOOK_FILE" '
  /<script src="index.js"><\/script>/ {
    while ((getline hook_line < hook_file) > 0) {
      print hook_line
    }
    close(hook_file)
  }
  { print }
' "$HTML_FILE" > "${HTML_FILE}.tmp" && mv "${HTML_FILE}.tmp" "$HTML_FILE"

if grep -q "VoltArena Cloudflare Chunk Reassembler Hook" "$HTML_FILE"; then
  echo "PASS: Successfully injected reassembler hook into $HTML_FILE."
else
  echo "FAIL: Reassembler hook could not be verified in $HTML_FILE."
  exit 1
fi
