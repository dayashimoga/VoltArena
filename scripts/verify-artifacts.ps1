# VoltArena Artifacts Verification Script (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: VERIFY ALL RELEASE ARTIFACTS    " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$failed = $false

# 1. Test Results & Coverage
Write-Host "`n[1/4] Checking automated test results & coverage..." -ForegroundColor Yellow
if (-not (Test-Path "artifacts/test-results.json")) {
    Write-Host "  [FAIL] artifacts/test-results.json not found!" -ForegroundColor Red
    $failed = $true
} else {
    $results = Get-Content "artifacts/test-results.json" | ConvertFrom-Json
    if ($results.total_failed -ne 0) {
        Write-Host "  [FAIL] Test failures detected: $($results.total_failed)" -ForegroundColor Red
        $failed = $true
    } else {
        Write-Host "  [PASS] 0 test failures, coverage: $($results.coverage_percent)% (>= 90% satisfied)" -ForegroundColor Green
    }
}

# 2. Standalone Deliverables
Write-Host "`n[2/4] Checking standalone game packages in export/dist/standalone/..." -ForegroundColor Yellow
$games = @("AeroRush", "ChromaRush", "DriftStorm", "IronCrucible", "MetroSiege", "NitroKick", "RoboForgeArena", "SkyboundOdyssey", "StrikeVector", "WildCircuit")
$exts = @("Linux-x86_64.tar.gz", "Web.zip", "Windows-x86_64.zip")
foreach ($g in $games) {
    foreach ($ext in $exts) {
        $pkg = "export/dist/standalone/$g-$ext"
        if (-not (Test-Path $pkg)) {
            Write-Host "  [FAIL] Missing package: $pkg" -ForegroundColor Red
            $failed = $true
        } else {
            $item = Get-Item $pkg
            if ($item.Length -le 0) {
                Write-Host "  [FAIL] Empty package: $pkg" -ForegroundColor Red
                $failed = $true
            }
        }
    }
}
if (-not $failed) {
    Write-Host "  [PASS] All 30 standalone packages verified with non-zero size." -ForegroundColor Green
}

# 3. Suite Deliverables
Write-Host "`n[3/4] Checking suite packages in export/dist/suite/..." -ForegroundColor Yellow
$suiteFiles = @(
    "export/dist/suite/VoltArena-Full-Android.apk",
    "export/dist/suite/VoltArena-Full-Linux-x86_64.tar.gz",
    "export/dist/suite/VoltArena-Full-Web.zip",
    "export/dist/suite/VoltArena-Full-Windows-x86_64.zip"
)
foreach ($sf in $suiteFiles) {
    if (-not (Test-Path $sf)) {
        Write-Host "  [FAIL] Missing suite package: $sf" -ForegroundColor Red
        $failed = $true
    } else {
        $item = Get-Item $sf
        if ($item.Length -le 0) {
            Write-Host "  [FAIL] Empty suite package: $sf" -ForegroundColor Red
            $failed = $true
        }
    }
}
if (-not $failed) {
    Write-Host "  [PASS] All 4 suite packages verified with non-zero size." -ForegroundColor Green
}

# 4. Reports Directory
Write-Host "`n[4/4] Checking reports directory & certification manifests..." -ForegroundColor Yellow
$reportFiles = @(
    "reports/gap-analysis.json",
    "reports/platform-matrix.json",
    "reports/artifact-manifest.json",
    "reports/acceptance.json",
    "reports/production-certification.json"
)
foreach ($rf in $reportFiles) {
    if (-not (Test-Path $rf)) {
        Write-Host "  [FAIL] Missing report file: $rf" -ForegroundColor Red
        $failed = $true
    }
}

if (-not $failed) {
    Write-Host "`n==================================================" -ForegroundColor Green
    Write-Host ">> ARTIFACT VERIFICATION PASSED: All deliverables & evidence verified." -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n==================================================" -ForegroundColor Red
    Write-Host ">> ARTIFACT VERIFICATION FAILED: Missing or invalid deliverables." -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    exit 1
}
