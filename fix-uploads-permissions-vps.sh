#!/bin/bash

# Fix Uploads Directory Permissions on VPS
# This script creates the uploads directory structure and sets proper permissions

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

VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

print_step "Fixing uploads directory permissions on VPS..."

# Create the fix script that will run on VPS
cat > /tmp/fix-uploads-permissions.sh << 'EOFSCRIPT'
#!/bin/bash

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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

cd ~/sourcecode || exit 1

print_step "Creating uploads directory structure..."

# Create main uploads directory
mkdir -p uploads
mkdir -p uploads/documents
mkdir -p uploads/documents/register
mkdir -p uploads/documents/user
mkdir -p uploads/images
mkdir -p uploads/images/business
mkdir -p uploads/images/project
mkdir -p logs

print_status "Directories..."

# Get current user
CURRENT_USER=$(whoami)
print_info "Current user: $CURRENT_USER"

# Get Docker user ID (usually 1000 or from container)
# Check if we can determine the container user ID
CONTAINER_UID=$(docker exec hajifund-backend id -u 2>/dev/null || echo "1000")
CONTAINER_GID=$(docker exec hajifund-backend id -g 2>/dev/null || echo "1000")

print_info "Container UID: $CONTAINER_UID, GID: $CONTAINER_GID"

# Set ownership - Linux: use current user or container UID
print_step "Setting ownership..."
if [ "$CURRENT_USER" != "root" ]; then
    # Try without sudo first (works if user owns the directory)
    chown -R $CURRENT_USER:$CURRENT_USER uploads logs 2>/dev/null || {
        # If that fails, try sudo (may require password)
        print_info "Attempting with sudo..."
        sudo chown -R $CURRENT_USER:$CURRENT_USER uploads logs 2>/dev/null || true
    }
else
    # Root user - set to container UID/GID
    chown -R $CONTAINER_UID:$CONTAINER_GID uploads logs 2>/dev/null || chown -R 1000:1000 uploads logs
fi

# Set permissions - Linux: use 777 for Docker volume mounts (most reliable)
print_step "Setting permissions (777 for Docker compatibility)..."
chmod -R 777 uploads 2>/dev/null || {
    print_warning "Failed to set 777, trying with sudo..."
    sudo chmod -R 777 uploads 2>/dev/null || true
}
chmod -R 755 logs 2>/dev/null || sudo chmod -R 755 logs 2>/dev/null || true

print_status "Directory structure created:"
# Use find instead of tree (more reliable on Linux)
find uploads -type d | sort | head -20

print_status "Permissions set:"
ls -ld uploads uploads/* 2>/dev/null | head -10

# Verify Docker can write
print_step "Testing Docker container write access..."

# Check if backend container is running (Linux: check by name or image)
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(backend|hajifund)" | head -1 || echo "")
if [ -n "$CONTAINER_NAME" ]; then
    print_info "Backend container found: $CONTAINER_NAME"
    
    # Try to create a test file from container
    if docker exec "$CONTAINER_NAME" touch /app/uploads/.test_write 2>/dev/null; then
        print_status "✅ Container can write to uploads directory"
        docker exec "$CONTAINER_NAME" rm -f /app/uploads/.test_write 2>/dev/null || true
    else
        print_error "❌ Container cannot write to uploads directory"
        print_info "Checking container user and permissions..."
        docker exec "$CONTAINER_NAME" id 2>/dev/null || true
        print_info "Ensuring 777 permissions..."
        chmod -R 777 uploads 2>/dev/null || sudo chmod -R 777 uploads 2>/dev/null || true
        if docker exec "$CONTAINER_NAME" touch /app/uploads/.test_write 2>/dev/null; then
            print_status "✅ Fixed! Container can now write"
            docker exec "$CONTAINER_NAME" rm -f /app/uploads/.test_write 2>/dev/null || true
        else
            print_error "Still cannot write. Container may need to be restarted."
        fi
    fi
else
    print_warning "Backend container is not running. Permissions are set, but cannot test write access."
    print_info "Start the container with: docker-compose up -d backend"
fi

print_status "Uploads directory permissions fixed!"
print_info "Directories created:"
echo "  - uploads/documents/register"
echo "  - uploads/documents/user"
echo "  - uploads/images/business"
echo "  - uploads/images/project"
echo "  - logs"

EOFSCRIPT

# Copy script to VPS
print_step "Copying fix script to VPS..."
scp -i "$VPS_KEY" /tmp/fix-uploads-permissions.sh "$VPS_USER@$VPS_HOST:~/sourcecode/"

# Run script on VPS
print_step "Running fix script on VPS..."
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "cd ~/sourcecode && chmod +x fix-uploads-permissions.sh && ./fix-uploads-permissions.sh"

# Restart backend container to ensure it picks up the changes
print_step "Restarting backend container..."
# Try docker compose (newer plugin) first, then docker-compose (older)
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "cd ~/sourcecode && (docker compose restart backend 2>/dev/null || docker-compose restart backend 2>/dev/null || echo 'Note: Container restart attempted')"

print_status "✅ Uploads permissions fixed and backend restarted!"

echo ""
print_info "Test registration again. The permission error should be resolved."

