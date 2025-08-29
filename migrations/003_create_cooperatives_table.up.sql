-- Create cooperatives table with UUID and sharding support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS cooperatives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    bank_account VARCHAR(100) NOT NULL,
    profit_sharing_policy JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_cooperatives_registration_number ON cooperatives(registration_number);
CREATE INDEX idx_cooperatives_is_active ON cooperatives(is_active);
CREATE INDEX idx_cooperatives_created_at ON cooperatives(created_at);
CREATE INDEX idx_cooperatives_email ON cooperatives(email);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_cooperatives_updated_at 
    BEFORE UPDATE ON cooperatives 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
