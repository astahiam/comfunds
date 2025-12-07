#!/bin/bash

# Direct Fix Uploads Permissions Script for Linux VPS
# Run this directly on your VPS: ./fix-uploads-permissions-vps-direct.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Change to sourcecode directory
cd ~/sourcecode || {
    print_error "Cannot find ~/sourcecode directory"
    exit 1
}

print_step "Creating uploads directory structure on Linux..."

# Create all required directories
mkdir -p uploads/documents/register
mkdir -p uploads/documents/user
mkdir -p uploads/images/business
mkdir -p uploads/images/project
mkdir -p logs

print_status "Directories created"

# Get current user (Linux)
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

print_info "Current user: $CURRENT_USER (UID: $CURRENT_UID, GID: $CURRENT_GID)"

# Try to get container user info
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(backend|hajifund)" | head -1 || echo "")
if [ -n "$CONTAINER_NAME" ]; then
    CONTAINER_UID=$(docker exec "$CONTAINER_NAME" id -u 2>/dev/null || echo "1000")
    CONTAINER_GID=$(docker exec "$CONTAINER_NAME" id -g 2>/dev/null || echo "1000")
    print_info "Container: $CONTAINER_NAME (UID: $CONTAINER_UID, GID: $CONTAINER_GID)"
else
    CONTAINER_UID="1000"
    CONTAINER_GID="1000"
    print_warning "Backend container not found, using default UID/GID: 1000"
fi

# Set ownership (Linux: prefer current user, fallback to container UID)
print_step "Setting ownership..."
if [ "$CURRENT_USER" != "root" ]; then
    chown -R $CURRENT_USER:$CURRENT_USER uploads logs 2>/dev/null || {
        print_warning "chown failed, trying with sudo..."
        sudo chown -R $CURRENT_USER:$CURRENT_USER uploads logs || {
            print_error "Failed to set ownership"
            exit 1
        }
    }
else
    # Root user - use container UID/GID
    chown -R $CONTAINER_UID:$CONTAINER_GID uploads logs 2>/dev/null || chown -R 1000:1000 uploads logs
fi

# Set permissions - Linux: 777 for Docker volume mounts (required for non-root containers)
print_step "Setting permissions (777 for Docker compatibility)..."
chmod -R 777 uploads 2>/dev/null || {
    print_warning "chmod failed, trying with sudo..."
    sudo chmod -R 777 uploads || {
        print_error "Failed to set permissions"
        exit 1
    }
}
chmod -R 755 logs 2>/dev/null || sudo chmod -R 755 logs 2>/dev/null || true

print_status "Permissions set successfully"

# Verify structure
print_status "Directory structure:"
find uploads -type d | sort

print_status "Permissions verification:"
ls -ld uploads uploads/documents uploads/documents/register uploads/images 2>/dev/null || true

# Test Docker container write access
if [ -n "$CONTAINER_NAME" ]; then
    print_step "Testing container write access..."
    if docker exec "$CONTAINER_NAME" touch /app/uploads/.test_write 2>/dev/null; then
        print_status "✅ Container can write to uploads directory"
        docker exec "$CONTAINER_NAME" rm -f /app/uploads/.test_write 2>/dev/null || true
    else
        print_error "❌ Container cannot write"
        print_info "Checking container user..."
        docker exec "$CONTAINER_NAME" id 2>/dev/null || true
        print_warning "You may need to restart the container"
    fi
fi

# Restart backend container
print_step "Restarting backend container..."
if command -v docker-compose &> /dev/null; then
    docker-compose restart backend 2>/dev/null || true
elif docker compose version &> /dev/null; then
    docker compose restart backend 2>/dev/null || true
else
    print_warning "Docker Compose not found, please restart manually"
fi

print_status "✅ Uploads permissions fixed!"
print_info "Directories ready:"
echo "  - uploads/documents/register (777)"
echo "  - uploads/documents/user (777)"
echo "  - uploads/images/business (777)"
echo "  - uploads/images/project (777)"
echo ""
print_info "You can now test registration. The permission error should be resolved."

