#!/bin/bash

# HajiFund Database Migration Script
# This script exports data from local sharded databases and prepares for VPS deployment
# Usage: ./migrate-database.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./database-backup"
VPS_IP="103.103.20.68"
VPS_USER="root"  # Change this to your VPS username
LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="5432"
LOCAL_DB_USER="postgres"
VPS_DB_HOST="localhost"
VPS_DB_PORT="5432"
VPS_DB_USER="comfunds_user"
VPS_DB_PASSWORD="comfunds_secure_password"

# Shard names
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

echo -e "${BLUE}🚀 HajiFund Database Migration Script${NC}"
echo -e "${BLUE}====================================${NC}"

# Function to print status messages
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

# Check if required tools are installed
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command -v pg_dump &> /dev/null; then
        print_error "pg_dump is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        print_error "psql is not installed. Please install PostgreSQL client tools."
        exit 1
    fi
    
    if ! command -v ssh &> /dev/null; then
        print_error "ssh is not installed. Please install OpenSSH client."
        exit 1
    fi
    
    print_status "All dependencies are available"
}

# Create backup directory
create_backup_dir() {
    print_info "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR/schema"
    mkdir -p "$BACKUP_DIR/data"
    print_status "Backup directory created: $BACKUP_DIR"
}

# Export database schemas
export_schemas() {
    print_info "Exporting database schemas..."
    
    for shard in "${SHARDS[@]}"; do
        print_info "Exporting schema for $shard..."
        
        # Export schema only
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
                --schema-only --no-owner --no-privileges \
                -f "$BACKUP_DIR/schema/${shard}_schema.sql" \
                "$shard"
        
        print_status "Schema exported for $shard"
    done
}

# Export database data
export_data() {
    print_info "Exporting database data..."
    
    for shard in "${SHARDS[@]}"; do
        print_info "Exporting data for $shard..."
        
        # Export data only
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
                --data-only --no-owner --no-privileges \
                --disable-triggers \
                -f "$BACKUP_DIR/data/${shard}_data.sql" \
                "$shard"
        
        print_status "Data exported for $shard"
    done
}

