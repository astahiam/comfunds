-- Update users table to use UUID and add cooperative relationship
ALTER TABLE users 
    ADD COLUMN temp_id UUID DEFAULT uuid_generate_v4(),
    ADD COLUMN cooperative_id UUID,
    ADD COLUMN roles JSONB DEFAULT '["guest"]',
    ADD COLUMN kyc_status VARCHAR(20) DEFAULT 'pending';

-- Update existing users with new UUIDs
UPDATE users SET temp_id = uuid_generate_v4();

-- Drop old primary key and create new one
ALTER TABLE users DROP CONSTRAINT users_pkey;
ALTER TABLE users DROP COLUMN id;
ALTER TABLE users RENAME COLUMN temp_id TO id;
ALTER TABLE users ADD PRIMARY KEY (id);

-- Note: Foreign key constraint removed for sharded database architecture
-- Cooperative relationship maintained through application logic

-- Create new indexes
CREATE INDEX idx_users_cooperative_id ON users(cooperative_id);
CREATE INDEX idx_users_roles ON users USING GIN(roles);
CREATE INDEX idx_users_kyc_status ON users(kyc_status);
-- Additional indexes for sharded database performance
CREATE INDEX idx_users_name_search ON users(name); -- Enhanced name search index
CREATE INDEX idx_users_phone ON users(phone); -- Index for phone number search

-- Create trigger for updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
