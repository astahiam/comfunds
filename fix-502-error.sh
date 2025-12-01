#!/bin/bash

# HajiFund 502 Error Quick Fix Script
# This script quickly fixes common causes of 502 Bad Gateway errors

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

print_step "Quick Fix for 502 Bad Gateway Error"

# 1. Stop all services
print_info "Stopping all services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Check if applications are built
print_step "Building applications if needed..."
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

# 4. Check database connectivity
print_step "Checking database connectivity..."
if systemctl is-active --quiet postgresql; then
    print_status "PostgreSQL is running"
    
    # Test connection to each shard
    for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
        if PGPASSWORD=postgres psql -h localhost -U postgres -d "$shard" -c "SELECT 1;" > /dev/null 2>&1; then
            print_status "Connection to $shard: OK"
        else
            print_warning "Connection to $shard: FAILED - will fix permissions"
            # Fix permissions for this shard
            PGPASSWORD=postgres psql -h localhost -U postgres -d "$shard" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;" || true
            PGPASSWORD=postgres psql -h localhost -U postgres -d "$shard" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;" || true
        fi
    done
else
    print_error "PostgreSQL is not running"
    print_info "Starting PostgreSQL..."
    systemctl start postgresql
    sleep 5
fi

# 5. Clear any stuck processes
print_info "Clearing stuck processes..."
pkill -f "hajifund-backend" 2>/dev/null || true
pkill -f "hajifund-frontend" 2>/dev/null || true
pkill -f "go run main.go" 2>/dev/null || true

# 6. Start services in order
print_step "Starting services..."

print_info "Starting backend..."
systemctl start hajifund-backend
sleep 10

# Check if backend is responding
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is responding"
else
    print_error "Backend is not responding"
    echo "Backend logs:"
    journalctl -u hajifund-backend -n 20 --no-pager
    exit 1
fi

print_info "Starting frontend..."
systemctl start hajifund-frontend
sleep 10

# Check if frontend is responding
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "Frontend is responding"
else
    print_error "Frontend is not responding"
    echo "Frontend logs:"
    journalctl -u hajifund-frontend -n 20 --no-pager
fi

print_info "Starting nginx..."
systemctl start nginx
sleep 5

# 7. Test the fix
print_step "Testing the fix..."

sleep 10

echo "Testing backend health endpoint:"
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend health check: OK"
else
    print_error "Backend health check: FAILED"
fi

echo "Testing frontend:"
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "Frontend: OK"
else
    print_error "Frontend: FAILED"
fi

echo "Testing nginx proxy:"
if curl -f -s http://localhost/ > /dev/null 2>&1; then
    print_status "Nginx proxy: OK"
else
    print_error "Nginx proxy: FAILED"
fi

echo "Testing external access:"
if curl -f -s http://103.103.20.68/ > /dev/null 2>&1; then
    print_status "External access: OK"
else
    print_error "External access: FAILED"
fi

# 8. Test registration endpoint
print_step "Testing registration endpoint..."

echo "Testing registration endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"Test123!","phone":"+6281234567890","address":"Test Address","roles":["investor"]}' || echo "Registration endpoint test failed"

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

print_status "502 error fix completed!"
print_info "The 502 Bad Gateway error should now be resolved."
print_info "Try accessing your application again: http://103.103.20.68"
