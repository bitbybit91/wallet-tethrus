# Tethrus Low-RAM Build Script (PowerShell)
# Usage: .\local-build.ps1
# Requires PowerShell 5+ and gradlew.bat in the current directory.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Helper: pretty yes/no prompt
# ---------------------------------------------------------------------------
function Read-Choice {
    param([string]$Prompt, [string[]]$Choices)
    while ($true) {
        Write-Host $Prompt -ForegroundColor Cyan
        for ($i = 0; $i -lt $Choices.Count; $i++) {
            Write-Host ("  {0}) {1}" -f ($i + 1), $Choices[$i])
        }
        $raw = Read-Host "Enter choice (1-$($Choices.Count))"
        $idx = [int]$raw - 1
        if ($idx -ge 0 -and $idx -lt $Choices.Count) { return $idx }
        Write-Warning "Invalid choice. Try again."
    }
}

# ---------------------------------------------------------------------------
# Memory check
# ---------------------------------------------------------------------------
$sw = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host ""
Write-Host "=== Tethrus Low-RAM Build ===" -ForegroundColor Green
Write-Host ""

try {
    $availMB = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue
    Write-Host ("Available RAM: {0:N0} MB" -f $availMB)
    if ($availMB -lt 1536) {
        Write-Warning "Less than 1.5 GB RAM available ($availMB MB). Build may fail or be slow."
    }
} catch {
    Write-Warning "Could not read available memory: $_"
}

# ---------------------------------------------------------------------------
# Java home fallback
# ---------------------------------------------------------------------------
if (-not $env:JAVA_HOME) {
    $candidate = "C:\Program Files\Eclipse Adoptium\jdk-17"
    if (Test-Path $candidate) {
        $env:JAVA_HOME = $candidate
        Write-Host "JAVA_HOME set to $candidate"
    } else {
        Write-Warning "JAVA_HOME is not set and default path not found. Build may fail."
    }
}

$env:GRADLE_OPTS = "-Xmx512m -Dfile.encoding=UTF-8"

# ---------------------------------------------------------------------------
# Flavor menu
# ---------------------------------------------------------------------------
$flavors = @(
    "prodnetDebug         -> mbw:assembleProdnetDebug",
    "prodnetRelease       -> mbw:assembleProdnetRelease",
    "btctestnetDebug      -> mbw:assembleBtctestnetDebug",
    "btctestnetRelease    -> mbw:assembleBtctestnetRelease",
    "huaweiProdnetDebug   -> mbw:assembleHuaweiProdnetDebug",
    "huaweiProdnetRelease -> mbw:assembleHuaweiProdnetRelease"
)

$tasks = @(
    "mbw:assembleProdnetDebug",
    "mbw:assembleProdnetRelease",
    "mbw:assembleBtctestnetDebug",
    "mbw:assembleBtctestnetRelease",
    "mbw:assembleHuaweiProdnetDebug",
    "mbw:assembleHuaweiProdnetRelease"
)

$choice = Read-Choice -Prompt "Select build target:" -Choices $flavors
$gradleTask = $tasks[$choice]

# ---------------------------------------------------------------------------
# Run Gradle
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Building: $gradleTask" -ForegroundColor Yellow
Write-Host ""

$gradlew = Join-Path $PSScriptRoot "gradlew.bat"
if (-not (Test-Path $gradlew)) {
    $gradlew = "gradlew.bat"   # rely on PATH / current dir
}

try {
    & $gradlew --no-daemon --max-workers=2 clean $gradleTask
    $exitCode = $LASTEXITCODE
} catch {
    Write-Error "Failed to launch Gradle: $_"
    exit 1
}

$sw.Stop()
$elapsed = $sw.Elapsed

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host ("Build SUCCEEDED in {0:mm\:ss}" -f $elapsed) -ForegroundColor Green

    # Print APK paths
    $apkDir = Join-Path $PSScriptRoot "mbw\build\outputs\apk"
    if (Test-Path $apkDir) {
        $apks = Get-ChildItem -Path $apkDir -Recurse -Filter "*.apk"
        if ($apks) {
            Write-Host ""
            Write-Host "Produced APKs:" -ForegroundColor Cyan
            $apks | ForEach-Object { Write-Host "  $($_.FullName)" }
        }
    }
    exit 0
} else {
    Write-Host ""
    Write-Host ("Build FAILED (exit $exitCode) after {0:mm\:ss}" -f $elapsed) -ForegroundColor Red
    exit $exitCode
}
