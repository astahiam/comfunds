-- Add business image field to businesses table
ALTER TABLE businesses 
ADD COLUMN business_image VARCHAR(500);

-- Add comment for documentation
COMMENT ON COLUMN businesses.business_image IS 'Business logo/image URL from AWS S3';
