#!/bin/bash

# Fix Frontend Dockerfile Location
# Run this on VPS

set -e

cd ~/sourcecode

echo "Fixing frontend Dockerfile location..."

# Copy Dockerfile.frontend to frontend directory if it exists in root
if [ -f "Dockerfile.frontend" ] && [ ! -f "frontend/Dockerfile.frontend" ]; then
    cp Dockerfile.frontend frontend/Dockerfile.frontend
    echo "✅ Copied Dockerfile.frontend to frontend directory"
elif [ -f "frontend/Dockerfile.frontend" ]; then
    echo "✅ Frontend Dockerfile already in correct location"
else
    echo "⚠️  Dockerfile.frontend not found. Please copy it manually."
fi

# Verify
if [ -f "frontend/Dockerfile.frontend" ]; then
    echo "✅ Frontend Dockerfile is ready"
    echo "You can now run: docker-compose build"
else
    echo "❌ Frontend Dockerfile still missing"
    exit 1
fi

