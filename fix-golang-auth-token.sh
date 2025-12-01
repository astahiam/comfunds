#!/bin/bash

# Fix Auth Token Cookie Issues for Direct Golang Deployment (No Nginx)
# This script addresses the empty auth_token cookie issue when using direct Golang

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

print_step "Fixing Auth Token Cookie Issues for Direct Golang Deployment"

# 1. Stop Nginx (if running)
print_step "1. Stopping Nginx..."

if systemctl is-active --quiet nginx; then
    print_info "Stopping Nginx service..."
    systemctl stop nginx
    systemctl disable nginx
    print_status "Nginx stopped and disabled"
else
    print_info "Nginx is not running"
fi

# 2. Configure backend for direct deployment
print_step "2. Configuring backend for direct deployment..."

if [ -f "/var/www/hajifund/.env" ]; then
    print_info "Backend .env file found"
    
    # Set JWT_SECRET
    if grep -q "JWT_SECRET" /var/www/hajifund/.env; then
        print_info "JWT_SECRET found, updating..."
        sed -i 's/JWT_SECRET=.*/JWT_SECRET=hajifund_jwt_secret_key_2024_very_secure_random_string_12345/' /var/www/hajifund/.env
    else
        print_info "Adding JWT_SECRET..."
        echo "JWT_SECRET=hajifund_jwt_secret_key_2024_very_secure_random_string_12345" >> /var/www/hajifund/.env
    fi
    
    # Set CORS_ORIGINS for direct deployment
    if grep -q "CORS_ORIGINS" /var/www/hajifund/.env; then
        print_info "CORS_ORIGINS found, updating..."
        sed -i 's/CORS_ORIGINS=.*/CORS_ORIGINS=http:\/\/103.103.20.68,http:\/\/localhost:3000,http:\/\/127.0.0.1:3000/' /var/www/hajifund/.env
    else
        print_info "Adding CORS_ORIGINS..."
        echo "CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://127.0.0.1:3000" >> /var/www/hajifund/.env
    fi
    
    # Set TRUSTED_PROXIES
    if grep -q "TRUSTED_PROXIES" /var/www/hajifund/.env; then
        print_info "TRUSTED_PROXIES found, updating..."
        sed -i 's/TRUSTED_PROXIES=.*/TRUSTED_PROXIES=103.103.20.68,127.0.0.1,localhost/' /var/www/hajifund/.env
    else
        print_info "Adding TRUSTED_PROXIES..."
        echo "TRUSTED_PROXIES=103.103.20.68,127.0.0.1,localhost" >> /var/www/hajifund/.env
    fi
    
    # Set PORT for backend
    if grep -q "PORT" /var/www/hajifund/.env; then
        print_info "PORT found, updating..."
        sed -i 's/PORT=.*/PORT=8080/' /var/www/hajifund/.env
    else
        print_info "Adding PORT..."
        echo "PORT=8080" >> /var/www/hajifund/.env
    fi
    
    print_status "Backend environment configured"
else
    print_error "Backend .env file not found"
    exit 1
fi

# 3. Configure frontend for direct deployment
print_step "3. Configuring frontend for direct deployment..."

