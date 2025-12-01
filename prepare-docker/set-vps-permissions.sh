#!/bin/bash

# Set VPS Permissions Script
# This script sets the correct permissions on Ubuntu VPS to match the expected deployment
# Ensures proper ownership and permissions for the HajiFund application

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

print_step "Setting VPS permissions for HajiFund application"

# Configuration
PROJECT_DIR="/var/www/hajifund"
BACKEND_DIR="$PROJECT_DIR"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd $PROJECT_DIR

# 1. Create www-data user and group if they don't exist
print_step "1. Ensuring www-data user and group exist..."

# Check if www-data user exists
if ! id "www-data" &>/dev/null; then
    print_info "Creating www-data user..."
    useradd -r -s /bin/false -d /var/www -c "Web Server" www-data
fi

# Check if www-data group exists
if ! getent group www-data > /dev/null 2>&1; then
    print_info "Creating www-data group..."
    groupadd www-data
fi

print_status "www-data user and group ready"

# 2. Set ownership to www-data:www-data
print_step "2. Setting ownership to www-data:www-data..."

chown -R www-data:www-data $PROJECT_DIR

print_status "Ownership set to www-data:www-data"

# 3. Set directory permissions (755)
print_step "3. Setting directory permissions (755)..."

# All directories
find $PROJECT_DIR -type d -exec chmod 755 {} \;

print_status "Directory permissions set to 755"

# 4. Set file permissions (644)
print_step "4. Setting file permissions (644)..."

# All regular files
find $PROJECT_DIR -type f -exec chmod 644 {} \;

print_status "File permissions set to 644"

# 5. Set executable permissions for shell scripts
print_step "5. Setting executable permissions for shell scripts..."

# Find and make all .sh files executable
find $PROJECT_DIR -name "*.sh" -type f -exec chmod +x {} \;

print_status "Shell scripts made executable"

# 6. Set Go binary permissions
print_step "6. Setting Go binary permissions..."

# Backend binary
if [ -f "$BACKEND_DIR/hajifund-backend" ]; then
    chmod +x $BACKEND_DIR/hajifund-backend
    chown www-data:www-data $BACKEND_DIR/hajifund-backend
    print_status "Backend binary permissions set"
fi

# Frontend binary
if [ -f "$FRONTEND_DIR/hajifund-frontend" ]; then
    chmod +x $FRONTEND_DIR/hajifund-frontend
    chown www-data:www-data $FRONTEND_DIR/hajifund-frontend
    print_status "Frontend binary permissions set"
fi

# 7. Set special permissions for sensitive files
print_step "7. Setting special permissions for sensitive files..."

# Environment files (600 - read/write for owner only)
find $PROJECT_DIR -name ".env" -type f -exec chmod 600 {} \;
find $PROJECT_DIR -name "*.env" -type f -exec chmod 600 {} \;

# SSH keys (600)
find $PROJECT_DIR -name "*.pem" -type f -exec chmod 600 {} \;
find $PROJECT_DIR -name "*.key" -type f -exec chmod 600 {} \;

# Log files (644)
find $PROJECT_DIR -name "*.log" -type f -exec chmod 644 {} \;

print_status "Special file permissions set"

# 8. Create upload and log directories with proper permissions
print_step "8. Creating upload and log directories..."

# Create directories if they don't exist
mkdir -p $PROJECT_DIR/uploads
mkdir -p $FRONTEND_DIR/uploads
mkdir -p $PROJECT_DIR/logs
mkdir -p $FRONTEND_DIR/logs

# Set permissions for directories
chmod 755 $PROJECT_DIR/uploads
chmod 755 $FRONTEND_DIR/uploads
chmod 755 $PROJECT_DIR/logs
chmod 755 $FRONTEND_DIR/logs

# Set ownership for directories
chown www-data:www-data $PROJECT_DIR/uploads
chown www-data:www-data $FRONTEND_DIR/uploads
chown www-data:www-data $PROJECT_DIR/logs
chown www-data:www-data $FRONTEND_DIR/logs

