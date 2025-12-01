# HajiFund Docker Deployment

This directory contains all the necessary files for deploying the HajiFund application using Docker on a VPS.

## Architecture

- **Backend**: Go Gin Gonic framework
- **Frontend**: Go Fiber framework  
- **Database**: PostgreSQL with sharding (4 shards: comfunds00, 01, 02, 03)
- **Session Store**: Redis
- **Reverse Proxy**: Nginx with HTTPS
- **Container Orchestration**: Docker Compose

## Data Flow

```
User Request → Nginx → Go Fiber (Frontend) → Go Gin (Backend) → PostgreSQL → Redis
```

## Files Structure

```
prepare-docker/
├── docker-compose.yml              # Main Docker Compose configuration
├── backend.env                     # Backend environment variables
├── frontend.env                    # Frontend environment variables
├── docker-deploy-complete.sh       # Complete deployment script
├── copy-to-vps.sh                  # Script to copy files to VPS
├── docker/
│   ├── nginx/
│   │   ├── nginx.conf              # Main Nginx configuration
│   │   └── default.conf             # Nginx server configuration
│   └── postgres/
│       ├── init-multiple-databases.sh  # Database initialization script
│       ├── init-comfunds00.sql     # Shard 0 schema
│       ├── init-comfunds01.sql     # Shard 1 schema
│       ├── init-comfunds02.sql     # Shard 2 schema
│       └── init-comfunds03.sql     # Shard 3 schema
└── README.md                       # This file
```

## Quick Deployment

### 1. Copy Files to VPS

```bash
# From the prepare-docker directory
./copy-to-vps.sh
```

### 2. Deploy on VPS

```bash
# SSH to VPS
ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68

# Navigate to project directory
cd ~/sourcecode

# Run deployment script
./docker-deploy-complete.sh
```

## Manual Deployment Steps

### 1. Prerequisites

- Ubuntu 24.04 VPS
- SSH access with sudo privileges
- Domain or IP address (103.103.20.68)

### 2. Install Docker

```bash
# Update system
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
```

### 3. Configure Environment

The deployment script automatically:
- Sets up file permissions
- Configures firewall (UFW)
- Creates SSL certificates
- Sets up database sharding
- Configures Nginx reverse proxy

### 4. Start Services

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

## Environment Variables

### Backend (.env)
- Database connection settings
- Redis configuration
- JWT settings
- CORS configuration
- Cookie settings
- Sharding configuration

### Frontend (frontend.env)
- Backend API URL
- CORS settings
- Cookie configuration
- Session settings

## Database Sharding

The application uses 4 PostgreSQL shards:
- `comfunds00` - Shard 0
- `comfunds01` - Shard 1  
- `comfunds02` - Shard 2
- `comfunds03` - Shard 3

Data is distributed using CRC32 hashing based on user/project IDs.

## Services

### Backend (Port 8080)
- Go Gin framework
- RESTful API
- JWT authentication
- Database sharding
- Redis session store

### Frontend (Port 3000)
- Go Fiber framework
- HTML templates
- Static file serving
- API proxy to backend

### PostgreSQL (Port 5432)
- 4 sharded databases
- UUID primary keys
- Automatic triggers
- Indexes for performance

### Redis (Port 6379)
- Session storage
- Caching
- Password protected

### Nginx (Ports 80/443)
- Reverse proxy
- SSL termination
- Static file serving
- Rate limiting
- CORS headers

## Management Commands

```bash
# Start services
./start.sh

# Stop services  
./stop.sh

# Restart services
./restart.sh

# View logs
./logs.sh

# Backup databases
./backup.sh
```

## Security Features

- HTTPS with SSL certificates
- Rate limiting on API endpoints
- CORS configuration
- HTTPOnly cookies
- Input validation
- SQL injection protection
- XSS protection headers

## Monitoring

- Health check endpoints
- Service status monitoring
- Log aggregation
- Database connection pooling
- Redis connection monitoring

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 80, 443, 3000, 8080, 5432, 6379 are available
2. **Permission errors**: Run `sudo chown -R $USER:$USER ~/sourcecode`
3. **SSL errors**: Check certificate paths in Nginx configuration
4. **Database connection**: Verify PostgreSQL is running and accessible
5. **Redis connection**: Check Redis password and connection string

### Logs

```bash
# View all service logs
docker compose logs

# View specific service logs
docker compose logs backend
docker compose logs frontend
docker compose logs postgres
docker compose logs redis
docker compose logs nginx
```

### Health Checks

```bash
# Check service health
curl http://103.103.20.68/health
curl http://103.103.20.68/api/v1/health
```

## Production Considerations

1. **Change default passwords** in environment files
2. **Use Let's Encrypt** for SSL certificates
3. **Configure proper firewall** rules
4. **Set up monitoring** and alerting
5. **Regular backups** of databases
6. **Update SSL certificates** before expiration
7. **Monitor resource usage** and scale as needed

## Support

For issues or questions:
1. Check service logs
2. Verify environment variables
3. Test individual service connectivity
4. Check firewall and network configuration
