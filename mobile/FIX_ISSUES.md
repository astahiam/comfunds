# Fixing Android Development Issues

## Issue 1: Java Runtime Not Found

### Solution: Install Java JDK

**Option A: Install via Homebrew (if Xcode is installed)**
```bash
brew install openjdk@17
```

**Option B: Download from Oracle/Adoptium (Recommended)**
1. Visit: https://adoptium.net/
2. Download JDK 17 for macOS
3. Install the .pkg file
4. Set environment variables:

Add to `~/.zshrc`:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH=$JAVA_HOME/bin:$PATH
```

Then reload:
```bash
source ~/.zshrc
```

**Option C: Use Android Studio's JDK**
If you have Android Studio installed:
```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH=$JAVA_HOME/bin:$PATH
```

Verify installation:
```bash
java -version
```

## Issue 2: EMFILE - Too Many Open Files

### Solution: Increase File Watcher Limit

**Step 1: Increase system limits (requires sudo)**

Create or edit `/etc/sysctl.conf`:
```bash
sudo nano /etc/sysctl.conf
```

Add these lines:
```
kern.maxfiles=65536
kern.maxfilesperproc=65536
```

**Step 2: Increase user limit**

Add to `~/.zshrc`:
```bash
ulimit -n 65536
```

Then reload:
```bash
source ~/.zshrc
```

**Step 3: Verify**
```bash
ulimit -n
# Should show 65536
```

**Step 4: Install Watchman (helps with file watching)**
```bash
brew install watchman
```

**Step 5: Configure Metro to ignore unnecessary directories**

Already created `.watchmanconfig` in the mobile directory. This helps reduce the number of files being watched.

## Quick Fix Script

Run these commands in your terminal:

```bash
# 1. Set Java Home (adjust path if needed)
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "/Applications/Android Studio.app/Contents/jbr/Contents/Home")
export PATH=$JAVA_HOME/bin:$PATH

# 2. Increase file limit for current session
ulimit -n 65536

# 3. Verify
java -version
ulimit -n

# 4. Try running Android again
cd mobile
npm run android
```

## Permanent Fix

Add these to your `~/.zshrc` file:

```bash
# Java Configuration
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "/Applications/Android Studio.app/Contents/jbr/Contents/Home")
export PATH=$JAVA_HOME/bin:$PATH

# Increase file watcher limit
ulimit -n 65536

# Android SDK (if Android Studio is installed)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Then reload:
```bash
source ~/.zshrc
```

## Alternative: Use Android Studio's JDK

If you have Android Studio installed, you can use its bundled JDK:

1. Open Android Studio
2. Go to Preferences → Build, Execution, Deployment → Build Tools → Gradle
3. Note the JDK path (usually something like `/Applications/Android Studio.app/Contents/jbr/Contents/Home`)
4. Set it in your environment:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH=$JAVA_HOME/bin:$PATH
```

## After Fixing

Try running Android again:
```bash
cd mobile
npm start  # In one terminal
npm run android  # In another terminal
```

## Troubleshooting

**If Java still not found:**
- Make sure Java is installed: `which java`
- Check JAVA_HOME: `echo $JAVA_HOME`
- Verify Java version: `java -version`

**If file limit still an issue:**
- Check current limit: `ulimit -n`
- Restart terminal after adding to .zshrc
- Try reducing Metro's watch scope by adding more directories to `.watchmanconfig`

**If build still fails:**
- Clean build: `cd android && ./gradlew clean && cd ..`
- Clear Metro cache: `npm start -- --reset-cache`
- Reinstall node_modules: `rm -rf node_modules && npm install`

