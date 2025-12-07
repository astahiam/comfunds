#!/bin/bash

# Deploy Database to VPS Docker
# Run this script on your VPS

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

print_step "Deploying database to VPS Docker..."

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Stop existing postgres container if running
print_step "Stopping existing PostgreSQL container..."
docker-compose stop postgres 2>/dev/null || true
docker-compose rm -f postgres 2>/dev/null || true

# Remove existing volume if needed (WARNING: This deletes existing data!)
read -p "Remove existing PostgreSQL volume? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Removing existing PostgreSQL volume..."
    docker volume rm $(docker volume ls -q | grep postgres) 2>/dev/null || true
fi

# Start PostgreSQL with init scripts
print_step "Starting PostgreSQL with data initialization..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
print_step "Waiting for PostgreSQL to be ready..."
sleep 10

# Check if databases were created
print_step "Verifying databases..."
for shard in "${SHARDS[@]}"; do
    if docker-compose exec -T postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_status "Database $shard exists"
    else
        print_error "Database $shard not found"
    fi
done

print_status "Deployment completed!"
print_step "You can now start other services:"
echo "  docker-compose up -d"
