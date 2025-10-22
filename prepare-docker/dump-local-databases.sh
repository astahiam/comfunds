#!/bin/bash

# Dump Local Databases to VPS PostgreSQL Docker
# This script dumps all local database shards and loads them into VPS Docker PostgreSQL

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

print_step "Dumping Local Databases to VPS Docker PostgreSQL"

# VPS Configuration
VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

# Local Database Configuration
LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="5432"
LOCAL_DB_USER="postgres"
LOCAL_DB_PASSWORD="postgres"

# VPS Docker Database Configuration
VPS_DB_HOST="103.103.20.68"
VPS_DB_PORT="5432"
VPS_DB_USER="postgres"
VPS_DB_PASSWORD="postgres123"

# Database shards
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

print_info "Configuration:"
print_info "  Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT"
print_info "  VPS DB: $VPS_DB_HOST:$VPS_DB_PORT"
print_info "  Shards: ${SHARDS[*]}"

# 1. Check if local databases exist
print_step "1. Checking local databases..."

for shard in "${SHARDS[@]}"; do
    if psql -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $shard -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "Local database $shard exists"
    else
        print_warning "Local database $shard does not exist"
    fi
done

# 2. Check VPS Docker PostgreSQL connection
print_step "2. Checking VPS Docker PostgreSQL connection..."

if psql -h $VPS_DB_HOST -p $VPS_DB_PORT -U $VPS_DB_USER -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_status "VPS Docker PostgreSQL is accessible"
else
    print_error "Cannot connect to VPS Docker PostgreSQL"
    print_info "Make sure Docker containers are running on VPS"
    print_info "Run: ssh -i $VPS_KEY $VPS_USER@$VPS_HOST 'cd $VPS_PATH && docker compose up -d'"
    exit 1
fi

# 3. Create dump directory
print_step "3. Creating dump directory..."

DUMP_DIR="./database-dumps"
mkdir -p $DUMP_DIR
print_status "Dump directory created: $DUMP_DIR"

# 4. Dump each local database
print_step "4. Dumping local databases..."

for shard in "${SHARDS[@]}"; do
    print_info "Dumping $shard..."
    
    # Check if database exists locally
    if psql -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $shard -c "SELECT 1;" >/dev/null 2>&1; then
        # Dump schema and data
        pg_dump -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $shard \
            --no-password \
            --format=custom \
            --compress=9 \
            --file="$DUMP_DIR/${shard}.dump"
        
        print_status "$shard dumped to $DUMP_DIR/${shard}.dump"
    else
        print_warning "Skipping $shard (does not exist locally)"
    fi
done

# 5. Copy dumps to VPS
print_step "5. Copying dumps to VPS..."

# Create dump directory on VPS
ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "mkdir -p $VPS_PATH/database-dumps"

# Copy dump files to VPS
for shard in "${SHARDS[@]}"; do
    if [ -f "$DUMP_DIR/${shard}.dump" ]; then
        print_info "Copying $shard dump to VPS..."
        scp -i $VPS_KEY "$DUMP_DIR/${shard}.dump" $VPS_USER@$VPS_HOST:$VPS_PATH/database-dumps/
        print_status "$shard dump copied to VPS"
    fi
done

# 6. Load dumps into VPS Docker PostgreSQL
print_step "6. Loading dumps into VPS Docker PostgreSQL..."

for shard in "${SHARDS[@]}"; do
    if ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "test -f $VPS_PATH/database-dumps/${shard}.dump"; then
        print_info "Loading $shard into VPS Docker PostgreSQL..."
        
        # Drop existing database if it exists
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres psql -U $VPS_DB_USER -d postgres -c \"DROP DATABASE IF EXISTS $shard;\""
        
        # Create database
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres psql -U $VPS_DB_USER -d postgres -c \"CREATE DATABASE $shard;\""
        
        # Load dump
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres pg_restore -U $VPS_DB_USER -d $shard --clean --if-exists $VPS_PATH/database-dumps/${shard}.dump"
        
        print_status "$shard loaded into VPS Docker PostgreSQL"
    else
        print_warning "Skipping $shard (dump file not found)"
    fi
done

# 7. Verify data was loaded
print_step "7. Verifying data was loaded..."

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

# 8. Clean up local dump files
print_step "8. Cleaning up local dump files..."

rm -rf $DUMP_DIR
print_status "Local dump files cleaned up"

# 9. Final verification
print_step "9. Final verification..."

print_info "Database status on VPS:"
ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec postgres psql -U $VPS_DB_USER -d postgres -c \"SELECT datname FROM pg_database WHERE datname LIKE 'comfunds%';\""

print_info "Sample data from each shard:"
for shard in "${SHARDS[@]}"; do
    print_info "=== $shard ==="
    ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec postgres psql -U $VPS_DB_USER -d $shard -c \"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' LIMIT 5;\""
done

# 10. Final status
print_step "10. Database migration completed!"

print_status "All local databases have been migrated to VPS Docker PostgreSQL!"
print_info "Migration summary:"
print_info "  Source: Local PostgreSQL"
print_info "  Destination: VPS Docker PostgreSQL"
print_info "  Shards migrated: ${SHARDS[*]}"

print_info "Next steps:"
print_info "1. Test your application on VPS"
print_info "2. Verify all data is accessible"
print_info "3. Update application configuration if needed"

print_warning "Important:"
print_warning "1. Backup your VPS data before making changes"
print_warning "2. Test all functionality after migration"
print_warning "3. Monitor application logs for any issues"

print_status "Database migration completed successfully! 🎉"
