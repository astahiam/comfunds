-- Schema Migration Script for comfunds02
-- This script ensures the database schema matches the expected structure
-- Safe to run multiple times (idempotent)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- USERS TABLE MIGRATION
-- ============================================

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add id column if missing (UUID type)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'id'
    ) THEN
        ALTER TABLE users ADD COLUMN id UUID DEFAULT uuid_generate_v4();
        
        -- Set id for existing rows
        UPDATE users SET id = uuid_generate_v4() WHERE id IS NULL;
        
        -- Add primary key if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conname = 'users_pkey'
        ) THEN
            ALTER TABLE users ADD PRIMARY KEY (id);
        END IF;
    END IF;
END $$;

-- Add cooperative_id column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'cooperative_id'
    ) THEN
        ALTER TABLE users ADD COLUMN cooperative_id UUID;
    END IF;
END $$;

-- Add roles column if missing (JSONB)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'roles'
    ) THEN
        ALTER TABLE users ADD COLUMN roles JSONB DEFAULT '[]'::jsonb;
    END IF;
END $$;

-- Add kyc_status column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'kyc_status'
    ) THEN
        ALTER TABLE users ADD COLUMN kyc_status VARCHAR(50) DEFAULT 'pending';
    END IF;
END $$;

-- Add user_profile_image column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'user_profile_image'
    ) THEN
        ALTER TABLE users ADD COLUMN user_profile_image VARCHAR(500);
    END IF;
END $$;

-- Add membership_payment_proof column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'membership_payment_proof'
    ) THEN
        ALTER TABLE users ADD COLUMN membership_payment_proof VARCHAR(500);
    END IF;
END $$;

-- Ensure id column is UUID type (convert if needed)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'id'
        AND data_type != 'uuid'
    ) THEN
        -- Create temporary UUID column
        ALTER TABLE users ADD COLUMN id_new UUID DEFAULT uuid_generate_v4();
        
        -- Copy data if id is integer
        UPDATE users SET id_new = uuid_generate_v4() WHERE id_new IS NULL;
        
        -- Drop old column and rename
        ALTER TABLE users DROP COLUMN id;
        ALTER TABLE users RENAME COLUMN id_new TO id;
        ALTER TABLE users ADD PRIMARY KEY (id);
    END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_cooperative_id ON users(cooperative_id);
CREATE INDEX IF NOT EXISTS idx_users_roles ON users USING GIN(roles);
CREATE INDEX IF NOT EXISTS idx_users_kyc_status ON users(kyc_status);
CREATE INDEX IF NOT EXISTS idx_users_membership_payment_proof ON users(membership_payment_proof) WHERE membership_payment_proof IS NOT NULL;

-- ============================================
-- COOPERATIVES TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS cooperatives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    bank_account VARCHAR(100) NOT NULL,
    profit_sharing_policy JSONB DEFAULT '{}',
    cooperative_image VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- BUSINESSES TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    owner_id UUID NOT NULL,
    cooperative_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    approval_status VARCHAR(50) DEFAULT 'draft',
    registration_number VARCHAR(100),
    legal_structure VARCHAR(100),
    industry VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255),
    established_date DATE,
    employee_count INTEGER DEFAULT 0,
    annual_revenue DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'IDR',
    bank_account VARCHAR(100),
    business_license VARCHAR(100),
    documents JSONB DEFAULT '[]',
    business_image VARCHAR(500),
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_by UUID,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_businesses_owner_id ON businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_cooperative_id ON businesses(cooperative_id);

-- ============================================
-- PROJECTS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    business_id UUID NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    funding_goal DECIMAL(15,2) NOT NULL,
    current_funding DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'IDR',
    status VARCHAR(50) DEFAULT 'draft',
    approval_status VARCHAR(50) DEFAULT 'draft',
    start_date DATE,
    end_date DATE,
    profit_sharing_percentage DECIMAL(5,2),
    risk_level VARCHAR(20),
    project_images JSONB DEFAULT '[]',
    category VARCHAR(100),
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_by UUID,
    rejected_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    sharia_compliant BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_projects_business_id ON projects(business_id);

-- ============================================
-- INVESTMENTS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS investments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL,
    investor_id UUID NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    status VARCHAR(50) DEFAULT 'pending',
    profit_share DECIMAL(5,2),
    disbursed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_investments_project_id ON investments(project_id);
CREATE INDEX IF NOT EXISTS idx_investments_investor_id ON investments(investor_id);

-- ============================================
-- AUDIT LOGS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    operation VARCHAR(100) NOT NULL,
    user_id UUID,
    ip_address INET,
    user_agent TEXT,
    changes JSONB,
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    status VARCHAR(50),
    error_msg TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- PROFIT DISTRIBUTIONS TABLE MIGRATION
-- ============================================

CREATE TABLE IF NOT EXISTS profit_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL,
    investment_id UUID NOT NULL,
    investor_id UUID NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    distribution_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- FOREIGN KEY CONSTRAINTS (if needed)
-- ============================================

-- Note: Foreign keys are optional in sharded architecture
-- Uncomment if you want referential integrity

-- ALTER TABLE users ADD CONSTRAINT fk_users_cooperative 
--     FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id);

-- ALTER TABLE businesses ADD CONSTRAINT fk_businesses_owner 
--     FOREIGN KEY (owner_id) REFERENCES users(id);

-- ALTER TABLE businesses ADD CONSTRAINT fk_businesses_cooperative 
--     FOREIGN KEY (cooperative_id) REFERENCES cooperatives(id);

-- ALTER TABLE projects ADD CONSTRAINT fk_projects_business 
--     FOREIGN KEY (business_id) REFERENCES businesses(id);

-- ALTER TABLE investments ADD CONSTRAINT fk_investments_project 
--     FOREIGN KEY (project_id) REFERENCES projects(id);

-- ALTER TABLE investments ADD CONSTRAINT fk_investments_investor 
--     FOREIGN KEY (investor_id) REFERENCES users(id);

-- ALTER TABLE profit_distributions ADD CONSTRAINT fk_profit_distributions_project 
--     FOREIGN KEY (project_id) REFERENCES projects(id);

