#!/bin/bash

# Fix Frontend using setcap (Allow binding to port 80)
# This script uses setcap to allow the frontend binary to bind to port 80

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

print_step "Fix Frontend using setcap (Allow binding to port 80)"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Rebuild frontend binary
print_step "2. Rebuilding frontend binary..."
cd /var/www/hajifund/frontend

# Ensure go.mod exists
if [ ! -f "go.mod" ]; then
    print_info "Initializing Go modules..."
    go mod init hajifund-frontend
    go mod tidy
fi

# Build the binary
print_info "Building frontend binary..."
go build -o hajifund-frontend main.go
print_status "Frontend binary built"

# 3. Set capabilities to allow binding to port 80
print_step "3. Setting capabilities for port 80 binding..."

# Install libcap2-bin if not installed
if ! command -v setcap &> /dev/null; then
    print_info "Installing libcap2-bin..."
    apt update
    apt install -y libcap2-bin
    print_status "libcap2-bin installed"
fi

# Set the capability to allow binding to privileged ports
print_info "Setting CAP_NET_BIND_SERVICE capability..."
setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
print_status "Capability set"

# Verify the capability was set
print_info "Verifying capability..."
getcap /var/www/hajifund/frontend/hajifund-frontend

# 4. Update frontend to use port 80
print_step "4. Configuring frontend to use port 80..."

# Update frontend .env
if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_info "Updating frontend .env to use port 80..."
    sed -i 's/PORT=.*/PORT=80/' /var/www/hajifund/frontend/.env
    print_status "Frontend .env updated to use port 80"
else
    print_info "Creating frontend .env with port 80..."
    cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF
    print_status "Frontend .env created with port 80"
fi

# 5. Update systemd service to use port 80
print_step "5. Updating systemd service to use port 80..."

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

print_status "Systemd service updated to use port 80"

# 6. Set proper permissions
print_step "6. Setting proper permissions..."
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions set"

# 7. Reload systemd and start service
print_step "7. Starting frontend service..."

# Reload systemd
systemctl daemon-reload
print_status "Systemd reloaded"

# Start frontend
print_info "Starting frontend on port 80..."
if systemctl start hajifund-frontend; then
    print_status "Frontend service started"
else
    print_error "Failed to start frontend service"
    systemctl status hajifund-frontend --no-pager
    exit 1
fi

# 8. Check service status
print_step "8. Checking service status..."

sleep 3

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running on port 80"
else
    print_error "Frontend service is not running"
    print_info "Service status:"
    systemctl status hajifund-frontend --no-pager
    print_info "Recent logs:"
    journalctl -u hajifund-frontend --no-pager -l | tail -10
fi

# 9. Test the setup
print_step "9. Testing the setup..."

# Test port 80 directly
print_info "Testing frontend on port 80..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding on port 80"
else
    print_warning "Frontend might not be responding on port 80"
fi

# Test external access
print_info "Testing external access..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access might not be working"
fi

print_status "setcap fix completed!"
print_info "Frontend is now accessible at: http://103.103.20.68"
print_info "The frontend binary now has the capability to bind to port 80"
