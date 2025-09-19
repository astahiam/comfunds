-- Create businesses table
CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL,
    cooperative_id UUID NOT NULL,
    registration_documents JSONB DEFAULT '{}',
    approval_status VARCHAR(20) DEFAULT 'pending',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Note: Foreign key constraints removed for sharded database architecture
    -- Relationships maintained through application logic
    CONSTRAINT chk_approval_status CHECK (approval_status IN ('pending', 'approved', 'rejected'))
);

-- Create indexes for better performance
CREATE INDEX idx_businesses_name ON businesses(name); -- Index for business name search
CREATE INDEX idx_businesses_owner_id ON businesses(owner_id);
CREATE INDEX idx_businesses_cooperative_id ON businesses(cooperative_id);
CREATE INDEX idx_businesses_approval_status ON businesses(approval_status);
CREATE INDEX idx_businesses_business_type ON businesses(business_type); -- Index for business type filtering
CREATE INDEX idx_businesses_is_active ON businesses(is_active);
CREATE INDEX idx_businesses_created_at ON businesses(created_at);
-- Additional indexes for sharded database performance
CREATE INDEX idx_businesses_name_type ON businesses(name, business_type); -- Composite index for name and type searches

-- Create trigger for updated_at
CREATE TRIGGER update_businesses_updated_at 
    BEFORE UPDATE ON businesses 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
