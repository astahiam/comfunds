-- Rollback: Remove optional fields from projects table

-- Drop indexes first
DROP INDEX IF EXISTS idx_projects_risk_level;
DROP INDEX IF EXISTS idx_projects_investment_period;
DROP INDEX IF EXISTS idx_projects_category;
DROP INDEX IF EXISTS idx_projects_owner_id;
DROP INDEX IF EXISTS idx_projects_cooperative_id;
DROP INDEX IF EXISTS idx_projects_start_date;

-- Drop columns
ALTER TABLE projects DROP COLUMN IF EXISTS min_investment;
ALTER TABLE projects DROP COLUMN IF EXISTS risk_level;
ALTER TABLE projects DROP COLUMN IF EXISTS investment_period;
ALTER TABLE projects DROP COLUMN IF EXISTS expected_return;
ALTER TABLE projects DROP COLUMN IF EXISTS start_date;
ALTER TABLE projects DROP COLUMN IF EXISTS end_date;
ALTER TABLE projects DROP COLUMN IF EXISTS target_amount;
ALTER TABLE projects DROP COLUMN IF EXISTS raised_amount;
ALTER TABLE projects DROP COLUMN IF EXISTS category;
ALTER TABLE projects DROP COLUMN IF EXISTS owner_id;
ALTER TABLE projects DROP COLUMN IF EXISTS cooperative_id;
ALTER TABLE projects DROP COLUMN IF EXISTS approved_by;
ALTER TABLE projects DROP COLUMN IF EXISTS approved_at;

