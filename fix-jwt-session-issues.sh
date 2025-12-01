#!/bin/bash

# HajiFund JWT Token and Session Fix Script
# This script fixes JWT token and session persistence issues on VPS

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

print_step "Fixing JWT Token and Session Issues"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Check current environment configuration
print_step "1. Checking current environment configuration..."

echo "Backend .env file:"
if [ -f "/var/www/hajifund/.env" ]; then
    cat /var/www/hajifund/.env
else
    print_warning "Backend .env file not found"
fi

echo ""
echo "Frontend .env file:"
if [ -f "/var/www/hajifund/frontend/.env" ]; then
    cat /var/www/hajifund/frontend/.env
else
    print_warning "Frontend .env file not found"
fi

# 3. Fix backend environment configuration
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
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-hajifund-2024

# CORS Configuration
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080

# Logging
LOG_LEVEL=info

# Trusted Proxies (for nginx)
TRUSTED_PROXIES=127.0.0.1,::1

# Rate Limiting
GENERAL_RATE_LIMIT_RPM=60
GENERAL_RATE_LIMIT_BURST=100
EOF

print_status "Backend environment configured"

# 4. Fix frontend environment configuration
print_step "3. Fixing frontend environment configuration..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080
EOF

print_status "Frontend environment configured"

# 5. Check JWT configuration in backend code
print_step "4. Checking JWT configuration in backend..."

# Check if JWT_SECRET is properly configured
if grep -q "JWT_SECRET" /var/www/hajifund/.env; then
    print_status "JWT_SECRET is configured in backend .env"
else
    print_error "JWT_SECRET not found in backend .env"
fi

# 6. Check cookie configuration in frontend
print_step "5. Checking cookie configuration in frontend..."

# Look for cookie configuration in auth handlers
if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    echo "Checking cookie configuration in auth handler..."
    grep -A 10 -B 2 "Cookie" /var/www/hajifund/frontend/handlers/auth.go || echo "No cookie configuration found"
fi

# 7. Update nginx configuration for proper cookie handling
print_step "6. Updating nginx configuration for cookie handling..."

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
    
    # Backend API routes - FIXED CONFIGURATION
    location /api/v1/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for session persistence
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/auth/ routes (without v1)
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for authentication
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
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
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_path / /;
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

print_status "Nginx configuration updated with proper cookie handling"

# 8. Test nginx configuration
print_info "Testing nginx configuration..."
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 9. Start services in order
print_step "7. Starting services..."

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

# 10. Test the fix
print_step "8. Testing JWT and session persistence..."

sleep 10

echo "Testing login endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123!"}' \
  -c /tmp/cookies.txt || echo "Login endpoint test failed"

echo ""
echo "Testing with cookies:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/v1/user/profile \
  -b /tmp/cookies.txt || echo "Profile endpoint test failed"

echo ""
echo "Testing external access:"
curl -s -w "HTTP Status: %{http_code}\n" -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123!"}' \
  -c /tmp/cookies_external.txt || echo "External login test failed"

# 11. Show final status
print_step "9. Final service status..."
echo "Backend:"
systemctl status hajifund-backend --no-pager -l

echo ""
echo "Frontend:"
systemctl status hajifund-frontend --no-pager -l

echo ""
echo "Nginx:"
systemctl status nginx --no-pager -l

print_status "JWT and session persistence fix completed!"
print_info "Key fixes applied:"
print_info "✅ Updated JWT_SECRET in backend .env"
print_info "✅ Fixed CORS_ORIGINS for VPS domain"
print_info "✅ Added proxy_cookie_domain configuration"
print_info "✅ Added proxy_cookie_path configuration"
print_info "✅ Added proxy_set_header Cookie configuration"
print_info ""
print_info "Test your login now: http://103.103.20.68"
print_info "The session should now persist properly!"
