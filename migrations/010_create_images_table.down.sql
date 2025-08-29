-- Drop trigger and function
DROP TRIGGER IF EXISTS trigger_update_images_updated_at ON images;
DROP FUNCTION IF EXISTS update_images_updated_at();

-- Drop indexes
DROP INDEX IF EXISTS idx_images_used_by;
DROP INDEX IF EXISTS idx_images_created_at;

-- Drop table
DROP TABLE IF EXISTS images;
