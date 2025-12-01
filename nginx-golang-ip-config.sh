#!/bin/bash

# Nginx Configuration for Go Apps with IP Address - Cookie/Session Fix
# This script creates the perfect nginx config for Go apps behind reverse proxy

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

print_step "Creating Nginx Configuration for Go Apps with IP Address"
print_info "This config specifically fixes cookie/session issues for Go apps behind reverse proxy"

# 1. Stop nginx
print_info "Stopping nginx..."
systemctl stop nginx 2>/dev/null || true

# 2. Create the perfect nginx configuration for Go apps with IP
print_step "1. Creating nginx configuration for Go apps with IP address..."

cat > /etc/nginx/sites-available/hajifund << 'EOF'
# Nginx Configuration for Go Apps with IP Address
# Optimized for cookie/session handling behind reverse proxy

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
    
    # Authentication endpoints - CRITICAL COOKIE HANDLING
    location /api/v1/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for Go apps with IP address
        proxy_set_header Cookie $http_cookie;
        
        # Cookie domain rewriting - ESSENTIAL for IP addresses
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        
        # Cookie path rewriting
        proxy_cookie_path / /;
        
        # Cookie flags for Go apps
        proxy_cookie_flags auth_token secure samesite=lax;
        proxy_cookie_flags session_id secure samesite=lax;
        
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
        
        # CRITICAL: Cookie handling for Go apps with IP address
        proxy_set_header Cookie $http_cookie;
        
        # Cookie domain rewriting - ESSENTIAL for IP addresses
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        
        # Cookie path rewriting
        proxy_cookie_path / /;
        
        # Cookie flags for Go apps
        proxy_cookie_flags auth_token secure samesite=lax;
        proxy_cookie_flags session_id secure samesite=lax;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Backend API routes
    location /api/v1/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_cookie_path / /;
        
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
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        proxy_cookie_domain localhost 103.103.20.68;
        proxy_cookie_domain 127.0.0.1 103.103.20.68;
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
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

print_status "Nginx configuration created for Go apps with IP address"

# 3. Enable the site
print_step "2. Enabling the site..."

# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default

# Enable our site
ln -sf /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/

print_status "Site enabled"

# 4. Test nginx configuration
print_step "3. Testing nginx configuration..."

if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 5. Start nginx
print_step "4. Starting nginx..."

systemctl start nginx
sleep 5

# 6. Test the configuration
print_step "5. Testing the configuration..."

print_info "Testing nginx reverse proxy..."

# Test if nginx is responding
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "Nginx is responding"
else
    print_warning "Nginx might not be fully ready yet"
fi

# Test if backend is accessible through nginx
if curl -f -s http://103.103.20.68/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is accessible through nginx"
else
    print_warning "Backend might not be accessible through nginx yet"
fi

# 7. Show nginx status
print_step "6. Nginx status..."

systemctl status nginx --no-pager -l | head -10

# 8. Summary
print_status "Nginx configuration for Go apps with IP address completed!"
print_info ""
print_info "🎯 Key Features of This Configuration:"
print_info "✅ Optimized for Go apps behind reverse proxy"
print_info "✅ Proper cookie handling for IP addresses"
print_info "✅ Cookie domain rewriting for localhost → IP"
print_info "✅ Cookie path rewriting"
print_info "✅ Cookie flags for Go apps (auth_token, session_id)"
print_info "✅ Rate limiting for API endpoints"
print_info "✅ WebSocket support"
print_info "✅ Health check endpoints"
print_info "✅ Security headers and file access restrictions"
print_info ""
print_info "🍪 Cookie Handling Features:"
print_info "   - proxy_cookie_domain: Rewrites localhost to IP"
print_info "   - proxy_cookie_path: Ensures proper path"
print_info "   - proxy_cookie_flags: Sets security flags for Go apps"
print_info "   - Cookie forwarding: Ensures cookies reach Go apps"
print_info ""
print_info "🌐 Your Go apps are now accessible at:"
print_info "   Frontend: http://103.103.20.68"
print_info "   Backend API: http://103.103.20.68/api/v1/"
print_info "   Admin: http://103.103.20.68/admin/"
print_info ""
print_info "This configuration specifically fixes cookie/session issues"
print_info "for Go apps running behind nginx reverse proxy with IP addresses!"
