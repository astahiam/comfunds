-- Remove user profile image field from users table
ALTER TABLE users 
DROP COLUMN IF EXISTS user_profile_image;
