#!/bin/bash

# Quick VPS Deployment Guide
# This script helps you deploy to VPS quickly

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Quick VPS Deployment Guide${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}Step 1: Export Local Database${NC}"
echo "  Run: ./export-and-deploy-to-vps.sh"
echo ""

echo -e "${BLUE}Step 2: Connect to VPS${NC}"
echo "  ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68"
echo ""

echo -e "${BLUE}Step 3: On VPS - Check Current Status${NC}"
echo "  cd ~/sourcecode"
echo "  docker-compose ps"
echo "  docker-compose logs --tail=50"
echo ""

echo -e "${BLUE}Step 4: Pull Latest Code (if needed)${NC}"
echo "  cd ~/sourcecode"
echo "  git pull origin master"
echo ""

echo -e "${BLUE}Step 5: Deploy Database${NC}"
echo "  Option A - If you uploaded database export:"
echo "    cd ~/sourcecode/database-export"
echo "    ./deploy-to-vps.sh"
echo ""
echo "  Option B - Run migrations:"
echo "    cd ~/sourcecode"
echo "    DB_HOST=localhost DB_USER=postgres DB_PASSWORD=postgres123 ./run-golang-migrations.sh up"
echo ""

echo -e "${BLUE}Step 6: Restart Services${NC}"
echo "  cd ~/sourcecode"
echo "  docker-compose down"
echo "  docker-compose up -d"
echo ""

echo -e "${BLUE}Step 7: Check Status${NC}"
echo "  docker-compose ps"
echo "  docker-compose logs --tail=100"
echo ""

echo -e "${GREEN}Ready to deploy! 🚀${NC}"

