#!/bin/bash

# Fix Auth Token Cookie Issues on VPS
# This script addresses the empty auth_token cookie issue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step "Fixing Auth Token Cookie Issues on VPS"

# 1. Check current environment variables
print_step "1. Checking current environment variables..."

if [ -f "/var/www/hajifund/backend/.env" ]; then
    print_info "Backend .env file found"
    
    # Check JWT_SECRET
    if grep -q "JWT_SECRET" /var/www/hajifund/backend/.env; then
        print_info "JWT_SECRET found in backend .env"
    else
        print_warning "JWT_SECRET not found, adding..."
        echo "JWT_SECRET=hajifund_jwt_secret_key_2024_very_secure_random_string_12345" >> /var/www/hajifund/backend/.env
        print_status "JWT_SECRET added"
    fi
    
    # Check CORS_ORIGINS
    if grep -q "CORS_ORIGINS" /var/www/hajifund/backend/.env; then
        print_info "CORS_ORIGINS found in backend .env"
    else
        print_warning "CORS_ORIGINS not found, adding..."
        echo "CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://127.0.0.1:3000" >> /var/www/hajifund/backend/.env
        print_status "CORS_ORIGINS added"
    fi
    
    # Check TRUSTED_PROXIES
    if grep -q "TRUSTED_PROXIES" /var/www/hajifund/backend/.env; then
        print_info "TRUSTED_PROXIES found in backend .env"
    else
        print_warning "TRUSTED_PROXIES not found, adding..."
        echo "TRUSTED_PROXIES=103.103.20.68,127.0.0.1,localhost" >> /var/www/hajifund/backend/.env
        print_status "TRUSTED_PROXIES added"
    fi
else
    print_error "Backend .env file not found"
    exit 1
fi

# 2. Fix frontend environment variables
print_step "2. Fixing frontend environment variables..."

if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_info "Frontend .env file found"
    
    # Check API_BASE_URL
    if grep -q "API_BASE_URL" /var/www/hajifund/frontend/.env; then
        print_info "API_BASE_URL found in frontend .env"
    else
        print_warning "API_BASE_URL not found, adding..."
        echo "API_BASE_URL=http://103.103.20.68:8080" >> /var/www/hajifund/frontend/.env
        print_status "API_BASE_URL added"
    fi
    
    # Check BACKEND_URL
    if grep -q "BACKEND_URL" /var/www/hajifund/frontend/.env; then
        print_info "BACKEND_URL found in frontend .env"
    else
        print_warning "BACKEND_URL not found, adding..."
        echo "BACKEND_URL=http://103.103.20.68:8080" >> /var/www/hajifund/frontend/.env
        print_status "BACKEND_URL added"
    fi
    
    # Check FRONTEND_URL
    if grep -q "FRONTEND_URL" /var/www/hajifund/frontend/.env; then
        print_info "FRONTEND_URL found in frontend .env"
    else
        print_warning "FRONTEND_URL not found, adding..."
        echo "FRONTEND_URL=http://103.103.20.68" >> /var/www/hajifund/frontend/.env
        print_status "FRONTEND_URL added"
    fi
else
    print_error "Frontend .env file not found"
    exit 1
fi

# 3. Fix backend cookie configuration
print_step "3. Fixing backend cookie configuration..."

# Check if backend has proper cookie settings
if [ -f "/var/www/hajifund/backend/main.go" ]; then
    print_info "Backend main.go found, checking cookie configuration..."
    
    # Check if cookie domain is set correctly
    if grep -q "CookieDomain" /var/www/hajifund/backend/main.go; then
        print_info "CookieDomain found in backend"
    else
        print_warning "CookieDomain not found, this might be the issue"
    fi
    
    # Check if cookie path is set correctly
    if grep -q "CookiePath" /var/www/hajifund/backend/main.go; then
        print_info "CookiePath found in backend"
    else
        print_warning "CookiePath not found, this might be the issue"
    fi
else
    print_error "Backend main.go not found"
    exit 1
fi

# 4. Fix Nginx configuration for cookies
print_step "4. Fixing Nginx configuration for cookies..."

