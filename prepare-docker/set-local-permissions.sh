#!/bin/bash

# Set Local Permissions Script
# This script sets the same permissions on Mac local files as they would have on Ubuntu VPS
# Ensures consistency between local development and VPS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}==> $1${NC}"
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step "Setting local permissions to match Ubuntu VPS"

# Configuration
PROJECT_ROOT="/Users/alkha/Documents/project/comfunds"
BACKEND_DIR="$PROJECT_ROOT"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
PREPARE_DOCKER_DIR="$PROJECT_ROOT/prepare-docker"

# Check if we're in the right directory
if [ ! -d "$PROJECT_ROOT" ]; then
    print_error "Project root not found: $PROJECT_ROOT"
    exit 1
fi

cd $PROJECT_ROOT

# 1. Set directory permissions (755)
print_step "1. Setting directory permissions (755)..."

# Main project directories
find . -type d -exec chmod 755 {} \;

# Specific important directories
chmod 755 .
chmod 755 frontend
chmod 755 prepare-docker
chmod 755 prepare-docker/docker
chmod 755 prepare-docker/docker/nginx
chmod 755 prepare-docker/docker/postgres

print_status "Directory permissions set to 755"

# 2. Set file permissions (644)
print_step "2. Setting file permissions (644)..."

# All regular files
find . -type f -exec chmod 644 {} \;

print_status "File permissions set to 644"

# 3. Set executable permissions for shell scripts
print_step "3. Setting executable permissions for shell scripts..."

# Find and make all .sh files executable
find . -name "*.sh" -type f -exec chmod +x {} \;

# Specific important scripts
chmod +x prepare-docker/docker/postgres/init-multiple-databases.sh
chmod +x prepare-docker/docker-deploy-complete.sh
chmod +x prepare-docker/copy-to-vps.sh
chmod +x prepare-docker/fix-golang-systemd.sh
chmod +x prepare-docker/copy-fix-to-vps.sh

print_status "Shell scripts made executable"

# 4. Set Go binary permissions (if they exist)
print_step "4. Setting Go binary permissions..."

# Backend binary
if [ -f "hajifund-backend" ]; then
    chmod +x hajifund-backend
    print_status "Backend binary permissions set"
fi

# Frontend binary
if [ -f "frontend/hajifund-frontend" ]; then
    chmod +x frontend/hajifund-frontend
    print_status "Frontend binary permissions set"
fi

# 5. Set special permissions for sensitive files
print_step "5. Setting special permissions for sensitive files..."

# Environment files (600 - read/write for owner only)
find . -name ".env" -type f -exec chmod 600 {} \;
find . -name "*.env" -type f -exec chmod 600 {} \;

# SSH keys (600)
find . -name "*.pem" -type f -exec chmod 600 {} \;
find . -name "*.key" -type f -exec chmod 600 {} \;

# Log files (644)
find . -name "*.log" -type f -exec chmod 644 {} \;

print_status "Special file permissions set"

# 6. Create upload and log directories with proper permissions
print_step "6. Creating upload and log directories..."

# Create directories if they don't exist
mkdir -p uploads
mkdir -p frontend/uploads
mkdir -p logs
mkdir -p frontend/logs
mkdir -p prepare-docker/docker/nginx/ssl
mkdir -p prepare-docker/docker/nginx/letsencrypt

# Set permissions for directories
chmod 755 uploads
chmod 755 frontend/uploads
chmod 755 logs
chmod 755 frontend/logs
chmod 755 prepare-docker/docker/nginx/ssl
chmod 755 prepare-docker/docker/nginx/letsencrypt

print_status "Upload and log directories created with proper permissions"

# 7. Set ownership (simulate www-data:www-data on Ubuntu)
print_step "7. Setting ownership (simulating www-data:www-data)..."

# On Mac, we'll use the current user as the equivalent of www-data
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)

# Set ownership for all files and directories
chown -R $CURRENT_USER:$CURRENT_GROUP .

print_status "Ownership set to $CURRENT_USER:$CURRENT_GROUP"

# 8. Verify permissions
print_step "8. Verifying permissions..."

print_info "Directory permissions:"
ls -la | head -10

print_info "Shell script permissions:"
find . -name "*.sh" -type f -exec ls -la {} \;

print_info "Environment file permissions:"
find . -name "*.env" -type f -exec ls -la {} \;

print_info "Go binary permissions:"
ls -la hajifund-backend 2>/dev/null || echo "Backend binary not found"
ls -la frontend/hajifund-frontend 2>/dev/null || echo "Frontend binary not found"

# 9. Create a permission summary
print_step "9. Creating permission summary..."

cat > permission-summary.txt << EOF
HajiFund Local Permissions Summary
==================================

Directory Structure:
- Project Root: $PROJECT_ROOT
- Backend: $BACKEND_DIR
- Frontend: $FRONTEND_DIR
- Docker Files: $PREPARE_DOCKER_DIR

Permissions Applied:
- Directories: 755 (rwxr-xr-x)
- Regular Files: 644 (rw-r--r--)
- Shell Scripts: 755 (rwxr-xr-x)
- Environment Files: 600 (rw-------)
- SSH Keys: 600 (rw-------)
- Go Binaries: 755 (rwxr-xr-x)

Ownership:
- User: $CURRENT_USER
- Group: $CURRENT_GROUP

Special Directories Created:
- uploads/
- frontend/uploads/
- logs/
- frontend/logs/
- prepare-docker/docker/nginx/ssl/
- prepare-docker/docker/nginx/letsencrypt/

This matches the expected permissions on Ubuntu VPS where:
- www-data:www-data ownership
- 755 for directories
- 644 for files
- 600 for sensitive files
- 755 for executables
EOF

print_status "Permission summary created: permission-summary.txt"

print_status "Local permissions set successfully!"

print_info "Summary:"
print_info "  - All directories: 755"
print_info "  - All files: 644"
print_info "  - Shell scripts: 755"
print_info "  - Environment files: 600"
print_info "  - Go binaries: 755"
print_info "  - Ownership: $CURRENT_USER:$CURRENT_GROUP"

print_warning "Note: This simulates Ubuntu VPS permissions on macOS"
print_warning "On the actual VPS, ownership will be www-data:www-data"
