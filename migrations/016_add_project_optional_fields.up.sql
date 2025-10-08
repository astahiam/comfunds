-- Add optional fields to projects table to match API

-- Add min_investment (replaces minimum_funding concept)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS min_investment DECIMAL(15,2) CHECK (min_investment >= 100);

-- Add risk_level
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS risk_level VARCHAR(20) CHECK (risk_level IN ('Low', 'Medium', 'High'));

-- Add investment_period (in months)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS investment_period INTEGER CHECK (investment_period >= 6 AND investment_period <= 120);

-- Add expected_return
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS expected_return VARCHAR(50);

-- Add start_date and end_date (project timeline)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;

-- Rename funding_goal to target_amount (to match API)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS target_amount DECIMAL(15,2) CHECK (target_amount >= 1000);

-- Add raised_amount (to match API)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS raised_amount DECIMAL(15,2) DEFAULT 0 CHECK (raised_amount >= 0);

-- Add category (to match API)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS category VARCHAR(100);

-- Add owner_id (project owner)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Add cooperative_id (for sharia compliance)
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS cooperative_id UUID;

-- Add approval fields
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS approved_by UUID;

ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;

-- Create indexes for new fields
CREATE INDEX IF NOT EXISTS idx_projects_risk_level ON projects(risk_level);
CREATE INDEX IF NOT EXISTS idx_projects_investment_period ON projects(investment_period);
CREATE INDEX IF NOT EXISTS idx_projects_category ON projects(category);
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_cooperative_id ON projects(cooperative_id);
CREATE INDEX IF NOT EXISTS idx_projects_start_date ON projects(start_date);

-- Add comment
COMMENT ON COLUMN projects.min_investment IS 'Minimum investment amount per investor';
COMMENT ON COLUMN projects.risk_level IS 'Project risk level: Low, Medium, or High';
COMMENT ON COLUMN projects.investment_period IS 'Investment period in months (6-120)';
COMMENT ON COLUMN projects.expected_return IS 'Expected return percentage or description';
COMMENT ON COLUMN projects.start_date IS 'Project start date';
COMMENT ON COLUMN projects.end_date IS 'Project end date';
COMMENT ON COLUMN projects.target_amount IS 'Target funding amount';
COMMENT ON COLUMN projects.raised_amount IS 'Current raised amount';
COMMENT ON COLUMN projects.category IS 'Project category (Agriculture, Technology, etc.)';