if [ -f "/etc/nginx/sites-available/default" ]; then
    print_info "Nginx configuration found"
    
    # Backup original nginx config
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    
    # Add cookie domain rewriting
    if ! grep -q "proxy_cookie_domain" /etc/nginx/sites-available/default; then
        print_info "Adding cookie domain rewriting to nginx..."
        
        # Add cookie domain rewriting for backend
        sed -i '/location \/api\//a\
        proxy_cookie_domain localhost 103.103.20.68;\
        proxy_cookie_domain 127.0.0.1 103.103.20.68;' /etc/nginx/sites-available/default
        
        print_status "Cookie domain rewriting added"
    else
        print_info "Cookie domain rewriting already exists"
    fi
    
    # Add cookie path rewriting
    if ! grep -q "proxy_cookie_path" /etc/nginx/sites-available/default; then
        print_info "Adding cookie path rewriting to nginx..."
        
        # Add cookie path rewriting
        sed -i '/proxy_cookie_domain/a\
        proxy_cookie_path \/ \/;' /etc/nginx/sites-available/default
        
        print_status "Cookie path rewriting added"
    else
        print_info "Cookie path rewriting already exists"
    fi
    
    # Test nginx configuration
    if nginx -t; then
        print_status "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
        exit 1
    fi
else
    print_warning "Nginx configuration not found, skipping nginx fixes"
fi

# 5. Fix backend cookie settings in code
print_step "5. Fixing backend cookie settings in code..."

if [ -f "/var/www/hajifund/backend/main.go" ]; then
    print_info "Checking backend cookie settings..."
    
    # Check if cookie domain is set to the VPS IP
    if grep -q "CookieDomain.*103.103.20.68" /var/www/hajifund/backend/main.go; then
        print_info "Cookie domain is set to VPS IP"
    else
        print_warning "Cookie domain might not be set correctly"
        
        # Try to fix cookie domain
        if grep -q "CookieDomain" /var/www/hajifund/backend/main.go; then
            print_info "Updating cookie domain to VPS IP..."
            sed -i 's/CookieDomain.*/CookieDomain: "103.103.20.68",/g' /var/www/hajifund/backend/main.go
            print_status "Cookie domain updated"
        else
            print_warning "CookieDomain not found in backend code"
        fi
    fi
    
    # Check if cookie path is set correctly
    if grep -q "CookiePath.*/" /var/www/hajifund/backend/main.go; then
        print_info "Cookie path is set correctly"
    else
        print_warning "Cookie path might not be set correctly"
        
        # Try to fix cookie path
        if grep -q "CookiePath" /var/www/hajifund/backend/main.go; then
            print_info "Updating cookie path..."
            sed -i 's/CookiePath.*/CookiePath: "\/",/g' /var/www/hajifund/backend/main.go
            print_status "Cookie path updated"
        else
            print_warning "CookiePath not found in backend code"
        fi
    fi
else
    print_error "Backend main.go not found"
    exit 1
fi

# 6. Rebuild and restart services
print_step "6. Rebuilding and restarting services..."

# Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend
systemctl stop hajifund-frontend

# Build backend
print_info "Building backend..."
cd /var/www/hajifund/backend
go build -o hajifund-backend main.go

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go

# Start services
print_info "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend

# Check service status
print_info "Checking service status..."
if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service failed to start"
    systemctl status hajifund-backend
fi

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running"
else
    print_error "Frontend service failed to start"
    systemctl status hajifund-frontend
fi

# 7. Test authentication
print_step "7. Testing authentication..."

# Test login endpoint
print_info "Testing login endpoint..."
if curl -s -X POST http://103.103.20.68:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"test123"}' \
    | grep -q "auth_token"; then
    print_status "Login endpoint returns auth_token"
else
    print_warning "Login endpoint might not be setting auth_token correctly"
fi

# Test with a real user
print_info "Testing with real user credentials..."
if curl -s -X POST http://103.103.20.68:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}' \
    | grep -q "auth_token"; then
    print_status "Real user login returns auth_token"
else
    print_warning "Real user login might not be working"
fi

# 8. Restart nginx
print_step "8. Restarting nginx..."

if systemctl restart nginx; then
    print_status "Nginx restarted successfully"
else
    print_error "Failed to restart nginx"
    systemctl status nginx
fi

# 9. Final test
print_step "9. Final authentication test..."

print_info "Testing complete authentication flow..."
print_info "1. Try logging in at: http://103.103.20.68/login"
print_info "2. Check browser developer tools for auth_token cookie"
print_info "3. Verify redirect to dashboard works"

print_status "Auth token cookie fix completed!"
print_info "If issues persist, check:"
print_info "- Backend logs: journalctl -u hajifund-backend -f"
print_info "- Frontend logs: journalctl -u hajifund-frontend -f"
print_info "- Nginx logs: tail -f /var/log/nginx/error.log"
