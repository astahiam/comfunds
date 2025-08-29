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
    
    CONSTRAINT fk_businesses_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_businesses_cooperative FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id) ON DELETE CASCADE,
    CONSTRAINT chk_approval_status CHECK (approval_status IN ('pending', 'approved', 'rejected'))
);

-- Create indexes for better performance
CREATE INDEX idx_businesses_owner_id ON businesses(owner_id);
CREATE INDEX idx_businesses_cooperative_id ON businesses(cooperative_id);
CREATE INDEX idx_businesses_approval_status ON businesses(approval_status);
CREATE INDEX idx_businesses_business_type ON businesses(business_type);
CREATE INDEX idx_businesses_is_active ON businesses(is_active);
CREATE INDEX idx_businesses_created_at ON businesses(created_at);

-- Create trigger for updated_at
CREATE TRIGGER update_businesses_updated_at 
    BEFORE UPDATE ON businesses 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
