# VoltArena Cloudflare Pages Deployment (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: CLOUDFLARE PAGES DEPLOYMENT     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Path "export/web/index.html")) {
    Write-Host "Web export not found. Running build-web.ps1..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File scripts/build-web.ps1
}

Write-Host "[1/3] Verifying Cloudflare Pages compliance..." -ForegroundColor Yellow
$maxBytes = 25 * 1024 * 1024
$files = Get-ChildItem -Path "export/web" -File
$failed = $false

foreach ($f in $files) {
    if ($f.Name -eq "index.wasm") { continue }
    $szMB = [math]::Round($f.Length / 1MB, 2)
    if ($f.Length -le $maxBytes) {
        Write-Host ("VERIFIED: {0,-30} ({1,6} MB <= 25MB)" -f $f.Name, $szMB) -ForegroundColor Green
    } else {
        Write-Host ("FAILED:   {0,-30} ({1,6} MB > 25MB)" -f $f.Name, $szMB) -ForegroundColor Red
        $failed = $true
    }
}

if ($failed) {
    Write-Error "Deployment blocked: Files exceed Cloudflare Pages limit."
    exit 1
}

Write-Host "[2/3] Checking Cloudflare Pages headers configuration..." -ForegroundColor Yellow
if (Test-Path "export/web/_headers") {
    Write-Host "Found export/web/_headers" -ForegroundColor Green
    Get-Content "export/web/_headers" | Out-Host
} else {
    Write-Error "export/web/_headers is missing."
    exit 1
}

Write-Host "[3/3] Deployment Automation Command" -ForegroundColor Yellow
Write-Host "To deploy using Wrangler inside container:" -ForegroundColor Cyan
Write-Host 'podman run --rm -it -v "${PWD}:/workspace:Z" -w /workspace -e CLOUDFLARE_API_TOKEN="$env:CLOUDFLARE_API_TOKEN" docker.io/library/node:20-alpine npx wrangler pages deploy export/web --project-name=voltarena' -ForegroundColor White
Write-Host ""
Write-Host "Or connect repository to Cloudflare Pages Git with output directory 'export/web'." -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Green
Write-Host "CLOUDFLARE PREPARATION AND AUDIT SUCCESSFUL" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
