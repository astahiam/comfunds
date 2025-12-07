# SQL Backup Files Usage Guide

## Overview

Each database shard has its own **completely standalone** restore file that can be executed independently.

## Files Created

For each database (comfunds00, comfunds01, comfunds02, comfunds03):

### 1. `{shard}_standalone_restore.sql` ⭐ **USE THIS ONE**
- **Completely self-contained** - includes everything
- Database creation
- Schema migrations (handles missing columns, indexes, etc.)
- All data
- **Size**: ~140-150KB each
- **Ready to execute** - no dependencies

### 2. `{shard}_migrate_schema.sql`
- Schema migration script only
- Handles schema differences
- Safe to run multiple times

### 3. `{shard}_complete.sql`
- Full database dump (schema + data)
- Includes CREATE DATABASE command

### 4. `{shard}_data_only.sql`
- Data only (INSERT statements)
- Use when schema already exists

## Quick Usage

### Restore Single Database

```bash
# Method 1: Direct PostgreSQL
psql -U postgres -d postgres -f comfunds00_standalone_restore.sql

# Method 2: Docker PostgreSQL
docker exec -i hajifund-postgres psql -U postgres -d postgres < comfunds00_standalone_restore.sql

# Method 3: With password
PGPASSWORD=postgres123 psql -U postgres -d postgres -f comfunds00_standalone_restore.sql
```

### Restore All 4 Databases

```bash
# Restore each one independently
psql -U postgres -d postgres -f comfunds00_standalone_restore.sql
psql -U postgres -d postgres -f comfunds01_standalone_restore.sql
psql -U postgres -d postgres -f comfunds02_standalone_restore.sql
psql -U postgres -d postgres -f comfunds03_standalone_restore.sql

# Or use the master script
./restore_all.sh
```

## What Each Standalone File Contains

Each `{shard}_standalone_restore.sql` file includes:

1. **Database Creation**
   ```sql
   CREATE DATABASE comfunds00;
   ```

2. **Schema Migrations**
   - Creates all tables if missing
   - Adds missing columns (id, membership_payment_proof, etc.)
   - Converts data types (INTEGER → UUID if needed)
   - Creates indexes
   - Handles all schema differences

3. **Data Import**
   - All INSERT statements
   - All your data

4. **Verification**
   - Shows user count
   - Shows table count

## Examples

### Example 1: Restore to Fresh PostgreSQL

```bash
# Fresh PostgreSQL installation
psql -U postgres -d postgres -f comfunds00_standalone_restore.sql
```

### Example 2: Restore to Docker PostgreSQL

```bash
# Copy file to container
docker cp comfunds00_standalone_restore.sql hajifund-postgres:/tmp/

# Execute
docker exec -i hajifund-postgres psql -U postgres -d postgres < /tmp/comfunds00_standalone_restore.sql

# Or pipe directly
cat comfunds00_standalone_restore.sql | docker exec -i hajifund-postgres psql -U postgres -d postgres
```

### Example 3: Restore to AWS RDS

```bash
# Set password
export PGPASSWORD=your_rds_password

# Restore
psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d postgres -f comfunds00_standalone_restore.sql
```

### Example 4: Restore to Remote Server

```bash
# Copy file to server
scp comfunds00_standalone_restore.sql user@server:/tmp/

# SSH and restore
ssh user@server "psql -U postgres -d postgres -f /tmp/comfunds00_standalone_restore.sql"
```

## Schema Migration Features

The standalone files handle:

✅ **Missing Columns**
- Adds `id` column (UUID) if missing
- Adds `membership_payment_proof` if missing
- Adds `cooperative_id`, `roles`, `kyc_status`, etc.

✅ **Wrong Data Types**
- Converts INTEGER `id` to UUID automatically
- Preserves all data during conversion

✅ **Missing Indexes**
- Creates all required indexes
- Uses `IF NOT EXISTS` (safe to run multiple times)

✅ **Missing Tables**
- Creates all tables (users, businesses, projects, etc.)
- With correct structure

✅ **Missing Extensions**
- Creates UUID extension automatically

## Safety Features

- **Idempotent**: Safe to run multiple times
- **Non-destructive**: Uses `IF NOT EXISTS` checks
- **Data preserving**: Doesn't drop existing data
- **Error handling**: Continues even if some parts fail

## Verification After Restore

```sql
-- Check database exists
SELECT datname FROM pg_database WHERE datname LIKE 'comfunds%';

-- Check users
SELECT COUNT(*) FROM users;

-- Check schema
\d users

-- Check specific user
SELECT email, name FROM users LIMIT 5;
```

## Troubleshooting

### Error: "database already exists"
- The script handles this automatically
- It will connect to existing database and update schema

### Error: "column already exists"
- The script uses `IF NOT EXISTS` checks
- Safe to ignore

### Error: "permission denied"
- Make sure PostgreSQL user has CREATE DATABASE permission
- Or create database manually first:
  ```sql
  CREATE DATABASE comfunds00;
  ```
  Then run the standalone script

### Error: "extension uuid-ossp does not exist"
- The script creates it automatically
- If it fails, run manually:
  ```sql
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  ```

## File Sizes

- `comfunds00_standalone_restore.sql`: ~149KB
- `comfunds01_standalone_restore.sql`: ~147KB
- `comfunds02_standalone_restore.sql`: ~143KB
- `comfunds03_standalone_restore.sql`: ~145KB

Total: ~584KB for all 4 databases

## Best Practices

1. **Always backup before restore** (if restoring to existing database)
2. **Test on development first** before production
3. **Check file integrity** before restoring
4. **Verify after restore** using SQL queries
5. **Keep backups** in safe location

## Summary

✅ **4 completely independent files** - one for each database
✅ **Self-contained** - no dependencies
✅ **Schema migration included** - handles all differences
✅ **Ready to execute** - just run the SQL file
✅ **Safe** - idempotent, non-destructive

**Just execute the `{shard}_standalone_restore.sql` file and you're done!**

