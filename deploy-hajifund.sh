#!/bin/bash

# HajiFund Complete Deployment Script for VPS
# This script automatically deploys the entire HajiFund application from GitHub
# Usage: ./deploy-hajifund.sh

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
GITHUB_REPO="https://github.com/astahiam/comfunds.git"  # Change this to your actual GitHub repo
APP_DIR="/var/www/hajifund"
APP_USER="www-data"
DOMAIN_OR_IP="103.103.20.68"  # Change this to your domain if you have one
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

# Install Go
install_go() {
    print_step "Installing Go..."
    
    # Remove existing Go installation
    rm -rf /usr/local/go
    
    # Download and install Go 1.21.5
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm go1.21.5.linux-amd64.tar.gz
    
    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/environment
    echo 'export GOPATH=/var/www/go' >> /etc/environment
    echo 'export GOBIN=$GOPATH/bin' >> /etc/environment
    
    # Create Go workspace
    mkdir -p /var/www/go
    
    print_status "Go installed successfully"
}

# Install PostgreSQL
install_postgresql() {
    print_step "Installing PostgreSQL..."
    
    apt install -y postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Configure PostgreSQL
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DB_PASSWORD';"
    sudo -u postgres psql -c "CREATE USER hajifund_user WITH PASSWORD '$DB_PASSWORD';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE postgres TO hajifund_user;"
    
    # Create sharded databases
    sudo -u postgres createdb hajifund00
    sudo -u postgres createdb hajifund01
    sudo -u postgres createdb hajifund02
    sudo -u postgres createdb hajifund03
    
    # Grant permissions
    for shard in hajifund00 hajifund01 hajifund02 hajifund03; do
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $shard TO hajifund_user;"
    done
    
    # Configure PostgreSQL for remote connections
    echo "listen_addresses = '*'" >> /etc/postgresql/15/main/postgresql.conf
    echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/15/main/pg_hba.conf
    
    systemctl restart postgresql
    
    print_status "PostgreSQL installed and configured"
}

