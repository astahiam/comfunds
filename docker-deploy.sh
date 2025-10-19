#!/bin/bash

# HajiFund Docker Deployment Script for VPS
# This script automatically deploys the entire HajiFund application using Docker
# Usage: ./docker-deploy.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration Variables
GITHUB_REPO="https://github.com/astahiam/comfunds.git"
APP_DIR="/var/www/hajifund"
DOMAIN_OR_IP="103.103.20.68"
DB_PASSWORD="postgres"
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
ADMIN_EMAIL="admin@hajifund.com"
ADMIN_PASSWORD="admin123"

# Function to print status messages
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Update system packages
update_system() {
    print_step "Updating system packages..."
    
    apt update -y
    apt upgrade -y
    apt install -y curl wget git build-essential software-properties-common
    
    print_status "System packages updated"
}

# Install Docker
install_docker() {
    print_step "Installing Docker..."
    
    # Remove old Docker installations
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install Docker dependencies
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (for non-root usage)
    usermod -aG docker $SUDO_USER 2>/dev/null || true
    
    print_status "Docker installed successfully"
}

# Install Docker Compose (standalone)
install_docker_compose() {
    print_step "Installing Docker Compose..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # Download and install
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Create symlink
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_status "Docker Compose installed successfully"
}

# Clone and setup application
setup_application() {
    print_step "Setting up HajiFund application..."
    
    # Create application directory
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Clone repository
    print_info "Cloning repository from GitHub..."
    git clone $GITHUB_REPO .
    
    print_status "Application code cloned successfully"
}

# Create environment file
create_environment() {
    print_step "Creating environment configuration..."
    
    cat > $APP_DIR/.env << EOF
# Database Configuration
DB_PASSWORD=$DB_PASSWORD

# JWT Configuration
JWT_SECRET=$JWT_SECRET

# Application URLs
FRONTEND_URL=https://$DOMAIN_OR_IP

# Admin Configuration
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# SSL Configuration
SSL_CERT_PATH=/etc/nginx/ssl/hajifund.crt
SSL_KEY_PATH=/etc/nginx/ssl/hajifund.key
EOF
    
    print_status "Environment configuration created"
}

# Create SSL certificates
create_ssl_certificates() {
    print_step "Creating SSL certificates..."
    
    # Create SSL directory
    mkdir -p $APP_DIR/docker/nginx/ssl
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $APP_DIR/docker/nginx/ssl/hajifund.key \
        -out $APP_DIR/docker/nginx/ssl/hajifund.crt \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=HajiFund/CN=$DOMAIN_OR_IP"
    
    print_status "SSL certificates created"
}

# Create Docker override for production
create_docker_override() {
    print_step "Creating Docker Compose override..."
    
    cat > $APP_DIR/docker-compose.override.yml << EOF
version: '3.8'

services:
  postgres:
    environment:
      POSTGRES_PASSWORD: $DB_PASSWORD
    volumes:
      - /var/lib/postgresql/data:/var/lib/postgresql/data

  backend:
    environment:
      DB_PASSWORD: $DB_PASSWORD
      JWT_SECRET: $JWT_SECRET
    volumes:
      - /var/log/hajifund/backend:/app/logs

  frontend:
    environment:
      BACKEND_URL: http://backend:8080
      FRONTEND_URL: https://$DOMAIN_OR_IP
    volumes:
      - /var/log/hajifund/frontend:/app/logs

  nginx:
    volumes:
      - /var/log/hajifund/nginx:/var/log/nginx

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /var/lib/postgresql/data
EOF
    
    print_status "Docker Compose override created"
}

# Create backup script
create_backup_script() {
    print_step "Creating backup script..."
    
    cat > /usr/local/bin/hajifund-docker-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/hajifund"
DATE=$(date +%Y%m%d_%H%M%S)
SHARDS=("hajifund00" "hajifund01" "hajifund02" "hajifund03")

mkdir -p $BACKUP_DIR

# Backup databases
for shard in "${SHARDS[@]}"; do
    echo "Backing up $shard..."
    docker exec hajifund-postgres pg_dump -U hajifund_user $shard > $BACKUP_DIR/${shard}_${DATE}.sql
done

# Backup application data
docker exec hajifund-postgres pg_dumpall -U hajifund_user > $BACKUP_DIR/postgres_all_${DATE}.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Docker backup completed: $DATE"
EOF
    
    chmod +x /usr/local/bin/hajifund-docker-backup.sh
    
    # Add to crontab for daily backups
    echo "0 2 * * * /usr/local/bin/hajifund-docker-backup.sh" | crontab -
    
    print_status "Backup script created and scheduled"
}

# Create monitoring script
create_monitoring_script() {
    print_step "Creating monitoring script..."
    
    cat > /usr/local/bin/hajifund-docker-monitor.sh << 'EOF'
#!/bin/bash

# HajiFund Docker Container Monitoring Script

echo "=== HajiFund Docker Container Status ==="
echo "Date: $(date)"
echo ""

# Check container status
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=hajifund"

echo ""
echo "Container Health:"
docker ps --format "table {{.Names}}\t{{.Status}}" --filter "health=healthy"
docker ps --format "table {{.Names}}\t{{.Status}}" --filter "health=unhealthy"

echo ""
echo "Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

echo ""
echo "Disk Usage:"
docker system df

echo ""
echo "Recent Logs (last 10 lines each):"
echo "--- Backend Logs ---"
docker logs --tail 10 hajifund-backend 2>/dev/null || echo "Backend container not running"

echo "--- Frontend Logs ---"
docker logs --tail 10 hajifund-frontend 2>/dev/null || echo "Frontend container not running"

echo "--- Nginx Logs ---"
docker logs --tail 10 hajifund-nginx 2>/dev/null || echo "Nginx container not running"

echo "--- PostgreSQL Logs ---"
docker logs --tail 10 hajifund-postgres 2>/dev/null || echo "PostgreSQL container not running"
EOF
    
    chmod +x /usr/local/bin/hajifund-docker-monitor.sh
    
    print_status "Monitoring script created"
}

