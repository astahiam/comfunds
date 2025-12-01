#!/bin/bash

# Copy fix script to VPS and run it
# This script copies the fix-golang-systemd.sh script to VPS and executes it

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

print_step "Copying and running fix script on VPS"

# Check if SSH key exists
if [ ! -f "$VPS_SSH_KEY" ]; then
    print_error "SSH key not found: $VPS_SSH_KEY"
    exit 1
fi

# Copy fix script to VPS
print_step "Copying fix script to VPS..."
scp -i $VPS_SSH_KEY fix-golang-systemd.sh $VPS_USER@$VPS_IP:~/

# Make it executable
ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "chmod +x ~/fix-golang-systemd.sh"

# Run the fix script
print_step "Running fix script on VPS..."
ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP "~/fix-golang-systemd.sh"

print_status "Fix script completed on VPS!"

print_info "To check the status, run:"
print_info "ssh -i $VPS_SSH_KEY $VPS_USER@$VPS_IP"
print_info "sudo systemctl status hajifund-backend hajifund-frontend"