if [ -f "/var/www/hajifund/frontend/.env" ]; then
    print_info "Frontend .env file found"
    
    # Set API_BASE_URL for direct backend connection
    if grep -q "API_BASE_URL" /var/www/hajifund/frontend/.env; then
        print_info "API_BASE_URL found, updating..."
        sed -i 's/API_BASE_URL=.*/API_BASE_URL=http:\/\/103.103.20.68:8080/' /var/www/hajifund/frontend/.env
    else
        print_info "Adding API_BASE_URL..."
        echo "API_BASE_URL=http://103.103.20.68:8080" >> /var/www/hajifund/frontend/.env
    fi
    
    # Set BACKEND_URL
    if grep -q "BACKEND_URL" /var/www/hajifund/frontend/.env; then
        print_info "BACKEND_URL found, updating..."
        sed -i 's/BACKEND_URL=.*/BACKEND_URL=http:\/\/103.103.20.68:8080/' /var/www/hajifund/frontend/.env
    else
        print_info "Adding BACKEND_URL..."
        echo "BACKEND_URL=http://103.103.20.68:8080" >> /var/www/hajifund/frontend/.env
    fi
    
    # Set FRONTEND_URL
    if grep -q "FRONTEND_URL" /var/www/hajifund/frontend/.env; then
        print_info "FRONTEND_URL found, updating..."
        sed -i 's/FRONTEND_URL=.*/FRONTEND_URL=http:\/\/103.103.20.68/' /var/www/hajifund/frontend/.env
    else
        print_info "Adding FRONTEND_URL..."
        echo "FRONTEND_URL=http://103.103.20.68" >> /var/www/hajifund/frontend/.env
    fi
    
    # Set PORT for frontend
    if grep -q "PORT" /var/www/hajifund/frontend/.env; then
        print_info "PORT found, updating..."
        sed -i 's/PORT=.*/PORT=80/' /var/www/hajifund/frontend/.env
    else
        print_info "Adding PORT..."
        echo "PORT=80" >> /var/www/hajifund/frontend/.env
    fi
    
    print_status "Frontend environment configured"
else
    print_error "Frontend .env file not found"
    exit 1
fi

# 4. Fix backend cookie settings for direct deployment
print_step "4. Fixing backend cookie settings for direct deployment..."

if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Backend main.go found, checking cookie configuration..."
    
    # Check if cookie domain is set correctly for VPS IP
    if grep -q "CookieDomain.*103.103.20.68" /var/www/hajifund/main.go; then
        print_info "Cookie domain is already set to VPS IP"
    else
        print_info "Updating cookie domain to VPS IP..."
        
        # Update cookie domain to VPS IP
        if grep -q "CookieDomain" /var/www/hajifund/main.go; then
            sed -i 's/CookieDomain:.*/CookieDomain: "103.103.20.68",/g' /var/www/hajifund/main.go
        else
            # Add cookie domain if not found
            sed -i '/CookiePath/a\
        CookieDomain: "103.103.20.68",' /var/www/hajifund/main.go
        fi
        
        print_status "Cookie domain updated to VPS IP"
    fi
    
    # Check if cookie path is set correctly
    if grep -q "CookiePath.*/" /var/www/hajifund/main.go; then
        print_info "Cookie path is set correctly"
    else
        print_info "Updating cookie path..."
        
        if grep -q "CookiePath" /var/www/hajifund/main.go; then
            sed -i 's/CookiePath:.*/CookiePath: "\/",/g' /var/www/hajifund/main.go
        else
            # Add cookie path if not found
            sed -i '/CookieDomain/a\
        CookiePath: "\/",' /var/www/hajifund/main.go
        fi
        
        print_status "Cookie path updated"
    fi
    
    # Check if cookie secure is set correctly for HTTP
    if grep -q "CookieSecure.*false" /var/www/hajifund/main.go; then
        print_info "Cookie secure is set to false (correct for HTTP)"
    else
        print_info "Updating cookie secure setting..."
        
        if grep -q "CookieSecure" /var/www/hajifund/main.go; then
            sed -i 's/CookieSecure:.*/CookieSecure: false,/g' /var/www/hajifund/main.go
        else
            # Add cookie secure if not found
            sed -i '/CookiePath/a\
        CookieSecure: false,' /var/www/hajifund/main.go
        fi
        
        print_status "Cookie secure updated to false (for HTTP)"
    fi
    
    # Check if cookie same site is set correctly
    if grep -q "CookieSameSite.*http.SameSiteLaxMode" /var/www/hajifund/main.go; then
        print_info "Cookie same site is set correctly"
    else
        print_info "Updating cookie same site setting..."
        
        if grep -q "CookieSameSite" /var/www/hajifund/main.go; then
            sed -i 's/CookieSameSite:.*/CookieSameSite: http.SameSiteLaxMode,/g' /var/www/hajifund/main.go
        else
            # Add cookie same site if not found
            sed -i '/CookieSecure/a\
        CookieSameSite: http.SameSiteLaxMode,' /var/www/hajifund/main.go
        fi
        
        print_status "Cookie same site updated"
    fi
    
    print_status "Backend cookie settings updated"
