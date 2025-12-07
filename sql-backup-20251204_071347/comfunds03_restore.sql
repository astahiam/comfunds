-- ============================================
-- RESTORE SCRIPT FOR comfunds03
-- ============================================
-- Usage: psql -U postgres -d postgres -f comfunds03_restore.sql
-- Or: docker exec -i container_name psql -U postgres -d postgres -f comfunds03_restore.sql
--
-- This script will:
-- 1. Create database if it doesn't exist
-- 2. Run schema migrations
-- 3. Import data
-- ============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE comfunds03'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds03')\gexec

-- Connect to the database
\c comfunds03

-- Run schema migrations first
\i comfunds03_migrate_schema.sql

-- Import data (from complete dump)
\i comfunds03_complete.sql

-- Verify
SELECT 'Database comfunds03 restored successfully!' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';

