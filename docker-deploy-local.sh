#!/bin/bash

# HajiFund Docker Deployment Script - Uses Local Working Configuration
# This script copies your working local Docker setup to VPS

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

print_step "Starting HajiFund Docker Deployment (Using Local Working Configuration)"
print_info "This script will copy your working local Docker setup to VPS"

# 1. Update system and install Docker
print_step "1. Installing Docker and Docker Compose..."

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker $USER

print_status "Docker and Docker Compose installed"

# 2. Create project directory
print_step "2. Setting up project directory..."

PROJECT_DIR="/opt/hajifund"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

print_status "Project directory created at $PROJECT_DIR"

# 3. Copy all working files from local setup
print_step "3. Copying working local configuration..."

# Copy the entire project structure
LOCAL_PROJECT_PATH="/Users/alkha/Documents/project/comfunds"

if [ ! -d "$LOCAL_PROJECT_PATH" ]; then
    print_error "Local project path not found: $LOCAL_PROJECT_PATH"
    print_info "Please make sure the path is correct"
    exit 1
fi

# Copy essential files
print_info "Copying Docker configuration files..."
cp "$LOCAL_PROJECT_PATH/docker-compose.yml" ./docker-compose.yml
cp "$LOCAL_PROJECT_PATH/Dockerfile.backend" ./Dockerfile.backend
cp "$LOCAL_PROJECT_PATH/Dockerfile.frontend" ./Dockerfile.frontend

# Copy nginx configuration
if [ -d "$LOCAL_PROJECT_PATH/docker/nginx" ]; then
    cp -r "$LOCAL_PROJECT_PATH/docker/nginx" ./docker/
fi

# Copy PostgreSQL initialization files
if [ -d "$LOCAL_PROJECT_PATH/docker/postgres" ]; then
    cp -r "$LOCAL_PROJECT_PATH/docker/postgres" ./docker/
fi

# Copy Go modules
cp "$LOCAL_PROJECT_PATH/go.mod" ./go.mod
cp "$LOCAL_PROJECT_PATH/go.sum" ./go.sum

# Copy frontend Go modules
mkdir -p frontend
cp "$LOCAL_PROJECT_PATH/frontend/go.mod" ./frontend/go.mod
cp "$LOCAL_PROJECT_PATH/frontend/go.sum" ./frontend/go.sum

# Copy source code
print_info "Copying source code..."
cp -r "$LOCAL_PROJECT_PATH/internal" ./internal/
cp -r "$LOCAL_PROJECT_PATH/frontend/handlers" ./frontend/handlers/
cp -r "$LOCAL_PROJECT_PATH/frontend/middleware" ./frontend/middleware/
cp -r "$LOCAL_PROJECT_PATH/frontend/models" ./frontend/models/
cp -r "$LOCAL_PROJECT_PATH/frontend/static" ./frontend/static/
cp -r "$LOCAL_PROJECT_PATH/frontend/utils" ./frontend/utils/
cp -r "$LOCAL_PROJECT_PATH/frontend/views" ./frontend/views/

# Copy main files
cp "$LOCAL_PROJECT_PATH/main.go" ./main.go
cp "$LOCAL_PROJECT_PATH/frontend/main.go" ./frontend/main.go

# Create uploads directory
mkdir -p uploads
chmod 755 uploads

print_status "All files copied successfully"

# 4. Create environment file
print_step "4. Creating environment configuration..."

cat > .env << 'EOF'
# Database Configuration
DB_PASSWORD=comfunds123

# Application Configuration
ENVIRONMENT=production
JWT_SECRET=hajifund-super-secret-jwt-key-production-2024-docker

# CORS Configuration
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080

# API Configuration
API_URL=http://backend:8080

# Logging
LOG_LEVEL=info
EOF

print_status "Environment configuration created"

# 5. Build and start containers
print_step "5. Building and starting containers..."

# Build and start all services
docker-compose up -d --build

print_status "Containers built and started"

# 6. Wait for services to be ready
print_step "6. Waiting for services to be ready..."

sleep 60

# Check if services are running
print_info "Checking service status..."

# Check PostgreSQL shards
for shard in 0 1 2 3; do
    if docker-compose exec -T postgres-comfunds${shard} pg_isready -U postgres > /dev/null 2>&1; then
        print_status "PostgreSQL shard ${shard} is ready"
    else
        print_warning "PostgreSQL shard ${shard} is not ready yet"
    fi
done

# Check Backend
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is ready"
else
    print_warning "Backend is not ready yet"
fi

# Check Frontend
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "Frontend is ready"
else
    print_warning "Frontend is not ready yet"
fi

# 7. Test the application
print_step "7. Testing the application..."

sleep 30

# Test credentials
TEST_EMAIL="testuser$(date +%s)@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User $(date +%s)"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

print_info "Testing complete flow..."

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

# 8. Show container status
print_step "8. Container status..."

docker-compose ps

# 9. Summary
print_status "Docker deployment completed!"
print_info ""
print_info "🎉 What was deployed:"
print_info "✅ PostgreSQL database with 4 shards (exact local setup)"
print_info "✅ Backend API service (exact local setup)"
print_info "✅ Frontend web service (exact local setup)"
print_info "✅ All services containerized"
print_info "✅ Using your working local configuration"
print_info ""
print_info "🌐 Your application is now available at:"
print_info "   Main site: http://103.103.20.68"
print_info "   Login page: http://103.103.20.68/login"
print_info "   Admin panel: http://103.103.20.68/admin"
print_info ""
print_info "🔧 Test credentials created:"
print_info "   Email: $TEST_EMAIL"
print_info "   Password: $TEST_PASSWORD"
print_info ""
print_info "📋 Management commands:"
print_info "   View logs: docker-compose logs -f"
print_info "   Stop services: docker-compose down"
print_info "   Restart services: docker-compose restart"
print_info "   Update services: docker-compose pull && docker-compose up -d"
print_info ""
print_info "This deployment uses your exact working local configuration!"
print_info "All services should work exactly like they do locally!"
