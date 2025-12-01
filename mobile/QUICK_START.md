# Quick Start Guide

## ✅ Issues Fixed!

1. **Java Runtime**: Using Android Studio's bundled JDK (Java 21)
2. **File Watcher Limit**: Increased to 65536
3. **Environment Setup**: Created `setup-env.sh` script

## How to Run Android App

### Option 1: Use the Setup Script (Recommended)

```bash
cd mobile
source setup-env.sh
npm run android
```

### Option 2: Manual Setup

The environment variables have been added to your `~/.zshrc`. Just reload your terminal:

```bash
source ~/.zshrc
cd mobile
npm run android
```

### Option 3: Run Setup Script Each Time

```bash
cd mobile
source setup-env.sh
npm run android
```

## What Was Fixed

✅ **Java Runtime**: Configured to use Android Studio's JDK (Java 21)  
✅ **File Watcher Limit**: Increased from default to 65536  
✅ **Watchman Config**: Created `.watchmanconfig` to ignore unnecessary directories  
✅ **Environment Variables**: Added to `~/.zshrc` for persistence  

## Verify Setup

Run this to check everything is configured:

```bash
cd mobile
source setup-env.sh
```

You should see:
- ✅ Using Android Studio JDK
- ✅ Android SDK configured  
- ✅ File Limit: 65536
- ✅ Java version displayed

## Running the App

1. **Start Metro Bundler** (Terminal 1):
   ```bash
   cd mobile
   npm start
   ```

2. **Run Android** (Terminal 2):
   ```bash
   cd mobile
   source setup-env.sh  # Only needed first time or if not in .zshrc
   npm run android
   ```

## Troubleshooting

**If Java still not found:**
```bash
source ~/.zshrc
java -version  # Should show Java 21
```

**If file limit still an issue:**
```bash
ulimit -n  # Should show 65536
```

**If build fails:**
```bash
cd android
./gradlew clean
cd ..
npm run android
```

## Next Steps

1. Make sure Android emulator is running OR device is connected
2. Run `npm run android`
3. The app should build and launch!

