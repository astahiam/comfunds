#!/bin/bash

# Final Frontend Fix
# This script fixes the most common frontend issues

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

print_step "Final Frontend Fix"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Clean up and rebuild
print_step "2. Cleaning up and rebuilding..."

cd /var/www/hajifund/frontend

# Remove old binary
if [ -f "hajifund-frontend" ]; then
    rm -f hajifund-frontend
    print_status "Old binary removed"
fi

# Initialize Go modules if needed
if [ ! -f "go.mod" ]; then
    print_info "Initializing Go modules..."
    go mod init hajifund-frontend
fi

# Update modules
print_info "Updating Go modules..."
go mod tidy

# Build the frontend
print_info "Building frontend..."
if go build -o hajifund-frontend main.go; then
    print_status "Frontend built successfully"
else
    print_error "Frontend build failed"
    print_info "Build output:"
    go build -v -o hajifund-frontend main.go 2>&1 || true
    exit 1
fi

# 3. Set proper permissions and setcap
print_step "3. Setting permissions and setcap..."

# Set ownership
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions set"

# Install setcap if needed
if ! command -v setcap &> /dev/null; then
    print_info "Installing libcap2-bin..."
    apt update
    apt install -y libcap2-bin
fi

# Apply setcap for port 80
print_info "Applying setcap for port 80..."
setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
print_status "setcap applied"

# Verify setcap
print_info "Verifying setcap..."
getcap /var/www/hajifund/frontend/hajifund-frontend

# 4. Create proper systemd service
print_step "4. Creating systemd service..."

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

# 5. Create proper .env file
print_step "5. Creating .env file..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF

print_status ".env file created"

# 6. Reload systemd and start service
print_step "6. Starting service..."

# Reload systemd
systemctl daemon-reload
print_status "Systemd reloaded"

# Start the service
print_info "Starting frontend service..."
if systemctl start hajifund-frontend; then
    print_status "Service started"
else
    print_error "Failed to start service"
    print_info "Service status:"
    systemctl status hajifund-frontend --no-pager
    print_info "Recent logs:"
    journalctl -u hajifund-frontend --no-pager -l | tail -10
    exit 1
fi

# 7. Check service status
print_step "7. Checking service status..."

sleep 5

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

# 8. Test external access
print_step "8. Testing external access..."

print_info "Testing external access..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access might not be working"
fi

print_status "Final frontend fix completed!"
print_info "Frontend should now be accessible at: http://103.103.20.68"
print_info "To check logs: journalctl -u hajifund-frontend -f"
