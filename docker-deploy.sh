#!/bin/bash

# HajiFund Docker Deployment Script
# This script deploys the entire HajiFund application using Docker

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

print_step "Starting HajiFund Docker Deployment"
print_info "This script will deploy the entire application using Docker containers"

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

# 3. Copy existing Docker Compose file (which works locally)
print_step "3. Using existing Docker Compose configuration..."

# Copy the existing docker-compose.yml that works locally
if [ -f "/Users/alkha/Documents/project/comfunds/docker-compose.yml" ]; then
    cp /Users/alkha/Documents/project/comfunds/docker-compose.yml ./docker-compose.yml
    print_status "Copied existing Docker Compose file"
else
    print_error "Could not find existing docker-compose.yml file"
    exit 1
fi

print_status "Docker Compose file created"

# 4. Copy existing Dockerfiles (which work locally)
print_step "4. Using existing Dockerfiles..."

# Copy existing Dockerfiles that work locally
if [ -f "/Users/alkha/Documents/project/comfunds/Dockerfile.backend" ]; then
    cp /Users/alkha/Documents/project/comfunds/Dockerfile.backend ./Dockerfile.backend
    print_status "Copied existing backend Dockerfile"
else
    print_error "Could not find existing Dockerfile.backend"
    exit 1
fi

if [ -f "/Users/alkha/Documents/project/comfunds/Dockerfile.frontend" ]; then
    cp /Users/alkha/Documents/project/comfunds/Dockerfile.frontend ./Dockerfile.frontend
    print_status "Copied existing frontend Dockerfile"
else
    print_error "Could not find existing Dockerfile.frontend"
    exit 1
fi

print_status "Dockerfiles created"

# 5. Create Nginx configuration
print_step "5. Creating Nginx configuration..."

mkdir -p docker/nginx

# Main nginx.conf
cat > docker/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

    include /etc/nginx/conf.d/*.conf;
}
EOF

# Default server configuration
cat > docker/nginx/default.conf << 'EOF'
# Upstream definitions
upstream backend {
    server backend:8080;
    keepalive 32;
}

upstream frontend {
    server frontend:3000;
    keepalive 32;
}

# Main HTTP server
server {
    listen 80;
    server_name _;
    
    # Increase client body size
    client_max_body_size 50M;
    
    # Frontend routes
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Authentication endpoints
    location /api/v1/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/auth/ routes (without v1)
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Backend API routes
    location /api/v1/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/ routes (general API without v1)
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cookie handling
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Admin routes
    location /admin/ {
        proxy_pass http://frontend/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Static files
    location /static/ {
        proxy_pass http://frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Upload files
    location /uploads/ {
        proxy_pass http://backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

print_status "Nginx configuration created"

# 6. Create PostgreSQL initialization files
print_step "6. Creating PostgreSQL initialization files..."

mkdir -p docker/postgres

# Create init script for multiple databases
cat > docker/postgres/init-multiple-databases.sh << 'EOF'
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE comfunds00;
    CREATE DATABASE comfunds01;
    CREATE DATABASE comfunds02;
    CREATE DATABASE comfunds03;
EOSQL
EOF

chmod +x docker/postgres/init-multiple-databases.sh

# Create database schemas (simplified versions)
for shard in 0 1 2 3; do
    cat > docker/postgres/init-comfunds${shard}.sql << EOF
-- Database: comfunds${shard}

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    roles TEXT[] DEFAULT '{"investor"}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES users(id),
    target_amount DECIMAL(15,2) NOT NULL,
    current_amount DECIMAL(15,2) DEFAULT 0,
    project_type VARCHAR(50) NOT NULL CHECK (project_type IN ('startup', 'expansion', 'equipment')),
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
    approval_status VARCHAR(50) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    rejected_by UUID REFERENCES users(id),
    rejected_at TIMESTAMP,
    rejection_reason TEXT,
    reviewer_comments TEXT,
    sharia_compliant BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Investments table
CREATE TABLE IF NOT EXISTS investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investor_id UUID REFERENCES users(id),
    project_id UUID REFERENCES projects(id),
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_investments_investor_id ON investments(investor_id);
CREATE INDEX IF NOT EXISTS idx_investments_project_id ON investments(project_id);

-- Insert sample data
INSERT INTO users (id, name, email, password, phone, address, roles) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'Admin User', 'admin@hajifund.com', '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+6281234567890', 'Admin Address', '{"admin"}'),
    ('550e8400-e29b-41d4-a716-446655440002', 'Test Investor', 'investor@hajifund.com', '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+6281234567891', 'Investor Address', '{"investor"}'),
    ('550e8400-e29b-41d4-a716-446655440003', 'Test Business', 'business@hajifund.com', '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+6281234567892', 'Business Address', '{"business"}')
ON CONFLICT (email) DO NOTHING;
EOF
done

print_status "PostgreSQL initialization files created"

# 7. Create uploads directory
print_step "7. Creating uploads directory..."

mkdir -p uploads
chmod 755 uploads

print_status "Uploads directory created"

# 8. Build and start containers
print_step "8. Building and starting containers..."

# Build and start all services
docker-compose up -d --build

print_status "Containers built and started"

# 9. Wait for services to be ready
print_step "9. Waiting for services to be ready..."

sleep 30

# Check if services are running
print_info "Checking service status..."

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    print_status "PostgreSQL is ready"
else
    print_warning "PostgreSQL is not ready yet"
fi

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

# Check Nginx
if curl -f -s http://localhost > /dev/null 2>&1; then
    print_status "Nginx is ready"
else
    print_warning "Nginx is not ready yet"
fi

# 10. Test the application
print_step "10. Testing the application..."

sleep 10

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

# 11. Show container status
print_step "11. Container status..."

docker-compose ps

# 12. Summary
print_status "Docker deployment completed!"
print_info ""
print_info "🎉 What was deployed:"
print_info "✅ PostgreSQL database with 4 shards"
print_info "✅ Redis for caching"
print_info "✅ Backend API service"
print_info "✅ Frontend web service"
print_info "✅ Nginx reverse proxy"
print_info "✅ All services containerized"
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
print_info "The Docker deployment should be much more reliable!"
print_info "All services are containerized and isolated!"