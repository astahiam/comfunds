#!/bin/bash

# Deploy HajiFund with Proper Permissions
# This script deploys the application and sets correct permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step "Deploying HajiFund with Proper Permissions"

# 1. Create directory structure
print_step "1. Creating directory structure..."

mkdir -p /var/www/hajifund/{frontend,logs,uploads}
print_status "Directory structure created"

# 2. Set initial ownership
print_step "2. Setting initial ownership..."

chown -R www-data:www-data /var/www/hajifund
print_status "Initial ownership set"

# 3. Build applications
print_step "3. Building applications..."

# Build backend
cd /var/www/hajifund
if [ -f "main.go" ]; then
    go build -o hajifund-backend main.go
    print_status "Backend built"
else
    print_error "Backend main.go not found"
fi

# Build frontend
cd /var/www/hajifund/frontend
if [ -f "main.go" ]; then
    go build -o hajifund-frontend main.go
    print_status "Frontend built"
else
    print_error "Frontend main.go not found"
fi

# 4. Set permissions according to best practices
print_step "4. Setting permissions according to best practices..."

# Directories: 755 (owner: rwx, group: rx, other: rx)
find /var/www/hajifund -type d -exec chmod 755 {} \;
print_status "Directory permissions set to 755"

# Files: 644 (owner: rw, group: r, other: r)
find /var/www/hajifund -type f -exec chmod 644 {} \;
print_status "File permissions set to 644"

# Go binaries: executable
chmod +x /var/www/hajifund/hajifund-backend
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Go binaries made executable"

# .env files: 600 (owner: rw, group: none, other: none)
find /var/www/hajifund -name ".env" -type f -exec chmod 600 {} \; 2>/dev/null || true
print_status ".env files set to 600"

# 5. Apply setcap for frontend
print_step "5. Applying setcap for frontend..."

setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend
print_status "Setcap applied for frontend"

# 6. Create systemd services
print_step "6. Creating systemd services..."

# Backend service
cat > /etc/systemd/system/hajifund-backend.service << 'EOF'
[Unit]
Description=HajiFund Backend Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund
ExecStart=/var/www/hajifund/hajifund-backend
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

# Frontend service
cat > /etc/systemd/system/hajifund-frontend.service << 'EOF'
[Unit]
Description=HajiFund Frontend Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund/frontend
ExecStart=/var/www/hajifund/frontend/hajifund-frontend
Restart=always
RestartSec=5
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd services created"

# 7. Reload systemd and start services
print_step "7. Starting services..."

systemctl daemon-reload
systemctl enable hajifund-backend
systemctl enable hajifund-frontend
systemctl start hajifund-backend
systemctl start hajifund-frontend

print_status "Services started"

# 8. Verify permissions
print_step "8. Verifying permissions..."

print_status "Final permission summary:"
echo "Ownership:"
ls -la /var/www/hajifund | head -5

echo "Directory permissions:"
find /var/www/hajifund -type d -exec ls -ld {} \; | head -5

echo "File permissions:"
find /var/www/hajifund -type f -exec ls -l {} \; | head -5

# 9. Test services
print_step "9. Testing services..."

sleep 5

# Test backend
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding"
else
    print_error "Backend is not responding"
fi

# Test frontend
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_error "Frontend is not responding"
fi

print_status "HajiFund deployment with proper permissions completed!"
print_status "✅ Directory structure created"
print_status "✅ Applications built"
print_status "✅ Permissions set correctly"
print_status "✅ Services configured and started"
print_status "✅ Applications tested"
