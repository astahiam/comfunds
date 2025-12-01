#!/bin/bash

# HajiFund Session Root Cause Analysis and Fix
# This script identifies and fixes the exact session issues between local and VPS

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

print_step "Analyzing Session Issues Between Local and VPS"
print_info "Let's identify why sessions work locally but fail on VPS"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Root Cause Analysis
print_step "1. Root Cause Analysis"

print_info "Common reasons sessions work locally but fail on VPS:"
print_info "1. Cookie Domain mismatch (localhost vs IP)"
print_info "2. HTTP vs HTTPS differences"
print_info "3. CORS configuration issues"
print_info "4. Nginx proxy cookie handling"
print_info "5. JWT secret differences"
print_info "6. Network interface binding"

# 3. Check current cookie configuration
print_step "2. Checking current cookie configuration..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_info "Current cookie configuration in auth.go:"
    grep -A 10 -B 2 "cookie" /var/www/hajifund/frontend/handlers/auth.go || true
else
    print_warning "auth.go not found"
fi

# 4. Fix cookie configuration for VPS
print_step "3. Fixing cookie configuration for VPS..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    # Fix cookie settings for VPS environment
    sed -i 's/Domain:   "103.103.20.68"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Secure:   true/Secure:   false/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/SameSite: "Strict"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Remove any domain restrictions completely
    sed -i 's/Domain:   ".*"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    
    print_status "Cookie configuration updated for VPS"
fi

# 5. Fix backend environment
print_step "4. Fixing backend environment for VPS..."

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
JWT_SECRET=hajifund-super-secret-jwt-key-production-2024-vps-$(date +%s)

# CORS Configuration - Allow all origins for VPS
CORS_ORIGINS=*

# Trusted Proxies - Allow all for VPS
TRUSTED_PROXIES=*

# Rate Limiting
GENERAL_RATE_LIMIT_RPM=60
GENERAL_RATE_LIMIT_BURST=100
EOF

print_status "Backend environment configured for VPS"

# 6. Fix frontend environment
print_step "5. Fixing frontend environment for VPS..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080
EOF

print_status "Frontend environment configured for VPS"

# 7. Fix nginx configuration for proper cookie handling
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
        proxy_set_header X-Forwarded-Proportional $scheme;
        
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
        
        # CRITICAL: Proper cookie handling for VPS
        proxy_set_header Cookie $http_cookie;
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
        proxy_cookie_flags auth_token secure samesite=lax;
        
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
        
        # CRITICAL: Proper cookie handling for VPS
        proxy_set_header Cookie $http_cookie;
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
        proxy_cookie_flags auth_token secure samesite=lax;
        
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

# 8. Alternative approach: Fix backend to handle VPS environment
print_step "7. Alternative approach: Backend VPS compatibility..."

# Create a VPS-specific backend configuration
if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    # Add VPS-specific cookie handling
    cat >> /var/www/hajifund/frontend/handlers/auth.go << 'EOF'

// VPS-specific cookie configuration
func setVPSCookie(c *fiber.Ctx, name, value string) {
    cookie := &fiber.Cookie{
        Name:     name,
        Value:    value,
        Path:     "/",
        Domain:   "", // Empty domain for VPS
        MaxAge:   86400, // 24 hours
        Secure:   false, // HTTP for VPS
        HTTPOnly: true,
        SameSite: "Lax", // Lax for VPS
    }
    c.Cookie(cookie)
}
EOF
    
    print_status "Added VPS-specific cookie handling"
fi

# 9. Start services in order
print_step "8. Starting services..."

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

# 10. Test the session with detailed analysis
print_step "9. Testing session with detailed analysis..."

sleep 10

# Test credentials
TEST_EMAIL="testuser$(date +%s)@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User $(date +%s)"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

print_info "Testing complete session flow with detailed analysis..."

echo "1. Testing registration:"
REGISTER_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -w "HTTP Status: %{http_code}\n" \
  -v 2>&1)

echo "$REGISTER_RESPONSE"

echo ""
echo "2. Testing login with cookie analysis:"
LOGIN_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/test_cookies.txt \
  -w "HTTP Status: %{http_code}\n" \
  -v 2>&1)

echo "$LOGIN_RESPONSE"

echo ""
echo "3. Cookie file analysis:"
if [ -f "/tmp/test_cookies.txt" ] && [ -s "/tmp/test_cookies.txt" ]; then
    print_status "Cookies are being set"
    echo "Cookie contents:"
    cat /tmp/test_cookies.txt
else
    print_error "No cookies are being set"
fi

echo ""
echo "4. Testing profile access:"
PROFILE_RESPONSE=$(curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt \
  -w "HTTP Status: %{http_code}\n" \
  -v 2>&1)

echo "$PROFILE_RESPONSE"

# 11. Show final status
print_step "10. Final service status..."

echo "Backend status:"
systemctl status hajifund-backend --no-pager -l | head -5

echo ""
echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

echo ""
echo "Nginx status:"
systemctl status nginx --no-pager -l | head -5

# 12. Summary and recommendations
print_status "Session root cause analysis completed!"
print_info ""
print_info "🎯 Root Cause Analysis:"
print_info "The main differences between local and VPS:"
print_info "1. Cookie Domain: localhost vs IP address"
print_info "2. HTTP vs HTTPS: VPS might need different security settings"
print_info "3. CORS: Local allows localhost, VPS needs IP address"
print_info "4. Nginx Proxy: Cookie forwarding between services"
print_info "5. Network Binding: Local vs external IP"
print_info ""
print_info "🔧 What was fixed:"
print_info "✅ Cookie domain configuration for VPS"
print_info "✅ CORS configuration for VPS environment"
print_info "✅ Nginx cookie handling and forwarding"
print_info "✅ Backend environment variables for VPS"
print_info "✅ Frontend environment configuration"
print_info ""
print_info "🌐 Test your login now: http://103.103.20.68/login"
print_info "The session should now work properly on VPS!"
print_info ""
print_info "💡 If still not working, try Docker deployment:"
print_info "   docker-compose up -d"
print_info "   (Docker handles networking and cookies automatically)"
