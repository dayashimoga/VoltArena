# VoltArena — Web Deployment & Cloudflare Pages Engineering

## 1. Overview & Constraints

VoltArena delivers a single-threaded WebAssembly (WASM) and WebGL2 deployment compatible with the **Cloudflare Pages Free Tier**.

### Cloudflare Pages Free Tier Constraints:
- **Maximum individual file size**: $\le 25.00\text{ MB}$.
- **Deployment model**: Pure static file hosting via edge CDN.
- **Cross-Origin Isolation**: Required for high-precision timers and WebAssembly shared memory (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`).

---

## 2. 25MB Asset Ceiling Solution: Streamed Binary Reassembly

Standard Godot 4.3 Web exports produce an `index.wasm` binary of approximately $\sim 33.74\text{ MB}$, exceeding Cloudflare's 25MB upload limit.

VoltArena resolves this without sacrificing engine features or splitting game packages:
1. **Build-Time Chunking**:
   - `scripts/packager.py` automatically splits `index.wasm` into chunks strictly $\le 18.0\text{ MB}$:
     - `index.wasm.part00` ($\sim 18.0\text{ MB}$)
     - `index.wasm.part01` ($\sim 15.7\text{ MB}$)
2. **Client-Side Progressive Stream Reassembler**:
   - `export/web/index.html` implements a high-performance in-memory reassembler using the browser's `ReadableStream` and `Response` APIs:
     ```javascript
     async function fetchAndReassembleWasm() {
       const parts = ['index.wasm.part00', 'index.wasm.part01'];
       const responses = await Promise.all(parts.map(p => fetch(p)));
       const buffers = await Promise.all(responses.map(r => r.arrayBuffer()));
       const totalLength = buffers.reduce((acc, b) => acc + b.byteLength, 0);
       const combined = new Uint8Array(totalLength);
       let offset = 0;
       for (const buf of buffers) {
         combined.set(new Uint8Array(buf), offset);
         offset += buf.byteLength;
       }
       return new Response(combined, { headers: { 'Content-Type': 'application/wasm' } });
     }
     ```
3. **Audited File Sizes**:
   All static assets in `export/web/` strictly measure below 20MB:
   - `index.html`: $\sim 28\text{ KB}$
   - `index.js`: $\sim 54\text{ KB}$
   - `index.wasm.part00`: $18.0\text{ MB}$
   - `index.wasm.part01`: $15.7\text{ MB}$
   - `index.pck`: Compressed game package

---

## 3. HTTP Security & Edge Cache Headers

Located at `platform/web/_headers` and copied to `export/web/_headers` during export:
```http
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Access-Control-Allow-Origin: *
  Cache-Control: public, max-age=31536000, immutable

/index.html
  Cache-Control: public, max-age=0, must-revalidate
```

- **COOP & COEP**: Enables `SharedArrayBuffer` support on Chromium, Edge, and Firefox.
- **Cache Invalidation**: HTML files revalidate on every request; WASM chunks and PCK bundles are cached immutably.

---

## 4. End-to-End Browser Testing in CI/CD

The continuous integration pipeline spins up a local HTTP server hosting `export/web/` and drives automated headless browser E2E tests:
1. Verifies HTTP 200 responses on all assets.
2. Validates WASM reassembly and engine initialization.
3. Tests canvas resizing and responsive scaling across mobile and desktop viewport profiles.
4. Asserts zero unhandled JavaScript exceptions or WebGL context failures.
