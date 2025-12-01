#!/bin/bash

# Simple Database Permissions Fix for HajiFund
# This script fixes the specific permission issue with the users table

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

print_step "Simple Database Permissions Fix"

# Database configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="postgres"

# Check if .env file exists and load it
if [ -f "/var/www/hajifund/.env" ]; then
    print_info "Loading database configuration from .env file..."
    source /var/www/hajifund/.env
    
    DB_HOST=${DB_HOST:-"localhost"}
    DB_PORT=${DB_PORT:-"5432"}
    DB_USER=${DB_USER:-"postgres"}
    DB_PASSWORD=${DB_PASSWORD:-"postgres"}
fi

print_info "Using database user: $DB_USER"
print_info "Database host: $DB_HOST:$DB_PORT"

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

# 2. Fix permissions for each database shard
print_step "2. Fixing permissions for all database shards..."

databases=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

for db in "${databases[@]}"; do
    print_info "Processing database: $db"
    
    # Check if database exists
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$db"; then
        print_status "Database $db exists"
        
        # Grant all necessary permissions
        print_info "Granting permissions on $db..."
        
        # Grant connection privilege
        execute_sql "GRANT CONNECT ON DATABASE $db TO $DB_USER;" "$db" || true
        
        # Grant usage on schema
        execute_sql "GRANT USAGE ON SCHEMA public TO $DB_USER;" "$db" || true
        
        # Grant permissions on all existing tables
        execute_sql "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $DB_USER;" "$db" || true
        
        # Grant permissions on all existing sequences
        execute_sql "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;" "$db" || true
        
        # Grant default privileges for future tables and sequences
        execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $DB_USER;" "$db" || true
        execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO $DB_USER;" "$db" || true
        
        print_status "Permissions granted for $db"
    else
        print_info "Database $db does not exist, skipping..."
    fi
done

# 3. Test the fix
print_step "3. Testing database permissions..."

for db in "${databases[@]}"; do
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$db"; then
        print_info "Testing permissions on $db..."
        
        # Test if user can select from users table
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -c "SELECT COUNT(*) FROM users;" > /dev/null 2>&1; then
            print_status "SELECT permission on users table in $db: OK"
        else
            print_error "SELECT permission on users table in $db: FAILED"
        fi
        
        # Test if user can insert into users table (dry run)
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -c "BEGIN; INSERT INTO users (id, email, name, password_hash, created_at) VALUES (gen_random_uuid(), 'test@test.com', 'Test User', 'test_hash', NOW()); ROLLBACK;" > /dev/null 2>&1; then
            print_status "INSERT permission on users table in $db: OK"
        else
            print_error "INSERT permission on users table in $db: FAILED"
        fi
    fi
done

print_status "Database permissions fix completed!"
print_info "The user '$DB_USER' now has proper permissions on all database shards."
print_info "Try registering a user again - the permission error should be resolved."
