#!/bin/bash

# HajiFund Complete Docker Deployment Script
# This script deploys the entire HajiFund application with Docker
# Includes: Backend (Gin), Frontend (Fiber), PostgreSQL (Sharded), Redis, Nginx, HTTPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_IP="103.103.20.68"
VPS_USER="ryankharisma"
VPS_SSH_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"
PROJECT_NAME="hajifund"

# Helper functions
print_step() {
    echo -e "${BLUE}==> $1${NC}"
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_step "Starting HajiFund Docker Deployment"

# 1. Update system and install Docker
print_step "1. Updating system and installing Docker..."

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

print_status "Docker installed successfully"

# 2. Install additional tools
print_step "2. Installing additional tools..."

sudo apt install -y wget curl git ufw certbot python3-certbot-nginx

print_status "Additional tools installed"

# 3. Create project directory
print_step "3. Setting up project directory..."

mkdir -p $VPS_PATH
cd $VPS_PATH

print_status "Project directory created: $VPS_PATH"

# 4. Copy project files
print_step "4. Copying project files..."

# Note: This assumes the script is run from the prepare-docker directory
# Copy all necessary files
cp docker-compose.yml $VPS_PATH/
cp backend.env $VPS_PATH/.env
cp frontend.env $VPS_PATH/frontend/.env
cp -r docker/ $VPS_PATH/
cp -r ../backend/ $VPS_PATH/
cp -r ../frontend/ $VPS_PATH/

print_status "Project files copied"

# 5. Set up file permissions
print_step "5. Setting up file permissions..."

sudo chown -R $USER:$USER $VPS_PATH
chmod -R 755 $VPS_PATH
chmod 600 $VPS_PATH/.env
chmod 600 $VPS_PATH/frontend/.env
chmod +x $VPS_PATH/docker/postgres/init-multiple-databases.sh

print_status "File permissions set"

# 6. Configure firewall
print_step "6. Configuring firewall..."

sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000
sudo ufw allow 8080

print_status "Firewall configured"

# 7. Create SSL certificates
print_step "7. Setting up SSL certificates..."

# Create directories for SSL
sudo mkdir -p /etc/letsencrypt/live/$VPS_IP
sudo mkdir -p /var/www/certbot

# Generate self-signed certificate for initial setup
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/letsencrypt/live/$VPS_IP/privkey.pem \
    -out /etc/letsencrypt/live/$VPS_IP/fullchain.pem \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=HajiFund/CN=$VPS_IP"

# Copy certificate to Docker volume
sudo mkdir -p $VPS_PATH/docker/nginx/ssl
sudo cp /etc/letsencrypt/live/$VPS_IP/*.pem $VPS_PATH/docker/nginx/ssl/

print_status "SSL certificates created"

# 8. Build and start services
print_step "8. Building and starting Docker services..."

cd $VPS_PATH

# Build images
docker compose build --no-cache

# Start services
docker compose up -d

print_status "Docker services started"

# 9. Wait for services to be ready
print_step "9. Waiting for services to be ready..."

sleep 30

# Check service health
print_info "Checking service health..."

# Check PostgreSQL
if docker compose exec postgres pg_isready -U postgres; then
    print_status "PostgreSQL is ready"
else
    print_error "PostgreSQL is not ready"
fi

# Check Redis
if docker compose exec redis redis-cli ping; then
    print_status "Redis is ready"
else
    print_error "Redis is not ready"
fi

# Check Backend
if curl -f http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is ready"
else
    print_warning "Backend health check failed, but service might still be starting"
fi

# Check Frontend
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    print_status "Frontend is ready"
else
    print_warning "Frontend health check failed, but service might still be starting"
fi

# Check Nginx
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_status "Nginx is ready"
else
    print_warning "Nginx health check failed, but service might still be starting"
fi

# 10. Create management scripts
print_step "10. Creating management scripts..."

# Create start script
cat > $VPS_PATH/start.sh << 'EOF'
#!/bin/bash
cd ~/sourcecode
docker compose up -d
echo "HajiFund services started"
EOF

# Create stop script
cat > $VPS_PATH/stop.sh << 'EOF'
#!/bin/bash
cd ~/sourcecode
docker compose down
echo "HajiFund services stopped"
EOF

# Create restart script
cat > $VPS_PATH/restart.sh << 'EOF'
#!/bin/bash
cd ~/sourcecode
docker compose down
docker compose up -d
echo "HajiFund services restarted"
EOF

# Create logs script
cat > $VPS_PATH/logs.sh << 'EOF'
#!/bin/bash
cd ~/sourcecode
docker compose logs -f
EOF

# Create backup script
cat > $VPS_PATH/backup.sh << 'EOF'
#!/bin/bash
cd ~/sourcecode
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup databases
for shard in 00 01 02 03; do
    docker compose exec -T postgres pg_dump -U postgres comfunds$shard > $BACKUP_DIR/comfunds$shard.sql
done

# Backup uploads
cp -r uploads $BACKUP_DIR/

echo "Backup created in $BACKUP_DIR"
EOF

# Make scripts executable
chmod +x $VPS_PATH/*.sh

print_status "Management scripts created"

# 11. Final status check
print_step "11. Final status check..."

print_info "Service URLs:"
print_info "  Frontend: http://$VPS_IP"
print_info "  Backend API: http://$VPS_IP/api"
print_info "  Health Check: http://$VPS_IP/health"

print_info "Service Status:"
docker compose ps

print_info "Management Commands:"
print_info "  Start: ./start.sh"
print_info "  Stop: ./stop.sh"
print_info "  Restart: ./restart.sh"
print_info "  Logs: ./logs.sh"
print_info "  Backup: ./backup.sh"

print_status "HajiFund Docker deployment completed successfully!"

print_warning "Important Notes:"
print_warning "1. SSL certificates are self-signed. For production, use Let's Encrypt"
print_warning "2. Change default passwords in production"
print_warning "3. Configure proper firewall rules"
print_warning "4. Set up monitoring and logging"
print_warning "5. Regular backups are recommended"

print_info "To access the application, visit: http://$VPS_IP"
