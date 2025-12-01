#!/bin/bash

# Fix API JSON Error
# This script fixes the "Unexpected token '<'" error when login/register

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

print_step "Fixing API JSON Error"

# 1. Check backend service
print_step "1. Checking backend service..."

if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service is not running"
    print_info "Starting backend service..."
    systemctl start hajifund-backend
    sleep 3
    
    if systemctl is-active --quiet hajifund-backend; then
        print_status "Backend service started"
    else
        print_error "Backend service failed to start"
        systemctl status hajifund-backend --no-pager
        exit 1
    fi
fi

# 2. Test backend API directly
print_step "2. Testing backend API directly..."

print_info "Testing backend health endpoint..."
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend health endpoint is working"
else
    print_warning "Backend health endpoint might not be working"
    print_info "Response:"
    curl -s http://localhost:8080/api/v1/health || true
fi

# 3. Test login endpoint directly
print_step "3. Testing login endpoint directly..."

print_info "Testing login endpoint..."
login_response=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}')

print_info "Login response:"
echo "$login_response"

if echo "$login_response" | grep -q "auth_token"; then
    print_status "Login endpoint returns JSON with auth_token"
elif echo "$login_response" | grep -q "<!DOCTYPE"; then
    print_error "Login endpoint returns HTML instead of JSON"
    print_info "This means the API route is not found or misconfigured"
else
    print_warning "Login endpoint response is unclear"
fi

# 4. Check backend routes
print_step "4. Checking backend routes..."

print_info "Checking if backend main.go has auth routes..."
if [ -f "/var/www/hajifund/main.go" ]; then
    if grep -q "auth/login" /var/www/hajifund/main.go; then
        print_status "Auth login route found in backend"
    else
        print_error "Auth login route NOT found in backend"
        print_info "Backend routes:"
        grep -n "\.Post\|\.Get" /var/www/hajifund/main.go || true
    fi
else
    print_error "Backend main.go not found"
fi

# 5. Check frontend API calls
print_step "5. Checking frontend API calls..."

print_info "Checking frontend login page..."
if [ -f "/var/www/hajifund/frontend/views/auth/login.html" ]; then
    if grep -q "/api/v1/auth/login" /var/www/hajifund/frontend/views/auth/login.html; then
        print_status "Frontend calls correct API endpoint"
    else
        print_error "Frontend does NOT call correct API endpoint"
        print_info "Frontend API calls:"
        grep -n "fetch\|api" /var/www/hajifund/frontend/views/auth/login.html || true
    fi
else
    print_error "Frontend login page not found"
fi

# 6. Fix frontend API base URL
print_step "6. Fixing frontend API base URL..."

# Update frontend .env
cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF

print_status "Frontend .env updated with correct API base URL"

# 7. Check if frontend is making API calls to the right URL
print_step "7. Checking frontend API configuration..."

# Check if frontend main.go has proper API configuration
if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Checking frontend main.go for API configuration..."
    
    if grep -q "API_BASE_URL" /var/www/hajifund/frontend/main.go; then
        print_status "Frontend main.go uses API_BASE_URL"
    else
        print_warning "Frontend main.go might not use API_BASE_URL"
    fi
else
    print_error "Frontend main.go not found"
fi

# 8. Test API call from frontend perspective
print_step "8. Testing API call from frontend perspective..."

print_info "Testing API call from frontend URL..."
if curl -s http://103.103.20.68:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}' \
    | grep -q "auth_token"; then
    print_status "API call from frontend URL works"
else
    print_warning "API call from frontend URL might not work"
fi

# 9. Rebuild and restart frontend
print_step "9. Rebuilding and restarting frontend..."

# Stop frontend
systemctl stop hajifund-frontend

# Rebuild frontend
cd /var/www/hajifund/frontend
print_info "Rebuilding frontend..."
go build -o hajifund-frontend main.go

# Set permissions
chown -R www-data:www-data /var/www/hajifund/frontend/
chmod +x /var/www/hajifund/frontend/hajifund-frontend

# Reapply setcap
setcap 'cap_net_bind_service=+ep' /var/www/hajifund/frontend/hajifund-frontend

# Start frontend
systemctl start hajifund-frontend
print_status "Frontend rebuilt and restarted"

# 10. Test the complete flow
print_step "10. Testing complete flow..."

sleep 3

# Test frontend
print_info "Testing frontend..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# Test backend
print_info "Testing backend..."
if curl -s http://103.103.20.68:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be responding"
fi

# Test login API
print_info "Testing login API..."
login_test=$(curl -s -X POST http://103.103.20.68:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}')

if echo "$login_test" | grep -q "auth_token"; then
    print_status "Login API returns JSON correctly"
elif echo "$login_test" | grep -q "<!DOCTYPE"; then
    print_error "Login API still returns HTML"
    print_info "This indicates a routing issue in the backend"
else
    print_warning "Login API response is unclear"
fi

print_status "API JSON error fix completed!"
print_info "If the issue persists, check:"
print_info "1. Backend routes are properly configured"
print_info "2. Frontend is calling the correct API URL"
print_info "3. CORS settings allow frontend to call backend"
print_info "4. Backend is listening on the correct port"
