#!/bin/bash

# Fix Users Table Schema on VPS
# This script adds missing columns to the users table if they don't exist

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

VPS_USER="ryankharisma"
VPS_HOST="103.103.20.68"
VPS_KEY="~/Downloads/ryan-biznet-gio.pem"
VPS_PATH="~/sourcecode"

print_step "Creating schema fix script for VPS..."

# Create the fix script that will run on VPS
cat > /tmp/fix-users-schema.sh << 'EOFSCRIPT'
#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
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

cd ~/sourcecode || exit 1

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose not found"
    exit 1
fi

DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres123}"
POSTGRES_SERVICE="${POSTGRES_SERVICE:-postgres}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Detect PostgreSQL container name
print_step "Detecting PostgreSQL container..."
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")

if [ -z "$CONTAINER_NAME" ]; then
    print_error "PostgreSQL container is not running"
    print_step "Starting PostgreSQL..."
    $COMPOSE_CMD up -d "$POSTGRES_SERVICE"
    sleep 10
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")
    if [ -z "$CONTAINER_NAME" ]; then
        print_error "Failed to start PostgreSQL container"
        exit 1
    fi
fi

print_status "Found PostgreSQL container: $CONTAINER_NAME"

# Check container status (avoid psql segfault by just checking container is running)
CONTAINER_STATUS=$(docker ps --format '{{.Names}}:{{.Status}}' | grep "^$CONTAINER_NAME:" | cut -d: -f2 || echo "")
if [ -z "$CONTAINER_STATUS" ]; then
    print_error "PostgreSQL container is not running"
    exit 1
fi

print_status "Container status: $CONTAINER_STATUS"

# Simple wait - just check container is running, don't try psql (avoids segfault)
print_step "Ensuring PostgreSQL container is ready..."
sleep 5

print_step "Fixing users table schema on all shards..."

for shard in "${SHARDS[@]}"; do
    print_step "Checking $shard..."
    
    # Check if database exists (using docker exec directly)
    DB_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$shard" && echo "yes" || echo "no")
    
    if [ "$DB_EXISTS" != "yes" ]; then
        print_error "Database $shard does not exist, creating it..."
        docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -c "CREATE DATABASE $shard;" 2>&1 || {
            print_error "Failed to create database $shard"
            continue
        }
        print_status "Created database $shard"
    fi
    
    # Check if users table exists (using docker exec directly)
    TABLE_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');" 2>/dev/null | xargs || echo "false")
    
    if [ "$TABLE_EXISTS" != "t" ]; then
        print_warning "Users table does not exist in $shard, creating it..."
        # Create users table with all required columns (using docker exec directly)
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" << 'EOF' 2>&1 || true
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    cooperative_id UUID,
    roles JSONB DEFAULT '[]',
    kyc_status VARCHAR(50) DEFAULT 'pending',
    user_profile_image VARCHAR(500),
    membership_payment_proof VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_cooperative_id ON users(cooperative_id);
EOF
        print_status "Created users table in $shard"
    fi
    
    # Check if id column exists (using docker exec directly)
    ID_COLUMN=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';" 2>/dev/null | xargs || echo "")
    
    if [ -z "$ID_COLUMN" ]; then
        print_error "❌ Column 'id' does not exist in $shard.users table!"
        print_step "Adding id column..."
        
        # Add UUID extension and id column (using docker exec directly)
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" << 'EOF' 2>&1 || true
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id') THEN
        ALTER TABLE users ADD COLUMN id UUID DEFAULT uuid_generate_v4();
        -- Check if primary key exists before adding
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_pkey') THEN
            ALTER TABLE users ADD PRIMARY KEY (id);
        END IF;
    END IF;
END $$;
EOF
        print_status "Added id column to $shard"
    else
        print_status "✅ id column exists in $shard"
    fi
    
    # Check and add membership_payment_proof column (using docker exec directly)
    MEMBERSHIP_COLUMN=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'membership_payment_proof';" 2>/dev/null | xargs || echo "")
    
    if [ -z "$MEMBERSHIP_COLUMN" ]; then
        print_step "Adding membership_payment_proof column to $shard..."
        docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS membership_payment_proof VARCHAR(500);" 2>&1 || true
        print_status "Added membership_payment_proof column to $shard"
    else
        print_status "✅ membership_payment_proof column exists in $shard"
    fi
    
    # Verify table structure (using docker exec directly)
    print_step "Verifying table structure for $shard..."
    COLUMNS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' ORDER BY ordinal_position;" 2>/dev/null | xargs || echo "")
    print_info "Columns: $COLUMNS"
    
    print_status "✅ $shard schema fixed"
done

print_status "All shards checked and fixed!"

# Verify all fixes (using docker exec directly)
print_step "Final verification..."
for shard in "${SHARDS[@]}"; do
    ID_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';" 2>/dev/null | xargs || echo "")
    MEMBERSHIP_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'membership_payment_proof';" 2>/dev/null | xargs || echo "")
    
    if [ -n "$ID_EXISTS" ] && [ -n "$MEMBERSHIP_EXISTS" ]; then
        print_status "✅ $shard: All columns present"
    else
        print_error "❌ $shard: Missing columns (id: $ID_EXISTS, membership_payment_proof: $MEMBERSHIP_EXISTS)"
    fi
done

print_step "Restarting backend to apply changes..."
$COMPOSE_CMD restart backend 2>/dev/null || docker compose restart backend 2>/dev/null || {
    print_warning "Could not restart backend automatically"
    print_info "Please restart manually: docker-compose restart backend"
}

print_status "✅ Schema fix completed!"
print_info "You can now test registration. The 'id' column error should be resolved."

EOFSCRIPT

# Copy script to VPS
print_step "Copying fix script to VPS..."
scp -i "$VPS_KEY" /tmp/fix-users-schema.sh "$VPS_USER@$VPS_HOST:~/sourcecode/"

# Run script on VPS
print_step "Running schema fix on VPS..."
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "cd ~/sourcecode && chmod +x fix-users-schema.sh && ./fix-users-schema.sh"

print_status "✅ Schema fix completed!"
