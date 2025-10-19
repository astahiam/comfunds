# HajiFund Docker Deployment Guide

## Overview
This guide covers deploying the HajiFund application using Docker containers on your VPS. Docker provides better isolation, easier scaling, and consistent deployments across environments.

## Prerequisites
- Ubuntu 24.04 VPS
- Root or sudo access
- Internet connection
- Domain name (optional, can use IP address)

## Quick Deployment

### 1. One-Command Deployment
```bash
# Download and run the deployment script
curl -fsSL https://raw.githubusercontent.com/astahiam/comfunds/main/docker-deploy.sh | sudo bash
```

### 2. Manual Deployment
```bash
# Clone the repository
git clone https://github.com/astahiam/comfunds.git
cd comfunds

# Make deployment script executable
chmod +x docker-deploy.sh

# Run deployment script
sudo ./docker-deploy.sh
```

## What Gets Deployed

### Services
- **Backend API** (Go/Gin) - Port 8080
- **Frontend** (GoFiber) - Port 3000  
- **PostgreSQL** (Sharded) - Port 5432
- **Nginx** (Reverse Proxy) - Ports 80/443
- **Redis** (Caching) - Port 6379

### Features
- ✅ SSL/TLS encryption
- ✅ Load balancing
- ✅ Health checks
- ✅ Automatic restarts
- ✅ Log management
- ✅ Backup system
- ✅ Monitoring tools

## Configuration

### Environment Variables
The deployment script creates a `.env` file with these variables:

```bash
# Database Configuration
DB_PASSWORD=postgres

# JWT Configuration  
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Application URLs
FRONTEND_URL=https://103.103.20.68

# Admin Configuration
ADMIN_EMAIL=admin@hajifund.com
ADMIN_PASSWORD=admin123
```

### Customizing Configuration
Edit the variables at the top of `docker-deploy.sh`:

```bash
# Configuration Variables
GITHUB_REPO="https://github.com/astahiam/comfunds.git"
DOMAIN_OR_IP="103.103.20.68"  # Your domain or IP
DB_PASSWORD="your_secure_password"
JWT_SECRET="your_jwt_secret"
ADMIN_EMAIL="admin@yourdomain.com"
ADMIN_PASSWORD="your_admin_password"
```

## Post-Deployment

### Access URLs
- **Frontend**: https://103.103.20.68
- **Backend API**: https://103.103.20.68/api/
- **Admin Panel**: https://103.103.20.68/admin/

### Default Admin Credentials
- **Email**: admin@hajifund.com
- **Password**: admin123

**⚠️ Change these credentials immediately after deployment!**

## Container Management

### View Running Containers
```bash
docker ps
```

### View Container Logs
```bash
# Backend logs
docker logs hajifund-backend

# Frontend logs  
docker logs hajifund-frontend

# All logs
docker logs hajifund-backend hajifund-frontend hajifund-nginx hajifund-postgres
```

### Restart Services
```bash
cd /var/www/hajifund
docker-compose restart
```

### Stop All Services
```bash
cd /var/www/hajifund
docker-compose down
```

### Start All Services
```bash
cd /var/www/hajifund
docker-compose up -d
```

### Update Application
```bash
cd /var/www/hajifund
git pull
docker-compose build --no-cache
docker-compose up -d
```

## Monitoring

### Container Status
```bash
/usr/local/bin/hajifund-docker-monitor.sh
```

### Resource Usage
```bash
docker stats
```

### Health Checks
```bash
# Check container health
docker ps --filter "health=unhealthy"

# Test endpoints
curl -k https://localhost/health
curl -k https://localhost/api/v1/health
```

## Backup and Restore

### Automatic Backups
Backups run daily at 2 AM automatically.

### Manual Backup
```bash
/usr/local/bin/hajifund-docker-backup.sh
```

### Restore from Backup
```bash
# Stop services
cd /var/www/hajifund
docker-compose down

# Restore database
docker exec -i hajifund-postgres psql -U hajifund_user hajifund00 < /var/backups/hajifund/hajifund00_YYYYMMDD_HHMMSS.sql

# Start services
docker-compose up -d
```

## Database Management

### Connect to PostgreSQL
```bash
docker exec -it hajifund-postgres psql -U hajifund_user -d postgres
```

