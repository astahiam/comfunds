# HajiFund Deployment Guide - Biznet GIO VPS

## Server Information
- **VPS Provider**: Biznet GIO
- **IP Address**: 103.103.20.68
- **OS**: Ubuntu 24.04
- **Architecture**: Multi-service deployment with sharded PostgreSQL

## Overview
This guide covers deploying:
1. **Backend API** (Go/Gin framework)
2. **Frontend** (GoFiber framework)
3. **PostgreSQL Sharded Databases** (4 shards)
4. **Reverse Proxy** (Nginx)
5. **SSL Certificate** (Let's Encrypt)

---

## Prerequisites

### 1. Server Access
```bash
# Connect to your VPS
ssh root@103.103.20.68
# or
ssh username@103.103.20.68
```

### 2. Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl wget git build-essential -y
```

---

## Step 1: Install Go

### Install Go 1.21+
```bash
# Download Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz

# Remove old Go installation if exists
sudo rm -rf /usr/local/go

# Extract Go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export GOBIN=$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
go version
```

---

## Step 2: Install PostgreSQL

### Install PostgreSQL 15+
```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL prompt:
ALTER USER postgres PASSWORD 'your_secure_password';
CREATE USER comfunds_user WITH PASSWORD 'comfunds_secure_password';
GRANT ALL PRIVILEGES ON DATABASE postgres TO comfunds_user;
\q
```

### Create Sharded Databases
```bash
# Create databases for each shard
sudo -u postgres createdb comfunds00
sudo -u postgres createdb comfunds01
sudo -u postgres createdb comfunds02
sudo -u postgres createdb comfunds03

# Grant permissions
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds00 TO comfunds_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds01 TO comfunds_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds02 TO comfunds_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds03 TO comfunds_user;"
```

### Configure PostgreSQL
```bash
# Edit PostgreSQL configuration
sudo nano /etc/postgresql/15/main/postgresql.conf

# Update these settings:
listen_addresses = '*'
port = 5432
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB

# Edit pg_hba.conf for authentication
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Add these lines (replace with your IP if needed):
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

---

## Step 3: Install Nginx

### Install Nginx
```bash
sudo apt install nginx -y

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Configure Nginx
```bash
# Create main configuration
sudo nano /etc/nginx/sites-available/hajifund

# Add this configuration:
server {
    listen 80;
    server_name 103.103.20.68;  # Replace with your domain if you have one

    # Frontend (GoFiber) - Port 3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API (Go/Gin) - Port 8080
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /static/ {
        alias /var/www/hajifund/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# Enable the site
sudo ln -s /etc/nginx/sites-available/hajifund /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

---

## Step 4: Deploy Application Code

### Create Application Directory
```bash
# Create application directory
sudo mkdir -p /var/www/hajifund
sudo chown $USER:$USER /var/www/hajifund
cd /var/www/hajifund
```

### Clone/Upload Code
```bash
# Option 1: If you have a Git repository
git clone https://github.com/yourusername/hajifund.git .

# Option 2: Upload via SCP from local machine
# From your local machine:
# scp -r /Users/alkha/Documents/project/comfunds/* root@103.103.20.68:/var/www/hajifund/
```

### Set Up Environment Variables
```bash
# Create environment file for backend
nano /var/www/hajifund/.env

# Add these variables:
DB_HOST=localhost
DB_PORT=5432
DB_USER=comfunds_user
DB_PASSWORD=comfunds_password
DB_SSLMODE=disable
JWT_SECRET=your-super-secret-jwt-key-change-in-production
PORT=8080
ENVIRONMENT=production

# Create environment file for frontend
nano /var/www/hajifund/frontend/.env

# Add these variables:
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production
```

### Install Dependencies
```bash
cd /var/www/hajifund

# Install Go modules for backend
go mod tidy

# Install Go modules for frontend
cd frontend
go mod tidy
cd ..
```

---

## Step 5: Initialize Database Schema

### Run Database Migrations
```bash
# Create database schemas using the init scripts
cd /var/www/hajifund

# Initialize each shard
sudo -u postgres psql -d comfunds00 -f docker/postgres/init-comfunds00.sql
sudo -u postgres psql -d comfunds01 -f docker/postgres/init-comfunds01.sql
sudo -u postgres psql -d comfunds02 -f docker/postgres/init-comfunds02.sql
sudo -u postgres psql -d comfunds03 -f docker/postgres/init-comfunds03.sql

# Verify tables were created
sudo -u postgres psql -d comfunds00 -c "\dt"
```

---

## Step 6: Create Systemd Services

### Backend Service
```bash
sudo nano /etc/systemd/system/hajifund-backend.service

# Add this content:
[Unit]
Description=HajiFund Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
ExecStart=/usr/local/go/bin/go run main.go
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hajifund-backend

[Install]
WantedBy=multi-user.target
```

### Frontend Service
```bash
sudo nano /etc/systemd/system/hajifund-frontend.service

# Add this content:
[Unit]
Description=HajiFund Frontend
After=network.target hajifund-backend.service
Requires=hajifund-backend.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund/frontend
Environment=PATH=/usr/local/go/bin:/usr/bin:/bin
ExecStart=/usr/local/go/bin/go run main.go
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hajifund-frontend

[Install]
WantedBy=multi-user.target
```

### Enable and Start Services
```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable hajifund-backend
sudo systemctl enable hajifund-frontend

# Start services
sudo systemctl start hajifund-backend
sudo systemctl start hajifund-frontend

# Check status
sudo systemctl status hajifund-backend
sudo systemctl status hajifund-frontend
```

---

## Step 7: Configure Firewall

### UFW Firewall
```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Allow PostgreSQL (optional, for external access)
sudo ufw allow 5432

# Check status
sudo ufw status
```

---

## Step 8: SSL Certificate (Optional but Recommended)

### Install Certbot
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### Get SSL Certificate
```bash
# If you have a domain name:
sudo certbot --nginx -d yourdomain.com

# If you only have IP address, you can use a self-signed certificate:
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/hajifund.key \
    -out /etc/ssl/certs/hajifund.crt

# Update Nginx configuration for HTTPS
sudo nano /etc/nginx/sites-available/hajifund

# Add HTTPS configuration:
server {
    listen 443 ssl http2;
    server_name 103.103.20.68;  # Replace with your domain

    ssl_certificate /etc/ssl/certs/hajifund.crt;
    ssl_certificate_key /etc/ssl/private/hajifund.key;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    # Same location blocks as HTTP configuration
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /var/www/hajifund/frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name 103.103.20.68;
    return 301 https://$server_name$request_uri;
}

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

---

## Step 9: Monitoring and Logs

### Set Up Log Rotation
```bash
sudo nano /etc/logrotate.d/hajifund

# Add this content:
/var/log/hajifund-*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload hajifund-backend hajifund-frontend
    endscript
}
```

### Monitor Services
```bash
# Check service status
sudo systemctl status hajifund-backend
sudo systemctl status hajifund-frontend
sudo systemctl status nginx
sudo systemctl status postgresql

# View logs
sudo journalctl -u hajifund-backend -f
sudo journalctl -u hajifund-frontend -f
sudo journalctl -u nginx -f

# Check application logs
tail -f /var/log/syslog | grep hajifund
```

---

## Step 10: Testing Deployment

### Test Backend API
```bash
# Test backend health
curl http://103.103.20.68/api/v1/health

# Test database connection
curl http://103.103.20.68/api/v1/projects
```

### Test Frontend
```bash
# Open in browser or test with curl
curl -I http://103.103.20.68
```

### Test Database Connectivity
```bash
# Test PostgreSQL connection
sudo -u postgres psql -h localhost -p 5432 -U comfunds_user -d comfunds00 -c "SELECT version();"
```

---

## Step 11: Backup and Maintenance

### Database Backup Script
```bash
sudo nano /usr/local/bin/hajifund-backup.sh

# Add this content:
#!/bin/bash
BACKUP_DIR="/var/backups/hajifund"
DATE=$(date +%Y%m%d_%H%M%S)
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

mkdir -p $BACKUP_DIR

for shard in "${SHARDS[@]}"; do
    echo "Backing up $shard..."
    sudo -u postgres pg_dump $shard > $BACKUP_DIR/${shard}_${DATE}.sql
done

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: $DATE"

# Make executable
sudo chmod +x /usr/local/bin/hajifund-backup.sh

# Add to crontab for daily backups
sudo crontab -e

# Add this line for daily backup at 2 AM:
0 2 * * * /usr/local/bin/hajifund-backup.sh
```

---

## Troubleshooting

### Common Issues

1. **Services won't start**
   ```bash
   sudo journalctl -u hajifund-backend -n 50
   sudo journalctl -u hajifund-frontend -n 50
   ```

2. **Database connection issues**
   ```bash
   sudo systemctl status postgresql
   sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
   ```

3. **Port conflicts**
   ```bash
   sudo netstat -tulpn | grep :3000
   sudo netstat -tulpn | grep :8080
   sudo netstat -tulpn | grep :5432
   ```

4. **Permission issues**
   ```bash
   sudo chown -R www-data:www-data /var/www/hajifund
   sudo chmod -R 755 /var/www/hajifund
   ```

### Performance Optimization

1. **PostgreSQL Tuning**
   ```bash
   sudo nano /etc/postgresql/15/main/postgresql.conf
   # Adjust shared_buffers, effective_cache_size, work_mem based on your server specs
   ```

2. **Nginx Caching**
   ```bash
   # Add caching directives to nginx config
   location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```

---

## Security Considerations

1. **Change default passwords**
2. **Use strong JWT secrets**
3. **Regular security updates**
4. **Monitor logs for suspicious activity**
5. **Use fail2ban for SSH protection**
6. **Regular database backups**
7. **SSL/TLS encryption**

---

## Final Checklist

- [ ] Go installed and configured
- [ ] PostgreSQL installed with 4 sharded databases
- [ ] Application code deployed
- [ ] Environment variables configured
- [ ] Database schema initialized
- [ ] Systemd services created and running
- [ ] Nginx configured and running
- [ ] Firewall configured
- [ ] SSL certificate installed (optional)
- [ ] Monitoring and logging set up
- [ ] Backup system configured
- [ ] All services tested and working

---

## Access URLs

- **Frontend**: http://103.103.20.68 or https://103.103.20.68
- **Backend API**: http://103.103.20.68/api/ or https://103.103.20.68/api/
- **Admin Panel**: http://103.103.20.68/admin/ or https://103.103.20.68/admin/

---

## Support

For issues or questions:
1. Check service logs: `sudo journalctl -u service-name -f`
2. Verify configuration files
3. Test database connectivity
4. Check firewall and port accessibility
5. Review this deployment guide

---

**Note**: Replace `103.103.20.68` with your actual domain name if you have one. This will improve SEO and user experience.
