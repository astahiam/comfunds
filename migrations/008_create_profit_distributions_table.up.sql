-- Create profit_distributions table
CREATE TABLE IF NOT EXISTS profit_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL,
    business_profit DECIMAL(15,2) NOT NULL,
    distribution_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    total_distributed DECIMAL(15,2) NOT NULL CHECK (total_distributed >= 0),
    status VARCHAR(20) DEFAULT 'calculated',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_profit_distributions_project FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT chk_distribution_status CHECK (status IN ('calculated', 'approved', 'distributed', 'cancelled'))
);

-- Create investment_returns table
CREATE TABLE IF NOT EXISTS investment_returns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investment_id UUID NOT NULL,
    distribution_id UUID NOT NULL,
    return_amount DECIMAL(15,2) NOT NULL CHECK (return_amount >= 0),
    return_percentage DECIMAL(5,2) NOT NULL CHECK (return_percentage >= 0),
    payment_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'pending',
    transaction_ref VARCHAR(50) UNIQUE NOT NULL DEFAULT ('RTN-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::bigint || '-' || nextval('global_transaction_seq')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_investment_returns_investment FOREIGN KEY (investment_id) REFERENCES investments(id) ON DELETE CASCADE,
    CONSTRAINT fk_investment_returns_distribution FOREIGN KEY (distribution_id) REFERENCES profit_distributions(id) ON DELETE CASCADE,
    CONSTRAINT chk_return_status CHECK (status IN ('pending', 'paid', 'failed')),
    CONSTRAINT unique_investment_distribution UNIQUE (investment_id, distribution_id)
);

-- Create indexes for profit_distributions
CREATE INDEX idx_profit_distributions_project_id ON profit_distributions(project_id);
CREATE INDEX idx_profit_distributions_status ON profit_distributions(status);
CREATE INDEX idx_profit_distributions_distribution_date ON profit_distributions(distribution_date);
CREATE INDEX idx_profit_distributions_created_at ON profit_distributions(created_at);

-- Create indexes for investment_returns
CREATE INDEX idx_investment_returns_investment_id ON investment_returns(investment_id);
CREATE INDEX idx_investment_returns_distribution_id ON investment_returns(distribution_id);
CREATE INDEX idx_investment_returns_status ON investment_returns(status);
CREATE INDEX idx_investment_returns_payment_date ON investment_returns(payment_date);
CREATE INDEX idx_investment_returns_transaction_ref ON investment_returns(transaction_ref);
CREATE INDEX idx_investment_returns_created_at ON investment_returns(created_at);

-- Create triggers for updated_at
CREATE TRIGGER update_profit_distributions_updated_at 
    BEFORE UPDATE ON profit_distributions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_investment_returns_updated_at 
    BEFORE UPDATE ON investment_returns 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
