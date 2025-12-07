#!/bin/bash

# Fix Docker Build Segmentation Fault Issue
# This script diagnoses and fixes Docker build issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
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

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_header "Docker Build Issue Troubleshooting"

# Step 1: Check Docker version
print_step "1. Checking Docker installation..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
print_info "Docker: $DOCKER_VERSION"

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    print_info "Docker Compose: $COMPOSE_VERSION"
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_info "Docker Compose (plugin): $COMPOSE_VERSION"
else
    print_error "Docker Compose not found"
    exit 1
fi

# Step 2: Check system resources
print_step "2. Checking system resources..."

# Check memory
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
AVAIL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
print_info "Total Memory: ${TOTAL_MEM}MB"
print_info "Available Memory: ${AVAIL_MEM}MB"

if [ "$AVAIL_MEM" -lt 512 ]; then
    print_warning "Low memory available. Docker build may fail."
    print_info "Consider stopping other services or adding swap space"
fi

# Check disk space
DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}')
print_info "Available Disk Space: $DISK_SPACE"

# Step 3: Check Docker daemon
print_step "3. Checking Docker daemon..."

if ! docker info >/dev/null 2>&1; then
    print_error "Docker daemon is not running"
    print_info "Start Docker: sudo systemctl start docker"
    exit 1
fi
print_status "Docker daemon is running"

# Step 4: Clean Docker
print_step "4. Cleaning Docker cache and build cache..."

print_info "Removing unused containers..."
docker container prune -f >/dev/null 2>&1 || true

print_info "Removing unused images..."
docker image prune -f >/dev/null 2>&1 || true

print_info "Removing build cache..."
docker builder prune -f >/dev/null 2>&1 || true

print_status "Docker cleaned"

# Step 5: Test simple build
print_step "5. Testing simple Docker build..."

print_info "Testing with a simple image..."
if docker build --help >/dev/null 2>&1; then
    print_status "Docker build command works"
else
    print_error "Docker build command failed"
    exit 1
fi

# Step 6: Provide alternative build method
print_step "6. Creating alternative build script..."

cat > build-images-individually.sh << 'BUILD_SCRIPT'
#!/bin/bash

# Build Docker images individually (workaround for docker-compose segfault)

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

echo "Building Docker images individually..."

# Build backend
if [ -f "Dockerfile.backend" ]; then
    print_step "Building backend image..."
    docker build -f Dockerfile.backend -t hajifund-backend .
    print_status "Backend image built"
fi

# Build frontend
if [ -f "frontend/Dockerfile.frontend" ] || [ -f "frontend/Dockerfile" ]; then
    print_step "Building frontend image..."
    if [ -f "frontend/Dockerfile.frontend" ]; then
        docker build -f frontend/Dockerfile.frontend -t hajifund-frontend ./frontend
    else
        docker build -f frontend/Dockerfile -t hajifund-frontend ./frontend
    fi
    print_status "Frontend image built"
fi

print_status "All images built successfully!"
BUILD_SCRIPT

chmod +x build-images-individually.sh
print_status "Alternative build script created: build-images-individually.sh"

# Step 7: Create updated deployment script
print_step "7. Creating updated deployment script with workarounds..."

cat > deploy-vps-safe.sh << 'DEPLOY_SCRIPT'
#!/bin/bash

# Safe VPS Deployment Script (with Docker build workarounds)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

PROJECT_DIR="${PROJECT_DIR:-$HOME/sourcecode}"
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres123}"

cd "$PROJECT_DIR"

print_step "Safe VPS Deployment"

# Build images individually (workaround for docker-compose segfault)
print_step "Building images individually..."

if [ -f "build-images-individually.sh" ]; then
    ./build-images-individually.sh
else
    print_warning "build-images-individually.sh not found, trying direct build..."
    
    # Try building directly
    if [ -f "Dockerfile.backend" ]; then
        docker build -f Dockerfile.backend -t hajifund-backend . || print_warning "Backend build failed"
    fi
    
    if [ -f "frontend/Dockerfile" ]; then
        docker build -f frontend/Dockerfile -t hajifund-frontend ./frontend || print_warning "Frontend build failed"
    fi
fi

# Start services using docker-compose (images already built)
print_step "Starting services..."

# Use docker compose (newer) or docker-compose (older)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Start PostgreSQL first
print_step "Starting PostgreSQL..."
$COMPOSE_CMD up -d postgres
sleep 10

# Run migrations
print_step "Running migrations..."
if [ -f "run-golang-migrations.sh" ]; then
    DB_HOST="$DB_HOST" DB_USER="$DB_USER" DB_PASSWORD="$DB_PASSWORD" \
        ./run-golang-migrations.sh up || print_warning "Migrations failed"
fi

# Start all services
print_step "Starting all services..."
$COMPOSE_CMD up -d

print_status "Deployment completed!"
print_step "Check status: $COMPOSE_CMD ps"
DEPLOY_SCRIPT

chmod +x deploy-vps-safe.sh
print_status "Safe deployment script created: deploy-vps-safe.sh"

# Step 8: Recommendations
print_header "Recommendations"

print_info "1. Try using the safe deployment script:"
echo "   ./deploy-vps-safe.sh"
echo ""

print_info "2. Or build images individually:"
echo "   ./build-images-individually.sh"
echo "   docker-compose up -d"
echo ""

print_info "3. If issues persist, try:"
echo "   - Restart Docker: sudo systemctl restart docker"
echo "   - Update Docker: Check for updates"
echo "   - Use newer docker compose (plugin): docker compose build"
echo ""

print_info "4. Check Docker logs:"
echo "   sudo journalctl -u docker.service -n 50"
echo ""

print_status "Troubleshooting complete!"

