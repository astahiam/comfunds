-- Add approval_status column to projects table
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending';

-- Add constraint for approval_status
ALTER TABLE projects
ADD CONSTRAINT chk_project_approval_status 
CHECK (approval_status IN ('pending', 'approved', 'rejected'));

-- Add indexes for filtering
CREATE INDEX IF NOT EXISTS idx_projects_approval_status ON projects(approval_status);

-- Add columns for rejection tracking
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS reviewer_comments TEXT;

-- Add owner_id and cooperative_id if they don't exist
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS cooperative_id UUID REFERENCES cooperatives(id);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_cooperative_id ON projects(cooperative_id);
CREATE INDEX IF NOT EXISTS idx_projects_approved_by ON projects(approved_by);
CREATE INDEX IF NOT EXISTS idx_projects_rejected_by ON projects(rejected_by);

