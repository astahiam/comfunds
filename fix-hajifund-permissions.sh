#!/bin/bash

# Fix HajiFund Permissions
# This script sets correct permissions for /var/www/hajifund folder and all contents

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step "Fixing HajiFund Permissions"

# 1. Check if directory exists
print_step "1. Checking if /var/www/hajifund exists..."

if [ -d "/var/www/hajifund" ]; then
    print_status "HajiFund directory exists"
else
    print_error "HajiFund directory not found at /var/www/hajifund"
    exit 1
fi

# 2. Check current permissions
print_step "2. Checking current permissions..."

print_info "Current ownership:"
ls -la /var/www/hajifund | head -5

print_info "Current permissions:"
find /var/www/hajifund -maxdepth 2 -type d -exec ls -ld {} \; | head -10

# 3. Stop services before changing permissions
print_step "3. Stopping services before permission changes..."

if systemctl is-active --quiet hajifund-backend; then
    print_info "Stopping backend service..."
    systemctl stop hajifund-backend
    print_status "Backend service stopped"
else
    print_info "Backend service not running"
fi

if systemctl is-active --quiet hajifund-frontend; then
    print_info "Stopping frontend service..."
    systemctl stop hajifund-frontend
    print_status "Frontend service stopped"
else
    print_info "Frontend service not running"
fi

# 4. Set ownership to www-data
print_step "4. Setting ownership to www-data..."

print_info "Setting ownership for /var/www/hajifund..."
chown -R www-data:www-data /var/www/hajifund
print_status "Ownership set to www-data:www-data"

# 5. Set directory permissions to 755
print_step "5. Setting directory permissions to 755..."

print_info "Setting directory permissions..."
find /var/www/hajifund -type d -exec chmod 755 {} \;
print_status "Directory permissions set to 755"

# 6. Set file permissions to 644
print_step "6. Setting file permissions to 644..."

print_info "Setting file permissions..."
find /var/www/hajifund -type f -exec chmod 644 {} \;
print_status "File permissions set to 644"

# 7. Set special permissions for executables
print_step "7. Setting special permissions for executables..."

# Make Go binaries executable
if [ -f "/var/www/hajifund/hajifund-backend" ]; then
    print_info "Setting backend binary permissions..."
    chmod +x /var/www/hajifund/hajifund-backend
    chown www-data:www-data /var/www/hajifund/hajifund-backend
    print_status "Backend binary permissions set"
fi

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_info "Setting frontend binary permissions..."
    chmod +x /var/www/hajifund/frontend/hajifund-frontend
    chown www-data:www-data /var/www/hajifund/frontend/hajifund-frontend
    print_status "Frontend binary permissions set"
fi

# 8. Set special permissions for .env files
print_step "8. Setting special permissions for .env files..."

# Backend .env
if [ -f "/var/www/hajifund/.env" ]; then
    print_info "Setting backend .env permissions..."
    chmod 600 /var/www/hajifund/.env
    chown www-data:www-data /var/www/hajifund/.env
    print_status "Backend .env permissions set"
fi

# Frontend .env
if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_info "Setting frontend .env permissions..."
    chmod 600 /var/www/hajifund/frontend/.env
    chown www-data:www-data /var/www/hajifund/frontend/.env
    print_status "Frontend .env permissions set"
fi

# 9. Set special permissions for log files
print_step "9. Setting special permissions for log files..."

# Create log directory if it doesn't exist
mkdir -p /var/www/hajifund/logs
chown www-data:www-data /var/www/hajifund/logs
chmod 755 /var/www/hajifund/logs

# Set permissions for any existing log files
find /var/www/hajifund -name "*.log" -type f -exec chmod 644 {} \; 2>/dev/null || true
find /var/www/hajifund -name "*.log" -type f -exec chown www-data:www-data {} \; 2>/dev/null || true

print_status "Log file permissions set"

# 10. Set special permissions for uploads directory
print_step "10. Setting special permissions for uploads directory..."

# Create uploads directory if it doesn't exist
mkdir -p /var/www/hajifund/uploads
chown www-data:www-data /var/www/hajifund/uploads
chmod 755 /var/www/hajifund/uploads

# Set permissions for any existing upload files
find /var/www/hajifund/uploads -type f -exec chmod 644 {} \; 2>/dev/null || true
find /var/www/hajifund/uploads -type f -exec chown www-data:www-data {} \; 2>/dev/null || true

print_status "Uploads directory permissions set"

# 11. Set special permissions for database files
print_step "11. Setting special permissions for database files..."

# Set permissions for any database files
find /var/www/hajifund -name "*.db" -type f -exec chmod 644 {} \; 2>/dev/null || true
find /var/www/hajifund -name "*.db" -type f -exec chown www-data:www-data {} \; 2>/dev/null || true

print_status "Database file permissions set"

# 12. Apply setcap for frontend binary
print_step "12. Applying setcap for frontend binary..."

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_info "Applying setcap for port 80 binding..."
    setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
    print_status "Setcap applied for frontend binary"
fi

# 13. Verify permissions
print_step "13. Verifying permissions..."

print_info "Verifying ownership:"
ls -la /var/www/hajifund | head -5

print_info "Verifying directory permissions:"
find /var/www/hajifund -maxdepth 2 -type d -exec ls -ld {} \; | head -10

print_info "Verifying file permissions:"
find /var/www/hajifund -maxdepth 2 -type f -exec ls -l {} \; | head -10

# 14. Check for any files not owned by www-data
print_step "14. Checking for files not owned by www-data..."

print_info "Files not owned by www-data:"
find /var/www/hajifund ! -user www-data -type f 2>/dev/null | head -10 || print_status "All files owned by www-data"

print_info "Directories not owned by www-data:"
find /var/www/hajifund ! -user www-data -type d 2>/dev/null | head -10 || print_status "All directories owned by www-data"

# 15. Start services
print_step "15. Starting services..."

print_info "Starting backend service..."
systemctl start hajifund-backend
sleep 2

if systemctl is-active --quiet hajififund-backend; then
    print_status "Backend service started successfully"
else
    print_warning "Backend service might not have started"
    systemctl status hajifund-backend --no-pager
fi

print_info "Starting frontend service..."
systemctl start hajifund-frontend
sleep 2

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service started successfully"
else
    print_warning "Frontend service might not have started"
    systemctl status hajifund-frontend --no-pager
fi

# 16. Test services
print_step "16. Testing services..."

sleep 3

# Test backend
print_info "Testing backend..."
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be responding"
fi

# Test frontend
print_info "Testing frontend..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# 17. Show final permission summary
print_step "17. Final permission summary..."

print_info "Final ownership summary:"
ls -la /var/www/hajifund

print_info "Final permission summary:"
echo "Directories:"
find /var/www/hajifund -type d -exec ls -ld {} \; | head -5

echo "Files:"
find /var/www/hajifund -type f -exec ls -l {} \; | head -5

print_status "HajiFund permissions fix completed!"
print_info "Summary of changes:"
print_info "✅ Ownership set to www-data:www-data"
print_info "✅ Directory permissions set to 755"
print_info "✅ File permissions set to 644"
print_info "✅ Executable permissions set for Go binaries"
print_info "✅ .env files set to 600 (secure)"
print_info "✅ Log and upload directories created with proper permissions"
print_info "✅ Setcap applied for frontend binary"
print_info "✅ Services restarted and tested"
