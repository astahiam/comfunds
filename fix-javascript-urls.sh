#!/bin/bash

# Fix JavaScript URLs
# This script fixes hardcoded localhost URLs in JavaScript files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_step "Fixing JavaScript URLs"

# 1. Fix hardcoded localhost URLs in app.js
print_step "1. Fixing hardcoded localhost URLs in app.js..."

if [ -f "/var/www/hajifund/frontend/static/js/app.js" ]; then
    print_info "Updating hardcoded URLs in app.js..."
    
    # Replace localhost:8080 with VPS IP:8080
    sed -i 's/http:\/\/localhost:8080/http:\/\/103.103.20.68:8080/g' /var/www/hajifund/frontend/static/js/app.js
    
    # Replace localhost:3000 with VPS IP
    sed -i 's/http:\/\/localhost:3000/http:\/\/103.103.20.68/g' /var/www/hajifund/frontend/static/js/app.js
    
    # Replace localhost with VPS IP
    sed -i 's/http:\/\/localhost/http:\/\/103.103.20.68/g' /var/www/hajifund/frontend/static/js/app.js
    
    print_status "Hardcoded URLs updated in app.js"
else
    print_error "app.js not found"
fi

# 2. Check for other JavaScript files with hardcoded URLs
print_step "2. Checking for other JavaScript files..."

find /var/www/hajifund/frontend -name "*.js" -type f | while read file; do
    if grep -q "localhost" "$file"; then
        print_info "Found localhost URLs in: $file"
        
        # Replace localhost URLs
        sed -i 's/http:\/\/localhost:8080/http:\/\/103.103.20.68:8080/g' "$file"
        sed -i 's/http:\/\/localhost:3000/http:\/\/103.103.20.68/g' "$file"
        sed -i 's/http:\/\/localhost/http:\/\/103.103.20.68/g' "$file"
        
        print_status "Updated URLs in: $file"
    fi
done

# 3. Check HTML files for hardcoded URLs
print_step "3. Checking HTML files for hardcoded URLs..."

find /var/www/hajifund/frontend -name "*.html" -type f | while read file; do
    if grep -q "localhost" "$file"; then
        print_info "Found localhost URLs in: $file"
        
        # Replace localhost URLs
        sed -i 's/http:\/\/localhost:8080/http:\/\/103.103.20.68:8080/g' "$file"
        sed -i 's/http:\/\/localhost:3000/http:\/\/103.103.20.68/g' "$file"
        sed -i 's/http:\/\/localhost/http:\/\/103.103.20.68/g' "$file"
        
        print_status "Updated URLs in: $file"
    fi
done

# 4. Check Go files for hardcoded URLs
print_step "4. Checking Go files for hardcoded URLs..."

find /var/www/hajifund -name "*.go" -type f | while read file; do
    if grep -q "localhost" "$file"; then
        print_info "Found localhost URLs in: $file"
        
        # Replace localhost URLs
        sed -i 's/http:\/\/localhost:8080/http:\/\/103.103.20.68:8080/g' "$file"
        sed -i 's/http:\/\/localhost:3000/http:\/\/103.103.20.68/g' "$file"
        sed -i 's/http:\/\/localhost/http:\/\/103.103.20.68/g' "$file"
        
        print_status "Updated URLs in: $file"
    fi
done

# 5. Verify the changes
print_step "5. Verifying the changes..."

print_info "Checking app.js for remaining localhost URLs..."
if grep -q "localhost" /var/www/hajifund/frontend/static/js/app.js; then
    print_warning "Still found localhost URLs in app.js:"
    grep -n "localhost" /var/www/hajifund/frontend/static/js/app.js
else
    print_status "No localhost URLs found in app.js"
fi

# 6. Rebuild and restart frontend
print_step "6. Rebuilding and restarting frontend..."

# Stop frontend
systemctl stop hajifund-frontend

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go
chown www-data:www-data hajifund-frontend
chmod +x hajifund-frontend
setcap 'cap_net_bind_service=+ep' hajifund-frontend
print_status "Frontend built"

# Start frontend
print_info "Starting frontend..."
systemctl start hajifund-frontend
print_status "Frontend started"

# 7. Test the fix
print_step "7. Testing the fix..."

sleep 3

# Test frontend
print_info "Testing frontend..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# Check if JavaScript is making requests to correct URLs
print_info "Checking JavaScript requests..."
print_info "Open browser developer tools and check Network tab for requests"
print_info "All requests should go to 103.103.20.68:8080, not localhost:3000"

print_status "JavaScript URLs fix completed!"
print_info "Issues addressed:"
print_info "1. Replaced localhost:8080 with 103.103.20.68:8080"
print_info "2. Replaced localhost:3000 with 103.103.20.68"
print_info "3. Updated all JavaScript files"
print_info "4. Updated all HTML files"
print_info "5. Updated all Go files"
print_info "6. Frontend rebuilt and restarted"

print_info "Test your application now:"
print_info "1. Open browser developer tools"
print_info "2. Check Network tab for requests"
print_info "3. All API calls should go to 103.103.20.68:8080"
print_info "4. No more localhost:3000 requests"
