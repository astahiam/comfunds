-- Restore funding_goal NOT NULL constraint
ALTER TABLE projects ALTER COLUMN funding_goal SET NOT NULL;
ALTER TABLE projects ALTER COLUMN current_funding SET NOT NULL;

