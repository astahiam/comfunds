#!/bin/bash

# HajiFund Database Permissions Fix Script
# This script fixes database permissions for the application user

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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
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

print_step "Fixing Database Permissions for HajiFund"

# Database configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASSWORD="postgres"
# Get database credentials from environment if available
if [ -f "/var/www/hajifund/.env" ]; then
    print_info "Loading database configuration from .env file..."
    source /var/www/hajifund/.env
    
    DB_HOST=${DB_HOST:-"localhost"}
    DB_PORT=${DB_PORT:-"5432"}
    DB_USER=${DB_USER:-"postgres"}
    DB_PASSWORD=${DB_PASSWORD:-"postgres"}
    APP_USER=${DB_USER:-"postgres"}  # Use the same user as backend
    APP_PASSWORD=${DB_PASSWORD:-"postgres"}
else
    # Default values if no .env file
    APP_USER="postgres"
    APP_PASSWORD="postgres"
fi

print_info "Database Configuration:"
print_info "Host: $DB_HOST"
print_info "Port: $DB_PORT"
print_info "Admin User: $DB_USER"
print_info "App User: $APP_USER"

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

# Function to check if user exists
user_exists() {
    local db_name="$1"
    local result=$(execute_sql "SELECT 1 FROM pg_roles WHERE rolname='$APP_USER';" "$db_name" 2>/dev/null | grep -c "1" || echo "0")
    # Clean the result to remove any whitespace/newlines
    echo $(echo "$result" | tr -d '\n\r ')
}

# Function to check if database exists
database_exists() {
    local db_name="$1"
    local result=$(execute_sql "SELECT 1 FROM pg_database WHERE datname='$db_name';" 2>/dev/null | grep -c "1" || echo "0")
    # Clean the result to remove any whitespace/newlines
    echo $(echo "$result" | tr -d '\n\r ')
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

# 2. Create application user if it doesn't exist
print_step "2. Creating application user..."
if [ "$(user_exists)" -eq "0" ]; then
    print_info "Creating user: $APP_USER"
    execute_sql "CREATE USER $APP_USER WITH PASSWORD '$APP_PASSWORD';"
    print_status "User $APP_USER created"
else
    print_status "User $APP_USER already exists"
fi

# 3. Fix permissions for each database shard
print_step "3. Fixing permissions for all database shards..."

databases=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

for db in "${databases[@]}"; do
    print_info "Processing database: $db"
    
    # Check if database exists
    if [ "$(database_exists "$db")" -eq "0" ]; then
        print_warning "Database $db does not exist, creating it..."
        execute_sql "CREATE DATABASE $db;"
        print_status "Database $db created"
    fi
    
    # Grant connection privilege
    execute_sql "GRANT CONNECT ON DATABASE $db TO $APP_USER;" "$db"
    
    # Grant usage on schema
    execute_sql "GRANT USAGE ON SCHEMA public TO $APP_USER;" "$db"
    
    # Grant permissions on all existing tables
    execute_sql "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $APP_USER;" "$db"
    
    # Grant permissions on all existing sequences
    execute_sql "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $APP_USER;" "$db"
    
    # Grant default privileges for future tables and sequences
    execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $APP_USER;" "$db"
    execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO $APP_USER;" "$db"
    
    print_status "Permissions granted for $db"
done

# 4. Test database connection
print_step "4. Testing database connection..."
if PGPASSWORD="$APP_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$APP_USER" -d "comfunds00" -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "Database connection test successful"
else
    print_error "Database connection test failed"
    print_info "Checking if user can connect to any database..."
    
    # Try to connect to each database
    for db in "${databases[@]}"; do
        if PGPASSWORD="$APP_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$APP_USER" -d "$db" -c "SELECT 1;" > /dev/null 2>&1; then
            print_status "Connection to $db: SUCCESS"
        else
            print_error "Connection to $db: FAILED"
        fi
    done
fi

# 5. Test table permissions
print_step "5. Testing table permissions..."
for db in "${databases[@]}"; do
    print_info "Testing permissions on $db..."
    
    # Test if user can select from users table
    if PGPASSWORD="$APP_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$APP_USER" -d "$db" -c "SELECT COUNT(*) FROM users;" > /dev/null 2>&1; then
        print_status "SELECT permission on users table in $db: OK"
    else
        print_error "SELECT permission on users table in $db: FAILED"
    fi
    
    # Test if user can insert into users table (dry run)
    if PGPASSWORD="$APP_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$APP_USER" -d "$db" -c "BEGIN; INSERT INTO users (id, email, name, password_hash, created_at) VALUES (gen_random_uuid(), 'test@test.com', 'Test User', 'test_hash', NOW()); ROLLBACK;" > /dev/null 2>&1; then
        print_status "INSERT permission on users table in $db: OK"
    else
        print_error "INSERT permission on users table in $db: FAILED"
    fi
done

# 6. Show current user permissions
print_step "6. Current user permissions summary..."
execute_sql "SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin FROM pg_roles WHERE rolname='$APP_USER';"

print_status "Database permissions fix completed!"
print_info "The application user '$APP_USER' now has proper permissions on all database shards."
print_info "Try registering a user again - the permission error should be resolved."
