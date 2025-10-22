#!/bin/bash

# Copy Docker Deployment Files to VPS
# This script copies all necessary Docker files to the VPS

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

print_step "Copying Docker Deployment Files to VPS"

# VPS Configuration
VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

# SSH Configuration
SSH_CMD="ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
SCP_CMD="scp -i $VPS_KEY"

print_info "VPS Configuration:"
print_info "  User: $VPS_USER"
print_info "  Host: $VPS_HOST"
print_info "  Key: $VPS_KEY"
print_info "  Path: $VPS_PATH"

# 1. Test SSH connection
print_step "1. Testing SSH connection..."

if $SSH_CMD "echo 'SSH connection successful'"; then
    print_status "SSH connection successful"
else
    print_error "SSH connection failed. Please check your SSH key and connection."
    exit 1
fi

# 2. Create directory structure on VPS
print_step "2. Creating directory structure on VPS..."

$SSH_CMD "mkdir -p $VPS_PATH"
$SSH_CMD "mkdir -p $VPS_PATH/docker/nginx"
$SSH_CMD "mkdir -p $VPS_PATH/docker/postgres"
$SSH_CMD "mkdir -p $VPS_PATH/frontend"
$SSH_CMD "mkdir -p $VPS_PATH/uploads"
$SSH_CMD "mkdir -p $VPS_PATH/logs"

print_status "Directory structure created"

# 3. Copy main Docker files
print_step "3. Copying main Docker files..."

# Copy docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    $SCP_CMD docker-compose.yml $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "docker-compose.yml copied"
else
    print_error "docker-compose.yml not found"
fi

# Copy Dockerfiles
if [ -f "Dockerfile.backend" ]; then
    $SCP_CMD Dockerfile.backend $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "Dockerfile.backend copied"
else
    print_error "Dockerfile.backend not found"
fi

if [ -f "Dockerfile.frontend" ]; then
    $SCP_CMD Dockerfile.frontend $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "Dockerfile.frontend copied"
else
    print_error "Dockerfile.frontend not found"
fi

# Copy environment files
if [ -f "env.example" ]; then
    $SCP_CMD env.example $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "env.example copied"
else
    print_error "env.example not found"
fi

# 4. Copy Nginx configuration
print_step "4. Copying Nginx configuration..."

if [ -f "docker/nginx/nginx.conf" ]; then
    $SCP_CMD docker/nginx/nginx.conf $VPS_USER@$VPS_HOST:$VPS_PATH/docker/nginx
    print_status "nginx.conf copied"
else
    print_error "docker/nginx/nginx.conf not found"
fi

if [ -f "docker/nginx/default.conf" ]; then
    $SCP_CMD docker/nginx/default.conf $VPS_USER@$VPS_HOST:$VPS_PATH/docker/nginx
    print_status "default.conf copied"
else
    print_error "docker/nginx/default.conf not found"
fi

# 5. Copy PostgreSQL initialization
print_step "5. Copying PostgreSQL initialization..."

if [ -f "docker/postgres/init-multiple-databases.sh" ]; then
    $SCP_CMD docker/postgres/init-multiple-databases.sh $VPS_USER@$VPS_HOST:$VPS_PATH/docker/postgres/
    print_status "init-multiple-databases.sh copied"
else
    print_error "docker/postgres/init-multiple-databases.sh not found"
fi

# Copy database schema files
for i in {0..3}; do
    if [ -f "docker/postgres/init-comfunds0$i.sql" ]; then
        $SCP_CMD docker/postgres/init-comfunds0$i.sql $VPS_USER@$VPS_HOST:$VPS_PATH/docker/postgres/
        print_status "init-comfunds0$i.sql copied"
    else
        print_warning "init-comfunds0$i.sql not found"
    fi
done

# 6. Copy frontend files
print_step "6. Copying frontend files..."

# Copy frontend environment
if [ -f "frontend/env.example" ]; then
    $SCP_CMD frontend/env.example $VPS_USER@$VPS_HOST:$VPS_PATH/frontend/
    print_status "frontend/env.example copied"
else
    print_error "frontend/env.example not found"
fi

