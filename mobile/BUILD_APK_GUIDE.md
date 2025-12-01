# Build APK Guide - Simple Steps

## Quick Solution: Use Java 17

The build requires **Java 17** (not Java 21). Here's how to get it:

### Option 1: Download Java 17 (Easiest)

1. **Download Java 17:**
   - Visit: https://adoptium.net/temurin/releases/?version=17
   - Download: **macOS x64** or **macOS ARM64** (depending on your Mac)
   - Install the `.pkg` file

2. **Set Java 17 as default:**
   ```bash
   export JAVA_HOME=$(/usr/libexec/java_home -v 17)
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. **Verify:**
   ```bash
   java -version
   # Should show: openjdk version "17.x.x"
   ```

4. **Build APK:**
   ```bash
   cd mobile
   ./build-apk.sh
   ```

### Option 2: Use Android Studio's JDK (If Available)

If Android Studio has JDK 17 bundled:

```bash
# Check if Android Studio has JDK 17
ls -la "/Applications/Android Studio.app/Contents/jbr/Contents/Home" 2>/dev/null

# If it exists, check version
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" -version
```

If it's Java 17, update `build-apk.sh` to use it.

### Option 3: Install via Homebrew (If Xcode Available)

```bash
brew tap homebrew/cask-versions
brew install --cask temurin17
```

Then set JAVA_HOME:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

## Build APK After Java 17 is Installed

```bash
cd mobile

# Set Java 17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH

# Build
./build-apk.sh
```

## APK Location

After successful build, the APK will be at:
```
mobile/android/app/build/outputs/apk/debug/app-debug.apk
```

Also copied to:
```
mobile/hajifund-debug.apk
```

## Install on Phone

1. **Transfer APK to phone** (USB, email, cloud storage)
2. **Enable "Install from Unknown Sources"** in Android settings
3. **Open APK file** on phone and install

Or use ADB:
```bash
adb install mobile/hajifund-debug.apk
```

## Troubleshooting

**If "Java 17 not found":**
- Make sure Java 17 is installed
- Check: `/usr/libexec/java_home -V` (should list Java 17)
- Set JAVA_HOME manually: `export JAVA_HOME=/path/to/java17`

**If build still fails:**
- Clean: `cd android && ./gradlew clean && cd ..`
- Try: `cd android && ./gradlew assembleDebug --no-daemon`

