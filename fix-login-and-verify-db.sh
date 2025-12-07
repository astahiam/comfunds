#!/bin/bash

# Fix Login Issues and Verify Database Copy
# This script verifies database copy and fixes any schema issues

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

print_step "Creating verification and fix script for VPS..."

cat > /tmp/fix-login-verify.sh << 'EOFSCRIPT'
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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Detect PostgreSQL container
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(postgres|hajifund)" | head -1 || echo "")

if [ -z "$CONTAINER_NAME" ]; then
    print_error "PostgreSQL container not found"
    exit 1
fi

print_status "Using container: $CONTAINER_NAME"

DB_USER="${DB_USER:-postgres}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

print_step "Verifying and fixing databases..."

for shard in "${SHARDS[@]}"; do
    print_step "Checking $shard..."
    
    # Check if database exists
    DB_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$shard" && echo "yes" || echo "no")
    
    if [ "$DB_EXISTS" != "yes" ]; then
        print_error "Database $shard does not exist!"
        print_step "Creating database $shard..."
        docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -c "CREATE DATABASE $shard;" 2>&1 || true
        continue
    fi
    
    # Check if users table exists
    TABLE_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');" 2>/dev/null | xargs || echo "false")
    
    if [ "$TABLE_EXISTS" != "t" ]; then
        print_error "Users table does not exist in $shard!"
        print_step "Creating users table..."
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
        continue
    fi
    
    # Check for id column
    ID_COLUMN=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';" 2>/dev/null | xargs || echo "")
    
    if [ -z "$ID_COLUMN" ]; then
        print_error "❌ Column 'id' does not exist in $shard.users!"
        print_step "Adding id column..."
        docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" << 'EOF' 2>&1 || true
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id') THEN
        ALTER TABLE users ADD COLUMN id UUID DEFAULT uuid_generate_v4();
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_pkey') THEN
            ALTER TABLE users ADD PRIMARY KEY (id);
        END IF;
    END IF;
END $$;
EOF
    else
        print_status "✅ id column exists"
    fi
    
    # Check for membership_payment_proof column
    MEMBERSHIP_COLUMN=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'membership_payment_proof';" 2>/dev/null | xargs || echo "")
    
    if [ -z "$MEMBERSHIP_COLUMN" ]; then
        print_error "❌ Column 'membership_payment_proof' does not exist!"
        print_step "Adding membership_payment_proof column..."
        docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS membership_payment_proof VARCHAR(500);" 2>&1 || true
    else
        print_status "✅ membership_payment_proof column exists"
    fi
    
    # Count users
    USER_COUNT=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs || echo "0")
    print_info "Users in $shard: $USER_COUNT"
    
    # Show sample user emails
    if [ "$USER_COUNT" -gt 0 ]; then
        SAMPLE_EMAILS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT email FROM users LIMIT 3;" 2>/dev/null | xargs || echo "")
        print_info "Sample emails: $SAMPLE_EMAILS"
    fi
    
    # Count tables
    TABLE_COUNT=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0")
    print_info "Tables in $shard: $TABLE_COUNT"
done

print_step "Restarting backend (using docker restart to avoid segfault)..."
BACKEND_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "(backend|hajifund)" | grep -v postgres | head -1 || echo "")

if [ -n "$BACKEND_CONTAINER" ]; then
    print_info "Found backend container: $BACKEND_CONTAINER"
    docker restart "$BACKEND_CONTAINER" 2>&1 || true
    print_status "Backend restarted"
    sleep 5
    
    print_step "Checking backend health..."
    if curl -f -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
        print_status "Backend health check: OK"
    else
        print_error "Backend health check: FAILED"
        print_info "Backend logs:"
        docker logs --tail=30 "$BACKEND_CONTAINER" 2>&1 | tail -30 || true
    fi
else
    print_error "Backend container not found"
fi

print_status "Verification and fixes completed!"

EOFSCRIPT

# Copy and run script
print_step "Copying script to VPS..."
scp -i "$VPS_KEY" /tmp/fix-login-verify.sh "$VPS_USER@$VPS_HOST:~/sourcecode/"

print_step "Running verification and fixes on VPS..."
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "cd ~/sourcecode && chmod +x fix-login-verify.sh && ./fix-login-verify.sh"

print_status "✅ Verification and fixes completed!"

