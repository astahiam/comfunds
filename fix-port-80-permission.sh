#!/bin/bash

# Fix Port 80 Permission Issue
# This script fixes the "permission denied" error when binding to port 80

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

print_step "Fixing Port 80 Permission Issue"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Check what's using port 80
print_step "2. Checking what's using port 80..."

if netstat -tlnp | grep -q ":80 "; then
    print_warning "Port 80 is already in use:"
    netstat -tlnp | grep ":80 "
    
    # Check if it's nginx
    if netstat -tlnp | grep ":80 " | grep -q nginx; then
        print_info "Nginx is using port 80, stopping it..."
        systemctl stop nginx
        systemctl disable nginx
        print_status "Nginx stopped and disabled"
    fi
else
    print_status "Port 80 is available"
fi

# 3. Option 1: Use port 3000 instead of port 80
print_step "3. Configuring frontend to use port 3000 instead of port 80..."

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

# 5. Alternative: Configure nginx to proxy port 80 to port 3000
print_step "5. Setting up nginx to proxy port 80 to port 3000..."

# Install nginx if not installed
if ! command -v nginx &> /dev/null; then
    print_info "Installing nginx..."
    apt update
    apt install -y nginx
    print_status "Nginx installed"
fi

# Create nginx configuration
print_info "Creating nginx configuration..."
cat > /etc/nginx/sites-available/hajifund << 'EOF'
server {
    listen 80;
    server_name 103.103.20.68;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Handle WebSocket connections
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Handle cookies properly
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
    }
    
    # Proxy API calls to backend
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Handle cookies for API calls
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 6. Reload systemd and start services
print_step "6. Starting services..."

# Reload systemd
systemctl daemon-reload
print_status "Systemd reloaded"

# Start nginx
print_info "Starting nginx..."
systemctl start nginx
systemctl enable nginx
print_status "Nginx started"

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

if systemctl is-active --quiet nginx; then
    print_status "Nginx is running on port 80"
else
    print_error "Nginx is not running"
    systemctl status nginx --no-pager
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

# Test port 80 (nginx proxy)
print_info "Testing nginx proxy on port 80..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Nginx proxy is working on port 80"
else
    print_warning "Nginx proxy might not be working on port 80"
fi

# Test external access
print_info "Testing external access..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access might not be working"
fi

print_status "Port 80 permission fix completed!"
print_info "Frontend is now accessible at:"
print_info "- Direct: http://103.103.20.68:3000"
print_info "- Via nginx: http://103.103.20.68"
print_info "Nginx proxies port 80 to port 3000, so users can access the site normally."
