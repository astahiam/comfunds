#!/bin/bash

# Docker Migration Runner - Simplified version for Docker containers
# This script runs migrations inside Docker containers

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

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration
MIGRATIONS_DIR="${MIGRATIONS_DIR:-./migrations}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Database connection from environment (set by Docker Compose)
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

# Migration direction
DIRECTION="${1:-up}"

print_step "Running migrations in Docker environment"
print_info "Database: $DB_HOST:$DB_PORT"
print_info "User: $DB_USER"
print_info "Direction: $DIRECTION"
echo ""

# Set PGPASSWORD for psql
export PGPASSWORD="$DB_PASSWORD"

# Function to run migrations on a shard
run_migrations() {
    local shard=$1
    
    print_step "Migrating $shard..."
    
    # Get migration files
    if [ "$DIRECTION" = "up" ]; then
        migration_files=$(ls "$MIGRATIONS_DIR"/*.up.sql 2>/dev/null | sort)
    elif [ "$DIRECTION" = "down" ]; then
        migration_files=$(ls "$MIGRATIONS_DIR"/*.down.sql 2>/dev/null | sort -r)
    else
        print_error "Invalid direction: $DIRECTION (use 'up' or 'down')"
        return 1
    fi
    
    if [ -z "$migration_files" ]; then
        print_error "No migration files found in $MIGRATIONS_DIR"
        return 1
    fi
    
    # Check connection first
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -c "SELECT 1;" >/dev/null 2>&1; then
        print_error "Cannot connect to $shard"
        return 1
    fi
    
    # Run each migration
    for migration_file in $migration_files; do
        migration_name=$(basename "$migration_file")
        
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -f "$migration_file" 2>&1; then
            print_status "  ✅ $migration_name"
        else
            # Check if it's a "already exists" error (common for IF NOT EXISTS)
            if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -f "$migration_file" 2>&1 | grep -q "already exists"; then
                print_info "  ⚠️  $migration_name (already applied)"
            else
                print_error "  ❌ $migration_name failed"
                return 1
            fi
        fi
    done
    
    print_status "Completed migrations for $shard"
    return 0
}

# Run migrations on all shards
failed=0
for shard in "${SHARDS[@]}"; do
    echo ""
    if ! run_migrations "$shard"; then
        failed=1
    fi
done

echo ""
if [ $failed -eq 0 ]; then
    print_status "All migrations completed successfully!"
    exit 0
else
    print_error "Some migrations failed"
    exit 1
fi

