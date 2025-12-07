#!/bin/bash

# Complete Docker Deployment Script for AWS Free Tier
# Includes: Database export, Docker build, deployment, and verification
# Usage: ./deploy-complete-aws.sh [aws-host] [aws-user] [ssh-key]

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

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Configuration
AWS_HOST="${1:-${AWS_HOST:-ec2-user@your-aws-instance.compute-1.amazonaws.com}}"
AWS_USER="${AWS_USER:-ec2-user}"
AWS_KEY="${2:-${AWS_KEY:-~/.ssh/aws-key.pem}}"
AWS_PATH="${AWS_PATH:-~/app}"

# Extract host from AWS_HOST if it includes user
if [[ "$AWS_HOST" == *"@"* ]]; then
    AWS_USER=$(echo "$AWS_HOST" | cut -d@ -f1)
    AWS_HOST=$(echo "$AWS_HOST" | cut -d@ -f2)
fi

# Local Database Configuration
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

# Remote Database Configuration
REMOTE_DB_USER="${REMOTE_DB_USER:-postgres}"
REMOTE_DB_PASSWORD="${REMOTE_DB_PASSWORD:-postgres123}"

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

print_header "Complete Docker Deployment to AWS"

print_info "Configuration:"
print_info "  AWS Host: $AWS_USER@$AWS_HOST"
print_info "  AWS Key: $AWS_KEY"
print_info "  AWS Path: $AWS_PATH"
print_info "  Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT"
print_info "  Shards: ${SHARDS[*]}"
echo ""

# Step 1: Verify local database
print_step "Step 1: Verifying local PostgreSQL..."

if [ -n "$LOCAL_DB_PASSWORD" ]; then
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
fi

if ! psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_error "Cannot connect to local PostgreSQL"
    print_info "Please ensure PostgreSQL is running locally"
    exit 1
fi

print_status "Local PostgreSQL connection: OK"

# Check local databases
for shard in "${SHARDS[@]}"; do
    if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        USER_COUNT=$(psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs || echo "0")
        print_info "  $shard: ✅ ($USER_COUNT users)"
    else
        print_warning "  $shard: ❌ (not found)"
    fi
done

# Step 2: Export local databases
print_header "Step 2: Exporting Local Databases"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_DIR="./db-export-${TIMESTAMP}"
mkdir -p "$DUMP_DIR"

for shard in "${SHARDS[@]}"; do
    print_step "Exporting $shard..."
    
    if ! psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_warning "Local database $shard does not exist, skipping..."
        continue
    fi
    
    # Export complete database
    pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
        --no-password \
        --clean \
        --if-exists \
        --create \
        --format=plain \
        --file="$DUMP_DIR/${shard}_complete.sql" \
        "$shard" 2>&1 | grep -v "WARNING" || true
    
    FILE_SIZE=$(du -h "$DUMP_DIR/${shard}_complete.sql" | cut -f1)
    print_status "Exported $shard ($FILE_SIZE)"
done

print_status "Databases exported to $DUMP_DIR"

# Step 3: Prepare deployment package
print_header "Step 3: Preparing Deployment Package"

DEPLOY_DIR="./deploy-package-${TIMESTAMP}"
mkdir -p "$DEPLOY_DIR"

print_step "Copying application files..."

# Copy essential files
cp -r docker-compose.yml "$DEPLOY_DIR/"
cp -r Dockerfile.backend "$DEPLOY_DIR/"
cp -r Dockerfile.frontend "$DEPLOY_DIR/" 2>/dev/null || cp -r frontend/Dockerfile.frontend "$DEPLOY_DIR/Dockerfile.frontend" 2>/dev/null || true
cp -r docker "$DEPLOY_DIR/" 2>/dev/null || true
cp -r .dockerignore "$DEPLOY_DIR/" 2>/dev/null || true

# Copy source code
print_step "Copying source code..."
mkdir -p "$DEPLOY_DIR/backend"
cp -r internal "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp -r cmd "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp -r main.go "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp -r go.mod "$DEPLOY_DIR/backend/" 2>/dev/null || true
cp -r go.sum "$DEPLOY_DIR/backend/" 2>/dev/null || true

