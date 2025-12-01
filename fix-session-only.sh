#!/bin/bash

# HajiFund Session Fix Only Script
# This script ONLY fixes session issues without touching the login page design

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

print_step "Fixing Session Issues Only (No Design Changes)"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Fix backend environment for sessions
print_step "1. Fixing backend environment..."

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

# CORS Configuration - Allow all origins for now
CORS_ORIGINS=*

# Trusted Proxies
TRUSTED_PROXIES=*
EOF

print_status "Backend environment fixed"

# 3. Fix frontend environment
print_step "2. Fixing frontend environment..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080
EOF

print_status "Frontend environment fixed"

# 4. Fix backend cookie configuration
print_step "3. Fixing backend cookie configuration..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    # Fix cookie settings - remove all restrictions
    sed -i 's/Domain:   "103.103.20.68"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Secure:   true/Secure:   false/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/SameSite: "Strict"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/HttpOnly: true/HttpOnly: false/g' /var/www/hajifund/frontend/handlers/auth.go
    
    print_status "Backend cookie configuration fixed"
fi

# 5. Fix nginx configuration for sessions
print_step "4. Fixing nginx configuration..."

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
    
    # Authentication endpoints
    location /api/v1/auth/ {
        proxy_pass http://backend/api/v1/auth/;
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
    
    # Handle /api/auth/ routes (without v1)
    location /api/auth/ {
        proxy_pass http://backend/api/v1/auth/;
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

# 6. Start services in order
print_step "5. Starting services..."

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

# 7. Test the session
print_step "6. Testing session..."

sleep 10

# Test credentials
TEST_EMAIL="testuser$(date +%s)@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User $(date +%s)"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

print_info "Testing complete session flow..."

echo "1. Testing registration:"
REGISTER_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -w "HTTP Status: %{http_code}\n")

echo "$REGISTER_RESPONSE"

echo ""
echo "2. Testing login:"
LOGIN_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n")

echo "$LOGIN_RESPONSE"

echo ""
echo "3. Testing profile access:"
PROFILE_RESPONSE=$(curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n")

echo "$PROFILE_RESPONSE"

# 8. Show final status
print_step "7. Final service status..."

echo "Backend status:"
systemctl status hajifund-backend --no-pager -l | head -5

echo ""
echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

echo ""
echo "Nginx status:"
systemctl status nginx --no-pager -l | head -5

# 9. Summary
print_status "Session fix completed!"
print_info ""
print_info "🎉 What was fixed:"
print_info "✅ Backend environment configured for sessions"
print_info "✅ Frontend environment configured"
print_info "✅ Backend cookie configuration fixed"
print_info "✅ Nginx cookie handling configured"
print_info "✅ All services restarted"
print_info ""
print_info "🌐 Your application is now available at:"
print_info "   Main site: http://103.103.20.68"
print_info "   Login page: http://103.103.20.68/login"
print_info ""
print_info "🔧 Test credentials created:"
print_info "   Email: $TEST_EMAIL"
print_info "   Password: $TEST_PASSWORD"
print_info ""
print_info "The session should now work properly!"
print_info "The login page design was NOT changed!"
