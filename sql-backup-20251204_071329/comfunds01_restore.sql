-- ============================================
-- RESTORE SCRIPT FOR comfunds01
-- ============================================
-- Usage: psql -U postgres -d postgres -f comfunds01_restore.sql
-- Or: docker exec -i container_name psql -U postgres -d postgres -f comfunds01_restore.sql
--
-- This script will:
-- 1. Create database if it doesn't exist
-- 2. Run schema migrations
-- 3. Import data
-- ============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE comfunds01'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds01')\gexec

-- Connect to the database
\c comfunds01

-- Run schema migrations first
\i comfunds01_migrate_schema.sql

-- Import data (from complete dump)
\i comfunds01_complete.sql

-- Verify
SELECT 'Database comfunds01 restored successfully!' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';

