# Building APK - Quick Guide

## ⚠️ Important: Java 17 Required

React Native 0.72.6 requires **Java 17** (not Java 21).

## Step 1: Install Java 17

**Download from:**
https://adoptium.net/temurin/releases/?version=17

Choose:
- **macOS x64** for Intel Macs
- **macOS ARM64** for Apple Silicon (M1/M2/M3)

Install the `.pkg` file.

## Step 2: Verify Installation

```bash
/usr/libexec/java_home -V
# Should list Java 17
```

## Step 3: Build APK

```bash
cd mobile

# Set Java 17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH

# Build
./build-apk.sh
```

## Step 4: Find Your APK

After successful build:
- **Location:** `mobile/android/app/build/outputs/apk/debug/app-debug.apk`
- **Also copied to:** `mobile/hajifund-debug.apk`

## Step 5: Install on Phone

### Method 1: Transfer and Install
1. Copy APK to your phone (USB, email, cloud)
2. Enable "Install from Unknown Sources" in Android settings
3. Open APK file on phone and tap Install

### Method 2: ADB Install
```bash
adb install mobile/hajifund-debug.apk
```

## Troubleshooting

**"Java 17 not found"**
- Make sure Java 17 is installed
- Check: `/usr/libexec/java_home -V`
- If not listed, reinstall Java 17

**Build fails with Kotlin errors**
- Make sure you're using Java 17 (not 21)
- Clean build: `cd android && ./gradlew clean`

**APK not found**
- Check: `ls -la mobile/android/app/build/outputs/apk/debug/`
- If directory doesn't exist, build failed - check error messages

## Alternative: Use Android Studio

1. Open Android Studio
2. Open: `mobile/android` folder
3. Build → Build Bundle(s) / APK(s) → Build APK(s)
4. APK will be in: `app/build/outputs/apk/debug/`

