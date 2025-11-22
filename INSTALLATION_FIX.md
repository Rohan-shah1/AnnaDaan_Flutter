# Installation Fix Guide

## Problem: App Builds But Won't Install

Your device (RMX2161 - Android 12) is detected, but installation fails silently.

## Quick Fixes (Try These in Order)

### Fix 1: Uninstall Old Version First
**This is the MOST COMMON issue!**

1. On your phone: Settings → Apps → Search "annadaan"
2. If found, tap it → Uninstall
3. Then try installing again: `flutter run`

### Fix 2: Enable Installation from USB
On your phone:
1. Settings → Developer Options
2. Enable "Install via USB" or "USB Installation"
3. Also enable "USB Debugging (Security settings)"

### Fix 3: Check Device Storage
1. Settings → Storage
2. Make sure you have at least 200MB free space
3. Clear some space if needed

### Fix 4: Manual Installation via ADB
If Flutter install fails, try manual installation:

1. Find the APK: `build\app\outputs\flutter-apk\app-debug.apk`
2. Copy it to your phone (via USB, email, or cloud)
3. On phone: Open the APK file
4. Allow "Install from Unknown Sources" if prompted
5. Tap Install

### Fix 5: Try Direct ADB Install
If you have Android SDK Platform Tools installed:

```bash
# Navigate to platform-tools folder, then:
adb install -r "C:\Users\km450\StudioProjects\AnnaDaan\build\app\outputs\flutter-apk\app-debug.apk"
```

The `-r` flag replaces existing app.

### Fix 6: Check for Installation Errors
Run this to see detailed installation logs:

```bash
flutter run --verbose
```

Look for lines containing "INSTALL" or "error" in the output.

## Step-by-Step Solution

1. **First, uninstall any existing version:**
   - On phone: Settings → Apps → annadaan → Uninstall

2. **Enable USB installation:**
   - Settings → Developer Options
   - Enable "Install via USB"
   - Enable "USB Debugging (Security settings)"

3. **Try installation again:**
   ```bash
   flutter run
   ```

4. **If still fails, manually install:**
   - Transfer APK to phone
   - Open APK file on phone
   - Install manually

## Common Error Messages

### "INSTALL_FAILED_INSUFFICIENT_STORAGE"
- **Solution:** Free up device storage (need at least 200MB)

### "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
- **Solution:** Uninstall old version first, then reinstall

### "INSTALL_FAILED_INVALID_APK"
- **Solution:** Rebuild APK: `flutter clean && flutter build apk --debug`

### "INSTALL_PARSE_FAILED_NO_CERTIFICATES"
- **Solution:** This shouldn't happen with debug builds, but try rebuilding

### No error message (silent failure)
- **Solution:** Usually means old version exists - uninstall first

## Verify Installation

After installation, check:
1. Settings → Apps → Look for "annadaan"
2. App drawer → Look for "annadaan" icon
3. Try opening the app

## Still Not Working?

Share the exact error message from:
```bash
flutter run --verbose
```

This will show what's preventing installation.

