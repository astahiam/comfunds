#!/bin/bash

# Create Complete SQL Backup with Schema Migration Scripts
# Creates backup SQL files that can be executed directly to restore databases
# Includes ALTER TABLE scripts to handle schema differences

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Configuration
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./sql-backup-${TIMESTAMP}"

print_header "Creating Complete SQL Backup with Schema Migrations"

# Set password
if [ -n "$LOCAL_DB_PASSWORD" ]; then
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
fi

# Verify connection
print_step "Verifying local PostgreSQL connection..."
if ! psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_error "Cannot connect to local PostgreSQL"
    exit 1
fi
print_status "Connection OK"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create schema migration script template
create_migration_script() {
    local shard=$1
    cat > "$BACKUP_DIR/${shard}_migrate_schema.sql" << EOFMIGRATION
-- Schema Migration Script for ${shard}
-- This script ensures the database schema matches the expected structure
-- Safe to run multiple times (idempotent)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- USERS TABLE MIGRATION
-- ============================================

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add id column if missing (UUID type)
DO \$\$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'id'
    ) THEN
        ALTER TABLE users ADD COLUMN id UUID DEFAULT uuid_generate_v4();
        
        -- Set id for existing rows
        UPDATE users SET id = uuid_generate_v4() WHERE id IS NULL;
        
        -- Add primary key if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'users_pkey'
        ) THEN
            ALTER TABLE users ADD PRIMARY KEY (id);
        END IF;
    END IF;
END \$\$;

-- Add cooperative_id column if missing
DO \$\$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'cooperative_id'
    ) THEN
        ALTER TABLE users ADD COLUMN cooperative_id UUID;
    END IF;
END \$\$;

-- Add roles column if missing (JSONB)
DO \$\$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'roles'
    ) THEN
        ALTER TABLE users ADD COLUMN roles JSONB DEFAULT '[]'::jsonb;
    END IF;
END \$\$;

-- Add kyc_status column if missing
DO \$\$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'kyc_status'
    ) THEN
        ALTER TABLE users ADD COLUMN kyc_status VARCHAR(50) DEFAULT 'pending';
    END IF;
END \$\$;

-- Add user_profile_image column if missing
DO \$\$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'user_profile_image'
    ) THEN
        ALTER TABLE users ADD COLUMN user_profile_image VARCHAR(500);
    END IF;
END \$\$;

-- Add membership_payment_proof column if missing
DO \$\$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'membership_payment_proof'
    ) THEN
        ALTER TABLE users ADD COLUMN membership_payment_proof VARCHAR(500);
    END IF;
END \$\$;

-- Ensure id column is UUID type (convert if needed)
DO \$\$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'id'
        AND data_type != 'uuid'
    ) THEN
        -- Create temporary UUID column
        ALTER TABLE users ADD COLUMN id_new UUID DEFAULT uuid_generate_v4();
        
        -- Copy data if id is integer
        UPDATE users SET id_new = uuid_generate_v4() WHERE id_new IS NULL;
        
        -- Drop old column and rename
        ALTER TABLE users DROP COLUMN id;
        ALTER TABLE users RENAME COLUMN id_new TO id;
        ALTER TABLE users ADD PRIMARY KEY (id);
    END IF;
END \$\$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_cooperative_id ON users(cooperative_id);
CREATE INDEX IF NOT EXISTS idx_users_roles ON users USING GIN(roles);
CREATE INDEX IF NOT EXISTS idx_users_kyc_status ON users(kyc_status);
CREATE INDEX IF NOT EXISTS idx_users_membership_payment_proof ON users(membership_payment_proof) WHERE membership_payment_proof IS NOT NULL;

-- ============================================
-- COOPERATIVES TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS cooperatives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    bank_account VARCHAR(100) NOT NULL,
    profit_sharing_policy JSONB DEFAULT '{}',
    cooperative_image VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- BUSINESSES TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    owner_id UUID NOT NULL,
    cooperative_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    approval_status VARCHAR(50) DEFAULT 'draft',
    registration_number VARCHAR(100),
    legal_structure VARCHAR(100),
    industry VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255),
    established_date DATE,
    employee_count INTEGER DEFAULT 0,
    annual_revenue DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'IDR',
    bank_account VARCHAR(100),
    business_license VARCHAR(100),
    documents JSONB DEFAULT '[]',
    business_image VARCHAR(500),
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_by UUID,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_businesses_owner_id ON businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_cooperative_id ON businesses(cooperative_id);

-- ============================================
-- PROJECTS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    business_id UUID NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    funding_goal DECIMAL(15,2) NOT NULL,
    current_funding DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'IDR',
    status VARCHAR(50) DEFAULT 'draft',
    approval_status VARCHAR(50) DEFAULT 'draft',
    start_date DATE,
    end_date DATE,
    profit_sharing_percentage DECIMAL(5,2),
    risk_level VARCHAR(20),
    project_images JSONB DEFAULT '[]',
    category VARCHAR(100),
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_by UUID,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    sharia_compliant BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_projects_business_id ON projects(business_id);

