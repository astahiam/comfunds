-- Remove indexes
DROP INDEX IF EXISTS idx_projects_approval_status;
DROP INDEX IF EXISTS idx_projects_owner_id;
DROP INDEX IF EXISTS idx_projects_cooperative_id;
DROP INDEX IF EXISTS idx_projects_approved_by;
DROP INDEX IF EXISTS idx_projects_rejected_by;

-- Remove columns
ALTER TABLE projects
DROP COLUMN IF EXISTS approval_status,
DROP COLUMN IF EXISTS rejected_by,
DROP COLUMN IF EXISTS rejected_at,
DROP COLUMN IF EXISTS rejection_reason,
DROP COLUMN IF EXISTS reviewer_comments,
DROP COLUMN IF EXISTS owner_id,
DROP COLUMN IF EXISTS cooperative_id;

-- Remove constraint
ALTER TABLE projects
DROP CONSTRAINT IF EXISTS chk_project_approval_status;

