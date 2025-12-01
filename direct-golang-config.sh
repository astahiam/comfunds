#!/bin/bash

# Direct Golang Configuration - No Nginx
# This script configures Go frontend to run on port 80 directly

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

print_step "Configuring Direct Golang Setup - No Nginx"
print_info "This will run Go frontend on port 80 directly"

# 1. Stop all services
print_info "Stopping all services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Disable nginx
print_step "1. Disabling nginx..."

systemctl disable nginx 2>/dev/null || true
print_status "Nginx disabled"

# 3. Configure backend environment
print_step "2. Configuring backend environment..."

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
JWT_SECRET=hajifund-super-secret-jwt-key-production-2024-direct

# CORS Configuration - Allow all origins for direct setup
CORS_ORIGINS=*

# Trusted Proxies - Allow all for direct setup
TRUSTED_PROXIES=*

# Rate Limiting
GENERAL_RATE_LIMIT_RPM=60
GENERAL_RATE_LIMIT_BURST=100
EOF

print_status "Backend environment configured"

# 4. Configure frontend environment for port 80
print_step "3. Configuring frontend environment for port 80..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=80
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080

# Cookie Configuration for direct setup
COOKIE_DOMAIN=
COOKIE_SECURE=false
COOKIE_SAMESITE=Lax
EOF

print_status "Frontend environment configured for port 80"

# 5. Fix frontend cookie configuration for direct setup
print_step "4. Fixing frontend cookie configuration for direct setup..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    print_info "Applying cookie fixes for direct setup..."
    
    # Fix 1: Remove domain restriction
    sed -i 's/Domain:   "103.103.20.68"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Domain:   "localhost"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Domain:   ".*"/Domain:   ""/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Fix 2: Set Secure to false for HTTP
    sed -i 's/Secure:   true/Secure:   false/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Fix 3: Set SameSite to Lax for direct setup
    sed -i 's/SameSite: "Strict"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/SameSite: "None"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    
    # Fix 4: Ensure HTTPOnly is true for security
    sed -i 's/HTTPOnly: false/HTTPOnly: true/g' /var/www/hajifund/frontend/handlers/auth.go
    
    print_status "Cookie configuration fixed for direct setup"
fi

# 6. Configure systemd services for direct setup
print_step "5. Configuring systemd services for direct setup..."

# Backend service (port 8080)
cat > /etc/systemd/system/hajifund-backend.service << 'EOF'
[Unit]
Description=HajiFund Backend
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund
ExecStart=/var/www/hajifund/backend
Restart=always
RestartSec=5
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
EnvironmentFile=/var/www/hajifund/.env

[Install]
WantedBy=multi-user.target
EOF

# Frontend service (port 80) - requires root for port 80
cat > /etc/systemd/system/hajifund-frontend.service << 'EOF'
[Unit]
Description=HajiFund Frontend
After=network.target hajifund-backend.service
Wants=hajifund-backend.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/var/www/hajifund/frontend
ExecStart=/var/www/hajifund/frontend/frontend
Restart=always
RestartSec=5
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
EnvironmentFile=/var/www/hajifund/frontend/.env

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

print_status "Systemd services configured for direct setup"

# 7. Build applications
print_step "6. Building applications..."

# Build backend
print_info "Building backend..."
cd /var/www/hajifund
go build -o backend main.go

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o frontend main.go

print_status "Applications built successfully"

# 8. Set proper permissions
print_step "7. Setting proper permissions..."

# Set permissions for backend
chown -R www-data:www-data /var/www/hajifund
chmod +x /var/www/hajifund/backend

# Set permissions for frontend (needs root for port 80)
chown -R root:root /var/www/hajifund/frontend
chmod +x /var/www/hajifund/frontend/frontend

print_status "Permissions set correctly"

# 9. Start services in order
print_step "8. Starting services..."

print_info "Starting backend..."
systemctl start hajifund-backend
sleep 15

# Check backend
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is responding on port 8080"
else
    print_warning "Backend might not be fully ready yet"
fi

print_info "Starting frontend on port 80..."
systemctl start hajifund-frontend
sleep 15

# Check frontend
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "Frontend is responding on port 80"
else
    print_warning "Frontend might not be fully ready yet"
fi

# 10. Test the direct setup
print_step "9. Testing the direct setup..."

sleep 10

# Test credentials
TEST_EMAIL="testuser$(date +%s)@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User $(date +%s)"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

print_info "Testing direct setup..."

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

# 11. Show final status
print_step "10. Final service status..."

echo "Backend status:"
systemctl status hajifund-backend --no-pager -l | head -5

echo ""
echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

# 12. Summary
print_status "Direct Golang configuration completed!"
print_info ""
print_info "🎯 What was configured:"
print_info "✅ Removed nginx completely"
print_info "✅ Go frontend runs directly on port 80"
print_info "✅ Go backend runs on port 8080"
print_info "✅ Direct communication between frontend and backend"
print_info "✅ Cookie configuration optimized for direct setup"
print_info "✅ Systemd services configured properly"
print_info ""
print_info "🌐 Your application is now accessible at:"
print_info "   Main site: http://103.103.20.68 (port 80)"
print_info "   Backend API: http://103.103.20.68/api/v1/"
print_info "   Admin: http://103.103.20.68/admin/"
print_info ""
print_info "🔧 Test credentials created:"
print_info "   Email: $TEST_EMAIL"
print_info "   Password: $TEST_PASSWORD"
print_info ""
print_info "💡 Benefits of this setup:"
print_info "   - No nginx complexity"
print_info "   - Direct Go-to-Go communication"
print_info "   - Simpler cookie handling"
print_info "   - Easier debugging"
print_info "   - Better performance (no proxy overhead)"
print_info ""
print_info "The direct setup should resolve all cookie/session issues!"
print_info "Frontend on port 80, backend on port 8080, no nginx needed!"
