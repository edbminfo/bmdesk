<#
.SYNOPSIS
  BMDesk Docker Build Script

.DESCRIPTION
  Build BMDesk Android or Windows using Docker containers.

.PARAMETER Target
  Build target: 'android' or 'windows' (default: android)

.PARAMETER ConnType
  Connection type: 'incoming', 'outgoing', or empty for both

.PARAMETER Mode
  Build mode: 'release' (default) or 'debug'

.EXAMPLE
  .\docker-build.ps1 android
  .\docker-build.ps1 windows -ConnType incoming
#>

param(
    [ValidateSet("android", "windows")]
    [string]$Target = "android",

    [ValidateSet("incoming", "outgoing", "")]
    [string]$ConnType = "",

    [ValidateSet("release", "debug")]
    [string]$Mode = "release"
)

$env:MODE = $Mode

switch ($Target) {
    "android" {
        Write-Host "=== BMDesk Android Build (Docker) ===" -ForegroundColor Cyan
        Write-Host "Building Docker image (this may take a while on first run)..." -ForegroundColor Yellow

        docker build -t bmdesk-android -f Dockerfile.android .

        Write-Host "Running Android build in container..." -ForegroundColor Yellow
        docker run --rm -v "${PWD}:/workspace" -e MODE=$Mode bmdesk-android

        Write-Host "Build complete!" -ForegroundColor Green
        Write-Host "Output: flutter/build/app/outputs/"
    }
    "windows" {
        Write-Host "=== BMDesk Windows Build ===" -ForegroundColor Cyan

        $args = @("--flutter")
        if ($ConnType) {
            $args += "--conn-type", $ConnType
        }

        python build.py @args

        Write-Host "Build complete!" -ForegroundColor Green
        Write-Host "Output: bmdesk-*-install.exe"
    }
}
