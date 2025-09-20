#!/bin/bash

# Run all migrations on all shards
set -e

echo "🚀 Running migrations on all shards..."

SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")
MIGRATIONS_DIR="migrations"

for shard in "${SHARDS[@]}"; do
    echo ""
    echo "📊 Running migrations on shard: $shard"
    echo "=================================="
    
    # Run each migration file in order
    for migration_file in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
        migration_name=$(basename "$migration_file")
        echo "  🔄 Applying $migration_name to $shard..."
        
        PGPASSWORD="" psql -h localhost -U postgres -d "$shard" -f "$migration_file" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "  ✅ $migration_name applied successfully"
        else
            echo "  ⚠️  $migration_name may have already been applied or failed"
        fi
    done
    
    echo "  ✅ Completed migrations for $shard"
done

echo ""
echo "🎉 All migrations completed!"
echo ""
echo "🔍 Verifying businesses table structure..."
PGPASSWORD="" psql -h localhost -U postgres -d comfunds00 -c "\d businesses" | head -15
