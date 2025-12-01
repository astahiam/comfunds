#!/bin/bash
# Build APK for Hajifund Mobile App

echo "🔨 Building Hajifund APK..."
echo ""

cd "$(dirname "$0")"

# Check disk space (need at least 5GB free for Android builds)
AVAILABLE_SPACE=$(df -k . | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -lt 5242880 ]; then  # 5GB in KB
    echo "⚠️  Warning: Low disk space detected ($(df -h . | tail -1 | awk '{print $4}') available)"
    echo "   Android builds require at least 5GB free space"
    echo "   Consider freeing up space or the build may fail"
    echo ""
fi

# Set Java environment - Try Java 17 first (required for Gradle 8.0.1)
JAVA_17=$(/usr/libexec/java_home -v 17 2>/dev/null)
if [ -n "$JAVA_17" ]; then
    export JAVA_HOME="$JAVA_17"
    export PATH=$JAVA_HOME/bin:$PATH
    echo "✅ Using Java 17: $JAVA_HOME"
    java -version | head -1
else
    echo "❌ Java 17 not found!"
    echo ""
    echo "Please install Java 17:"
    echo "  1. Visit: https://adoptium.net/temurin/releases/?version=17"
    echo "  2. Download and install macOS version"
    echo "  3. Then run this script again"
    echo ""
    echo "Or set JAVA_HOME manually:"
    echo "  export JAVA_HOME=/path/to/java17"
    echo "  export PATH=\$JAVA_HOME/bin:\$PATH"
    exit 1
fi

# Set Android SDK if available
if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/platform-tools
    echo "✅ Android SDK configured"
fi

# Ensure Node.js is in PATH (required for Gradle builds)
if command -v node &> /dev/null; then
    NODE_PATH=$(which node | sed 's|/node$||')
    export PATH=$NODE_PATH:$PATH
    echo "✅ Node.js configured: $(node --version)"
else
    # Try to find Node.js via nvm
    if [ -f "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if command -v node &> /dev/null; then
            NODE_PATH=$(which node | sed 's|/node$||')
            export PATH=$NODE_PATH:$PATH
            echo "✅ Node.js configured via nvm: $(node --version)"
        else
            echo "❌ Node.js not found!"
            echo "Please ensure Node.js is installed and available"
            exit 1
        fi
    else
        echo "❌ Node.js not found!"
        echo "Please install Node.js or ensure it's in PATH"
        exit 1
    fi
fi

# Verify Node.js is accessible
if ! command -v node &> /dev/null; then
    echo "❌ Node.js verification failed!"
    exit 1
fi

# Increase file limit
ulimit -n 65536 2>/dev/null

# Build the APK
echo ""
echo "📦 Building release APK..."
cd android

# Stop any running Gradle daemons to ensure fresh environment
echo "🛑 Stopping Gradle daemons..."
./gradlew --stop 2>/dev/null || true

# Export Node.js path for Gradle (React Native Gradle plugin needs this)
export NODE_BINARY=$(which node)
NODE_DIR=$(dirname "$NODE_BINARY")
export PATH="$NODE_DIR:$PATH"
echo "🔧 Node.js binary: $NODE_BINARY"
echo "🔧 Node.js directory: $NODE_DIR"

# Create/update local.properties if Android Studio SDK is available
if [ -d "$HOME/Library/Android/sdk" ]; then
    if [ ! -f "local.properties" ] || ! grep -q "sdk.dir" local.properties 2>/dev/null; then
        echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties
        echo "✅ Created local.properties with Android SDK path"
    fi
fi

# Create a local node symlink in android directory so Gradle can find it
# This is needed because Gradle runs in a separate JVM and doesn't inherit PATH properly
if [ ! -f "node" ] || [ ! -L "node" ]; then
    ln -sf "$NODE_BINARY" node 2>/dev/null || cp "$NODE_BINARY" node 2>/dev/null || true
    echo "🔧 Created local node binary link for Gradle"
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
# Pass Node.js path to Gradle via environment variables
# Also add current directory to PATH so local node binary can be found
env NODE_BINARY="$NODE_BINARY" PATH="$(pwd):$NODE_DIR:$PATH" ./gradlew clean --no-daemon

# Build debug APK (easier, no signing required)
echo ""
echo "🔨 Building debug APK..."
# Ensure Node.js is in PATH for Gradle processes
# Add current directory first so local node symlink takes precedence
env NODE_BINARY="$NODE_BINARY" PATH="$(pwd):$NODE_DIR:$PATH" ./gradlew assembleDebug --no-daemon

if [ $? -eq 0 ]; then
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    if [ -f "$APK_PATH" ]; then
        echo ""
        echo "✅ APK built successfully!"
        echo ""
        echo "📱 APK Location:"
        echo "   $(pwd)/$APK_PATH"
        echo ""
        echo "📏 APK Size:"
        ls -lh "$APK_PATH" | awk '{print "   " $5}'
        echo ""
        echo "📲 To install on your phone:"
        echo "   1. Copy the APK to your phone via USB or cloud storage"
        echo "   2. Enable 'Install from Unknown Sources' in phone settings"
        echo "   3. Open the APK file on your phone and install"
        echo ""
        echo "💡 Or use ADB to install directly:"
        echo "   adb install $APK_PATH"
        echo ""
        # Copy APK to mobile root for easy access
        cp "$APK_PATH" "../hajifund-debug.apk"
        echo "📋 APK also copied to:"
        echo "   $(pwd)/../hajifund-debug.apk"
        echo ""
        
    else
        echo "❌ APK file not found at expected location"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi

