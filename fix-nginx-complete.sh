#!/bin/bash

# HajiFund Complete Nginx Fix Script
# This script fixes ALL nginx routing issues for both /api/ and /api/v1/ routes

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

print_step "Complete Nginx Configuration Fix for HajiFund"

# 1. Stop nginx
print_info "Stopping nginx..."
systemctl stop nginx

# 2. Backup current configuration
print_info "Backing up current nginx configuration..."
if [ -f "/etc/nginx/sites-available/hajifund" ]; then
    cp /etc/nginx/sites-available/hajifund /etc/nginx/sites-available/hajifund.backup.$(date +%Y%m%d_%H%M%S)
fi

# 3. Create the complete nginx configuration
print_info "Creating complete nginx configuration..."

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
limit_req_zone $binary_remote_addr zone=register:10m rate=3r/m;

# Main HTTP server
server {
    listen 80;
    server_name _;
    
    # Increase client body size for file uploads
    client_max_body_size 50M;
    
    # Frontend routes (everything not API)
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
    
    # CRITICAL: Handle /api/auth/ routes (without v1)
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        # This handles /api/auth/login, /api/auth/register, etc.
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept";
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/ routes (general API without v1)
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        # This handles /api/projects, /api/investments, etc.
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept";
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/v1/ routes (explicit v1 API)
    location /api/v1/ {
        limit_req zone=api burst=20 nodelay;
        
        # This handles /api/v1/projects, /api/v1/investments, etc.
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept";
        
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

# 4. Test nginx configuration
print_info "Testing nginx configuration..."
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    print_info "Checking nginx error log:"
    tail -20 /var/log/nginx/error.log
    exit 1
fi

# 5. Enable the site
print_info "Enabling hajifund site..."
ln -sf /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 6. Start nginx
print_info "Starting nginx..."
systemctl start nginx

# 7. Wait for services to be ready
print_info "Waiting for services to be ready..."
sleep 10

# 8. Test the fix
print_step "Testing the complete fix..."

echo "Testing backend health endpoint directly:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost:8080/api/v1/health || echo "Backend not responding directly"

echo ""
echo "Testing nginx API proxy (/api/v1/health):"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/v1/health || echo "Nginx /api/v1/ proxy not working"

echo ""
echo "Testing nginx API proxy (/api/health):"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/health || echo "Nginx /api/ proxy not working"

echo ""
echo "Testing auth endpoint (/api/v1/auth/login):"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/v1/auth/login || echo "Auth endpoint /api/v1/ not working"

echo ""
echo "Testing auth endpoint (/api/auth/login):"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/auth/login || echo "Auth endpoint /api/ not working"

echo ""
echo "Testing external access (/api/auth/login):"
curl -s -w "HTTP Status: %{http_code}\n" http://103.103.20.68/api/auth/login || echo "External /api/auth/login not working"

echo ""
echo "Testing external access (/api/v1/auth/login):"
curl -s -w "HTTP Status: %{http_code}\n" http://103.103.20.68/api/v1/auth/login || echo "External /api/v1/auth/login not working"

# 9. Show final status
print_step "Final status check..."
echo "Nginx status:"
systemctl status nginx --no-pager -l

echo ""
echo "Backend status:"
systemctl status hajifund-backend --no-pager -l

echo ""
echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l

print_status "Complete nginx fix completed!"
print_info "Key fixes applied:"
print_info "✅ /api/auth/ → Backend /api/v1/auth/"
print_info "✅ /api/ → Backend /api/v1/"
print_info "✅ /api/v1/ → Backend /api/v1/"
print_info "✅ Added CORS headers"
print_info "✅ Added rate limiting"
print_info "✅ Increased upload size limit"
print_info ""
print_info "Test these URLs:"
print_info "• http://103.103.20.68/api/auth/login"
print_info "• http://103.103.20.68/api/auth/register"
print_info "• http://103.103.20.68/api/v1/health"
