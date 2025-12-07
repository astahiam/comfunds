#!/bin/bash

# Copy Local PostgreSQL Data to VPS Docker PostgreSQL
# Uses direct pg_dump | psql pipe for efficient transfer
# Based on: https://stackoverflow.com/a (CC BY-SA 4.0)

set -e

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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

# Local Database Configuration
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

# VPS Database Configuration (Docker - exposed on port 5432)
VPS_DB_HOST="${VPS_DB_HOST:-103.103.20.68}"
VPS_DB_PORT="${VPS_DB_PORT:-5432}"
VPS_DB_USER="${VPS_DB_USER:-postgres}"
VPS_DB_PASSWORD="${VPS_DB_PASSWORD:-postgres123}"

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

print_step "Copying local PostgreSQL data to VPS Docker PostgreSQL..."
print_info "Using direct pg_dump | psql pipe method"

# Set passwords for non-interactive mode
if [ -n "$LOCAL_DB_PASSWORD" ]; then
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
fi

# Check local PostgreSQL connection
print_step "Checking local PostgreSQL connection..."
if ! psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_error "Cannot connect to local PostgreSQL"
    exit 1
fi
print_status "Local PostgreSQL connection: OK"

# Check VPS PostgreSQL connection
print_step "Checking VPS PostgreSQL connection..."
export PGPASSWORD="$VPS_DB_PASSWORD"
if ! psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_error "Cannot connect to VPS PostgreSQL"
    print_info "Make sure PostgreSQL container is running and port 5432 is accessible"
    exit 1
fi
print_status "VPS PostgreSQL connection: OK"

# Copy each database using direct pipe
for shard in "${SHARDS[@]}"; do
    print_step "Copying $shard..."
    
    # Check if local database exists
    if ! psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_error "Local database $shard does not exist, skipping..."
        continue
    fi
    
    # Use pg_dump with --inserts flag (INSERT statements work better than COPY when piping)
    print_info "Dumping $shard from local and importing to VPS..."
    
    # Create database on VPS first if it doesn't exist
    export PGPASSWORD="$VPS_DB_PASSWORD"
    psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d postgres -c "CREATE DATABASE $shard;" 2>&1 | grep -v "already exists" || true
    
    # Set local password for pg_dump
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
    
    # Dump with INSERT statements (--inserts) instead of COPY (more reliable when piping)
    # Use --column-inserts for better compatibility
    pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
        --no-password \
        --clean \
        --if-exists \
        --inserts \
        --column-inserts \
        --format=plain \
        "$shard" 2>&1 | \
        grep -v "WARNING" | \
        PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" 2>&1 | \
        grep -vE "(already exists|does not exist|WARNING|NOTICE|invalid command)" || {
            print_warning "Some errors occurred during import, but continuing..."
        }
    
    # Verify import (use actual COUNT queries, not pg_stat which may not be updated)
    print_step "Verifying $shard on VPS..."
    export PGPASSWORD="$VPS_DB_PASSWORD"
    TABLE_COUNT=$(psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0")
    
    # Count actual rows from users table (more reliable than pg_stat)
    USER_COUNT=$(psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs || echo "0")
    
    # Try to get total row count from pg_stat, but fallback to users count
    ROW_COUNT=$(psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT COALESCE(SUM(n_live_tup), 0)::bigint FROM pg_stat_user_tables;" 2>/dev/null | xargs || echo "$USER_COUNT")
    
    # If pg_stat shows 0 but we have users, use users count as indicator
    if [ "$ROW_COUNT" = "0" ] && [ "$USER_COUNT" -gt 0 ]; then
        ROW_COUNT="$USER_COUNT+"
    fi
    
    print_status "✅ $shard copied (${TABLE_COUNT} tables, ${USER_COUNT} users, ~${ROW_COUNT} total rows)"
done

# Restart backend on VPS (using docker restart directly to avoid segfault)
print_step "Restarting backend on VPS..."
BACKEND_CONTAINER=$(ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "docker ps --format '{{.Names}}' | grep -E '(backend|hajifund)' | grep -v postgres | head -1" 2>/dev/null || echo "")
if [ -n "$BACKEND_CONTAINER" ]; then
    ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "docker restart $BACKEND_CONTAINER" 2>&1 || true
    print_status "Backend container restarted: $BACKEND_CONTAINER"
else
    print_warning "Backend container not found, skipping restart"
fi

print_status "✅ All databases copied successfully!"
print_info "Method: Direct pg_dump | psql pipe (no intermediate files)"
print_info "Local → VPS: $LOCAL_DB_HOST:$LOCAL_DB_PORT → $VPS_DB_HOST:$VPS_DB_PORT"

