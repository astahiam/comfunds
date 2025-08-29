-- Remove image fields from projects table
ALTER TABLE projects 
DROP COLUMN IF EXISTS project_image_1,
DROP COLUMN IF EXISTS project_image_2,
DROP COLUMN IF EXISTS project_image_3;
