#!/bin/bash

# Sync Permissions to VPS Script
# This script copies the permission structure from local Mac to Ubuntu VPS
# Ensures VPS follows the same permissions as the local development environment

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

print_step "Syncing permissions from local Mac to VPS"

# Configuration
VPS_IP="103.103.20.68"
VPS_USER="ryankharisma"
VPS_SSH_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"
LOCAL_PROJECT_ROOT="/Users/alkha/Documents/project/comfunds"

# Check if SSH key exists
if [ ! -f "$VPS_SSH_KEY" ]; then
    print_error "SSH key not found: $VPS_SSH_KEY"
    exit 1
fi

# Check if local project exists
if [ ! -d "$LOCAL_PROJECT_ROOT" ]; then
    print_error "Local project not found: $LOCAL_PROJECT_ROOT"
    exit 1
fi

# 1. First, set local permissions as reference
print_step "1. Setting local permissions as reference..."

cd $LOCAL_PROJECT_ROOT

# Set local permissions to match what we want on VPS
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;
find . -name ".env" -type f -exec chmod 600 {} \;
find . -name "*.env" -type f -exec chmod 600 {} \;
find . -name "*.pem" -type f -exec chmod 600 {} \;
find . -name "*.key" -type f -exec chmod 600 {} \;

# Set Go binaries if they exist
if [ -f "hajifund-backend" ]; then
    chmod +x hajifund-backend
fi
if [ -f "frontend/hajifund-frontend" ]; then
    chmod +x frontend/hajifund-frontend
fi

print_status "Local permissions set as reference"

# 2. Create permission mapping file
print_step "2. Creating permission mapping file..."

cat > permission-mapping.txt << EOF
# Permission mapping from local to VPS
# This file contains the permission structure to apply on VPS

# Directories: 755
$(find . -type d | sed 's/^/DIR:/')

# Files: 644
$(find . -type f | sed 's/^/FILE:/')

# Executable files: 755
$(find . -name "*.sh" -type f | sed 's/^/EXEC:/')
$(find . -name "hajifund-backend" -type f | sed 's/^/EXEC:/')
$(find . -name "hajifund-frontend" -type f | sed 's/^/EXEC:/')

# Sensitive files: 600
$(find . -name ".env" -type f | sed 's/^/SENSITIVE:/')
$(find . -name "*.env" -type f | sed 's/^/SENSITIVE:/')
$(find . -name "*.pem" -type f | sed 's/^/SENSITIVE:/')
$(find . -name "*.key" -type f | sed 's/^/SENSITIVE:/')
EOF

print_status "Permission mapping file created"

# 3. Copy permission mapping to VPS
print_step "3. Copying permission mapping to VPS..."

scp -i $VPS_SSH_KEY permission-mapping.txt $VPS_USER@$VPS_IP:~/

print_status "Permission mapping copied to VPS"

# 4. Create VPS permission application script
print_step "4. Creating VPS permission application script..."

cat > apply-vps-permissions.sh << 'EOF'
#!/bin/bash

# Apply VPS Permissions Script
# This script applies the same permissions from local Mac to Ubuntu VPS

set -e

# Colors
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

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step "Applying permissions from local Mac to VPS"

# Configuration
PROJECT_DIR="/var/www/hajifund"
MAPPING_FILE="~/permission-mapping.txt"

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

# 1. Set basic permissions first
print_step "1. Setting basic permissions..."

# All directories to 755
find $PROJECT_DIR -type d -exec chmod 755 {} \;

# All files to 644
find $PROJECT_DIR -type f -exec chmod 644 {} \;

print_status "Basic permissions set"

# 2. Set executable permissions
print_step "2. Setting executable permissions..."

# Shell scripts
find $PROJECT_DIR -name "*.sh" -type f -exec chmod +x {} \;

# Go binaries
if [ -f "$PROJECT_DIR/hajifund-backend" ]; then
    chmod +x $PROJECT_DIR/hajifund-backend
fi
if [ -f "$PROJECT_DIR/frontend/hajifund-frontend" ]; then
    chmod +x $PROJECT_DIR/frontend/hajifund-frontend
fi

print_status "Executable permissions set"

# 3. Set sensitive file permissions
print_step "3. Setting sensitive file permissions..."

