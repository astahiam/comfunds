#!/bin/bash

# Open Port 3000 in Firewall
# This script opens port 3000 for external access

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

print_step "Opening Port 3000 in Firewall"

# 1. Check if UFW is installed
print_step "1. Checking UFW firewall..."

if command -v ufw &> /dev/null; then
    print_status "UFW firewall is installed"
else
    print_info "Installing UFW firewall..."
    apt update
    apt install -y ufw
    print_status "UFW firewall installed"
fi

# 2. Check UFW status
print_info "Current UFW status:"
ufw status verbose

# 3. Open port 3000
print_step "2. Opening port 3000..."

print_info "Allowing port 3000 through firewall..."
ufw allow 3000/tcp
print_status "Port 3000 allowed"

# 4. Also ensure port 8080 is open for backend
print_step "3. Ensuring backend port 8080 is open..."

print_info "Allowing port 8080 through firewall..."
ufw allow 8080/tcp
print_status "Port 8080 allowed"

# 5. Check if SSH port is open (important!)
print_step "4. Ensuring SSH port is open..."

if ufw status | grep -q "22/tcp"; then
    print_status "SSH port 22 is already open"
else
    print_warning "SSH port 22 is not open, adding it..."
    ufw allow 22/tcp
    print_status "SSH port 22 allowed"
fi

# 6. Enable UFW if not already enabled
print_step "5. Enabling UFW firewall..."

if ufw status | grep -q "Status: active"; then
    print_status "UFW is already active"
else
    print_info "Enabling UFW firewall..."
    ufw --force enable
    print_status "UFW firewall enabled"
fi

# 7. Show current firewall rules
print_step "6. Showing current firewall rules..."

print_info "Current UFW rules:"
ufw status numbered

# 8. Test if ports are accessible
print_step "7. Testing port accessibility..."

# Test port 3000
print_info "Testing port 3000..."
if netstat -tlnp | grep -q ":3000"; then
    print_status "Port 3000 is listening"
else
    print_warning "Port 3000 is not listening (frontend might not be running)"
fi

# Test port 8080
print_info "Testing port 8080..."
if netstat -tlnp | grep -q ":8080"; then
    print_status "Port 8080 is listening"
else
    print_warning "Port 8080 is not listening (backend might not be running)"
fi

# 9. Show access information
print_step "8. Access Information"

print_status "Firewall configuration completed!"
print_info "Your application is now accessible from outside:"
print_info "- Frontend: http://103.103.20.68:3000"
print_info "- Backend: http://103.103.20.68:8080"
print_info ""
print_info "Firewall rules applied:"
print_info "- Port 3000 (Frontend): ALLOWED"
print_info "- Port 8080 (Backend): ALLOWED"
print_info "- Port 22 (SSH): ALLOWED"

# 10. Optional: Show how to test from outside
print_step "9. Testing from outside (optional)"

print_info "To test from outside, you can run these commands from another machine:"
print_info "curl http://103.103.20.68:3000"
print_info "curl http://103.103.20.68:8080/api/v1/health"

print_status "Port 3000 firewall configuration completed!"
print_warning "Make sure your frontend service is running on port 3000"
print_info "Check with: systemctl status hajifund-frontend"
