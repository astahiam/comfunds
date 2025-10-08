-- Remove funding_goal NOT NULL constraint and make it nullable
-- This allows us to use target_amount as the primary field
ALTER TABLE projects ALTER COLUMN funding_goal DROP NOT NULL;
ALTER TABLE projects ALTER COLUMN current_funding DROP NOT NULL;

-- Set default values from target_amount for existing records
UPDATE projects SET funding_goal = target_amount WHERE funding_goal IS NULL;
UPDATE projects SET current_funding = raised_amount WHERE current_funding IS NULL;

