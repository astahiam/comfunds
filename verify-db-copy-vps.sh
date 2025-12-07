#!/bin/bash

# Verify Database Copy and Check Login Issues
# Run this on VPS to check if database copy worked and diagnose login issues

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

print_step "Verifying database copy and checking login issues..."

# Create verification script for VPS
cat > /tmp/verify-db-vps.sh << 'EOFSCRIPT'
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

print_step "Checking databases..."

for shard in "${SHARDS[@]}"; do
    print_step "Checking $shard..."
    
    # Check if database exists
    DB_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$shard" && echo "yes" || echo "no")
    
    if [ "$DB_EXISTS" != "yes" ]; then
        print_error "Database $shard does not exist!"
        continue
    fi
    
    # Check if users table exists
    TABLE_EXISTS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users');" 2>/dev/null | xargs || echo "false")
    
    if [ "$TABLE_EXISTS" != "t" ]; then
        print_error "Users table does not exist in $shard!"
        continue
    fi
    
    # Check for id column
    ID_COLUMN=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';" 2>/dev/null | xargs || echo "")
    
    if [ -z "$ID_COLUMN" ]; then
        print_error "❌ Column 'id' does not exist in $shard.users!"
    else
        print_status "✅ id column exists"
    fi
    
    # Check for membership_payment_proof column
    MEMBERSHIP_COLUMN=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'membership_payment_proof';" 2>/dev/null | xargs || echo "")
    
    if [ -z "$MEMBERSHIP_COLUMN" ]; then
        print_error "❌ Column 'membership_payment_proof' does not exist!"
    else
        print_status "✅ membership_payment_proof column exists"
    fi
    
    # Count users
    USER_COUNT=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs || echo "0")
    print_info "Users in $shard: $USER_COUNT"
    
    # Show sample user emails
    if [ "$USER_COUNT" -gt 0 ]; then
        SAMPLE_EMAILS=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT email FROM users LIMIT 5;" 2>/dev/null | xargs || echo "")
        print_info "Sample emails: $SAMPLE_EMAILS"
    fi
    
    # Count tables
    TABLE_COUNT=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0")
    print_info "Tables in $shard: $TABLE_COUNT"
done

print_step "Checking backend container..."
BACKEND_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "(backend|hajifund)" | grep -v postgres | head -1 || echo "")

if [ -n "$BACKEND_CONTAINER" ]; then
    print_status "Backend container: $BACKEND_CONTAINER"
    BACKEND_STATUS=$(docker ps --format '{{.Names}}:{{.Status}}' | grep "^$BACKEND_CONTAINER:" | cut -d: -f2 || echo "")
    print_info "Status: $BACKEND_STATUS"
    
    print_step "Backend logs (last 20 lines)..."
    docker logs --tail=20 "$BACKEND_CONTAINER" 2>&1 | tail -20 || true
else
    print_error "Backend container not found"
fi

print_step "Checking backend health..."
if curl -f -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
    print_status "Backend health check: OK"
else
    print_error "Backend health check: FAILED"
fi

EOFSCRIPT

# Copy and run verification script
print_step "Copying verification script to VPS..."
scp -i "$VPS_KEY" /tmp/verify-db-vps.sh "$VPS_USER@$VPS_HOST:~/sourcecode/"

print_step "Running verification on VPS..."
ssh -i "$VPS_KEY" "$VPS_USER@$VPS_HOST" "cd ~/sourcecode && chmod +x verify-db-vps.sh && ./verify-db-vps.sh"

print_status "Verification completed!"

