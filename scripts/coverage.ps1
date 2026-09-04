$ErrorActionPreference = "Continue"
$PSNativeCommandUseErrorActionPreference = $false

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: CODE COVERAGE AUDIT             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$output = podman run --rm -v "${PWD}:/workspace:Z" -w /workspace docker.io/barichello/godot-ci:4.3 godot --headless -s res://tests/runner.gd 2>&1
$output | Out-Host

$covLine = $output | Where-Object { $_ -match "Code Coverage Metric:\s+([\d\.]+)%" } | Select-Object -First 1
if ($covLine -match "([\d\.]+)%") {
    $val = [double]$Matches[1]
    Write-Host "Detected Coverage: $val%" -ForegroundColor Yellow
    if ($val -ge 90.0) {
        Write-Host "COVERAGE GATE PASSED: $val% >= 90.0%" -ForegroundColor Green
        exit 0
    } else {
        Write-Error "Coverage $val% is below 90% threshold."
        exit 1
    }
} else {
    Write-Error "Failed to parse Code Coverage Metric from test runner output."
    exit 1
}
