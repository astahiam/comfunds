#!/bin/bash
# Fix "Too Many Open Files" Error on macOS

echo "🔧 Fixing file limit issues..."

# Get current limits
CURRENT_SOFT=$(ulimit -n)
CURRENT_HARD=$(ulimit -Hn)

echo "Current soft limit: $CURRENT_SOFT"
echo "Current hard limit: $CURRENT_HARD"

# Set higher limits for current session
ulimit -n 65536 2>/dev/null || {
    echo "⚠️  Could not set limit to 65536, trying 32768..."
    ulimit -n 32768 2>/dev/null || {
        echo "⚠️  Could not set limit to 32768, trying 16384..."
        ulimit -n 16384
    }
}

NEW_LIMIT=$(ulimit -n)
echo "✅ New limit: $NEW_LIMIT"

# Create launchd limit file (requires manual sudo)
echo ""
echo "📝 To make this permanent, run these commands:"
echo ""
echo "sudo sysctl -w kern.maxfiles=65536"
echo "sudo sysctl -w kern.maxfilesperproc=65536"
echo ""
echo "Then add to ~/.zshrc:"
echo "ulimit -n 65536"
echo ""

# Check if launchd limits can be set
if [ -w /Library/LaunchDaemons/limit.maxfiles.plist ]; then
    echo "✅ LaunchDaemon file exists and is writable"
else
    echo "📝 To create permanent system-wide limit, create:"
    echo "   /Library/LaunchDaemons/limit.maxfiles.plist"
    echo "   (See FIX_FILE_LIMIT.md for details)"
fi

echo ""
echo "✅ File limit increased for current session"
echo "   Run: source fix-file-limit.sh before npm run android"

