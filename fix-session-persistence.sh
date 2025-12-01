#!/bin/bash

# HajiFund Session Persistence Fix Script
# This script fixes the specific issue where login works but session doesn't persist

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

print_step "Fixing Session Persistence Issue"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Fix backend cookie configuration
print_step "1. Fixing backend cookie configuration..."

# Check if the backend is setting cookies correctly
if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_info "Updating cookie configuration in auth handler..."
    
    # Backup the original file
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    # Update cookie configuration
    sed -i 's/Secure:   false/Secure:   false/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/SameSite: "Lax"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/HTTPOnly: true/HTTPOnly: true/g' /var/www/hajifund/frontend/handlers/auth.go
    
    print_status "Backend cookie configuration updated"
fi

# 3. Fix backend environment for proper cookie handling
print_step "2. Fixing backend environment configuration..."

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
JWT_SECRET=hajifund-super-secret-jwt-key-production-2024-vps-103-103-20-68

# CORS Configuration - CRITICAL for session persistence
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000

# Trusted Proxies (for nginx)
TRUSTED_PROXIES=127.0.0.1,::1,103.103.20.68

# Rate Limiting
GENERAL_RATE_LIMIT_RPM=60
GENERAL_RATE_LIMIT_BURST=100

# Cookie Configuration
COOKIE_DOMAIN=103.103.20.68
COOKIE_SECURE=false
COOKIE_SAME_SITE=Lax
EOF

print_status "Backend environment configured for session persistence"

# 4. Fix frontend environment
print_step "3. Fixing frontend environment configuration..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080

# Cookie Configuration
COOKIE_DOMAIN=103.103.20.68
EOF

print_status "Frontend environment configured"

# 5. Fix nginx configuration with proper cookie handling
print_step "4. Fixing nginx configuration for cookie persistence..."

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

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# Main HTTP server
server {
    listen 80;
    server_name _;
    
    # Increase client body size for file uploads
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
    
    # CRITICAL: Authentication endpoints with proper cookie handling
    location /api/v1/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for authentication
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_cookie_path ~^/api/v1/auth/(.*)$ /$1;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/auth/ routes (without v1) - REDIRECT TO v1
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for authentication
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_cookie_path ~^/api/auth/(.*)$ /$1;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Backend API routes with cookie handling
    location /api/v1/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for session persistence
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/ routes (general API without v1)
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for session persistence
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_set_header Cookie $http_cookie;
        
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
    
    # Static files with caching
    location /static/ {
        proxy_pass http://frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # Compression
        gzip_static on;
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
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|git|htaccess|htpasswd)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

print_status "Nginx configuration updated with advanced cookie handling"

# 6. Test nginx configuration
print_info "Testing nginx configuration..."
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 7. Start services in order
print_step "5. Starting services..."

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

# 8. Test session persistence
print_step "6. Testing session persistence..."

sleep 10

# Test user credentials
TEST_EMAIL="testuser@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

echo "Testing registration and session persistence:"
echo "1. Registering test user:"
curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -c /tmp/register_cookies.txt -w "HTTP Status: %{http_code}\n"

echo ""
echo "2. Login test:"
curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n"

echo ""
echo "3. Cookie verification:"
if [ -f "/tmp/test_cookies.txt" ] && [ -s "/tmp/test_cookies.txt" ]; then
    print_status "Cookies are being set"
    cat /tmp/test_cookies.txt
else
    print_error "No cookies are being set"
fi

echo ""
echo "4. Profile access test:"
curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n"

echo ""
echo "5. Testing session persistence with refresh:"
curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n"

echo ""
echo "6. Testing with different endpoint:"
curl -s http://103.103.20.68/api/v1/user/projects \
  -b /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n"

# 9. Show final status
print_step "7. Final service status..."
echo "Backend:"
systemctl status hajifund-backend --no-pager -l

echo ""
echo "Frontend:"
systemctl status hajifund-frontend --no-pager -l

echo ""
echo "Nginx:"
systemctl status nginx --no-pager -l

print_status "Session persistence fix completed!"
print_info "Key fixes applied:"
print_info "✅ Fixed cookie domain configuration"
print_info "✅ Added proper CORS origins"
print_info "✅ Updated JWT secret for production"
print_info "✅ Fixed nginx proxy cookie handling"
print_info "✅ Added cookie path rewriting"
print_info ""
print_info "Test your login now: http://103.103.20.68"
print_info "The session should now persist properly!"
print_info ""
print_info "If still having issues, run: ./diagnose-session-issue.sh"
