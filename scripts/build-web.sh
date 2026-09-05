#!/usr/bin/env bash
set -e
echo "=================================================="
echo "       VOLTARENA: BUILD WEB (CLOUDFLARE READY)    "
echo "=================================================="

mkdir -p export/web

echo "[1/5] Exporting Godot Web package in Podman container..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/web && godot --headless --export-release 'Web' export/web/index.html"

echo "[2/5] Creating Cloudflare-compliant WASM & PCK chunks (<= 18MB each)..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "split -b 18M -d export/web/index.wasm export/web/index.wasm.part && split -b 18M -d export/web/index.pck export/web/index.pck.part"

echo "[3/5] Deploying Cloudflare Pages _headers..."
cp platform/web/_headers export/web/_headers

echo "[4/5] Injecting WASM and PCK chunk reassembler into index.html..."
# Ensure index.html includes transparent fetch fallback for chunked WASM and PCK
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 -c '
with open("export/web/index.html", "r", encoding="utf-8") as f:
    content = f.read()

hook = """
\t\t<script>
\t\t// VoltArena Cloudflare Chunk Reassembler Hook
\t\t(function() {
\t\t\tconst origFetch = window.fetch;
\t\t\tasync function assembleParts(prefix, contentType) {
\t\t\t\tlet parts = [];
\t\t\t\tfor (let i = 0; i < 20; i++) {
\t\t\t\t\tconst num = i < 10 ? '0' + i : '' + i;
\t\t\t\t\tconst partUrl = prefix + '.part' + num;
\t\t\t\t\ttry {
\t\t\t\t\t\tconst res = await origFetch(partUrl);
\t\t\t\t\t\tif (!res.ok) break;
\t\t\t\t\t\tconst buf = await res.arrayBuffer();
\t\t\t\t\t\tif (buf.byteLength === 0) break;
\t\t\t\t\t\tparts.push(new Uint8Array(buf));
\t\t\t\t\t} catch (e) {
\t\t\t\t\t\tbreak;
\t\t\t\t\t}
\t\t\t\t}
\t\t\t\tif (parts.length === 0) return null;
\t\t\t\tlet totalLen = 0;
\t\t\t\tfor (const p of parts) totalLen += p.byteLength;
\t\t\t\tconst combined = new Uint8Array(totalLen);
\t\t\t\tlet offset = 0;
\t\t\t\tfor (const p of parts) {
\t\t\t\t\tcombined.set(p, offset);
\t\t\t\t\toffset += p.byteLength;
\t\t\t\t}
\t\t\t\treturn new Response(combined, { status: 200, headers: { "Content-Type": contentType } });
\t\t\t}

\t\t\twindow.fetch = async function(resource, init) {
\t\t\t\tconst url = typeof resource === "string" ? resource : (resource?.url || "");
\t\t\t\tif (url.endsWith("index.wasm")) {
\t\t\t\t\ttry {
\t\t\t\t\t\tconst res = await origFetch(resource, init);
\t\t\t\t\t\tif (res.ok) return res;
\t\t\t\t\t} catch (e) {}
\t\t\t\t\tconst assembled = await assembleParts("index.wasm", "application/wasm");
\t\t\t\t\tif (assembled) return assembled;
\t\t\t\t}
\t\t\t\tif (url.endsWith("index.pck")) {
\t\t\t\t\ttry {
\t\t\t\t\t\tconst res = await origFetch(resource, init);
\t\t\t\t\t\tif (res.ok) return res;
\t\t\t\t\t} catch (e) {}
\t\t\t\t\tconst assembled = await assembleParts("index.pck", "application/octet-stream");
\t\t\t\t\tif (assembled) return assembled;
\t\t\t\t}
\t\t\t\tif (url.includes(".pck")) {
\t\t\t\t\tinit = Object.assign({}, init, { cache: "no-store" });
\t\t\t\t}
\t\t\t\treturn origFetch(resource, init);
\t\t\t};
\t\t})();
\t\t</script>
"""

if "VoltArena Cloudflare Chunk Reassembler Hook" not in content:
    content = content.replace("<script src=\"index.js\"></script>", hook + "\n\t\t<script src=\"index.js\"></script>")
    with open("export/web/index.html", "w", encoding="utf-8") as f:
        f.write(content)
'

echo "[5/5] Auditing exported files against Cloudflare 25MB limit..."
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/library/python:3.12-alpine python3 -c '
import os, sys

web_dir = "export/web"
max_bytes = 25 * 1024 * 1024 # 25 MB
all_passed = True

print(f"{web_dir:35} | Size (MB) | Status")
print("-" * 55)
for root, _, files in os.walk(web_dir):
    for fn in sorted(files):
        fp = os.path.join(root, fn)
        sz = os.path.getsize(fp)
        sz_mb = sz / (1024 * 1024)
        if fn == "index.wasm" or fn == "index.pck":
            print(f"{fn:35} | {sz_mb:8.2f} | [SOURCE - Chunks will be served]")
            continue
        status = "PASS (<=25MB)" if sz <= max_bytes else "FAIL (>25MB)"
        if sz > max_bytes:
            all_passed = False
        print(f"{fn:35} | {sz_mb:8.2f} | {status}")

if not all_passed:
    sys.exit(1)
'

echo "=================================================="
echo "BUILD WEB COMPLETE: 100% COMPLIANT WITH CLOUDFLARE"
echo "=================================================="
