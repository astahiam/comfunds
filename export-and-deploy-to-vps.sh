#!/bin/bash

# Export Local Database and Deploy to VPS Docker
# This script exports your local database and prepares it for VPS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_DIR="./database-export-${TIMESTAMP}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Local Database Configuration
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

# VPS Configuration
VPS_USER="${VPS_USER:-ryankharisma}"
VPS_HOST="${VPS_HOST:-103.103.20.68}"
VPS_KEY="${VPS_KEY:-~/Downloads/ryan-biznet-gio.pem}"
VPS_PATH="${VPS_PATH:-~/sourcecode}"

print_header "Export Local Database and Deploy to VPS"

print_info "Configuration:"
print_info "  Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT"
print_info "  Local User: $LOCAL_DB_USER"
print_info "  VPS Host: $VPS_HOST"
print_info "  VPS User: $VPS_USER"
print_info "  Export Directory: $EXPORT_DIR"
echo ""

# Step 1: Check local database connection
print_step "1. Checking local database connection..."

if [ -n "$LOCAL_DB_PASSWORD" ]; then
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
fi

if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_status "Local database connection: OK"
else
    print_error "Cannot connect to local database"
    print_info "Please check:"
    print_info "  - PostgreSQL is running"
    print_info "  - Connection settings are correct"
    print_info "  - Set LOCAL_DB_PASSWORD if needed"
    exit 1
fi

# Step 2: Create export directory
print_step "2. Creating export directory..."
mkdir -p "$EXPORT_DIR"
print_status "Export directory created: $EXPORT_DIR"

# Step 3: Export each database shard
print_step "3. Exporting database shards..."

for shard in "${SHARDS[@]}"; do
    print_info "Exporting $shard..."
    
    # Check if database exists
    if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -c "SELECT 1;" >/dev/null 2>&1; then
        # Export schema and data together (for Docker init)
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --clean \
            --if-exists \
            --create \
            --format=plain \
            --file="$EXPORT_DIR/${shard}_complete.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        # Also create data-only dump (for loading into existing DB)
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --data-only \
            --disable-triggers \
            --format=plain \
            --file="$EXPORT_DIR/${shard}_data.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        print_status "✅ $shard exported"
    else
        print_warning "⚠️  Database $shard does not exist, skipping..."
    fi
done

# Step 4: Create Docker init SQL files
print_step "4. Creating Docker initialization files..."

for shard in "${SHARDS[@]}"; do
    if [ -f "$EXPORT_DIR/${shard}_complete.sql" ]; then
        # Create init file for Docker (without CREATE DATABASE, as it's handled by init script)
        grep -v "^CREATE DATABASE" "$EXPORT_DIR/${shard}_complete.sql" | \
        grep -v "^\\\\connect" | \
        grep -v "^--" | \
        sed "s/^/-- /" | \
        sed "1i-- Auto-generated from local database export" > "$EXPORT_DIR/init-${shard}.sql" || \
        cp "$EXPORT_DIR/${shard}_complete.sql" "$EXPORT_DIR/init-${shard}.sql"
        
        print_status "Created init-${shard}.sql"
    fi
done

# Step 5: Create deployment package
print_step "5. Creating deployment package..."

# Create docker-compose override with data volumes
cat > "$EXPORT_DIR/docker-compose.override.yml" << EOF
version: '3.8'

services:
  postgres:
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-comfunds00.sql:/docker-entrypoint-initdb.d/10-init-comfunds00.sql:ro
      - ./init-comfunds01.sql:/docker-entrypoint-initdb.d/11-init-comfunds01.sql:ro
      - ./init-comfunds02.sql:/docker-entrypoint-initdb.d/12-init-comfunds02.sql:ro
      - ./init-comfunds03.sql:/docker-entrypoint-initdb.d/13-init-comfunds03.sql:ro

volumes:
  postgres_data:
EOF

# Create deployment script for VPS
cat > "$EXPORT_DIR/deploy-to-vps.sh" << 'DEPLOY_SCRIPT'
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
DEPLOY_SCRIPT

