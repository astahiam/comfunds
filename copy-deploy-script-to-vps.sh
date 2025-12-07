#!/bin/bash

# Copy Deployment Script to VPS
# Run this from your local machine

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

echo -e "${CYAN}Copying deployment script to VPS...${NC}"

# Copy the deployment script
scp -i "$VPS_KEY" deploy-vps-complete.sh "$VPS_USER@$VPS_HOST:$VPS_PATH/"

# Make it executable on VPS
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "chmod +x $VPS_PATH/deploy-vps-complete.sh"

echo -e "${GREEN}✅ Deployment script copied to VPS!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. SSH to VPS:"
echo "     ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
echo ""
echo "  2. Run deployment:"
echo "     cd $VPS_PATH"
echo "     ./deploy-vps-complete.sh"
echo ""

