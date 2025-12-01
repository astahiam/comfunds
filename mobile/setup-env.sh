#!/bin/bash
# Environment Setup Script for Hajifund Mobile Development

echo "Setting up development environment..."

# Java Configuration
if [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    echo "✅ Using Android Studio JDK: $JAVA_HOME"
elif [ -d "$(brew --prefix)/opt/openjdk@17" ]; then
    export JAVA_HOME="$(brew --prefix)/opt/openjdk@17"
    echo "✅ Using Homebrew OpenJDK 17: $JAVA_HOME"
else
    JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)
    if [ -n "$JAVA_HOME" ]; then
        export JAVA_HOME
        echo "✅ Using system JDK: $JAVA_HOME"
    else
        echo "⚠️  Java JDK not found. Please install JDK 17."
        echo "   Visit: https://adoptium.net/"
    fi
fi

export PATH=$JAVA_HOME/bin:$PATH

# Increase file watcher limit
ulimit -n 65536 2>/dev/null || echo "⚠️  Could not increase file limit (may need sudo)"

# Android SDK
if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/emulator
    export PATH=$PATH:$ANDROID_HOME/platform-tools
    export PATH=$PATH:$ANDROID_HOME/tools
    export PATH=$PATH:$ANDROID_HOME/tools/bin
    echo "✅ Android SDK configured"
fi

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && echo "✅ NVM loaded"

echo ""
echo "Environment Summary:"
echo "==================="
echo "Java: $(java -version 2>&1 | head -1)"
echo "File Limit: $(ulimit -n)"
echo "JAVA_HOME: $JAVA_HOME"
echo "ANDROID_HOME: $ANDROID_HOME"
echo ""

echo "✅ Setup complete! You can now run: npm run android"

