#!/bin/bash

# Debug Frontend Failure
# This script will find out exactly why the frontend is failing

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

print_step "Debugging Frontend Failure"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Check if binary exists and is executable
print_step "2. Checking frontend binary..."

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_status "Binary exists"
    
    # Check if it's executable
    if [ -x "/var/www/hajifund/frontend/hajifund-frontend" ]; then
        print_status "Binary is executable"
    else
        print_error "Binary is NOT executable"
        chmod +x /var/www/hajifund/frontend/hajifund-frontend
        print_status "Made binary executable"
    fi
    
    # Check file size
    file_size=$(stat -c%s "/var/www/hajifund/frontend/hajifund-frontend")
    print_info "Binary size: $file_size bytes"
    
    if [ $file_size -eq 0 ]; then
        print_error "Binary is empty (0 bytes) - compilation failed"
    fi
else
    print_error "Binary does NOT exist"
fi

# 3. Check setcap
print_step "3. Checking setcap..."

if command -v getcap &> /dev/null; then
    print_info "setcap status:"
    getcap /var/www/hajifund/frontend/hajifund-frontend 2>/dev/null || print_warning "No setcap found"
else
    print_warning "getcap command not found"
fi

# 4. Test running the binary manually
print_step "4. Testing binary manually..."

cd /var/www/hajifund/frontend

# Set environment variables
export PORT=80
export GIN_MODE=release

print_info "Environment variables:"
print_info "PORT=$PORT"
print_info "GIN_MODE=$GIN_MODE"

# Try to run the binary and capture any errors
print_info "Attempting to run frontend binary manually..."
timeout 10s ./hajifund-frontend 2>&1 || {
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
        print_warning "Binary started but timed out (this might be normal)"
    else
        print_error "Binary failed to start (exit code: $exit_code)"
    fi
}

# 5. Check for compilation errors
print_step "5. Checking for compilation errors..."

print_info "Testing compilation..."
if go build -v -o hajifund-frontend main.go 2>&1; then
    print_status "Compilation successful"
else
    print_error "Compilation failed"
    print_info "Compilation output:"
    go build -v -o hajifund-frontend main.go 2>&1 || true
fi

# 6. Check Go modules
print_step "6. Checking Go modules..."

if [ -f "go.mod" ]; then
    print_info "go.mod exists"
    print_info "go.mod contents:"
    cat go.mod
    
    print_info "Running go mod tidy..."
    if go mod tidy; then
        print_status "Go modules are clean"
    else
        print_error "go mod tidy failed"
    fi
else
    print_warning "go.mod not found"
fi

# 7. Check for missing dependencies
print_step "7. Checking for missing dependencies..."

print_info "Checking for import errors..."
if go list -e ./... 2>&1 | grep -q "import"; then
    print_error "Import errors found:"
    go list -e ./... 2>&1 | grep "import" || true
fi

# 8. Check systemd service configuration
print_step "8. Checking systemd service configuration..."

if [ -f "/etc/systemd/system/hajifund-frontend.service" ]; then
    print_status "Systemd service file exists"
    
    print_info "Service file contents:"
    cat /etc/systemd/system/hajifund-frontend.service
    
    # Check if the service file is valid
    if systemctl cat hajifund-frontend > /dev/null 2>&1; then
        print_status "Systemd service configuration is valid"
    else
        print_error "Systemd service configuration is invalid"
    fi
else
    print_error "Systemd service file does NOT exist"
fi

# 9. Check service logs
print_step "9. Checking service logs..."

print_info "Recent frontend service logs:"
journalctl -u hajifund-frontend --no-pager -l | tail -20

# 10. Check if port 80 is already in use
print_step "10. Checking if port 80 is already in use..."

if netstat -tlnp | grep -q ":80 "; then
    print_warning "Port 80 is already in use:"
    netstat -tlnp | grep ":80 "
else
    print_status "Port 80 is available"
fi

# 11. Check file permissions
print_step "11. Checking file permissions..."

print_info "Frontend directory permissions:"
ls -la /var/www/hajifund/frontend/

print_info "Binary permissions:"
if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    ls -la /var/www/hajifund/frontend/hajifund-frontend
else
    print_error "Binary does not exist"
fi

# 12. Check if www-data user exists
print_step "12. Checking www-data user..."

if id "www-data" &>/dev/null; then
    print_status "www-data user exists"
    print_info "www-data user info:"
    id www-data
else
    print_error "www-data user does NOT exist"
fi

# 13. Try to fix common issues
print_step "13. Attempting to fix common issues..."

# Fix permissions
print_info "Setting correct permissions..."
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions fixed"

# Rebuild if needed
if [ ! -f "/var/www/hajifund/frontend/hajifund-frontend" ] || [ ! -s "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_info "Rebuilding frontend..."
    cd /var/www/hajifund/frontend
    go build -o hajifund-frontend main.go
    chown www-data:www-data hajifund-frontend
    chmod +x hajifund-frontend
    print_status "Frontend rebuilt"
fi

# Reapply setcap
print_info "Reapplying setcap..."
if command -v setcap &> /dev/null; then
    setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
    print_status "setcap reapplied"
else
    print_warning "setcap command not found"
fi

# Reload systemd
print_info "Reloading systemd..."
systemctl daemon-reload

# Try to start the service
print_info "Attempting to start frontend service..."
if systemctl start hajifund-frontend; then
    print_status "Service started successfully"
    sleep 3
    
    if systemctl is-active --quiet hajifund-frontend; then
        print_status "Frontend service is now running"
    else
        print_error "Service started but is not active"
        print_info "Latest logs:"
        journalctl -u hajifund-frontend --no-pager -l | tail -10
    fi
else
    print_error "Failed to start service"
    print_info "Service status:"
    systemctl status hajifund-frontend --no-pager
fi

print_step "Debug completed!"
print_info "If the service is still failing, check the logs above for specific error messages."
