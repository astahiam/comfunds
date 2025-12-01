#!/bin/bash
set -e

# Create multiple databases for sharding
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create databases for sharding
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

# Apply schema to each database
for db in comfunds00 comfunds01 comfunds02 comfunds03; do
    echo "Initializing database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" -f /docker-entrypoint-initdb.d/init-$db.sql
done

echo "All databases initialized successfully!"