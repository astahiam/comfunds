# Immediate Fix for "Too Many Open Files"

## ✅ Already Fixed in package.json!

The npm scripts now automatically set the file limit. Just run:

```bash
npm start
# or
npm run android
```

The `ulimit -n 65536` command is now built into the scripts!

## If Still Having Issues

### Quick Fix (Run Before npm start):

```bash
cd mobile
ulimit -n 65536
npm start
```

### Permanent Fix (One-Time Setup):

**Option 1: Install LaunchDaemon (Recommended)**

```bash
cd mobile
./install-file-limit-fix.sh
```

This will:
- Create system-wide file limit configuration
- Set kernel parameters
- Add ulimit to your ~/.zshrc
- Make the fix permanent

**Option 2: Manual Setup**

1. Copy LaunchDaemon file:
```bash
sudo cp limit.maxfiles.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chmod 644 /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
```

2. Set kernel parameters:
```bash
sudo sysctl -w kern.maxfiles=65536
sudo sysctl -w kern.maxfilesperproc=65536
```

3. Add to ~/.zshrc:
```bash
echo "ulimit -n 65536" >> ~/.zshrc
source ~/.zshrc
```

## Verify Fix

```bash
# Check current limit
ulimit -n
# Should show 65536

# Check system limit
launchctl limit maxfiles
# Should show: maxfiles    65536           200000
```

## What Was Changed

1. ✅ **package.json scripts** - Now include `ulimit -n 65536`
2. ✅ **metro.config.js** - Optimized to reduce file watching
3. ✅ **.watchmanconfig** - Ignores more directories
4. ✅ **LaunchDaemon file** - Created for permanent fix

## Try Now

```bash
cd mobile
npm start
```

Should work without EMFILE errors! 🎉

