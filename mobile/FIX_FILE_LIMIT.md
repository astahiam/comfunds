# Fix "Too Many Open Files" Error - Complete Guide

## Quick Fix (Temporary - Current Session Only)

Run this before starting Metro/Android:

```bash
cd mobile
ulimit -n 65536
npm start
# In another terminal:
npm run android
```

Or use the script:
```bash
cd mobile
source fix-file-limit.sh
npm run android
```

## Permanent Fix Options

### Option 1: System-Wide Limit (Recommended - Requires Sudo)

**Step 1: Create LaunchDaemon file**

Create `/Library/LaunchDaemons/limit.maxfiles.plist`:

```bash
sudo nano /Library/LaunchDaemons/limit.maxfiles.plist
```

Add this content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>65536</string>
      <string>200000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
```

**Step 2: Set permissions and load**

```bash
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chmod 644 /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
```

**Step 3: Set kernel parameters**

```bash
sudo sysctl -w kern.maxfiles=65536
sudo sysctl -w kern.maxfilesperproc=65536
```

**Step 4: Add to ~/.zshrc**

```bash
ulimit -n 65536
```

Then reload:
```bash
source ~/.zshrc
```

### Option 2: User-Level Limit (No Sudo Required)

**Add to ~/.zshrc:**

```bash
# Increase file descriptor limit
ulimit -n 65536

# If that doesn't work, try:
ulimit -S -n 65536
ulimit -H -n 65536
```

Then reload:
```bash
source ~/.zshrc
```

### Option 3: Per-Session Script

Create a script that you run before development:

```bash
#!/bin/bash
# Run this before npm start or npm run android
ulimit -n 65536
export NODE_OPTIONS="--max-old-space-size=4096"
```

## Optimize Metro Bundler

Already configured in `metro.config.js` to ignore unnecessary directories.

## Reduce File Watching

The `.watchmanconfig` file has been updated to ignore:
- `node_modules`
- `android` folder
- `ios` folder  
- Build directories
- Git directories

## Alternative: Use Watchman

Install watchman (better file watching):

```bash
brew install watchman
```

Then restart Metro:
```bash
npm start -- --reset-cache
```

## Verify Fix

Check current limit:
```bash
ulimit -n
# Should show 65536 or higher
```

Check system limits:
```bash
launchctl limit maxfiles
# Should show: maxfiles    65536           200000
```

## If Still Having Issues

1. **Reduce Metro's watch scope:**
   - Close other applications
   - Close other Metro instances
   - Restart computer

2. **Use Watchman:**
   ```bash
   brew install watchman
   watchman watch-del-all
   npm start -- --reset-cache
   ```

3. **Clean everything:**
   ```bash
   cd mobile
   rm -rf node_modules
   npm install
   cd android && ./gradlew clean && cd ..
   npm start -- --reset-cache
   ```

4. **Check for other processes:**
   ```bash
   lsof | wc -l
   # If this is very high, close some applications
   ```

## Quick Test

After applying fixes:

```bash
cd mobile
ulimit -n 65536
npm start
# Should start without EMFILE errors
```

## Summary

**For immediate fix (each session):**
```bash
ulimit -n 65536
```

**For permanent fix:**
1. Create LaunchDaemon file (see Option 1)
2. Add `ulimit -n 65536` to `~/.zshrc`
3. Reboot or restart terminal

The Metro config and Watchman config have been optimized to reduce file watching overhead.

