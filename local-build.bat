@echo off
setlocal enabledelayedexpansion

SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
SET JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17

echo ============================================
echo  Tethrus Wallet - Local Build Script
echo  Optimized for low-memory systems
echo ============================================
echo.
echo JAVA_HOME: %JAVA_HOME%
echo GRADLE_OPTS: %GRADLE_OPTS%
echo.
echo Available RAM check:
wmic OS get FreePhysicalMemory /value
echo.
echo Select build variant:
echo 1) prodnetDebug
echo 2) prodnetRelease
echo 3) btctestnetDebug
echo 4) btctestnetRelease
echo 5) huaweiProdnetDebug
echo 6) huaweiProdnetRelease
echo.
set /p choice=Enter choice (1-6): 

if "%choice%"=="1" (
    set TASK=mbw:assembleProdnetDebug
    set VARIANT=prodnetDebug
) else if "%choice%"=="2" (
    set TASK=mbw:assembleProdnetRelease
    set VARIANT=prodnetRelease
) else if "%choice%"=="3" (
    set TASK=mbw:assembleBtctestnetDebug
    set VARIANT=btctestnetDebug
) else if "%choice%"=="4" (
    set TASK=mbw:assembleBtctestnetRelease
    set VARIANT=btctestnetRelease
) else if "%choice%"=="5" (
    set TASK=mbw:assembleHuaweiProdnetDebug
    set VARIANT=huaweiProdnetDebug
) else if "%choice%"=="6" (
    set TASK=mbw:assembleHuaweiProdnetRelease
    set VARIANT=huaweiProdnetRelease
) else (
    echo Invalid choice. Exiting.
    exit /b 1
)

echo.
echo Building %VARIANT%...
echo Command: gradlew.bat --no-daemon --max-workers=2 clean %TASK%
echo.

call gradlew.bat --no-daemon --max-workers=2 clean %TASK%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo  Build succeeded: %VARIANT%
    echo ============================================
) else (
    echo.
    echo ============================================
    echo  Build FAILED: %VARIANT%
    echo  Exit code: %ERRORLEVEL%
    echo ============================================
    exit /b %ERRORLEVEL%
)

endlocal