# Create deployment script for VPS
create_vps_deployment_script() {
    print_info "Creating VPS deployment script..."
    
    cat > "$BACKUP_DIR/deploy-to-vps.sh" << 'EOF'
#!/bin/bash

# HajiFund Database Deployment Script for VPS
# This script imports the exported data to the VPS databases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./database-backup"
VPS_DB_HOST="localhost"
VPS_DB_PORT="5432"
VPS_DB_USER="comfunds_user"
VPS_DB_PASSWORD="comfunds_secure_password"

# Shard names
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

echo -e "${BLUE}🚀 HajiFund Database Deployment to VPS${NC}"
echo -e "${BLUE}=====================================${NC}"

# Function to print status messages
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

# Check if backup files exist
check_backup_files() {
    print_info "Checking backup files..."
    
    for shard in "${SHARDS[@]}"; do
        if [[ ! -f "$BACKUP_DIR/schema/${shard}_schema.sql" ]]; then
            print_error "Schema file not found: $BACKUP_DIR/schema/${shard}_schema.sql"
            exit 1
        fi
        
        if [[ ! -f "$BACKUP_DIR/data/${shard}_data.sql" ]]; then
            print_error "Data file not found: $BACKUP_DIR/data/${shard}_data.sql"
            exit 1
        fi
    done
    
    print_status "All backup files are available"
}

# Create databases if they don't exist
create_databases() {
    print_info "Creating databases..."
    
    for shard in "${SHARDS[@]}"; do
        print_info "Creating database: $shard"
        
        # Create database if it doesn't exist
        PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d postgres \
            -c "SELECT 1 FROM pg_database WHERE datname = '$shard'" | grep -q 1 || \
        PGPASSWORD="$VPS_DB_PASSWORD" createdb -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" "$shard"
        
        print_status "Database $shard is ready"
    done
}

# Import schemas
import_schemas() {
    print_info "Importing database schemas..."
    
    for shard in "${SHARDS[@]}"; do
        print_info "Importing schema for $shard..."
        
        PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
            -f "$BACKUP_DIR/schema/${shard}_schema.sql"
        
        print_status "Schema imported for $shard"
    done
}

# Import data
import_data() {
    print_info "Importing database data..."
    
    for shard in "${SHARDS[@]}"; do
        print_info "Importing data for $shard..."
        
        PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
            -f "$BACKUP_DIR/data/${shard}_data.sql"
        
        print_status "Data imported for $shard"
    done
}

# Verify import
verify_import() {
    print_info "Verifying data import..."
    
    for shard in "${SHARDS[@]}"; do
        print_info "Verifying $shard..."
        
        # Count tables
        table_count=$(PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
            -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
        
        print_status "$shard has $table_count tables"
        
        # Show some sample data counts
        if PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
            -c "\dt" > /dev/null 2>&1; then
            
            # Count users if table exists
            if PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
                -c "\d users" > /dev/null 2>&1; then
                user_count=$(PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
                    -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs || echo "0")
                print_info "  - Users: $user_count"
            fi
            
            # Count projects if table exists
            if PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
                -c "\d projects" > /dev/null 2>&1; then
                project_count=$(PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
                    -t -c "SELECT COUNT(*) FROM projects;" 2>/dev/null | xargs || echo "0")
                print_info "  - Projects: $project_count"
            fi
            
            # Count businesses if table exists
            if PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
                -c "\d businesses" > /dev/null 2>&1; then
                business_count=$(PGPASSWORD="$VPS_DB_PASSWORD" psql -h "$VPS_DB_HOST" -p "$VPS_DB_PORT" -U "$VPS_DB_USER" -d "$shard" \
                    -t -c "SELECT COUNT(*) FROM businesses;" 2>/dev/null | xargs || echo "0")
                print_info "  - Businesses: $business_count"
            fi
        fi
    done
    
    print_status "Data verification completed"
}

# Main execution
main() {
    echo -e "${BLUE}Starting database deployment to VPS...${NC}"
    
    check_backup_files
    create_databases
    import_schemas
    import_data
    verify_import
    
    echo -e "${GREEN}🎉 Database deployment completed successfully!${NC}"
    echo -e "${BLUE}Your HajiFund application data is now ready on the VPS.${NC}"
}

# Run main function
main "$@"
EOF

    chmod +x "$BACKUP_DIR/deploy-to-vps.sh"
    print_status "VPS deployment script created: $BACKUP_DIR/deploy-to-vps.sh"
}

# Create upload script
create_upload_script() {
    print_info "Creating upload script..."
    
    cat > "$BACKUP_DIR/upload-to-vps.sh" << EOF
#!/bin/bash

# HajiFund Database Upload Script
# This script uploads the backup files to the VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VPS_IP="$VPS_IP"
VPS_USER="$VPS_USER"
BACKUP_DIR="./database-backup"

echo -e "${BLUE}🚀 Uploading HajiFund Database Backup to VPS${NC}"
echo -e "${BLUE}===========================================${NC}"

# Function to print status messages
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
    print_error "Backup directory not found: $BACKUP_DIR"
    print_error "Please run the migration script first: ./migrate-database.sh"
    exit 1
fi

print_info "Uploading backup files to VPS..."
print_info "VPS: $VPS_USER@$VPS_IP"

# Create remote directory
ssh "$VPS_USER@$VPS_IP" "mkdir -p ~/hajifund-database-backup"

# Upload backup files
rsync -avz --progress "$BACKUP_DIR/" "$VPS_USER@$VPS_IP:~/hajifund-database-backup/"

print_status "Backup files uploaded successfully"

print_info "Next steps:"
echo -e "${YELLOW}1. SSH to your VPS: ssh $VPS_USER@$VPS_IP${NC}"
echo -e "${YELLOW}2. Navigate to backup directory: cd ~/hajifund-database-backup${NC}"
echo -e "${YELLOW}3. Run deployment script: ./deploy-to-vps.sh${NC}"

EOF

    chmod +x "$BACKUP_DIR/upload-to-vps.sh"
    print_status "Upload script created: $BACKUP_DIR/upload-to-vps.sh"
}

# Create README for the backup
create_readme() {
    print_info "Creating README file..."
    
    cat > "$BACKUP_DIR/README.md" << 'EOF'
# HajiFund Database Backup

This directory contains the exported database backup for HajiFund application.

## Files Structure

```
database-backup/
├── schema/                    # Database schemas
│   ├── comfunds00_schema.sql
│   ├── comfunds01_schema.sql
│   ├── comfunds02_schema.sql
│   └── comfunds03_schema.sql
├── data/                      # Database data
│   ├── comfunds00_data.sql
│   ├── comfunds01_data.sql
│   ├── comfunds02_data.sql
│   └── comfunds03_data.sql
├── deploy-to-vps.sh          # VPS deployment script
├── upload-to-vps.sh          # Upload script
└── README.md                 # This file
```

## Deployment Steps

### 1. Upload to VPS
```bash
./upload-to-vps.sh
```

### 2. Deploy on VPS
SSH to your VPS and run:
```bash
cd ~/hajifund-database-backup
./deploy-to-vps.sh
```

## Manual Deployment (Alternative)

If the automated scripts don't work, you can manually import the data:

### 1. Create databases on VPS
```bash
sudo -u postgres createdb comfunds00
sudo -u postgres createdb comfunds01
sudo -u postgres createdb comfunds02
sudo -u postgres createdb comfunds03
```

### 2. Import schemas
```bash
for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
    PGPASSWORD="your_password" psql -h localhost -U comfunds_user -d $shard -f schema/${shard}_schema.sql
done
```

### 3. Import data
```bash
for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
    PGPASSWORD="your_password" psql -h localhost -U comfunds_user -d $shard -f data/${shard}_data.sql
done
```

## Troubleshooting

### Permission Issues
Make sure the PostgreSQL user has the necessary permissions:
```bash
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds00 TO comfunds_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds01 TO comfunds_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds02 TO comfunds_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE comfunds03 TO comfunds_user;"
```

### Connection Issues
Verify PostgreSQL is running and accessible:
```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

### File Not Found
Make sure all backup files are present:
```bash
ls -la schema/
ls -la data/
```

## Support

If you encounter issues:
1. Check the PostgreSQL logs: `sudo journalctl -u postgresql -f`
2. Verify database permissions
3. Check network connectivity between local machine and VPS
4. Ensure all required tools are installed on the VPS

EOF

    print_status "README file created: $BACKUP_DIR/README.md"
}

# Main execution function
main() {
    echo -e "${BLUE}Starting database migration...${NC}"
    
    check_dependencies
    create_backup_dir
    export_schemas
    export_data
    create_vps_deployment_script
    create_upload_script
    create_readme
    
    echo -e "${GREEN}🎉 Database migration completed successfully!${NC}"
    echo -e "${BLUE}==============================================${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${YELLOW}1. Review the backup files in: $BACKUP_DIR${NC}"
    echo -e "${YELLOW}2. Upload to VPS: ./$BACKUP_DIR/upload-to-vps.sh${NC}"
    echo -e "${YELLOW}3. Deploy on VPS: SSH to VPS and run ./deploy-to-vps.sh${NC}"
    echo -e "${BLUE}==============================================${NC}"
}

# Run main function
main "$@"
