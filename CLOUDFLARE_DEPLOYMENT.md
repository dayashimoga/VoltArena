# VoltArena — Cloudflare Pages Deployment & Limit Optimization

## 1. Cloudflare Pages Free Tier Constraints

Cloudflare Pages provides global CDN edge hosting with strict free-tier specifications:
* **Asset Size Limit**: **Maximum 25.0 MB (26,214,400 bytes) per individual uploaded file**.
* **Bandwidth & Requests**: Unlimited free tier bandwidth.
* **Header Support**: Configurable via `_headers` file in the root deploy directory.

---

## 2. The Godot 4 WebAssembly Size Challenge

By default, Godot 4.3's Web export template produces an uncompressed `index.wasm` of approximately **33.74 MB (35,376,909 bytes)**. Attempting to deploy `index.wasm` directly to Cloudflare Pages triggers an immediate upload rejection error (`Asset exceeds 25MB maximum`).

---

## 3. The VoltArena Solution: Automated Chunking & Parallel Stream Reassembly

VoltArena resolves this constraint cleanly with an automated chunking and client-side reassembly protocol:

### 3.1 Build-Time Binary Splitting
During `scripts/build-web.sh` (or `build-web.ps1`), the 33.74MB WebAssembly file is split into chunks of maximum 18MB using `split -b 18M -d`:
* `index.wasm.part00` $\to$ **18.00 MB** ($18,874,368$ bytes $\le 25$MB)
* `index.wasm.part01` $\to$ **15.74 MB** ($16,502,541$ bytes $\le 25$MB)

Both files are well within Cloudflare's 25MB ceiling.

### 3.2 Client-Side Transparent Fetch Hook
In `export/web/index.html`, a lightweight stream interception hook intercepts any browser requests for `index.wasm`:

```javascript
(function() {
    const origFetch = window.fetch;
    window.fetch = async function(resource, init) {
        const url = typeof resource === "string" ? resource : (resource?.url || "");
        if (url.endsWith("index.wasm")) {
            // Local dev fallback: try fetching directly first
            try {
                const res = await origFetch(resource, init);
                if (res.ok) return res;
            } catch (e) {}

            // Cloudflare Pages: fetch parts in parallel
            const [r1, r2] = await Promise.all([
                origFetch("index.wasm.part00"),
                origFetch("index.wasm.part01")
            ]);
            const [b1, b2] = await Promise.all([r1.arrayBuffer(), r2.arrayBuffer()]);

            // Stitch into single contiguous WebAssembly buffer
            const combined = new Uint8Array(b1.byteLength + b2.byteLength);
            combined.set(new Uint8Array(b1), 0);
            combined.set(new Uint8Array(b2), b1.byteLength);

            return new Response(combined, {
                status: 200,
                headers: { "Content-Type": "application/wasm" }
            });
        }
        return origFetch(resource, init);
    };
})();
```

**Key Advantages**:
1. **Parallel Download**: Fetching two 17MB chunks simultaneously saturates HTTP/2 or HTTP/3 multiplexed connections, often loading faster than a single sequential file download!
2. **Zero Modification to Godot Engine**: The Godot loader and Emscripten runtime receive a completely standard `Response` object with `application/wasm` MIME type and identical SHA256 integrity.

---

## 4. Cloudflare Pages HTTP Headers (`_headers`)

The file `platform/web/_headers` is automatically copied into `export/web/_headers`:

```http
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  X-Frame-Options: SAMEORIGIN
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin

/*.html
  Cache-Control: no-cache, must-revalidate

/*.wasm
  Content-Type: application/wasm
  Cache-Control: public, max-age=31536000, immutable

/*.pck
  Content-Type: application/octet-stream
  Cache-Control: public, max-age=31536000, immutable

/*.js
  Cache-Control: public, max-age=31536000, immutable
```

* **Security Isolation**: `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` unlock high-resolution browser performance timers and WebAssembly thread primitives.
* **Immutable Caching**: High-bandwidth WASM and PCK assets are cached on Cloudflare's worldwide edge CDN for 1 year (`max-age=31536000, immutable`).

---

## 5. Deployment Methods

### Method A: Direct CLI Deployment via Containerized Wrangler (Zero Host Installs)
Set your Cloudflare API token and run Wrangler inside `node:20-alpine`:

```bash
podman run --rm -it \
  -v "${PWD}:/workspace:Z" \
  -w /workspace \
  -e CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN}" \
  docker.io/library/node:20-alpine \
  npx wrangler pages deploy export/web --project-name=voltarena
```

### Method B: Cloudflare Pages Git Integration
1. Push this repository to GitHub or GitLab.
2. In the Cloudflare Dashboard, go to **Workers & Pages** $\to$ **Create application** $\to$ **Pages** $\to$ **Connect to Git**.
3. Configure build settings:
   * **Framework preset**: None
   * **Build command**: `bash scripts/build-web.sh` (or upload pre-built export)
   * **Build output directory**: `export/web`
4. Click **Save and Deploy**.