# Environment files
find $PROJECT_DIR -name ".env" -type f -exec chmod 600 {} \;
find $PROJECT_DIR -name "*.env" -type f -exec chmod 600 {} \;

# SSH keys
find $PROJECT_DIR -name "*.pem" -type f -exec chmod 600 {} \;
find $PROJECT_DIR -name "*.key" -type f -exec chmod 600 {} \;

print_status "Sensitive file permissions set"

# 4. Set ownership to www-data:www-data
print_step "4. Setting ownership to www-data:www-data..."

# Ensure www-data user exists
if ! id "www-data" &>/dev/null; then
    useradd -r -s /bin/false -d /var/www -c "Web Server" www-data
fi

# Set ownership
chown -R www-data:www-data $PROJECT_DIR

print_status "Ownership set to www-data:www-data"

# 5. Create necessary directories
print_step "5. Creating necessary directories..."

mkdir -p $PROJECT_DIR/uploads
mkdir -p $PROJECT_DIR/frontend/uploads
mkdir -p $PROJECT_DIR/logs
mkdir -p $PROJECT_DIR/frontend/logs

# Set permissions for new directories
chmod 755 $PROJECT_DIR/uploads
chmod 755 $PROJECT_DIR/frontend/uploads
chmod 755 $PROJECT_DIR/logs
chmod 755 $PROJECT_DIR/frontend/logs

# Set ownership for new directories
chown www-data:www-data $PROJECT_DIR/uploads
chown www-data:www-data $PROJECT_DIR/frontend/uploads
chown www-data:www-data $PROJECT_DIR/logs
chown www-data:www-data $PROJECT_DIR/frontend/logs

print_status "Necessary directories created"

# 6. Verify permissions
print_step "6. Verifying permissions..."

print_info "Project directory permissions:"
ls -la $PROJECT_DIR | head -10

print_info "Shell script permissions:"
find $PROJECT_DIR -name "*.sh" -type f -exec ls -la {} \;

print_info "Environment file permissions:"
find $PROJECT_DIR -name "*.env" -type f -exec ls -la {} \;

print_info "Go binary permissions:"
ls -la $PROJECT_DIR/hajifund-backend 2>/dev/null || echo "Backend binary not found"
ls -la $PROJECT_DIR/frontend/hajifund-frontend 2>/dev/null || echo "Frontend binary not found"

print_status "VPS permissions applied successfully!"

print_info "Summary:"
print_info "  - All directories: 755"
print_info "  - All files: 644"
print_info "  - Shell scripts: 755"
print_info "  - Environment files: 600"
print_info "  - Go binaries: 755"
print_info "  - Ownership: www-data:www-data"

print_warning "Note: This matches the local Mac permission structure"
print_warning "Make sure to restart systemd services after permission changes:"
print_warning "  sudo systemctl daemon-reload"
print_warning "  sudo systemctl restart hajifund-backend hajifund-frontend"
EOF

print_status "VPS permission application script created"

# 5. Copy the script to VPS
print_step "5. Copying permission application script to VPS..."

scp -i $VPS_SSH_KEY apply-vps-permissions.sh $VPS_USER@$VPS_IP:~/

# Make it executable on VPS
ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "chmod +x ~/apply-vps-permissions.sh"

print_status "Permission application script copied to VPS"

# 6. Run the script on VPS
print_step "6. Running permission application script on VPS..."

ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "sudo ~/apply-vps-permissions.sh"

print_status "Permissions applied on VPS"

# 7. Clean up local files
print_step "7. Cleaning up local files..."

rm -f permission-mapping.txt
rm -f apply-vps-permissions.sh

print_status "Local cleanup completed"

print_status "Permission sync completed successfully!"

print_info "Summary:"
print_info "  - Local permissions set as reference"
print_info "  - Permission mapping created"
print_info "  - VPS permissions applied to match local"
print_info "  - Ownership set to www-data:www-data on VPS"
print_info "  - All necessary directories created"

print_warning "Note: VPS now follows the same permission structure as local Mac"
print_warning "Make sure to restart systemd services on VPS:"
print_warning "  ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP"
print_warning "  sudo systemctl daemon-reload"
print_warning "  sudo systemctl restart hajifund-backend hajifund-frontend"
