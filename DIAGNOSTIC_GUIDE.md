# Diagnostic Guide - App Not Displaying on Mobile

## Step-by-Step Diagnosis

### Step 1: Verify App Installation
1. **Check if app is installed:**
   - Go to Settings → Apps → Look for "annadaan"
   - If it's there, try opening it
   - If it crashes immediately, note the error message

2. **Check app icon:**
   - Look in your app drawer for "annadaan"
   - If icon is there but app doesn't open, it's a launch issue

### Step 2: Run with Flutter to See Errors
**This is the BEST way to see what's wrong:**

1. Connect your device via USB
2. Enable USB Debugging
3. Run this command:
   ```bash
   flutter run
   ```
4. **Watch the console output** - it will show you EXACT errors

### Step 3: Check Common Issues

#### Issue A: App Installs But Shows Blank Screen
**Possible Causes:**
- Font loading issue (should be fixed now)
- Navigation error
- Widget build error

**Solution:**
- Run `flutter run` to see errors
- Check if splash screen appears

#### Issue B: App Crashes Immediately
**Possible Causes:**
- Missing permissions
- Android version incompatibility
- Missing resources

**Solution:**
- Check device Android version (should be Android 5.0+)
- Check device storage space
- Try running `flutter run` to see crash logs

#### Issue C: App Doesn't Install
**Possible Causes:**
- APK corrupted
- Device storage full
- Unknown sources not enabled

**Solution:**
- Rebuild APK: `flutter clean && flutter build apk --debug`
- Check device storage
- Enable "Install from Unknown Sources"

### Step 4: Test with Minimal App
If the app still doesn't work, we can create a minimal test version to isolate the issue.

## Quick Test Commands

```bash
# 1. Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug

# 2. Run directly on device (shows errors)
flutter run

# 3. Check Flutter setup
flutter doctor -v
```

## What to Check on Your Device

1. **Android Version:** Settings → About Phone → Android Version
   - Should be Android 5.0 (API 21) or higher

2. **Storage Space:** Settings → Storage
   - Should have at least 100MB free

3. **Developer Options:** Settings → Developer Options
   - USB Debugging should be enabled

4. **App Permissions:** Settings → Apps → annadaan → Permissions
   - Internet permission should be granted

## If App Still Doesn't Show

**Run this command and share the output:**
```bash
flutter run --verbose
```

This will show detailed logs of what's happening when the app tries to launch.

## Common Error Messages and Solutions

### "App keeps stopping"
- **Cause:** Runtime crash
- **Solution:** Run `flutter run` to see error details

### "App not installed"
- **Cause:** Installation failed
- **Solution:** Uninstall old version, rebuild, reinstall

### "Blank/White screen"
- **Cause:** Widget build error or navigation issue
- **Solution:** Check `flutter run` output for build errors

### "App icon not showing"
- **Cause:** Launcher activity not properly configured
- **Solution:** Already fixed in AndroidManifest.xml

