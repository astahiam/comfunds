-- Remove business image field from businesses table
ALTER TABLE businesses 
DROP COLUMN IF EXISTS business_image;
