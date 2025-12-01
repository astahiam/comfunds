#!/bin/bash

# HajiFund Data Migration Script
# This script dumps data from local PostgreSQL and loads it into VPS

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

# Configuration
LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="5432"
LOCAL_DB_USER="postgres"
LOCAL_DB_PASSWORD="postgres"

VPS_IP="103.103.20.68"
VPS_SSH_USER="ryankharisma"
VPS_SSH_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_DB_HOST="localhost"  # DB is on localhost from VPS perspective
VPS_DB_PORT="5432"
VPS_DB_USER="postgres"
VPS_DB_PASSWORD="postgres"

# Database shards
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Backup directory
BACKUP_DIR="./database_backup_$(date +%Y%m%d_%H%M%S)"

print_step "HajiFund Data Migration Script"
print_info "Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT"
print_info "VPS SSH: $VPS_SSH_USER@$VPS_IP"
print_info "VPS DB: $VPS_DB_HOST:$VPS_DB_PORT"
print_info "Backup Directory: $BACKUP_DIR"

# Function to execute SQL command on local DB
execute_local_sql() {
    local sql="$1"
    local db_name="$2"
    
    if [ -n "$db_name" ]; then
        PGPASSWORD="$LOCAL_DB_PASSWORD" psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$db_name" -c "$sql"
    else
        PGPASSWORD="$LOCAL_DB_PASSWORD" psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -c "$sql"
    fi
}

# Function to execute SQL command on VPS DB
execute_vps_sql() {
    local sql="$1"
    local db_name="$2"
    
    if [ -n "$db_name" ]; then
        PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$db_name" -c "$sql"
    else
        PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -c "$sql"
    fi
}

# Function to check if database exists
database_exists() {
    local db_name="$1"
    local host="$2"
    local user="$3"
    local password="$4"
    
    PGPASSWORD="$password" psql -h "$host" -p "$VPS_DB_PORT" -U "$user" -lqt | cut -d \| -f 1 | grep -qw "$db_name"
}

# 1. Create backup directory
print_step "1. Creating backup directory..."
mkdir -p "$BACKUP_DIR"
print_status "Backup directory created: $BACKUP_DIR"

# 2. Test local database connection
print_step "2. Testing local database connection..."
if PGPASSWORD="$LOCAL_DB_PASSWORD" psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "Local database connection: OK"
else
    print_error "Cannot connect to local database"
    print_info "Please check your local PostgreSQL is running and credentials are correct"
    exit 1
fi

# 3. Test VPS SSH connection
print_step "3. Testing VPS SSH connection..."
if ssh -i "$VPS_SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPS_SSH_USER@$VPS_IP" "echo 'SSH connection successful'" > /dev/null 2>&1; then
    print_status "VPS SSH connection: OK"
else
    print_error "Cannot connect to VPS via SSH"
    print_info "Please check your SSH key and credentials"
    print_info "SSH command: ssh -i $VPS_SSH_KEY $VPS_SSH_USER@$VPS_IP"
    exit 1
fi

# 4. Test VPS database connection
print_step "4. Testing VPS database connection..."
if ssh -i "$VPS_SSH_KEY" -o ConnectTimeout=10 "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -c 'SELECT 1;'" > /dev/null 2>&1; then
    print_status "VPS database connection: OK"
else
    print_error "Cannot connect to VPS database"
    print_info "Please check your VPS PostgreSQL is running and credentials are correct"
    exit 1
fi

# 5. Dump data from local databases
print_step "5. Dumping data from local databases..."

for shard in "${SHARDS[@]}"; do
    print_info "Dumping data from $shard..."
    
    # Check if local database exists
    if database_exists "$shard" "$LOCAL_DB_HOST" "$LOCAL_DB_USER" "$LOCAL_DB_PASSWORD"; then
        # Dump schema and data
        PGPASSWORD="$LOCAL_DB_PASSWORD" pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password --verbose --clean --if-exists --create \
            --format=plain --file="$BACKUP_DIR/${shard}_schema_and_data.sql" "$shard"
        
        # Dump data only (for loading)
        PGPASSWORD="$LOCAL_DB_PASSWORD" pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password --verbose --data-only --disable-triggers \
            --format=plain --file="$BACKUP_DIR/${shard}_data_only.sql" "$shard"
        
        print_status "Dumped $shard successfully"
    else
        print_warning "Database $shard does not exist locally, skipping..."
    fi
done

# 6. Create databases on VPS if they don't exist
print_step "6. Creating databases on VPS..."

for shard in "${SHARDS[@]}"; do
    print_info "Checking/Creating database $shard on VPS..."
    
    if ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -lqt | cut -d \| -f 1 | grep -qw '$shard'"; then
        print_status "Database $shard already exists on VPS"
    else
        print_info "Creating database $shard on VPS..."
        ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -c 'CREATE DATABASE $shard;'"
        print_status "Database $shard created on VPS"
    fi
