#!/bin/bash

# ComFunds Database Setup Script
# This script creates the sharded databases for the ComFunds platform

set -e  # Exit on any error

# Default values
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres}
DB_ADMIN_DB=${DB_ADMIN_DB:-postgres}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if database exists
check_database_exists() {
    local db_name=$1
    if [ -n "$DB_PASSWORD" ]; then
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_ADMIN_DB -lqt | cut -d \| -f 1 | grep -qw $db_name
    else
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_ADMIN_DB -lqt | cut -d \| -f 1 | grep -qw $db_name
    fi
}

# Function to create database
create_database() {
    local db_name=$1
    print_status "Creating database: $db_name"
    
    if check_database_exists $db_name; then
        print_warning "Database $db_name already exists, skipping creation"
        return 0
    fi
    
    if [ -n "$DB_PASSWORD" ]; then
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_ADMIN_DB -c "CREATE DATABASE $db_name;"
    else
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_ADMIN_DB -c "CREATE DATABASE $db_name;"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Database $db_name created successfully"
    else
        print_error "Failed to create database $db_name"
        exit 1
    fi
}

# Function to test database connection
test_connection() {
    print_status "Testing PostgreSQL connection..."
    
    if [ -n "$DB_PASSWORD" ]; then
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_ADMIN_DB -c "SELECT version();" > /dev/null 2>&1
    else
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_ADMIN_DB -c "SELECT version();" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        print_success "PostgreSQL connection successful"
    else
        print_error "Failed to connect to PostgreSQL"
        print_error "Please check your database configuration:"
        print_error "  Host: $DB_HOST"
        print_error "  Port: $DB_PORT" 
        print_error "  User: $DB_USER"
        print_error "  Admin DB: $DB_ADMIN_DB"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  --host HOST         Database host (default: localhost)"
    echo "  --port PORT         Database port (default: 5432)"
    echo "  --user USER         Database user (default: postgres)"
    echo "  --password PASS     Database password (default: empty)"
    echo "  --admin-db DB       Admin database name (default: postgres)"
    echo ""
    echo "Environment variables:"
    echo "  DB_HOST             Database host"
    echo "  DB_PORT             Database port"
    echo "  DB_USER             Database user"
    echo "  DB_PASSWORD         Database password"
    echo "  DB_ADMIN_DB         Admin database name"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default values"
    echo "  $0 --user myuser --password mypass    # Specify user and password"
    echo "  DB_PASSWORD=secret $0                 # Use environment variable"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --host)
            DB_HOST="$2"
            shift 2
            ;;
        --port)
            DB_PORT="$2"
            shift 2
            ;;
        --user)
            DB_USER="$2"
            shift 2
            ;;
        --password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --admin-db)
            DB_ADMIN_DB="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
print_status "ComFunds Database Setup"
print_status "======================="
print_status "Host: $DB_HOST"
print_status "Port: $DB_PORT"
print_status "User: $DB_USER"
print_status "Admin DB: $DB_ADMIN_DB"
echo ""

# Test connection first
test_connection

# Create sharded databases
print_status "Creating sharded databases..."
create_database "comfunds01"
create_database "comfunds02"
create_database "comfunds03"
create_database "comfunds04"

echo ""
print_success "All sharded databases created successfully!"
print_status "Next steps:"
print_status "1. Run database migrations: make migrate-up"
print_status "2. Start the application: make dev"
echo ""
print_status "Database URLs for reference:"
if [ -n "$DB_PASSWORD" ]; then
    print_status "  comfunds01: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/comfunds01"
    print_status "  comfunds02: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/comfunds02"
    print_status "  comfunds03: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/comfunds03"
    print_status "  comfunds04: postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/comfunds04"
else
    print_status "  comfunds01: postgresql://$DB_USER@$DB_HOST:$DB_PORT/comfunds01"
    print_status "  comfunds02: postgresql://$DB_USER@$DB_HOST:$DB_PORT/comfunds02"
    print_status "  comfunds03: postgresql://$DB_USER@$DB_HOST:$DB_PORT/comfunds03"
    print_status "  comfunds04: postgresql://$DB_USER@$DB_HOST:$DB_PORT/comfunds04"
fi
