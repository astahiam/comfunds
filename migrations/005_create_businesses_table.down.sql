DROP TRIGGER IF EXISTS update_businesses_updated_at ON businesses;
DROP INDEX IF EXISTS idx_businesses_created_at;
DROP INDEX IF EXISTS idx_businesses_is_active;
DROP INDEX IF EXISTS idx_businesses_business_type;
DROP INDEX IF EXISTS idx_businesses_approval_status;
DROP INDEX IF EXISTS idx_businesses_cooperative_id;
DROP INDEX IF EXISTS idx_businesses_owner_id;
DROP TABLE IF EXISTS businesses;
