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
$hookScript = Get-Content -Raw -Encoding UTF8 "platform/web/reassembler_hook.html"

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
