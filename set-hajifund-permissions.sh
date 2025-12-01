#!/bin/bash

# Set HajiFund Permissions - Simple Version
# This script sets basic permissions for /var/www/hajifund folder

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step "Setting HajiFund Permissions"

# Check if directory exists
if [ ! -d "/var/www/hajifund" ]; then
    print_error "HajiFund directory not found at /var/www/hajifund"
    exit 1
fi

# Stop services
print_step "Stopping services..."
systemctl stop hajifund-backend 2>/dev/null || true
systemctl stop hajifund-frontend 2>/dev/null || true

# Set ownership
print_step "Setting ownership to www-data..."
chown -R www-data:www-data /var/www/hajifund

# Set directory permissions to 755
print_step "Setting directory permissions to 755..."
find /var/www/hajifund -type d -exec chmod 755 {} \;

# Set file permissions to 644
print_step "Setting file permissions to 644..."
find /var/www/hajifund -type f -exec chmod 644 {} \;

# Make Go binaries executable
print_step "Setting executable permissions for Go binaries..."
if [ -f "/var/www/hajifund/hajifund-backend" ]; then
    chmod +x /var/www/hajifund/hajifund-backend
fi

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    chmod +x /var/www/hajifund/frontend/hajifund-frontend
    setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
fi

# Set .env files to 600 (secure)
print_step "Setting .env file permissions to 600..."
find /var/www/hajifund -name ".env" -type f -exec chmod 600 {} \; 2>/dev/null || true

# Start services
print_step "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend

print_status "HajiFund permissions set successfully!"
print_status "✅ Ownership: www-data:www-data"
print_status "✅ Directories: 755"
print_status "✅ Files: 644"
print_status "✅ Executables: +x"
print_status "✅ .env files: 600"