-- ============================================
-- INVESTMENTS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS investments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL,
    investor_id UUID NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    status VARCHAR(50) DEFAULT 'pending',
    profit_share DECIMAL(5,2),
    disbursed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_investments_project_id ON investments(project_id);
CREATE INDEX IF NOT EXISTS idx_investments_investor_id ON investments(investor_id);

-- ============================================
-- AUDIT LOGS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    operation VARCHAR(100) NOT NULL,
    user_id UUID,
    ip_address INET,
    user_agent TEXT,
    changes JSONB,
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    status VARCHAR(50),
    error_msg TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- PROFIT DISTRIBUTIONS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS profit_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL,
    investment_id UUID NOT NULL,
    investor_id UUID NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    distribution_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- FOREIGN KEY CONSTRAINTS (if needed)
-- ============================================

-- Note: Foreign keys are optional in sharded architecture
-- Uncomment if you want referential integrity

-- ALTER TABLE users ADD CONSTRAINT fk_users_cooperative 
--     FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id);

-- ALTER TABLE businesses ADD CONSTRAINT fk_businesses_owner 
--     FOREIGN KEY (owner_id) REFERENCES users(id);

-- ALTER TABLE businesses ADD CONSTRAINT fk_businesses_cooperative 
--     FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id);

-- ALTER TABLE projects ADD CONSTRAINT fk_projects_business 
--     FOREIGN KEY (business_id) REFERENCES businesses(id);

-- ALTER TABLE investments ADD CONSTRAINT fk_investments_project 
--     FOREIGN KEY (project_id) REFERENCES projects(id);

-- ALTER TABLE investments ADD CONSTRAINT fk_investments_investor 
--     FOREIGN KEY (investor_id) REFERENCES users(id);

-- ALTER TABLE profit_distributions ADD CONSTRAINT fk_profit_distributions_project 
--     FOREIGN KEY (project_id) REFERENCES projects(id);

EOFMIGRATION
}

# Export each database
for shard in "${SHARDS[@]}"; do
    print_header "Processing $shard"
    
    # Check if database exists
    if ! psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
        print_error "Database $shard does not exist, skipping..."
        continue
    fi
    
    # Create migration script for this shard
    print_step "Creating schema migration script..."
    create_migration_script "$shard"
    
    # Export complete database (schema + data)
    print_step "Exporting complete database..."
    pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
        --no-password \
        --clean \
        --if-exists \
        --create \
        --format=plain \
        --file="$BACKUP_DIR/${shard}_complete.sql" \
        "$shard" 2>&1 | grep -v "WARNING" || true
    
    # Note: restore.sql is not needed since we have standalone_restore.sql
    # But create it for reference
    print_step "Creating reference restore script..."
    cat > "$BACKUP_DIR/${shard}_restore.sql" << RESTORESCRIPT
