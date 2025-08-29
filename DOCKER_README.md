# ComFunds Docker Setup

This document provides comprehensive instructions for running the ComFunds platform using Docker containers.

## 🏗️ Architecture Overview

The ComFunds platform consists of the following services:

- **Backend API** (Go) - RESTful API server
- **Frontend Web** (Flutter Web) - Web application
- **Mobile App** (Flutter) - iOS and Android applications
- **Database** (PostgreSQL) - Primary database
- **Redis** (Optional) - Caching layer
- **Nginx** (Optional) - Reverse proxy for production

## 📁 Project Structure

```
comfunds/
├── Dockerfile                 # Go API production build
├── Dockerfile.dev            # Go API development build
├── docker-compose.yml        # Production orchestration
├── docker-compose.dev.yml    # Development orchestration
├── web/
│   ├── Dockerfile            # Flutter web production build
│   ├── Dockerfile.dev        # Flutter web development build
│   └── nginx.conf            # Nginx configuration
├── mobile/
│   └── Dockerfile            # Flutter mobile build
└── Makefile                  # Development commands
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- Ports 80, 8080, 3000, 5432 available

### Development Environment

1. **Start development environment:**
   ```bash
   make dev
   ```

2. **Access services:**
   - Backend API: http://localhost:8081
   - Frontend Web: http://localhost:3000
   - Database Admin: http://localhost:8082
   - Redis: localhost:6380

3. **View logs:**
   ```bash
   make dev-logs
   ```

4. **Stop development environment:**
   ```bash
   make dev-stop
   ```

### Production Environment

1. **Build and start production:**
   ```bash
   make build
   make run
   ```

2. **Access services:**
   - Backend API: http://localhost:8080
   - Frontend Web: http://localhost:80

3. **Stop production:**
   ```bash
   make stop
   ```

## 📱 Mobile Development

### Android Builds

1. **Build Android APK:**
   ```bash
   make mobile-build
   ```

2. **Build Android App Bundle:**
   ```bash
   make mobile-bundle
   ```

### iOS Development

For iOS development, you'll need to use the mobile Docker container:

```bash
# Build iOS simulator version
docker build -f mobile/Dockerfile --target ios-builder ./mobile
```

## 🛠️ Development Commands

### Make Commands

| Command | Description |
|---------|-------------|
| `make dev` | Start development environment |
| `make dev-stop` | Stop development environment |
| `make dev-logs` | Show development logs |
| `make build` | Build production images |
| `make run` | Start production environment |
| `make stop` | Stop production environment |
| `make logs` | Show production logs |
| `make clean` | Clean all containers and volumes |
| `make test` | Run tests |
| `make migrate` | Run database migrations |
| `make shell` | Open shell in backend container |
| `make health` | Check service health |

### Docker Compose Commands

#### Development
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop development environment
docker-compose -f docker-compose.dev.yml down

# Rebuild development images
docker-compose -f docker-compose.dev.yml build --no-cache
```

#### Production
```bash
# Start production environment
docker-compose up -d

# View logs
docker-compose logs -f

# Stop production environment
docker-compose down

# Rebuild production images
docker-compose build --no-cache
```

## 🔧 Configuration

### Environment Variables

#### Backend API
- `DATABASE_URL` - PostgreSQL connection string
- `PORT` - API server port (default: 8080)
- `ENVIRONMENT` - Environment (development/production)
- `JWT_SECRET` - JWT signing secret

#### Database
- `POSTGRES_DB` - Database name
- `POSTGRES_USER` - Database user
- `POSTGRES_PASSWORD` - Database password

### Custom Configuration

1. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit environment variables:**
   ```bash
   nano .env
   ```

3. **Restart services:**
   ```bash
   make dev-stop
   make dev
   ```

## 🗄️ Database Management

### Migrations

1. **Run migrations:**
   ```bash
   make migrate
   ```

2. **Reset database:**
   ```bash
   make db-reset
   ```

### Database Access

1. **Via Adminer (Web UI):**
   - URL: http://localhost:8082
   - Server: postgres-dev
   - Username: comfunds_user
   - Password: comfunds_password
   - Database: comfunds_dev

2. **Via Docker:**
   ```bash
   docker-compose exec postgres-dev psql -U comfunds_user -d comfunds_dev
   ```

## 🔍 Monitoring and Debugging

### Health Checks

```bash
make health
```

### Logs

```bash
# All services
make dev-logs

# Specific services
make backend-logs
make frontend-logs
make db-logs
```

### Container Shell Access

```bash
# Backend container
make shell

# Database container
docker-compose exec postgres-dev bash

# Frontend container
docker-compose -f docker-compose.dev.yml exec frontend-dev bash
```

## 🚀 Deployment

### Production Deployment

1. **Build production images:**
   ```bash
   make build
   ```

2. **Start production services:**
   ```bash
   make run
   ```

3. **Verify deployment:**
   ```bash
   make health
   ```

### Scaling

```bash
# Scale backend services
docker-compose up -d --scale backend=3

# Scale frontend services
docker-compose up -d --scale frontend=2
```

## 🔒 Security Considerations

### Production Security

1. **Change default passwords:**
   - Update database passwords
   - Change JWT secrets
   - Use strong API keys

2. **Enable HTTPS:**
   - Configure SSL certificates
   - Use Nginx reverse proxy
   - Enable security headers

3. **Network security:**
   - Use Docker networks
   - Restrict container access
   - Implement firewall rules

### Security Headers

The Nginx configuration includes security headers:
- X-Frame-Options
- X-XSS-Protection
- X-Content-Type-Options
- Referrer-Policy
- Content-Security-Policy

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check port usage
   netstat -tulpn | grep :8080
   
   # Change ports in docker-compose files
   ```

2. **Database connection issues:**
   ```bash
   # Check database health
   docker-compose exec postgres-dev pg_isready
   
   # Reset database
   make db-reset
   ```

3. **Build failures:**
   ```bash
   # Clean and rebuild
   make clean
   make build
   ```

4. **Memory issues:**
   ```bash
   # Increase Docker memory limit
   # Check container resource usage
   docker stats
   ```

### Performance Optimization

1. **Enable Docker BuildKit:**
   ```bash
   export DOCKER_BUILDKIT=1
   ```

2. **Use multi-stage builds:**
   - Already implemented in Dockerfiles
   - Reduces final image size

3. **Optimize layer caching:**
   - Copy dependency files first
   - Use .dockerignore effectively

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Flutter Web Documentation](https://flutter.dev/web)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🤝 Contributing

When contributing to the Docker setup:

1. Test changes in development environment
2. Update documentation
3. Ensure backward compatibility
4. Follow security best practices
5. Add appropriate health checks

## 📄 License

This Docker setup is part of the ComFunds project and follows the same license terms.
