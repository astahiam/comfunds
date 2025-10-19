#!/bin/bash

# Fix HajiFund Systemd Services Script
# This script fixes the systemd service configuration issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

print_step "Fixing HajiFund systemd services..."

# Stop existing services
print_info "Stopping existing services..."
systemctl stop hajifund-backend hajifund-frontend 2>/dev/null || true

# Build the applications
print_info "Building applications..."
cd /var/www/hajifund

# Set Go environment
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/var/www/go

# Build backend
print_info "Building backend..."
go build -o hajifund-backend main.go

# Build frontend
print_info "Building frontend..."
cd frontend
go build -o hajifund-frontend main.go
cd ..

print_status "Applications built successfully"

# Fix backend service
print_info "Creating corrected backend service..."
cat > /etc/systemd/system/hajifund-backend.service << 'EOF'
[Unit]
Description=HajiFund Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
Environment=GOPATH=/var/www/go
ExecStart=/var/www/hajifund/hajifund-backend
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hajifund-backend

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/www/hajifund/logs

[Install]
WantedBy=multi-user.target
EOF

# Fix frontend service
print_info "Creating corrected frontend service..."
cat > /etc/systemd/system/hajifund-frontend.service << 'EOF'
[Unit]
Description=HajiFund Frontend
After=network.target hajifund-backend.service
Requires=hajifund-backend.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund/frontend
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
Environment=GOPATH=/var/www/go
ExecStart=/var/www/hajifund/frontend/hajifund-frontend
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hajifund-frontend

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/www/hajifund/frontend/logs

[Install]
WantedBy=multi-user.target
EOF

# Set proper ownership
print_info "Setting proper ownership..."
chown www-data:www-data /var/www/hajifund/hajifund-backend
chown www-data:www-data /var/www/hajifund/frontend/hajifund-frontend
chmod +x /var/www/hajifund/hajifund-backend
chmod +x /var/www/hajifund/frontend/hajifund-frontend

# Create logs directory
mkdir -p /var/www/hajifund/logs
mkdir -p /var/www/hajifund/frontend/logs
chown -R www-data:www-data /var/www/hajifund/logs

# Reload systemd and start services
print_info "Reloading systemd and starting services..."
systemctl daemon-reload
systemctl enable hajifund-backend hajifund-frontend
systemctl start hajifund-backend
sleep 5
systemctl start hajifund-frontend

# Check service status
print_info "Checking service status..."
sleep 10

echo ""
print_info "Backend Service Status:"
systemctl status hajifund-backend --no-pager -l

echo ""
print_info "Frontend Service Status:"
systemctl status hajifund-frontend --no-pager -l

# Test endpoints
print_info "Testing endpoints..."
sleep 10

if curl -f -s http://localhost:8080/api/v1/health > /dev/null; then
    print_status "Backend API is responding"
else
    print_warning "Backend API is not responding yet"
fi

if curl -f -s http://localhost:3000 > /dev/null; then
    print_status "Frontend is responding"
else
    print_warning "Frontend is not responding yet"
fi

print_status "Systemd services fixed successfully!"
print_info "You can now check logs with: journalctl -u hajifund-backend -f"
print_info "You can now check logs with: journalctl -u hajifund-frontend -f"
