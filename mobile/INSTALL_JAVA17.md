# Install Java 17 - Quick Guide

## Why Java 17?

React Native 0.72.6 requires Java 17. Your current Java 21 is too new and causes Kotlin compatibility issues.

## Install Java 17

### Step 1: Download

Visit: **https://adoptium.net/temurin/releases/?version=17**

Download:
- **macOS x64** (for Intel Macs)
- **macOS ARM64** (for Apple Silicon M1/M2/M3)

### Step 2: Install

1. Open the downloaded `.pkg` file
2. Follow the installation wizard
3. Complete the installation

### Step 3: Verify

```bash
/usr/libexec/java_home -V
```

You should see Java 17 listed.

### Step 4: Build APK

```bash
cd mobile

# Set Java 17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH

# Verify
java -version
# Should show: openjdk version "17.x.x"

# Build
./build-apk.sh
```

## Alternative: Use Android Studio

If you have Android Studio installed:

1. Open Android Studio
2. File → Open → Select `mobile/android` folder
3. Wait for Gradle sync
4. Build → Build Bundle(s) / APK(s) → Build APK(s)
5. APK location: `android/app/build/outputs/apk/debug/app-debug.apk`
./
## After Building

The APK will be at:
- `mobile/android/app/build/outputs/apk/debug/app-debug.apk`
- Also copied to: `mobile/hajifund-debug.apk`

Transfer to your phone and install!

