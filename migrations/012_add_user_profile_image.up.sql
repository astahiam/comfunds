-- Add user profile image field to users table
ALTER TABLE users 
ADD COLUMN user_profile_image VARCHAR(500);

-- Add comment for documentation
COMMENT ON COLUMN users.user_profile_image IS 'User profile image URL from AWS S3';
