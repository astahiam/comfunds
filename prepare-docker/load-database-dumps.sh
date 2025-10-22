#!/bin/bash

# Load Database Dumps into VPS Docker PostgreSQL
# This script loads pre-existing database dumps into VPS Docker PostgreSQL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

print_step "Loading Database Dumps into VPS Docker PostgreSQL"

# VPS Configuration
VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

# VPS Docker Database Configuration
VPS_DB_HOST="103.103.20.68"
VPS_DB_PORT="5432"
VPS_DB_USER="postgres"
VPS_DB_PASSWORD="postgres123"

# Database shards
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

print_info "Configuration:"
print_info "  VPS DB: $VPS_DB_HOST:$VPS_DB_PORT"
print_info "  Shards: ${SHARDS[*]}"

# 1. Check VPS Docker PostgreSQL connection
print_step "1. Checking VPS Docker PostgreSQL connection..."

if psql -h $VPS_DB_HOST -p $VPS_DB_PORT -U $VPS_DB_USER -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_status "VPS Docker PostgreSQL is accessible"
else
    print_error "Cannot connect to VPS Docker PostgreSQL"
    print_info "Make sure Docker containers are running on VPS"
    print_info "Run: ssh -i $VPS_KEY $VPS_USER@$VPS_HOST 'cd $VPS_PATH && docker compose up -d'"
    exit 1
fi

# 2. Check if dump files exist on VPS
print_step "2. Checking dump files on VPS..."

ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "ls -la $VPS_PATH/database-dumps/"

for shard in "${SHARDS[@]}"; do
    if ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "test -f $VPS_PATH/database-dumps/${shard}.dump"; then
        print_status "Dump file for $shard exists"
    else
        print_warning "Dump file for $shard not found"
    fi
done

# 3. Load each dump into VPS Docker PostgreSQL
print_step "3. Loading dumps into VPS Docker PostgreSQL..."

for shard in "${SHARDS[@]}"; do
    if ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "test -f $VPS_PATH/database-dumps/${shard}.dump"; then
        print_info "Loading $shard into VPS Docker PostgreSQL..."
        
        # Drop existing database if it exists
        print_info "Dropping existing $shard database..."
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres psql -U $VPS_DB_USER -d postgres -c \"DROP DATABASE IF EXISTS $shard;\""
        
        # Create database
        print_info "Creating $shard database..."
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres psql -U $VPS_DB_USER -d postgres -c \"CREATE DATABASE $shard;\""
        
        # Load dump
        print_info "Loading $shard dump..."
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres pg_restore -U $VPS_DB_USER -d $shard --clean --if-exists $VPS_PATH/database-dumps/${shard}.dump"
        
        print_status "$shard loaded into VPS Docker PostgreSQL"
    else
        print_warning "Skipping $shard (dump file not found)"
    fi
done

# 4. Verify data was loaded
print_step "4. Verifying data was loaded..."

for shard in "${SHARDS[@]}"; do
    print_info "Verifying $shard..."
    
    # Get table count
    TABLE_COUNT=$(ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres psql -U $VPS_DB_USER -d $shard -t -c \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';\"")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        print_status "$shard has $TABLE_COUNT tables"
    else
        print_warning "$shard has no tables"
    fi
done

# 5. Show sample data from each shard
print_step "5. Showing sample data from each shard..."

for shard in "${SHARDS[@]}"; do
    print_info "=== $shard ==="
    ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec postgres psql -U $VPS_DB_USER -d $shard -c \"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' LIMIT 5;\""
done

# 6. Final verification
print_step "6. Final verification..."

print_info "Database status on VPS:"
ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec postgres psql -U $VPS_DB_USER -d postgres -c \"SELECT datname FROM pg_database WHERE datname LIKE 'comfunds%';\""

# 7. Clean up dump files (optional)
print_step "7. Cleaning up dump files..."

read -p "Do you want to remove dump files from VPS? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "rm -rf $VPS_PATH/database-dumps"
    print_status "Dump files removed from VPS"
else
    print_info "Dump files kept on VPS"
fi

# 8. Final status
print_step "8. Database loading completed!"

print_status "All database dumps have been loaded into VPS Docker PostgreSQL!"
print_info "Loading summary:"
print_info "  Destination: VPS Docker PostgreSQL"
print_info "  Shards loaded: ${SHARDS[*]}"

print_info "Next steps:"
print_info "1. Test your application on VPS"
print_info "2. Verify all data is accessible"
print_info "3. Update application configuration if needed"

print_warning "Important:"
print_warning "1. Test all functionality after loading"
print_warning "2. Monitor application logs for any issues"
print_warning "3. Consider setting up regular backups"

print_status "Database loading completed successfully! 🎉"
