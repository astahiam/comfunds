#!/bin/bash

# HajiFund Session Persistence Diagnostic Script
# This script diagnoses why login works but session doesn't persist

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

print_step "Diagnosing Session Persistence Issue"

# 1. Test registration and login endpoints
print_step "1. Testing registration and login endpoints..."

# Test user credentials
TEST_EMAIL="testuser@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

echo "Testing registration with curl:"
curl -v -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -c /tmp/register_cookies.txt 2>&1 | grep -E "(Cookie|Set-Cookie|HTTP|Location)"

echo ""
echo "Testing login with curl:"
curl -v -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/login_cookies.txt 2>&1 | grep -E "(Cookie|Set-Cookie|HTTP|Location)"

echo ""
echo "Cookies saved:"
if [ -f "/tmp/login_cookies.txt" ]; then
    cat /tmp/login_cookies.txt
else
    print_error "No cookies were set"
fi

# 2. Test with cookies
echo ""
echo "Testing profile endpoint with cookies:"
curl -v http://localhost:8080/api/v1/user/profile \
  -b /tmp/login_cookies.txt 2>&1 | grep -E "(Cookie|HTTP|Location|Authorization)"

# 3. Test through nginx
echo ""
echo "Testing through nginx:"
curl -v -X POST http://localhost/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -c /tmp/nginx_register_cookies.txt 2>&1 | grep -E "(Cookie|Set-Cookie|HTTP|Location)"

echo ""
echo "Testing login through nginx:"
curl -v -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/nginx_login_cookies.txt 2>&1 | grep -E "(Cookie|Set-Cookie|HTTP|Location)"

echo ""
echo "Nginx cookies saved:"
if [ -f "/tmp/nginx_login_cookies.txt" ]; then
    cat /tmp/nginx_login_cookies.txt
else
    print_error "No cookies were set through nginx"
fi

# 4. Test external access
echo ""
echo "Testing external access:"
curl -v -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -c /tmp/external_register_cookies.txt 2>&1 | grep -E "(Cookie|Set-Cookie|HTTP|Location)"

echo ""
echo "Testing login through external access:"
curl -v -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/external_login_cookies.txt 2>&1 | grep -E "(Cookie|Set-Cookie|HTTP|Location)"

echo ""
echo "External cookies saved:"
if [ -f "/tmp/external_login_cookies.txt" ]; then
    cat /tmp/external_login_cookies.txt
else
    print_error "No cookies were set through external access"
fi

# 5. Check backend logs
print_step "2. Checking backend logs for cookie issues..."

echo "Backend logs (last 50 lines):"
journalctl -u hajifund-backend -n 50 --no-pager | grep -E "(cookie|Cookie|auth|login|token)" || echo "No relevant logs found"

# 6. Check frontend logs
echo ""
echo "Frontend logs (last 50 lines):"
journalctl -u hajifund-frontend -n 50 --no-pager | grep -E "(cookie|Cookie|auth|login|token)" || echo "No relevant logs found"

# 7. Check nginx logs
echo ""
echo "Nginx error logs:"
tail -20 /var/log/nginx/error.log | grep -E "(cookie|Cookie|auth|login|token)" || echo "No relevant nginx errors found"

# 8. Check cookie configuration in backend code
print_step "3. Checking cookie configuration in backend..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    echo "Cookie configuration in auth handler:"
    grep -A 15 -B 5 "Cookie" /var/www/hajifund/frontend/handlers/auth.go || echo "No cookie configuration found"
fi

# 9. Check JWT configuration
print_step "4. Checking JWT configuration..."

echo "JWT_SECRET in backend .env:"
grep "JWT_SECRET" /var/www/hajifund/.env || echo "JWT_SECRET not found"

echo ""
echo "JWT configuration in backend code:"
if [ -f "/var/www/hajifund/main.go" ]; then
    grep -A 5 -B 5 "JWT" /var/www/hajifund/main.go || echo "No JWT configuration found"
fi

# 10. Test JWT token validation
print_step "5. Testing JWT token validation..."

echo "Testing JWT token validation endpoint:"
curl -v http://localhost:8080/api/v1/auth/refresh \
  -b /tmp/login_cookies.txt 2>&1 | grep -E "(Cookie|HTTP|Location|Authorization)"

# 11. Check browser cookie settings
print_step "6. Browser cookie analysis..."

echo "Cookie analysis:"
echo "1. Check if cookies are being set with correct domain"
echo "2. Check if cookies are being sent with requests"
echo "3. Check if cookies are being cleared immediately"
echo "4. Check if cookies have correct expiration"

# 12. Provide diagnosis
print_step "7. DIAGNOSIS RESULTS..."

echo ""
print_info "🔍 COMMON SESSION PERSISTENCE ISSUES:"
echo ""

# Check if cookies are being set
if [ -f "/tmp/login_cookies.txt" ] && [ -s "/tmp/login_cookies.txt" ]; then
    print_status "Cookies are being set by backend"
else
    print_error "Cookies are NOT being set by backend"
    echo "   → Backend cookie configuration issue"
fi

# Check if cookies work through nginx
if [ -f "/tmp/nginx_login_cookies.txt" ] && [ -s "/tmp/nginx_login_cookies.txt" ]; then
    print_status "Cookies work through nginx proxy"
else
    print_error "Cookies do NOT work through nginx proxy"
    echo "   → Nginx cookie proxy configuration issue"
fi

# Check if cookies work externally
if [ -f "/tmp/external_login_cookies.txt" ] && [ -s "/tmp/external_login_cookies.txt" ]; then
    print_status "Cookies work through external access"
else
    print_error "Cookies do NOT work through external access"
    echo "   → Domain/CORS cookie configuration issue"
fi

echo ""
print_info "🛠️  RECOMMENDED SOLUTIONS:"
echo ""

echo "1. If cookies are not being set by backend:"
echo "   - Check backend cookie configuration"
echo "   - Verify JWT token generation"
echo "   - Check cookie domain/path settings"

echo ""
echo "2. If cookies don't work through nginx:"
echo "   - Fix nginx proxy_cookie_domain configuration"
echo "   - Fix nginx proxy_cookie_path configuration"
echo "   - Add proxy_set_header Cookie configuration"

echo ""
echo "3. If cookies don't work externally:"
echo "   - Fix CORS configuration"
echo "   - Fix cookie domain settings"
echo "   - Check SameSite cookie attributes"

echo ""
echo "4. Quick fixes to try:"
echo "   - Run: ./fix-jwt-session-issues.sh"
echo "   - Check browser developer tools for cookie issues"
echo "   - Test with different browsers"

print_status "Diagnostic completed!"
print_info "Check the curl output above for specific cookie issues."
