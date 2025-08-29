-- Drop sharded databases for ComFunds platform
-- This migration removes the 4 databases used for sharding

-- Note: This file should be run against the default 'postgres' database
-- with a user that has DROP privileges
-- WARNING: This will permanently delete all data in the sharded databases

-- Drop database for shard 1
DROP DATABASE IF EXISTS comfunds01;

-- Drop database for shard 2
DROP DATABASE IF EXISTS comfunds02;

-- Drop database for shard 3
DROP DATABASE IF EXISTS comfunds03;

-- Drop database for shard 4
DROP DATABASE IF EXISTS comfunds04;
