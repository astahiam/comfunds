#!/bin/bash

# HajiFund 502 Bad Gateway Diagnostic Script
# This script diagnoses why nginx returns 502 after registration

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

print_step "Diagnosing 502 Bad Gateway Error"

# 1. Check service status
print_step "1. Checking service status..."

echo "Backend Service Status:"
systemctl status hajifund-backend --no-pager -l || true

echo ""
echo "Frontend Service Status:"
systemctl status hajifund-frontend --no-pager -l || true

echo ""
echo "Nginx Service Status:"
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

# 4. Check application logs for errors
print_step "4. Checking application logs for errors..."

echo "Backend logs (last 50 lines):"
journalctl -u hajifund-backend -n 50 --no-pager || echo "No backend logs found"

echo ""
echo "Frontend logs (last 50 lines):"
journalctl -u hajifund-frontend -n 50 --no-pager || echo "No frontend logs found"

echo ""
echo "Nginx error logs:"
tail -20 /var/log/nginx/error.log || echo "No nginx error log found"

echo ""
echo "Nginx access logs (last 20 lines):"
tail -20 /var/log/nginx/access.log || echo "No nginx access log found"

# 5. Check system resources
print_step "5. Checking system resources..."

echo "Memory usage:"
free -h

echo ""
echo "Disk usage:"
df -h

echo ""
echo "CPU usage:"
top -bn1 | grep "Cpu(s)" || echo "Could not get CPU info"

# 6. Check if backend process is running
print_step "6. Checking backend process..."

echo "Backend processes:"
ps aux | grep -E "(hajifund-backend|go run main.go)" | grep -v grep || echo "No backend processes found"

echo ""
echo "Frontend processes:"
ps aux | grep -E "(hajifund-frontend|go run main.go)" | grep -v grep || echo "No frontend processes found"

# 7. Test database connectivity
print_step "7. Testing database connectivity..."

echo "Testing PostgreSQL connection:"
if systemctl is-active --quiet postgresql; then
    print_status "PostgreSQL is running"
    
    # Test connection to each shard
    for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
        echo "Testing connection to $shard:"
        if PGPASSWORD=postgres psql -h localhost -U postgres -d "$shard" -c "SELECT 1;" > /dev/null 2>&1; then
            print_status "Connection to $shard: OK"
        else
            print_error "Connection to $shard: FAILED"
        fi
    done
else
    print_error "PostgreSQL is not running"
fi

# 8. Check nginx configuration
print_step "8. Checking nginx configuration..."

echo "Nginx configuration test:"
nginx -t || print_error "Nginx configuration has errors"

echo ""
echo "Nginx upstream configuration:"
grep -A 5 -B 5 "upstream backend" /etc/nginx/sites-available/hajifund || echo "No upstream configuration found"

# 9. Test registration endpoint specifically
print_step "9. Testing registration endpoint..."

echo "Testing registration endpoint directly:"
curl -s -w "HTTP Status: %{http_code}\n" -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"Test123!","phone":"+6281234567890","address":"Test Address","roles":["investor"]}' || echo "Registration endpoint not responding"

# 10. Check for recent crashes
print_step "10. Checking for recent crashes..."

echo "System logs (last 50 lines):"
journalctl -n 50 --no-pager | grep -i "error\|crash\|panic\|fatal" || echo "No recent errors found"

echo ""
echo "Backend crash logs:"
journalctl -u hajifund-backend --since "5 minutes ago" --no-pager || echo "No recent backend logs"

# 11. Provide diagnosis and solutions
print_step "11. DIAGNOSIS RESULTS..."

echo ""
print_info "🔍 COMMON CAUSES OF 502 BAD GATEWAY:"
echo ""

# Check if backend is running
if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service is NOT running"
    echo "   → This is the most likely cause of 502 errors"
fi

# Check if backend responds
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend responds to health checks"
else
    print_error "Backend does NOT respond to health checks"
    echo "   → Backend is running but not responding to requests"
fi

# Check if nginx can reach backend
if curl -f -s http://localhost/api/v1/health > /dev/null 2>&1; then
    print_status "Nginx can reach backend"
else
    print_error "Nginx cannot reach backend"
    echo "   → Nginx proxy configuration issue"
fi

echo ""
print_info "🛠️  RECOMMENDED SOLUTIONS:"
echo ""

echo "1. If backend service is not running:"
echo "   sudo systemctl start hajifund-backend"
echo "   sudo systemctl enable hajifund-backend"

echo ""
echo "2. If backend is running but not responding:"
echo "   sudo systemctl restart hajifund-backend"
echo "   Check logs: sudo journalctl -u hajifund-backend -f"

echo ""
echo "3. If database connection issues:"
echo "   sudo systemctl restart postgresql"
echo "   Run: ./fix-db-permissions-simple.sh"

echo ""
echo "4. If nginx proxy issues:"
echo "   sudo nginx -t"
echo "   sudo systemctl restart nginx"

echo ""
echo "5. If memory/disk issues:"
echo "   sudo systemctl restart hajifund-backend hajifund-frontend"

echo ""
echo "6. Quick fix - restart all services:"
echo "   sudo systemctl restart hajifund-backend hajifund-frontend nginx"

print_status "Diagnostic completed!"
print_info "Check the logs above for specific error messages."
