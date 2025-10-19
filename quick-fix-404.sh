#!/bin/bash

# HajiFund Quick 404 Fix Script
# This script quickly fixes the most common 404 issues

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

print_step "Quick 404 Fix for HajiFund"

# 1. Stop all services
print_info "Stopping all services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Build applications
print_step "Building applications..."
cd /var/www/hajifund

# Set Go environment
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/var/www/go

# Build backend
print_info "Building backend..."
if [ -f "main.go" ]; then
    go build -o hajifund-backend main.go
    print_status "Backend built successfully"
else
    print_error "main.go not found in /var/www/hajifund"
    exit 1
fi

# Build frontend
print_info "Building frontend..."
if [ -f "frontend/main.go" ]; then
    cd frontend
    go build -o hajifund-frontend main.go
    cd ..
    print_status "Frontend built successfully"
else
    print_error "frontend/main.go not found"
    exit 1
fi

# 3. Set proper permissions
print_info "Setting permissions..."
chown www-data:www-data hajifund-backend
chown www-data:www-data frontend/hajifund-frontend
chmod +x hajifund-backend
chmod +x frontend/hajifund-frontend

# 4. Fix systemd services
print_info "Updating systemd services..."

# Backend service
cat > /etc/systemd/system/hajifund-backend.service << 'EOF'
[Unit]
ent: HajiFund Backend API
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

[Install]
WantedBy=multi-user.target
EOF

# Frontend service
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

[Install]
WantedBy=multi-user.target
EOF

# 5. Fix nginx configuration
print_info "Updating nginx configuration..."

# Create nginx config if it doesn't exist
if [ ! -f "/etc/nginx/sites-available/hajifund" ]; then
    cat > /etc/nginx/sites-available/hajifund << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Frontend (GoFiber) - Port 3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Backend API (Go/Gin) - Port 8080
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files
    location /static/ {
        alias /var/www/hajifund/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
fi

# Enable site
ln -sf /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 6. Create environment files if they don't exist
print_info "Creating environment files..."

if [ ! -f "/var/www/hajifund/.env" ]; then
    cat > /var/www/hajifund/.env << 'EOF'
DB_HOST=localhost
DB_PORT=5432
DB_USER=hajifund_user
DB_PASSWORD=postgres
DB_SSLMODE=disable
JWT_SECRET=your-super-secret-jwt-key-change-in-production
PORT=8080
ENVIRONMENT=production
EOF
fi

if [ ! -f "/var/www/hajifund/frontend/.env" ]; then
    cat > /var/www/hajifund/frontend/.env << 'EOF'
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production
EOF
fi

# 7. Reload and start services
print_info "Reloading systemd and starting services..."
systemctl daemon-reload
systemctl enable hajifund-backend hajifund-frontend

# Start services in order
systemctl start hajifund-backend
sleep 10

systemctl start hajifund-frontend
sleep 10

systemctl start nginx
sleep 5

# 8. Test services
print_step "Testing services..."

sleep 15

echo "Testing backend..."
if curl -f -s http://localhost:8080/api/v1/health > /dev/null; then
    print_status "Backend is responding"
else
    print_warning "Backend is not responding"
    echo "Backend logs:"
    journalctl -u hajifund-backend -n 10 --no-pager
fi

echo "Testing frontend..."
if curl -f -s http://localhost:3000 > /dev/null; then
    print_status "Frontend is responding"
else
    print_warning "Frontend is not responding"
    echo "Frontend logs:"
    journalctl -u hajifund-frontend -n 10 --no-pager
fi

echo "Testing nginx..."
if curl -f -s http://localhost/ > /dev/null; then
    print_status "Nginx is responding"
else
    print_warning "Nginx is not responding"
    echo "Nginx logs:"
    journalctl -u nginx -n 10 --no-pager
fi

# 9. Show final status
print_step "Final service status..."
echo "Backend:"
systemctl status hajifund-backend --no-pager -l

echo ""
echo "Frontend:"
systemctl status hajifund-frontend --no-pager -l

echo ""
echo "Nginx:"
systemctl status nginx --no-pager -l

print_status "Quick fix completed!"
print_info "Try accessing your site now: http://103.103.20.68"
print_info "If still having issues, run: ./troubleshoot-404.sh"
