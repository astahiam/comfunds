#!/bin/bash

# Fix Session/Login/Register Issues on VPS
# Run this on your VPS

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

cd ~/sourcecode

print_step "Fixing Session/Login/Register Issues"

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose not found"
    exit 1
fi

# Update docker-compose.yml to fix cookie domain
print_step "1. Updating docker-compose.yml cookie settings..."

if [ -f "docker-compose.yml" ]; then
    # Remove COOKIE_DOMAIN or set it to empty for IP addresses
    sed -i 's/COOKIE_DOMAIN:.*103\.103\.20\.68/COOKIE_DOMAIN: ""/' docker-compose.yml || \
    sed -i 's/COOKIE_DOMAIN: 103\.103\.20\.68/COOKIE_DOMAIN: ""/' docker-compose.yml || true
    
    # Ensure CORS_ORIGINS includes VPS IP
    if ! grep -q "CORS_ORIGINS.*103.103.20.68" docker-compose.yml; then
        sed -i 's/CORS_ORIGINS:.*/CORS_ORIGINS: http:\/\/103.103.20.68,http:\/\/103.103.20.68:3000,http:\/\/localhost:3000/' docker-compose.yml || true
    fi
    
    print_status "docker-compose.yml updated"
fi

# Restart frontend with new settings
print_step "2. Restarting frontend service..."

$COMPOSE_CMD stop frontend
$COMPOSE_CMD up -d --build frontend

print_status "Frontend restarted"

# Wait a bit
sleep 5

# Check if services are running
print_step "3. Checking service status..."

$COMPOSE_CMD ps

print_status "Fix completed!"
echo ""
echo "Test login/register at: http://103.103.20.68:3000/login"
echo ""

