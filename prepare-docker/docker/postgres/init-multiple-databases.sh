#!/bin/bash
set -e

# Create multiple databases for sharding
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create shard databases
    CREATE DATABASE comfunds00;
    CREATE DATABASE comfunds01;
    CREATE DATABASE comfunds02;
    CREATE DATABASE comfunds03;
    
    -- Grant permissions
    GRANT ALL PRIVILEGES ON DATABASE comfunds00 TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comfunds01 TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comfunds02 TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE comfunds03 TO $POSTGRES_USER;
EOSQL

# Initialize each shard with its schema
for shard in 00 01 02 03; do
    echo "Initializing comfunds$shard database..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "comfunds$shard" -f "/docker-entrypoint-initdb.d/init-comfunds$shard.sql"
done

echo "All shard databases initialized successfully!"