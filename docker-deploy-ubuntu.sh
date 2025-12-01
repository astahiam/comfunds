#!/bin/bash

# HajiFund Docker Deployment Script for Ubuntu VPS
# This script handles file permissions and deploys everything properly

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

print_step "HajiFund Docker Deployment for Ubuntu VPS"

# 1. Update system and install Docker
print_step "1. Updating system and installing Docker..."

# Update package list
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    unzip

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

print_status "Docker installed successfully"

# 2. Create project directory
print_step "2. Creating project directory..."

# Create project directory
sudo mkdir -p /opt/hajifund
cd /opt/hajifund

# Set proper ownership
sudo chown -R $USER:$USER /opt/hajifund

print_status "Project directory created"

# 3. Copy project files
print_step "3. Copying project files..."

# Copy all project files (assuming you're running from project root)
if [ -f "docker-compose.yml" ]; then
    cp -r . /opt/hajifund/
    print_status "Project files copied"
else
    print_error "docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

# 4. Set up environment files
print_step "4. Setting up environment files..."

# Copy environment examples
if [ -f "env.example" ]; then
    cp env.example .env
    print_status "Backend .env created"
else
    print_warning "env.example not found, creating basic .env"
    cat > .env << 'EOF'
# Basic environment configuration
HOST=0.0.0.0
PORT=8080
GIN_MODE=release
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres123
DB_NAME=postgres
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redis123
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
ALLOWED_ORIGINS=http://103.103.20.68,http://localhost:3000
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000
TRUSTED_PROXIES=103.103.20.68,nginx
COOKIE_DOMAIN=103.103.20.68
COOKIE_PATH=/
COOKIE_SECURE=false
COOKIE_SAME_SITE=Lax
EOF
fi

# Frontend environment
if [ -f "frontend/env.example" ]; then
    cp frontend/env.example frontend/.env
    print_status "Frontend .env created"
else
    print_warning "frontend/env.example not found, creating basic frontend .env"
    cat > frontend/.env << 'EOF'
# Frontend environment configuration
HOST=0.0.0.0
PORT=3000
GIN_MODE=release
API_BASE_URL=http://backend:8080
BACKEND_URL=http://backend:8080
FRONTEND_URL=http://103.103.20.68
ALLOWED_ORIGINS=http://103.103.20.68,http://localhost:3000
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000
TRUSTED_PROXIES=103.103.20.68,nginx
COOKIE_DOMAIN=103.103.20.68
COOKIE_PATH=/
COOKIE_SECURE=false
COOKIE_SAME_SITE=Lax
EOF
fi

# 5. Set proper file permissions
print_step "5. Setting proper file permissions..."

# Set ownership
sudo chown -R $USER:$USER /opt/hajifund

# Set directory permissions
find /opt/hajifund -type d -exec chmod 755 {} \;

# Set file permissions
find /opt/hajifund -type f -exec chmod 644 {} \;

# Make scripts executable
find /opt/hajifund -name "*.sh" -exec chmod +x {} \;

# Set specific permissions for sensitive files
chmod 600 /opt/hajifund/.env
chmod 600 /opt/hajifund/frontend/.env

# Create directories for uploads and logs
mkdir -p /opt/hajifund/uploads
mkdir -p /opt/hajifund/logs
mkdir -p /opt/hajifund/frontend/uploads
mkdir -p /opt/hajifund/frontend/logs

# Set permissions for upload and log directories
chmod 755 /opt/hajifund/uploads
chmod 755 /opt/hajifund/logs
chmod 755 /opt/hajifund/frontend/uploads
chmod 755 /opt/hajifund/frontend/logs

print_status "File permissions set correctly"

# 6. Configure firewall
print_step "6. Configuring firewall..."

# Install UFW if not present
sudo apt-get install -y ufw

# Configure firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

print_status "Firewall configured"

# 7. Build and start services
print_step "7. Building and starting services..."

# Build and start with Docker Compose
cd /opt/hajifund