mkdir -p "$DEPLOY_DIR/frontend"
cp -r frontend/* "$DEPLOY_DIR/frontend/" 2>/dev/null || true

# Copy database dumps
print_step "Copying database dumps..."
cp -r "$DUMP_DIR" "$DEPLOY_DIR/db-dumps"

# Create deployment script
print_step "Creating deployment script..."

cat > "$DEPLOY_DIR/deploy.sh" << 'DEPLOYSCRIPT'
#!/bin/bash

# Deployment script to run on AWS instance

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

APP_DIR="${APP_DIR:-~/app}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres123}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

cd "$APP_DIR" || exit 1

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not installed"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose not found"
    exit 1
fi

print_step "Stopping existing containers..."
$COMPOSE_CMD down 2>/dev/null || true

print_step "Building Docker images..."
$COMPOSE_CMD build --no-cache 2>&1 | tail -20 || {
    print_error "Build failed, trying individual builds..."
    docker build -f Dockerfile.backend -t sourcecode-backend . || true
    docker build -f frontend/Dockerfile.frontend -t sourcecode-frontend ./frontend || true
}

print_step "Starting PostgreSQL..."
$COMPOSE_CMD up -d postgres
sleep 10

# Wait for PostgreSQL
print_step "Waiting for PostgreSQL..."
for i in {1..30}; do
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")
    if [ -n "$CONTAINER_NAME" ]; then
        if docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
            print_status "PostgreSQL is ready"
            break
        fi
    fi
    if [ $i -eq 30 ]; then
        print_error "PostgreSQL failed to start"
        exit 1
    fi
    sleep 2
done

# Import databases
print_step "Importing databases..."
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")

if [ -n "$CONTAINER_NAME" ] && [ -d "db-dumps" ]; then
    for shard in "${SHARDS[@]}"; do
        if [ -f "db-dumps/${shard}_complete.sql" ]; then
            print_step "Importing $shard..."
            
            # Create database if needed
            docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -c "CREATE DATABASE $shard;" 2>&1 | grep -v "already exists" || true
            
            # Import data
            cat "db-dumps/${shard}_complete.sql" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" 2>&1 | \
                grep -vE "(does not exist|already exists|WARNING|NOTICE)" || true
            
            print_status "Imported $shard"
        fi
    done
fi

# Start all services
print_step "Starting all services..."
$COMPOSE_CMD up -d

print_step "Waiting for services to start..."
sleep 15

# Health checks
print_step "Checking service health..."

# Check PostgreSQL
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")
if [ -n "$CONTAINER_NAME" ]; then
    if docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "PostgreSQL: OK"
    else
        print_error "PostgreSQL: FAILED"
    fi
fi

# Check Backend
if curl -f -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
    print_status "Backend: OK"
else
    print_error "Backend: FAILED"
    docker logs $(docker ps -q -f name=backend) --tail=20 2>&1 || true
fi

# Check Frontend
if curl -f -s http://localhost:3000 >/dev/null 2>&1; then
    print_status "Frontend: OK"
else
    print_error "Frontend: FAILED"
fi

print_status "Deployment completed!"
print_info "Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|backend|frontend|postgres|redis)" || true

DEPLOYSCRIPT

chmod +x "$DEPLOY_DIR/deploy.sh"

# Create AWS setup script
cat > "$DEPLOY_DIR/aws-setup.sh" << 'AWSSETUP'
#!/bin/bash

# AWS EC2 Setup Script
# Run this on a fresh AWS EC2 instance

set -e

print_step() {
    echo -e "\033[0;34m🔄 $1\033[0m"
}

print_status() {
    echo -e "\033[0;32m✅ $1\033[0m"
}

print_step "Installing Docker..."

# Update system
sudo yum update -y || sudo apt-get update -y

# Install Docker
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
elif command -v apt-get &> /dev/null; then
    # Ubuntu
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
fi

# Install Docker Compose
print_step "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Or use Docker Compose plugin
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

print_status "Docker installed"
print_info "You may need to log out and log back in for group changes to take effect"

AWSSETUP

chmod +x "$DEPLOY_DIR/aws-setup.sh"

print_status "Deployment package created: $DEPLOY_DIR"

# Step 4: Upload to AWS
print_header "Step 4: Uploading to AWS"

print_step "Creating app directory on AWS..."
ssh -i "$AWS_KEY" "$AWS_USER@$AWS_HOST" "mkdir -p $AWS_PATH" 2>&1 || {
    print_error "Cannot connect to AWS instance"
    print_info "Please check:"
    print_info "  1. AWS instance is running"
    print_info "  2. Security group allows SSH (port 22)"
    print_info "  3. SSH key path is correct: $AWS_KEY"
    exit 1
}

print_step "Uploading deployment package..."
# Create tar archive for faster upload
tar czf "$DEPLOY_DIR.tar.gz" -C "$DEPLOY_DIR" .
scp -i "$AWS_KEY" "$DEPLOY_DIR.tar.gz" "$AWS_USER@$AWS_HOST:$AWS_PATH/"

print_step "Extracting on AWS..."
ssh -i "$AWS_KEY" "$AWS_USER@$AWS_HOST" "cd $AWS_PATH && tar xzf $DEPLOY_DIR.tar.gz && rm $DEPLOY_DIR.tar.gz"

print_status "Files uploaded to AWS"

# Step 5: Setup AWS instance (if needed)
print_header "Step 5: Setting up AWS Instance"

print_step "Checking Docker installation..."
DOCKER_INSTALLED=$(ssh -i "$AWS_KEY" "$AWS_USER@$AWS_HOST" "command -v docker" 2>/dev/null || echo "")

if [ -z "$DOCKER_INSTALLED" ]; then
    print_warning "Docker not found, installing..."
    scp -i "$AWS_KEY" "$DEPLOY_DIR/aws-setup.sh" "$AWS_USER@$AWS_HOST:$AWS_PATH/"
    ssh -i "$AWS_KEY" "$AWS_USER@$AWS_HOST" "cd $AWS_PATH && chmod +x aws-setup.sh && ./aws-setup.sh"
    print_info "Docker installed. You may need to reconnect SSH for group changes."
else
    print_status "Docker already installed"
fi

# Step 6: Deploy on AWS
print_header "Step 6: Deploying on AWS"

print_step "Running deployment script..."
ssh -i "$AWS_KEY" "$AWS_USER@$AWS_HOST" "cd $AWS_PATH && chmod +x deploy.sh && ./deploy.sh"

print_status "Deployment completed!"

# Step 7: Verify deployment
print_header "Step 7: Verifying Deployment"

print_step "Checking services..."
ssh -i "$AWS_KEY" "$AWS_USER@$AWS_HOST" "cd $AWS_PATH && docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

print_info "Access your application:"
print_info "  Backend: http://$AWS_HOST:8080"
print_info "  Frontend: http://$AWS_HOST:3000"
print_info ""
print_info "Note: Make sure AWS Security Groups allow:"
print_info "  - Port 22 (SSH)"
print_info "  - Port 3000 (Frontend)"
print_info "  - Port 8080 (Backend)"
print_info "  - Port 5432 (PostgreSQL - optional, for direct access)"

print_status "✅ Complete deployment finished!"
print_info "Deployment package saved in: $DEPLOY_DIR"
print_info "You can delete it after verifying the deployment"

