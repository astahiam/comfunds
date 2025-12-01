#!/bin/bash
# Development startup script with file limit fix

echo "🚀 Starting Hajifund Mobile Development Environment..."

# Increase file limit
ulimit -n 65536
echo "✅ File limit set to: $(ulimit -n)"

# Load environment
if [ -f "./setup-env.sh" ]; then
    source ./setup-env.sh
fi

# Start Metro bundler
echo "📦 Starting Metro bundler..."
npm start

