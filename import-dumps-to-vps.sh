#!/bin/bash

# Import Database Dumps to VPS
# Run this from your local machine after dumping databases

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

# Find the most recent dump directory
DUMP_DIR=$(ls -td database-dumps-* 2>/dev/null | head -1)

if [ -z "$DUMP_DIR" ]; then
    echo "❌ No dump directory found. Run ./dump-all-local-databases.sh first"
    exit 1
fi

echo -e "${CYAN}Uploading database dumps to VPS...${NC}"
echo "Using dump directory: $DUMP_DIR"
echo ""

# Create directory on VPS
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_PATH/db-import"

# Upload all dump files
echo "📤 Uploading files..."
scp -i "$VPS_KEY" "$DUMP_DIR"/* "$VPS_USER@$VPS_HOST:$VPS_PATH/db-import/"

echo -e "${GREEN}✅ Upload completed!${NC}"
echo ""
echo -e "${BLUE}Next steps on VPS:${NC}"
echo "  1. SSH to VPS:"
echo "   ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
echo ""
echo "2. Import databases:"
echo "   cd $VPS_PATH/db-import"
echo "   chmod +x import-to-vps.sh"
echo "   ./import-to-vps.sh"
echo ""

