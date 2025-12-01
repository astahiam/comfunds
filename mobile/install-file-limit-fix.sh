#!/bin/bash
# Install permanent file limit fix (requires sudo)

echo "🔧 Installing permanent file limit fix..."
echo "⚠️  This requires sudo access"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Don't run this script as root/sudo"
    echo "   It will prompt for password when needed"
    exit 1
fi

# Create LaunchDaemon file
echo "📝 Creating LaunchDaemon configuration..."
sudo cp limit.maxfiles.plist /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chmod 644 /Library/LaunchDaemons/limit.maxfiles.plist

# Load the LaunchDaemon
echo "📦 Loading LaunchDaemon..."
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist

# Set kernel parameters
echo "⚙️  Setting kernel parameters..."
sudo sysctl -w kern.maxfiles=65536
sudo sysctl -w kern.maxfilesperproc=65536

# Add to ~/.zshrc if not already there
if ! grep -q "ulimit -n 65536" ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# Hajifund Mobile - File limit fix" >> ~/.zshrc
    echo "ulimit -n 65536" >> ~/.zshrc
    echo "✅ Added ulimit to ~/.zshrc"
else
    echo "✅ ulimit already in ~/.zshrc"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo "   2. Verify: launchctl limit maxfiles"
echo "   3. Should show: maxfiles    65536           200000"
echo ""
echo "🚀 You can now run: npm run android"

