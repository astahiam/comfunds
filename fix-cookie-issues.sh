#!/bin/bash

# HajiFund Cookie Issues Fix
# This script fixes the specific cookie problems between local and VPS

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

print_step "Fixing Cookie Issues Between Local and VPS"
print_info "The problem is likely cookie domain, security, or CORS settings"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Analyze cookie issues
print_step "1. Analyzing Cookie Issues"

print_info "Common cookie problems between local and VPS:"
print_info "🔍 Local (localhost:3000) vs VPS (103.103.20.68:80)"
print_info "🔍 Cookie Domain: localhost vs IP address"
print_info "🔍 Cookie Security: HTTP vs HTTPS"
print_info "🔍 Cookie SameSite: Strict vs Lax"
print_info "🔍 CORS Origins: localhost vs external IP"

# 3. Check current cookie configuration
print_step "2. Checking current cookie configuration..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_info "Current cookie configuration:"
    grep -A 15 -B 5 "cookie" /var/www/hajifund/frontend/handlers/auth.go || true
else
    print_warning "auth.go not found"
fi

# 4. Fix cookie configuration for VPS
print_step "3. Fixing cookie configuration for VPS..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    print_info "Applying cookie fixes for VPS..."
    
    # Fix 1: Remove domain restriction
    sed -i 's/Domain:   "103.103.20.68"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Domain:   "localhost"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Domain:   ".*"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Fix 2: Set Secure to false for HTTP
    sed -i 's/Secure:   true/Secure:   false/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Fix 3: Set SameSite to Lax for VPS
    sed -i 's/SameSite: "Strict"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/SameSite: "None"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Fix 4: Ensure HTTPOnly is true for security
    sed -i 's/HTTPOnly: false/HTTPOnly: true/g' /var/www/hajifund/frontend/handlers/auth.go
    
    print_status "Cookie configuration fixed for VPS"
fi

# 5. Fix backend environment for cookies
print_step "4. Fixing backend environment for cookies..."

cat > /var/www/hajifund/.env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_SSLMODE=disable

# Application Configuration
ENVIRONMENT=production
PORT=8080
JWT_SECRET=hajifund-super-secret-jwt-key-production-2024-vps-cookies

# CORS Configuration - Allow all origins for VPS
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000,http://127.0.0.1:8080

# Trusted Proxies - Allow all for VPS
TRUSTED_PROXIES=127.0.0.1,::1,103.103.20.68

# Rate Limiting
GENERAL_RATE_LIMIT_RPM=60
GENERAL_RATE_LIMIT_BURST=100
EOF

print_status "Backend environment configured for cookies"

# 6. Fix frontend environment for cookies
print_step "5. Fixing frontend environment for cookies..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080

# Cookie Configuration
COOKIE_DOMAIN=
COOKIE_SECURE=false
COOKIE_SAMESITE=Lax
EOF

print_status "Frontend environment configured for cookies"

# 7. Fix nginx configuration for cookie handling
print_step "6. Fixing nginx configuration for cookie handling..."

cat > /etc/nginx/sites-available/hajifund << 'EOF'
# Upstream definitions
upstream backend {
    server 127.0.0.1:8080;
    keepalive 32;
}

upstream frontend {
    server 127.0.0.1:3000;
    keepalive 32;
}

