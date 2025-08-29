-- Drop idempotency table and related objects
DROP SEQUENCE IF EXISTS idempotency_sequence;
DROP INDEX IF EXISTS idx_idempotency_table_name;
DROP INDEX IF EXISTS idx_idempotency_sequence;
DROP INDEX IF EXISTS idx_idempotency_expires_at;
DROP INDEX IF EXISTS idx_idempotency_user_endpoint;
DROP TABLE IF EXISTS idempotency_keys;
