#!/bin/bash

# Script to load HajiFund data on VPS
# Run this script on the VPS server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

print_step "Loading HajiFund Data on VPS"

# Database configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="postgres"

# Database shards
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Function to execute SQL command
execute_sql() {
    local sql="$1"
    local db_name="$2"
    
    if [ -n "$db_name" ]; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "$sql"
    else
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "$sql"
    fi
}

# 1. Check if PostgreSQL is running
print_step "1. Checking PostgreSQL service..."
if systemctl is-active --quiet postgresql; then
    print_status "PostgreSQL is running"
else
    print_error "PostgreSQL is not running"
    print_info "Starting PostgreSQL..."
    systemctl start postgresql
    sleep 5
fi

# 2. Create databases if they don't exist
print_step "2. Creating databases..."

for shard in "${SHARDS[@]}"; do
    print_info "Checking/Creating database $shard..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_status "Database $shard already exists"
    else
        print_info "Creating database $shard..."
        execute_sql "CREATE DATABASE $shard;"
        print_status "Database $shard created"
    fi
done

# 3. Load data from backup files
print_step "3. Loading data from backup files..."

for shard in "${SHARDS[@]}"; do
    if [ -f "${shard}_data_only.sql" ]; then
        print_info "Loading data to $shard..."
        
        # Load data
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
            -d "$shard" -f "${shard}_data_only.sql"
        
        print_status "Data loaded to $shard"
    else
        print_warning "No data file found for $shard, skipping..."
    fi
done

# 4. Fix permissions
print_step "4. Fixing database permissions..."

for shard in "${SHARDS[@]}"; do
    print_info "Fixing permissions for $shard..."
    
    # Grant all privileges to postgres user
    execute_sql "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;" "$shard" || true
    execute_sql "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;" "$shard" || true
    execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_USER;" "$shard" || true
    execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USER;" "$shard" || true
    
    print_status "Permissions fixed for $shard"
done

# 5. Verify data
print_step "5. Verifying data..."

for shard in "${SHARDS[@]}"; do
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_info "Verifying $shard..."
        
        # Count tables
        table_count=$(execute_sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" "$shard" | grep -o '[0-9]*' | head -1)
        print_info "  Tables in $shard: $table_count"
        
        # Count users if table exists
        if execute_sql "SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public';" "$shard" | grep -q "1"; then
            user_count=$(execute_sql "SELECT COUNT(*) FROM users;" "$shard" | grep -o '[0-9]*' | head -1)
            print_info "  Users in $shard: $user_count"
        fi
    fi
done

print_status "Data loading completed!"
print_info "All databases have been loaded with data from the backup files."
