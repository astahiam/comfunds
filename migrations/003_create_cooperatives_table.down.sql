DROP TRIGGER IF EXISTS update_cooperatives_updated_at ON cooperatives;
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP INDEX IF EXISTS idx_cooperatives_email;
DROP INDEX IF EXISTS idx_cooperatives_created_at;
DROP INDEX IF EXISTS idx_cooperatives_is_active;
DROP INDEX IF EXISTS idx_cooperatives_registration_number;
DROP TABLE IF EXISTS cooperatives;
