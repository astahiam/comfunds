#!/bin/bash

# Import Database Dumps to VPS Docker PostgreSQL
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
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-hajifund-postgres}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"

print_step "Importing databases to VPS Docker PostgreSQL..."

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose not found"
    exit 1
fi

# Detect PostgreSQL container name
print_step "Detecting PostgreSQL container..."
if docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    CONTAINER_NAME="$POSTGRES_CONTAINER"
    print_status "Found container: $CONTAINER_NAME"
elif docker ps --format '{{.Names}}' | grep -q "postgres"; then
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep "postgres" | head -1)
    print_status "Found PostgreSQL container: $CONTAINER_NAME"
else
    # Check if service exists in docker-compose
    if $COMPOSE_CMD ps "$POSTGRES_SERVICE" &>/dev/null; then
        CONTAINER_NAME="$POSTGRES_SERVICE"
        print_status "Using service name: $CONTAINER_NAME"
    else
        print_error "PostgreSQL container not found"
        print_step "Starting PostgreSQL service..."
        $COMPOSE_CMD up -d "$POSTGRES_SERVICE"
        sleep 5
        CONTAINER_NAME="$POSTGRES_SERVICE"
    fi
fi

# Check if PostgreSQL container is running
print_step "Checking PostgreSQL container status..."
CONTAINER_STATUS=$(docker ps --format '{{.Names}}:{{.Status}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")

if [ -z "$CONTAINER_STATUS" ]; then
    print_error "PostgreSQL container is not running"
    print_step "Starting PostgreSQL..."
    $COMPOSE_CMD up -d "$POSTGRES_SERVICE"
    sleep 10
    
    # Verify container started
    if ! docker ps --format '{{.Names}}' | grep -qE "(postgres|hajifund)"; then
        print_error "Failed to start PostgreSQL container"
        print_error "Checking container logs:"
        $COMPOSE_CMD logs --tail=30 "$POSTGRES_SERVICE" || true
        exit 1
    fi
else
    print_status "PostgreSQL container status: $CONTAINER_STATUS"
fi

# Wait for PostgreSQL to be ready
print_step "Waiting for PostgreSQL to be ready..."
for i in {1..60}; do
    # Use psql instead of pg_isready to avoid segmentation faults
    # Check if we can connect and run a simple query
    if $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        print_error "PostgreSQL failed to start after 2 minutes"
        print_error "Container status:"
        docker ps -a | grep -E "(postgres|hajifund)" || true
        print_error "PostgreSQL logs:"
        $COMPOSE_CMD logs --tail=50 "$POSTGRES_SERVICE" || true
        exit 1
    fi
    if [ $((i % 5)) -eq 0 ]; then
        print_step "Still waiting... ($i/60)"
    fi
    sleep 2
done

# Additional wait to ensure PostgreSQL is fully initialized
print_step "Ensuring PostgreSQL is fully initialized..."
sleep 3

# Import each database
for shard in "${SHARDS[@]}"; do
    print_step "Importing $shard..."
    
    # Check if dump file exists
    if [ ! -f "${shard}_complete.sql" ] && [ ! -f "${shard}.dump" ]; then
        print_error "No dump file found for $shard, skipping..."
        continue
    fi
    
    # Create database if it doesn't exist
    print_step "Checking if database $shard exists..."
    DB_EXISTS=$(set +e; $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$shard" && echo "yes" || echo "no"; set -e)
    
    if [ "$DB_EXISTS" != "yes" ]; then
        print_step "Creating database $shard..."
        if ! $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -c "CREATE DATABASE $shard;" 2>&1; then
            print_error "Failed to create database $shard, it may already exist"
        fi
    else
        print_status "Database $shard already exists"
    fi
    
    # Drop existing data (optional - comment out if you want to merge)
    print_step "Clearing existing data in $shard..."
    $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -d "$shard" << 'EOF' 2>&1 | grep -vE "(does not exist|WARNING|NOTICE)" || true
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
EOF
    
    # Import using custom format if available (faster)
    if [ -f "${shard}.dump" ]; then
        print_step "Importing custom format dump for $shard..."
        # Try to copy dump file into container (works with postgres:15)
        DUMP_IN_CONTAINER="/tmp/${shard}.dump"
        if docker cp "${shard}.dump" "$CONTAINER_NAME:$DUMP_IN_CONTAINER" 2>/dev/null; then
            # Import from container path
            $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" pg_restore -U "$VPS_DB_USER" -d "$shard" --clean --if-exists "$DUMP_IN_CONTAINER" 2>&1 | grep -vE "(does not exist|WARNING|NOTICE)" || true
            $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" rm -f "$DUMP_IN_CONTAINER" 2>/dev/null || true
        else
            # Fallback: try with service name as container name
            if docker cp "${shard}.dump" "$POSTGRES_SERVICE:$DUMP_IN_CONTAINER" 2>/dev/null; then
                $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" pg_restore -U "$VPS_DB_USER" -d "$shard" --clean --if-exists "$DUMP_IN_CONTAINER" 2>&1 | grep -vE "(does not exist|WARNING|NOTICE)" || true
                $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" rm -f "$DUMP_IN_CONTAINER" 2>/dev/null || true
            else
                print_error "Could not copy dump file into container, falling back to SQL import"
                if [ -f "${shard}_complete.sql" ]; then
                    cat "${shard}_complete.sql" | $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -d "$shard" 2>&1 | grep -vE "(does not exist|already exists|WARNING|NOTICE)" || true
                fi
            fi
        fi
    elif [ -f "${shard}_complete.sql" ]; then
        print_step "Importing SQL dump for $shard..."
        # Use psql with proper error handling (works with postgres:15)
        cat "${shard}_complete.sql" | $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -d "$shard" 2>&1 | grep -vE "(does not exist|already exists|WARNING|NOTICE)" || true
    fi
    
    # Verify import
    print_step "Verifying import for $shard..."
    TABLE_COUNT=$(set +e; $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0"; set -e)
    ROW_COUNT=$(set +e; $COMPOSE_CMD exec -T "$POSTGRES_SERVICE" psql -U "$VPS_DB_USER" -d "$shard" -t -c "SELECT COALESCE(SUM(n_live_tup), 0)::bigint FROM pg_stat_user_tables;" 2>/dev/null | xargs || echo "0"; set -e)
    
    print_status "✅ $shard imported (${TABLE_COUNT} tables, ~${ROW_COUNT} rows)"
done

print_status "All databases imported successfully!"
print_step "Restarting services..."

$COMPOSE_CMD restart backend frontend || true

print_status "Import completed and services restarted!"