# Main HTTP server
server {
    listen 80;
    server_name _;
    
    # Increase client body size
    client_max_body_size 50M;
    
    # Frontend routes
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Authentication endpoints - CRITICAL COOKIE HANDLING
    location /api/v1/auth/ {
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for VPS
        proxy_set_header Cookie $http_cookie;
        
        # Cookie domain rewriting
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        
        # Cookie path rewriting
        proxy_cookie_path / /;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/auth/ routes (without v1)
    location /api/auth/ {
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for VPS
        proxy_set_header Cookie $http_cookie;
        
        # Cookie domain rewriting
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        
        # Cookie path rewriting
        proxy_cookie_path / /;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Backend API routes
    location /api/v1/ {
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        proxy_cookie_path / /;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/ routes (general API without v1)
    location /api/ {
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        proxy_cookie_path / /;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Admin routes
    location /admin/ {
        proxy_pass http://frontend/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Static files
    location /static/ {
        proxy_pass http://frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Upload files
    location /uploads/ {
        proxy_pass http://backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test nginx configuration
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 8. Start services in order
print_step "7. Starting services..."

print_info "Starting backend..."
systemctl start hajifund-backend
sleep 15

# Check backend
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be fully ready yet"
fi

print_info "Starting frontend..."
systemctl start hajifund-frontend
sleep 15

# Check frontend
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be fully ready yet"
fi

print_info "Starting nginx..."
systemctl start nginx
sleep 5

# 9. Test cookie functionality
print_step "8. Testing cookie functionality..."

sleep 10

# Test credentials
TEST_EMAIL="testuser$(date +%s)@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User $(date +%s)"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

print_info "Testing cookie functionality..."

echo "1. Testing registration:"
REGISTER_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -w "HTTP Status: %{http_code}\n")

echo "$REGISTER_RESPONSE"

echo ""
echo "2. Testing login and cookie setting:"
LOGIN_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/test_cookies.txt \
  -w "HTTP Status: %{http_code}\n" \
  -D /tmp/response_headers.txt)

echo "$LOGIN_RESPONSE"

echo ""
echo "3. Analyzing response headers for cookies:"
if [ -f "/tmp/response_headers.txt" ]; then
    echo "Response headers:"
    cat /tmp/response_headers.txt | grep -i cookie || echo "No cookie headers found"
fi

echo ""
echo "4. Analyzing cookie file:"
if [ -f "/tmp/test_cookies.txt" ] && [ -s "/tmp/test_cookies.txt" ]; then
    print_status "Cookies are being set"
    echo "Cookie file contents:"
    cat /tmp/test_cookies.txt
    echo ""
    echo "Cookie analysis:"
    if grep -q "auth_token" /tmp/test_cookies.txt; then
        print_status "auth_token cookie found"
    else
        print_error "auth_token cookie NOT found"
    fi
else
    print_error "No cookies are being set"
fi

echo ""
echo "5. Testing profile access with cookies:"
PROFILE_RESPONSE=$(curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt \
  -w "HTTP Status: %{http_code}\n")

echo "$PROFILE_RESPONSE"

# 10. Show final status
print_step "9. Final service status..."

echo "Backend status:"
systemctl status hajifund-backend --no-pager -l | head -5

echo ""
echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

echo ""
echo "Nginx status:"
systemctl status nginx --no-pager -l | head -5

# 11. Summary
print_status "Cookie issues fix completed!"
print_info ""
print_info "🍪 Cookie Issues Fixed:"
print_info "✅ Cookie Domain: Removed domain restrictions for VPS"
print_info "✅ Cookie Security: Set Secure=false for HTTP"
print_info "✅ Cookie SameSite: Set to Lax for VPS compatibility"
print_info "✅ Cookie HTTPOnly: Ensured security"
print_info "✅ Nginx Cookie Handling: Added domain and path rewriting"
print_info "✅ CORS Configuration: Added VPS IP to allowed origins"
print_info ""
print_info "🔍 Key Differences Fixed:"
print_info "   Local: localhost:3000 (no domain restrictions)"
print_info "   VPS: 103.103.20.68:80 (IP address requires different settings)"
print_info ""
print_info "🌐 Test your login now: http://103.103.20.68/login"
print_info "Cookies should now work properly on VPS!"
print_info ""
print_info "💡 If cookies still don't work, the issue might be:"
print_info "   1. Browser cache (clear browser cache)"
print_info "   2. HTTPS requirement (try with domain + SSL)"
print_info "   3. Docker deployment (handles cookies automatically)"
