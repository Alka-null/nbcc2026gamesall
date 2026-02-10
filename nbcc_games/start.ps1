# NBCC Games - Quick Start Script
# Run this script after installing Flutter

Write-Host "🎮 NBCC Strategy Games - Setup" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Flutter is installed" -ForegroundColor Green
        Write-Host $flutterVersion
    }
} catch {
    Write-Host "✗ Flutter not found!" -ForegroundColor Red
    Write-Host "`nPlease install Flutter first:" -ForegroundColor Yellow
    Write-Host "1. Close this PowerShell window" -ForegroundColor White
    Write-Host "2. Open a NEW PowerShell window (to refresh PATH)" -ForegroundColor White
    Write-Host "3. Run this script again`n" -ForegroundColor White
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "`n================================`n" -ForegroundColor Cyan

# Navigate to project directory
$projectPath = "c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames\nbcc_games"
Write-Host "Navigating to project directory..." -ForegroundColor Yellow
Set-Location $projectPath

# Get dependencies
Write-Host "`nDownloading dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Dependencies installed successfully!" -ForegroundColor Green
} else {
    Write-Host "`n✗ Failed to install dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Check for devices
Write-Host "`n================================`n" -ForegroundColor Cyan
Write-Host "Checking available devices..." -ForegroundColor Yellow
flutter devices

# Ask user how to run
Write-Host "`n================================`n" -ForegroundColor Cyan
Write-Host "How would you like to run the app?" -ForegroundColor Yellow
Write-Host "1. Windows Desktop" -ForegroundColor White
Write-Host "2. Web (Chrome)" -ForegroundColor White
Write-Host "3. Android Device" -ForegroundColor White
Write-Host "4. Exit" -ForegroundColor White

$choice = Read-Host "`nEnter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "`nLaunching on Windows Desktop..." -ForegroundColor Green
        flutter run -d windows
    }
    "2" {
        Write-Host "`nLaunching in Chrome..." -ForegroundColor Green
        flutter run -d chrome
    }
    "3" {
        Write-Host "`nLaunching on Android..." -ForegroundColor Green
        flutter run
    }
    "4" {
        Write-Host "`nExiting..." -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "`nInvalid choice. Exiting..." -ForegroundColor Red
        exit
    }
}
