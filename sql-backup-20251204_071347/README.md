# SQL Backup Files

Created: Thu Dec  4 07:13:49 WIB 2025

## Files Description

### For each shard (comfunds00-03):

1. **`{shard}_migrate_schema.sql`** - Schema migration script
   - Ensures all tables, columns, indexes exist
   - Safe to run multiple times (idempotent)
   - Handles schema differences

2. **`{shard}_complete.sql`** - Complete database dump
   - Includes CREATE DATABASE, schema, and data
   - Use this for full restore

3. **`{shard}_data_only.sql`** - Data only dump
   - Only INSERT statements
   - Use when schema already exists

4. **`{shard}_standalone_restore.sql`** - All-in-one restore script
   - Includes migrations + data
   - Self-contained, ready to execute

5. **`{shard}_restore.sql`** - Restore script (requires separate files)
   - References migration and complete files

### Master Scripts:

- **`restore_all.sh`** - Restores all databases at once

## Usage

### Option 1: Standalone Restore (Recommended)



### Option 2: Using Master Script



### Option 3: Manual Restore



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



