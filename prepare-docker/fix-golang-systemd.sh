#!/bin/bash

# Fix Golang Systemd Services Script
# This script fixes the failing systemd services by compiling Go applications
# and updating the service configurations to use compiled binaries

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}==> $1${NC}"
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step "Fixing Golang Systemd Services"

# Configuration
PROJECT_DIR="/var/www/hajifund"
BACKEND_DIR="$PROJECT_DIR"
FRONTEND_DIR="$PROJECT_DIR/frontend"
BACKEND_BINARY="$PROJECT_DIR/hajifund-backend"
FRONTEND_BINARY="$PROJECT_DIR/frontend/hajifund-frontend"

# 1. Stop the failing services
print_step "1. Stopping failing services..."
sudo systemctl stop hajifund-backend hajifund-frontend
print_status "Services stopped"

# 2. Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

# 3. Fix backend
print_step "2. Fixing backend service..."

cd $BACKEND_DIR

# Check if main.go exists
if [ ! -f "main.go" ]; then
    print_error "main.go not found in $BACKEND_DIR"
    exit 1
fi

# Initialize go mod if needed
if [ ! -f "go.mod" ]; then
    print_info "Initializing go.mod for backend..."
    go mod init hajifund-backend
fi

# Download dependencies
print_info "Downloading backend dependencies..."
go mod tidy

# Compile backend
print_info "Compiling backend..."
go build -o $BACKEND_BINARY main.go

# Set permissions
sudo chown www-data:www-data $BACKEND_BINARY
sudo chmod +x $BACKEND_BINARY

print_status "Backend compiled successfully"

# 4. Fix frontend
print_step "3. Fixing frontend service..."

cd $FRONTEND_DIR

# Check if main.go exists
if [ ! -f "main.go" ]; then
    print_error "main.go not found in $FRONTEND_DIR"
    exit 1
fi

# Initialize go mod if needed
if [ ! -f "go.mod" ]; then
    print_info "Initializing go.mod for frontend..."
    go mod init hajifund-frontend
fi

# Download dependencies
print_info "Downloading frontend dependencies..."
go mod tidy

# Compile frontend
print_info "Compiling frontend..."
go build -o $FRONTEND_BINARY main.go

# Set permissions
sudo chown www-data:www-data $FRONTEND_BINARY
sudo chmod +x $FRONTEND_BINARY

print_status "Frontend compiled successfully"

# 5. Update systemd services
print_step "4. Updating systemd services..."

# Update backend service
sudo tee /etc/systemd/system/hajifund-backend.service > /dev/null << EOF
[Unit]
Description=HajiFund Backend Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$BACKEND_DIR
ExecStart=$BACKEND_BINARY
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=HOST=0.0.0.0
Environment=PORT=8080
Environment=DB_HOST=localhost
Environment=DB_PORT=5432
Environment=DB_USER=postgres
Environment=DB_PASSWORD=postgres
Environment=DB_NAME=postgres
Environment=REDIS_HOST=localhost
Environment=REDIS_PORT=6379
Environment=REDIS_PASSWORD=redis123
Environment=JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
Environment=CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080
Environment=TRUSTED_PROXIES=103.103.20.68,127.0.0.1
Environment=COOKIE_DOMAIN=103.103.20.68
Environment=COOKIE_PATH=/
Environment=COOKIE_SECURE=false
Environment=COOKIE_SAME_SITE=Lax
Environment=COOKIE_HTTP_ONLY=true

[Install]
WantedBy=multi-user.target
EOF

# Update frontend service
sudo tee /etc/systemd/system/hajifund-frontend.service > /dev/null << EOF
[Unit]
Description=HajiFund Frontend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$FRONTEND_DIR
ExecStart=$FRONTEND_BINARY
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=HOST=0.0.0.0
Environment=PORT=3000
Environment=API_BASE_URL=http://localhost:8080
Environment=BACKEND_URL=http://localhost:8080
Environment=FRONTEND_URL=http://103.103.20.68
Environment=CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080
Environment=TRUSTED_PROXIES=103.103.20.68,127.0.0.1
Environment=COOKIE_DOMAIN=103.103.20.68
Environment=COOKIE_PATH=/
Environment=COOKIE_SECURE=false
Environment=COOKIE_SAME_SITE=Lax
Environment=COOKIE_HTTP_ONLY=true

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd services updated"

# 6. Reload systemd and start services
print_step "5. Reloading systemd and starting services..."

sudo systemctl daemon-reload
sudo systemctl enable hajifund-backend hajifund-frontend

# Start services
sudo systemctl start hajifund-backend hajifund-frontend

# Wait a moment for services to start
sleep 5

# Check service status
print_step "6. Checking service status..."

if sudo systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service failed to start"
    print_info "Backend logs:"
    sudo journalctl -u hajifund-backend --no-pager -n 20
fi

if sudo systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running"
else
    print_error "Frontend service failed to start"
    print_info "Frontend logs:"
    sudo journalctl -u hajifund-frontend --no-pager -n 20
fi

# 7. Test services
print_step "7. Testing services..."

# Test backend
if curl -f http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend API is responding"
else
    print_warning "Backend API health check failed"
fi

# Test frontend
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    print_status "Frontend is responding"
else
    print_warning "Frontend health check failed"
fi

# 8. Show final status
print_step "8. Final service status:"
sudo systemctl status hajifund-backend hajifund-frontend --no-pager

print_status "Golang systemd services fixed successfully!"

print_info "Service URLs:"
print_info "  Backend API: http://103.103.20.68:8080"
print_info "  Frontend: http://103.103.20.68:3000"

print_info "Management commands:"
print_info "  sudo systemctl status hajifund-backend hajifund-frontend"
print_info "  sudo systemctl restart hajifund-backend hajifund-frontend"
print_info "  sudo journalctl -u hajifund-backend -f"
print_info "  sudo journalctl -u hajifund-frontend -f"
