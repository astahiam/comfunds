-- ============================================
-- RESTORE SCRIPT FOR comfunds02
-- ============================================
-- Usage: psql -U postgres -d postgres -f comfunds02_restore.sql
-- Or: docker exec -i container_name psql -U postgres -d postgres -f comfunds02_restore.sql
--
-- This script will:
-- 1. Create database if it doesn't exist
-- 2. Run schema migrations
-- 3. Import data
-- ============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE comfunds02'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds02')\gexec

-- Connect to the database
\c comfunds02

-- Run schema migrations first
\i comfunds02_migrate_schema.sql

-- Import data (from complete dump)
\i comfunds02_complete.sql

-- Verify
SELECT 'Database comfunds02 restored successfully!' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';

