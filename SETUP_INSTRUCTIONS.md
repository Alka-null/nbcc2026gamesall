# NBCC Strategy Games - Setup Instructions

## Flutter Installation (Windows)

### Option 1: Install via PowerShell (Recommended)
```powershell
# Download Flutter SDK
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip" -OutFile "$env:USERPROFILE\Downloads\flutter_windows.zip"

# Extract to C:\src\flutter
Expand-Archive -Path "$env:USERPROFILE\Downloads\flutter_windows.zip" -DestinationPath "C:\src"

# Add to PATH
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", [EnvironmentVariableTarget]::User)
```

### Option 2: Manual Installation
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to your PATH environment variable
4. Restart PowerShell

### Verify Installation
```powershell
flutter doctor
```

## Android Studio Setup (for mobile deployment)

1. Download Android Studio: https://developer.android.com/studio
2. Install Android SDK
3. Run `flutter doctor --android-licenses` and accept all

## VS Code Setup (Optional but Recommended)

1. Install extensions:
   - Flutter
   - Dart
   
## Create and Run Project

After Flutter is installed:

```powershell
cd "c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames"
flutter create nbcc_games
cd nbcc_games
flutter pub get
flutter run -d windows  # For Windows desktop
flutter run -d chrome   # For web preview
```

## Quick Install Script

Run this in PowerShell as Administrator:

```powershell
# Install Chocolatey (package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Flutter via Chocolatey
choco install flutter -y

# Verify
flutter doctor
```

After installation completes, return here and I'll set up the complete project!
