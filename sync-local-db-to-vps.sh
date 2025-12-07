#!/bin/bash

# One-Step Script: Export Local DB and Import to VPS
# This script does everything automatically

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Configuration
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

VPS_USER="${VPS_USER:-ryankharisma}"
VPS_HOST="${VPS_HOST:-103.103.20.68}"
VPS_KEY="${VPS_KEY:-~/Downloads/ryan-biznet-gio.pem}"
VPS_PATH="${VPS_PATH:-~/sourcecode}"

VPS_DB_USER="${VPS_DB_USER:-postgres}"
VPS_DB_PASSWORD="${VPS_DB_PASSWORD:-postgres123}"

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")
TEMP_DIR="./db-sync-temp-$$"

print_step "One-Step Database Sync: Local → VPS"

# Step 1: Export from local
print_step "1. Exporting from local database..."

if [ -n "$LOCAL_DB_PASSWORD" ]; then
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
fi

mkdir -p "$TEMP_DIR"

for shard in "${SHARDS[@]}"; do
    if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -c "SELECT 1;" >/dev/null 2>&1; then
        print_step "Exporting $shard..."
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --clean \
            --if-exists \
            --format=plain \
            --file="$TEMP_DIR/${shard}.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        print_status "$shard exported"
    else
        print_error "$shard does not exist locally"
    fi
done

# Step 2: Upload to VPS
print_step "2. Uploading to VPS..."

ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $VPS_PATH/db-sync"

for shard in "${SHARDS[@]}"; do
    if [ -f "$TEMP_DIR/${shard}.sql" ]; then
        scp -i "$VPS_KEY" "$TEMP_DIR/${shard}.sql" "$VPS_USER@$VPS_HOST:$VPS_PATH/db-sync/"
        print_status "$shard uploaded"
    fi
done

# Step 3: Import to VPS
print_step "3. Importing to VPS Docker PostgreSQL..."

ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" << EOF
    cd $VPS_PATH
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        echo "❌ Docker Compose not found"
        exit 1
    fi
    
    # Ensure PostgreSQL is running
    if ! \$COMPOSE_CMD ps | grep -q "postgres.*Up"; then
        echo "Starting PostgreSQL..."
        \$COMPOSE_CMD up -d postgres
        sleep 10
    fi
    
    # Wait for PostgreSQL
    for i in {1..30}; do
        if \$COMPOSE_CMD exec -T postgres pg_isready -U $VPS_DB_USER >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    
    # Import each database
    for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
        if [ -f "db-sync/\${shard}.sql" ]; then
            echo "Importing \$shard..."
            
            # Create database if needed
            \$COMPOSE_CMD exec -T postgres psql -U $VPS_DB_USER -c "CREATE DATABASE \$shard;" 2>/dev/null || true
            
            # Import data
            cat "db-sync/\${shard}.sql" | \$COMPOSE_CMD exec -T postgres psql -U $VPS_DB_USER -d "\$shard" 2>&1 | grep -v "does not exist" | grep -v "already exists" || true
            
            echo "✅ \$shard imported"
        fi
    done
    
    echo ""
    echo "✅ All databases imported!"
    echo ""
    echo "Restarting services..."
    \$COMPOSE_CMD restart backend frontend || true
EOF

# Cleanup
print_step "4. Cleaning up..."
rm -rf "$TEMP_DIR"
print_status "Temporary files removed"

print_status "Database sync completed!"
print_step "Check your VPS application - projects should now be visible!"