# Install Nginx
install_nginx() {
    print_step "Installing Nginx..."
    
    apt install -y nginx
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/hajifund << EOF
server {
    listen 80;
    server_name $DOMAIN_OR_IP;
    
    # Frontend (GoFiber) - Port 3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Backend API (Go/Gin) - Port 8080
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Static files
    location /static/ {
        alias $APP_DIR/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and start Nginx
    nginx -t
    systemctl start nginx
    systemctl enable nginx
    
    print_status "Nginx installed and configured"
}

# Install Node.js (for potential frontend build tools)
install_nodejs() {
    print_step "Installing Node.js..."
    
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    print_status "Node.js installed"
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
    
    # Set ownership
    chown -R $APP_USER:$APP_USER $APP_DIR
    
    # Install Go dependencies
    print_info "Installing Go dependencies..."
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/var/www/go
    
    # Backend dependencies
    go mod tidy
    
    # Frontend dependencies
    cd frontend
    go mod tidy
    cd ..
    
    print_status "Application setup completed"
}

# Configure environment variables
configure_environment() {
    print_step "Configuring environment variables..."
    
    # Backend environment
    cat > $APP_DIR/.env << EOF
DB_HOST=localhost
DB_PORT=5432
DB_USER=hajifund_user
DB_PASSWORD=$DB_PASSWORD
DB_SSLMODE=disable
JWT_SECRET=$JWT_SECRET
PORT=8080
ENVIRONMENT=production
EOF
    
    # Frontend environment
    cat > $APP_DIR/frontend/.env << EOF
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://$DOMAIN_OR_IP
PORT=3000
ENVIRONMENT=production
EOF
    
    # Set ownership
    chown $APP_USER:$APP_USER $APP_DIR/.env
    chown $APP_USER:$APP_USER $APP_DIR/frontend/.env
    
    print_status "Environment variables configured"
}

# Initialize database
initialize_database() {
    print_step "Initializing database..."
    
    # Wait for PostgreSQL to be ready
    sleep 5
    
    # Initialize each shard with schema
    for shard in hajifund00 hajifund01 hajifund02 hajifund03; do
        print_info "Initializing $shard..."
        
        # Use the init scripts if they exist
        if [[ -f "$APP_DIR/docker/postgres/init-${shard}.sql" ]]; then
            sudo -u postgres psql -d $shard -f "$APP_DIR/docker/postgres/init-${shard}.sql"
        else
            # Create basic tables if init scripts don't exist
            sudo -u postgres psql -d $shard << 'EOF'
-- Create basic tables structure
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    roles TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_amount DECIMAL(15,2),
    raised_amount DECIMAL(15,2) DEFAULT 0,
    min_investment DECIMAL(15,2),
    project_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft',
    approval_status VARCHAR(20) DEFAULT 'pending',
    risk_level VARCHAR(20),
    investment_period INTEGER,
    expected_return VARCHAR(50),
    business_id UUID REFERENCES businesses(id),
    owner_id UUID REFERENCES users(id),
    cooperative_id UUID,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_by UUID REFERENCES users(id),
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    reviewer_comments TEXT,
    sharia_compliant BOOLEAN DEFAULT FALSE,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investor_id UUID REFERENCES users(id),
    project_id UUID REFERENCES projects(id),
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'IDR',
    investment_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cooperatives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    bank_account VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_approval_status ON projects(approval_status);
CREATE INDEX IF NOT EXISTS idx_investments_investor_id ON investments(investor_id);
CREATE INDEX IF NOT EXISTS idx_investments_project_id ON investments(project_id);

-- Create admin user
INSERT INTO users (email, name, password_hash, roles) 
VALUES ('$ADMIN_EMAIL', 'Admin', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', ARRAY['admin', 'member'])
ON CONFLICT (email) DO NOTHING;
EOF
        fi
        
        print_status "$shard initialized"
    done
    
    print_status "Database initialization completed"
}

# Create systemd services
create_systemd_services() {
    print_step "Creating systemd services..."
    
    # Backend service
    cat > /etc/systemd/system/hajifund-backend.service << EOF
[Unit]
Description=HajiFund Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
Environment=GOPATH=/var/www/go
ExecStart=/usr/local/go/bin/go run main.go
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hajifund-backend

[Install]
WantedBy=multi-user.target
EOF
    
    # Frontend service
    cat > /etc/systemd/system/hajifund-frontend.service << EOF
[Unit]
Description=HajiFund Frontend
After=network.target hajifund-backend.service
Requires=hajifund-backend.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR/frontend
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
Environment=GOPATH=/var/www/go
ExecStart=/usr/local/go/bin/go run main.go
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hajifund-frontend

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable services
    systemctl daemon-reload
    systemctl enable hajifund-backend
    systemctl enable hajifund-frontend
    
    print_status "Systemd services created and enabled"
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

# Start services
start_services() {
    print_step "Starting services..."
    
    # Start services
    systemctl start hajifund-backend
    sleep 5
    systemctl start hajifund-frontend
    
    # Check service status
    print_info "Checking service status..."
    systemctl status hajifund-backend --no-pager -l
    systemctl status hajifund-frontend --no-pager -l
    
    print_status "Services started"
}

# Install SSL certificate (optional)
install_ssl() {
    print_step "Installing SSL certificate..."
    
    # Install Certbot
    apt install -y certbot python3-certbot-nginx
    
    # Create self-signed certificate for now
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/hajifund.key \
        -out /etc/ssl/certs/hajifund.crt \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=HajiFund/CN=$DOMAIN_OR_IP"
    
    # Update Nginx configuration for HTTPS
    cat > /etc/nginx/sites-available/hajifund << EOF
server {
    listen 80;
    server_name $DOMAIN_OR_IP;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_OR_IP;
    
    ssl_certificate /etc/ssl/certs/hajifund.crt;
    ssl_certificate_key /etc/ssl/private/hajifund.key;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Frontend (GoFiber) - Port 3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Backend API (Go/Gin) - Port 8080
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Static files
    location /static/ {
        alias $APP_DIR/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Test and restart Nginx
    nginx -t
    systemctl restart nginx
    
    print_status "SSL certificate installed"
}

# Create backup script
create_backup_script() {
    print_step "Creating backup script..."
    
    cat > /usr/local/bin/hajifund-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/hajifund"
DATE=$(date +%Y%m%d_%H%M%S)
SHARDS=("hajifund00" "hajifund01" "hajifund02" "hajifund03")

mkdir -p $BACKUP_DIR

for shard in "${SHARDS[@]}"; do
    echo "Backing up $shard..."
    sudo -u postgres pg_dump $shard > $BACKUP_DIR/${shard}_${DATE}.sql
done

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF
    
    chmod +x /usr/local/bin/hajifund-backup.sh
    
    # Add to crontab for daily backups
    echo "0 2 * * * /usr/local/bin/hajifund-backup.sh" | crontab -
    
    print_status "Backup script created and scheduled"
}

# Final verification
verify_deployment() {
    print_step "Verifying deployment..."
    
    # Check if services are running
    if systemctl is-active --quiet hajifund-backend; then
        print_status "Backend service is running"
    else
        print_error "Backend service is not running"
    fi
    
    if systemctl is-active --quiet hajifund-frontend; then
        print_status "Frontend service is running"
    else
        print_error "Frontend service is not running"
    fi
    
    if systemctl is-active --quiet nginx; then
        print_status "Nginx is running"
    else
        print_error "Nginx is not running"
    fi
    
    if systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL is running"
    else
        print_error "PostgreSQL is not running"
    fi
    
    # Test HTTP endpoints
    sleep 10
    
    if curl -f -s http://localhost:8080/api/v1/health > /dev/null; then
        print_status "Backend API is responding"
    else
        print_warning "Backend API is not responding"
    fi
    
    if curl -f -s http://localhost:3000 > /dev/null; then
        print_status "Frontend is responding"
    else
        print_warning "Frontend is not responding"
    fi
    
    print_status "Deployment verification completed"
}

# Display final information
display_final_info() {
    print_header "🎉 HajiFund Deployment Completed!"
    
    echo -e "${GREEN}Your HajiFund application is now deployed and running!${NC}"
    echo ""
    echo -e "${BLUE}Access URLs:${NC}"
    echo -e "  Frontend: ${CYAN}http://$DOMAIN_OR_IP${NC} or ${CYAN}https://$DOMAIN_OR_IP${NC}"
    echo -e "  Backend API: ${CYAN}http://$DOMAIN_OR_IP/api/${NC} or ${CYAN}https://$DOMAIN_OR_IP/api/${NC}"
    echo -e "  Admin Panel: ${CYAN}http://$DOMAIN_OR_IP/admin/${NC} or ${CYAN}https://$DOMAIN_OR_IP/admin/${NC}"
    echo ""
    echo -e "${BLUE}Admin Credentials:${NC}"
    echo -e "  Email: ${CYAN}$ADMIN_EMAIL${NC}"
    echo -e "  Password: ${CYAN}$ADMIN_PASSWORD${NC}"
    echo ""
    echo -e "${BLUE}Database Information:${NC}"
    echo -e "  Host: ${CYAN}localhost${NC}"
    echo -e "  Port: ${CYAN}5432${NC}"
    echo -e "  User: ${CYAN}hajifund_user${NC}"
    echo -e "  Password: ${CYAN}$DB_PASSWORD${NC}"
    echo -e "  Databases: ${CYAN}hajifund00, hajifund01, hajifund02, hajifund03${NC}"
    echo ""
    echo -e "${BLUE}Service Management:${NC}"
    echo -e "  Backend: ${CYAN}systemctl status hajifund-backend${NC}"
    echo -e "  Frontend: ${CYAN}systemctl status hajifund-frontend${NC}"
    echo -e "  Nginx: ${CYAN}systemctl status nginx${NC}"
    echo -e "  PostgreSQL: ${CYAN}systemctl status postgresql${NC}"
    echo ""
    echo -e "${BLUE}Logs:${NC}"
    echo -e "  Backend: ${CYAN}journalctl -u hajifund-backend -f${NC}"
    echo -e "  Frontend: ${CYAN}journalctl -u hajifund-frontend -f${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Update DNS records to point to this server (if using domain)"
    echo -e "  2. Configure Let's Encrypt SSL certificate for production"
    echo -e "  3. Set up monitoring and alerting"
    echo -e "  4. Configure backup retention policies"
    echo ""
    echo -e "${GREEN}Deployment completed successfully! 🚀${NC}"
}

# Main execution function
main() {
    print_header "🚀 HajiFund VPS Deployment Script"
    
    check_root
    update_system
    install_go
    install_postgresql
    install_nginx
    install_nodejs
    setup_application
    configure_environment
    initialize_database
    create_systemd_services
    configure_firewall
    start_services
    install_ssl
    create_backup_script
    verify_deployment
    display_final_info
}

# Run main function
main "$@"
