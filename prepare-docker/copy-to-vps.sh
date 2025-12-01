#!/bin/bash

# Simple script to copy all Docker files to VPS
# Run this from the prepare-docker directory

set -e

# Configuration
VPS_IP="103.103.20.68"
VPS_USER="ryankharisma"
VPS_SSH_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}==> $1${NC}"
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step "Copying HajiFund Docker files to VPS"

# Check if SSH key exists
if [ ! -f "$VPS_SSH_KEY" ]; then
    print_error "SSH key not found: $VPS_SSH_KEY"
    exit 1
fi

# Create remote directory
print_step "Creating remote directory..."
ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "mkdir -p $VPS_PATH"

# Copy all files
print_step "Copying files to VPS..."

# Copy main files
scp -i $VPS_SSH_KEY docker-compose.yml $VPS_USER@$VPS_IP:$VPS_PATH/
scp -i $VPS_SSH_KEY backend.env $VPS_USER@$VPS_IP:$VPS_PATH/.env
scp -i $VPS_SSH_KEY frontend.env $VPS_USER@$VPS_IP:$VPS_PATH/frontend.env
scp -i $VPS_SSH_KEY docker-deploy-complete.sh $VPS_USER@$VPS_IP:$VPS_PATH/

# Copy Docker directory
scp -i $VPS_SSH_KEY -r docker/ $VPS_USER@$VPS_IP:$VPS_PATH/

# Copy source code (if exists)
if [ -d "../backend" ]; then
    print_info "Copying backend source code..."
    scp -i $VPS_SSH_KEY -r ../backend/ $VPS_USER@$VPS_IP:$VPS_PATH/
fi

if [ -d "../frontend" ]; then
    print_info "Copying frontend source code..."
    scp -i $VPS_SSH_KEY -r ../frontend/ $VPS_USER@$VPS_IP:$VPS_PATH/
fi

# Set permissions
print_step "Setting permissions..."
ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "chmod +x $VPS_PATH/docker-deploy-complete.sh"
ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "chmod +x $VPS_PATH/docker/postgres/init-multiple-databases.sh"

print_status "Files copied successfully!"

print_info "To deploy on VPS, run:"
print_info "ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP"
print_info "cd $VPS_PATH"
print_info "./docker-deploy-complete.sh"
