@echo off
setlocal enabledelayedexpansion

echo ============================================
echo  Tethrus Wallet - Dev Environment Setup Check
echo ============================================
echo.

set ERRORS=0

REM --- Check JDK 17 ---
echo [1/5] Checking JDK 17...
where java >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [FAIL] Java not found in PATH.
    set /a ERRORS+=1
) else (
    for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do (
        set JAVA_VER=%%~v
    )
    echo   [OK] Java version: !JAVA_VER!
    echo !JAVA_VER! | findstr /b "17" >nul
    if !ERRORLEVEL! NEQ 0 (
        echo   [WARN] Expected JDK 17. Found: !JAVA_VER!
    )
)

REM --- Check JAVA_HOME ---
if defined JAVA_HOME (
    echo   [OK] JAVA_HOME: %JAVA_HOME%
) else (
    echo   [WARN] JAVA_HOME is not set. Set it to your JDK 17 installation.
)
echo.

REM --- Check Android SDK ---
echo [2/5] Checking Android SDK...
if defined ANDROID_HOME (
    echo   [OK] ANDROID_HOME: %ANDROID_HOME%
) else if defined ANDROID_SDK_ROOT (
    echo   [OK] ANDROID_SDK_ROOT: %ANDROID_SDK_ROOT%
) else (
    echo   [FAIL] Neither ANDROID_HOME nor ANDROID_SDK_ROOT is set.
    set /a ERRORS+=1
)
echo.

REM --- Check NDK ---
echo [3/5] Checking NDK 21.1.6352462...
set NDK_PATH=
if defined ANDROID_HOME set NDK_PATH=%ANDROID_HOME%\ndk\21.1.6352462
if defined ANDROID_SDK_ROOT if not defined NDK_PATH set NDK_PATH=%ANDROID_SDK_ROOT%\ndk\21.1.6352462
if defined NDK_PATH (
    if exist "!NDK_PATH!" (
        echo   [OK] NDK found at: !NDK_PATH!
    ) else (
        echo   [FAIL] NDK 21.1.6352462 not found at: !NDK_PATH!
        echo   Install with: sdkmanager "ndk;21.1.6352462"
        set /a ERRORS+=1
    )
) else (
    echo   [SKIP] Cannot check NDK without ANDROID_HOME or ANDROID_SDK_ROOT.
)
echo.

REM --- Check CMake ---
echo [4/5] Checking CMake 3.22.1...
set CMAKE_PATH=
if defined ANDROID_HOME set CMAKE_PATH=%ANDROID_HOME%\cmake\3.22.1
if defined ANDROID_SDK_ROOT if not defined CMAKE_PATH set CMAKE_PATH=%ANDROID_SDK_ROOT%\cmake\3.22.1
if defined CMAKE_PATH (
    if exist "!CMAKE_PATH!" (
        echo   [OK] CMake found at: !CMAKE_PATH!
    ) else (
        echo   [FAIL] CMake 3.22.1 not found at: !CMAKE_PATH!
        echo   Install with: sdkmanager "cmake;3.22.1"
        set /a ERRORS+=1
    )
) else (
    echo   [SKIP] Cannot check CMake without ANDROID_HOME or ANDROID_SDK_ROOT.
)
echo.

REM --- Check Gradle Wrapper ---
echo [5/5] Checking Gradle wrapper...
if exist "gradlew.bat" (
    echo   [OK] gradlew.bat found.
    for /f "tokens=1,* delims==" %%a in ('findstr "distributionUrl" gradle\wrapper\gradle-wrapper.properties') do (
        echo   Gradle distribution: %%b
    )
) else (
    echo   [FAIL] gradlew.bat not found. Are you in the project root?
    set /a ERRORS+=1
)
echo.

echo ============================================
if %ERRORS% EQU 0 (
    echo  All checks passed. Ready to build!
) else (
    echo  %ERRORS% check(s) failed. Please fix the issues above.
)
echo ============================================

endlocal