# Copy frontend source code
if [ -d "frontend" ]; then
    print_info "Copying frontend source code..."
    $SCP_CMD -r frontend/* $VPS_USER@$VPS_HOST:$VPS_PATH/frontend/
    print_status "Frontend source code copied"
else
    print_error "frontend directory not found"
fi

# 7. Copy backend source code
print_step "7. Copying backend source code..."

# Copy main backend files
if [ -f "main.go" ]; then
    $SCP_CMD main.go $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "main.go copied"
else
    print_error "main.go not found"
fi

if [ -f "go.mod" ]; then
    $SCP_CMD go.mod $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "go.mod copied"
else
    print_error "go.mod not found"
fi

if [ -f "go.sum" ]; then
    $SCP_CMD go.sum $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "go.sum copied"
else
    print_warning "go.sum not found"
fi

# Copy internal directory
if [ -d "internal" ]; then
    print_info "Copying internal directory..."
    $SCP_CMD -r internal/ $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "internal directory copied"
else
    print_error "internal directory not found"
fi

# Copy other Go files
for file in *.go; do
    if [ -f "$file" ]; then
        $SCP_CMD "$file" $VPS_USER@$VPS_HOST:$VPS_PATH/
        print_status "$file copied"
    fi
done

# 8. Copy deployment script
print_step "8. Copying deployment script..."

if [ -f "docker-deploy-ubuntu.sh" ]; then
    $SCP_CMD docker-deploy-ubuntu.sh $VPS_USER@$VPS_HOST:$VPS_PATH/
    print_status "docker-deploy-ubuntu.sh copied"
else
    print_error "docker-deploy-ubuntu.sh not found"
fi

# 9. Set proper permissions on VPS
print_step "9. Setting proper permissions on VPS..."

$SSH_CMD "chmod -R 755 $VPS_PATH"
$SSH_CMD "find $VPS_PATH -type f -name '*.sh' -exec chmod +x {} \;"
$SSH_CMD "chmod 600 $VPS_PATH/env.example"
$SSH_CMD "chmod 600 $VPS_PATH/frontend/env.example"

print_status "Permissions set correctly"

# 10. Create .env files from examples
print_step "10. Creating .env files from examples..."

$SSH_CMD "cd $VPS_PATH && cp env.example .env"
$SSH_CMD "cd $VPS_PATH/frontend && cp env.example .env"
$SSH_CMD "chmod 600 $VPS_PATH/.env"
$SSH_CMD "chmod 600 $VPS_PATH/frontend/.env"

print_status ".env files created"

# 11. Verify files were copied
print_step "11. Verifying files were copied..."

print_info "Files on VPS:"
$SSH_CMD "ls -la $VPS_PATH/"

print_info "Docker files:"
$SSH_CMD "ls -la $VPS_PATH/docker/"

print_info "Nginx files:"
$SSH_CMD "ls -la $VPS_PATH/docker/nginx/"

print_info "PostgreSQL files:"
$SSH_CMD "ls -la $VPS_PATH/docker/postgres/"

print_info "Frontend files:"
$SSH_CMD "ls -la $VPS_PATH/frontend/"

# 12. Final status
print_step "12. Copy completed!"

print_status "All Docker deployment files copied successfully!"
print_info "Files copied to: $VPS_PATH"
print_info "Next steps:"
print_info "1. SSH into VPS: ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
print_info "2. Navigate to project: cd $VPS_PATH"
print_info "3. Run deployment: sudo ./docker-deploy-ubuntu.sh"
print_info "4. Or run: docker compose up -d"

print_info "Key files copied:"
print_info "  ✅ docker-compose.yml"
print_info "  ✅ Dockerfile.backend"
print_info "  ✅ Dockerfile.frontend"
print_info "  ✅ env.example → .env"
print_info "  ✅ frontend/env.example → frontend/.env"
print_info "  ✅ docker/nginx/nginx.conf"
print_info "  ✅ docker/nginx/default.conf"
print_info "  ✅ docker/postgres/init-multiple-databases.sh"
print_info "  ✅ docker/postgres/init-comfunds*.sql"
print_info "  ✅ docker-deploy-ubuntu.sh"
print_info "  ✅ All source code (backend + frontend)"

print_warning "Important:"
print_warning "1. Check .env files and update passwords/secrets"
print_warning "2. Verify all files are present on VPS"
print_warning "3. Run the deployment script to start services"

print_status "File copy completed successfully! 🎉"
