#!/bin/bash

# Fix Duplicate Function Declaration
# This script removes duplicate setVPSCookie function declarations

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

print_step "Fixing Duplicate Function Declaration"

# 1. Check if auth.go exists
if [ ! -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_error "auth.go file not found at /var/www/hajifund/frontend/handlers/auth.go"
    exit 1
fi

# 2. Backup the file
print_info "Creating backup..."
cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup

# 3. Check for duplicate setVPSCookie functions
print_info "Checking for duplicate setVPSCookie functions..."

# Count occurrences of setVPSCookie function
COUNT=$(grep -c "func setVPSCookie" /var/www/hajifund/frontend/handlers/auth.go || true)

if [ "$COUNT" -gt 1 ]; then
    print_info "Found $COUNT setVPSCookie functions, removing duplicates..."
    
    # Remove all setVPSCookie functions and add only one
    # First, remove all existing setVPSCookie functions
    sed -i '/^\/\/ VPS-specific cookie configuration/,/^}/d' /var/www/hajifund/frontend/handlers/auth.go
    sed -i '/^func setVPSCookie/,/^}/d' /var/www/hajifund/frontend/handlers/auth.go
    
    # Add a single setVPSCookie function at the end
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
    
    print_status "Removed duplicate setVPSCookie functions and added single function"
else
    print_info "No duplicate setVPSCookie functions found"
fi

# 4. Test the Go file for syntax errors
print_info "Testing Go file for syntax errors..."

cd /var/www/hajifund/frontend

if go build -o /dev/null ./handlers/auth.go 2>/dev/null; then
    print_status "Go file syntax is correct"
else
    print_error "Go file has syntax errors"
    print_info "Restoring backup..."
    cp /var/www/hajifund/frontend/handlers/auth.go.backup /var/www/hajifund/frontend/handlers/auth.go
    exit 1
fi

# 5. Build the frontend application
print_info "Building frontend application..."

if go build -o frontend main.go; then
    print_status "Frontend application built successfully"
else
    print_error "Failed to build frontend application"
    exit 1
fi

# 6. Restart the frontend service
print_info "Restarting frontend service..."

systemctl restart hajifund-frontend
sleep 5

# Check if service is running
if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running"
else
    print_error "Frontend service failed to start"
    echo "Service status:"
    systemctl status hajifund-frontend --no-pager -l
    exit 1
fi

print_status "Duplicate function declaration fixed!"
print_info ""
print_info "🎯 What was fixed:"
print_info "✅ Removed duplicate setVPSCookie function declarations"
print_info "✅ Added single setVPSCookie function"
print_info "✅ Tested Go file syntax"
print_info "✅ Built frontend application"
print_info "✅ Restarted frontend service"
print_info ""
print_info "The duplicate function declaration error should now be resolved!"
