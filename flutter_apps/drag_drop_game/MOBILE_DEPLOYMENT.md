# Running Drag & Drop Game on Mobile Devices

## Android Device

### Prerequisites
1. **Enable Developer Options** on your Android device:
   - Go to **Settings** > **About Phone**
   - Tap **Build Number** 7 times until you see "You are now a developer!"
   
2. **Enable USB Debugging**:
   - Go to **Settings** > **Developer Options**
   - Turn on **USB Debugging**

### Steps to Run

1. **Connect your device** via USB cable to your computer

2. **Verify device connection**:
   ```powershell
   cd flutter_apps\drag_drop_game
   flutter devices
   ```
   You should see your device listed (e.g., "SM-G991B • android-arm64")

3. **Run the app**:
   ```powershell
   flutter run -d <device-id>
   ```
   Or simply:
   ```powershell
   flutter run
   ```
   Flutter will automatically select your connected device if there's only one.

4. **Alternative - Wireless Debugging** (Android 11+):
   - Enable **Wireless Debugging** in Developer Options
   - Tap **Pair device with pairing code**
   - Run: `adb pair <IP>:<Port>` with the code shown
   - Then: `adb connect <IP>:<Port>`
   - Run: `flutter run`

---

## iOS Device (Requires macOS)

### Prerequisites
1. **Apple Developer Account** (free or paid)
2. **Xcode** installed on macOS
3. **Physical iOS device** with cable

### Steps to Run

1. **Trust your Mac** on the iOS device when prompted

2. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Set up signing**:
   - Select **Runner** in project navigator
   - Go to **Signing & Capabilities** tab
   - Select your **Team** (Apple ID)
   - Xcode will automatically create a provisioning profile

4. **Run the app**:
   ```bash
   cd flutter_apps/drag_drop_game
   flutter run
   ```

---

##Building Release APK (Android)

For sharing the app without connecting to your computer:

```powershell
cd flutter_apps\drag_drop_game
flutter build apk --release
```

The APK will be at: `build\app\outputs\flutter-apk\app-release.apk`

Transfer this file to your Android device and install it.

---

## Building Release IPA (iOS)

```bash
flutter build ipa --release
```

The IPA will be at: `build/ios/ipa/`

You'll need to upload to TestFlight or App Store Connect for distribution.

---

## Troubleshooting

### Device Not Detected
- **Windows**: Install device-specific USB drivers
- **Check cable**: Use a data cable, not charge-only
- Run: `flutter doctor -v` to check setup

### "Device is locked" error
- Unlock your device and trust the computer

### Build errors
- Run: `flutter clean`
- Then: `flutter pub get`
- Try again: `flutter run`

### Performance Issues
- Use release mode: `flutter run --release`

---

## Quick Commands Reference

| Command | Description |
|---------|-------------|
| `flutter devices` | List connected devices |
| `flutter run` | Run in debug mode (hot reload enabled) |
| `flutter run --release` | Run in release mode (optimized) |
| `flutter install` | Install current build without running |
| `flutter build apk` | Build Android APK |
| `flutter build appbundle` | Build Android  App Bundle (for Play Store) |
| `flutter build ipa` | Build iOS IPA |

---

## Hot Reload on Device

While the app is running:
- Press `r` in terminal for **hot reload** (faster, preserves state)
- Press `R` for **hot restart** (slower, fresh start)
- Press `q` to quit

This allows you to make code changes and see them instantly on your device!
