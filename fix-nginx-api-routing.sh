#!/bin/bash

# HajiFund Nginx API Routing Fix Script
# This script fixes the nginx configuration for proper API routing

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

print_step "Fixing Nginx API Routing Configuration"

# 1. Stop nginx
print_info "Stopping nginx..."
systemctl stop nginx

# 2. Backup current configuration
print_info "Backing up current nginx configuration..."
cp /etc/nginx/sites-available/hajifund /etc/nginx/sites-available/hajifund.backup.$(date +%Y%m%d_%H%M%S)

# 3. Create corrected nginx configuration
print_info "Creating corrected nginx configuration..."

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

# Main HTTP server (for testing)
server {
    listen 80;
    server_name _;
    
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
        # Rate limiting for API
        limit_req zone=api burst=20 nodelay;
        
        # CRITICAL FIX: Remove trailing slash from proxy_pass
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Legacy API routes (without v1)
    location /api/ {
        # Rate limiting for API
        limit_req zone=api burst=20 nodelay;
        
        # CRITICAL FIX: Remove trailing slash from proxy_pass
        proxy_pass http://backend/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Login endpoint with stricter rate limiting
    location /api/v1/auth/login {
        limit_req zone=login burst=5 nodelay;
        
        proxy_pass http://backend/api/v1/auth/login;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files with caching
    location /static/ {
        proxy_pass http://frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # Compression
        gzip_static on;
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

# HTTPS server (if SSL is configured)
server {
    listen 443 ssl http2;
    server_name _;
    
    # SSL configuration (only if certificates exist)
    ssl_certificate /etc/nginx/ssl/hajifund.crt;
    ssl_certificate_key /etc/nginx/ssl/hajifund.key;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
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
        # Rate limiting for API
        limit_req zone=api burst=20 nodelay;
        
        # CRITICAL FIX: Remove trailing slash from proxy_pass
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Legacy API routes (without v1)
    location /api/ {
        # Rate limiting for API
        limit_req zone=api burst=20 nodelay;
        
        # CRITICAL FIX: Remove trailing slash from proxy_pass
        proxy_pass http://backend/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Login endpoint with stricter rate limiting
    location /api/v1/auth/login {
        limit_req zone=login burst=5 nodelay;
        
        proxy_pass http://backend/api/v1/auth/login;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files with caching
    location /static/ {
        proxy_pass http://frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # Compression
        gzip_static on;
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
    exit 1
fi

# 5. Enable the site
print_info "Enabling hajifund site..."
ln -sf /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 6. Start nginx
print_info "Starting nginx..."
systemctl start nginx

# 7. Test the fix
print_step "Testing the API routing fix..."

sleep 5

echo "Testing backend health endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost:8080/api/v1/health || echo "Backend not responding directly"

echo ""
echo "Testing nginx API proxy:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/v1/health || echo "Nginx API proxy not working"

echo ""
echo "Testing auth endpoint:"
curl -s -w "HTTP Status: %{http_code}\n" http://localhost/api/v1/auth/login || echo "Auth endpoint not working"

echo ""
echo "Testing external access:"
curl -s -w "HTTP Status: %{http_code}\n" http://103.103.20.68/api/v1/health || echo "External access not working"

# 8. Show final status
print_step "Final status check..."
echo "Nginx status:"
systemctl status nginx --no-pager -l

print_status "Nginx API routing fix completed!"
print_info "The main issue was in the proxy_pass configuration:"
print_info "- Old: proxy_pass http://backend/;"
print_info "- New: proxy_pass http://backend/api/v1/;"
print_info ""
print_info "Try accessing your API now: http://103.103.20.68/api/v1/auth/login"
