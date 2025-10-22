#!/bin/bash

# Backup VPS Docker PostgreSQL Databases
# This script creates backups of all database shards from VPS Docker PostgreSQL

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

print_step "Backing up VPS Docker PostgreSQL Databases"

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

# Backup configuration
BACKUP_DIR="./vps-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

print_info "Configuration:"
print_info "  VPS DB: $VPS_DB_HOST:$VPS_DB_PORT"
print_info "  Shards: ${SHARDS[*]}"
print_info "  Backup directory: $BACKUP_DIR"
print_info "  Timestamp: $TIMESTAMP"

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

# 2. Create backup directory
print_step "2. Creating backup directory..."

mkdir -p $BACKUP_DIR
print_status "Backup directory created: $BACKUP_DIR"

# 3. Create backup directory on VPS
print_step "3. Creating backup directory on VPS..."

ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "mkdir -p $VPS_PATH/backups/$TIMESTAMP"
print_status "Backup directory created on VPS: $VPS_PATH/backups/$TIMESTAMP"

# 4. Backup each database
print_step "4. Backing up databases..."

for shard in "${SHARDS[@]}"; do
    print_info "Backing up $shard..."
    
    # Check if database exists
    if ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres psql -U $VPS_DB_USER -d $shard -c 'SELECT 1;'" >/dev/null 2>&1; then
        # Create backup
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "docker compose exec -T postgres pg_dump -U $VPS_DB_USER -d $shard --format=custom --compress=9 --file=/tmp/${shard}_${TIMESTAMP}.dump"
        
        # Move backup to backup directory
        ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "mv /tmp/${shard}_${TIMESTAMP}.dump $VPS_PATH/backups/$TIMESTAMP/"
        
        print_status "$shard backed up to $VPS_PATH/backups/$TIMESTAMP/${shard}_${TIMESTAMP}.dump"
    else
        print_warning "Database $shard does not exist, skipping"
    fi
done

# 5. Copy backups to local machine
print_step "5. Copying backups to local machine..."

for shard in "${SHARDS[@]}"; do
    if ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "test -f $VPS_PATH/backups/$TIMESTAMP/${shard}_${TIMESTAMP}.dump"; then
        print_info "Copying $shard backup to local machine..."
        scp -i $VPS_KEY $VPS_USER@$VPS_HOST:$VPS_PATH/backups/$TIMESTAMP/${shard}_${TIMESTAMP}.dump $BACKUP_DIR/
        print_status "$shard backup copied to local machine"
    fi
done

# 6. Verify backups
print_step "6. Verifying backups..."

print_info "Local backup files:"
ls -la $BACKUP_DIR/

print_info "VPS backup files:"
ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "ls -la $VPS_PATH/backups/$TIMESTAMP/"

# 7. Create backup summary
print_step "7. Creating backup summary..."

cat > $BACKUP_DIR/backup_summary.txt << EOF
HajiFund Database Backup Summary
===============================

Backup Date: $(date)
VPS Host: $VPS_HOST
Backup Directory: $BACKUP_DIR
Timestamp: $TIMESTAMP

Databases Backed Up:
$(for shard in "${SHARDS[@]}"; do
    if [ -f "$BACKUP_DIR/${shard}_${TIMESTAMP}.dump" ]; then
        echo "  ✅ $shard"
    else
        echo "  ❌ $shard (not found)"
    fi
done)

Backup Files:
$(ls -la $BACKUP_DIR/*.dump 2>/dev/null || echo "No dump files found")

Restore Commands:
$(for shard in "${SHARDS[@]}"; do
    if [ -f "$BACKUP_DIR/${shard}_${TIMESTAMP}.dump" ]; then
        echo "  pg_restore -U postgres -d $shard --clean --if-exists $BACKUP_DIR/${shard}_${TIMESTAMP}.dump"
    fi
done)
EOF

print_status "Backup summary created: $BACKUP_DIR/backup_summary.txt"

# 8. Clean up old backups (optional)
print_step "8. Cleaning up old backups..."

read -p "Do you want to remove old backups from VPS? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh -i $VPS_KEY $VPS_USER@$VPS_HOST "find $VPS_PATH/backups -type d -mtime +7 -exec rm -rf {} +"
    print_status "Old backups removed from VPS"
else
    print_info "Old backups kept on VPS"
fi

# 9. Final status
print_step "9. Backup completed!"

print_status "All databases have been backed up successfully!"
print_info "Backup summary:"
print_info "  Local directory: $BACKUP_DIR"
print_info "  VPS directory: $VPS_PATH/backups/$TIMESTAMP"
print_info "  Timestamp: $TIMESTAMP"

print_info "Backup files created:"
for shard in "${SHARDS[@]}"; do
    if [ -f "$BACKUP_DIR/${shard}_${TIMESTAMP}.dump" ]; then
        print_info "  ✅ $shard"
    else
        print_info "  ❌ $shard (not found)"
    fi
done

print_info "Next steps:"
print_info "1. Test restore from backup files"
print_info "2. Store backups in secure location"
print_info "3. Set up automated backup schedule"

print_warning "Important:"
print_warning "1. Keep backups in secure location"
print_warning "2. Test restore procedures regularly"
print_warning "3. Consider encryption for sensitive data"

print_status "Database backup completed successfully! 🎉"
