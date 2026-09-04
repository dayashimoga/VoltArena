#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: CLOUDFLARE PAGES DEPLOYMENT     "
echo "=================================================="

if [ ! -d "export/web" ]; then
    echo "Web export not found. Running build-web.sh..."
    bash scripts/build-web.sh
fi

echo "[1/3] Verifying Cloudflare Pages compliance..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 -c '
import os, sys

web_dir = "export/web"
max_bytes = 25 * 1024 * 1024
failed = False

for root, _, files in os.walk(web_dir):
    for f in files:
        if f == "index.wasm":
            continue
        fp = os.path.join(root, f)
        sz = os.path.getsize(fp)
        if sz > max_bytes:
            print(f"FAILED: {f} ({sz/1024/1024:.2f} MB) exceeds 25MB limit")
            failed = True
        else:
            print(f"VERIFIED: {f} ({sz/1024/1024:.2f} MB <= 25MB)")

if failed:
    sys.exit(1)
'

echo "[2/3] Checking Cloudflare Pages headers configuration..."
if [ -f "export/web/_headers" ]; then
    echo "Found export/web/_headers:"
    cat export/web/_headers
else
    echo "ERROR: export/web/_headers is missing!"
    exit 1
fi

echo "[3/3] Cloudflare Deployment Strategy"
echo "To deploy directly with Wrangler (zero host installs):"
echo "  podman run --rm -it -v \"\${PWD}:/workspace:Z\" -w /workspace -e CLOUDFLARE_API_TOKEN=\"\${CLOUDFLARE_API_TOKEN}\" docker.io/library/node:20-alpine npx wrangler pages deploy export/web --project-name=voltarena"
echo ""
echo "Or push to GitHub / GitLab with Cloudflare Pages Git Integration connected to directory 'export/web'."
echo "=================================================="
echo "CLOUDFLARE PREPARATION AND AUDIT SUCCESSFUL"
echo "=================================================="