chmod +x "$EXPORT_DIR/deploy-to-vps.sh"

# Step 6: Create upload script
print_step "6. Creating upload script..."

cat > "$EXPORT_DIR/upload-to-vps.sh" << UPLOAD_SCRIPT
#!/bin/bash

# Upload database export to VPS
# Run this from your local machine

set -e

VPS_USER="${VPS_USER}"
VPS_HOST="${VPS_HOST}"
VPS_KEY="${VPS_KEY}"
VPS_PATH="${VPS_PATH}"
EXPORT_DIR="${EXPORT_DIR}"

echo "🚀 Uploading database export to VPS..."

# Create directory on VPS
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_PATH/database-export"

# Upload all files
echo "📤 Uploading files..."
scp -i "$VPS_KEY" -r "$EXPORT_DIR"/* "$VPS_USER@$VPS_HOST:$VPS_PATH/database-export/"

echo "✅ Upload completed!"
echo ""
echo "Next steps on VPS:"
echo "  1. SSH to VPS: ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
echo "  2. Navigate: cd $VPS_PATH/database-export"
echo "  3. Run: ./deploy-to-vps.sh"
UPLOAD_SCRIPT

chmod +x "$EXPORT_DIR/upload-to-vps.sh"

# Step 7: Create README
print_step "7. Creating README..."

cat > "$EXPORT_DIR/README.md" << README
# Database Export for VPS Deployment

This directory contains exported database data from your local PostgreSQL.

## Files

- \`init-comfunds00.sql\` - Database initialization for shard 0
- \`init-comfunds01.sql\` - Database initialization for shard 1
- \`init-comfunds02.sql\` - Database initialization for shard 2
- \`init-comfunds03.sql\` - Database initialization for shard 3
- \`*_complete.sql\` - Complete database dumps (schema + data)
- \`*_data.sql\` - Data-only dumps
- \`docker-compose.override.yml\` - Docker Compose override
- \`deploy-to-vps.sh\` - Deployment script (run on VPS)
- \`upload-to-vps.sh\` - Upload script (run locally)

## Quick Deployment

### Option 1: Automated Upload and Deploy

```bash
# From local machine
./upload-to-vps.sh

# Then SSH to VPS and run
ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68
cd ~/sourcecode/database-export
./deploy-to-vps.sh
```

### Option 2: Manual Copy

```bash
# Copy files to VPS
scp -i ~/Downloads/ryan-biznet-gio.pem -r ./* ryankharisma@103.103.20.68:~/sourcecode/database-export/

# SSH to VPS
ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68

# Deploy
cd ~/sourcecode/database-export
./deploy-to-vps.sh
```

### Option 3: Load into Existing Docker Container

If PostgreSQL is already running:

```bash
# Copy init files to docker/postgres directory
cp init-*.sql ~/sourcecode/docker/postgres/

# Restart PostgreSQL
cd ~/sourcecode
docker-compose restart postgres
```

## Important Notes

⚠️ **WARNING**: The deployment script may remove existing PostgreSQL volumes. Make sure to backup existing data if needed.

The init SQL files will be automatically loaded when PostgreSQL container starts for the first time.
README

# Step 8: Summary
print_header "Export Summary"

print_status "Database export completed!"
echo ""
print_info "Export directory: $EXPORT_DIR"
print_info "Files created:"
ls -lh "$EXPORT_DIR" | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'
echo ""

print_step "Next Steps:"
echo ""
echo "1. Upload to VPS:"
echo "   cd $EXPORT_DIR"
echo "   ./upload-to-vps.sh"
echo ""
echo "2. Or manually copy:"
echo "   scp -i $VPS_KEY -r $EXPORT_DIR/* $VPS_USER@$VPS_HOST:$VPS_PATH/database-export/"
echo ""
echo "3. Deploy on VPS:"
echo "   ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
echo "   cd $VPS_PATH/database-export"
echo "   ./deploy-to-vps.sh"
echo ""
print_status "Ready for deployment! 🚀"

