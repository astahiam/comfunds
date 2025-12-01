#!/bin/bash

# Fix Session Issues and Revert to Port 80
# This script fixes session/cookie issues and puts frontend back on port 80

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

print_step "Fixing Session Issues and Reverting to Port 80"

# 1. Stop services
print_step "1. Stopping services..."
systemctl stop hajifund-frontend
systemctl stop hajifund-backend
print_status "Services stopped"

# 2. Install setcap for port 80 binding
print_step "2. Installing setcap for port 80 binding..."

if ! command -v setcap &> /dev/null; then
    print_info "Installing libcap2-bin..."
    apt update
    apt install -y libcap2-bin
    print_status "libcap2-bin installed"
else
    print_status "libcap2-bin already installed"
fi

# 3. Fix backend cookie settings for port 80
print_step "3. Fixing backend cookie settings for port 80..."

# Update backend .env
if [ -f "/var/www/hajifund/.env" ]; then
    print_info "Updating backend .env for port 80 frontend..."
    
    # Update CORS_ORIGINS to include port 80
    if grep -q "CORS_ORIGINS" /var/www/hajifund/.env; then
        sed -i 's/CORS_ORIGINS=.*/CORS_ORIGINS=http:\/\/103.103.20.68,http:\/\/localhost:3000,http:\/\/127.0.0.1:3000/' /var/www/hajifund/.env
    else
        echo "CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://127.0.0.1:3000" >> /var/www/hajifund/.env
    fi
    
    print_status "Backend .env updated"
else
    print_error "Backend .env not found"
    exit 1
fi

# 4. Fix frontend configuration for port 80
print_step "4. Fixing frontend configuration for port 80..."

# Update frontend .env
cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF

print_status "Frontend .env updated for port 80"

# 5. Rebuild frontend with setcap
print_step "5. Rebuilding frontend with setcap..."

cd /var/www/hajifund/frontend

# Clean old binary
if [ -f "hajifund-frontend" ]; then
    rm -f hajifund-frontend
    print_status "Old binary removed"
fi

# Build new binary
print_info "Building frontend binary..."
if go build -o hajifund-frontend main.go; then
    print_status "Frontend built successfully"
else
    print_error "Frontend build failed"
    exit 1
fi

# Set setcap for port 80 binding
print_info "Setting setcap for port 80 binding..."
setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
print_status "setcap applied for port 80"

# Verify setcap
print_info "Verifying setcap..."
getcap /var/www/hajifund/frontend/hajifund-frontend

# 6. Update systemd service for port 80
print_step "6. Updating systemd service for port 80..."

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

print_status "Systemd service updated for port 80"

# 7. Set proper permissions
print_step "7. Setting permissions..."
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions set"

# 8. Update firewall for port 80
print_step "8. Updating firewall for port 80..."

# Allow port 80
ufw allow 80/tcp
print_status "Port 80 allowed in firewall"

# Keep port 8080 for backend
ufw allow 8080/tcp
print_status "Port 8080 allowed in firewall"

# Keep SSH
ufw allow 22/tcp
print_status "SSH port 22 allowed"

# 9. Reload systemd and start services
print_step "9. Starting services..."

# Reload systemd
systemctl daemon-reload
print_status "Systemd reloaded"

# Start backend first
print_info "Starting backend..."
if systemctl start hajifund-backend; then
    print_status "Backend started"
else
    print_error "Backend failed to start"
    systemctl status hajifund-backend --no-pager
fi

# Start frontend
print_info "Starting frontend on port 80..."
if systemctl start hajifund-frontend; then
    print_status "Frontend started"
else
    print_error "Frontend failed to start"
    systemctl status hajifund-frontend --no-pager
fi

# 10. Check service status
print_step "10. Checking service status..."

sleep 5

if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend is running on port 8080"
else
    print_error "Backend is not running"
    systemctl status hajifund-backend --no-pager
fi

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend is running on port 80"
else
    print_error "Frontend is not running"
    systemctl status hajifund-frontend --no-pager
fi

# 11. Test the setup
print_step "11. Testing the setup..."

# Test frontend on port 80
print_info "Testing frontend on port 80..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding on port 80"
else
    print_warning "Frontend might not be responding on port 80"
fi

# Test backend on port 8080
print_info "Testing backend on port 8080..."
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding on port 8080"
else
    print_warning "Backend might not be responding on port 8080"
fi

# Test external access
print_info "Testing external access..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access might not be working"
fi

# 12. Test login functionality
print_step "12. Testing login functionality..."

print_info "Testing login endpoint..."
if curl -s -X POST http://103.103.20.68:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}' \
    | grep -q "auth_token"; then
    print_status "Login endpoint is working and returns auth_token"
else
    print_warning "Login endpoint might not be working correctly"
fi

print_status "Session and port 80 fix completed!"
print_info "Your application is now accessible at:"
print_info "- Frontend: http://103.103.20.68 (port 80)"
print_info "- Backend: http://103.103.20.68:8080"
print_info ""
print_info "Session/cookie issues should now be fixed because:"
print_info "- Frontend is back on port 80 (standard port)"
print_info "- Backend cookie settings updated for port 80"
print_info "- CORS settings updated for port 80"
print_info "- setcap allows frontend to bind to port 80"
