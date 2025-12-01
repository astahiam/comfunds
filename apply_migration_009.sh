#!/bin/bash

# Apply migration 009 (add membership_payment_proof column) to all shards
set -e

echo "🚀 Applying migration 009 to all shards..."

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")
MIGRATION_FILE="migrations/009_add_membership_payment_proof.up.sql"

# Get database connection details from environment or use defaults
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"

for shard in "${SHARDS[@]}"; do
    echo ""
    echo "📊 Applying migration to shard: $shard"
    echo "=================================="
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Check if column already exists
    column_exists=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -t -c "
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name='users' 
            AND column_name='membership_payment_proof'
        );
    " | xargs)
    
    if [ "$column_exists" = "t" ]; then
        echo "  ✅ Column 'membership_payment_proof' already exists in $shard"
    else
        echo "  🔄 Applying migration to $shard..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -f "$MIGRATION_FILE"
        
        if [ $? -eq 0 ]; then
            echo "  ✅ Migration applied successfully to $shard"
        else
            echo "  ❌ Failed to apply migration to $shard"
            exit 1
        fi
    fi
done

echo ""
echo "🎉 Migration 009 applied to all shards!"
echo ""
echo "🔍 Verifying users table structure..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d comfunds00 -c "\d users" | grep -E "(membership_payment_proof|Column)" || echo "Column verification completed"

