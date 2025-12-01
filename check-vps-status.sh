#!/bin/bash

# VPS Status Check Script
# This script checks what's happening after configuration changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

print_step "Checking VPS Status After Configuration Changes"

# 1. Check service status
print_step "1. Checking service status..."

echo "Backend service status:"
systemctl status hajifund-backend --no-pager -l | head -10

echo ""
echo "Frontend service status:"
systemctl status hajifund-frontend --no-pager -l | head -10

echo ""
echo "Nginx service status:"
systemctl status nginx --no-pager -l | head -10

# 2. Check port usage
print_step "2. Checking port usage..."

echo "Port 80 usage:"
lsof -i :80 || echo "No process using port 80"

echo ""
echo "Port 3000 usage:"
lsof -i :3000 || echo "No process using port 3000"

echo ""
echo "Port 8080 usage:"
lsof -i :8080 || echo "No process using port 8080"

# 3. Check if applications are responding
print_step "3. Checking application responses..."

echo "Testing localhost:80 (frontend):"
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "Frontend responding on localhost:80"
else
    print_error "Frontend NOT responding on localhost:80"
fi

echo "Testing localhost:8080 (backend):"
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend responding on localhost:8080"
else
    print_error "Backend NOT responding on localhost:8080"
fi

echo "Testing external IP:80 (frontend):"
if curl -f -s http://103.103.20.68 > /dev/null 2>&1; then
    print_status "Frontend responding on external IP:80"
else
    print_error "Frontend NOT responding on external IP:80"
fi

# 4. Check application logs
print_step "4. Checking application logs..."

echo "Backend logs (last 10 lines):"
journalctl -u hajifund-backend -n 10 --no-pager || echo "No backend logs found"

echo ""
echo "Frontend logs (last 10 lines):"
journalctl -u hajifund-frontend -n 10 --no-pager || echo "No frontend logs found"

# 5. Check configuration files
print_step "5. Checking configuration files..."

echo "Backend environment file:"
if [ -f "/var/www/hajifund/.env" ]; then
    print_status "Backend .env exists"
    echo "Key settings:"
    grep -E "(PORT|JWT_SECRET|CORS_ORIGINS)" /var/www/hajifund/.env || echo "No key settings found"
else
    print_error "Backend .env file not found"
fi

echo ""
echo "Frontend environment file:"
if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_status "Frontend .env exists"
    echo "Key settings:"
    grep -E "(PORT|BACKEND_URL|FRONTEND_URL)" /var/www/hajifund/frontend/.env || echo "No key settings found"
else
    print_error "Frontend .env file not found"
fi

# 6. Check if applications are built
print_step "6. Checking if applications are built..."

echo "Backend binary:"
if [ -f "/var/www/hajifund/backend" ]; then
    print_status "Backend binary exists"
    ls -la /var/www/hajifund/backend
else
    print_error "Backend binary not found"
fi

echo ""
echo "Frontend binary:"
if [ -f "/var/www/hajifund/frontend/frontend" ]; then
    print_status "Frontend binary exists"
    ls -la /var/www/hajifund/frontend/frontend
else
    print_error "Frontend binary not found"
fi

# 7. Test session functionality
print_step "7. Testing session functionality..."

echo "Testing registration:"
REGISTER_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"TestPassword123!","phone":"+6281234567890","address":"Test Address","roles":["investor"]}' \
  -w "HTTP Status: %{http_code}\n")

echo "$REGISTER_RESPONSE"

echo ""
echo "Testing login:"
LOGIN_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPassword123!"}' \
  -c /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n")

echo "$LOGIN_RESPONSE"

echo ""
echo "Cookie analysis:"
if [ -f "/tmp/test_cookies.txt" ] && [ -s "/tmp/test_cookies.txt" ]; then
    print_status "Cookies are being set"
    cat /tmp/test_cookies.txt
else
    print_error "No cookies are being set"
fi

# 8. Recommendations
print_step "8. Recommendations..."

echo ""
print_info "🔍 Analysis Results:"
print_info ""

# Check if services are running
if systemctl is-active --quiet hajifund-backend && systemctl is-active --quiet hajifund-frontend; then
    print_status "Services are running"
else
    print_error "Services are not running properly"
    print_info "Try: systemctl restart hajifund-backend hajifund-frontend"
fi

# Check if port 80 is being used
if lsof -i :80 > /dev/null 2>&1; then
    print_status "Port 80 is in use"
else
    print_error "Port 80 is not in use"
    print_info "Frontend might not be running on port 80"
fi

# Check if external access works
if curl -f -s http://103.103.20.68 > /dev/null 2>&1; then
    print_status "External access works"
else
    print_error "External access doesn't work"
    print_info "Check firewall: ufw status"
    print_info "Check if port 80 is open: netstat -tlnp | grep :80"
fi

echo ""
print_info "💡 Common Issues and Solutions:"
print_info "1. Services not restarting: systemctl restart hajifund-backend hajifund-frontend"
print_info "2. Port conflicts: Check if nginx is still running and stop it"
print_info "3. Firewall issues: ufw allow 80"
print_info "4. Application not built: Run the build commands again"
print_info "5. Configuration not applied: Check .env files"
print_info ""
print_info "🔄 If nothing works, try:"
print_info "1. Restart VPS: sudo reboot"
print_info "2. Or use Docker deployment instead"
print_info ""
print_info "VPS changes usually apply immediately, but sometimes services need restarts!"