else
    print_error "Backend main.go not found"
    exit 1
fi

# 5. Update systemd services for direct deployment
print_step "5. Updating systemd services for direct deployment..."

# Update backend service
print_info "Updating backend systemd service..."
    
cat > /etc/systemd/system/hajifund-backend.service << 'EOF'
[Unit]
Description=HajiFund Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund
ExecStart=/var/www/hajifund/hajifund-backend
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
EOF
    
print_status "Backend systemd service updated"

# Update frontend service
print_info "Updating frontend systemd service..."
    
cat > /etc/systemd/system/hajifund-frontend.service << 'EOF'
[Unit]
Description=HajiFund Frontend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund/frontend
ExecStart=/var/www/hajifund/frontend/hajifund-frontend
Restart=always
RestartSec=5
Environment=PORT=80
Environment=GIN_MODE=release

[Install]
WantedBy=multi-user.target
EOF
    
print_status "Frontend systemd service updated"

# 6. Rebuild and restart services
print_step "6. Rebuilding and restarting services..."

# Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend
systemctl stop hajifund-frontend

# Build backend
print_info "Building backend..."
cd /var/www/hajifund
go build -o hajifund-backend main.go

# Set backend permissions
chown www-data:www-data /var/www/hajifund/hajifund-backend
chmod +x /var/www/hajifund/hajifund-backend
print_status "Backend binary permissions set"

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend

# Check if frontend has go.mod
if [ ! -f "go.mod" ]; then
    print_info "Initializing frontend Go modules..."
    go mod init hajifund-frontend
    go mod tidy
fi

go build -o hajifund-frontend main.go

# Set frontend permissions
chown www-data:www-data /var/www/hajifund/frontend/hajifund-frontend
chmod +x /var/www/hajifund/frontend/hajifund-frontend
print_status "Frontend binary permissions set"

# Reload systemd
print_info "Reloading systemd..."
systemctl daemon-reload

# Start services
print_info "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend

# Enable services
print_info "Enabling services..."
systemctl enable hajifund-backend
systemctl enable hajifund-frontend

# Check service status
print_info "Checking service status..."

# Wait a moment for services to start
sleep 5

if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running on port 8080"
else
    print_error "Backend service failed to start"
    print_info "Backend service status:"
    systemctl status hajifund-backend --no-pager
    print_info "Backend logs:"
    journalctl -u hajifund-backend --no-pager -l | tail -10
fi

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running on port 80"
else
    print_error "Frontend service failed to start"
    print_info "Frontend service status:"
    systemctl status hajifund-frontend --no-pager
    print_info "Frontend logs:"
    journalctl -u hajifund-frontend --no-pager -l | tail -10
fi

# 7. Test authentication
print_step "7. Testing authentication..."

# Test backend directly
print_info "Testing backend directly..."
if curl -s http://103.103.20.68:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be responding correctly"
fi

# Test frontend directly
print_info "Testing frontend directly..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding correctly"
fi

# Test login endpoint
print_info "Testing login endpoint..."
if curl -s -X POST http://103.103.20.68:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}' \
    | grep -q "auth_token"; then
    print_status "Login endpoint returns auth_token"
else
    print_warning "Login endpoint might not be setting auth_token correctly"
fi

# 8. Final test
print_step "8. Final authentication test..."

print_info "Testing complete authentication flow..."
print_info "1. Try logging in at: http://103.103.20.68/login"
print_info "2. Check browser developer tools for auth_token cookie"
print_info "3. Verify redirect to dashboard works"
print_info "4. Check that cookies are set with correct domain (103.103.20.68)"

print_status "Direct Golang auth token cookie fix completed!"
print_info "Services running:"
print_info "- Backend: http://103.103.20.68:8080"
print_info "- Frontend: http://103.103.20.68"
print_info "If issues persist, check:"
print_info "- Backend logs: journalctl -u hajifund-backend -f"
print_info "- Frontend logs: journalctl -u hajifund-frontend -f"
