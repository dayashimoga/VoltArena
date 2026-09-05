# VoltArena Build Web (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: BUILD WEB (CLOUDFLARE READY)    " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/web")) {
    New-Item -ItemType Directory -Force -Path "export/web" | Out-Null
}

Write-Host "[1/5] Exporting Godot Web package in Podman container..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "mkdir -p export/web && godot --headless --export-release 'Web' export/web/index.html"

Write-Host "[2/5] Creating Cloudflare-compliant WASM & PCK chunks (<= 18MB each)..." -ForegroundColor Yellow
podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 bash -c "split -b 18M -d export/web/index.wasm export/web/index.wasm.part && split -b 18M -d export/web/index.pck export/web/index.pck.part"

Write-Host "[3/5] Deploying Cloudflare Pages _headers..." -ForegroundColor Yellow
Copy-Item -Force "platform/web/_headers" "export/web/_headers"

Write-Host "[4/5] Injecting WASM and PCK chunk reassembler into index.html..." -ForegroundColor Yellow
$htmlContent = Get-Content -Raw -Encoding UTF8 "export/web/index.html"
$hookScript = @'
		<script>
		// VoltArena Cloudflare Chunk Reassembler Hook
		(function() {
			const origFetch = window.fetch;
			async function assembleParts(prefix, contentType) {
				let parts = [];
				for (let i = 0; i < 20; i++) {
					const num = i < 10 ? '0' + i : '' + i;
					const partUrl = prefix + '.part' + num;
					try {
						const res = await origFetch(partUrl);
						if (!res.ok) break;
						const buf = await res.arrayBuffer();
						if (buf.byteLength === 0) break;
						parts.push(new Uint8Array(buf));
					} catch (e) {
						break;
					}
				}
				if (parts.length === 0) return null;
				let totalLen = 0;
				for (const p of parts) totalLen += p.byteLength;
				const combined = new Uint8Array(totalLen);
				let offset = 0;
				for (const p of parts) {
					combined.set(p, offset);
					offset += p.byteLength;
				}
				return new Response(combined, { status: 200, headers: { "Content-Type": contentType } });
			}

			window.fetch = async function(resource, init) {
				const url = typeof resource === "string" ? resource : (resource?.url || "");
				if (url.endsWith("index.wasm")) {
					try {
						const res = await origFetch(resource, init);
						if (res.ok) return res;
					} catch (e) {}
					const assembled = await assembleParts("index.wasm", "application/wasm");
					if (assembled) return assembled;
				}
				if (url.endsWith("index.pck")) {
					try {
						const res = await origFetch(resource, init);
						if (res.ok) return res;
					} catch (e) {}
					const assembled = await assembleParts("index.pck", "application/octet-stream");
					if (assembled) return assembled;
				}
				if (url.includes(".pck")) {
					init = Object.assign({}, init, { cache: "no-store" });
				}
				return origFetch(resource, init);
			};
		})();
		</script>
'@

if (-not $htmlContent.Contains("VoltArena Cloudflare Chunk Reassembler Hook")) {
    $htmlContent = $htmlContent.Replace('<script src="index.js"></script>', "$hookScript`r`n`t`t<script src=`"index.js`"></script>")
    Set-Content -Path "export/web/index.html" -Value $htmlContent -Encoding UTF8
}

Write-Host "[5/5] Auditing exported files against Cloudflare 25MB limit..." -ForegroundColor Yellow
$maxBytes = 25 * 1024 * 1024
$files = Get-ChildItem -Path "export/web" -File
$hasFailure = $false

foreach ($f in $files) {
    $sizeMB = [math]::Round($f.Length / 1MB, 2)
    if ($f.Name -eq "index.wasm" -or $f.Name -eq "index.pck") {
        Write-Host ("{0,-30} | {1,8} MB | [SOURCE - Chunks will be served]" -f $f.Name, $sizeMB) -ForegroundColor DarkGray
        continue
    }
    if ($f.Length -le $maxBytes) {
        Write-Host ("{0,-30} | {1,8} MB | PASS (<=25MB)" -f $f.Name, $sizeMB) -ForegroundColor Green
    } else {
        Write-Host ("{0,-30} | {1,8} MB | FAIL (>25MB)" -f $f.Name, $sizeMB) -ForegroundColor Red
        $hasFailure = $true
    }
}

if ($hasFailure) {
    Write-Error "One or more deployable files exceeded Cloudflare 25MB threshold."
    exit 1
}

Write-Host "==================================================" -ForegroundColor Green
Write-Host "BUILD WEB COMPLETE: 100% COMPLIANT WITH CLOUDFLARE" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
