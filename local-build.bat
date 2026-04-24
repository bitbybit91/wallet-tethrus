@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
if "%JAVA_HOME%"=="" SET JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17
echo === Tethrus Low-RAM Build ===
wmic OS get FreePhysicalMemory /value | find "="
echo.
echo 1) prodnetDebug
echo 2) prodnetRelease
echo 3) btctestnetDebug
echo 4) btctestnetRelease
echo 5) huaweiProdnetDebug
echo 6) huaweiProdnetRelease
set /p choice=Enter choice (1-6):
if "%choice%"=="1" call gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleProdnetDebug
if "%choice%"=="2" call gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleProdnetRelease
if "%choice%"=="3" call gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleBtctestnetDebug
if "%choice%"=="4" call gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleBtctestnetRelease
if "%choice%"=="5" call gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleHuaweiProdnetDebug
if "%choice%"=="6" call gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleHuaweiProdnetRelease
endlocal
