# VoltArena Clean Workspace (PowerShell)
$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       VOLTARENA: CLEAN WORKSPACE                 " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Remove-Item -Recurse -Force "export/web" 2>$null | Out-Null
Remove-Item -Recurse -Force "export/linux" 2>$null | Out-Null
Remove-Item -Recurse -Force "export/windows" 2>$null | Out-Null
Remove-Item -Recurse -Force "export/android" 2>$null | Out-Null
Remove-Item -Recurse -Force "export/dist" 2>$null | Out-Null
Remove-Item -Force "tests/test_output.log" 2>$null | Out-Null

Write-Host "Cleaned export/ and log directories." -ForegroundColor Green
