#!/bin/bash

# HajiFund Docker Deployment Script
# This script deploys the HajiFund application using Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
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

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    log_success "Docker and Docker Compose are installed"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        log_warning ".env file not found. Creating from example..."
        if [ -f "docker/env.example" ]; then
            cp docker/env.example .env
            log_warning "Please edit .env file with your configuration before continuing"
            log_warning "Especially update JWT_SECRET and DB_PASSWORD for production"
            read -p "Press Enter to continue after editing .env file..."
        else
            log_error "No .env file and no example found. Please create .env file manually."
            exit 1
        fi
    fi
    log_success ".env file found"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p docker/nginx/ssl
    mkdir -p logs
    log_success "Directories created"
}

# Build and start services
deploy_services() {
    log_info "Building and starting services..."
    
    # Pull latest images
    docker-compose -f $COMPOSE_FILE pull
    
    # Build custom images
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    # Start services
    docker-compose -f $COMPOSE_FILE up -d
    
    log_success "Services started"
}

# Wait for services to be healthy
wait_for_services() {
    log_info "Waiting for services to be healthy..."
    
    # Wait for databases
    log_info "Waiting for PostgreSQL databases..."
    sleep 30
    
    # Wait for backend
    log_info "Waiting for backend service..."
    timeout 120 bash -c 'until docker-compose -f '$COMPOSE_FILE' exec backend wget --no-verbose --tries=1 --spider http://localhost:8080/api/v1/health; do sleep 5; done'
    
    # Wait for frontend
    log_info "Waiting for frontend service..."
    timeout 60 bash -c 'until docker-compose -f '$COMPOSE_FILE' exec frontend wget --no-verbose --tries=1 --spider http://localhost:3000/test; do sleep 5; done'
    
    log_success "All services are healthy"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    # Wait a bit more for databases to be fully ready
    sleep 10
    
    # Run migrations
    docker-compose -f $COMPOSE_FILE exec backend ./main migrate || {
        log_warning "Migrations failed or already applied"
    }
    
    log_success "Database migrations completed"
}

# Seed demo data
seed_demo_data() {
    log_info "Seeding demo data..."
    
    # Run demo data seeding
    docker-compose -f $COMPOSE_FILE exec backend ./scripts/run_seed_demo.sh || {
        log_warning "Demo data seeding failed or already exists"
    }
    
    log_success "Demo data seeding completed"
}

# Show service status
show_status() {
    log_info "Service Status:"
    docker-compose -f $COMPOSE_FILE ps
    
    echo ""
    log_info "Service URLs:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend API: http://localhost:8080"
    echo "  API Health: http://localhost:8080/api/v1/health"
    echo ""
    log_info "Database Ports:"
    echo "  PostgreSQL Shard 0: localhost:5432"
    echo "  PostgreSQL Shard 1: localhost:5433"
    echo "  PostgreSQL Shard 2: localhost:5434"
    echo "  PostgreSQL Shard 3: localhost:5435"
    echo ""
    log_info "Demo Accounts:"
    echo "  Admin: admin@hajifund.com / admin123"
    echo "  Business Owner: demo-business@example.com / Password123!"
    echo "  Investor: frontendtest@example.com / Password123!"
    echo "  Member: member@hajifund.com / password123"
}

# Main deployment function
main() {
    log_info "Starting HajiFund Docker Deployment..."
    
    check_docker
    check_env_file
    create_directories
    deploy_services
    wait_for_services
    run_migrations
    seed_demo_data
    show_status
    
    log_success "HajiFund deployment completed successfully!"
    log_info "You can now access the application at http://localhost:3000"
}

# Handle script arguments
case "${1:-}" in
    "stop")
        log_info "Stopping HajiFund services..."
        docker-compose -f $COMPOSE_FILE down
        log_success "Services stopped"
        ;;
    "restart")
        log_info "Restarting HajiFund services..."
        docker-compose -f $COMPOSE_FILE restart
        log_success "Services restarted"
        ;;
    "logs")
        docker-compose -f $COMPOSE_FILE logs -f
        ;;
    "status")
        show_status
        ;;
    "clean")
        log_warning "This will remove all containers, volumes, and images. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            docker-compose -f $COMPOSE_FILE down -v --rmi all
            log_success "Cleanup completed"
        else
            log_info "Cleanup cancelled"
        fi
        ;;
    *)
        main
        ;;
esac
