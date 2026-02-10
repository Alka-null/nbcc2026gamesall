@echo off
echo ====================================
echo NBCC Strategy Games - Quick Setup
echo ====================================
echo.

cd /d "c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames\nbcc_games"

echo Installing dependencies...
call flutter pub get

if %errorlevel% equ 0 (
    echo.
    echo ====================================
    echo Setup complete!
    echo ====================================
    echo.
    echo To run the app:
    echo   Windows Desktop:  flutter run -d windows
    echo   Web Browser:      flutter run -d chrome
    echo   Android Device:   flutter run
    echo.
) else (
    echo.
    echo ERROR: Failed to install dependencies
    echo Please make sure Flutter is installed and in your PATH
    echo.
    echo Steps:
    echo 1. Close this window
    echo 2. Open a NEW Command Prompt or PowerShell
    echo 3. Run: flutter doctor
    echo 4. Run this script again
    echo.
)

pause
