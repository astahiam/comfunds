#!/bin/bash

# HajiFund VPS Production Deployment Script
# This script deploys the HajiFund application on a VPS server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN_NAME="${DOMAIN_NAME:-your-domain.com}"
EMAIL="${EMAIL:-admin@your-domain.com}"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
PROJECT_NAME="comfunds"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    apt update && apt upgrade -y
    log_success "System updated"
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker is already installed"
        return
    fi

    log_info "Installing Docker..."
    
    # Install prerequisites
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    log_success "Docker installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose is already installed"
        return
    fi

    log_info "Installing Docker Compose..."
    
    # Download Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make it executable
    chmod +x /usr/local/bin/docker-compose
    
    # Create symlink
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose installed successfully"
}

# Install Nginx (for reverse proxy)
install_nginx() {
    if command -v nginx &> /dev/null; then
        log_info "Nginx is already installed"
        return
    fi

    log_info "Installing Nginx..."
    apt install -y nginx
    
    # Start and enable Nginx
    systemctl start nginx
    systemctl enable nginx
    
    log_success "Nginx installed successfully"
}

# Install Certbot for SSL
install_certbot() {
    if command -v certbot &> /dev/null; then
        log_info "Certbot is already installed"
        return
    fi

    log_info "Installing Certbot..."
    
    # Install snapd
    apt install -y snapd
    snap install core; snap refresh core
    
    # Install certbot
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    
    log_success "Certbot installed successfully"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    # Install ufw if not present
    apt install -y ufw
    
    # Configure firewall rules
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    log_success "Firewall configured"
}

# Create application directory
create_app_directory() {
    log_info "Creating application directory..."
    
    APP_DIR="/opt/comfunds"
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    log_success "Application directory created at $APP_DIR"
}

# Setup SSL certificates
setup_ssl() {
    if [ "$DOMAIN_NAME" = "your-domain.com" ]; then
        log_warning "Domain name not set. Skipping SSL setup."
        log_warning "Set DOMAIN_NAME environment variable to enable SSL"
        return
    fi

    log_info "Setting up SSL certificates for $DOMAIN_NAME..."
    
    # Stop nginx temporarily
    systemctl stop nginx
    
    # Obtain SSL certificate
    certbot certonly --standalone -d $DOMAIN_NAME -d api.$DOMAIN_NAME --email $EMAIL --agree-tos --non-interactive
    
    # Create nginx configuration
    cat > /etc/nginx/sites-available/comfunds << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME api.$DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name api.$DOMAIN_NAME;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable the site
    ln -sf /etc/nginx/sites-available/comfunds /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    nginx -t
    
    # Start nginx
    systemctl start nginx
    
    # Setup auto-renewal
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
    
    log_success "SSL certificates configured"
}

# Create production environment file
create_production_env() {
    log_info "Creating production environment file..."
    
    # Generate a secure JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    DB_PASSWORD=$(openssl rand -base64 16)
    
    cat > $ENV_FILE << EOF
# HajiFund Production Environment Configuration

# Database Configuration
DB_PASSWORD=$DB_PASSWORD
DB_HOST=postgres-comfunds00
DB_USER=postgres
DB_SSLMODE=disable

# Application Configuration
ENVIRONMENT=production
PORT=8080
JWT_SECRET=$JWT_SECRET

# CORS Configuration
CORS_ORIGINS=https://$DOMAIN_NAME,https://api.$DOMAIN_NAME

# Logging
LOG_LEVEL=info

# Frontend Configuration
API_URL=http://backend:8080

# Domain Configuration
DOMAIN_NAME=$DOMAIN_NAME
FRONTEND_URL=https://$DOMAIN_NAME
BACKEND_URL=https://api.$DOMAIN_NAME
EOF

    log_success "Production environment file created"
}

# Deploy application
deploy_application() {
    log_info "Deploying HajiFund application..."
    
    # Copy application files (assuming they're in the current directory)
    cp -r /root/comfunds/* . 2>/dev/null || {
        log_warning "Application files not found in /root/comfunds"
        log_info "Please copy your application files to this directory"
    }
    
    # Make deploy script executable
    chmod +x docker/deploy.sh
    
    # Deploy using the deploy script
    ./docker/deploy.sh
    
    log_success "Application deployed successfully"
}

# Setup monitoring
setup_monitoring() {
    log_info "Setting up basic monitoring..."
    
    # Create log rotation
    cat > /etc/logrotate.d/comfunds << EOF
/opt/comfunds/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

    # Create systemd service for auto-restart
    cat > /etc/systemd/system/comfunds.service << EOF
[Unit]
Description=HajiFund Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/comfunds
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    # Enable the service
    systemctl enable comfunds.service
    
    log_success "Monitoring and auto-restart configured"
}

# Main deployment function
main() {
    log_info "Starting HajiFund VPS Production Deployment..."
    
    check_root
    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    configure_firewall
    create_app_directory
    setup_ssl
    create_production_env
    deploy_application
    setup_monitoring
    
    log_success "HajiFund VPS deployment completed successfully!"
    log_info "Application URLs:"
    echo "  Frontend: https://$DOMAIN_NAME"
    echo "  Backend API: https://api.$DOMAIN_NAME"
    echo ""
    log_info "Demo Accounts:"
    echo "  Admin: admin@hajifund.com / admin123"
    echo "  Business Owner: demo-business@example.com / Password123!"
    echo "  Investor: frontendtest@example.com / Password123!"
    echo "  Member: member@hajifund.com / password123"
    echo ""
    log_info "To manage the application:"
    echo "  Start: systemctl start comfunds"
    echo "  Stop: systemctl stop comfunds"
    echo "  Status: systemctl status comfunds"
    echo "  Logs: docker-compose logs -f"
}

# Handle script arguments
case "${1:-}" in
    "ssl")
        setup_ssl
        ;;
    "restart")
        systemctl restart comfunds
        log_success "Application restarted"
        ;;
    "status")
        systemctl status comfunds
        docker-compose ps
        ;;
    "logs")
        docker-compose logs -f
        ;;
    *)
        main
        ;;
esac
