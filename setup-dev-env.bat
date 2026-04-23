@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
echo === Tethrus Dev Environment Setup Check ===
echo.
set ALL_OK=1

:: -----------------------------------------------------------------------
:: 1. Check Java 17
:: -----------------------------------------------------------------------
echo Checking Java version...
java -version >nul 2>&1
if errorlevel 1 (
    echo   [FAIL] java not found on PATH
    set ALL_OK=0
) else (
    for /f "tokens=3 delims= " %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        set RAW_VER=%%v
    )
    :: Strip quotes
    set RAW_VER=!RAW_VER:"=!
    :: Major version is everything before the first dot (or the whole string for Java 17+)
    for /f "delims=." %%m in ("!RAW_VER!") do set MAJOR=%%m
    if "!MAJOR!"=="17" (
        echo   [OK] Java 17 detected ^(!RAW_VER!^)
    ) else (
        echo   [WARN] Expected Java 17, found !RAW_VER! ^(MAJOR=!MAJOR!^)
        set ALL_OK=0
    )
)
echo.

:: -----------------------------------------------------------------------
:: 2. Check ANDROID_HOME
:: -----------------------------------------------------------------------
echo Checking ANDROID_HOME...
if "%ANDROID_HOME%"=="" (
    echo   [FAIL] ANDROID_HOME environment variable is not set
    set ALL_OK=0
) else (
    if exist "%ANDROID_HOME%\platform-tools\adb.exe" (
        echo   [OK] ANDROID_HOME=%ANDROID_HOME%
    ) else (
        echo   [WARN] ANDROID_HOME=%ANDROID_HOME% but platform-tools not found there
        set ALL_OK=0
    )
)
echo.

:: -----------------------------------------------------------------------
:: 3. Check gradlew.bat version
:: -----------------------------------------------------------------------
echo Checking gradlew.bat...
if not exist "gradlew.bat" (
    echo   [FAIL] gradlew.bat not found in current directory
    set ALL_OK=0
) else (
    call gradlew.bat --version --no-daemon >nul 2>&1
    if errorlevel 1 (
        echo   [FAIL] gradlew.bat --version failed
        set ALL_OK=0
    ) else (
        echo   [OK] gradlew.bat is functional
    )
)
echo.

:: -----------------------------------------------------------------------
:: Summary
:: -----------------------------------------------------------------------
if "%ALL_OK%"=="1" (
    echo === All checks PASSED. Ready to build. ===
) else (
    echo === One or more checks FAILED. Review output above. ===
    exit /b 1
)
endlocal