# Deploy application
deploy_application() {
    print_step "Deploying HajiFund application with Docker..."
    
    cd $APP_DIR
    
    # Stop any existing containers
    print_info "Stopping existing containers..."
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # Build and start containers
    print_info "Building and starting containers..."
    docker-compose -f docker-compose.prod.yml up -d --build
    
    # Wait for services to be ready
    print_info "Waiting for services to be ready..."
    sleep 30
    
    # Check container status
    print_info "Checking container status..."
    docker-compose -f docker-compose.prod.yml ps
    
    print_status "Application deployed successfully"
}

# Configure firewall
configure_firewall() {
    print_step "Configuring firewall..."
    
    # Install UFW if not present
    apt install -y ufw
    
    # Configure firewall rules
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    print_status "Firewall configured"
}

# Verify deployment
verify_deployment() {
    print_step "Verifying deployment..."
    
    # Wait for services to be fully ready
    sleep 60
    
    # Check container health
    print_info "Checking container health..."
    docker ps --filter "name=hajifund" --format "table {{.Names}}\t{{.Status}}"
    
    # Test HTTP endpoints
    print_info "Testing HTTP endpoints..."
    
    # Test backend health
    if curl -f -s http://localhost:8080/api/v1/health > /dev/null; then
        print_status "Backend API is responding"
    else
        print_warning "Backend API is not responding"
    fi
    
    # Test frontend
    if curl -f -s http://localhost:3000 > /dev/null; then
        print_status "Frontend is responding"
    else
        print_warning "Frontend is not responding"
    fi
    
    # Test nginx
    if curl -f -s -k https://localhost > /dev/null; then
        print_status "Nginx is responding"
    else
        print_warning "Nginx is not responding"
    fi
    
    print_status "Deployment verification completed"
}

# Display final information
display_final_info() {
    print_header "🎉 HajiFund Docker Deployment Completed!"
    
    echo -e "${GREEN}Your HajiFund application is now deployed and running with Docker!${NC}"
    echo ""
    echo -e "${BLUE}Access URLs:${NC}"
    echo -e "  Frontend: ${CYAN}https://$DOMAIN_OR_IP${NC}"
    echo -e "  Backend API: ${CYAN}https://$DOMAIN_OR_IP/api/${NC}"
    echo -e "  Admin Panel: ${CYAN}https://$DOMAIN_OR_IP/admin/${NC}"
    echo ""
    echo -e "${BLUE}Admin Credentials:${NC}"
    echo -e "  Email: ${CYAN}$ADMIN_EMAIL${NC}"
    echo -e "  Password: ${CYAN}$ADMIN_PASSWORD${NC}"
    echo ""
    echo -e "${BLUE}Container Management:${NC}"
    echo -e "  View containers: ${CYAN}docker ps${NC}"
    echo -e "  View logs: ${CYAN}docker logs hajifund-backend${NC}"
    echo -e "  Restart services: ${CYAN}cd $APP_DIR && docker-compose restart${NC}"
    echo -e "  Stop services: ${CYAN}cd $APP_DIR && docker-compose down${NC}"
    echo -e "  Update services: ${CYAN}cd $APP_DIR && docker-compose pull && docker-compose up -d${NC}"
    echo ""
    echo -e "${BLUE}Monitoring:${NC}"
    echo -e "  Container status: ${CYAN}/usr/local/bin/hajifund-docker-monitor.sh${NC}"
    echo -e "  System resources: ${CYAN}docker stats${NC}"
    echo -e "  Container logs: ${CYAN}docker logs -f hajifund-backend${NC}"
    echo ""
    echo -e "${BLUE}Backup:${NC}"
    echo -e "  Manual backup: ${CYAN}/usr/local/bin/hajifund-docker-backup.sh${NC}"
    echo -e "  Backup location: ${CYAN}/var/backups/hajifund/${NC}"
    echo ""
    echo -e "${BLUE}Database Access:${NC}"
    echo -e "  Connect to PostgreSQL: ${CYAN}docker exec -it hajifund-postgres psql -U hajifund_user${NC}"
    echo -e "  Database names: ${CYAN}hajifund00, hajifund01, hajifund02, hajifund03${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Configure domain name and SSL certificate"
    echo -e "  2. Set up monitoring and alerting"
    echo -e "  3. Configure log rotation"
    echo -e "  4. Set up automated backups"
    echo -e "  5. Configure scaling policies"
    echo ""
    echo -e "${GREEN}Docker deployment completed successfully! 🐳🚀${NC}"
}

# Main execution function
main() {
    print_header "🐳 HajiFund Docker VPS Deployment Script"
    
    check_root
    update_system
    install_docker
    install_docker_compose
    setup_application
    create_environment
    create_ssl_certificates
    create_docker_override
    create_backup_script
    create_monitoring_script
    configure_firewall
    deploy_application
    verify_deployment
    display_final_info
}

# Run main function
main "$@"
