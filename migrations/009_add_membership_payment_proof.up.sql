-- Add membership_payment_proof column to users table
ALTER TABLE users 
    ADD COLUMN IF NOT EXISTS membership_payment_proof VARCHAR(500);

-- Add index for membership payment proof
CREATE INDEX IF NOT EXISTS idx_users_membership_payment_proof ON users(membership_payment_proof) WHERE membership_payment_proof IS NOT NULL;
