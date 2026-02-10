# NBCC Strategy Games

🎮 Interactive gamification platform for sales training - Built with Flutter

## 🎯 Games Included

1. **Jigsaw Puzzle** - Build the 2030 Evergreen Drivers (16-piece puzzle)
2. **Drag & Drop** - Match statements to Growth, Productivity, Future-Fit categories
3. **Challenge Mode** - Complete DMS/SOT/QuickDrinks tasks in 60 seconds
4. **Beer Cup Challenge** - Fill the cup by answering scenario-based questions
5. **Know Your Enablers** - Quiz about sales tools and enablers
6. **App Demos** - Learn about SEM, QuickDrinks, DMS, and Asset Management

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK 3.19.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio (for Android deployment) OR
- Xcode (for iOS deployment) OR
- Chrome (for web preview)

### Installation Steps

1. **Close and reopen PowerShell** to apply Flutter PATH changes

2. **Verify Flutter installation:**
   ```powershell
   flutter --version
   flutter doctor
   ```

3. **Navigate to project folder:**
   ```powershell
   cd "c:\Users\HomePC\Desktop\AK\Projects\MyPersonal\NBCCStrategyGames\nbcc_games"
   ```

4. **Get dependencies:**
   ```powershell
   flutter pub get
   ```

5. **Run the app:**
   ```powershell
   # For Windows Desktop
   flutter run -d windows

   # For Web (Chrome)
   flutter run -d chrome

   # For Android (with device connected)
   flutter run -d <device-id>
   ```

## 📱 Building for Production

### Android APK
```powershell
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```powershell
flutter build appbundle --release
```

### iOS
```powershell
flutter build ios --release
```

### Windows
```powershell
flutter build windows --release
```

## 🎨 Features

- ✨ Beautiful gradient animations
- 🎯 Interactive drag-and-drop gameplay
- ⏱️ Real-time timers and countdowns
- 🏆 Score tracking and leaderboards
- 📊 Progress visualization
- 💫 Smooth transitions and effects
- 🌈 Premium corporate design
- 📱 Optimized for large touchscreens
- 🔄 Landscape-only orientation
- 🎭 Full-screen immersive mode

## 🛠️ Technology Stack

- **Framework:** Flutter 3.19+
- **Language:** Dart 3.2+
- **State Management:** Provider
- **Animations:** flutter_animate, Lottie
- **UI Components:** Material 3, Google Fonts
- **Storage:** Shared Preferences, Hive
- **Timers:** circular_countdown_timer, stop_watch_timer

## 📦 Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # Game screens
│   ├── home_screen.dart
│   ├── jigsaw_puzzle_screen.dart
│   ├── drag_drop_screen.dart
│   ├── challenge_mode_screen.dart
│   ├── beer_cup_screen.dart
│   ├── enablers_quiz_screen.dart
│   └── demo_screen.dart
├── widgets/                  # Reusable widgets
│   ├── animated_background.dart
│   └── game_card.dart
├── utils/                    # Utilities
│   ├── app_theme.dart
│   └── game_state.dart
└── models/                   # Data models
```

## 🎮 How to Deploy on Large Screen

### Option 1: Android Tablet/Display
1. Build APK: `flutter build apk --release`
2. Transfer APK to Android device
3. Install and run in fullscreen/kiosk mode

### Option 2: Windows Desktop
1. Build Windows app: `flutter build windows --release`
2. Copy `build/windows/runner/Release` folder
3. Run on Windows tablet/PC connected to large display

### Option 3: Web (for demos)
1. Build web: `flutter build web --release`
2. Deploy to hosting (Firebase, Netlify, etc.)
3. Open in fullscreen browser on display device

## 🔧 Troubleshooting

**Issue: Flutter command not recognized**
- Close and reopen PowerShell/Terminal
- Verify Flutter is in PATH: `echo $env:PATH`
- Manually add to PATH if needed

**Issue: Dependencies not downloading**
```powershell
flutter clean
flutter pub get
```

**Issue: Build fails**
```powershell
flutter doctor
flutter pub upgrade
```

## 📝 Customization

### Adding New Questions
Edit the question arrays in respective screen files:
- `jigsaw_puzzle_screen.dart` - Puzzle labels
- `drag_drop_screen.dart` - Drag & drop statements
- `beer_cup_screen.dart` - Scenario questions
- `enablers_quiz_screen.dart` - Quiz questions

### Changing Colors
Modify `lib/utils/app_theme.dart` to update color scheme

### Adjusting Timer Durations
Update timer values in individual screen files

## 🎯 Deployment Checklist for Events

- [ ] Flutter installed and verified
- [ ] Dependencies downloaded (`flutter pub get`)
- [ ] App tested on target device
- [ ] Large screen/display connected
- [ ] Device in fullscreen/kiosk mode
- [ ] Orientation locked to landscape
- [ ] Internet connection (if using online features)
- [ ] Backup APK/executable available

## 📧 Support

For issues or questions, check:
- Flutter documentation: https://docs.flutter.dev
- Project issues: Check error logs in terminal

---

**Built with ❤️ using Flutter**