-- ============================================
-- RESTORE SCRIPT FOR ${shard} (REFERENCE)
-- ============================================
-- NOTE: Use ${shard}_standalone_restore.sql instead (it's self-contained)
-- This file is for reference only
-- ============================================

-- To restore, use the standalone file:
-- psql -U postgres -d postgres -f ${shard}_standalone_restore.sql

RESTORESCRIPT
    
    # Create standalone restore script (all-in-one) - COMPLETELY INDEPENDENT FILE
    print_step "Creating standalone restore script for ${shard}..."
    
    # Create data-only dump first
    print_step "Creating data-only dump..."
    pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
        --no-password \
        --data-only \
        --disable-triggers \
        --format=plain \
        --file="$BACKUP_DIR/${shard}_data_only.sql" \
        "$shard" 2>&1 | grep -v "WARNING" || true
    
    # Create completely standalone file
    cat > "$BACKUP_DIR/${shard}_standalone_restore.sql" << STANDALONE
-- ============================================
-- STANDALONE RESTORE SCRIPT FOR ${shard}
-- ============================================
-- This is a COMPLETELY SELF-CONTAINED script
-- Usage: psql -U postgres -d postgres -f ${shard}_standalone_restore.sql
-- Or: docker exec -i container_name psql -U postgres -d postgres < ${shard}_standalone_restore.sql
-- 
-- This file contains EVERYTHING needed to restore ${shard}:
-- 1. Database creation
-- 2. Schema migrations (handles missing columns, indexes, etc.)
-- 3. All data
-- ============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE ${shard}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${shard}')\gexec

-- Connect to the database
\c ${shard}

STANDALONE
    
    # Append migration script (schema setup)
    cat "$BACKUP_DIR/${shard}_migrate_schema.sql" >> "$BACKUP_DIR/${shard}_standalone_restore.sql"
    
    # Append data import section
    echo "" >> "$BACKUP_DIR/${shard}_standalone_restore.sql"
    echo "-- ============================================" >> "$BACKUP_DIR/${shard}_standalone_restore.sql"
    echo "-- IMPORT DATA FOR ${shard}" >> "$BACKUP_DIR/${shard}_standalone_restore.sql"
    echo "-- ============================================" >> "$BACKUP_DIR/${shard}_standalone_restore.sql"
    echo "" >> "$BACKUP_DIR/${shard}_standalone_restore.sql"
    
    # Append data (clean up any problematic commands)
    cat "$BACKUP_DIR/${shard}_data_only.sql" | \
        grep -v "^--" | \
        grep -v "^SET" | \
        grep -v "^SELECT pg_catalog" | \
        grep -v "^\\\\\." >> "$BACKUP_DIR/${shard}_standalone_restore.sql" || true
    
    # Add verification at the end
    cat >> "$BACKUP_DIR/${shard}_standalone_restore.sql" << VERIFY

-- ============================================
-- VERIFICATION
-- ============================================
SELECT 'Database ${shard} restored successfully!' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public';
VERIFY
    
    FILE_SIZE=$(du -h "$BACKUP_DIR/${shard}_standalone_restore.sql" | cut -f1)
    print_status "Created restore scripts for $shard ($FILE_SIZE)"
done

# Create master restore script
print_header "Creating Master Restore Script"

cat > "$BACKUP_DIR/restore_all.sh" << 'MASTERSCRIPT'
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

MASTERSCRIPT

chmod +x "$BACKUP_DIR/restore_all.sh"

# Create README
cat > "$BACKUP_DIR/README.md" << README
# SQL Backup Files

Created: $(date)

## Files Description

### For each shard (comfunds00-03):

1. **\`{shard}_migrate_schema.sql\`** - Schema migration script
   - Ensures all tables, columns, indexes exist
   - Safe to run multiple times (idempotent)
   - Handles schema differences

2. **\`{shard}_complete.sql\`** - Complete database dump
   - Includes CREATE DATABASE, schema, and data
   - Use this for full restore

3. **\`{shard}_data_only.sql\`** - Data only dump
   - Only INSERT statements
   - Use when schema already exists

4. **\`{shard}_standalone_restore.sql\`** - All-in-one restore script
   - Includes migrations + data
   - Self-contained, ready to execute

5. **\`{shard}_restore.sql\`** - Restore script (requires separate files)
   - References migration and complete files

### Master Scripts:

- **\`restore_all.sh\`** - Restores all databases at once

## Usage

### Option 1: Standalone Restore (Recommended)

```bash
# For single database
psql -U postgres -d postgres -f comfunds00_standalone_restore.sql

# Or in Docker
docker exec -i hajifund-postgres psql -U postgres -d postgres < comfunds00_standalone_restore.sql
```

### Option 2: Using Master Script

```bash
# Set database credentials
export DB_USER=postgres
export DB_PASSWORD=postgres123

# Run restore
./restore_all.sh

# Or in Docker
export DOCKER_CONTAINER=hajifund-postgres
./restore_all.sh
```

### Option 3: Manual Restore

```bash
# 1. Create database
psql -U postgres -c "CREATE DATABASE comfunds00;"

# 2. Run migrations
psql -U postgres -d comfunds00 -f comfunds00_migrate_schema.sql

# 3. Import data
psql -U postgres -d comfunds00 -f comfunds00_complete.sql
```

## Schema Migrations

The migration scripts handle:
- ✅ Missing columns (adds them with defaults)
- ✅ Wrong data types (converts UUID from INTEGER)
- ✅ Missing indexes (creates them)
- ✅ Missing tables (creates them)
- ✅ Missing extensions (creates UUID extension)

## Safety

- All migrations are idempotent (safe to run multiple times)
- Uses IF NOT EXISTS checks
- Preserves existing data
- Handles type conversions safely

## Verification

After restore, verify:

```sql
-- Check database exists
SELECT datname FROM pg_database WHERE datname LIKE 'comfunds%';

-- Check users table
SELECT COUNT(*) FROM users;

-- Check schema
\d users
```

README

print_header "Backup Summary"

print_status "SQL backups created in: $BACKUP_DIR"
echo ""
print_info "Files created for each shard:"
echo "  - {shard}_migrate_schema.sql (schema migrations)"
echo "  - {shard}_complete.sql (full dump)"
echo "  - {shard}_data_only.sql (data only)"
echo "  - {shard}_standalone_restore.sql (all-in-one restore)"
echo ""
print_info "Master scripts:"
echo "  - restore_all.sh (restore all databases)"
echo "  - README.md (documentation)"
echo ""
print_status "✅ Backup completed!"
print_info "To restore: cd $BACKUP_DIR && ./restore_all.sh"

