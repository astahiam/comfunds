#!/bin/bash
# Simple APK build script

echo "🔨 Building Hajifund APK..."
echo ""

cd "$(dirname "$0")"

# Check for Java 17
JAVA_17=$(/usr/libexec/java_home -v 17 2>/dev/null)
if [ -z "$JAVA_17" ]; then
    echo "❌ Java 17 not found!"
    echo ""
    echo "Please install Java 17 first:"
    echo "  1. Visit: https://adoptium.net/temurin/releases/?version=17"
    echo "  2. Download and install macOS version"
    echo "  3. Run this script again"
    echo ""
    echo "Or use Android Studio to build the APK:"
    echo "  1. Open Android Studio"
    echo "  2. Open: mobile/android folder"
    echo "  3. Build → Build APK(s)"
    exit 1
fi

export JAVA_HOME="$JAVA_17"
export PATH=$JAVA_HOME/bin:$PATH

echo "✅ Using Java 17: $JAVA_HOME"
java -version | head -1
echo ""

# Set Android SDK if available
if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/platform-tools
fi

# Increase file limit
ulimit -n 65536 2>/dev/null

# Build
cd android
echo "🧹 Cleaning..."
./gradlew clean > /dev/null 2>&1

echo "🔨 Building debug APK..."
./gradlew assembleDebug

if [ $? -eq 0 ]; then
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    if [ -f "$APK_PATH" ]; then
        echo ""
        echo "✅ APK built successfully!"
        echo ""
        echo "📱 APK Location:"
        echo "   $(pwd)/$APK_PATH"
        echo ""
        ls -lh "$APK_PATH" | awk '{print "📏 Size: " $5}'
        echo ""
        
        # Copy to root for easy access
        cp "$APK_PATH" "../hajifund-debug.apk"
        echo "📋 Also copied to:"
        echo "   $(pwd)/../hajifund-debug.apk"
        echo ""
        echo "📲 To install on your phone:"
        echo "   1. Copy hajifund-debug.apk to your phone"
        echo "   2. Enable 'Install from Unknown Sources'"
        echo "   3. Open APK and install"
    fi
else
    echo "❌ Build failed - check errors above"
    exit 1
fi
