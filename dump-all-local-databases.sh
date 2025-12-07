#!/bin/bash

# Dump All Local Database Shards
# This script dumps all 4 PostgreSQL shards from local database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
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

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_DIR="./database-dumps-${TIMESTAMP}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Local Database Configuration
LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_USER="${LOCAL_DB_USER:-postgres}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

print_header "Dump All Local Database Shards"

print_info "Configuration:"
print_info "  Local DB: $LOCAL_DB_HOST:$LOCAL_DB_PORT"
print_info "  Local User: $LOCAL_DB_USER"
print_info "  Dump Directory: $DUMP_DIR"
print_info "  Shards: ${SHARDS[*]}"
echo ""

# Step 1: Check local database connection
print_step "1. Checking local database connection..."

if [ -n "$LOCAL_DB_PASSWORD" ]; then
    export PGPASSWORD="$LOCAL_DB_PASSWORD"
fi

if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    print_status "Local database connection: OK"
else
    print_error "Cannot connect to local database"
    print_info "Please check:"
    print_info "  - PostgreSQL is running locally"
    print_info "  - Connection settings are correct"
    print_info "  - Set LOCAL_DB_PASSWORD if needed"
    exit 1
fi

# Step 2: Create dump directory
print_step "2. Creating dump directory..."
mkdir -p "$DUMP_DIR"
print_status "Dump directory created: $DUMP_DIR"

# Step 3: Dump each database shard
print_step "3. Dumping database shards..."

TOTAL_TABLES=0
TOTAL_ROWS=0

for shard in "${SHARDS[@]}"; do
    print_info "Dumping $shard..."
    
    # Check if database exists
    if psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -c "SELECT 1;" >/dev/null 2>&1; then
        # Get table count
        TABLE_COUNT=$(psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
        
        # Get row count estimate
        ROW_COUNT=$(psql -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" -d "$shard" -t -c "SELECT COALESCE(SUM(n_live_tup), 0)::bigint FROM pg_stat_user_tables;" 2>/dev/null | xargs || echo "0")
        
        # Dump complete database (schema + data)
        print_info "  Creating complete dump (schema + data)..."
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --clean \
            --if-exists \
            --create \
            --format=plain \
            --verbose \
            --file="$DUMP_DIR/${shard}_complete.sql" \
            "$shard" 2>&1 | grep -v "WARNING" | tail -5 || true
        
        # Dump schema only
        print_info "  Creating schema-only dump..."
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --schema-only \
            --clean \
            --if-exists \
            --format=plain \
            --file="$DUMP_DIR/${shard}_schema.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        # Dump data only
        print_info "  Creating data-only dump..."
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --data-only \
            --disable-triggers \
            --format=plain \
            --file="$DUMP_DIR/${shard}_data.sql" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        # Dump in custom format (for pg_restore)
        print_info "  Creating custom format dump..."
        pg_dump -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PORT" -U "$LOCAL_DB_USER" \
            --no-password \
            --format=custom \
            --compress=9 \
            --file="$DUMP_DIR/${shard}.dump" \
            "$shard" 2>&1 | grep -v "WARNING" || true
        
        TOTAL_TABLES=$((TOTAL_TABLES + TABLE_COUNT))
        TOTAL_ROWS=$((TOTAL_ROWS + ROW_COUNT))
        
        print_status "✅ $shard dumped (${TABLE_COUNT} tables, ~${ROW_COUNT} rows)"
    else
        print_warning "⚠️  Database $shard does not exist locally, skipping..."
    fi
done

# Step 4: Create summary
print_step "4. Creating dump summary..."

cat > "$DUMP_DIR/DUMP_SUMMARY.txt" << EOF
Database Dump Summary
====================
Date: $(date)
Source: Local PostgreSQL
Host: $LOCAL_DB_HOST:$LOCAL_DB_PORT
User: $LOCAL_DB_USER

Dumped Databases:
EOF

for shard in "${SHARDS[@]}"; do
    if [ -f "$DUMP_DIR/${shard}_complete.sql" ]; then
        FILE_SIZE=$(du -h "$DUMP_DIR/${shard}_complete.sql" | cut -f1)
        echo "  - $shard: ✅ ($FILE_SIZE)" >> "$DUMP_DIR/DUMP_SUMMARY.txt"
    else
        echo "  - $shard: ❌ (not found)" >> "$DUMP_DIR/DUMP_SUMMARY.txt"
    fi
done

cat >> "$DUMP_DIR/DUMP_SUMMARY.txt" << EOF

Total Statistics:
  - Total Tables: $TOTAL_TABLES
  - Total Rows: ~$TOTAL_ROWS

Files Created:
EOF

ls -lh "$DUMP_DIR" | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}' >> "$DUMP_DIR/DUMP_SUMMARY.txt"

cat >> "$DUMP_DIR/DUMP_SUMMARY.txt" << EOF

Import Instructions:
====================

To import to VPS Docker PostgreSQL:

1. Upload dumps to VPS:
   scp -i ~/Downloads/ryan-biznet-gio.pem -r $DUMP_DIR/* ryankharisma@103.103.20.68:~/sourcecode/db-import/

2. On VPS, import:
   cd ~/sourcecode/db-import
   docker-compose exec -T postgres psql -U postgres -d comfunds00 -f comfunds00_complete.sql
   docker-compose exec -T postgres psql -U postgres -d comfunds01 -f comfunds01_complete.sql
   docker-compose exec -T postgres psql -U postgres -d comfunds02 -f comfunds02_complete.sql
   docker-compose exec -T postgres psql -U postgres -d comfunds03 -f comfunds03_complete.sql

Or use custom format:
   docker-compose exec -T postgres pg_restore -U postgres -d comfunds00 --clean --if-exists comfunds00.dump
   docker-compose exec -T postgres pg_restore -U postgres -d comfunds01 --clean --if-exists comfunds01.dump
   docker-compose exec -T postgres pg_restore -U postgres -d comfunds02 --clean --if-exists comfunds02.dump
   docker-compose exec -T postgres pg_restore -U postgres -d comfunds03 --clean --if-exists comfunds03.dump
EOF

print_status "Summary created: $DUMP_DIR/DUMP_SUMMARY.txt"

# Step 5: Show summary
print_header "Dump Summary"

print_status "All database shards dumped successfully!"
echo ""
print_info "Dump directory: $DUMP_DIR"
print_info "Total tables: $TOTAL_TABLES"
print_info "Total rows: ~$TOTAL_ROWS"
echo ""
print_info "Files created:"
ls -lh "$DUMP_DIR" | tail -n +2 | awk '{printf "  %-40s %8s\n", $9, $5}'
echo ""
print_info "File sizes:"
du -sh "$DUMP_DIR"/* | awk '{printf "  %-40s %8s\n", $2, $1}'
echo ""
print_step "Next steps:"
echo "  1. Review dumps in: $DUMP_DIR"
echo "  2. Upload to VPS: scp -i ~/Downloads/ryan-biznet-gio.pem -r $DUMP_DIR/* ryankharisma@103.103.20.68:~/sourcecode/db-import/"
echo "  3. Import on VPS using instructions in DUMP_SUMMARY.txt"
echo ""
print_status "Dump completed! 🎉"

