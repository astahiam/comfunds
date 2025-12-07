#!/bin/bash

# Master Restore Script
# Restores all databases from SQL backups

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
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

DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres123}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Check if running in Docker
if [ -f /.dockerenv ] || [ -n "$DOCKER_CONTAINER" ]; then
    CONTAINER_NAME="${DOCKER_CONTAINER:-hajifund-postgres}"
    PSQL_CMD="docker exec -i $CONTAINER_NAME psql -U $DB_USER"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
else
    PSQL_CMD="psql -U $DB_USER"
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
fi

print_step "Restoring all databases..."

for shard in "${SHARDS[@]}"; do
    if [ ! -f "${shard}_standalone_restore.sql" ]; then
        print_error "Restore file for $shard not found, skipping..."
        continue
    fi
    
    print_step "Restoring $shard..."
    
    if [ -n "$CONTAINER_NAME" ]; then
        # Docker mode
        cat "${shard}_standalone_restore.sql" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres 2>&1 | \
            grep -vE "(does not exist|already exists|WARNING|NOTICE)" || true
    else
        # Direct mode
        $PSQL_CMD -d postgres -f "${shard}_standalone_restore.sql" 2>&1 | \
            grep -vE "(does not exist|already exists|WARNING|NOTICE)" || true
    fi
    
    print_status "Restored $shard"
done

print_status "All databases restored!"

