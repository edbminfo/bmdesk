@echo off
setlocal
cd /d %~dp0\..

echo ============================================
echo   BMDesk - Install APK to device (64-bit)
echo ============================================

set APK=%~1
if "%APK%"=="" set APK=flutter\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

if not exist "%APK%" (
    echo ERROR: APK not found: %APK%
    exit /b 1
)

echo Installing: %APK%

:: Bypass Play Protect verification
adb shell settings put global package_verifier_enable 0 >nul 2>&1
adb install -t "%APK%"

if %ERRORLEVEL% equ 0 (
    echo SUCCESS: APK installed!
) else (
    echo FAILED: Check if device is connected and authorized.
    echo Run: adb devices
)

endlocal
