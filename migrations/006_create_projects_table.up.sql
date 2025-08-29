-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    business_id UUID NOT NULL,
    funding_goal DECIMAL(15,2) NOT NULL CHECK (funding_goal > 0),
    minimum_funding DECIMAL(15,2) CHECK (minimum_funding >= 0),
    current_funding DECIMAL(15,2) DEFAULT 0 CHECK (current_funding >= 0),
    funding_deadline TIMESTAMP WITH TIME ZONE,
    profit_sharing_ratio JSONB NOT NULL DEFAULT '{"investor": 70, "business": 30}',
    project_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',
    milestones JSONB DEFAULT '[]',
    documents JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_projects_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT chk_project_type CHECK (project_type IN ('startup', 'expansion', 'equipment')),
    CONSTRAINT chk_project_status CHECK (status IN ('draft', 'submitted', 'approved', 'active', 'funded', 'closed', 'cancelled')),
    CONSTRAINT chk_funding_goal_minimum CHECK (minimum_funding IS NULL OR minimum_funding <= funding_goal),
    CONSTRAINT chk_current_funding_goal CHECK (current_funding <= funding_goal)
);

-- Create indexes for better performance
CREATE INDEX idx_projects_business_id ON projects(business_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_project_type ON projects(project_type);
CREATE INDEX idx_projects_funding_deadline ON projects(funding_deadline);
CREATE INDEX idx_projects_created_at ON projects(created_at);
CREATE INDEX idx_projects_funding_goal ON projects(funding_goal);

-- Create trigger for updated_at
CREATE TRIGGER update_projects_updated_at 
    BEFORE UPDATE ON projects 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