# Pull base images
docker compose pull

# Build custom images
docker compose build --no-cache

# Start services
docker compose up -d

print_status "Services started"

# 8. Wait for services to be ready
print_step "8. Waiting for services to be ready..."

# Wait for database
print_info "Waiting for database..."
timeout 60 bash -c 'until docker compose exec postgres pg_isready -U postgres; do sleep 2; done'

# Wait for Redis
print_info "Waiting for Redis..."
timeout 30 bash -c 'until docker compose exec redis redis-cli ping; do sleep 2; done'

# Wait for backend
print_info "Waiting for backend..."
timeout 60 bash -c 'until curl -f http://localhost:8080/api/v1/health; do sleep 2; done'

# Wait for frontend
print_info "Waiting for frontend..."
timeout 60 bash -c 'until curl -f http://localhost:3000/; do sleep 2; done'

print_status "All services are ready"

# 9. Test the deployment
print_step "9. Testing the deployment..."

# Test backend health
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is healthy"
else
    print_warning "Backend health check failed"
fi

# Test frontend
if curl -s http://localhost:3000/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend test failed"
fi

# Test external access
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "External access is working"
else
    print_warning "External access test failed"
fi

# 10. Show service status
print_step "10. Service status..."

print_info "Docker containers status:"
docker compose ps

print_info "Service logs (last 10 lines each):"
echo "=== Backend Logs ==="
docker compose logs --tail=10 backend

echo "=== Frontend Logs ==="
docker compose logs --tail=10 frontend

echo "=== Nginx Logs ==="
docker compose logs --tail=10 nginx

# 11. Create management scripts
print_step "11. Creating management scripts..."

# Create start script
cat > /opt/hajifund/start.sh << 'EOF'
#!/bin/bash
cd /opt/hajifund
docker compose up -d
echo "HajiFund services started"
EOF

# Create stop script
cat > /opt/hajifund/stop.sh << 'EOF'
#!/bin/bash
cd /opt/hajifund
docker compose down
echo "HajiFund services stopped"
EOF

# Create restart script
cat > /opt/hajifund/restart.sh << 'EOF'
#!/bin/bash
cd /opt/hajifund
docker compose down
docker compose up -d
echo "HajiFund services restarted"
EOF

# Create logs script
cat > /opt/hajifund/logs.sh << 'EOF'
#!/bin/bash
cd /opt/hajifund
docker compose logs -f
EOF

# Create update script
cat > /opt/hajifund/update.sh << 'EOF'
#!/bin/bash
cd /opt/hajifund
docker compose down
docker compose pull
docker compose build --no-cache
docker compose up -d
echo "HajiFund services updated"
EOF

# Make scripts executable
chmod +x /opt/hajifund/*.sh

print_status "Management scripts created"

# 12. Final status
print_step "12. Deployment completed!"

print_status "HajiFund Docker deployment completed successfully!"
print_info "Services are running at:"
print_info "  Frontend: http://103.103.20.68/"
print_info "  Backend API: http://103.103.20.68:8080/api/v1/"
print_info "  Admin: http://103.103.20.68/admin"

print_info "Management commands:"
print_info "  Start: /opt/hajifund/start.sh"
print_info "  Stop: /opt/hajifund/stop.sh"
print_info "  Restart: /opt/hajifund/restart.sh"
print_info "  Logs: /opt/hajifund/logs.sh"
print_info "  Update: /opt/hajifund/update.sh"

print_info "File permissions have been set correctly:"
print_info "  Directories: 755"
print_info "  Files: 644"
print_info "  Scripts: 755"
print_info "  .env files: 600"

print_warning "Important:"
print_warning "1. Change default passwords in .env files"
print_warning "2. Update JWT_SECRET in production"
print_warning "3. Configure SSL certificates for HTTPS"
print_warning "4. Set up regular backups"
print_warning "5. Monitor logs for any issues"

print_status "Deployment completed successfully! 🎉"
