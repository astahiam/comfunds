-- Create sharded databases for ComFunds platform
-- This migration creates the 4 databases used for sharding

-- Note: This file should be run against the default 'postgres' database
-- with a user that has CREATEDB privileges

-- Create database for shard 0
SELECT 'CREATE DATABASE comfunds00'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds00')\gexec

-- Create database for shard 1
SELECT 'CREATE DATABASE comfunds01'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds01')\gexec

-- Create database for shard 2  
SELECT 'CREATE DATABASE comfunds02'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds02')\gexec

-- Create database for shard 3
SELECT 'CREATE DATABASE comfunds03'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds03')\gexec
