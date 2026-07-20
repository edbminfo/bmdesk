@echo off
setlocal

set MODE=%MODE%
if "%MODE%"=="" set MODE=release

echo ============================================
echo   BMDesk Android Build
echo   Mode: %MODE%
echo ============================================
echo.

echo [1/3] Building APK (split per ABI)...
flutter build apk --split-per-abi --target-platform android-arm64,android-arm --%MODE% --obfuscate --split-debug-info split-debug-info
if %ERRORLEVEL% neq 0 (
    echo ERROR: APK split build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Building APK (fat)...
flutter build apk --target-platform android-arm64,android-arm --%MODE% --obfuscate --split-debug-info split-debug-info
if %ERRORLEVEL% neq 0 (
    echo ERROR: APK fat build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Building AAB...
flutter build appbundle --target-platform android-arm64,android-arm --%MODE% --obfuscate --split-debug-info split-debug-info
if %ERRORLEVEL% neq 0 (
    echo ERROR: AAB build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ============================================
echo   Build completed successfully!
echo ============================================
echo.
echo Outputs:
echo   APK (split): build\app\outputs\flutter-apk\app-*-%MODE%.apk
echo   APK (fat):   build\app\outputs\flutter-apk\app-%MODE%.apk
echo   AAB:         build\app\outputs\bundle\%MODE%\app-%MODE%.aab
echo.

endlocal
