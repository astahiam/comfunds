DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP INDEX IF EXISTS idx_users_kyc_status;
DROP INDEX IF EXISTS idx_users_roles;
DROP INDEX IF EXISTS idx_users_cooperative_id;

ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_cooperative;
ALTER TABLE users DROP COLUMN IF EXISTS kyc_status;
ALTER TABLE users DROP COLUMN IF EXISTS roles;
ALTER TABLE users DROP COLUMN IF EXISTS cooperative_id;

-- Revert to original integer ID (simplified for rollback)
ALTER TABLE users DROP CONSTRAINT users_pkey;
ALTER TABLE users DROP COLUMN id;
ALTER TABLE users ADD COLUMN id SERIAL PRIMARY KEY;
