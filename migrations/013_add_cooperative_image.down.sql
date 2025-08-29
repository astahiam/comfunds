-- Remove cooperative image field from cooperatives table
ALTER TABLE cooperatives 
DROP COLUMN IF EXISTS cooperative_image;
