#!/bin/bash

# Diagnose Frontend Service Failure
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

print_step "Diagnosing Frontend Service Failure"

# 1. Check if frontend binary exists
print_step "1. Checking frontend binary..."

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_status "Frontend binary exists"
    
    # Check if it's executable
    if [ -x "/var/www/hajifund/frontend/hajifund-frontend" ]; then
        print_status "Frontend binary is executable"
    else
        print_error "Frontend binary is NOT executable"
        print_info "Fixing permissions..."
        chmod +x /var/www/hajifund/frontend/hajifund-frontend
        print_status "Permissions fixed"
    fi
    
    # Check file size
    file_size=$(stat -c%s "/var/www/hajifund/frontend/hajifund-frontend")
    print_info "Binary size: $file_size bytes"
    
    if [ $file_size -eq 0 ]; then
        print_error "Binary is empty (0 bytes) - compilation failed"
    fi
else
    print_error "Frontend binary does NOT exist"
    print_info "This means compilation failed"
fi

# 2. Check frontend directory structure
print_step "2. Checking frontend directory structure..."

if [ -d "/var/www/hajifund/frontend" ]; then
    print_status "Frontend directory exists"
    
    print_info "Frontend directory contents:"
    ls -la /var/www/hajifund/frontend/
    
    if [ -f "/var/www/hajifund/frontend/main.go" ]; then
        print_status "main.go exists"
    else
        print_error "main.go does NOT exist"
    fi
    
    if [ -f "/var/www/hajifund/frontend/go.mod" ]; then
        print_status "go.mod exists"
    else
        print_warning "go.mod does NOT exist"
    fi
else
    print_error "Frontend directory does NOT exist"
fi

# 3. Test compilation manually
print_step "3. Testing frontend compilation manually..."

cd /var/www/hajifund/frontend

print_info "Current directory: $(pwd)"
print_info "Go version: $(go version)"

if [ -f "main.go" ]; then
    print_info "Attempting to compile frontend..."
    
    # Try to compile and capture output
    if go build -v -o hajifund-frontend main.go 2>&1; then
        print_status "Frontend compiles successfully"
    else
        print_error "Frontend compilation FAILED"
        print_info "Compilation output:"
        go build -v -o hajifund-frontend main.go 2>&1 || true
    fi
else
    print_error "Cannot test compilation - main.go not found"
fi

# 4. Check Go modules
print_step "4. Checking Go modules..."

if [ -f "go.mod" ]; then
    print_info "go.mod contents:"
    cat go.mod
    
    print_info "Running go mod tidy..."
    if go mod tidy; then
        print_status "Go modules are clean"
    else
        print_error "Go mod tidy failed"
    fi
else
    print_warning "No go.mod found, initializing..."
    if go mod init hajifund-frontend; then
        print_status "Go modules initialized"
        go mod tidy
    else
        print_error "Failed to initialize Go modules"
    fi
fi

# 5. Check for missing dependencies
print_step "5. Checking for missing dependencies..."

print_info "Checking for import errors..."
if go list -e ./... 2>&1 | grep -q "import"; then
    print_error "Import errors found:"
    go list -e ./... 2>&1 | grep "import" || true
fi

# 6. Test running the binary manually
print_step "6. Testing frontend binary manually..."

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_info "Testing frontend binary execution..."
    
    # Try to run it and capture any errors
    cd /var/www/hajifund/frontend
    
    # Set environment variables
    export PORT=80
    export GIN_MODE=release
    
    print_info "Environment variables set:"
    print_info "PORT=$PORT"
    print_info "GIN_MODE=$GIN_MODE"
    
    # Try to run the binary (timeout after 5 seconds)
    print_info "Attempting to run frontend binary..."
    timeout 5s ./hajifund-frontend 2>&1 || {
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_warning "Frontend binary started but timed out (this might be normal)"
        else
            print_error "Frontend binary failed to start (exit code: $exit_code)"
        fi
    }
else
    print_error "Cannot test binary - it doesn't exist"
fi

# 7. Check systemd service configuration
print_step "7. Checking systemd service configuration..."

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

# 8. Check service logs
print_step "8. Checking service logs..."

print_info "Recent frontend service logs:"
journalctl -u hajifund-frontend --no-pager -l | tail -20

# 9. Check if port 80 is already in use
print_step "9. Checking if port 80 is already in use..."

if netstat -tlnp | grep -q ":80 "; then
    print_warning "Port 80 is already in use:"
    netstat -tlnp | grep ":80 "
else
    print_status "Port 80 is available"
fi

# 10. Check file permissions
print_step "10. Checking file permissions..."

print_info "Frontend directory permissions:"
ls -la /var/www/hajifund/frontend/

print_info "Binary permissions:"
if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    ls -la /var/www/hajifund/frontend/hajifund-frontend
else
    print_error "Binary does not exist"
fi

# 11. Check if www-data user exists
print_step "11. Checking www-data user..."

if id "www-data" &>/dev/null; then
    print_status "www-data user exists"
    print_info "www-data user info:"
    id www-data
else
    print_error "www-data user does NOT exist"
fi

# 12. Try to fix common issues
print_step "12. Attempting to fix common issues..."

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

print_step "Diagnosis completed!"
print_info "If the service is still failing, check the logs above for specific error messages."