### List Databases
```bash
docker exec hajifund-postgres psql -U hajifund_user -c "\l"
```

### Backup Specific Database
```bash
docker exec hajifund-postgres pg_dump -U hajifund_user hajifund00 > backup.sql
```

## Scaling

### Scale Backend Services
```bash
cd /var/www/hajifund
docker-compose up -d --scale backend=3
```

### Scale Frontend Services
```bash
cd /var/www/hajifund
docker-compose up -d --scale frontend=2
```

## SSL Certificate

### Using Let's Encrypt (Recommended)
```bash
# Install Certbot
apt install certbot

# Get certificate
certbot certonly --standalone -d yourdomain.com

# Copy certificates to Docker
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /var/www/hajifund/docker/nginx/ssl/hajifund.crt
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /var/www/hajifund/docker/nginx/ssl/hajifund.key

# Restart Nginx
docker restart hajifund-nginx
```

### Auto-renewal
```bash
# Add to crontab
echo "0 12 * * * /usr/bin/certbot renew --quiet && docker restart hajifund-nginx" | crontab -
```

## Troubleshooting

### Common Issues

#### 1. Containers Won't Start
```bash
# Check logs
docker logs hajifund-backend
docker logs hajifund-frontend

# Check disk space
df -h

# Check memory
free -h
```

#### 2. Database Connection Issues
```bash
# Check PostgreSQL status
docker exec hajifund-postgres pg_isready -U hajifund_user

# Check database exists
docker exec hajifund-postgres psql -U hajifund_user -c "\l"
```

#### 3. SSL Certificate Issues
```bash
# Check certificate files
ls -la /var/www/hajifund/docker/nginx/ssl/

# Test SSL
openssl x509 -in /var/www/hajifund/docker/nginx/ssl/hajifund.crt -text -noout
```

#### 4. Port Conflicts
```bash
# Check what's using ports
netstat -tulpn | grep :80
netstat -tulpn | grep :443
netstat -tulpn | grep :8080
netstat -tulpn | grep :3000
```

### Log Analysis
```bash
# Application logs
tail -f /var/log/hajifund/backend/app.log
tail -f /var/log/hajifund/frontend/app.log

# Nginx logs
tail -f /var/log/hajifund/nginx/access.log
tail -f /var/log/hajifund/nginx/error.log

# Docker logs
docker logs -f hajifund-backend
docker logs -f hajifund-frontend
```

## Performance Optimization

### Resource Limits
Edit `docker-compose.prod.yml` to add resource limits:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

### Database Optimization
```bash
# Connect to database
docker exec -it hajifund-postgres psql -U hajifund_user -d postgres

# Optimize PostgreSQL settings
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
SELECT pg_reload_conf();
```

## Security

### Container Security
- All containers run as non-root users
- Network isolation between services
- SSL/TLS encryption for all traffic
- Rate limiting on API endpoints

### Database Security
- Strong passwords required
- Network access restricted
- Regular backups
- Audit logging enabled

### Firewall Configuration
```bash
# Check firewall status
ufw status

# Allow only necessary ports
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
```

## Maintenance

### Regular Tasks
1. **Daily**: Check container health
2. **Weekly**: Review logs and performance
3. **Monthly**: Update containers and dependencies
4. **Quarterly**: Security audit and backup testing

### Update Procedure
```bash
# 1. Backup current state
/usr/local/bin/hajifund-docker-backup.sh

# 2. Pull latest code
cd /var/www/hajifund
git pull

# 3. Rebuild containers
docker-compose build --no-cache

# 4. Restart services
docker-compose down
docker-compose up -d

# 5. Verify deployment
/usr/local/bin/hajifund-docker-monitor.sh
```

## Support

### Getting Help
1. Check container logs: `docker logs [container-name]`
2. Run monitoring script: `/usr/local/bin/hajifund-docker-monitor.sh`
3. Check service status: `docker-compose ps`
4. Review this documentation

### Useful Commands
```bash
# System overview
docker system df
docker system prune

# Container management
docker ps -a
docker images
docker volume ls

# Service management
cd /var/www/hajifund
docker-compose ps
docker-compose logs
docker-compose restart
```

---

**🎉 Your HajiFund application is now running with Docker!**

For more information, visit the [main repository](https://github.com/astahiam/comfunds) or check the logs and monitoring tools provided.