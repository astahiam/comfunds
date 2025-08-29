-- Add image fields to projects table
ALTER TABLE projects 
ADD COLUMN project_image_1 VARCHAR(500),
ADD COLUMN project_image_2 VARCHAR(500),
ADD COLUMN project_image_3 VARCHAR(500);

-- Add comments for documentation
COMMENT ON COLUMN projects.project_image_1 IS 'Primary project image URL from AWS S3';
COMMENT ON COLUMN projects.project_image_2 IS 'Secondary project image URL from AWS S3';
COMMENT ON COLUMN projects.project_image_3 IS 'Tertiary project image URL from AWS S3';
