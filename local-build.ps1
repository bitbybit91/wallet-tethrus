#Requires -Version 5.1
<#
.SYNOPSIS
    Tethrus Wallet local build script for Windows (PowerShell).
    Optimized for low-memory systems (4GB RAM, dual-core CPU).
.DESCRIPTION
    Builds the Tethrus wallet application with memory-constrained settings.
    Provides build variant selection, memory monitoring, and elapsed time reporting.
#>

param(
    [ValidateSet('prodnetDebug','prodnetRelease','btctestnetDebug','btctestnetRelease','huaweiProdnetDebug','huaweiProdnetRelease')]
    [string]$Variant
)

$ErrorActionPreference = 'Stop'

$env:GRADLE_OPTS = '-Xmx512m -Dfile.encoding=UTF-8'
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17'

function Get-MemoryInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
    $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
    $usedMB = $totalMB - $freeMB
    $pctUsed = [math]::Round(($usedMB / $totalMB) * 100, 1)
    return @{
        TotalMB  = $totalMB
        FreeMB   = $freeMB
        UsedMB   = $usedMB
        PctUsed  = $pctUsed
    }
}

Write-Host '============================================' -ForegroundColor Cyan
Write-Host ' Tethrus Wallet - Local Build Script (PS)' -ForegroundColor Cyan
Write-Host ' Optimized for low-memory systems' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "JAVA_HOME:    $env:JAVA_HOME"
Write-Host "GRADLE_OPTS:  $env:GRADLE_OPTS"
Write-Host ''

try {
    $mem = Get-MemoryInfo
    Write-Host "Memory: $($mem.FreeMB) MB free / $($mem.TotalMB) MB total ($($mem.PctUsed)% used)" -ForegroundColor Yellow
} catch {
    Write-Host 'Unable to query memory info.' -ForegroundColor Yellow
}
Write-Host ''

$variantMap = @{
    '1' = @{ Task = 'mbw:assembleProdnetDebug';          Name = 'prodnetDebug' }
    '2' = @{ Task = 'mbw:assembleProdnetRelease';        Name = 'prodnetRelease' }
    '3' = @{ Task = 'mbw:assembleBtctestnetDebug';       Name = 'btctestnetDebug' }
    '4' = @{ Task = 'mbw:assembleBtctestnetRelease';     Name = 'btctestnetRelease' }
    '5' = @{ Task = 'mbw:assembleHuaweiProdnetDebug';    Name = 'huaweiProdnetDebug' }
    '6' = @{ Task = 'mbw:assembleHuaweiProdnetRelease';  Name = 'huaweiProdnetRelease' }
}

if ($Variant) {
    $selected = $variantMap.Values | Where-Object { $_.Name -eq $Variant } | Select-Object -First 1
} else {
    Write-Host 'Select build variant:'
    Write-Host '  1) prodnetDebug'
    Write-Host '  2) prodnetRelease'
    Write-Host '  3) btctestnetDebug'
    Write-Host '  4) btctestnetRelease'
    Write-Host '  5) huaweiProdnetDebug'
    Write-Host '  6) huaweiProdnetRelease'
    Write-Host ''
    $choice = Read-Host 'Enter choice (1-6)'
    $selected = $variantMap[$choice]
}

if (-not $selected) {
    Write-Host 'Invalid selection. Exiting.' -ForegroundColor Red
    exit 1
}

$task = $selected.Task
$name = $selected.Name

Write-Host ''
Write-Host "Building $name ..." -ForegroundColor Green
Write-Host "Command: .\gradlew.bat --no-daemon --max-workers=2 clean $task"
Write-Host ''

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

& .\gradlew.bat --no-daemon --max-workers=2 clean $task
$exitCode = $LASTEXITCODE

$stopwatch.Stop()
$elapsed = $stopwatch.Elapsed

Write-Host ''
if ($exitCode -eq 0) {
    Write-Host '============================================' -ForegroundColor Green
    Write-Host " Build succeeded: $name" -ForegroundColor Green
    Write-Host " Elapsed time: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Host '============================================' -ForegroundColor Green
} else {
    Write-Host '============================================' -ForegroundColor Red
    Write-Host " Build FAILED: $name" -ForegroundColor Red
    Write-Host " Exit code: $exitCode" -ForegroundColor Red
    Write-Host " Elapsed time: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Red
    Write-Host '============================================' -ForegroundColor Red
    exit $exitCode
}

try {
    $mem = Get-MemoryInfo
    Write-Host "Post-build memory: $($mem.FreeMB) MB free / $($mem.TotalMB) MB total ($($mem.PctUsed)% used)" -ForegroundColor Yellow
} catch {
    Write-Host 'Unable to query post-build memory info.' -ForegroundColor Yellow
}
