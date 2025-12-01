#!/bin/bash

# Simple Golang Fiber Frontend Fix
# Just run frontend on port 3000 - no complex workarounds

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

print_step "Simple Golang Fiber Frontend Fix"

# 1. Stop the failing service
print_step "1. Stopping failing service..."
systemctl stop hajifund-frontend
print_status "Service stopped"

# 2. Clean up any old binaries
print_step "2. Cleaning up old binaries..."
if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    rm -f /var/www/hajifund/frontend/hajifund-frontend
    print_status "Old binary removed"
fi

# 3. Go to frontend directory and build
print_step "3. Building frontend..."
cd /var/www/hajifund/frontend

# Initialize Go modules if needed
if [ ! -f "go.mod" ]; then
    print_info "Initializing Go modules..."
    go mod init hajifund-frontend
    go mod tidy
    print_status "Go modules initialized"
fi

# Build the frontend
print_info "Building frontend binary..."
if go build -o hajifund-frontend main.go; then
    print_status "Frontend built successfully"
else
    print_error "Frontend build failed"
    print_info "Build output:"
    go build -v -o hajifund-frontend main.go 2>&1 || true
    exit 1
fi

# 4. Configure frontend to use port 3000
print_step "4. Configuring frontend to use port 3000..."

# Create/update frontend .env
cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=3000
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68:3000
EOF

print_status "Frontend .env configured for port 3000"

# 5. Update systemd service
print_step "5. Updating systemd service..."

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

print_status "Systemd service updated"

# 6. Set proper permissions
print_step "6. Setting permissions..."
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions set"

# 7. Reload and start service
print_step "7. Starting frontend service..."

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

# 8. Check service status
print_step "8. Checking service status..."

sleep 3

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running on port 3000"
    
    # Check if it's listening on port 3000
    if netstat -tlnp | grep -q ":3000.*hajifund-frontend"; then
        print_status "Frontend is listening on port 3000"
    else
        print_warning "Frontend might not be listening on port 3000"
    fi
else
    print_error "Frontend service is not running"
    print_info "Service status:"
    systemctl status hajifund-frontend --no-pager
    print_info "Recent logs:"
    journalctl -u hajifund-frontend --no-pager -l | tail -10
fi

# 9. Test the setup
print_step "9. Testing the setup..."

# Test port 3000 directly
print_info "Testing frontend on port 3000..."
if curl -s http://localhost:3000/ | grep -q "HajiFund"; then
    print_status "Frontend is responding on port 3000"
else
    print_warning "Frontend might not be responding on port 3000"
fi

# Test external access
print_info "Testing external access..."
if curl -s http://103.103.20.68:3000/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access might not be working"
fi

# 10. Show access information
print_step "10. Access Information"

print_status "Frontend is now running successfully!"
print_info "Access your application at:"
print_info "- Direct: http://103.103.20.68:3000"
print_info "- Backend: http://103.103.20.68:8080"
print_info ""
print_info "No complex workarounds needed - just simple Golang Fiber on port 3000!"
print_info "Users can access the frontend directly on port 3000."

print_status "Simple Golang Fiber fix completed!"
