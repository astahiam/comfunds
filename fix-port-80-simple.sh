#!/bin/bash

# Simple Fix for Port 80 Permission Issue (No Nginx)
# This script fixes the port 80 permission issue without installing nginx

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

print_step "Simple Fix for Port 80 Permission Issue (No Nginx)"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Remove nginx if it exists
print_step "2. Removing nginx..."
if systemctl is-active --quiet nginx; then
    print_info "Stopping and removing nginx..."
    systemctl stop nginx
    systemctl disable nginx
    apt remove -y nginx nginx-common
    print_status "Nginx removed"
else
    print_info "Nginx is not installed"
fi

# 3. Configure frontend to use port 3000
print_step "3. Configuring frontend to use port 3000..."

# Update frontend .env
if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_info "Updating frontend .env to use port 3000..."
    sed -i 's/PORT=.*/PORT=3000/' /var/www/hajifund/frontend/.env
    print_status "Frontend .env updated to use port 3000"
else
    print_info "Creating frontend .env with port 3000..."
    cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=3000
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68:3000
EOF
    print_status "Frontend .env created with port 3000"
fi

# 4. Update systemd service to use port 3000
print_step "4. Updating systemd service to use port 3000..."

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
Environment=PORT=3000
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd service updated to use port 3000"

# 5. Set up iptables port forwarding (port 80 -> port 3000)
print_step "5. Setting up iptables port forwarding (80 -> 3000)..."

# Install iptables-persistent if not installed
if ! dpkg -l | grep -q iptables-persistent; then
    print_info "Installing iptables-persistent..."
    apt update
    apt install -y iptables-persistent
    print_status "iptables-persistent installed"
fi

# Add port forwarding rule
print_info "Adding iptables port forwarding rule..."
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3000
iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3000

# Save iptables rules
print_info "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4
print_status "iptables rules saved"

# 6. Reload systemd and start frontend
print_step "6. Starting frontend service..."

# Reload systemd
systemctl daemon-reload
print_status "Systemd reloaded"

# Start frontend
print_info "Starting frontend on port 3000..."
if systemctl start hajifund-frontend; then
    print_status "Frontend service started"
else
    print_error "Failed to start frontend service"
    systemctl status hajifund-frontend --no-pager
    exit 1
fi

# 7. Check service status
print_step "7. Checking service status..."

sleep 3

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running on port 3000"
else
    print_error "Frontend service is not running"
    print_info "Service status:"
    systemctl status hajifund-frontend --no-pager
    print_info "Recent logs:"
    journalctl -u hajifund-frontend --no-pager -l | tail -10
fi

# 8. Test the setup
print_step "8. Testing the setup..."

# Test port 3000 directly
print_info "Testing frontend on port 3000..."
if curl -s http://localhost:3000/ | grep -q "HajiFund"; then
    print_status "Frontend is responding on port 3000"
else
    print_warning "Frontend might not be responding on port 3000"
fi

# Test port 80 (should redirect to port 3000)
print_info "Testing port 80 redirect..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Port 80 redirect is working"
else
    print_warning "Port 80 redirect might not be working"
fi

# Test external access
print_info "Testing external access..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access might not be working"
fi

# 9. Show current iptables rules
print_step "9. Showing current iptables rules..."
print_info "Current iptables NAT rules:"
iptables -t nat -L -n

print_status "Simple port 80 fix completed!"
print_info "Frontend is now accessible at:"
print_info "- Direct: http://103.103.20.68:3000"
print_info "- Via redirect: http://103.103.20.68 (port 80 redirects to 3000)"
print_info "No nginx needed - iptables handles the port forwarding!"
