DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
DROP INDEX IF EXISTS idx_projects_funding_goal;
DROP INDEX IF EXISTS idx_projects_created_at;
DROP INDEX IF EXISTS idx_projects_funding_deadline;
DROP INDEX IF EXISTS idx_projects_project_type;
DROP INDEX IF EXISTS idx_projects_status;
DROP INDEX IF EXISTS idx_projects_business_id;
DROP TABLE IF EXISTS projects;
