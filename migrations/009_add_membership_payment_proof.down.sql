-- Remove membership_payment_proof column from users table
DROP INDEX IF EXISTS idx_users_membership_payment_proof;
ALTER TABLE users DROP COLUMN IF EXISTS membership_payment_proof;

