#!/bin/bash

# Upload database export to VPS
# Run this from your local machine

set -e

VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"
EXPORT_DIR="./database-export-20251202_072155"

echo "🚀 Uploading database export to VPS..."

# Create directory on VPS
ssh -i "~/Downloads/ryan-biznet-gio.pem" "ryankharisma@103.103.20.68" "mkdir -p ~/sourcecode/database-export"

# Upload all files
echo "📤 Uploading files..."
scp -i "~/Downloads/ryan-biznet-gio.pem" -r "./database-export-20251202_072155"/* "ryankharisma@103.103.20.68:~/sourcecode/database-export/"

echo "✅ Upload completed!"
echo ""
echo "Next steps on VPS:"
echo "  1. SSH to VPS: ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68"
echo "  2. Navigate: cd ~/sourcecode/database-export"
echo "  3. Run: ./deploy-to-vps.sh"
