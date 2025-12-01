#!/bin/bash

# Quick Fix for Frontend Service
# This script fixes the most common frontend service issues

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

print_step "Quick Fix for Frontend Service"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Remove old binary if it exists
print_step "2. Cleaning up old binary..."
if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    rm -f /var/www/hajifund/frontend/hajifund-frontend
    print_status "Old binary removed"
fi

# 3. Go to frontend directory
print_step "3. Setting up frontend directory..."
cd /var/www/hajifund/frontend

# 4. Initialize Go modules if needed
print_step "4. Setting up Go modules..."
if [ ! -f "go.mod" ]; then
    print_info "Initializing Go modules..."
    go mod init hajifund-frontend
fi

# Update modules
go mod tidy
print_status "Go modules updated"

# 5. Check for compilation errors
print_step "5. Checking compilation..."
print_info "Attempting to compile frontend..."

if go build -v -o hajifund-frontend main.go; then
    print_status "Frontend compiled successfully"
else
    print_error "Frontend compilation failed"
    print_info "Trying to fix import issues..."
    
    # Try to fix common import issues
    go mod download
    go mod tidy
    
    # Try compilation again
    if go build -v -o hajifund-frontend main.go; then
        print_status "Frontend compiled after fixing imports"
    else
        print_error "Frontend still fails to compile"
        print_info "Compilation output:"
        go build -v -o hajifund-frontend main.go 2>&1 || true
        exit 1
    fi
fi

# 6. Set proper permissions
print_step "6. Setting permissions..."
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions set"

# 7. Create/update systemd service
print_step "7. Creating systemd service..."
cat > /etc/systemd/system/hajifund-frontend.service << 'EOF'
[Unit]
Description=HajiFund Frontend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund/frontend
ExecStart=/var/www/hajifund/frontend/hajifund-frontend
Restart=always
RestartSec=5
Environment=PORT=80
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd service created"

# 8. Reload systemd
print_step "8. Reloading systemd..."
systemctl daemon-reload
print_status "Systemd reloaded"

# 9. Start the service
print_step "9. Starting frontend service..."
if systemctl start hajifund-frontend; then
    print_status "Service started"
else
    print_error "Failed to start service"
    systemctl status hajifund-frontend --no-pager
    exit 1
fi

# 10. Check if it's running
print_step "10. Checking service status..."
sleep 3

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running!"
    
    # Check if it's listening on port 80
    if netstat -tlnp | grep -q ":80.*hajifund-frontend"; then
        print_status "Frontend is listening on port 80"
    else
        print_warning "Frontend might not be listening on port 80"
    fi
    
    # Test HTTP response
    print_info "Testing HTTP response..."
    if curl -s http://localhost/ | grep -q "HajiFund"; then
        print_status "Frontend is responding to HTTP requests"
    else
        print_warning "Frontend might not be responding to HTTP requests"
    fi
else
    print_error "Frontend service is not running"
    print_info "Service status:"
    systemctl status hajifund-frontend --no-pager
    print_info "Recent logs:"
    journalctl -u hajifund-frontend --no-pager -l | tail -10
fi

print_status "Quick fix completed!"
print_info "Frontend should now be accessible at: http://103.103.20.68"
