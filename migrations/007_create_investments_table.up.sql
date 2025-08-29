-- Create sequence for unique transaction references across shards
CREATE SEQUENCE IF NOT EXISTS global_transaction_seq START 1000000;

-- Create investments table
CREATE TABLE IF NOT EXISTS investments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL,
    investor_id UUID NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    investment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    profit_sharing_percentage DECIMAL(5,2) NOT NULL CHECK (profit_sharing_percentage >= 0 AND profit_sharing_percentage <= 100),
    status VARCHAR(20) DEFAULT 'pending',
    transaction_ref VARCHAR(50) UNIQUE NOT NULL DEFAULT ('TXN-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::bigint || '-' || nextval('global_transaction_seq')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_investments_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_investments_investor FOREIGN KEY (investor_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_investment_status CHECK (status IN ('pending', 'confirmed', 'refunded', 'cancelled')),
    CONSTRAINT unique_investor_project UNIQUE (project_id, investor_id)
);

-- Create indexes for better performance
CREATE INDEX idx_investments_project_id ON investments(project_id);
CREATE INDEX idx_investments_investor_id ON investments(investor_id);
CREATE INDEX idx_investments_status ON investments(status);
CREATE INDEX idx_investments_investment_date ON investments(investment_date);
CREATE INDEX idx_investments_transaction_ref ON investments(transaction_ref);
CREATE INDEX idx_investments_created_at ON investments(created_at);

-- Create trigger for updated_at
CREATE TRIGGER update_investments_updated_at 
    BEFORE UPDATE ON investments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
