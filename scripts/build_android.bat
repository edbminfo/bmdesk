@echo off
setlocal
cd /d %~dp0\..

set MODE=%MODE%
if "%MODE%"=="" set MODE=release
set TARGET=%~1

if "%TARGET%"=="" (
    echo Usage: build_android.bat [arm64^|arm^|all]
    echo   arm64 - 64-bit devices
    echo   arm   - 32-bit devices
    echo   all   - both architectures
    exit /b 1
)

set "ANDROID_NDK_HOME=%LOCALAPPDATA%\Android\sdk\ndk\28.2.13676358"
set "VCPKG_ROOT=D:\vcpkg"

echo ============================================
echo   BMDesk Android Build
echo   Target: %TARGET%
echo   Mode: %MODE%
echo ============================================

:: ============ ARM64 ============
if "%TARGET%"=="arm64"       goto :build_arm64
if "%TARGET%"=="arm"         goto :build_arm
if "%TARGET%"=="all"         goto :build_arm64

echo Unknown target: %TARGET%
exit /b 1

:build_arm64
    set "VCPKG_INSTALLED_ROOT=D:\vcpkg-installed\android-arm64"

    echo.
    echo [1/4] Installing vcpkg deps (arm64)...
    mkdir "%VCPKG_INSTALLED_ROOT%" 2>nul
    "%VCPKG_ROOT%\vcpkg.exe" install --triplet arm64-android --x-install-root="%VCPKG_INSTALLED_ROOT%"
    if %ERRORLEVEL% neq 0 ( echo ERROR: vcpkg arm64 failed! & exit /b %ERRORLEVEL% )

    echo.
    echo [2/4] Building Rust native lib (arm64)...
    set "SODIUM_LIB_DIR=%VCPKG_INSTALLED_ROOT%\lib"
    set "OPENSSL_DIR=%VCPKG_INSTALLED_ROOT%"
    set "AARCH64_LINUX_ANDROID_OPENSSL_NO_VENDOR=1"
    set "PKG_CONFIG_PATH=%VCPKG_INSTALLED_ROOT%\lib\pkgconfig"
    cargo ndk --platform 21 --target aarch64-linux-android build --locked --release --features flutter,hwcodec
    if %ERRORLEVEL% neq 0 ( echo ERROR: Rust arm64 build failed! & exit /b %ERRORLEVEL% )

    if "%TARGET%"=="arm64" goto :build_apk

:build_arm
    set "VCPKG_INSTALLED_ROOT=D:\vcpkg-installed\android-arm"

    echo.
    echo [1/4] Installing vcpkg deps (armv7)...
    mkdir "%VCPKG_INSTALLED_ROOT%" 2>nul
    "%VCPKG_ROOT%\vcpkg.exe" install --triplet arm-neon-android --x-install-root="%VCPKG_INSTALLED_ROOT%"
    if %ERRORLEVEL% neq 0 ( echo ERROR: vcpkg armv7 failed! & exit /b %ERRORLEVEL% )

    :: Create symlink arm-android -> arm-neon-android for hwcodec
    rmdir "%VCPKG_INSTALLED_ROOT%\arm-android" 2>nul
    mklink /J "%VCPKG_INSTALLED_ROOT%\arm-android" "%VCPKG_INSTALLED_ROOT%" 2>nul

    echo.
    echo [2/4] Building Rust native lib (armv7)...
    set "SODIUM_LIB_DIR=%VCPKG_INSTALLED_ROOT%\lib"
    set "OPENSSL_DIR=%VCPKG_INSTALLED_ROOT%"
    set "ARMV7_LINUX_ANDROIDEABI_OPENSSL_NO_VENDOR=1"
    set "PKG_CONFIG_PATH=%VCPKG_INSTALLED_ROOT%\lib\pkgconfig"
    cargo ndk --platform 21 --target armv7-linux-androideabi build --locked --release --features flutter,hwcodec
    if %ERRORLEVEL% neq 0 ( echo ERROR: Rust armv7 build failed! & exit /b %ERRORLEVEL% )

:build_apk
    echo.
    echo [3/4] Building Flutter APK...

    :: O APK split-per-abi pega os .so de jniLibs/
    :: Copiar o .so do target correto
    cd flutter

    if "%TARGET%"=="all" (
        flutter build apk --split-per-abi --target-platform android-arm64,android-arm --%MODE% --obfuscate --split-debug-info split-debug-info
    ) else if "%TARGET%"=="arm64" (
        flutter build apk --split-per-abi --target-platform android-arm64 --%MODE% --obfuscate --split-debug-info split-debug-info
    ) else if "%TARGET%"=="arm" (
        flutter build apk --split-per-abi --target-platform android-arm --%MODE% --obfuscate --split-debug-info split-debug-info
    )
    cd ..
    if %ERRORLEVEL% neq 0 ( echo ERROR: Flutter build failed! & exit /b %ERRORLEVEL% )

    echo.
    echo [4/4] Building AAB...
    cd flutter
    flutter build appbundle --target-platform android-arm64,android-arm --%MODE% --obfuscate --split-debug-info split-debug-info
    cd ..
    if %ERRORLEVEL% neq 0 ( echo ERROR: AAB build failed! & exit /b %ERRORLEVEL% )

    echo.
    echo ============================================
    echo   Build completed!
    echo   APK: flutter\build\app\outputs\flutter-apk\
    echo   AAB: flutter\build\app\outputs\bundle\%MODE%\
    echo ============================================
    endlocal
    exit /b 0
