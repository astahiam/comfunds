# 🐳 HajiFund Docker Deployment Guide

This guide provides comprehensive instructions for deploying the HajiFund Islamic crowdfunding platform using Docker containers with 4 sharded PostgreSQL databases.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start (Development)](#quick-start-development)
- [Production Deployment](#production-deployment)
- [Configuration](#configuration)
- [Database Sharding](#database-sharding)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture Overview

The HajiFund application consists of:

- **Frontend**: Go-based web application (Port 3000)
- **Backend API**: Go-based REST API (Port 8080)
- **PostgreSQL Shards**: 4 database instances for horizontal scaling
  - `comfunds00` (Port 5432)
  - `comfunds01` (Port 5433)
  - `comfunds02` (Port 5434)
  - `comfunds03` (Port 5435)
- **Nginx**: Reverse proxy and load balancer (Port 80/443)

## 🔧 Prerequisites

### For Development
- Docker Desktop or Docker Engine
- Docker Compose
- Git

### For Production VPS
- Ubuntu 20.04+ or CentOS 8+
- Root access or sudo privileges
- Domain name (for SSL)
- Minimum 4GB RAM, 2 CPU cores, 50GB storage

## 🚀 Quick Start (Development)

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd comfunds

# Copy environment file
cp docker/env.example .env

# Edit environment variables (optional for development)
nano .env
```

### 2. Deploy with Docker Compose

```bash
# Make deployment script executable
chmod +x docker/deploy.sh

# Deploy the application
./docker/deploy.sh
```

### 3. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **API Health Check**: http://localhost:8080/api/v1/health

### 4. Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@hajifund.com | admin123 |
| Business Owner | demo-business@example.com | Password123! |
| Investor | frontendtest@example.com | Password123! |
| Member | member@hajifund.com | password123 |

## 🌐 Production Deployment

### Automated VPS Deployment

```bash
# Set your domain name
export DOMAIN_NAME="your-domain.com"
export EMAIL="admin@your-domain.com"

# Run the VPS deployment script
sudo ./docker/deploy-vps.sh
```

This script will:
- Install Docker and Docker Compose
- Install Nginx and Certbot
- Configure SSL certificates
- Set up firewall rules
- Deploy the application
- Configure auto-restart and monitoring

### Manual Production Setup

#### 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 2. Application Deployment

```bash
# Clone application
git clone <your-repo-url>
cd comfunds

# Create production environment
cp docker/env.example .env
nano .env  # Edit with production values

# Deploy
./docker/deploy.sh
```

#### 3. SSL Configuration

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d api.your-domain.com

# Setup auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_PASSWORD` | PostgreSQL password | comfunds123 |
| `JWT_SECRET` | JWT signing secret | (generated) |
| `ENVIRONMENT` | Environment mode | production |
| `DOMAIN_NAME` | Your domain name | your-domain.com |
| `CORS_ORIGINS` | Allowed CORS origins | http://localhost:3000 |

### Database Configuration

The application uses 4 PostgreSQL shards for horizontal scaling:

- **Shard 0**: Users with ID hash % 4 = 0
- **Shard 1**: Users with ID hash % 4 = 1
- **Shard 2**: Users with ID hash % 4 = 2
- **Shard 3**: Users with ID hash % 4 = 3

Each shard contains identical table schemas for:
- Users
- Cooperatives
- Businesses
- Projects
- Investments
- Audit logs

## 📊 Database Sharding

### Shard Distribution

The application automatically distributes data across shards based on UUID hashing:

```go
// Example shard selection
shardIndex := hash(userID) % 4
```

### Database Access

| Shard | Port | Database | Purpose |
|-------|------|----------|---------|
| 0 | 5432 | comfunds00 | Primary operations |
| 1 | 5433 | comfunds01 | Secondary operations |
| 2 | 5434 | comfunds02 | Tertiary operations |
| 3 | 5435 | comfunds03 | Quaternary operations |

### Backup Strategy

```bash
# Backup all shards
for i in {0..3}; do
    docker exec comfunds-postgres-0$i pg_dump -U postgres comfunds0$i > backup_comfunds0$i_$(date +%Y%m%d).sql
done
```

## 🔍 Monitoring & Maintenance

### Service Management

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Update and restart
docker-compose pull
docker-compose up -d
```

### Health Checks

- **Backend**: http://localhost:8080/api/v1/health
- **Frontend**: http://localhost:3000/test
- **Database**: Built-in PostgreSQL health checks

### Log Management

```bash
# View application logs
docker-compose logs backend
docker-compose logs frontend

# View database logs
docker-compose logs postgres-comfunds00
```

### Performance Monitoring

```bash
# Monitor resource usage
docker stats

# Check database connections
docker exec comfunds-postgres-00 psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Services Won't Start

```bash
# Check logs
docker-compose logs

# Check port conflicts
netstat -tulpn | grep :3000
netstat -tulpn | grep :8080
```

#### 2. Database Connection Issues

```bash
# Test database connectivity
docker exec comfunds-backend ping postgres-comfunds00

# Check database status
docker exec comfunds-postgres-00 pg_isready -U postgres
```

#### 3. SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Test SSL
openssl s_client -connect your-domain.com:443
```

#### 4. Memory Issues

```bash
# Check memory usage
free -h
docker stats

# Increase swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Reset Everything

```bash
# Stop and remove all containers
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Clean up volumes
docker volume prune

# Restart fresh
./docker/deploy.sh
```

## 📚 Additional Resources

### Docker Commands Reference

```bash
# Build specific service
docker-compose build backend

# Scale services
docker-compose up -d --scale backend=2

# Execute commands in containers
docker-compose exec backend bash
docker-compose exec postgres-comfunds00 psql -U postgres

# View container logs
docker logs comfunds-backend
```

### Database Management

```bash
# Connect to database
docker exec -it comfunds-postgres-00 psql -U postgres -d comfunds00

# Run migrations
docker-compose exec backend ./main migrate

# Seed demo data
docker-compose exec backend ./scripts/run_seed_demo.sh
```

### Security Best Practices

1. **Change default passwords** in production
2. **Use strong JWT secrets**
3. **Enable SSL/TLS** for all communications
4. **Regular security updates**
5. **Monitor access logs**
6. **Backup data regularly**

## 🆘 Support

For issues and questions:

1. Check the logs: `docker-compose logs`
2. Verify configuration: `docker-compose config`
3. Test connectivity: `docker-compose exec backend ping postgres-comfunds00`
4. Review this documentation
5. Check GitHub issues

---

**Happy Deploying! 🚀**

The HajiFund platform is now ready to serve the Islamic crowdfunding community with a robust, scalable, and secure infrastructure.
