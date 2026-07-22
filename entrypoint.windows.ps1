<#
.SYNOPSIS
  BMDesk Windows Docker build entrypoint

.DESCRIPTION
  Sets MSVC environment, installs vcpkg deps, generates flutter-rust-bridge
  bindings, and runs build.py --flutter.

.PARAMETER Arch
  Target architecture: x86_64 (default) or i686 (32-bit)

.PARAMETER ConnType
  Connection type: 'incoming', 'outgoing', or '' (both)

.PARAMETER Mode
  Build mode: 'release' (default) or 'debug'

.PARAMETER SkipPortablePack
  Skip final portable-packer step; keeps raw flutter Release/ output

.PARAMETER SkipVcpkg
  Skip vcpkg install step (use when deps are pre-built)

.PARAMETER SkipBridge
  Skip flutter-rust-bridge codegen (use when bridge is pre-generated)

.EXAMPLE
  docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build
  docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build -ConnType incoming
  docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build -Arch i686
  docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build powershell
#>

param(
    [ValidateSet("x86_64", "i686")]
    [string]$Arch = "x86_64",

    [ValidateSet("incoming", "outgoing", "")]
    [string]$ConnType = "",

    [ValidateSet("release", "debug")]
    [string]$Mode = "release",

    [switch]$SkipPortablePack,
    [switch]$SkipVcpkg,
    [switch]$SkipBridge
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ── Build PATH for this process ──
$env:PATH = @(
    'C:\tools\bin',
    'C:\tools\cmake\bin',
    'C:\tools\ninja',
    'C:\tools\python',
    'C:\tools\python\Scripts',
    'C:\tools\llvm\bin',
    'C:\Program Files\Git\cmd',
    'C:\Program Files\Git\bin',
    'C:\Program Files\Git\usr\bin',
    "$env:CARGO_HOME\bin",
    'C:\tools\rust\bin',
    'C:\tools\flutter\bin',
    $env:PATH
) -join ';'

# ── MSVC environment (capture vcvars64 output into current PS session) ──
Write-Host "Setting up MSVC environment..." -ForegroundColor Cyan
$vcvarsBat = "C:\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvarsBat)) {
    Write-Error "vcvars64.bat not found at $vcvarsBat — VS Build Tools not installed?"
    exit 1
}
# Run vcvars and import all env vars into this PowerShell process
cmd /c "`"$vcvarsBat`" > nul && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $name  = $matches[1]
        $value = $matches[2]
        Set-Item -Path "env:$name" -Value $value
    }
}
Write-Host "MSVC environment loaded. INCLUDE=$env:INCLUDE" -ForegroundColor Gray

# ── Print tool versions ──
Write-Host "=== BMDesk Windows Build Environment ===" -ForegroundColor Cyan
Write-Host "Target arch : $Arch" -ForegroundColor Yellow
Write-Host "Conn type   : $(if ($ConnType) { $ConnType } else { 'standard' })" -ForegroundColor Yellow
Write-Host "Mode        : $Mode" -ForegroundColor Yellow

Write-Host "--- Tool versions ---" -ForegroundColor Gray
try { python --version } catch { Write-Host "python: NOT FOUND" -ForegroundColor Red }
try { rustup show active-toolchain } catch { Write-Host "rustup: NOT FOUND" -ForegroundColor Red }
try { clang-cl --version 2>&1 | Select-Object -First 1 } catch { Write-Host "clang-cl: NOT FOUND" -ForegroundColor Red }
try { cmake --version 2>&1 | Select-Object -First 1 } catch { Write-Host "cmake: NOT FOUND" -ForegroundColor Red }
try { flutter --version 2>&1 | Select-Object -First 1 } catch { Write-Host "flutter: NOT FOUND" -ForegroundColor Red }
try { git --version } catch { Write-Host "git: NOT FOUND" -ForegroundColor Red }
Write-Host "---" -ForegroundColor Gray

# ── vcpkg deps ──
if (-not $SkipVcpkg) {
    Write-Host "Installing vcpkg dependencies..." -ForegroundColor Cyan
    $vcpkgTriplet = if ($Arch -eq "i686") { "x86-windows-static" } else { "x64-windows-static" }
    $vcpkgArgs = @(
        "install",
        "--triplet=$vcpkgTriplet",
        "--x-install-root=$env:VCPKG_ROOT\installed"
    )
    $overlayDir = if (Test-Path .\res\vcpkg) { ".\res\vcpkg" } else { $null }
    if ($overlayDir) {
        $vcpkgArgs += "--overlay-ports=$overlayDir"
    }
    Write-Host "  vcpkg $vcpkgArgs" -ForegroundColor Gray
    & "$env:VCPKG_ROOT\vcpkg.exe" @vcpkgArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "vcpkg install failed (exit code $LASTEXITCODE)"
        exit 1
    }
} else {
    Write-Host "Skipping vcpkg install (--SkipVcpkg)" -ForegroundColor Yellow
}

# ── Flutter pub get ──
Write-Host "Flutter pub get..." -ForegroundColor Cyan
Push-Location flutter
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
} finally {
    Pop-Location
}

# ── Flutter-rust-bridge ──
if (-not $SkipBridge) {
    Write-Host "Installing flutter-rust-bridge codegen..." -ForegroundColor Cyan
    cargo install cargo-expand --version 1.0.95 --locked
    if ($LASTEXITCODE -ne 0) { Write-Error "cargo-expand install failed"; exit 1 }
    cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid" --locked
    if ($LASTEXITCODE -ne 0) { Write-Error "flutter_rust_bridge_codegen install failed"; exit 1 }

    Write-Host "Generating bridge code..." -ForegroundColor Cyan
    flutter_rust_bridge_codegen `
        --rust-input ./src/flutter_ffi.rs `
        --dart-output ./flutter/lib/generated_bridge.dart `
        --c-output ./flutter/windows/runner/bridge_generated.h
    if ($LASTEXITCODE -ne 0) { Write-Error "bridge codegen failed"; exit 1 }

    Write-Host "Bridge generated successfully." -ForegroundColor Green
} else {
    Write-Host "Skipping bridge codegen (--SkipBridge)" -ForegroundColor Yellow
}

# ── Build ──
Write-Host "Building BMDesk..." -ForegroundColor Cyan

$buildArgs = @("--flutter")
if ($ConnType) {
    $buildArgs += "--conn-type", $ConnType
}
if ($Arch -eq "i686") {
    $buildArgs += "--32"
}
if ($SkipPortablePack) {
    $buildArgs += "--skip-portable-pack"
}

Write-Host "  python build.py $buildArgs" -ForegroundColor Gray
python build.py @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed (exit code $LASTEXITCODE)"
    exit 1
}

# ── Report output ──
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Output:" -ForegroundColor Yellow
$installers = Get-ChildItem .\bmdesk-*.exe -ErrorAction SilentlyContinue
if ($installers) {
    $installers | ForEach-Object {
        Write-Host "  $($_.Name)  ($('{0:N0}' -f $_.Length) bytes)" -ForegroundColor White
    }
} else {
    Write-Host "  No installer found — check flutter build output:" -ForegroundColor Yellow
    $archDir = if ($Arch -eq "i686") { "x86" } else { "x64" }
    $flutterOut = ".\flutter\build\windows\$archDir\runner\Release"
    if (Test-Path $flutterOut) {
        Write-Host "  $flutterOut" -ForegroundColor White
        Get-ChildItem $flutterOut -Filter *.exe | ForEach-Object {
            Write-Host "    $($_.Name)  ($('{0:N0}' -f $_.Length) bytes)" -ForegroundColor Gray
        }
    }
}
