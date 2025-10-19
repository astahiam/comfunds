#!/bin/bash

# HajiFund 404 Troubleshooting Script
# This script helps diagnose and fix 404 errors

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

print_step "HajiFund 404 Troubleshooting"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

# 1. Check service status
print_step "1. Checking service status..."

echo "Backend Service:"
systemctl status hajifund-backend --no-pager -l || true

echo ""
echo "Frontend Service:"
systemctl status hajifund-frontend --no-pager -l || true

echo ""
echo "Nginx Service:"
systemctl status nginx --no-pager -l || true

# 2. Check if services are listening on ports
print_step "2. Checking port listeners..."

echo "Port 8080 (Backend):"
netstat -tulpn | grep :8080 || echo "Nothing listening on port 8080"

echo "Port 3000 (Frontend):"
netstat -tulpn | grep :3000 || echo "Nothing listening on port 3000"

echo "Port 80 (Nginx):"
netstat -tulpn | grep :80 || echo "Nothing listening on port 80"

# 3. Test direct connections
print_step "3. Testing direct connections..."

echo "Testing backend directly:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/api/v1/health || echo "Backend not responding"

echo "Testing frontend directly:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3000/ || echo "Frontend not responding"

echo "Testing nginx:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "Nginx not responding"

# 4. Check application logs
print_step "4. Checking application logs..."

echo "Backend logs (last 20 lines):"
journalctl -u hajifund-backend -n 20 --no-pager || echo "No backend logs found"

echo ""
echo "Frontend logs (last 20 lines):"
journalctl -u hajifund-frontend -n 20 --no-pager || echo "No frontend logs found"

echo ""
echo "Nginx logs (last 20 lines):"
journalctl -u nginx -n 20 --no-pager || echo "No nginx logs found"

# 5. Check application files
print_step "5. Checking application files..."

if [ -f "/var/www/hajifund/hajifund-backend" ]; then
    print_status "Backend binary exists"
    ls -la /var/www/hajifund/hajifund-backend
else
    print_error "Backend binary not found"
    print_info "Looking for Go files..."
    ls -la /var/www/hajifund/main.go || echo "main.go not found"
fi

if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    print_status "Frontend binary exists"
    ls -la /var/www/hajifund/frontend/hajifund-frontend
else
    print_error "Frontend binary not found"
    print_info "Looking for frontend Go files..."
    ls -la /var/www/hajifund/frontend/main.go || echo "frontend/main.go not found"
fi

# 6. Check nginx configuration
print_step "6. Checking nginx configuration..."

if [ -f "/etc/nginx/sites-available/hajifund" ]; then
    print_status "Nginx config exists"
    echo "Nginx configuration:"
    cat /etc/nginx/sites-available/hajifund
else
    print_error "Nginx configuration not found"
fi

# 7. Check nginx syntax
print_info "Checking nginx syntax..."
nginx -t 2>&1 || print_error "Nginx configuration has errors"

# 8. Check environment variables
print_step "7. Checking environment variables..."

if [ -f "/var/www/hajifund/.env" ]; then
    print_status "Backend .env exists"
    echo "Backend environment variables:"
    cat /var/www/hajifund/.env
else
    print_error "Backend .env not found"
fi

if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_status "Frontend .env exists"
    echo "Frontend environment variables:"
    cat /var/www/hajifund/frontend/.env
else
    print_error "Frontend .env not found"
fi

# 9. Try to restart services
print_step "8. Attempting to restart services..."

print_info "Restarting backend..."
systemctl restart hajifund-backend
sleep 5

print_info "Restarting frontend..."
systemctl restart hajifund-frontend
sleep 5

print_info "Restarting nginx..."
systemctl restart nginx
sleep 5

# 10. Test again after restart
print_step "9. Testing after restart..."

sleep 10

echo "Testing backend after restart:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/api/v1/health || echo "Backend still not responding"

echo "Testing frontend after restart:"
curl -s -o /dev/nulladow -w "HTTP Status: %{http_code}\n" http://localhost:3000/ || echo "Frontend still not responding"

echo "Testing nginx after restart:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "Nginx still not responding"

# 11. Provide solutions
print_step "10. Recommended solutions..."

echo ""
print_info "Common 404 solutions:"

echo "1. If backend is not responding:"
echo "   - Check if the application is built: go build -o hajifund-backend main.go"
echo "   - Check if the binary is executable: chmod +x hajifund-backend"
echo "   - Check logs: journalctl -u hajifund-backend -f"

echo ""
echo "2. If frontend is not responding:"
echo "   - Check if the application is built: cd frontend && go build -o hajifund-frontend main.go"
echo "   - Check if the binary is executable: chmod +x hajifund-frontend"
echo "   - Check logs: journalctl -u hajifund-frontend -f"

echo ""
echo "3. If nginx is not responding:"
echo "   - Check nginx config: nginx -t"
echo "   - Check if site is enabled: ls -la /etc/nginx/sites-enabled/"
echo "   - Check nginx logs: journalctl -u nginx -f"

echo ""
echo "4. Quick fix commands:"
echo "   sudo systemctl stop hajifund-backend hajifund-frontend"
echo "   cd /var/www/hajifund && go build -o hajifund-backend main.go"
echo "   cd /var/www/hajifund/frontend && go build -o hajifund-frontend main.go"
echo "   sudo chown www-data:www-data hajifund-backend frontend/hajifund-frontend"
echo "   sudo chmod +x hajifund-backend frontend/hajifund-frontend"
echo "   sudo systemctl start hajifund-backend hajifund-frontend"

print_status "Troubleshooting completed!"