print_status "Upload and log directories created with proper permissions"

# 9. Set special permissions for systemd service files
print_step "9. Setting systemd service file permissions..."

# Systemd service files
if [ -f "/etc/systemd/system/hajifund-backend.service" ]; then
    chmod 644 /etc/systemd/system/hajifund-backend.service
    chown root:root /etc/systemd/system/hajifund-backend.service
    print_status "Backend systemd service permissions set"
fi

if [ -f "/etc/systemd/system/hajifund-frontend.service" ]; then
    chmod 644 /etc/systemd/system/hajifund-frontend.service
    chown root:root /etc/systemd/system/hajifund-frontend.service
    print_status "Frontend systemd service permissions set"
fi

# 10. Set permissions for Docker files (if using Docker)
print_step "10. Setting Docker file permissions..."

if [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
    chmod 644 $PROJECT_DIR/docker-compose.yml
    chown www-data:www-data $PROJECT_DIR/docker-compose.yml
    print_status "Docker Compose file permissions set"
fi

# Docker directory
if [ -d "$PROJECT_DIR/docker" ]; then
    chown -R www-data:www-data $PROJECT_DIR/docker
    find $PROJECT_DIR/docker -type d -exec chmod 755 {} \;
    find $PROJECT_DIR/docker -type f -exec chmod 644 {} \;
    find $PROJECT_DIR/docker -name "*.sh" -type f -exec chmod +x {} \;
    print_status "Docker directory permissions set"
fi

# 11. Verify permissions
print_step "11. Verifying permissions..."

print_info "Project directory permissions:"
ls -la $PROJECT_DIR | head -10

print_info "Shell script permissions:"
find $PROJECT_DIR -name "*.sh" -type f -exec ls -la {} \;

print_info "Environment file permissions:"
find $PROJECT_DIR -name "*.env" -type f -exec ls -la {} \;

print_info "Go binary permissions:"
ls -la $BACKEND_DIR/hajifund-backend 2>/dev/null || echo "Backend binary not found"
ls -la $FRONTEND_DIR/hajifund-frontend 2>/dev/null || echo "Frontend binary not found"

# 12. Create a permission summary
print_step "12. Creating permission summary..."

cat > $PROJECT_DIR/permission-summary.txt << EOF
HajiFund VPS Permissions Summary
================================

Directory Structure:
- Project Root: $PROJECT_DIR
- Backend: $BACKEND_DIR
- Frontend: $FRONTEND_DIR

Permissions Applied:
- Directories: 755 (rwxr-xr-x)
- Regular Files: 644 (rw-r--r--)
- Shell Scripts: 755 (rwxr-xr-x)
- Environment Files: 600 (rw-------)
- SSH Keys: 600 (rw-------)
- Go Binaries: 755 (rwxr-xr-x)
- Systemd Services: 644 (rw-r--r--)

Ownership:
- Application Files: www-data:www-data
- Systemd Services: root:root
- System Files: root:root

Special Directories:
- $PROJECT_DIR/uploads/
- $FRONTEND_DIR/uploads/
- $PROJECT_DIR/logs/
- $FRONTEND_DIR/logs/

This matches the expected permissions for Ubuntu VPS deployment:
- www-data:www-data ownership for application files
- 755 for directories
- 644 for files
- 600 for sensitive files
- 755 for executables
- root:root for system files
EOF

print_status "Permission summary created: $PROJECT_DIR/permission-summary.txt"

print_status "VPS permissions set successfully!"

print_info "Summary:"
print_info "  - All directories: 755"
print_info "  - All files: 644"
print_info "  - Shell scripts: 755"
print_info "  - Environment files: 600"
print_info "  - Go binaries: 755"
print_info "  - Application ownership: www-data:www-data"
print_info "  - System files ownership: root:root"

print_warning "Note: This sets the correct permissions for Ubuntu VPS deployment"
print_warning "Make sure to restart systemd services after permission changes:"
print_warning "  sudo systemctl daemon-reload"
print_warning "  sudo systemctl restart hajifund-backend hajifund-frontend"