done

# 7. Load schema and data to VPS
print_step "7. Loading data to VPS databases..."

for shard in "${SHARDS[@]}"; do
    if [ -f "$BACKUP_DIR/${shard}_data_only.sql" ]; then
        print_info "Loading data to $shard on VPS..."
        
        # Copy the SQL file to VPS
        scp -i "$VPS_SSH_KEY" "$BACKUP_DIR/${shard}_data_only.sql" "$VPS_SSH_USER@$VPS_IP:/tmp/"
        
        # Load data on VPS
        ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -f /tmp/${shard}_data_only.sql"
        
        print_status "Data loaded to $shard on VPS"
    else
        print_warning "No data file found for $shard, skipping..."
    fi
done

# 8. Verify data migration
print_step "8. Verifying data migration..."

for shard in "${SHARDS[@]}"; do
    if ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -lqt | cut -d \| -f 1 | grep -qw '$shard'"; then
        print_info "Verifying $shard..."
        
        # Count tables
        table_count=$(ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';\"" | grep -o '[0-9]*' | head -1)
        print_info "  Tables in $shard: $table_count"
        
        # Count users if table exists
        if ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public';\"" | grep -q "1"; then
            user_count=$(ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT COUNT(*) FROM users;\"" | grep -o '[0-9]*' | head -1)
            print_info "  Users in $shard: $user_count"
        fi
        
        # Count projects if table exists
        if ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT 1 FROM information_schema.tables WHERE table_name = 'projects' AND table_schema = 'public';\"" | grep -q "1"; then
            project_count=$(ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT COUNT(*) FROM projects;\"" | grep -o '[0-9]*' | head -1)
            print_info "  Projects in $shard: $project_count"
        fi
        
        # Count businesses if table exists
        if ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT 1 FROM information_schema.tables WHERE table_name = 'businesses' AND table_schema = 'public';\"" | grep -q "1"; then
            business_count=$(ssh -i "$VPS_SSH_KEY" "$VPS_SSH_USER@$VPS_IP" "PGPASSWORD='$VPS_DB_PASSWORD' psql -h localhost -p $VPS_DB_PORT -U $VPS_DB_USER -d $shard -c \"SELECT COUNT(*) FROM businesses;\"" | grep -o '[0-9]*' | head -1)
            print_info "  Businesses in $shard: $business_count"
        fi
    fi
done

# 9. Create a summary report
print_step "9. Creating migration summary..."

cat > "$BACKUP_DIR/migration_summary.txt" << EOF
HajiFund Data Migration Summary
===============================
Date: $(date)
Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT
VPS DB: $VPS_DB_HOST:$VPS_DB_PORT

Databases Migrated:
EOF

for shard in "${SHARDS[@]}"; do
    if [ -f "$BACKUP_DIR/${shard}_data_only.sql" ]; then
        echo "- $shard: ✅ Migrated" >> "$BACKUP_DIR/migration_summary.txt"
    else
        echo "- $shard: ❌ Skipped (no data)" >> "$BACKUP_DIR/migration_summary.txt"
    fi
done

echo "" >> "$BACKUP_DIR/migration_summary.txt"
echo "Backup Files:" >> "$BACKUP_DIR/migration_summary.txt"
ls -la "$BACKUP_DIR" >> "$BACKUP_DIR/migration_summary.txt"

print_status "Migration summary created: $BACKUP_DIR/migration_summary.txt"

# 9. Create a script to load data on VPS
print_step "9. Creating VPS data loading script..."

cat > "$BACKUP_DIR/load_data_on_vps.sh" << 'EOF'
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
EOF

chmod +x "$BACKUP_DIR/load_data_on_vps.sh"
print_status "VPS loading script created: $BACKUP_DIR/load_data_on_vps.sh"

print_status "Data migration completed successfully!"
print_info "Summary:"
print_info "  - Backup directory: $BACKUP_DIR"
print_info "  - Data files: ${SHARDS[*]}"
print_info "  - VPS loading script: $BACKUP_DIR/load_data_on_vps.sh"
print_info ""
print_info "Next steps:"
print_info "1. Copy the backup directory to your VPS:"
print_info "   scp -i $VPS_SSH_KEY -r $BACKUP_DIR $VPS_SSH_USER@$VPS_IP:/home/$VPS_SSH_USER/"
print_info ""
print_info "2. SSH into your VPS and run the loading script:"
print_info "   ssh -i $VPS_SSH_KEY $VPS_SSH_USER@$VPS_IP"
print_info "   cd $BACKUP_DIR"
print_info "   sudo ./load_data_on_vps.sh"
print_info ""
print_info "3. Alternative: The data has already been loaded automatically!"
print_info "   Your VPS databases should now contain all your local data."
