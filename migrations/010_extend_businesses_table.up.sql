-- Extend businesses table to match BusinessExtended entity
-- Add missing fields with appropriate NULL constraints

ALTER TABLE businesses 
ADD COLUMN IF NOT EXISTS business_image VARCHAR(500),
ADD COLUMN IF NOT EXISTS registration_number VARCHAR(100),
ADD COLUMN IF NOT EXISTS tax_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS legal_structure VARCHAR(100),
ADD COLUMN IF NOT EXISTS industry VARCHAR(100),
ADD COLUMN IF NOT EXISTS sector VARCHAR(100),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS phone VARCHAR(50),
ADD COLUMN IF NOT EXISTS email VARCHAR(255),
ADD COLUMN IF NOT EXISTS website VARCHAR(500),
ADD COLUMN IF NOT EXISTS established_date DATE,
ADD COLUMN IF NOT EXISTS employee_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS annual_revenue DECIMAL(15,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'IDR',
ADD COLUMN IF NOT EXISTS bank_account VARCHAR(100),
ADD COLUMN IF NOT EXISTS business_license VARCHAR(500),
ADD COLUMN IF NOT EXISTS documents JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'draft',
ADD COLUMN IF NOT EXISTS approved_by UUID,
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS performance_metrics JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS compliance_status JSONB DEFAULT '{}';

-- Update existing records to have sensible defaults for new fields
UPDATE businesses 
SET 
    registration_number = COALESCE(registration_number, 'REG-' || EXTRACT(EPOCH FROM created_at)::TEXT),
    legal_structure = COALESCE(legal_structure, 'PT'),
    industry = COALESCE(industry, 'Other'),
    address = COALESCE(address, 'Not specified'),
    phone = COALESCE(phone, ''),
    email = COALESCE(email, ''),
    established_date = COALESCE(established_date, created_at::DATE),
    status = COALESCE(status, 'pending_approval')
WHERE 
    registration_number IS NULL OR 
    legal_structure IS NULL OR 
    industry IS NULL OR 
    address IS NULL OR 
    phone IS NULL OR 
    email IS NULL OR 
    established_date IS NULL OR 
    status IS NULL;

-- Add indexes for new searchable fields
CREATE INDEX IF NOT EXISTS idx_businesses_registration_number ON businesses(registration_number);
CREATE INDEX IF NOT EXISTS idx_businesses_industry ON businesses(industry);
CREATE INDEX IF NOT EXISTS idx_businesses_status ON businesses(status);
CREATE INDEX IF NOT EXISTS idx_businesses_email ON businesses(email);
CREATE INDEX IF NOT EXISTS idx_businesses_approved_by ON businesses(approved_by);
CREATE INDEX IF NOT EXISTS idx_businesses_approved_at ON businesses(approved_at);

-- Add constraints for status values
ALTER TABLE businesses 
ADD CONSTRAINT IF NOT EXISTS chk_business_status 
CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'suspended', 'active', 'inactive'));
