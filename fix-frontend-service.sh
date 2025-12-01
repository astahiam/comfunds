#!/bin/bash

# Fix Frontend Service Issues
# This script fixes the frontend systemd service that's failing to start

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

print_step "Fixing Frontend Service Issues"

# 1. Stop the failing service
print_step "1. Stopping failing frontend service..."

if systemctl is-active --quiet hajifund-frontend; then
    print_info "Stopping frontend service..."
    systemctl stop hajifund-frontend
    print_status "Frontend service stopped"
else
    print_info "Frontend service is not running"
fi

# 2. Check if frontend directory exists
print_step "2. Checking frontend directory..."

if [ -d "/var/www/hajifund/frontend" ]; then
    print_info "Frontend directory exists"
else
    print_error "Frontend directory not found at /var/www/hajifund/frontend"
    exit 1
fi

# 3. Check if main.go exists in frontend
print_step "3. Checking frontend main.go..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Frontend main.go found"
else
    print_error "Frontend main.go not found"
    exit 1
fi

# 4. Check for compilation errors
print_step "4. Checking for compilation errors..."

cd /var/www/hajifund/frontend

print_info "Checking Go modules..."
if [ -f "go.mod" ]; then
    print_info "Go modules found"
    go mod tidy
    print_status "Go modules updated"
else
    print_warning "No go.mod found, initializing..."
    go mod init hajifund-frontend
    go mod tidy
    print_status "Go modules initialized"
fi

print_info "Testing compilation..."
if go build -o hajifund-frontend main.go; then
    print_status "Frontend compiles successfully"
else
    print_error "Frontend compilation failed"
    print_info "Checking for specific errors..."
    go build -v -o hajifund-frontend main.go 2>&1 | head -20
    exit 1
fi

# 5. Check if binary was created
print_step "5. Checking if binary was created..."

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_status "Frontend binary created successfully"
    
    # Make it executable
    chmod +x /var/www/hajifund/frontend/hajifund-frontend
    print_status "Binary made executable"
else
    print_error "Frontend binary not created"
    exit 1
fi

# 6. Check frontend environment
print_step "6. Checking frontend environment..."

if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_info "Frontend .env file found"
    
    # Check if PORT is set
    if grep -q "PORT" /var/www/hajifund/frontend/.env; then
        print_info "PORT found in .env"
    else
        print_warning "PORT not found, adding..."
        echo "PORT=80" >> /var/www/hajifund/frontend/.env
        print_status "PORT added to .env"
    fi
    
    # Check if API_BASE_URL is set
    if grep -q "API_BASE_URL" /var/www/hajifund/frontend/.env; then
        print_info "API_BASE_URL found in .env"
    else
        print_warning "API_BASE_URL not found, adding..."
        echo "API_BASE_URL=http://103.103.20.68:8080" >> /var/www/hajifund/frontend/.env
        print_status "API_BASE_URL added to .env"
    fi
else
    print_warning "Frontend .env file not found, creating..."
    cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF
    print_status "Frontend .env file created"
fi

# 7. Update systemd service
print_step "7. Updating systemd service..."

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

print_status "Systemd service updated"

# 8. Set proper permissions
print_step "8. Setting proper permissions..."

chown -R www-data:www-data /var/www/hajifund/frontend
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Permissions set"

# 9. Reload systemd and start service
print_step "9. Reloading systemd and starting service..."

systemctl daemon-reload
print_status "Systemd reloaded"

# Start the service
print_info "Starting frontend service..."
if systemctl start hajifund-frontend; then
    print_status "Frontend service started"
else
    print_error "Failed to start frontend service"
    systemctl status hajifund-frontend
    exit 1
fi

# 10. Check service status
print_step "10. Checking service status..."

sleep 3

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running"
    
    # Check if it's listening on port 80
    if netstat -tlnp | grep -q ":80.*hajifund-frontend"; then
        print_status "Frontend is listening on port 80"
    else
        print_warning "Frontend might not be listening on port 80"
    fi
else
    print_error "Frontend service is not running"
    print_info "Checking service status..."
    systemctl status hajifund-frontend
    print_info "Checking logs..."
    journalctl -u hajifund-frontend --no-pager -l
fi

# 11. Test frontend
print_step "11. Testing frontend..."

print_info "Testing frontend response..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding correctly"
else
    print_warning "Frontend might not be responding correctly"
    print_info "Trying localhost test..."
    if curl -s http://localhost/ | grep -q "HajiFund"; then
        print_status "Frontend responds on localhost"
    else
        print_error "Frontend is not responding"
    fi
fi

print_status "Frontend service fix completed!"
print_info "Frontend should now be accessible at: http://103.103.20.68"
print_info "To check logs: journalctl -u hajifund-frontend -f"
