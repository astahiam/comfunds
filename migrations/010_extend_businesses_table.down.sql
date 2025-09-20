-- Rollback: Remove extended fields from businesses table

-- Drop indexes
DROP INDEX IF EXISTS idx_businesses_approved_at;
DROP INDEX IF EXISTS idx_businesses_approved_by;
DROP INDEX IF EXISTS idx_businesses_email;
DROP INDEX IF EXISTS idx_businesses_status;
DROP INDEX IF EXISTS idx_businesses_industry;
DROP INDEX IF EXISTS idx_businesses_registration_number;

-- Drop constraints
ALTER TABLE businesses DROP CONSTRAINT IF EXISTS chk_business_status;

-- Remove added columns
ALTER TABLE businesses 
DROP COLUMN IF EXISTS compliance_status,
DROP COLUMN IF EXISTS performance_metrics,
DROP COLUMN IF EXISTS metadata,
DROP COLUMN IF EXISTS rejection_reason,
DROP COLUMN IF EXISTS approved_at,
DROP COLUMN IF EXISTS approved_by,
DROP COLUMN IF EXISTS status,
DROP COLUMN IF EXISTS documents,
DROP COLUMN IF EXISTS business_license,
DROP COLUMN IF EXISTS bank_account,
DROP COLUMN IF EXISTS currency,
DROP COLUMN IF EXISTS annual_revenue,
DROP COLUMN IF EXISTS employee_count,
DROP COLUMN IF EXISTS established_date,
DROP COLUMN IF EXISTS website,
DROP COLUMN IF EXISTS email,
DROP COLUMN IF EXISTS phone,
DROP COLUMN IF EXISTS address,
DROP COLUMN IF EXISTS sector,
DROP COLUMN IF EXISTS industry,
DROP COLUMN IF EXISTS legal_structure,
DROP COLUMN IF EXISTS tax_id,
DROP COLUMN IF EXISTS registration_number,
DROP COLUMN IF EXISTS business_image;
