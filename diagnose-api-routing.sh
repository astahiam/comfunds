#!/bin/bash

# HajiFund API Routing Diagnostic Script
# This script diagnoses why VPS API calls are failing with 404

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

print_step "HajiFund API Routing Diagnostic"

echo ""
print_info "🔍 DIAGNOSING API ROUTING ISSUE"
echo "Local: http://127.0.0.1/api/auth/login"
echo "VPS:   http://103.103.20.68/api/auth/login"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

# 1. Check backend service status
print_step "1. Checking backend service status..."
echo "Backend Service Status:"
systemctl status hajifund-backend --no-pager -l || true

# 2. Check if backend is listening on port 8080
print_step "2. Checking backend port listeners..."
echo "Port 8080 listeners:"
netstat -tulpn | grep :8080 || echo "Nothing listening on port 8080"

# 3. Test backend directly
print_step "3. Testing backend API directly..."
echo "Testing backend health endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost:8080/api/v1/health || echo "Backend not responding"

echo ""
echo "Testing backend auth endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost:8080/api/v1/auth/login || echo "Auth endpoint not responding"

# 4. Check nginx configuration
print_step "4. Checking nginx configuration..."
if [ -f "/etc/nginx/sites-available/hajifund" ]; then
    print_status "Nginx config exists"
    echo "Nginx configuration for API routes:"
    grep -A 10 -B 2 "location /api/" /etc/nginx/sites-available/hajifund || echo "No API location block found"
else
    print_error "Nginx configuration not found"
fi

# 5. Test nginx routing
print_step "5. Testing nginx API routing..."
echo "Testing nginx API proxy:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/ || echo "Nginx API proxy not working"

echo ""
echo "Testing nginx auth endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/v1/auth/login || echo "Nginx auth proxy not working"

# 6. Check frontend environment variables
print_step "6. Checking frontend environment variables..."
if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_status "Frontend .env exists"
    echo "Frontend environment variables:"
    cat /var/www/hajifund/frontend/.env
else
    print_error "Frontend .env not found"
fi

# 7. Check backend environment variables
print_step "7. Checking backend environment variables..."
if [ -f "/var/www/hajifund/.env" ]; then
    print_status "Backend .env exists"
    echo "Backend environment variables:"
    cat /var/www/hajifund/.env
else
    print_error "Backend .env not found"
fi

# 8. Check application logs
print_step "8. Checking application logs..."
echo "Backend logs (last 20 lines):"
journalctl -u hajifund-backend -n 20 --no-pager || echo "No backend logs found"

echo ""
echo "Frontend logs (last 20 lines):"
journalctl -u hajifund-frontend -n 20 --no-pager || echo "No frontend logs found"

echo ""
echo "Nginx logs (last 20 lines):"
journalctl -u nginx -n 20 --no-pager || echo "No nginx logs found"

# 9. Test external access
print_step "9. Testing external access..."
echo "Testing external API access:"
curl -s -w "HTTP Status: %{http_code}\n" http://103.103.20.68/api/v1/health || echo "External API not accessible"

echo ""
echo "Testing external auth endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" http://103.103.20.68/api/v1/auth/login || echo "External auth endpoint not accessible"

# 10. Check firewall
print_step "10. Checking firewall rules..."
echo "UFW status:"
ufw status || echo "UFW not configured"

echo ""
echo "iptables rules for port 80:"
iptables -L INPUT -n | grep :80 || echo "No specific iptables rules for port 80"

echo ""
echo "iptables rules for port 8080:"
iptables -L INPUT -n | grep :8080 || echo "No specific iptables rules for port 8080"

# 11. Provide diagnosis
print_step "11. DIAGNOSIS RESULTS..."
echo ""
print_info "🔍 ROOT CAUSE ANALYSIS:"
echo ""

# Check if backend is running
if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service is NOT running"
    echo "   → This is likely the main cause of 404 errors"
fi

# Check if nginx is running
if systemctl is-active --quiet nginx; then
    print_status "Nginx service is running"
else
    print_error "Nginx service is NOT running"
fi

# Check if backend responds directly
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend responds directly on port 8080"
else
    print_error "Backend does NOT respond directly on port 8080"
    echo "   → Backend application is not working properly"
fi

# Check if nginx proxies correctly
if curl -f -s http://localhost/api/v1/health > /dev/null 2>&1; then
    print_status "Nginx proxies API requests correctly"
else
    print_error "Nginx does NOT proxy API requests correctly"
    echo "   → Nginx configuration issue"
fi

echo ""
print_info "🛠️  LIKELY SOLUTIONS:"
echo ""

echo "1. If backend service is not running:"
echo "   sudo systemctl start hajifund-backend"
echo "   sudo systemctl enable hajifund-backend"

echo ""
echo "2. If backend doesn't respond on port 8080:"
echo "   cd /var/www/hajifund"
echo "   go build -o hajifund-backend main.go"
echo "   sudo systemctl restart hajifund-backend"

echo ""
echo "3. If nginx doesn't proxy correctly:"
echo "   sudo nginx -t"
echo "   sudo systemctl restart nginx"

echo ""
echo "4. If firewall is blocking:"
echo "   sudo ufw allow 80/tcp"
echo "   sudo ufw allow 443/tcp"

echo ""
echo "5. Quick fix - restart all services:"
echo "   sudo systemctl restart hajifund-backend"
echo "   sudo systemctl restart hajifund-frontend"
echo "   sudo systemctl restart nginx"

print_status "Diagnostic completed!"
