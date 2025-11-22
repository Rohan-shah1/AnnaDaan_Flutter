# AnnaDaan App Installation Guide

## Quick Installation Steps

### Method 1: Using Flutter (Recommended)
1. Connect your Android device via USB
2. Enable USB Debugging on your device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go to Settings → Developer Options → Enable "USB Debugging"
3. Run the following command:
   ```bash
   flutter install
   ```

### Method 2: Manual APK Installation
1. The APK file is located at: `build\app\outputs\flutter-apk\app-debug.apk`
2. Transfer the APK to your Android device (via USB, email, or cloud storage)
3. On your device:
   - Open the APK file
   - If prompted, allow "Install from Unknown Sources"
   - Tap "Install"

### Method 3: Using Android Emulator
1. Open Android Studio
2. Start an Android Virtual Device (AVD)
3. Run: `flutter run`

## Troubleshooting

### "App cannot be installed" Error
- **Solution**: Enable "Install from Unknown Sources" in your device settings
  - Settings → Security → Install unknown apps
  - Or Settings → Apps → Special access → Install unknown apps

### "Device not found" Error
- Make sure USB Debugging is enabled
- Try a different USB cable
- Check if device drivers are installed (Windows)
- Run `flutter doctor` to diagnose issues

### Build Errors
- Run `flutter clean` then `flutter pub get`
- Make sure all dependencies are installed: `flutter pub get`
- Check Android SDK is properly configured

## APK Location
After building, the APK is located at:
```
build\app\outputs\flutter-apk\app-debug.apk
```

## Building a Release APK
For production release:
```bash
flutter build apk --release
```
The release APK will be at: `build\app\outputs\flutter-apk\app-release.apk`

