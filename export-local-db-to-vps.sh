#!/bin/bash

# Export Local Database and Import to VPS
# This script exports all data from local PostgreSQL and imports it to VPS

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
EXPORT_DIR="./db-export-${TIMESTAMP}"
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

# VPS Database Configuration (Docker)
VPS_DB_HOST="${VPS_DB_HOST:-localhost}"
VPS_DB_PORT="${VPS_DB_PORT:-5432}"
VPS_DB_USER="${VPS_DB_USER:-postgres}"
VPS_DB_PASSWORD="${VPS_DB_PASSWORD:-postgres123}"

print_header "Export Local Database and Import to VPS"

print_info "Configuration:"
print_info "  Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT"
print_info "  Local User: $LOCAL_DB_USER"
print_info "  VPS Host: $VPS_HOST"
print_info "  VPS User: $VPS_USER"
print_info "  VPS DB: $VPS_DB_USER@$VPS_DB_HOST:$VPS_DB_PORT"
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
    print_info "  - PostgreSQL is running locally"
    print_info "  - Connection settings are correct"
    print_info "  - Set LOCAL_DB_PASSWORD if needed"
    exit 1
fi

# Step 2: Create export directory
print_step "2. Creating export directory..."
mkdir -p "$EXPORT_DIR"
print_status "Export directory created: $EXPORT_DIR"

# Step 3: Export each database shard
print_step "3. Exporting database shards from local..."

for shard in "${SHARDS[@]}"; do
    print_info "Exporting $shard..."
    
    # Check if database exists locally
    if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -c "SELECT 1;" >/dev/null 2>&1; then
        # Export schema and data together
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --clean \
            --if-exists \
            --format=plain \
            --file="$EXPORT_DIR/${shard}_complete.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        # Also create data-only dump
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --data-only \
            --disable-triggers \
            --format=plain \
            --file="$EXPORT_DIR/${shard}_data.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        # Get table counts
        TABLE_COUNT=$(psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
        print_status "✅ $shard exported (${TABLE_COUNT} tables)"
    else
        print_warning "⚠️  Database $shard does not exist locally, skipping..."
    fi
done

# Step 4: Create import script for VPS
print_step "4. Creating VPS import script..."

cat > "$EXPORT_DIR/import-to-vps.sh" << 'IMPORT_SCRIPT'
#!/bin/bash

# Import Database to VPS Docker PostgreSQL
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
VPS_DB_USER="${VPS_DB_USER:-postgres}"
VPS_DB_PASSWORD="${VPS_DB_PASSWORD:-postgres123}"

print_step "Importing databases to VPS Docker PostgreSQL..."

# Check if Docker is running
if ! docker ps >/dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose not found"
    exit 1
fi

# Check if PostgreSQL container is running
if ! $COMPOSE_CMD ps | grep -q "postgres.*Up"; then
    print_error "PostgreSQL container is not running"
    print_step "Starting PostgreSQL..."
    $COMPOSE_CMD up -d postgres
    sleep 10
fi

# Wait for PostgreSQL to be ready
print_step "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if $COMPOSE_CMD exec -T postgres pg_isready -U "$VPS_DB_USER" >/dev/null 2>&1; then
        print_status "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "PostgreSQL failed to start"
        exit 1
    fi
    sleep 2
done

# Import each database
for shard in "${SHARDS[@]}"; do
    print_step "Importing $shard..."
    
    # Check if dump file exists
    if [ ! -f "${shard}_complete.sql" ] && [ ! -f "${shard}_data.sql" ]; then
        print_error "No dump file found for $shard, skipping..."
        continue
    fi
    
    # Create database if it doesn't exist
    if ! $COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_step "Creating database $shard..."
        $COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -c "CREATE DATABASE $shard;"
    fi
    
    # Drop existing data (optional - comment out if you want to merge)
    print_step "Clearing existing data in $shard..."
    $COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -d "$shard" << EOF
        DO \$\$ DECLARE
            r RECORD;
        BEGIN
            FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
                EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
            END LOOP;
        END \$\$;
EOF
    
    # Import schema and data
    if [ -f "${shard}_complete.sql" ]; then
        print_step "Importing complete dump for $shard..."
        cat "${shard}_complete.sql" | $COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -d "$shard" 2>&1 | grep -v "does not exist" | grep -v "already exists" || true
    elif [ -f "${shard}_data.sql" ]; then
        print_step "Importing data dump for $shard..."
        cat "${shard}_data.sql" | $COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -d "$shard" 2>&1 | grep -v "does not exist" || true
    fi
    
    # Verify import
    TABLE_COUNT=$($COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0")
    ROW_COUNT=$($COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT SUM(n_live_tup) FROM pg_stat_user_tables;" 2>/dev/null | xargs || echo "0")
    
    print_status "✅ $shard imported (${TABLE_COUNT} tables, ~${ROW_COUNT} rows)"
done

print_status "All databases imported successfully!"
print_step "Verifying imports..."

for shard in "${SHARDS[@]}"; do
    echo ""
    echo "Database: $shard"
    $COMPOSE_CMD exec -T postgres psql -U "$VPS_DB_USER" -d "$shard" -c "\dt" | head -20 || true
done

print_status "Import completed!"
IMPORT_SCRIPT

chmod +x "$EXPORT_DIR/import-to-vps.sh"

# Step 5: Create upload script
print_step "5. Creating upload script..."

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
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_PATH/db-import"

# Upload all files
echo "📤 Uploading files..."
scp -i "$VPS_KEY" -r "$EXPORT_DIR"/* "$VPS_USER@$VPS_HOST:$VPS_PATH/db-import/"

echo "✅ Upload completed!"
echo ""
echo "Next steps on VPS:"
echo "  1. SSH to VPS: ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
echo "  2. Navigate: cd $VPS_PATH/db-import"
echo "  3. Run: ./import-to-vps.sh"
UPLOAD_SCRIPT

chmod +x "$EXPORT_DIR/upload-to-vps.sh"

# Step 6: Summary
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
echo "   scp -i $VPS_KEY -r $EXPORT_DIR/* $VPS_USER@$VPS_HOST:$VPS_PATH/db-import/"
echo ""
echo "3. Import on VPS:"
echo "   ssh -i $VPS_KEY $VPS_USER@$VPS_HOST"
echo "   cd $VPS_PATH/db-import"
echo "   ./import-to-vps.sh"
echo ""
print_status "Ready to import! 🚀"

