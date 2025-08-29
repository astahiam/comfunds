-- Add cooperative image field to cooperatives table
ALTER TABLE cooperatives 
ADD COLUMN cooperative_image VARCHAR(500);

-- Add comment for documentation
COMMENT ON COLUMN cooperatives.cooperative_image IS 'Cooperative logo/image URL from AWS S3';
