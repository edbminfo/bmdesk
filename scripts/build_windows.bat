@echo off
setlocal
cd /d %~dp0\..

set MODE=%MODE%
if "%MODE%"=="" set MODE=release

echo ============================================
echo   BMDesk Windows Build
echo   Mode: %MODE%
echo ============================================

set "VCPKG_ROOT=D:\vcpkg"
set "VCPKG_INSTALLED_ROOT=D:\vcpkg-installed\windows"

echo.
echo [1/3] Installing vcpkg dependencies...
mkdir "%VCPKG_INSTALLED_ROOT%" 2>nul
"%VCPKG_ROOT%\vcpkg.exe" install --triplet x64-windows-static --x-install-root="%VCPKG_INSTALLED_ROOT%"
if %ERRORLEVEL% neq 0 (
    echo ERROR: vcpkg install failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Building Rust native lib...
cargo build --locked --features flutter,hwcodec --%MODE%
if %ERRORLEVEL% neq 0 (
    echo ERROR: Rust build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Building Flutter Windows app...
cd flutter
flutter build windows --%MODE%
cd ..
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter build failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ============================================
echo   Build completed! Check: flutter\build\windows\x64\runner\%MODE%\
echo ============================================
endlocal
