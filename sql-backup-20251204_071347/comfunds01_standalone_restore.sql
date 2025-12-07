-- ============================================
-- STANDALONE RESTORE SCRIPT FOR comfunds01
-- ============================================
-- This is a COMPLETELY SELF-CONTAINED script
-- Usage: psql -U postgres -d postgres -f comfunds01_standalone_restore.sql
-- Or: docker exec -i container_name psql -U postgres -d postgres < comfunds01_standalone_restore.sql
-- 
-- This file contains EVERYTHING needed to restore comfunds01:
-- 1. Database creation
-- 2. Schema migrations (handles missing columns, indexes, etc.)
-- 3. All data
-- ============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE comfunds01'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds01')\gexec

-- Connect to the database
\c comfunds01

-- Schema Migration Script for comfunds01
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


-- ============================================
-- IMPORT DATA FOR comfunds01
-- ============================================






ALTER TABLE public.audit_logs DISABLE TRIGGER ALL;

COPY public.audit_logs (id, entity_type, entity_id, operation, user_id, ip_address, user_agent, changes, old_values, new_values, reason, status, error_msg, created_at) FROM stdin;


ALTER TABLE public.audit_logs ENABLE TRIGGER ALL;


ALTER TABLE public.businesses DISABLE TRIGGER ALL;

COPY public.businesses (id, name, business_type, description, owner_id, cooperative_id, registration_documents, approval_status, is_active, created_at, updated_at, business_image, registration_number, tax_id, legal_structure, industry, sector, address, phone, email, website, established_date, employee_count, annual_revenue, currency, bank_account, business_license, documents, status, approved_by, approved_at, rejection_reason, metadata, performance_metrics, compliance_status) FROM stdin;
05e4e524-5c1c-4d07-925f-4923c034c699	Kolam Koi Breeding	agriculture	Pembiakan ikan koi	ffcee1b1-019d-4105-8be8-790e0959074e	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-09-20 14:49:09.846051+07	2025-09-20 16:09:34.344197+07	\N	0101-PT-CAFE-0980947		PT	Agrobisnis		Jl. Babakan Radio Bandung	+628131313131	ryan.kharisma@outlook.com		2025-09-19	11	1.00	IDR	13700111234	093-PT00284-CAFE09394	[]	draft	\N	\N	\N	null	null	null
00b6e0c6-c515-4bf3-8888-21d2328ec95b	Konter hp Alip	technology	membeli hp lalu hp yang dibeli dijual	672529e8-f0e5-4679-b3a7-9e2ab9fc9cfb	550e8400-e29b-41d4-a716-446655440001	{}	pending	t	2025-10-11 22:47:01.969464+07	2025-10-11 22:47:01.969464+07	\N	Nomor registrasi 1234		PT	handphone		127 greenlake	89132154	aliep@gmail.com	https:/konterhp.com	2025-10-11	100	1000000000.00	EUR	1234567890123	123	[]	draft	\N	\N	\N	null	null	null


ALTER TABLE public.businesses ENABLE TRIGGER ALL;


ALTER TABLE public.cooperatives DISABLE TRIGGER ALL;

COPY public.cooperatives (id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at, cooperative_image) FROM stdin;
5eac8a28-5879-433c-aa3f-e452195b77df	Cooperative 1	COOP-2024-001-5000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-22 16:55:09.11003+07	2025-08-22 16:55:09.11003+07	\N
22b42f64-be6e-4f9d-826d-3ed9d9fa6094	Cooperative 5	COOP-2024-005-1000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-22 16:55:09.117485+07	2025-08-22 16:55:09.117485+07	\N
a94daec9-7a87-454d-9450-ea05e1adeeab	Cooperative 9	COOP-2024-009-4000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-22 16:55:09.120316+07	2025-08-22 16:55:09.120316+07	\N
7627e9ef-5116-4d21-a3d9-e3fa914bee97	Cooperative 13	COOP-2024-013-6000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-22 16:55:09.122891+07	2025-08-22 16:55:09.122891+07	\N
017d4212-15e7-434d-95e2-49bc85846d5c	Cooperative 17	COOP-2024-017-9000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-22 16:55:09.126183+07	2025-08-22 16:55:09.126183+07	\N
ea3bc417-55ba-4b15-b705-2b97c6e4fedd	Cooperative 1	COOP-2024-001-7000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-22 16:55:46.02607+07	2025-08-22 16:55:46.02607+07	\N
57f0ae36-5498-4b5c-94e5-2ca0dccf304f	Cooperative 1	COOP-2024-001-1755856577350170000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-22 16:56:17.350173+07	2025-08-22 16:56:17.350173+07	\N
1edf1eac-c27a-448e-b884-e9bcc9ef7520	Cooperative 5	COOP-2024-005-1755856577353095000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-22 16:56:17.353098+07	2025-08-22 16:56:17.353099+07	\N
7b7630a5-00a7-47df-9084-2d8dbe9af173	Cooperative 9	COOP-2024-009-1755856577359205000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-22 16:56:17.359208+07	2025-08-22 16:56:17.359208+07	\N
88c2c694-91a2-4efa-b59f-806103a9ec48	Cooperative 13	COOP-2024-013-1755856577362056000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-22 16:56:17.362059+07	2025-08-22 16:56:17.36206+07	\N
83915c21-b20a-4865-8244-be372f00e8b5	Cooperative 17	COOP-2024-017-1755856577364861000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-22 16:56:17.364863+07	2025-08-22 16:56:17.364863+07	\N
ce9b0e03-1c06-4db7-af26-96c133b998cb	Cooperative 1	COOP-2024-001-1755858945244848000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-22 17:35:45.24485+07	2025-08-22 17:35:45.24485+07	\N
407a5339-b865-4717-9ab2-70edc9e68487	Cooperative 5	COOP-2024-005-1755858945248694000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-22 17:35:45.248696+07	2025-08-22 17:35:45.248696+07	\N
22449053-e9d6-43aa-a281-db963479d420	Cooperative 9	COOP-2024-009-1755858945250199000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-22 17:35:45.250201+07	2025-08-22 17:35:45.250201+07	\N
5348023f-ac94-49fc-80e9-ae7d9257c196	Cooperative 13	COOP-2024-013-1755858945251552000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-22 17:35:45.251554+07	2025-08-22 17:35:45.251554+07	\N
b618a131-0478-465f-bf3a-f6fe2369101f	Cooperative 17	COOP-2024-017-1755858945252953000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-22 17:35:45.252954+07	2025-08-22 17:35:45.252954+07	\N
5e05a1a2-7fe4-4521-ad1c-6c0e7e6a6be4	Cooperative 1	COOP-2024-001-1756473775211142000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-29 20:22:55.211152+07	2025-08-29 20:22:55.211152+07	\N
01e029d2-217f-4468-8eff-55cd5b0b132b	Cooperative 5	COOP-2024-005-1756473775217337000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-29 20:22:55.21734+07	2025-08-29 20:22:55.21734+07	\N
8de9a783-c4d5-427f-b3c1-5392e704a386	Cooperative 9	COOP-2024-009-1756473775219783000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-29 20:22:55.219786+07	2025-08-29 20:22:55.219786+07	\N
093e1107-0aa8-4b2f-9e22-c5d61f8d16ba	Cooperative 13	COOP-2024-013-1756473775222129000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-29 20:22:55.222131+07	2025-08-29 20:22:55.222132+07	\N
4b1b8eda-8f84-4b67-9849-58e3a3ccd78e	Cooperative 17	COOP-2024-017-1756473775223782000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-29 20:22:55.223785+07	2025-08-29 20:22:55.223785+07	\N
f288e546-f8fd-476b-847c-e7f6c61111b1	Cooperative 1	COOP-2024-001-1756475953202378000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-29 20:59:13.202382+07	2025-08-29 20:59:13.202382+07	\N
47e362c5-900d-420d-81af-f2b344dffac0	Cooperative 5	COOP-2024-005-1756475953209748000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-29 20:59:13.209751+07	2025-08-29 20:59:13.209751+07	\N
5cd57274-74f6-406e-a10d-db12c3c55419	Cooperative 9	COOP-2024-009-1756475953212750000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-29 20:59:13.212752+07	2025-08-29 20:59:13.212752+07	\N
99d64b3d-e426-42e9-864a-4574df387691	Cooperative 13	COOP-2024-013-1756475953214899000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-29 20:59:13.214901+07	2025-08-29 20:59:13.214901+07	\N
584fef0c-f1fc-47e5-a6d1-edd2bd55f192	Cooperative 17	COOP-2024-017-1756475953216492000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-29 20:59:13.216494+07	2025-08-29 20:59:13.216494+07	\N
969cf1a8-94ad-4800-95ab-b119f845417e	Cooperative 1	COOP-2024-001-1756479580166754000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-29 21:59:40.166761+07	2025-08-29 21:59:40.166761+07	\N
24e71ded-5d82-457d-95ea-7515dcbfbc9b	Cooperative 5	COOP-2024-005-1756479580185388000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-29 21:59:40.185392+07	2025-08-29 21:59:40.185392+07	\N
2cc7d639-f753-4c75-8e3a-1b356620e50b	Cooperative 9	COOP-2024-009-1756479580200716000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-29 21:59:40.200724+07	2025-08-29 21:59:40.200725+07	\N
a7434d18-3782-4bbc-8583-2c5c3cc92736	Cooperative 13	COOP-2024-013-1756479580247573000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-29 21:59:40.247579+07	2025-08-29 21:59:40.247579+07	\N
5f3786c0-43ad-465c-8f42-79bc8433867c	Cooperative 17	COOP-2024-017-1756479580251370000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-29 21:59:40.251373+07	2025-08-29 21:59:40.251373+07	\N
e47f92ea-de17-4520-83db-02a43b5c67c7	Cooperative 1	COOP-2024-001-1756479720902438000	Address 1	+12345670001	coop1@example.com	1234567891	{}	t	2025-08-29 22:02:00.90244+07	2025-08-29 22:02:00.90244+07	\N
adb79af7-7673-4e5f-8e4d-cbf26a9b3ddc	Cooperative 5	COOP-2024-005-1756479720905127000	Address 5	+12345670005	coop5@example.com	1234567895	{}	t	2025-08-29 22:02:00.905129+07	2025-08-29 22:02:00.905129+07	\N
4c8024b6-4a9e-4c3f-a15a-537aa023fb8e	Cooperative 9	COOP-2024-009-1756479720907404000	Address 9	+12345670009	coop9@example.com	1234567899	{}	t	2025-08-29 22:02:00.907406+07	2025-08-29 22:02:00.907407+07	\N
c3d7ca1e-718e-46eb-ac38-78d5e70b630f	Cooperative 13	COOP-2024-013-1756479720909525000	Address 13	+12345670013	coop13@example.com	12345678913	{}	t	2025-08-29 22:02:00.909527+07	2025-08-29 22:02:00.909527+07	\N
3ae86844-e760-4244-a10d-5cda15188ac0	Cooperative 17	COOP-2024-017-1756479720911177000	Address 17	+12345670017	coop17@example.com	12345678917	{}	t	2025-08-29 22:02:00.91118+07	2025-08-29 22:02:00.91118+07	\N
550e8400-e29b-41d4-a716-446655440001	Koperasi Haji	KH-001-2024	Jl. Masjidil Haram No. 123, Jakarta Pusat	+62-21-12345678	info@koperasihaji.id	1234567890	{"platform_fee": 5, "default_business_share": 30, "default_investor_share": 70}	t	2025-09-19 19:44:36.321691+07	2025-09-19 21:37:14.930912+07	\N
550e8400-e29b-41d4-a716-446655440002	Koperasi SIDANA	SIDANA-002-2024	Jl. Simpan Pinjam No. 456, Jakarta Selatan	+62-21-87654321	info@koperasisidana.id	0987654321	{"platform_fee": 3, "default_business_share": 25, "default_investor_share": 75}	t	2025-09-19 19:44:36.321691+07	2025-09-19 21:37:14.930912+07	\N


ALTER TABLE public.cooperatives ENABLE TRIGGER ALL;


ALTER TABLE public.idempotency_keys DISABLE TRIGGER ALL;

COPY public.idempotency_keys (id, user_id, endpoint, request_hash, response_data, status, created_at, expires_at, sequence_number, table_name, random_suffix) FROM stdin;


ALTER TABLE public.idempotency_keys ENABLE TRIGGER ALL;


ALTER TABLE public.images DISABLE TRIGGER ALL;

COPY public.images (id, image_url, image_name, used_by, image_size, created_at, updated_at) FROM stdin;


ALTER TABLE public.images ENABLE TRIGGER ALL;


ALTER TABLE public.users DISABLE TRIGGER ALL;

COPY public.users (email, name, password, phone, address, is_active, created_at, updated_at, id, cooperative_id, roles, kyc_status, user_profile_image, membership_payment_proof) FROM stdin;
user-0-a39a791f@example.com	User 0	hashedpassword	\N	\N	t	2025-08-22 16:55:09.030114+07	2025-08-22 16:55:09.030114+07	a39a791f-8a03-4356-924f-c5e2e90d1d0f	\N	["guest"]	pending	\N	\N
user-3-88db9f5d@example.com	User 3	hashedpassword	\N	\N	t	2025-08-22 16:55:09.043718+07	2025-08-22 16:55:09.043719+07	88db9f5d-c695-4f4b-a4ee-776f1f91fea3	\N	["guest"]	pending	\N	\N
user-9-e13af88a@example.com	User 9	hashedpassword	\N	\N	t	2025-08-22 16:55:09.050568+07	2025-08-22 16:55:09.050568+07	e13af88a-60a9-4415-af95-ea712cad30a2	\N	["guest"]	pending	\N	\N
user-11-009f0fc0@example.com	User 11	hashedpassword	\N	\N	t	2025-08-22 16:55:09.051932+07	2025-08-22 16:55:09.051932+07	009f0fc0-cbb0-41b3-9752-0ac6c28cc5f6	\N	["guest"]	pending	\N	\N
user-24-63bdf00c@example.com	User 24	hashedpassword	\N	\N	t	2025-08-22 16:55:09.061125+07	2025-08-22 16:55:09.061125+07	63bdf00c-e7c9-4f3c-8251-0f0360536228	\N	["guest"]	pending	\N	\N
user-25-a6cd7968@example.com	User 25	hashedpassword	\N	\N	t	2025-08-22 16:55:09.061642+07	2025-08-22 16:55:09.061642+07	a6cd7968-07ff-46da-96d8-511d2f13e556	\N	["guest"]	pending	\N	\N
user-26-cdfa14d3@example.com	User 26	hashedpassword	\N	\N	t	2025-08-22 16:55:09.062074+07	2025-08-22 16:55:09.062074+07	cdfa14d3-bf30-4314-9ef3-89aefca43cc5	\N	["guest"]	pending	\N	\N
user-27-7440918b@example.com	User 27	hashedpassword	\N	\N	t	2025-08-22 16:55:09.062525+07	2025-08-22 16:55:09.062525+07	7440918b-991f-4df4-aaf7-02b81b7bee7d	\N	["guest"]	pending	\N	\N
user-28-ce89e7f5@example.com	User 28	hashedpassword	\N	\N	t	2025-08-22 16:55:09.06313+07	2025-08-22 16:55:09.06313+07	ce89e7f5-572b-425a-a428-903f2f10b8c0	\N	["guest"]	pending	\N	\N
user-33-a66290a1@example.com	User 33	hashedpassword	\N	\N	t	2025-08-22 16:55:09.066151+07	2025-08-22 16:55:09.066151+07	a66290a1-0e30-43f2-9a78-0fd9d1082b6b	\N	["guest"]	pending	\N	\N
user-40-c6143680@example.com	User 40	hashedpassword	\N	\N	t	2025-08-22 16:55:09.071112+07	2025-08-22 16:55:09.071112+07	c6143680-ce6a-45ee-905f-41fd547de4a4	\N	["guest"]	pending	\N	\N
user-44-42127698@example.com	User 44	hashedpassword	\N	\N	t	2025-08-22 16:55:09.074443+07	2025-08-22 16:55:09.074443+07	42127698-a08c-4512-93f4-c98c0b7675b4	\N	["guest"]	pending	\N	\N
user-52-1b69dba6@example.com	User 52	hashedpassword	\N	\N	t	2025-08-22 16:55:09.080012+07	2025-08-22 16:55:09.080012+07	1b69dba6-df1a-4c82-9ee3-29a8a6be844f	\N	["guest"]	pending	\N	\N
user-53-3446de50@example.com	User 53	hashedpassword	\N	\N	t	2025-08-22 16:55:09.080566+07	2025-08-22 16:55:09.080566+07	3446de50-807e-4857-83b1-ca484cbfc4ad	\N	["guest"]	pending	\N	\N
user-54-3d36ceca@example.com	User 54	hashedpassword	\N	\N	t	2025-08-22 16:55:09.081205+07	2025-08-22 16:55:09.081205+07	3d36ceca-60f3-4465-9821-a3b9c893952b	\N	["guest"]	pending	\N	\N
user-57-3a71cf7d@example.com	User 57	hashedpassword	\N	\N	t	2025-08-22 16:55:09.08272+07	2025-08-22 16:55:09.08272+07	3a71cf7d-4a27-4671-b479-790affbce572	\N	["guest"]	pending	\N	\N
user-63-f5af1f91@example.com	User 63	hashedpassword	\N	\N	t	2025-08-22 16:55:09.085095+07	2025-08-22 16:55:09.085095+07	f5af1f91-ff04-4c27-9fce-0a6a3f2bf779	\N	["guest"]	pending	\N	\N
user-67-ad8bb16c@example.com	User 67	hashedpassword	\N	\N	t	2025-08-22 16:55:09.086449+07	2025-08-22 16:55:09.086449+07	ad8bb16c-89f4-4c09-b1c6-299ad66be106	\N	["guest"]	pending	\N	\N
user-73-844951d1@example.com	User 73	hashedpassword	\N	\N	t	2025-08-22 16:55:09.090405+07	2025-08-22 16:55:09.090405+07	844951d1-ed33-4d86-9932-82c978645f18	\N	["guest"]	pending	\N	\N
user-74-19d27266@example.com	User 74	hashedpassword	\N	\N	t	2025-08-22 16:55:09.091099+07	2025-08-22 16:55:09.091099+07	19d27266-223b-465c-995b-797da7621353	\N	["guest"]	pending	\N	\N
user-76-08fa6825@example.com	User 76	hashedpassword	\N	\N	t	2025-08-22 16:55:09.09256+07	2025-08-22 16:55:09.09256+07	08fa6825-3005-44d9-9697-b271d93d20a0	\N	["guest"]	pending	\N	\N
user-77-7d85b598@example.com	User 77	hashedpassword	\N	\N	t	2025-08-22 16:55:09.093397+07	2025-08-22 16:55:09.093397+07	7d85b598-6705-43be-8295-53c6dbc74b72	\N	["guest"]	pending	\N	\N
user-78-27666426@example.com	User 78	hashedpassword	\N	\N	t	2025-08-22 16:55:09.093868+07	2025-08-22 16:55:09.093869+07	27666426-97c7-4fce-a325-d11c45caf782	\N	["guest"]	pending	\N	\N
user-80-f5051604@example.com	User 80	hashedpassword	\N	\N	t	2025-08-22 16:55:09.09465+07	2025-08-22 16:55:09.094651+07	f5051604-991d-47c7-b77e-81ca4e606dca	\N	["guest"]	pending	\N	\N
user-85-491f141a@example.com	User 85	hashedpassword	\N	\N	t	2025-08-22 16:55:09.097182+07	2025-08-22 16:55:09.097182+07	491f141a-63eb-4a24-9b74-e79d1d0581c1	\N	["guest"]	pending	\N	\N
user-94-a6cd76eb@example.com	User 94	hashedpassword	\N	\N	t	2025-08-22 16:55:09.102403+07	2025-08-22 16:55:09.102403+07	a6cd76eb-3a6b-4094-bc1f-6251d38051ca	\N	["guest"]	pending	\N	\N
user-97-6849e58d@example.com	User 97	hashedpassword	\N	\N	t	2025-08-22 16:55:09.10367+07	2025-08-22 16:55:09.10367+07	6849e58d-562c-4fc2-bbe2-189d8497dd61	\N	["guest"]	pending	\N	\N
concurrent-user-1-d0ba0179@example.com	Concurrent User 1	password	\N	\N	t	2025-08-22 16:55:09.326109+07	2025-08-22 16:55:09.32611+07	d0ba0179-23ce-40f5-9eab-894c0c20d24d	\N	["guest"]	pending	\N	\N
perf-test-0-ff5ef2cd@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:09.496724+07	2025-08-22 16:55:09.496724+07	ff5ef2cd-ec41-4585-a4a6-30e548318359	\N	["guest"]	pending	\N	\N
perf-test-1-bab5008d@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:09.49738+07	2025-08-22 16:55:09.49738+07	bab5008d-c868-4eef-87f7-586449d62348	\N	["guest"]	pending	\N	\N
perf-test-2-da384765@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:09.498641+07	2025-08-22 16:55:09.498642+07	da384765-2d8c-4682-b74f-25ba4b73696d	\N	["guest"]	pending	\N	\N
perf-test-3-4cf803e6@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:09.499735+07	2025-08-22 16:55:09.499735+07	4cf803e6-fc80-4b4b-a73b-65dd12aeea32	\N	["guest"]	pending	\N	\N
perf-test-4-4981939e@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:09.500804+07	2025-08-22 16:55:09.500804+07	4981939e-8336-4cd2-b65d-e5eb53759667	\N	["guest"]	pending	\N	\N
perf-test-5-636c5ebb@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:09.501505+07	2025-08-22 16:55:09.501505+07	636c5ebb-9e74-456f-914f-5f3ed638435e	\N	["guest"]	pending	\N	\N
perf-test-6-5fdc40f9@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:09.502125+07	2025-08-22 16:55:09.502126+07	5fdc40f9-9b50-4562-8060-60b65be57d05	\N	["guest"]	pending	\N	\N
perf-test-7-75f93324@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:09.50274+07	2025-08-22 16:55:09.50274+07	75f93324-9361-4341-aeaa-4a02f0e8a952	\N	["guest"]	pending	\N	\N
perf-test-8-1cc64216@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:09.503258+07	2025-08-22 16:55:09.503258+07	1cc64216-2b9d-46e4-9960-a5c792d802da	\N	["guest"]	pending	\N	\N
perf-test-9-f50d9fec@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:09.503793+07	2025-08-22 16:55:09.503793+07	f50d9fec-2e94-48e2-a121-6f29b0a26952	\N	["guest"]	pending	\N	\N
perf-test-10-0e676621@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:09.504509+07	2025-08-22 16:55:09.504509+07	0e676621-da4b-46a9-9d5c-aad4a8cb8fce	\N	["guest"]	pending	\N	\N
perf-test-11-bcad02b9@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:09.505149+07	2025-08-22 16:55:09.505149+07	bcad02b9-eab3-488d-9c20-6851292cebc6	\N	["guest"]	pending	\N	\N
perf-test-12-5bc69075@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:09.505833+07	2025-08-22 16:55:09.505833+07	5bc69075-6d97-4d2e-92c2-5511eaec5273	\N	["guest"]	pending	\N	\N
perf-test-13-755e1c58@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:09.506919+07	2025-08-22 16:55:09.506919+07	755e1c58-b9ab-46ef-a9cb-a352ce2dd310	\N	["guest"]	pending	\N	\N
perf-test-14-16e31833@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:09.50862+07	2025-08-22 16:55:09.50862+07	16e31833-499b-4c3a-af93-9cf16dacb85a	\N	["guest"]	pending	\N	\N
perf-test-15-2db086d1@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:09.509756+07	2025-08-22 16:55:09.509756+07	2db086d1-66de-4d7a-b22d-be149453a36a	\N	["guest"]	pending	\N	\N
perf-test-16-ae7cf2fa@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:09.510629+07	2025-08-22 16:55:09.510629+07	ae7cf2fa-d789-43d3-9c9a-b42b478e58e4	\N	["guest"]	pending	\N	\N
perf-test-17-0baf67f0@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:09.511281+07	2025-08-22 16:55:09.511281+07	0baf67f0-741a-4b98-a9b4-0c021f959cce	\N	["guest"]	pending	\N	\N
perf-test-18-89f00697@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:09.511761+07	2025-08-22 16:55:09.511761+07	89f00697-6150-4100-be6b-e1ff6228221c	\N	["guest"]	pending	\N	\N
perf-test-19-bbbba747@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:09.512441+07	2025-08-22 16:55:09.512441+07	bbbba747-ef38-4763-862d-51b634b65ecc	\N	["guest"]	pending	\N	\N
perf-test-20-a4741be5@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:09.513112+07	2025-08-22 16:55:09.513112+07	a4741be5-e15a-4fa6-8897-74879278e85d	\N	["guest"]	pending	\N	\N
perf-test-21-abb0f3e2@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:09.513739+07	2025-08-22 16:55:09.513739+07	abb0f3e2-5757-436a-8177-0160166850f4	\N	["guest"]	pending	\N	\N
perf-test-22-93a36d65@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:09.51441+07	2025-08-22 16:55:09.51441+07	93a36d65-22f2-4994-ac0c-a8bdae0bc937	\N	["guest"]	pending	\N	\N
perf-test-23-b501648d@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:09.5152+07	2025-08-22 16:55:09.515201+07	b501648d-3847-4359-99bc-9f4d84e50560	\N	["guest"]	pending	\N	\N
perf-test-24-9db3bdfa@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:09.515982+07	2025-08-22 16:55:09.515982+07	9db3bdfa-922a-4459-a916-4a28e0574311	\N	["guest"]	pending	\N	\N
perf-test-25-7385ce9c@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:09.516693+07	2025-08-22 16:55:09.516693+07	7385ce9c-bf70-404d-a2d9-d24801f3c332	\N	["guest"]	pending	\N	\N
perf-test-26-ce2414fa@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:09.517964+07	2025-08-22 16:55:09.517965+07	ce2414fa-a68a-4219-bdce-1cbcd9bb4a2c	\N	["guest"]	pending	\N	\N
perf-test-27-a25ba1a8@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:09.518558+07	2025-08-22 16:55:09.518561+07	a25ba1a8-76fc-471e-aa2b-0c3ce267e4ee	\N	["guest"]	pending	\N	\N
perf-test-28-f7fbd54c@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:09.519172+07	2025-08-22 16:55:09.519172+07	f7fbd54c-f181-47ca-a914-33a913ee38d9	\N	["guest"]	pending	\N	\N
perf-test-29-80de6b10@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:09.519642+07	2025-08-22 16:55:09.519642+07	80de6b10-5cf5-49d0-b650-c2eba954e012	\N	["guest"]	pending	\N	\N
perf-test-30-0f798d98@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:09.520237+07	2025-08-22 16:55:09.520237+07	0f798d98-b93c-4c41-ba1c-aec05de02b38	\N	["guest"]	pending	\N	\N
perf-test-31-2059fc75@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:09.520659+07	2025-08-22 16:55:09.520659+07	2059fc75-7d60-43d2-9a32-f27649a8701f	\N	["guest"]	pending	\N	\N
perf-test-32-a3303077@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:09.521112+07	2025-08-22 16:55:09.521112+07	a3303077-b33e-4513-a42f-7a2f3add4819	\N	["guest"]	pending	\N	\N
perf-test-33-c66fffb3@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:09.521603+07	2025-08-22 16:55:09.521604+07	c66fffb3-6721-4383-96ef-08c67d9cf82f	\N	["guest"]	pending	\N	\N
perf-test-34-ec3509ba@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:09.522058+07	2025-08-22 16:55:09.522059+07	ec3509ba-b7ce-43f4-8ef1-4019528d71a4	\N	["guest"]	pending	\N	\N
perf-test-35-cc5986f7@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:09.522648+07	2025-08-22 16:55:09.522648+07	cc5986f7-149d-4487-a7e7-c5c0213c246a	\N	["guest"]	pending	\N	\N
perf-test-36-85e8347a@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:09.523202+07	2025-08-22 16:55:09.523202+07	85e8347a-8bfb-4655-aa01-bf0ab48aa90d	\N	["guest"]	pending	\N	\N
perf-test-37-84524e5b@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:09.523755+07	2025-08-22 16:55:09.523755+07	84524e5b-e50c-4bad-89de-f8a620752465	\N	["guest"]	pending	\N	\N
perf-test-38-ca64486e@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:09.524359+07	2025-08-22 16:55:09.524359+07	ca64486e-f911-4c63-9bbb-1af91a143d9f	\N	["guest"]	pending	\N	\N
perf-test-39-415ccaa9@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:09.525026+07	2025-08-22 16:55:09.525026+07	415ccaa9-99be-43d9-ac85-03e1ba6e38d9	\N	["guest"]	pending	\N	\N
perf-test-40-71e37e40@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:09.525644+07	2025-08-22 16:55:09.525644+07	71e37e40-04cd-40f8-9c09-2defd57e2a45	\N	["guest"]	pending	\N	\N
perf-test-41-54910dbd@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:09.526166+07	2025-08-22 16:55:09.526166+07	54910dbd-f013-4407-9d47-f35c87c82260	\N	["guest"]	pending	\N	\N
perf-test-42-1f23c012@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:09.52667+07	2025-08-22 16:55:09.52667+07	1f23c012-9a58-40c5-8635-a86ecbacb492	\N	["guest"]	pending	\N	\N
perf-test-43-68752286@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:09.527038+07	2025-08-22 16:55:09.527038+07	68752286-8628-41c5-b841-a1ee5b6b19a0	\N	["guest"]	pending	\N	\N
perf-test-44-ebd57395@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:09.527375+07	2025-08-22 16:55:09.527375+07	ebd57395-e1ca-4949-abc7-342db4ea99c0	\N	["guest"]	pending	\N	\N
perf-test-45-0ab21d91@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:09.527772+07	2025-08-22 16:55:09.527772+07	0ab21d91-7c1d-4496-b81c-f7ed291b73ae	\N	["guest"]	pending	\N	\N
perf-test-46-24702eb1@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:09.528099+07	2025-08-22 16:55:09.528099+07	24702eb1-fa4d-4275-b529-92c6ee2211fd	\N	["guest"]	pending	\N	\N
perf-test-47-dda4a126@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:09.528583+07	2025-08-22 16:55:09.528583+07	dda4a126-3282-4fdd-8682-712c4a88bf59	\N	["guest"]	pending	\N	\N
perf-test-48-e502ff4d@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:09.529149+07	2025-08-22 16:55:09.529149+07	e502ff4d-d121-4b4a-b9d2-177c596f3fe0	\N	["guest"]	pending	\N	\N
perf-test-49-bd9392e6@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:09.529603+07	2025-08-22 16:55:09.529603+07	bd9392e6-1575-490b-8ec6-f20926b52130	\N	["guest"]	pending	\N	\N
user-5-bb56ed0c@example.com	User 5	hashedpassword	\N	\N	t	2025-08-22 16:55:45.966348+07	2025-08-22 16:55:45.966348+07	bb56ed0c-c86d-4b92-8fcd-50a2546a9e23	\N	["guest"]	pending	\N	\N
user-11-e1c5612e@example.com	User 11	hashedpassword	\N	\N	t	2025-08-22 16:55:45.972845+07	2025-08-22 16:55:45.972846+07	e1c5612e-d921-46d9-9d02-cd192e07fae1	\N	["guest"]	pending	\N	\N
user-19-f5cbe9ab@example.com	User 19	hashedpassword	\N	\N	t	2025-08-22 16:55:45.976691+07	2025-08-22 16:55:45.976691+07	f5cbe9ab-b297-408a-87b0-9573504457e6	\N	["guest"]	pending	\N	\N
user-20-d59f8a61@example.com	User 20	hashedpassword	\N	\N	t	2025-08-22 16:55:45.977062+07	2025-08-22 16:55:45.977062+07	d59f8a61-c331-4f39-980d-02ed5ef6b41c	\N	["guest"]	pending	\N	\N
user-22-8d61134d@example.com	User 22	hashedpassword	\N	\N	t	2025-08-22 16:55:45.977777+07	2025-08-22 16:55:45.977777+07	8d61134d-c6bf-471a-9601-b0bcf5f3b56b	\N	["guest"]	pending	\N	\N
user-38-51f4d92c@example.com	User 38	hashedpassword	\N	\N	t	2025-08-22 16:55:45.988774+07	2025-08-22 16:55:45.988774+07	51f4d92c-5505-42bb-8564-cf042c813c59	\N	["guest"]	pending	\N	\N
user-39-1379e528@example.com	User 39	hashedpassword	\N	\N	t	2025-08-22 16:55:45.989314+07	2025-08-22 16:55:45.989314+07	1379e528-ee2c-4f41-831b-c3a365860ed9	\N	["guest"]	pending	\N	\N
user-45-435175de@example.com	User 45	hashedpassword	\N	\N	t	2025-08-22 16:55:45.9924+07	2025-08-22 16:55:45.992401+07	435175de-2a29-479a-b88b-889dea182664	\N	["guest"]	pending	\N	\N
user-55-3c070b6b@example.com	User 55	hashedpassword	\N	\N	t	2025-08-22 16:55:45.996812+07	2025-08-22 16:55:45.996812+07	3c070b6b-4459-4c4e-81c0-faa91e1e5586	\N	["guest"]	pending	\N	\N
user-56-e33d4584@example.com	User 56	hashedpassword	\N	\N	t	2025-08-22 16:55:45.998191+07	2025-08-22 16:55:45.998192+07	e33d4584-20fc-4f7b-976d-5ac002f8e5df	\N	["guest"]	pending	\N	\N
user-69-3da57875@example.com	User 69	hashedpassword	\N	\N	t	2025-08-22 16:55:46.006804+07	2025-08-22 16:55:46.006804+07	3da57875-51c3-4515-9bc5-116434134abc	\N	["guest"]	pending	\N	\N
user-73-8952cedc@example.com	User 73	hashedpassword	\N	\N	t	2025-08-22 16:55:46.008579+07	2025-08-22 16:55:46.008579+07	8952cedc-f7e3-4974-bde0-1edf866b06c4	\N	["guest"]	pending	\N	\N
user-75-f1c5f557@example.com	User 75	hashedpassword	\N	\N	t	2025-08-22 16:55:46.009364+07	2025-08-22 16:55:46.009364+07	f1c5f557-4e50-4920-89d9-d0d1b9840644	\N	["guest"]	pending	\N	\N
user-76-355d9f95@example.com	User 76	hashedpassword	\N	\N	t	2025-08-22 16:55:46.00985+07	2025-08-22 16:55:46.00985+07	355d9f95-9c37-4da4-b161-0a9128dfcbe6	\N	["guest"]	pending	\N	\N
user-81-b9592b0c@example.com	User 81	hashedpassword	\N	\N	t	2025-08-22 16:55:46.012208+07	2025-08-22 16:55:46.012208+07	b9592b0c-be2f-44c1-9121-f0e628f89cd0	\N	["guest"]	pending	\N	\N
user-86-d2eeaaad@example.com	User 86	hashedpassword	\N	\N	t	2025-08-22 16:55:46.017165+07	2025-08-22 16:55:46.017165+07	d2eeaaad-171e-406f-81fc-533b4bb6076d	\N	["guest"]	pending	\N	\N
user-96-581fba6c@example.com	User 96	hashedpassword	\N	\N	t	2025-08-22 16:55:46.023562+07	2025-08-22 16:55:46.023562+07	581fba6c-0580-40ed-9588-9826331b98ef	\N	["guest"]	pending	\N	\N
concurrent-user-1-62dae8c0@example.com	Concurrent User 1	password	\N	\N	t	2025-08-22 16:55:46.283219+07	2025-08-22 16:55:46.28322+07	62dae8c0-00f8-43c3-86e1-ea874a92259e	\N	["guest"]	pending	\N	\N
perf-test-0-ef4c156e@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:46.447184+07	2025-08-22 16:55:46.447184+07	ef4c156e-e6cc-44cb-a93d-f1c7a239927d	\N	["guest"]	pending	\N	\N
perf-test-1-dcd6f486@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:46.489302+07	2025-08-22 16:55:46.489302+07	dcd6f486-d168-4b0f-b9bd-cc2b48c7c6df	\N	["guest"]	pending	\N	\N
perf-test-2-9bc1c79c@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:46.491322+07	2025-08-22 16:55:46.491323+07	9bc1c79c-1d05-436f-9055-b9c8a5825697	\N	["guest"]	pending	\N	\N
perf-test-3-bfc076a1@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:46.492092+07	2025-08-22 16:55:46.492093+07	bfc076a1-4de2-472b-b94e-9c9fc72d269f	\N	["guest"]	pending	\N	\N
perf-test-4-c71ff531@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:46.492751+07	2025-08-22 16:55:46.492751+07	c71ff531-b948-4013-bb4a-f7d14689a242	\N	["guest"]	pending	\N	\N
perf-test-5-4bd04135@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:46.493385+07	2025-08-22 16:55:46.493385+07	4bd04135-a7de-4821-88bf-caea307a70cd	\N	["guest"]	pending	\N	\N
perf-test-6-288960a1@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:46.493947+07	2025-08-22 16:55:46.493947+07	288960a1-24c1-4f0b-9857-304445398d6e	\N	["guest"]	pending	\N	\N
perf-test-7-53f6eb00@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:46.4944+07	2025-08-22 16:55:46.4944+07	53f6eb00-4608-4232-a3f8-c66bb71c0bed	\N	["guest"]	pending	\N	\N
perf-test-8-5f6651d8@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:46.495+07	2025-08-22 16:55:46.495+07	5f6651d8-31c6-44be-a51d-92ad5d3569d4	\N	["guest"]	pending	\N	\N
perf-test-9-16fb0295@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:46.495776+07	2025-08-22 16:55:46.495776+07	16fb0295-d909-4edb-b770-69904d410671	\N	["guest"]	pending	\N	\N
perf-test-10-650f2e1c@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:46.49658+07	2025-08-22 16:55:46.49658+07	650f2e1c-c0a2-4323-bdc7-1e9b4b1800af	\N	["guest"]	pending	\N	\N
perf-test-11-390d6aec@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:46.497569+07	2025-08-22 16:55:46.497569+07	390d6aec-be99-466f-ad8b-58bdf94d7f67	\N	["guest"]	pending	\N	\N
perf-test-12-3151180b@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:46.49839+07	2025-08-22 16:55:46.49839+07	3151180b-0b83-4b69-ae68-f50ec6fcfd00	\N	["guest"]	pending	\N	\N
perf-test-13-af2d1a8f@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:46.49922+07	2025-08-22 16:55:46.49922+07	af2d1a8f-9d5d-46ad-a11e-e4ed489995cc	\N	["guest"]	pending	\N	\N
perf-test-14-27836c68@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:46.499864+07	2025-08-22 16:55:46.499864+07	27836c68-0ad1-4579-a4ac-1de48ad82ebf	\N	["guest"]	pending	\N	\N
perf-test-15-077818ad@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:46.500585+07	2025-08-22 16:55:46.500585+07	077818ad-be63-440f-937c-897cea8e1c73	\N	["guest"]	pending	\N	\N
perf-test-16-648187bb@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:46.501378+07	2025-08-22 16:55:46.501378+07	648187bb-1215-457a-9552-5c0aa420c638	\N	["guest"]	pending	\N	\N
perf-test-17-114e56c0@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:46.501965+07	2025-08-22 16:55:46.501965+07	114e56c0-56f8-49e1-98e0-53cea82b83c3	\N	["guest"]	pending	\N	\N
perf-test-18-7f372364@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:46.502475+07	2025-08-22 16:55:46.502475+07	7f372364-488a-4d31-a928-d1dea35124a4	\N	["guest"]	pending	\N	\N
perf-test-19-f2cddfe3@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:46.503118+07	2025-08-22 16:55:46.503118+07	f2cddfe3-2829-4702-84d3-23edae22ee1d	\N	["guest"]	pending	\N	\N
perf-test-20-a0ac0893@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:46.503623+07	2025-08-22 16:55:46.503623+07	a0ac0893-311a-4f93-9667-c6069da3a7cf	\N	["guest"]	pending	\N	\N
perf-test-21-67f33538@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:46.504106+07	2025-08-22 16:55:46.504106+07	67f33538-03a5-484d-84ad-b197b598bf4d	\N	["guest"]	pending	\N	\N
perf-test-22-51470731@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:46.504564+07	2025-08-22 16:55:46.504564+07	51470731-f232-4e29-967d-63bd210d2927	\N	["guest"]	pending	\N	\N
perf-test-23-0e1724aa@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:46.505013+07	2025-08-22 16:55:46.505013+07	0e1724aa-9a3d-417d-ac6d-eb2c811ea74e	\N	["guest"]	pending	\N	\N
perf-test-24-4123ae8f@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:46.505434+07	2025-08-22 16:55:46.505434+07	4123ae8f-bef8-4146-a4a3-5d6394173218	\N	["guest"]	pending	\N	\N
perf-test-25-0e2eb16c@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:46.505804+07	2025-08-22 16:55:46.505804+07	0e2eb16c-b736-4044-be18-18f6d35e8fd6	\N	["guest"]	pending	\N	\N
perf-test-26-40ea9118@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:46.506232+07	2025-08-22 16:55:46.506232+07	40ea9118-1fd2-4e8f-8ad7-671b8cdc85d0	\N	["guest"]	pending	\N	\N
perf-test-27-cf28b554@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:46.506621+07	2025-08-22 16:55:46.506621+07	cf28b554-36a3-4939-859f-61b743e290dc	\N	["guest"]	pending	\N	\N
perf-test-28-db2dba44@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:46.506988+07	2025-08-22 16:55:46.506988+07	db2dba44-b7d6-42e4-8483-ffc3a78cd263	\N	["guest"]	pending	\N	\N
perf-test-29-64bd911d@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:46.507355+07	2025-08-22 16:55:46.507355+07	64bd911d-606d-46b0-ad54-5291db13ebef	\N	["guest"]	pending	\N	\N
perf-test-30-a69cd16d@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:46.507719+07	2025-08-22 16:55:46.507719+07	a69cd16d-bf8e-4816-935c-85c81386fe20	\N	["guest"]	pending	\N	\N
perf-test-31-7bd08720@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:46.508103+07	2025-08-22 16:55:46.508103+07	7bd08720-bdff-4d84-b3bd-fa9b2146a857	\N	["guest"]	pending	\N	\N
perf-test-32-f65751f5@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:46.508457+07	2025-08-22 16:55:46.508457+07	f65751f5-a1aa-45b5-877b-100fe16d85df	\N	["guest"]	pending	\N	\N
perf-test-33-6d642928@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:46.50882+07	2025-08-22 16:55:46.50882+07	6d642928-46d6-4981-bed2-ed44f02bae5b	\N	["guest"]	pending	\N	\N
perf-test-34-81f5c734@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:46.509151+07	2025-08-22 16:55:46.509151+07	81f5c734-7f69-4e0a-b461-8e8eb19b3ce3	\N	["guest"]	pending	\N	\N
perf-test-35-f48440c8@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:46.509532+07	2025-08-22 16:55:46.509533+07	f48440c8-cb3e-4f06-a8b8-ff2e1cc340ba	\N	["guest"]	pending	\N	\N
perf-test-36-af786235@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:46.50988+07	2025-08-22 16:55:46.50988+07	af786235-ddc7-4fab-99b7-0f59b563fed1	\N	["guest"]	pending	\N	\N
perf-test-37-d25b9999@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:46.51024+07	2025-08-22 16:55:46.51024+07	d25b9999-cd12-4f72-aa88-6e352a270fd3	\N	["guest"]	pending	\N	\N
perf-test-38-104300f4@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:46.510719+07	2025-08-22 16:55:46.510719+07	104300f4-580d-487c-b3e1-20cee4f5332d	\N	["guest"]	pending	\N	\N
perf-test-39-e341b73f@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:46.511084+07	2025-08-22 16:55:46.511084+07	e341b73f-de39-4706-9a0f-7454a94c3684	\N	["guest"]	pending	\N	\N
perf-test-40-038712c0@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:46.511515+07	2025-08-22 16:55:46.511515+07	038712c0-274e-473d-9e1a-c2ed6c18738d	\N	["guest"]	pending	\N	\N
perf-test-41-89a87012@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:46.511895+07	2025-08-22 16:55:46.511895+07	89a87012-5201-41ed-bbcb-fa148bc80e9f	\N	["guest"]	pending	\N	\N
perf-test-42-155d44ae@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:46.512252+07	2025-08-22 16:55:46.512252+07	155d44ae-5822-4e4b-a55c-1671c4143fb6	\N	["guest"]	pending	\N	\N
perf-test-43-20837cea@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:46.512646+07	2025-08-22 16:55:46.512646+07	20837cea-1ec6-4b8a-ae7a-2bebdc1af901	\N	["guest"]	pending	\N	\N
perf-test-44-5b553b2e@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:46.513058+07	2025-08-22 16:55:46.513059+07	5b553b2e-1373-4fd5-9e4f-ad3832738432	\N	["guest"]	pending	\N	\N
perf-test-45-2545fd2e@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:46.513531+07	2025-08-22 16:55:46.513531+07	2545fd2e-0e56-4eb2-afd2-c9a05c359404	\N	["guest"]	pending	\N	\N
perf-test-46-252a3253@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:46.514122+07	2025-08-22 16:55:46.514122+07	252a3253-208a-41f4-b59f-d9a7a005ee15	\N	["guest"]	pending	\N	\N
perf-test-47-d2ca0350@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:46.514621+07	2025-08-22 16:55:46.514621+07	d2ca0350-06de-4257-b954-1713b3aebc5d	\N	["guest"]	pending	\N	\N
perf-test-48-494d48d6@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:46.515234+07	2025-08-22 16:55:46.515234+07	494d48d6-a8be-424d-a3e0-5c44bcb9059f	\N	["guest"]	pending	\N	\N
perf-test-49-d07fd9f8@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:46.515828+07	2025-08-22 16:55:46.515828+07	d07fd9f8-8139-437e-8fab-95b4bc7bd645	\N	["guest"]	pending	\N	\N
user-4-f2cbeedf@example.com	User 4	hashedpassword	\N	\N	t	2025-08-22 16:56:17.279198+07	2025-08-22 16:56:17.279198+07	f2cbeedf-386e-4ed0-a5de-0ab646811f4e	\N	["guest"]	pending	\N	\N
user-7-04853402@example.com	User 7	hashedpassword	\N	\N	t	2025-08-22 16:56:17.283009+07	2025-08-22 16:56:17.283009+07	04853402-275e-4861-b863-f19153b198c1	\N	["guest"]	pending	\N	\N
user-10-3d2d628e@example.com	User 10	hashedpassword	\N	\N	t	2025-08-22 16:56:17.286634+07	2025-08-22 16:56:17.286634+07	3d2d628e-ec90-4bac-8c61-09b0bc2d9b6a	\N	["guest"]	pending	\N	\N
user-12-b00632c1@example.com	User 12	hashedpassword	\N	\N	t	2025-08-22 16:56:17.288946+07	2025-08-22 16:56:17.288946+07	b00632c1-535c-4c0d-be11-b5349b4f64dc	\N	["guest"]	pending	\N	\N
user-20-49e3a744@example.com	User 20	hashedpassword	\N	\N	t	2025-08-22 16:56:17.296428+07	2025-08-22 16:56:17.296428+07	49e3a744-067c-4d3e-bb15-34afa58a66db	\N	["guest"]	pending	\N	\N
user-27-8ed579aa@example.com	User 27	hashedpassword	\N	\N	t	2025-08-22 16:56:17.300322+07	2025-08-22 16:56:17.300323+07	8ed579aa-a275-423a-9849-343e5abf808e	\N	["guest"]	pending	\N	\N
user-31-885147be@example.com	User 31	hashedpassword	\N	\N	t	2025-08-22 16:56:17.302282+07	2025-08-22 16:56:17.302282+07	885147be-b17f-4117-aea9-8ff87d743b1d	\N	["guest"]	pending	\N	\N
user-37-78e72152@example.com	User 37	hashedpassword	\N	\N	t	2025-08-22 16:56:17.309728+07	2025-08-22 16:56:17.309728+07	78e72152-7b63-499e-83f6-ba71abd3c298	\N	["guest"]	pending	\N	\N
user-40-177b4bf7@example.com	User 40	hashedpassword	\N	\N	t	2025-08-22 16:56:17.311829+07	2025-08-22 16:56:17.311829+07	177b4bf7-7d41-4ed5-9b7a-e36d942e77f6	\N	["guest"]	pending	\N	\N
user-41-147d2c16@example.com	User 41	hashedpassword	\N	\N	t	2025-08-22 16:56:17.312546+07	2025-08-22 16:56:17.312547+07	147d2c16-2656-4491-a896-de4d4d70691e	\N	["guest"]	pending	\N	\N
user-46-247f30a7@example.com	User 46	hashedpassword	\N	\N	t	2025-08-22 16:56:17.315893+07	2025-08-22 16:56:17.315894+07	247f30a7-e798-4863-a3db-cb84ff59d440	\N	["guest"]	pending	\N	\N
user-51-e3407d1e@example.com	User 51	hashedpassword	\N	\N	t	2025-08-22 16:56:17.318316+07	2025-08-22 16:56:17.318316+07	e3407d1e-d813-4bb4-9fe2-61ed8ac0086e	\N	["guest"]	pending	\N	\N
user-53-0ec1e6a7@example.com	User 53	hashedpassword	\N	\N	t	2025-08-22 16:56:17.319184+07	2025-08-22 16:56:17.319185+07	0ec1e6a7-dc54-495e-a078-5f96e5823094	\N	["guest"]	pending	\N	\N
user-56-f7145288@example.com	User 56	hashedpassword	\N	\N	t	2025-08-22 16:56:17.320866+07	2025-08-22 16:56:17.320866+07	f7145288-e157-4ea6-991e-72b2df1925a6	\N	["guest"]	pending	\N	\N
user-71-4c5c8d9e@example.com	User 71	hashedpassword	\N	\N	t	2025-08-22 16:56:17.330806+07	2025-08-22 16:56:17.330806+07	4c5c8d9e-e907-470f-90b8-088b1fefbfce	\N	["guest"]	pending	\N	\N
user-73-f1462616@example.com	User 73	hashedpassword	\N	\N	t	2025-08-22 16:56:17.331576+07	2025-08-22 16:56:17.331576+07	f1462616-5501-4901-8400-3729255a9435	\N	["guest"]	pending	\N	\N
user-77-49fb0f88@example.com	User 77	hashedpassword	\N	\N	t	2025-08-22 16:56:17.333086+07	2025-08-22 16:56:17.333086+07	49fb0f88-46cb-439f-be4b-0efee459f887	\N	["guest"]	pending	\N	\N
user-80-44c079e3@example.com	User 80	hashedpassword	\N	\N	t	2025-08-22 16:56:17.334186+07	2025-08-22 16:56:17.334186+07	44c079e3-21ac-4679-8844-0d470bb36ed5	\N	["guest"]	pending	\N	\N
user-82-7a18c847@example.com	User 82	hashedpassword	\N	\N	t	2025-08-22 16:56:17.334974+07	2025-08-22 16:56:17.334974+07	7a18c847-894d-4a39-9e70-9919828c016e	\N	["guest"]	pending	\N	\N
user-83-ae698b98@example.com	User 83	hashedpassword	\N	\N	t	2025-08-22 16:56:17.335506+07	2025-08-22 16:56:17.335507+07	ae698b98-219b-44f9-8902-23bdfc55dd5b	\N	["guest"]	pending	\N	\N
user-85-9d3e2e34@example.com	User 85	hashedpassword	\N	\N	t	2025-08-22 16:56:17.336939+07	2025-08-22 16:56:17.336939+07	9d3e2e34-edac-4e2a-b967-f0d50ac104f5	\N	["guest"]	pending	\N	\N
user-86-2fa0ff7e@example.com	User 86	hashedpassword	\N	\N	t	2025-08-22 16:56:17.339165+07	2025-08-22 16:56:17.339165+07	2fa0ff7e-927f-4e39-9bf6-7783e38ce445	\N	["guest"]	pending	\N	\N
user-87-8a221aaf@example.com	User 87	hashedpassword	\N	\N	t	2025-08-22 16:56:17.340613+07	2025-08-22 16:56:17.340614+07	8a221aaf-e5af-4323-a3d1-0c1bb11b477e	\N	["guest"]	pending	\N	\N
user-88-1070f6f9@example.com	User 88	hashedpassword	\N	\N	t	2025-08-22 16:56:17.341803+07	2025-08-22 16:56:17.341803+07	1070f6f9-f0d4-4788-bb28-6085b1f652e0	\N	["guest"]	pending	\N	\N
user-91-48199967@example.com	User 91	hashedpassword	\N	\N	t	2025-08-22 16:56:17.343898+07	2025-08-22 16:56:17.343898+07	48199967-cc33-424c-b341-a43cc59dd564	\N	["guest"]	pending	\N	\N
concurrent-user-1-ef7424fd@example.com	Concurrent User 1	password	\N	\N	t	2025-08-22 16:56:17.628779+07	2025-08-22 16:56:17.628779+07	ef7424fd-3c86-4646-a3d7-3771972c5f2e	\N	["guest"]	pending	\N	\N
perf-test-0-54608905@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:56:17.820539+07	2025-08-22 16:56:17.820539+07	54608905-a08b-41b2-9065-2fdc6b855420	\N	["guest"]	pending	\N	\N
perf-test-1-f8572b37@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:56:17.822288+07	2025-08-22 16:56:17.822288+07	f8572b37-89eb-48fd-81ad-81f4773e23e1	\N	["guest"]	pending	\N	\N
perf-test-2-20aa987c@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:56:17.823932+07	2025-08-22 16:56:17.823932+07	20aa987c-5a43-4153-a06e-6c492c9df815	\N	["guest"]	pending	\N	\N
perf-test-3-9ae6f2bf@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:56:17.825087+07	2025-08-22 16:56:17.825087+07	9ae6f2bf-bf38-480f-b0bf-e725f7c69ff4	\N	["guest"]	pending	\N	\N
perf-test-4-d6ba89fe@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:56:17.825951+07	2025-08-22 16:56:17.825951+07	d6ba89fe-1063-4ea1-86e3-9cecfe6c1294	\N	["guest"]	pending	\N	\N
perf-test-5-fd1c70a5@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:56:17.826806+07	2025-08-22 16:56:17.826806+07	fd1c70a5-f98b-4782-b95c-b8eb177cbc2e	\N	["guest"]	pending	\N	\N
perf-test-6-fce0499f@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:56:17.827649+07	2025-08-22 16:56:17.827649+07	fce0499f-2622-4deb-a8b6-5248c4c964bb	\N	["guest"]	pending	\N	\N
perf-test-7-55991936@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:56:17.82846+07	2025-08-22 16:56:17.82846+07	55991936-6140-4b25-a6cc-50c356daa4ef	\N	["guest"]	pending	\N	\N
perf-test-8-aa898704@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:56:17.829415+07	2025-08-22 16:56:17.829415+07	aa898704-46eb-4091-a785-e6b3fd1229ef	\N	["guest"]	pending	\N	\N
perf-test-9-2c82c36b@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:56:17.830105+07	2025-08-22 16:56:17.830105+07	2c82c36b-6a82-4fd8-b26d-1cd7d1d42745	\N	["guest"]	pending	\N	\N
perf-test-10-b316e953@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:56:17.830604+07	2025-08-22 16:56:17.830604+07	b316e953-ebbc-40a7-9ec9-1d247d951c67	\N	["guest"]	pending	\N	\N
perf-test-11-f9867411@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:56:17.831031+07	2025-08-22 16:56:17.831031+07	f9867411-681a-4ba3-bc3c-866b5f1b1503	\N	["guest"]	pending	\N	\N
perf-test-12-7c725797@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:56:17.831458+07	2025-08-22 16:56:17.831458+07	7c725797-4ca5-41c5-b8c1-01f0c3a284aa	\N	["guest"]	pending	\N	\N
perf-test-13-e9e466f1@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:56:17.831842+07	2025-08-22 16:56:17.831843+07	e9e466f1-f0c8-4b57-957d-ee62d3693b7b	\N	["guest"]	pending	\N	\N
perf-test-14-a76e5c1b@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:56:17.832227+07	2025-08-22 16:56:17.832227+07	a76e5c1b-9245-4f5c-9a8e-0f2d6b0ab683	\N	["guest"]	pending	\N	\N
perf-test-15-6b549d06@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:56:17.832796+07	2025-08-22 16:56:17.832796+07	6b549d06-dfa5-4ef4-b320-a23d881df315	\N	["guest"]	pending	\N	\N
perf-test-16-8b056ca7@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:56:17.833176+07	2025-08-22 16:56:17.833176+07	8b056ca7-f9a0-43d8-a637-b44e748ec82c	\N	["guest"]	pending	\N	\N
perf-test-17-0caecce3@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:56:17.833519+07	2025-08-22 16:56:17.833519+07	0caecce3-093a-4811-aba2-8b18a21383f3	\N	["guest"]	pending	\N	\N
perf-test-18-bb0160a0@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:56:17.833864+07	2025-08-22 16:56:17.833864+07	bb0160a0-30d6-42dd-8434-0d9aeff1feaa	\N	["guest"]	pending	\N	\N
perf-test-19-a5daa84a@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:56:17.834203+07	2025-08-22 16:56:17.834203+07	a5daa84a-c60c-499f-8844-b423fd956dea	\N	["guest"]	pending	\N	\N
perf-test-20-f8041ea1@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:56:17.834527+07	2025-08-22 16:56:17.834528+07	f8041ea1-70f1-4a5c-b27f-4bf60092376c	\N	["guest"]	pending	\N	\N
perf-test-21-3b824239@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:56:17.83492+07	2025-08-22 16:56:17.83492+07	3b824239-b23a-4ab3-9e8d-9e70bcd2eee9	\N	["guest"]	pending	\N	\N
perf-test-22-6937c3f0@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:56:17.83534+07	2025-08-22 16:56:17.83534+07	6937c3f0-a1d1-4a94-ac85-c8bd1df6c4b7	\N	["guest"]	pending	\N	\N
perf-test-23-c9eee688@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:56:17.835938+07	2025-08-22 16:56:17.835938+07	c9eee688-c212-46ef-85ff-f5b42edba29a	\N	["guest"]	pending	\N	\N
perf-test-24-ab8fdd37@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:56:17.836446+07	2025-08-22 16:56:17.836446+07	ab8fdd37-fac7-4bdf-9864-16e83a792ab9	\N	["guest"]	pending	\N	\N
perf-test-25-15e6d1b6@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:56:17.836974+07	2025-08-22 16:56:17.836974+07	15e6d1b6-62f7-4d70-ac42-8956923130cb	\N	["guest"]	pending	\N	\N
perf-test-26-1a1483f1@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:56:17.837807+07	2025-08-22 16:56:17.837807+07	1a1483f1-0314-4489-84e9-f125068bf6b2	\N	["guest"]	pending	\N	\N
perf-test-27-5daf9142@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:56:17.839357+07	2025-08-22 16:56:17.839358+07	5daf9142-eb6a-40e0-a578-5aded473a197	\N	["guest"]	pending	\N	\N
perf-test-28-d83f2b2c@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:56:17.840603+07	2025-08-22 16:56:17.840604+07	d83f2b2c-a2ce-438b-8ccb-f399a256861c	\N	["guest"]	pending	\N	\N
perf-test-29-6a5ddad1@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:56:17.842073+07	2025-08-22 16:56:17.842073+07	6a5ddad1-431e-4cb0-9ff8-b5e8fe2ee7d0	\N	["guest"]	pending	\N	\N
perf-test-30-e33fd0b4@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:56:17.84283+07	2025-08-22 16:56:17.84283+07	e33fd0b4-a4bd-4f52-b5c2-d6777db72cf7	\N	["guest"]	pending	\N	\N
perf-test-31-dbc56cd2@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:56:17.843582+07	2025-08-22 16:56:17.843582+07	dbc56cd2-0de5-47e6-956d-fc7cf594b061	\N	["guest"]	pending	\N	\N
perf-test-32-0b2bcb76@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:56:17.844245+07	2025-08-22 16:56:17.844245+07	0b2bcb76-c8ea-4085-a75d-e832c88a4419	\N	["guest"]	pending	\N	\N
perf-test-33-97dadecd@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:56:17.844917+07	2025-08-22 16:56:17.844917+07	97dadecd-1c39-4a84-bcf7-61ce63c4e55a	\N	["guest"]	pending	\N	\N
perf-test-34-f60244dc@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:56:17.845514+07	2025-08-22 16:56:17.845514+07	f60244dc-a8ce-4986-95f9-03c2cc469385	\N	["guest"]	pending	\N	\N
perf-test-35-026515aa@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:56:17.846052+07	2025-08-22 16:56:17.846052+07	026515aa-a205-4a89-8a03-cb87882ed8b6	\N	["guest"]	pending	\N	\N
perf-test-36-efc4c95d@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:56:17.8466+07	2025-08-22 16:56:17.846601+07	efc4c95d-0e3f-42a3-ae59-4af2fbbbf4ca	\N	["guest"]	pending	\N	\N
perf-test-37-c58001c4@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:56:17.847145+07	2025-08-22 16:56:17.847145+07	c58001c4-a420-469e-aa45-b2eb3e28c388	\N	["guest"]	pending	\N	\N
perf-test-38-fb775bf0@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:56:17.847648+07	2025-08-22 16:56:17.847648+07	fb775bf0-f1da-418a-8d9e-d5c539c511d5	\N	["guest"]	pending	\N	\N
perf-test-39-bbe9eeb2@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:56:17.848171+07	2025-08-22 16:56:17.848171+07	bbe9eeb2-1720-4a7e-813a-9b5844dad7ed	\N	["guest"]	pending	\N	\N
perf-test-40-40535626@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:56:17.84875+07	2025-08-22 16:56:17.84875+07	40535626-95a0-457b-8e79-bdaf5e99b16a	\N	["guest"]	pending	\N	\N
perf-test-41-a88578a3@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:56:17.849315+07	2025-08-22 16:56:17.849315+07	a88578a3-ef55-469f-ad14-a7d6b3c3ba94	\N	["guest"]	pending	\N	\N
perf-test-42-366465e9@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:56:17.84981+07	2025-08-22 16:56:17.84981+07	366465e9-29fd-4f81-8f41-d134e6327e29	\N	["guest"]	pending	\N	\N
perf-test-43-4dfc959a@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:56:17.850281+07	2025-08-22 16:56:17.850281+07	4dfc959a-44ce-4b8c-a5ae-205750845bf0	\N	["guest"]	pending	\N	\N
perf-test-44-b5b56960@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:56:17.850749+07	2025-08-22 16:56:17.850749+07	b5b56960-8779-4b01-bfd5-c1266e457326	\N	["guest"]	pending	\N	\N
perf-test-45-35fdaa17@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:56:17.85166+07	2025-08-22 16:56:17.851688+07	35fdaa17-1fae-4f6a-9082-1d4315a07cdc	\N	["guest"]	pending	\N	\N
perf-test-46-bda11642@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:56:17.852504+07	2025-08-22 16:56:17.852504+07	bda11642-b4d6-48dd-9cbd-988bfff44a52	\N	["guest"]	pending	\N	\N
perf-test-47-9e2171b9@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:56:17.852977+07	2025-08-22 16:56:17.852977+07	9e2171b9-7d38-4004-9ac7-7ae8dfca985e	\N	["guest"]	pending	\N	\N
perf-test-48-047284cf@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:56:17.853562+07	2025-08-22 16:56:17.853562+07	047284cf-77df-4f80-969f-04cd19c0263a	\N	["guest"]	pending	\N	\N
perf-test-49-524568d2@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:56:17.85459+07	2025-08-22 16:56:17.85459+07	524568d2-2ebc-4ab3-9a0d-ac50be7c046b	\N	["guest"]	pending	\N	\N
user-2-27c9c4c1@example.com	User 2	hashedpassword	\N	\N	t	2025-08-22 17:35:45.194616+07	2025-08-22 17:35:45.194616+07	27c9c4c1-cae9-46e5-8405-373c62c48fc7	\N	["guest"]	pending	\N	\N
user-13-5c441d48@example.com	User 13	hashedpassword	\N	\N	t	2025-08-22 17:35:45.208069+07	2025-08-22 17:35:45.208069+07	5c441d48-8f54-40ad-83a0-a661424b1786	\N	["guest"]	pending	\N	\N
user-17-8170c9be@example.com	User 17	hashedpassword	\N	\N	t	2025-08-22 17:35:45.209631+07	2025-08-22 17:35:45.209631+07	8170c9be-7d67-426b-ba05-2a1e024ce328	\N	["guest"]	pending	\N	\N
user-18-ffb0b454@example.com	User 18	hashedpassword	\N	\N	t	2025-08-22 17:35:45.209995+07	2025-08-22 17:35:45.209995+07	ffb0b454-8c1e-4a16-8595-38f72145c34a	\N	["guest"]	pending	\N	\N
user-20-190db38d@example.com	User 20	hashedpassword	\N	\N	t	2025-08-22 17:35:45.210729+07	2025-08-22 17:35:45.210729+07	190db38d-d645-4887-94cb-66ec3393c4e0	\N	["guest"]	pending	\N	\N
user-23-35f11ac3@example.com	User 23	hashedpassword	\N	\N	t	2025-08-22 17:35:45.211779+07	2025-08-22 17:35:45.211779+07	35f11ac3-5f0e-47bc-be3e-3ecf9c83625e	\N	["guest"]	pending	\N	\N
user-25-0bb41ecd@example.com	User 25	hashedpassword	\N	\N	t	2025-08-22 17:35:45.212432+07	2025-08-22 17:35:45.212432+07	0bb41ecd-9afd-49d5-8f3d-1a3d1ac78d8d	\N	["guest"]	pending	\N	\N
user-35-44c85d9e@example.com	User 35	hashedpassword	\N	\N	t	2025-08-22 17:35:45.217132+07	2025-08-22 17:35:45.217132+07	44c85d9e-bf44-416b-a240-6d62300a560e	\N	["guest"]	pending	\N	\N
user-36-d8f15060@example.com	User 36	hashedpassword	\N	\N	t	2025-08-22 17:35:45.217568+07	2025-08-22 17:35:45.217569+07	d8f15060-d792-4acf-b94c-534cb57361b7	\N	["guest"]	pending	\N	\N
user-38-d2b32a5b@example.com	User 38	hashedpassword	\N	\N	t	2025-08-22 17:35:45.218414+07	2025-08-22 17:35:45.218414+07	d2b32a5b-0456-4a25-991a-d158aac3c906	\N	["guest"]	pending	\N	\N
user-45-97d30ca4@example.com	User 45	hashedpassword	\N	\N	t	2025-08-22 17:35:45.221036+07	2025-08-22 17:35:45.221036+07	97d30ca4-287a-4640-ad44-17891c553928	\N	["guest"]	pending	\N	\N
user-47-9e80d36e@example.com	User 47	hashedpassword	\N	\N	t	2025-08-22 17:35:45.222118+07	2025-08-22 17:35:45.222118+07	9e80d36e-2aae-484a-8d23-74d90848820d	\N	["guest"]	pending	\N	\N
user-48-1a03c68f@example.com	User 48	hashedpassword	\N	\N	t	2025-08-22 17:35:45.222604+07	2025-08-22 17:35:45.222605+07	1a03c68f-19cf-4f95-97f4-0aa0675ef90e	\N	["guest"]	pending	\N	\N
user-50-901347c9@example.com	User 50	hashedpassword	\N	\N	t	2025-08-22 17:35:45.223506+07	2025-08-22 17:35:45.223506+07	901347c9-5d8a-4884-a463-208ca02c7aa2	\N	["guest"]	pending	\N	\N
user-56-da4d5af7@example.com	User 56	hashedpassword	\N	\N	t	2025-08-22 17:35:45.225832+07	2025-08-22 17:35:45.225832+07	da4d5af7-1ee6-478a-9134-a819c125d0c6	\N	["guest"]	pending	\N	\N
user-60-aa9faa8e@example.com	User 60	hashedpassword	\N	\N	t	2025-08-22 17:35:45.227392+07	2025-08-22 17:35:45.227392+07	aa9faa8e-2499-47fa-ad1b-c7f0803bdb29	\N	["guest"]	pending	\N	\N
user-64-f0e77c42@example.com	User 64	hashedpassword	\N	\N	t	2025-08-22 17:35:45.228863+07	2025-08-22 17:35:45.228863+07	f0e77c42-9af5-4378-948d-51c31823fb89	\N	["guest"]	pending	\N	\N
user-65-878eb3d0@example.com	User 65	hashedpassword	\N	\N	t	2025-08-22 17:35:45.229392+07	2025-08-22 17:35:45.229392+07	878eb3d0-e33b-4b17-95b7-6d2286e10fc2	\N	["guest"]	pending	\N	\N
user-71-6eaa0dba@example.com	User 71	hashedpassword	\N	\N	t	2025-08-22 17:35:45.23218+07	2025-08-22 17:35:45.23218+07	6eaa0dba-8c48-40c5-bff5-ffae7c9f70c7	\N	["guest"]	pending	\N	\N
user-77-bdda8a60@example.com	User 77	hashedpassword	\N	\N	t	2025-08-22 17:35:45.234353+07	2025-08-22 17:35:45.234353+07	bdda8a60-d4be-4aa4-b51f-a0ed49b1829d	\N	["guest"]	pending	\N	\N
user-79-9bfb6156@example.com	User 79	hashedpassword	\N	\N	t	2025-08-22 17:35:45.235126+07	2025-08-22 17:35:45.235126+07	9bfb6156-db36-49c5-b191-d6ce33427183	\N	["guest"]	pending	\N	\N
user-86-87f68d91@example.com	User 86	hashedpassword	\N	\N	t	2025-08-22 17:35:45.238382+07	2025-08-22 17:35:45.238383+07	87f68d91-24ea-4c85-8b06-0d9726d8db77	\N	["guest"]	pending	\N	\N
user-89-2bd161d5@example.com	User 89	hashedpassword	\N	\N	t	2025-08-22 17:35:45.23976+07	2025-08-22 17:35:45.23976+07	2bd161d5-8cdf-417b-88ff-ead4ed0c564c	\N	["guest"]	pending	\N	\N
user-90-a8fb344f@example.com	User 90	hashedpassword	\N	\N	t	2025-08-22 17:35:45.240122+07	2025-08-22 17:35:45.240122+07	a8fb344f-83d6-4715-a936-167bfeed7d66	\N	["guest"]	pending	\N	\N
user-93-09e690ec@example.com	User 93	hashedpassword	\N	\N	t	2025-08-22 17:35:45.241212+07	2025-08-22 17:35:45.241212+07	09e690ec-9d7d-43d5-b95a-a9977d104662	\N	["guest"]	pending	\N	\N
user-97-aafbf7b8@example.com	User 97	hashedpassword	\N	\N	t	2025-08-22 17:35:45.242724+07	2025-08-22 17:35:45.242724+07	aafbf7b8-25a5-4336-b9c1-bde991e2fdd0	\N	["guest"]	pending	\N	\N
user-99-b4702d7a@example.com	User 99	hashedpassword	\N	\N	t	2025-08-22 17:35:45.243416+07	2025-08-22 17:35:45.243416+07	b4702d7a-6801-48c8-b5ec-af12bc806869	\N	["guest"]	pending	\N	\N
concurrent-user-1-7f9f381d@example.com	Concurrent User 1	password	\N	\N	t	2025-08-22 17:35:45.432919+07	2025-08-22 17:35:45.43292+07	7f9f381d-24be-4825-a497-e6019deb35dd	\N	["guest"]	pending	\N	\N
perf-test-0-deabc0e4@example.com	Performance User 0	password	\N	\N	t	2025-08-22 17:35:45.575987+07	2025-08-22 17:35:45.575987+07	deabc0e4-7643-44bd-a602-94e58b17f8ea	\N	["guest"]	pending	\N	\N
perf-test-1-ee0e29c7@example.com	Performance User 1	password	\N	\N	t	2025-08-22 17:35:45.57704+07	2025-08-22 17:35:45.57704+07	ee0e29c7-f183-4b77-808f-2b87b61fea1d	\N	["guest"]	pending	\N	\N
perf-test-2-e4565932@example.com	Performance User 2	password	\N	\N	t	2025-08-22 17:35:45.577742+07	2025-08-22 17:35:45.577742+07	e4565932-5384-4016-8335-bdcb9f5eb484	\N	["guest"]	pending	\N	\N
perf-test-3-6bd848d8@example.com	Performance User 3	password	\N	\N	t	2025-08-22 17:35:45.578222+07	2025-08-22 17:35:45.578222+07	6bd848d8-78c8-4d97-bca3-99fe84ed5401	\N	["guest"]	pending	\N	\N
perf-test-4-fffe7401@example.com	Performance User 4	password	\N	\N	t	2025-08-22 17:35:45.57875+07	2025-08-22 17:35:45.57875+07	fffe7401-1f8a-42bc-97c8-c1675ca63a47	\N	["guest"]	pending	\N	\N
perf-test-5-1eaf2178@example.com	Performance User 5	password	\N	\N	t	2025-08-22 17:35:45.579139+07	2025-08-22 17:35:45.579139+07	1eaf2178-4fa4-49ad-a932-1b6526903b92	\N	["guest"]	pending	\N	\N
perf-test-6-7b754d9b@example.com	Performance User 6	password	\N	\N	t	2025-08-22 17:35:45.579492+07	2025-08-22 17:35:45.579492+07	7b754d9b-2585-452a-b02a-99973fa2a7bd	\N	["guest"]	pending	\N	\N
perf-test-7-4bbd3b19@example.com	Performance User 7	password	\N	\N	t	2025-08-22 17:35:45.579908+07	2025-08-22 17:35:45.579908+07	4bbd3b19-ef4a-4f6a-a168-dec90ed870bb	\N	["guest"]	pending	\N	\N
perf-test-8-e6321b99@example.com	Performance User 8	password	\N	\N	t	2025-08-22 17:35:45.580285+07	2025-08-22 17:35:45.580285+07	e6321b99-283f-4611-983b-2898066eae97	\N	["guest"]	pending	\N	\N
perf-test-9-d8d98ec7@example.com	Performance User 9	password	\N	\N	t	2025-08-22 17:35:45.580689+07	2025-08-22 17:35:45.580689+07	d8d98ec7-d7cd-477c-adea-43276d6d11aa	\N	["guest"]	pending	\N	\N
perf-test-10-e860a243@example.com	Performance User 10	password	\N	\N	t	2025-08-22 17:35:45.581069+07	2025-08-22 17:35:45.581069+07	e860a243-0f33-4018-9298-27ee119d1f99	\N	["guest"]	pending	\N	\N
perf-test-11-64d82f1b@example.com	Performance User 11	password	\N	\N	t	2025-08-22 17:35:45.58143+07	2025-08-22 17:35:45.58143+07	64d82f1b-fc3a-4afb-9301-4614c112b81d	\N	["guest"]	pending	\N	\N
perf-test-12-17a1ce13@example.com	Performance User 12	password	\N	\N	t	2025-08-22 17:35:45.581873+07	2025-08-22 17:35:45.581873+07	17a1ce13-cddd-4f49-8f86-8b35564aa623	\N	["guest"]	pending	\N	\N
perf-test-13-79afc9c9@example.com	Performance User 13	password	\N	\N	t	2025-08-22 17:35:45.582242+07	2025-08-22 17:35:45.582242+07	79afc9c9-d21f-4944-9a70-c940e450b9eb	\N	["guest"]	pending	\N	\N
perf-test-14-d912c2a5@example.com	Performance User 14	password	\N	\N	t	2025-08-22 17:35:45.582601+07	2025-08-22 17:35:45.582601+07	d912c2a5-6486-41c7-a33d-dbacbb1f77d5	\N	["guest"]	pending	\N	\N
perf-test-15-9508cd60@example.com	Performance User 15	password	\N	\N	t	2025-08-22 17:35:45.583086+07	2025-08-22 17:35:45.583086+07	9508cd60-093a-470c-86f3-a331abd3feb1	\N	["guest"]	pending	\N	\N
perf-test-16-375f7d8c@example.com	Performance User 16	password	\N	\N	t	2025-08-22 17:35:45.583666+07	2025-08-22 17:35:45.583666+07	375f7d8c-10a2-4dce-aacc-013723b42637	\N	["guest"]	pending	\N	\N
perf-test-17-ed3714dd@example.com	Performance User 17	password	\N	\N	t	2025-08-22 17:35:45.584285+07	2025-08-22 17:35:45.584285+07	ed3714dd-d7df-4e5b-ba99-ec2afab3dbe6	\N	["guest"]	pending	\N	\N
perf-test-18-91582fee@example.com	Performance User 18	password	\N	\N	t	2025-08-22 17:35:45.584712+07	2025-08-22 17:35:45.584712+07	91582fee-2231-494b-bdcd-a149f3a24b24	\N	["guest"]	pending	\N	\N
perf-test-19-3fd943a8@example.com	Performance User 19	password	\N	\N	t	2025-08-22 17:35:45.585115+07	2025-08-22 17:35:45.585115+07	3fd943a8-806b-439b-a394-2c30962cf83d	\N	["guest"]	pending	\N	\N
perf-test-20-a0faaa4f@example.com	Performance User 20	password	\N	\N	t	2025-08-22 17:35:45.585535+07	2025-08-22 17:35:45.585535+07	a0faaa4f-6cb6-4989-a764-3d3b5a166f33	\N	["guest"]	pending	\N	\N
perf-test-21-590268e1@example.com	Performance User 21	password	\N	\N	t	2025-08-22 17:35:45.585973+07	2025-08-22 17:35:45.585973+07	590268e1-3b4b-49a4-8f14-0da785eda767	\N	["guest"]	pending	\N	\N
perf-test-22-019a676e@example.com	Performance User 22	password	\N	\N	t	2025-08-22 17:35:45.58637+07	2025-08-22 17:35:45.58637+07	019a676e-71c0-4b0a-9838-3432bf8afde2	\N	["guest"]	pending	\N	\N
perf-test-23-3b07739d@example.com	Performance User 23	password	\N	\N	t	2025-08-22 17:35:45.586751+07	2025-08-22 17:35:45.586751+07	3b07739d-69c1-4a4e-aa83-4f2188612237	\N	["guest"]	pending	\N	\N
perf-test-24-d744915a@example.com	Performance User 24	password	\N	\N	t	2025-08-22 17:35:45.587127+07	2025-08-22 17:35:45.587127+07	d744915a-d742-4bc4-a657-587909fda733	\N	["guest"]	pending	\N	\N
perf-test-25-610200b9@example.com	Performance User 25	password	\N	\N	t	2025-08-22 17:35:45.587479+07	2025-08-22 17:35:45.587479+07	610200b9-62e8-467d-857e-0bb163329e0b	\N	["guest"]	pending	\N	\N
perf-test-26-0e4aa06c@example.com	Performance User 26	password	\N	\N	t	2025-08-22 17:35:45.587839+07	2025-08-22 17:35:45.587839+07	0e4aa06c-c8bc-4640-870c-c3749ea827f3	\N	["guest"]	pending	\N	\N
perf-test-27-385100ad@example.com	Performance User 27	password	\N	\N	t	2025-08-22 17:35:45.588197+07	2025-08-22 17:35:45.588198+07	385100ad-36fc-4229-a2d0-7d0a824c7626	\N	["guest"]	pending	\N	\N
perf-test-28-43d7c23e@example.com	Performance User 28	password	\N	\N	t	2025-08-22 17:35:45.588548+07	2025-08-22 17:35:45.588548+07	43d7c23e-e774-49e7-bb32-baf27d65131c	\N	["guest"]	pending	\N	\N
perf-test-29-9e1e7b04@example.com	Performance User 29	password	\N	\N	t	2025-08-22 17:35:45.588909+07	2025-08-22 17:35:45.588909+07	9e1e7b04-6586-4cb8-b34b-afd3ecf06c42	\N	["guest"]	pending	\N	\N
perf-test-30-382e5c7a@example.com	Performance User 30	password	\N	\N	t	2025-08-22 17:35:45.589251+07	2025-08-22 17:35:45.589251+07	382e5c7a-a944-4521-bc75-1ad53d4682c1	\N	["guest"]	pending	\N	\N
perf-test-31-7d1b3558@example.com	Performance User 31	password	\N	\N	t	2025-08-22 17:35:45.589593+07	2025-08-22 17:35:45.589593+07	7d1b3558-4c5e-467a-86fd-699979af5c3e	\N	["guest"]	pending	\N	\N
perf-test-32-3553dc88@example.com	Performance User 32	password	\N	\N	t	2025-08-22 17:35:45.589978+07	2025-08-22 17:35:45.589978+07	3553dc88-40a6-477e-b0c1-264454b7b210	\N	["guest"]	pending	\N	\N
perf-test-33-ae1ee2c8@example.com	Performance User 33	password	\N	\N	t	2025-08-22 17:35:45.59033+07	2025-08-22 17:35:45.59033+07	ae1ee2c8-d2d6-4a92-bf49-c04962083371	\N	["guest"]	pending	\N	\N
perf-test-34-e376dd1a@example.com	Performance User 34	password	\N	\N	t	2025-08-22 17:35:45.590685+07	2025-08-22 17:35:45.590685+07	e376dd1a-abce-4597-b353-7006c552eb02	\N	["guest"]	pending	\N	\N
perf-test-35-6a5f939f@example.com	Performance User 35	password	\N	\N	t	2025-08-22 17:35:45.591037+07	2025-08-22 17:35:45.591037+07	6a5f939f-f2cb-453e-9099-467cd621c4a0	\N	["guest"]	pending	\N	\N
perf-test-36-e04d6e48@example.com	Performance User 36	password	\N	\N	t	2025-08-22 17:35:45.591401+07	2025-08-22 17:35:45.591401+07	e04d6e48-e5ea-438a-b99c-7c1496d3ec70	\N	["guest"]	pending	\N	\N
perf-test-37-31d5c096@example.com	Performance User 37	password	\N	\N	t	2025-08-22 17:35:45.591759+07	2025-08-22 17:35:45.591759+07	31d5c096-1689-4af3-97b0-278281b8a3fb	\N	["guest"]	pending	\N	\N
perf-test-38-8c5612fa@example.com	Performance User 38	password	\N	\N	t	2025-08-22 17:35:45.592292+07	2025-08-22 17:35:45.592292+07	8c5612fa-880c-4d6b-bfc0-577851d502c6	\N	["guest"]	pending	\N	\N
perf-test-39-1438d320@example.com	Performance User 39	password	\N	\N	t	2025-08-22 17:35:45.592884+07	2025-08-22 17:35:45.592884+07	1438d320-a5ea-4b93-872b-487ab8835cc5	\N	["guest"]	pending	\N	\N
perf-test-40-a71c556b@example.com	Performance User 40	password	\N	\N	t	2025-08-22 17:35:45.593414+07	2025-08-22 17:35:45.593414+07	a71c556b-c852-47a0-bd8c-5ed1951d5dd2	\N	["guest"]	pending	\N	\N
perf-test-41-04b14371@example.com	Performance User 41	password	\N	\N	t	2025-08-22 17:35:45.593813+07	2025-08-22 17:35:45.593813+07	04b14371-d94b-409f-b7f1-6c514155e54c	\N	["guest"]	pending	\N	\N
perf-test-42-1016b9d1@example.com	Performance User 42	password	\N	\N	t	2025-08-22 17:35:45.5944+07	2025-08-22 17:35:45.5944+07	1016b9d1-2a7c-4ecc-9408-4c27cf9f5378	\N	["guest"]	pending	\N	\N
perf-test-43-1158ad11@example.com	Performance User 43	password	\N	\N	t	2025-08-22 17:35:45.594772+07	2025-08-22 17:35:45.594772+07	1158ad11-866e-44c6-9867-8db748c7e2f0	\N	["guest"]	pending	\N	\N
perf-test-44-6d5a84d3@example.com	Performance User 44	password	\N	\N	t	2025-08-22 17:35:45.595146+07	2025-08-22 17:35:45.595146+07	6d5a84d3-19a7-4aa0-84c4-0ae207c3eaa6	\N	["guest"]	pending	\N	\N
perf-test-45-f0dcc0d0@example.com	Performance User 45	password	\N	\N	t	2025-08-22 17:35:45.595517+07	2025-08-22 17:35:45.595517+07	f0dcc0d0-f2a4-42b0-991b-b65ea4e5da3b	\N	["guest"]	pending	\N	\N
perf-test-46-ad987def@example.com	Performance User 46	password	\N	\N	t	2025-08-22 17:35:45.595881+07	2025-08-22 17:35:45.595881+07	ad987def-ce64-450f-b0d6-5ac2e0bc9faf	\N	["guest"]	pending	\N	\N
perf-test-47-914b6ac0@example.com	Performance User 47	password	\N	\N	t	2025-08-22 17:35:45.596386+07	2025-08-22 17:35:45.596386+07	914b6ac0-88f7-4f9e-a6fa-8addd34eaf7d	\N	["guest"]	pending	\N	\N
perf-test-48-19be8a9c@example.com	Performance User 48	password	\N	\N	t	2025-08-22 17:35:45.596759+07	2025-08-22 17:35:45.59676+07	19be8a9c-9f84-4952-8810-aa05ef1b1213	\N	["guest"]	pending	\N	\N
perf-test-49-adce9f33@example.com	Performance User 49	password	\N	\N	t	2025-08-22 17:35:45.59714+07	2025-08-22 17:35:45.597141+07	adce9f33-49d3-4ba4-8365-7f528782548b	\N	["guest"]	pending	\N	\N
user-3-b5d206c5@example.com	User 3	hashedpassword	\N	\N	t	2025-08-29 20:22:55.132618+07	2025-08-29 20:22:55.132618+07	b5d206c5-c22a-48ad-81f5-7821693aaa84	\N	["guest"]	pending	\N	\N
user-5-b2ef2d3f@example.com	User 5	hashedpassword	\N	\N	t	2025-08-29 20:22:55.151526+07	2025-08-29 20:22:55.151526+07	b2ef2d3f-9446-43e4-9d97-470a41106641	\N	["guest"]	pending	\N	\N
user-6-3ebe0baa@example.com	User 6	hashedpassword	\N	\N	t	2025-08-29 20:22:55.152272+07	2025-08-29 20:22:55.152272+07	3ebe0baa-92a3-4aed-a787-787c1de7dc70	\N	["guest"]	pending	\N	\N
user-8-fe0d8c34@example.com	User 8	hashedpassword	\N	\N	t	2025-08-29 20:22:55.154572+07	2025-08-29 20:22:55.154572+07	fe0d8c34-e905-47e3-a1f9-7ed39e12b69b	\N	["guest"]	pending	\N	\N
user-17-8644fb2c@example.com	User 17	hashedpassword	\N	\N	t	2025-08-29 20:22:55.161233+07	2025-08-29 20:22:55.161234+07	8644fb2c-987a-425b-afcd-dfd83d98df38	\N	["guest"]	pending	\N	\N
user-18-1c74cdc1@example.com	User 18	hashedpassword	\N	\N	t	2025-08-29 20:22:55.162241+07	2025-08-29 20:22:55.162241+07	1c74cdc1-636d-4cbf-9961-0df22b652871	\N	["guest"]	pending	\N	\N
user-20-7bbea543@example.com	User 20	hashedpassword	\N	\N	t	2025-08-29 20:22:55.163882+07	2025-08-29 20:22:55.163882+07	7bbea543-c97e-4afc-9329-77878fed2b88	\N	["guest"]	pending	\N	\N
user-22-5cf86e7e@example.com	User 22	hashedpassword	\N	\N	t	2025-08-29 20:22:55.164794+07	2025-08-29 20:22:55.164794+07	5cf86e7e-dcd6-4ec3-9b46-b0a24cb03fcc	\N	["guest"]	pending	\N	\N
user-34-2b424587@example.com	User 34	hashedpassword	\N	\N	t	2025-08-29 20:22:55.171619+07	2025-08-29 20:22:55.171619+07	2b424587-4b93-45ab-8a53-a78607d20124	\N	["guest"]	pending	\N	\N
user-37-74a441e2@example.com	User 37	hashedpassword	\N	\N	t	2025-08-29 20:22:55.172979+07	2025-08-29 20:22:55.172979+07	74a441e2-d1f4-457a-b723-22f3dcc4565d	\N	["guest"]	pending	\N	\N
user-41-e3078c00@example.com	User 41	hashedpassword	\N	\N	t	2025-08-29 20:22:55.174776+07	2025-08-29 20:22:55.174776+07	e3078c00-d5c1-47bd-8f24-f3eb322e8eac	\N	["guest"]	pending	\N	\N
user-47-41b69ea1@example.com	User 47	hashedpassword	\N	\N	t	2025-08-29 20:22:55.179982+07	2025-08-29 20:22:55.179982+07	41b69ea1-12a5-4565-850d-be9998369095	\N	["guest"]	pending	\N	\N
user-48-97360a9b@example.com	User 48	hashedpassword	\N	\N	t	2025-08-29 20:22:55.180531+07	2025-08-29 20:22:55.180532+07	97360a9b-df7c-422a-8d64-41b49ab2e42a	\N	["guest"]	pending	\N	\N
user-49-9fa8365d@example.com	User 49	hashedpassword	\N	\N	t	2025-08-29 20:22:55.18091+07	2025-08-29 20:22:55.18091+07	9fa8365d-c459-4f60-bfba-88c32cef7701	\N	["guest"]	pending	\N	\N
user-50-3d047448@example.com	User 50	hashedpassword	\N	\N	t	2025-08-29 20:22:55.181305+07	2025-08-29 20:22:55.181305+07	3d047448-72ee-482a-87b0-8733cef65c83	\N	["guest"]	pending	\N	\N
user-51-0c68a66f@example.com	User 51	hashedpassword	\N	\N	t	2025-08-29 20:22:55.181659+07	2025-08-29 20:22:55.181659+07	0c68a66f-e437-4156-87d9-e0b8d2c1c3fa	\N	["guest"]	pending	\N	\N
user-57-3ee2fd5a@example.com	User 57	hashedpassword	\N	\N	t	2025-08-29 20:22:55.184187+07	2025-08-29 20:22:55.184187+07	3ee2fd5a-64b9-4470-b7a8-89db938e22cf	\N	["guest"]	pending	\N	\N
user-59-5f0a26f8@example.com	User 59	hashedpassword	\N	\N	t	2025-08-29 20:22:55.18519+07	2025-08-29 20:22:55.18519+07	5f0a26f8-f70a-4e67-87ca-4edd3a5a9210	\N	["guest"]	pending	\N	\N
user-60-0ec7810a@example.com	User 60	hashedpassword	\N	\N	t	2025-08-29 20:22:55.186014+07	2025-08-29 20:22:55.186014+07	0ec7810a-969e-4aa7-83c8-fabe8e18225d	\N	["guest"]	pending	\N	\N
user-61-b027760c@example.com	User 61	hashedpassword	\N	\N	t	2025-08-29 20:22:55.186628+07	2025-08-29 20:22:55.186628+07	b027760c-49dd-4d66-a219-43b20f8582b9	\N	["guest"]	pending	\N	\N
user-67-73aaf2aa@example.com	User 67	hashedpassword	\N	\N	t	2025-08-29 20:22:55.189907+07	2025-08-29 20:22:55.189907+07	73aaf2aa-31f5-40ee-ac6d-c45d58b8644a	\N	["guest"]	pending	\N	\N
user-69-cc5537de@example.com	User 69	hashedpassword	\N	\N	t	2025-08-29 20:22:55.190866+07	2025-08-29 20:22:55.190866+07	cc5537de-4c4a-49c0-bdfc-60ff8803b89f	\N	["guest"]	pending	\N	\N
user-71-6ae96045@example.com	User 71	hashedpassword	\N	\N	t	2025-08-29 20:22:55.191941+07	2025-08-29 20:22:55.191941+07	6ae96045-8851-496b-a2d5-d9c64a79990c	\N	["guest"]	pending	\N	\N
user-77-e0c7a5e6@example.com	User 77	hashedpassword	\N	\N	t	2025-08-29 20:22:55.197167+07	2025-08-29 20:22:55.197167+07	e0c7a5e6-235f-479b-b2a2-9d6af46c071f	\N	["guest"]	pending	\N	\N
user-79-ebbfebbe@example.com	User 79	hashedpassword	\N	\N	t	2025-08-29 20:22:55.19843+07	2025-08-29 20:22:55.19843+07	ebbfebbe-f126-47ba-bb0e-db53723866fb	\N	["guest"]	pending	\N	\N
user-80-f249460e@example.com	User 80	hashedpassword	\N	\N	t	2025-08-29 20:22:55.198776+07	2025-08-29 20:22:55.198776+07	f249460e-4c49-4f2b-8206-bd1be7f2b99d	\N	["guest"]	pending	\N	\N
user-83-cc77b77f@example.com	User 83	hashedpassword	\N	\N	t	2025-08-29 20:22:55.200004+07	2025-08-29 20:22:55.200004+07	cc77b77f-69d5-41f0-9055-ea106c1f5283	\N	["guest"]	pending	\N	\N
user-85-abd5f35c@example.com	User 85	hashedpassword	\N	\N	t	2025-08-29 20:22:55.200901+07	2025-08-29 20:22:55.200901+07	abd5f35c-7058-43e6-ad17-413c0c444db7	\N	["guest"]	pending	\N	\N
user-93-d595304e@example.com	User 93	hashedpassword	\N	\N	t	2025-08-29 20:22:55.205265+07	2025-08-29 20:22:55.205265+07	d595304e-c916-47e5-8df0-738c2210b412	\N	["guest"]	pending	\N	\N
user-96-ad4cfc46@example.com	User 96	hashedpassword	\N	\N	t	2025-08-29 20:22:55.206519+07	2025-08-29 20:22:55.206519+07	ad4cfc46-b55e-4fa1-9d34-27a95412b34d	\N	["guest"]	pending	\N	\N
user-98-f523236e@example.com	User 98	hashedpassword	\N	\N	t	2025-08-29 20:22:55.207404+07	2025-08-29 20:22:55.207404+07	f523236e-e5a4-4cf6-95f7-889d8731fee8	\N	["guest"]	pending	\N	\N
concurrent-user-1-c917f332@example.com	Concurrent User 1	password	\N	\N	t	2025-08-29 20:22:55.469257+07	2025-08-29 20:22:55.469258+07	c917f332-3a29-4635-bd96-700b68c8f8d0	\N	["guest"]	pending	\N	\N
perf-test-0-ffcf3a08@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:22:55.641321+07	2025-08-29 20:22:55.641321+07	ffcf3a08-06d7-4ddc-91ca-25a97c86122a	\N	["guest"]	pending	\N	\N
perf-test-1-0d60b21d@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:22:55.641883+07	2025-08-29 20:22:55.641883+07	0d60b21d-28a2-43d5-a33e-1e332a6d1965	\N	["guest"]	pending	\N	\N
perf-test-2-c99577e7@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:22:55.642444+07	2025-08-29 20:22:55.642444+07	c99577e7-2eac-4533-9f98-595f386eaee6	\N	["guest"]	pending	\N	\N
perf-test-3-51e00ff8@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:22:55.643516+07	2025-08-29 20:22:55.643516+07	51e00ff8-ce71-4dd6-908e-b5a39871e20a	\N	["guest"]	pending	\N	\N
perf-test-4-555040d6@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:22:55.644571+07	2025-08-29 20:22:55.644572+07	555040d6-17a8-416f-a1c1-afa52f3658c4	\N	["guest"]	pending	\N	\N
perf-test-5-71068e17@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:22:55.645414+07	2025-08-29 20:22:55.645414+07	71068e17-9fb0-4d46-8baa-0015d602b0e6	\N	["guest"]	pending	\N	\N
perf-test-6-7741b8c8@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:22:55.646157+07	2025-08-29 20:22:55.646157+07	7741b8c8-e399-4091-9d00-ae22f38e830c	\N	["guest"]	pending	\N	\N
perf-test-7-7b9a4680@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:22:55.646873+07	2025-08-29 20:22:55.646874+07	7b9a4680-38f7-4d1c-977a-6609196324aa	\N	["guest"]	pending	\N	\N
perf-test-8-703c4a9d@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:22:55.647384+07	2025-08-29 20:22:55.647384+07	703c4a9d-e462-4636-9223-a9e202c91209	\N	["guest"]	pending	\N	\N
perf-test-9-bb279416@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:22:55.647788+07	2025-08-29 20:22:55.647788+07	bb279416-65fe-49f2-9448-e58f3bdcd677	\N	["guest"]	pending	\N	\N
perf-test-10-62f36f24@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:22:55.648146+07	2025-08-29 20:22:55.648146+07	62f36f24-61a4-4662-9848-0e2e80d629f6	\N	["guest"]	pending	\N	\N
perf-test-11-016f02c8@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:22:55.648547+07	2025-08-29 20:22:55.648547+07	016f02c8-1c9b-4edd-b957-22999b1ceaf4	\N	["guest"]	pending	\N	\N
perf-test-12-3df04257@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:22:55.648946+07	2025-08-29 20:22:55.648946+07	3df04257-9e44-4201-a1d2-62fedf80e7f2	\N	["guest"]	pending	\N	\N
perf-test-13-e081c1b0@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:22:55.649368+07	2025-08-29 20:22:55.649368+07	e081c1b0-acab-45ec-ab14-7a91173d70aa	\N	["guest"]	pending	\N	\N
perf-test-14-d8876eff@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:22:55.649779+07	2025-08-29 20:22:55.649779+07	d8876eff-cebc-40b6-b1d6-5c477df88f19	\N	["guest"]	pending	\N	\N
perf-test-15-80b9a0f2@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:22:55.650426+07	2025-08-29 20:22:55.650426+07	80b9a0f2-64d7-43c2-bba9-e6920ea4ed74	\N	["guest"]	pending	\N	\N
perf-test-16-9e1303ea@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:22:55.650952+07	2025-08-29 20:22:55.650952+07	9e1303ea-2925-42d9-9f1f-2edc28fd893c	\N	["guest"]	pending	\N	\N
perf-test-17-b6ea5c55@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:22:55.651396+07	2025-08-29 20:22:55.651396+07	b6ea5c55-ec86-44e5-86fe-d66af96b3ce7	\N	["guest"]	pending	\N	\N
perf-test-18-351db8a9@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:22:55.651832+07	2025-08-29 20:22:55.651832+07	351db8a9-1115-426e-b14a-445329870a80	\N	["guest"]	pending	\N	\N
perf-test-19-adcb2f63@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:22:55.652484+07	2025-08-29 20:22:55.652484+07	adcb2f63-66e5-47b3-b45c-d754c102d984	\N	["guest"]	pending	\N	\N
perf-test-20-68103855@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:22:55.653025+07	2025-08-29 20:22:55.653026+07	68103855-523c-4f98-9e86-4e2ae0f7239f	\N	["guest"]	pending	\N	\N
perf-test-21-990a38c7@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:22:55.653574+07	2025-08-29 20:22:55.653574+07	990a38c7-43da-42fb-a9bd-548983c7ab2b	\N	["guest"]	pending	\N	\N
perf-test-22-adf46828@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:22:55.654169+07	2025-08-29 20:22:55.654169+07	adf46828-5c95-48fd-9d17-d0517c93574b	\N	["guest"]	pending	\N	\N
perf-test-23-27f3ecbb@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:22:55.654671+07	2025-08-29 20:22:55.654671+07	27f3ecbb-5cbb-4d3a-9999-1fdc690ebc1d	\N	["guest"]	pending	\N	\N
perf-test-24-8e791324@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:22:55.655525+07	2025-08-29 20:22:55.655525+07	8e791324-e886-49e8-86d8-def05135ad0b	\N	["guest"]	pending	\N	\N
perf-test-25-4e503d9b@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:22:55.655934+07	2025-08-29 20:22:55.655934+07	4e503d9b-01b0-4fce-b6db-98662cae451b	\N	["guest"]	pending	\N	\N
perf-test-26-f0add7d1@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:22:55.656325+07	2025-08-29 20:22:55.656325+07	f0add7d1-d913-46a2-8907-e9851de54d6b	\N	["guest"]	pending	\N	\N
perf-test-27-6bd498f3@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:22:55.656697+07	2025-08-29 20:22:55.656697+07	6bd498f3-29dc-4247-bf71-002f76169243	\N	["guest"]	pending	\N	\N
perf-test-28-3ff315d0@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:22:55.657077+07	2025-08-29 20:22:55.657077+07	3ff315d0-c2c3-4234-afe4-521827c76138	\N	["guest"]	pending	\N	\N
perf-test-29-0855453e@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:22:55.657493+07	2025-08-29 20:22:55.657493+07	0855453e-cac1-4585-b104-557ede1f71fa	\N	["guest"]	pending	\N	\N
perf-test-30-933c564c@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:22:55.657923+07	2025-08-29 20:22:55.657923+07	933c564c-fb36-40ea-b0c5-82f81e2e7d03	\N	["guest"]	pending	\N	\N
perf-test-31-1e6031ae@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:22:55.658398+07	2025-08-29 20:22:55.658398+07	1e6031ae-be44-4f84-8b8e-0dea49af3568	\N	["guest"]	pending	\N	\N
perf-test-32-ffc1d142@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:22:55.658846+07	2025-08-29 20:22:55.658846+07	ffc1d142-7f9b-4630-b30a-7f7c10f7e172	\N	["guest"]	pending	\N	\N
perf-test-33-185b0d72@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:22:55.65942+07	2025-08-29 20:22:55.65942+07	185b0d72-9b8e-46e9-b3be-5385a42b4656	\N	["guest"]	pending	\N	\N
perf-test-34-061ae2c2@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:22:55.660067+07	2025-08-29 20:22:55.660068+07	061ae2c2-b6d3-4f63-8a45-4ff2dc0040a6	\N	["guest"]	pending	\N	\N
perf-test-35-7dde4220@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:22:55.660704+07	2025-08-29 20:22:55.660704+07	7dde4220-8c6a-41cd-99c8-21256c05780d	\N	["guest"]	pending	\N	\N
perf-test-36-8868a3ab@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:22:55.661529+07	2025-08-29 20:22:55.661529+07	8868a3ab-ec78-434e-b1c9-1e1b2988a86f	\N	["guest"]	pending	\N	\N
perf-test-37-f126c53c@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:22:55.662188+07	2025-08-29 20:22:55.662188+07	f126c53c-736f-4f97-8b24-73f408e36bb5	\N	["guest"]	pending	\N	\N
perf-test-38-a09ee771@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:22:55.662752+07	2025-08-29 20:22:55.662752+07	a09ee771-5725-4b33-ab55-c4c68459f375	\N	["guest"]	pending	\N	\N
perf-test-39-36ea63c6@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:22:55.663405+07	2025-08-29 20:22:55.663405+07	36ea63c6-df83-4d4b-8bba-400245ff3793	\N	["guest"]	pending	\N	\N
perf-test-40-ecf364d6@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:22:55.663833+07	2025-08-29 20:22:55.663833+07	ecf364d6-04e2-4b50-996b-30abec6e8d78	\N	["guest"]	pending	\N	\N
perf-test-41-e5e018a1@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:22:55.664222+07	2025-08-29 20:22:55.664222+07	e5e018a1-d3ab-4603-a92f-76692498f48a	\N	["guest"]	pending	\N	\N
perf-test-42-b91cb69f@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:22:55.664571+07	2025-08-29 20:22:55.664571+07	b91cb69f-aaf9-4053-ba0c-ee870bfb4a99	\N	["guest"]	pending	\N	\N
perf-test-43-07cbd8ab@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:22:55.664946+07	2025-08-29 20:22:55.664946+07	07cbd8ab-eb18-4c23-9589-bba405ef7fc6	\N	["guest"]	pending	\N	\N
perf-test-44-9f4ae5dc@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:22:55.665278+07	2025-08-29 20:22:55.665278+07	9f4ae5dc-5a73-49e1-870a-97abb9c7ba1c	\N	["guest"]	pending	\N	\N
perf-test-45-df2d1474@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:22:55.665661+07	2025-08-29 20:22:55.665661+07	df2d1474-22ea-4a00-9817-d21e1831d3df	\N	["guest"]	pending	\N	\N
perf-test-46-2a8a6f53@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:22:55.665996+07	2025-08-29 20:22:55.665996+07	2a8a6f53-705d-49b3-b6f2-b6d6f388dc08	\N	["guest"]	pending	\N	\N
perf-test-47-a418743c@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:22:55.666398+07	2025-08-29 20:22:55.666398+07	a418743c-b5e3-4a34-b04e-61f79073590a	\N	["guest"]	pending	\N	\N
perf-test-48-f6b33ad5@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:22:55.666894+07	2025-08-29 20:22:55.666894+07	f6b33ad5-36a9-45b9-8b3a-c97e95804372	\N	["guest"]	pending	\N	\N
perf-test-49-72cfa57f@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:22:55.667367+07	2025-08-29 20:22:55.667367+07	72cfa57f-acb0-4f79-a719-d90169945bf3	\N	["guest"]	pending	\N	\N
user-5-81b7dd63@example.com	User 5	hashedpassword	\N	\N	t	2025-08-29 20:59:13.133689+07	2025-08-29 20:59:13.133689+07	81b7dd63-a9d1-45f5-a16e-8c8fd7662046	\N	["guest"]	pending	\N	\N
user-6-626b431e@example.com	User 6	hashedpassword	\N	\N	t	2025-08-29 20:59:13.137557+07	2025-08-29 20:59:13.137557+07	626b431e-d1d3-4148-acfe-c8afa6732719	\N	["guest"]	pending	\N	\N
user-10-2a3165bf@example.com	User 10	hashedpassword	\N	\N	t	2025-08-29 20:59:13.144161+07	2025-08-29 20:59:13.144161+07	2a3165bf-8b44-4d3b-afdb-37ace59ba452	\N	["guest"]	pending	\N	\N
user-14-f7f30d3f@example.com	User 14	hashedpassword	\N	\N	t	2025-08-29 20:59:13.147214+07	2025-08-29 20:59:13.147214+07	f7f30d3f-6d23-4193-aabc-05d5f906e511	\N	["guest"]	pending	\N	\N
user-16-c9d8c77b@example.com	User 16	hashedpassword	\N	\N	t	2025-08-29 20:59:13.148433+07	2025-08-29 20:59:13.148433+07	c9d8c77b-806c-4b1a-be76-14e810a73b17	\N	["guest"]	pending	\N	\N
user-19-c8597096@example.com	User 19	hashedpassword	\N	\N	t	2025-08-29 20:59:13.149979+07	2025-08-29 20:59:13.14998+07	c8597096-4e0c-4667-b3f0-019ab5d2b945	\N	["guest"]	pending	\N	\N
user-20-f77b70d8@example.com	User 20	hashedpassword	\N	\N	t	2025-08-29 20:59:13.150418+07	2025-08-29 20:59:13.150418+07	f77b70d8-160a-4b18-8a68-189041422b64	\N	["guest"]	pending	\N	\N
user-26-a5cac7ca@example.com	User 26	hashedpassword	\N	\N	t	2025-08-29 20:59:13.153194+07	2025-08-29 20:59:13.153194+07	a5cac7ca-0d31-44b5-8794-28a6764e5cb5	\N	["guest"]	pending	\N	\N
user-27-305e14a2@example.com	User 27	hashedpassword	\N	\N	t	2025-08-29 20:59:13.154252+07	2025-08-29 20:59:13.154252+07	305e14a2-0cf7-4a48-b174-a161c2a0e0fb	\N	["guest"]	pending	\N	\N
user-32-d2fb311a@example.com	User 32	hashedpassword	\N	\N	t	2025-08-29 20:59:13.159794+07	2025-08-29 20:59:13.159794+07	d2fb311a-c5f6-45e3-a5d0-f3ac693c5ac7	\N	["guest"]	pending	\N	\N
user-41-11371936@example.com	User 41	hashedpassword	\N	\N	t	2025-08-29 20:59:13.165692+07	2025-08-29 20:59:13.165692+07	11371936-d9a2-4405-84f9-1781b0908b5c	\N	["guest"]	pending	\N	\N
user-43-87243f7b@example.com	User 43	hashedpassword	\N	\N	t	2025-08-29 20:59:13.166477+07	2025-08-29 20:59:13.166477+07	87243f7b-5331-4206-942a-6b803388ba74	\N	["guest"]	pending	\N	\N
user-44-868702d2@example.com	User 44	hashedpassword	\N	\N	t	2025-08-29 20:59:13.16689+07	2025-08-29 20:59:13.166891+07	868702d2-91a7-4c0e-b2e0-0b4019e5c84d	\N	["guest"]	pending	\N	\N
user-45-7902e580@example.com	User 45	hashedpassword	\N	\N	t	2025-08-29 20:59:13.167273+07	2025-08-29 20:59:13.167274+07	7902e580-5316-48a8-a5fe-4ee6f899c020	\N	["guest"]	pending	\N	\N
user-50-6297d96f@example.com	User 50	hashedpassword	\N	\N	t	2025-08-29 20:59:13.171245+07	2025-08-29 20:59:13.171245+07	6297d96f-1de4-4c47-9584-d1bf7aae2772	\N	["guest"]	pending	\N	\N
user-53-de9755aa@example.com	User 53	hashedpassword	\N	\N	t	2025-08-29 20:59:13.175025+07	2025-08-29 20:59:13.175025+07	de9755aa-8b8a-47cd-af89-16c119283b35	\N	["guest"]	pending	\N	\N
user-57-c2344628@example.com	User 57	hashedpassword	\N	\N	t	2025-08-29 20:59:13.177422+07	2025-08-29 20:59:13.177422+07	c2344628-5dec-4b6e-a55e-ede06eff2d57	\N	["guest"]	pending	\N	\N
user-62-afd4d62d@example.com	User 62	hashedpassword	\N	\N	t	2025-08-29 20:59:13.180098+07	2025-08-29 20:59:13.180098+07	afd4d62d-f5a9-4a44-8dce-7957996646ed	\N	["guest"]	pending	\N	\N
user-63-010b0011@example.com	User 63	hashedpassword	\N	\N	t	2025-08-29 20:59:13.180508+07	2025-08-29 20:59:13.180508+07	010b0011-c433-4a1e-86da-a1180bafbf0f	\N	["guest"]	pending	\N	\N
user-64-f245e833@example.com	User 64	hashedpassword	\N	\N	t	2025-08-29 20:59:13.18085+07	2025-08-29 20:59:13.18085+07	f245e833-02e0-4f52-8c1a-70f0877b2206	\N	["guest"]	pending	\N	\N
user-69-6fa6c1c5@example.com	User 69	hashedpassword	\N	\N	t	2025-08-29 20:59:13.182746+07	2025-08-29 20:59:13.182746+07	6fa6c1c5-90df-482b-a24b-bfd9c56ab3ef	\N	["guest"]	pending	\N	\N
user-73-3cd73a41@example.com	User 73	hashedpassword	\N	\N	t	2025-08-29 20:59:13.184538+07	2025-08-29 20:59:13.184538+07	3cd73a41-a35c-42e9-bc0b-bbf12f4275d8	\N	["guest"]	pending	\N	\N
user-88-ac392914@example.com	User 88	hashedpassword	\N	\N	t	2025-08-29 20:59:13.196308+07	2025-08-29 20:59:13.196308+07	ac392914-c51a-45c0-aa23-63dd7f65e666	\N	["guest"]	pending	\N	\N
user-90-277cd995@example.com	User 90	hashedpassword	\N	\N	t	2025-08-29 20:59:13.197152+07	2025-08-29 20:59:13.197152+07	277cd995-406c-445b-85f8-a743b1f0a255	\N	["guest"]	pending	\N	\N
concurrent-user-1-88836a04@example.com	Concurrent User 1	password	\N	\N	t	2025-08-29 20:59:13.418641+07	2025-08-29 20:59:13.418641+07	88836a04-f730-4544-b9eb-adf786812687	\N	["guest"]	pending	\N	\N
perf-test-0-10909f9c@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:59:13.649848+07	2025-08-29 20:59:13.649848+07	10909f9c-7f3d-4f45-8341-a4a92c13d59a	\N	["guest"]	pending	\N	\N
perf-test-1-8d63e8ec@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:59:13.650746+07	2025-08-29 20:59:13.650746+07	8d63e8ec-2d6f-4307-bb63-3123dc94dcde	\N	["guest"]	pending	\N	\N
perf-test-2-6f7b43aa@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:59:13.651867+07	2025-08-29 20:59:13.651867+07	6f7b43aa-286a-42a0-925e-2b5150101d01	\N	["guest"]	pending	\N	\N
perf-test-3-2900ca82@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:59:13.652518+07	2025-08-29 20:59:13.652518+07	2900ca82-e72c-4e36-8bc6-faf0906775ca	\N	["guest"]	pending	\N	\N
perf-test-4-08c31355@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:59:13.653136+07	2025-08-29 20:59:13.653136+07	08c31355-dc68-4542-9ad9-cc82a1bc4547	\N	["guest"]	pending	\N	\N
perf-test-5-5b283290@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:59:13.65425+07	2025-08-29 20:59:13.65425+07	5b283290-e353-4a33-9c9a-215cd12ddd2b	\N	["guest"]	pending	\N	\N
perf-test-6-7125637e@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:59:13.65534+07	2025-08-29 20:59:13.65534+07	7125637e-9dcb-4db4-89e6-7f583b6ae638	\N	["guest"]	pending	\N	\N
perf-test-7-72e96214@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:59:13.656928+07	2025-08-29 20:59:13.656929+07	72e96214-6429-4039-a73a-f87ff9cb545b	\N	["guest"]	pending	\N	\N
perf-test-8-99662661@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:59:13.658176+07	2025-08-29 20:59:13.658176+07	99662661-e2af-41e6-aba0-03cdf59dfa0a	\N	["guest"]	pending	\N	\N
perf-test-9-17530ffb@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:59:13.658707+07	2025-08-29 20:59:13.658708+07	17530ffb-bd69-4f47-aa0c-7ce72ee23b4d	\N	["guest"]	pending	\N	\N
perf-test-10-7a11e67f@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:59:13.659431+07	2025-08-29 20:59:13.659431+07	7a11e67f-aef0-412f-823f-9a3642aaff7e	\N	["guest"]	pending	\N	\N
perf-test-11-ff7acae3@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:59:13.660218+07	2025-08-29 20:59:13.660218+07	ff7acae3-2025-41af-a051-c2b44212e167	\N	["guest"]	pending	\N	\N
perf-test-12-b73e409c@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:59:13.660836+07	2025-08-29 20:59:13.660836+07	b73e409c-0446-4370-a502-5ec2cc346396	\N	["guest"]	pending	\N	\N
perf-test-13-317230a3@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:59:13.661437+07	2025-08-29 20:59:13.661437+07	317230a3-02ce-4d8c-b283-c50bcbb9d9df	\N	["guest"]	pending	\N	\N
perf-test-14-567b3323@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:59:13.661937+07	2025-08-29 20:59:13.661937+07	567b3323-32e5-45db-9299-6446674046a2	\N	["guest"]	pending	\N	\N
perf-test-15-3d421318@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:59:13.662378+07	2025-08-29 20:59:13.662378+07	3d421318-e2b4-4ed3-9d3c-6ebe260526d2	\N	["guest"]	pending	\N	\N
perf-test-16-4172ced6@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:59:13.66284+07	2025-08-29 20:59:13.66284+07	4172ced6-523a-4606-ba4f-f54052cf625e	\N	["guest"]	pending	\N	\N
perf-test-17-164de3ad@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:59:13.663442+07	2025-08-29 20:59:13.663442+07	164de3ad-c6f7-4ee9-9176-497e1a1478b0	\N	["guest"]	pending	\N	\N
perf-test-18-5a6ab97b@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:59:13.663811+07	2025-08-29 20:59:13.663811+07	5a6ab97b-18c7-46ab-ac98-34685feee08c	\N	["guest"]	pending	\N	\N
perf-test-19-f9d0327e@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:59:13.6642+07	2025-08-29 20:59:13.6642+07	f9d0327e-41fc-4371-b0c2-42f8a35fa82a	\N	["guest"]	pending	\N	\N
perf-test-20-c6e95bb7@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:59:13.664575+07	2025-08-29 20:59:13.664575+07	c6e95bb7-3136-4e7c-8a19-e448fac96076	\N	["guest"]	pending	\N	\N
perf-test-21-ead3ea12@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:59:13.664952+07	2025-08-29 20:59:13.664952+07	ead3ea12-2762-467f-8aeb-d6a990a26805	\N	["guest"]	pending	\N	\N
perf-test-22-8c5c3b86@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:59:13.665357+07	2025-08-29 20:59:13.665357+07	8c5c3b86-1dc0-4cbd-b081-a8debe200a5a	\N	["guest"]	pending	\N	\N
perf-test-23-a25091a4@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:59:13.66573+07	2025-08-29 20:59:13.665731+07	a25091a4-6bf3-48c4-82e6-20ca86e6b22b	\N	["guest"]	pending	\N	\N
perf-test-24-43b27709@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:59:13.666093+07	2025-08-29 20:59:13.666093+07	43b27709-50bf-4db1-8b37-db2ca547dda5	\N	["guest"]	pending	\N	\N
perf-test-25-a6a6e109@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:59:13.666477+07	2025-08-29 20:59:13.666477+07	a6a6e109-7cca-4acd-bbdb-62ea77c77f44	\N	["guest"]	pending	\N	\N
perf-test-26-c418dcb6@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:59:13.666853+07	2025-08-29 20:59:13.666853+07	c418dcb6-f773-4eb8-9f0b-5b2fb542fa51	\N	["guest"]	pending	\N	\N
perf-test-27-7677c7d7@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:59:13.667226+07	2025-08-29 20:59:13.667226+07	7677c7d7-c40c-483e-9253-d13178c686be	\N	["guest"]	pending	\N	\N
perf-test-28-010f25d2@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:59:13.66756+07	2025-08-29 20:59:13.66756+07	010f25d2-8a8a-446a-8e97-b6203c6dced9	\N	["guest"]	pending	\N	\N
perf-test-29-38439f67@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:59:13.667909+07	2025-08-29 20:59:13.667909+07	38439f67-4f3b-4f15-a237-c6152d4755df	\N	["guest"]	pending	\N	\N
perf-test-30-d4bba616@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:59:13.668321+07	2025-08-29 20:59:13.668321+07	d4bba616-910b-4ea3-8bcb-8c52b52ccb37	\N	["guest"]	pending	\N	\N
perf-test-31-1b875483@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:59:13.668707+07	2025-08-29 20:59:13.668708+07	1b875483-e0d1-476f-a229-8200bc494629	\N	["guest"]	pending	\N	\N
perf-test-32-adb3b884@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:59:13.669106+07	2025-08-29 20:59:13.669106+07	adb3b884-1be6-49b4-8a86-23bd1364ef4a	\N	["guest"]	pending	\N	\N
perf-test-33-60681706@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:59:13.669593+07	2025-08-29 20:59:13.669593+07	60681706-f4f9-484e-a2c0-47190251e799	\N	["guest"]	pending	\N	\N
perf-test-34-a4fe27d9@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:59:13.670069+07	2025-08-29 20:59:13.670069+07	a4fe27d9-3cf3-4bbd-8a85-b8aa82dcea41	\N	["guest"]	pending	\N	\N
perf-test-35-7420a082@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:59:13.670678+07	2025-08-29 20:59:13.670678+07	7420a082-99d8-47ad-9d39-411c5203affd	\N	["guest"]	pending	\N	\N
perf-test-36-10b27229@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:59:13.671394+07	2025-08-29 20:59:13.671394+07	10b27229-319f-4f06-aa2d-a3dc4776d7da	\N	["guest"]	pending	\N	\N
perf-test-37-479bee0a@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:59:13.672468+07	2025-08-29 20:59:13.672468+07	479bee0a-1144-4da7-8b92-a10602530671	\N	["guest"]	pending	\N	\N
perf-test-38-7da505f6@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:59:13.673869+07	2025-08-29 20:59:13.673869+07	7da505f6-802a-46d9-aee0-8dc43de6598d	\N	["guest"]	pending	\N	\N
perf-test-39-6f6c4483@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:59:13.674879+07	2025-08-29 20:59:13.674879+07	6f6c4483-2482-4d2c-9aba-ebfb98e50a4f	\N	["guest"]	pending	\N	\N
perf-test-40-5da393ec@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:59:13.675527+07	2025-08-29 20:59:13.675527+07	5da393ec-0662-4ec5-86b6-12f3f04e95e2	\N	["guest"]	pending	\N	\N
perf-test-41-6ad19bf3@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:59:13.676309+07	2025-08-29 20:59:13.676319+07	6ad19bf3-483e-40f6-8f14-10b0d394ded2	\N	["guest"]	pending	\N	\N
perf-test-42-ed8e9098@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:59:13.677022+07	2025-08-29 20:59:13.677022+07	ed8e9098-8a9f-4fe5-89b5-0f1bc319bb95	\N	["guest"]	pending	\N	\N
perf-test-43-98a18252@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:59:13.677671+07	2025-08-29 20:59:13.677671+07	98a18252-3f01-4c4c-82d8-06c7cdac31e0	\N	["guest"]	pending	\N	\N
perf-test-44-047d3d9c@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:59:13.678337+07	2025-08-29 20:59:13.678337+07	047d3d9c-a98c-4d8a-b217-e99766613506	\N	["guest"]	pending	\N	\N
perf-test-45-4c7e927a@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:59:13.678865+07	2025-08-29 20:59:13.678865+07	4c7e927a-91f3-4773-9aa7-b9baa16ae1aa	\N	["guest"]	pending	\N	\N
perf-test-46-57b46228@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:59:13.679299+07	2025-08-29 20:59:13.679299+07	57b46228-384e-4d00-84a7-08c5fcc84108	\N	["guest"]	pending	\N	\N
perf-test-47-218423f2@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:59:13.679692+07	2025-08-29 20:59:13.679692+07	218423f2-64f1-45ec-871b-340032658443	\N	["guest"]	pending	\N	\N
perf-test-48-ecd52945@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:59:13.680062+07	2025-08-29 20:59:13.680062+07	ecd52945-eec8-4979-85ac-002fa5aae0d3	\N	["guest"]	pending	\N	\N
perf-test-49-6d60fc09@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:59:13.680446+07	2025-08-29 20:59:13.680446+07	6d60fc09-938b-491c-89f7-22aa8135240c	\N	["guest"]	pending	\N	\N
user-1-d714ae7e@example.com	User 1	hashedpassword	\N	\N	t	2025-08-29 21:59:39.95863+07	2025-08-29 21:59:39.95863+07	d714ae7e-9703-45b9-95e8-1d2265208277	\N	["guest"]	pending	\N	\N
user-7-043714f8@example.com	User 7	hashedpassword	\N	\N	t	2025-08-29 21:59:39.975804+07	2025-08-29 21:59:39.975804+07	043714f8-5336-406b-982e-3297fad105a7	\N	["guest"]	pending	\N	\N
user-8-6dc29b43@example.com	User 8	hashedpassword	\N	\N	t	2025-08-29 21:59:39.976949+07	2025-08-29 21:59:39.976949+07	6dc29b43-8af8-4d0d-b40f-9097ea81ed92	\N	["guest"]	pending	\N	\N
user-10-e7dea08b@example.com	User 10	hashedpassword	\N	\N	t	2025-08-29 21:59:39.982762+07	2025-08-29 21:59:39.982762+07	e7dea08b-0419-4dce-9865-50a19aab15e3	\N	["guest"]	pending	\N	\N
user-18-1096888b@example.com	User 18	hashedpassword	\N	\N	t	2025-08-29 21:59:39.995565+07	2025-08-29 21:59:39.995565+07	1096888b-797a-4b51-b5ef-aa7d10b127f2	\N	["guest"]	pending	\N	\N
user-21-e8e26485@example.com	User 21	hashedpassword	\N	\N	t	2025-08-29 21:59:39.998468+07	2025-08-29 21:59:39.998468+07	e8e26485-f23b-49f9-886a-f6afff10b445	\N	["guest"]	pending	\N	\N
user-23-c42cae77@example.com	User 23	hashedpassword	\N	\N	t	2025-08-29 21:59:40.000346+07	2025-08-29 21:59:40.000347+07	c42cae77-5d6b-4d93-98c5-9bd7bd52dec8	\N	["guest"]	pending	\N	\N
user-25-31ca91fb@example.com	User 25	hashedpassword	\N	\N	t	2025-08-29 21:59:40.003809+07	2025-08-29 21:59:40.003809+07	31ca91fb-26fa-43e1-9862-9f29c526c332	\N	["guest"]	pending	\N	\N
user-34-c7620124@example.com	User 34	hashedpassword	\N	\N	t	2025-08-29 21:59:40.013292+07	2025-08-29 21:59:40.013293+07	c7620124-7ef8-4a5a-8e2c-bf08cb9836db	\N	["guest"]	pending	\N	\N
user-37-2b1e6d1a@example.com	User 37	hashedpassword	\N	\N	t	2025-08-29 21:59:40.015593+07	2025-08-29 21:59:40.015593+07	2b1e6d1a-d2df-4191-a51e-fb981fcdda9e	\N	["guest"]	pending	\N	\N
user-44-bcf6947c@example.com	User 44	hashedpassword	\N	\N	t	2025-08-29 21:59:40.0235+07	2025-08-29 21:59:40.0235+07	bcf6947c-ef6a-4be7-a205-ad14cf885f04	\N	["guest"]	pending	\N	\N
user-53-503d0a2c@example.com	User 53	hashedpassword	\N	\N	t	2025-08-29 21:59:40.03084+07	2025-08-29 21:59:40.03084+07	503d0a2c-3176-4ea8-ad2b-66bfe113f7e9	\N	["guest"]	pending	\N	\N
user-57-3da45a6a@example.com	User 57	hashedpassword	\N	\N	t	2025-08-29 21:59:40.038277+07	2025-08-29 21:59:40.038277+07	3da45a6a-e7cb-404e-9f5f-fc07851c12c8	\N	["guest"]	pending	\N	\N
user-61-acdcf02d@example.com	User 61	hashedpassword	\N	\N	t	2025-08-29 21:59:40.045988+07	2025-08-29 21:59:40.045989+07	acdcf02d-cb3f-4633-bbd4-6cd5ae6cf16c	\N	["guest"]	pending	\N	\N
user-63-cf1d1bba@example.com	User 63	hashedpassword	\N	\N	t	2025-08-29 21:59:40.048368+07	2025-08-29 21:59:40.048368+07	cf1d1bba-bcaf-4aa3-96bb-61e1b1a6fa4c	\N	["guest"]	pending	\N	\N
user-69-db1b7c7e@example.com	User 69	hashedpassword	\N	\N	t	2025-08-29 21:59:40.135936+07	2025-08-29 21:59:40.135936+07	db1b7c7e-b108-4c6d-b7dc-db1711e3dc68	\N	["guest"]	pending	\N	\N
user-70-b59bce99@example.com	User 70	hashedpassword	\N	\N	t	2025-08-29 21:59:40.137748+07	2025-08-29 21:59:40.137748+07	b59bce99-7911-4fcb-ac14-d6441ca5c2d3	\N	["guest"]	pending	\N	\N
user-71-e3bf009a@example.com	User 71	hashedpassword	\N	\N	t	2025-08-29 21:59:40.138525+07	2025-08-29 21:59:40.138526+07	e3bf009a-b4a6-44e2-aab6-0815fd490816	\N	["guest"]	pending	\N	\N
user-73-f452feab@example.com	User 73	hashedpassword	\N	\N	t	2025-08-29 21:59:40.140296+07	2025-08-29 21:59:40.140296+07	f452feab-26a6-4b87-84ba-c567fc6cbadc	\N	["guest"]	pending	\N	\N
user-75-0ca28d0e@example.com	User 75	hashedpassword	\N	\N	t	2025-08-29 21:59:40.142722+07	2025-08-29 21:59:40.142723+07	0ca28d0e-3c8d-4bec-9e24-4a93ff6c3820	\N	["guest"]	pending	\N	\N
user-79-ac467b17@example.com	User 79	hashedpassword	\N	\N	t	2025-08-29 21:59:40.146898+07	2025-08-29 21:59:40.146898+07	ac467b17-78be-4951-bf27-98dc1bd8e171	\N	["guest"]	pending	\N	\N
user-80-55f25702@example.com	User 80	hashedpassword	\N	\N	t	2025-08-29 21:59:40.147841+07	2025-08-29 21:59:40.147841+07	55f25702-2e9b-4924-a519-7ddd58ca7f0a	\N	["guest"]	pending	\N	\N
user-81-bcfb9094@example.com	User 81	hashedpassword	\N	\N	t	2025-08-29 21:59:40.148598+07	2025-08-29 21:59:40.148599+07	bcfb9094-c571-4ed6-9092-819381bd99b3	\N	["guest"]	pending	\N	\N
user-82-3406aadb@example.com	User 82	hashedpassword	\N	\N	t	2025-08-29 21:59:40.149252+07	2025-08-29 21:59:40.149252+07	3406aadb-b69a-4b67-8467-e20748d72a31	\N	["guest"]	pending	\N	\N
user-87-13633098@example.com	User 87	hashedpassword	\N	\N	t	2025-08-29 21:59:40.152076+07	2025-08-29 21:59:40.152076+07	13633098-f2fc-4f2a-b0bd-07b44bf78d43	\N	["guest"]	pending	\N	\N
user-97-ba132409@example.com	User 97	hashedpassword	\N	\N	t	2025-08-29 21:59:40.161418+07	2025-08-29 21:59:40.161418+07	ba132409-69c2-4da0-9207-7329e4ebbecf	\N	["guest"]	pending	\N	\N
user-99-e9c1d5e9@example.com	User 99	hashedpassword	\N	\N	t	2025-08-29 21:59:40.163309+07	2025-08-29 21:59:40.163309+07	e9c1d5e9-6bec-41c0-8283-98bc13e476ad	\N	["guest"]	pending	\N	\N
concurrent-user-1-a6ebeb41@example.com	Concurrent User 1	password	\N	\N	t	2025-08-29 21:59:40.598808+07	2025-08-29 21:59:40.598809+07	a6ebeb41-9670-4535-9106-e3fc7fef4bdb	\N	["guest"]	pending	\N	\N
perf-test-0-836f89d5@example.com	Performance User 0	password	\N	\N	t	2025-08-29 21:59:41.226768+07	2025-08-29 21:59:41.226771+07	836f89d5-67fd-4223-8938-ef4a8cea5040	\N	["guest"]	pending	\N	\N
perf-test-1-da19911d@example.com	Performance User 1	password	\N	\N	t	2025-08-29 21:59:41.227945+07	2025-08-29 21:59:41.227945+07	da19911d-a978-4cd9-97f9-f279e4d9cb35	\N	["guest"]	pending	\N	\N
perf-test-2-e39af74f@example.com	Performance User 2	password	\N	\N	t	2025-08-29 21:59:41.228731+07	2025-08-29 21:59:41.228731+07	e39af74f-6148-4e92-ad14-404359755c01	\N	["guest"]	pending	\N	\N
perf-test-3-cab7a419@example.com	Performance User 3	password	\N	\N	t	2025-08-29 21:59:41.22946+07	2025-08-29 21:59:41.229461+07	cab7a419-043d-4a4d-a26f-f885ce5383a2	\N	["guest"]	pending	\N	\N
perf-test-4-f71cc93c@example.com	Performance User 4	password	\N	\N	t	2025-08-29 21:59:41.230234+07	2025-08-29 21:59:41.230235+07	f71cc93c-a68b-4c91-8cac-c3e7568023f3	\N	["guest"]	pending	\N	\N
perf-test-5-58268a04@example.com	Performance User 5	password	\N	\N	t	2025-08-29 21:59:41.230891+07	2025-08-29 21:59:41.230892+07	58268a04-70b6-4635-b99c-2739c8e12048	\N	["guest"]	pending	\N	\N
perf-test-6-2c3d78ec@example.com	Performance User 6	password	\N	\N	t	2025-08-29 21:59:41.231517+07	2025-08-29 21:59:41.231517+07	2c3d78ec-ad51-4b24-9272-eb8ed14ff551	\N	["guest"]	pending	\N	\N
perf-test-7-f1d41892@example.com	Performance User 7	password	\N	\N	t	2025-08-29 21:59:41.232091+07	2025-08-29 21:59:41.232091+07	f1d41892-ecc1-4b8a-b624-76fed805743e	\N	["guest"]	pending	\N	\N
perf-test-8-3b8f7305@example.com	Performance User 8	password	\N	\N	t	2025-08-29 21:59:41.232857+07	2025-08-29 21:59:41.232857+07	3b8f7305-77c3-469c-a4f4-9ad156fafcc8	\N	["guest"]	pending	\N	\N
perf-test-9-4169b06d@example.com	Performance User 9	password	\N	\N	t	2025-08-29 21:59:41.233932+07	2025-08-29 21:59:41.233932+07	4169b06d-9c79-403e-a599-98374decb9c0	\N	["guest"]	pending	\N	\N
perf-test-10-89475cf4@example.com	Performance User 10	password	\N	\N	t	2025-08-29 21:59:41.234657+07	2025-08-29 21:59:41.234658+07	89475cf4-547b-48ea-8596-e95bce04eadc	\N	["guest"]	pending	\N	\N
perf-test-11-2f65b17f@example.com	Performance User 11	password	\N	\N	t	2025-08-29 21:59:41.235429+07	2025-08-29 21:59:41.235429+07	2f65b17f-de86-479a-aafd-6e09a6cc70fd	\N	["guest"]	pending	\N	\N
perf-test-12-72680ea0@example.com	Performance User 12	password	\N	\N	t	2025-08-29 21:59:41.236319+07	2025-08-29 21:59:41.236319+07	72680ea0-cbd5-4d2e-b589-7817994e61ac	\N	["guest"]	pending	\N	\N
perf-test-13-7753169c@example.com	Performance User 13	password	\N	\N	t	2025-08-29 21:59:41.237255+07	2025-08-29 21:59:41.237256+07	7753169c-e74f-4f1c-83de-cb21fa86c628	\N	["guest"]	pending	\N	\N
perf-test-14-38fa1834@example.com	Performance User 14	password	\N	\N	t	2025-08-29 21:59:41.238058+07	2025-08-29 21:59:41.238058+07	38fa1834-5ab2-4a13-a4fd-a222f668e5b9	\N	["guest"]	pending	\N	\N
perf-test-15-e26d1cec@example.com	Performance User 15	password	\N	\N	t	2025-08-29 21:59:41.238535+07	2025-08-29 21:59:41.238536+07	e26d1cec-bdba-4d53-b9b2-93b97bdbe705	\N	["guest"]	pending	\N	\N
perf-test-16-7a55e67d@example.com	Performance User 16	password	\N	\N	t	2025-08-29 21:59:41.238996+07	2025-08-29 21:59:41.238996+07	7a55e67d-4136-4fe7-963c-99d4cee549a4	\N	["guest"]	pending	\N	\N
perf-test-17-fadb6de5@example.com	Performance User 17	password	\N	\N	t	2025-08-29 21:59:41.2395+07	2025-08-29 21:59:41.2395+07	fadb6de5-18ea-435b-98d2-b1760c7b4642	\N	["guest"]	pending	\N	\N
perf-test-18-3ccc8acc@example.com	Performance User 18	password	\N	\N	t	2025-08-29 21:59:41.239886+07	2025-08-29 21:59:41.239886+07	3ccc8acc-273a-4840-a615-29bfb2310486	\N	["guest"]	pending	\N	\N
perf-test-19-c385a260@example.com	Performance User 19	password	\N	\N	t	2025-08-29 21:59:41.240402+07	2025-08-29 21:59:41.240402+07	c385a260-eb45-41f4-a3c3-53d113f54514	\N	["guest"]	pending	\N	\N
perf-test-20-6a5a5ebd@example.com	Performance User 20	password	\N	\N	t	2025-08-29 21:59:41.240885+07	2025-08-29 21:59:41.240886+07	6a5a5ebd-a447-4326-83ef-eedf348a0534	\N	["guest"]	pending	\N	\N
perf-test-21-53f477de@example.com	Performance User 21	password	\N	\N	t	2025-08-29 21:59:41.241356+07	2025-08-29 21:59:41.241356+07	53f477de-112d-4e72-87f7-a08250e8d691	\N	["guest"]	pending	\N	\N
perf-test-22-fd465ad7@example.com	Performance User 22	password	\N	\N	t	2025-08-29 21:59:41.241888+07	2025-08-29 21:59:41.241888+07	fd465ad7-a538-4613-9dbe-a872600b5627	\N	["guest"]	pending	\N	\N
perf-test-23-cb2ec055@example.com	Performance User 23	password	\N	\N	t	2025-08-29 21:59:41.242383+07	2025-08-29 21:59:41.242383+07	cb2ec055-58f6-49fe-9fab-b0edbd635170	\N	["guest"]	pending	\N	\N
perf-test-24-34bf5ea0@example.com	Performance User 24	password	\N	\N	t	2025-08-29 21:59:41.242749+07	2025-08-29 21:59:41.242749+07	34bf5ea0-22b8-4644-be37-31acadd082d4	\N	["guest"]	pending	\N	\N
perf-test-25-337c2ea5@example.com	Performance User 25	password	\N	\N	t	2025-08-29 21:59:41.243138+07	2025-08-29 21:59:41.243138+07	337c2ea5-fbd0-4724-a6ba-40624285dba2	\N	["guest"]	pending	\N	\N
perf-test-26-3010306d@example.com	Performance User 26	password	\N	\N	t	2025-08-29 21:59:41.243548+07	2025-08-29 21:59:41.243548+07	3010306d-0e29-4bfe-aacd-34c12c90155b	\N	["guest"]	pending	\N	\N
perf-test-27-aa348647@example.com	Performance User 27	password	\N	\N	t	2025-08-29 21:59:41.24393+07	2025-08-29 21:59:41.243931+07	aa348647-5bfc-4edc-b13d-200772297dd4	\N	["guest"]	pending	\N	\N
perf-test-28-7a181af9@example.com	Performance User 28	password	\N	\N	t	2025-08-29 21:59:41.244314+07	2025-08-29 21:59:41.244314+07	7a181af9-ae1b-4b19-b24a-2683228954b3	\N	["guest"]	pending	\N	\N
perf-test-29-55cd5234@example.com	Performance User 29	password	\N	\N	t	2025-08-29 21:59:41.244737+07	2025-08-29 21:59:41.244737+07	55cd5234-7816-4754-b47e-7034d8929fc3	\N	["guest"]	pending	\N	\N
perf-test-30-d8cbc26f@example.com	Performance User 30	password	\N	\N	t	2025-08-29 21:59:41.245191+07	2025-08-29 21:59:41.245192+07	d8cbc26f-ac75-450f-8044-2cf61f0858d8	\N	["guest"]	pending	\N	\N
perf-test-31-914b9bb5@example.com	Performance User 31	password	\N	\N	t	2025-08-29 21:59:41.245588+07	2025-08-29 21:59:41.245588+07	914b9bb5-58ce-4501-86bf-c14845d36594	\N	["guest"]	pending	\N	\N
perf-test-32-eda3694e@example.com	Performance User 32	password	\N	\N	t	2025-08-29 21:59:41.245978+07	2025-08-29 21:59:41.245979+07	eda3694e-7456-4c73-bcef-9a40181fec4e	\N	["guest"]	pending	\N	\N
perf-test-33-9ff25085@example.com	Performance User 33	password	\N	\N	t	2025-08-29 21:59:41.246413+07	2025-08-29 21:59:41.246413+07	9ff25085-7c87-41b3-a474-a288f0b5ceec	\N	["guest"]	pending	\N	\N
perf-test-34-a1079754@example.com	Performance User 34	password	\N	\N	t	2025-08-29 21:59:41.246892+07	2025-08-29 21:59:41.246892+07	a1079754-8536-493a-9cfa-6e1a7ca4003b	\N	["guest"]	pending	\N	\N
perf-test-35-1aafaae9@example.com	Performance User 35	password	\N	\N	t	2025-08-29 21:59:41.247293+07	2025-08-29 21:59:41.247294+07	1aafaae9-2055-4e20-991c-c9197e1d8fad	\N	["guest"]	pending	\N	\N
perf-test-36-d20aaaee@example.com	Performance User 36	password	\N	\N	t	2025-08-29 21:59:41.247856+07	2025-08-29 21:59:41.247856+07	d20aaaee-99a3-48cf-ac5c-6e7fb701e04a	\N	["guest"]	pending	\N	\N
perf-test-37-73ca1d76@example.com	Performance User 37	password	\N	\N	t	2025-08-29 21:59:41.248457+07	2025-08-29 21:59:41.248457+07	73ca1d76-27bd-4236-a8ad-da8a2990e2b6	\N	["guest"]	pending	\N	\N
perf-test-38-92312861@example.com	Performance User 38	password	\N	\N	t	2025-08-29 21:59:41.249032+07	2025-08-29 21:59:41.249032+07	92312861-4cf8-4ac4-ae1b-0d2612511ac7	\N	["guest"]	pending	\N	\N
perf-test-39-8eb54c26@example.com	Performance User 39	password	\N	\N	t	2025-08-29 21:59:41.249561+07	2025-08-29 21:59:41.249561+07	8eb54c26-f432-437d-9cc9-40b3c61be4bd	\N	["guest"]	pending	\N	\N
perf-test-40-ca6ff910@example.com	Performance User 40	password	\N	\N	t	2025-08-29 21:59:41.25013+07	2025-08-29 21:59:41.25013+07	ca6ff910-7332-412a-933c-83d349e00fdd	\N	["guest"]	pending	\N	\N
perf-test-41-5bab5c33@example.com	Performance User 41	password	\N	\N	t	2025-08-29 21:59:41.250583+07	2025-08-29 21:59:41.250583+07	5bab5c33-1286-4fd7-8793-a2a5f70b7095	\N	["guest"]	pending	\N	\N
perf-test-42-671ad08d@example.com	Performance User 42	password	\N	\N	t	2025-08-29 21:59:41.251051+07	2025-08-29 21:59:41.251051+07	671ad08d-2e98-4333-8267-c50d3647da2e	\N	["guest"]	pending	\N	\N
perf-test-43-56b4e3e3@example.com	Performance User 43	password	\N	\N	t	2025-08-29 21:59:41.251448+07	2025-08-29 21:59:41.251449+07	56b4e3e3-3bb1-4acf-b742-7b6c31e2845c	\N	["guest"]	pending	\N	\N
perf-test-44-68e711a1@example.com	Performance User 44	password	\N	\N	t	2025-08-29 21:59:41.251891+07	2025-08-29 21:59:41.251891+07	68e711a1-7e79-4504-a0ee-c78ffc757364	\N	["guest"]	pending	\N	\N
perf-test-45-a80e1bb6@example.com	Performance User 45	password	\N	\N	t	2025-08-29 21:59:41.252366+07	2025-08-29 21:59:41.252366+07	a80e1bb6-2e05-4e2e-9b27-e4d81914d8c7	\N	["guest"]	pending	\N	\N
perf-test-46-5740eb31@example.com	Performance User 46	password	\N	\N	t	2025-08-29 21:59:41.253002+07	2025-08-29 21:59:41.253002+07	5740eb31-c72a-4d48-986e-0c45a5e8d0b6	\N	["guest"]	pending	\N	\N
perf-test-47-6b0dd04d@example.com	Performance User 47	password	\N	\N	t	2025-08-29 21:59:41.253517+07	2025-08-29 21:59:41.253517+07	6b0dd04d-562f-4180-b683-07304a6a7241	\N	["guest"]	pending	\N	\N
perf-test-48-ba102d2d@example.com	Performance User 48	password	\N	\N	t	2025-08-29 21:59:41.254028+07	2025-08-29 21:59:41.254028+07	ba102d2d-0bb1-4ae3-be45-b711213a19b4	\N	["guest"]	pending	\N	\N
perf-test-49-503e9374@example.com	Performance User 49	password	\N	\N	t	2025-08-29 21:59:41.254524+07	2025-08-29 21:59:41.254524+07	503e9374-f861-444b-a409-c70f7256ac06	\N	["guest"]	pending	\N	\N
user-5-5af82b20@example.com	User 5	hashedpassword	\N	\N	t	2025-08-29 22:02:00.85132+07	2025-08-29 22:02:00.85132+07	5af82b20-1e74-4bc0-bb00-997eba057d83	\N	["guest"]	pending	\N	\N
user-8-59fcd5c9@example.com	User 8	hashedpassword	\N	\N	t	2025-08-29 22:02:00.855983+07	2025-08-29 22:02:00.855983+07	59fcd5c9-520c-411c-8980-bc6a9cdc99c9	\N	["guest"]	pending	\N	\N
user-9-c02f85bb@example.com	User 9	hashedpassword	\N	\N	t	2025-08-29 22:02:00.856812+07	2025-08-29 22:02:00.856813+07	c02f85bb-f330-444b-ba87-7a3895656e2b	\N	["guest"]	pending	\N	\N
user-13-750a84b5@example.com	User 13	hashedpassword	\N	\N	t	2025-08-29 22:02:00.859847+07	2025-08-29 22:02:00.859847+07	750a84b5-3a3b-412a-affc-3579afc9b462	\N	["guest"]	pending	\N	\N
user-14-8a9f1d9c@example.com	User 14	hashedpassword	\N	\N	t	2025-08-29 22:02:00.860509+07	2025-08-29 22:02:00.860509+07	8a9f1d9c-b953-4fca-ada7-764fc97c262c	\N	["guest"]	pending	\N	\N
user-15-d046f9c1@example.com	User 15	hashedpassword	\N	\N	t	2025-08-29 22:02:00.861082+07	2025-08-29 22:02:00.861082+07	d046f9c1-8c61-44b4-b622-704b0bc5be6f	\N	["guest"]	pending	\N	\N
user-20-083fbc14@example.com	User 20	hashedpassword	\N	\N	t	2025-08-29 22:02:00.863412+07	2025-08-29 22:02:00.863412+07	083fbc14-a0c0-49ed-af11-e6be2560ded7	\N	["guest"]	pending	\N	\N
user-21-7083595d@example.com	User 21	hashedpassword	\N	\N	t	2025-08-29 22:02:00.864086+07	2025-08-29 22:02:00.864086+07	7083595d-8ace-4ee7-9526-435f7ded3a2a	\N	["guest"]	pending	\N	\N
user-22-eb5b7c3b@example.com	User 22	hashedpassword	\N	\N	t	2025-08-29 22:02:00.864807+07	2025-08-29 22:02:00.864808+07	eb5b7c3b-ae6c-4a7b-98e2-bdd0c743ca3c	\N	["guest"]	pending	\N	\N
user-23-948e1162@example.com	User 23	hashedpassword	\N	\N	t	2025-08-29 22:02:00.865504+07	2025-08-29 22:02:00.865504+07	948e1162-c2e5-497e-9723-4805f8510511	\N	["guest"]	pending	\N	\N
user-25-e76ce75b@example.com	User 25	hashedpassword	\N	\N	t	2025-08-29 22:02:00.866641+07	2025-08-29 22:02:00.866641+07	e76ce75b-18ce-4dc1-b905-0154aa5e9073	\N	["guest"]	pending	\N	\N
user-26-7cd0a950@example.com	User 26	hashedpassword	\N	\N	t	2025-08-29 22:02:00.867087+07	2025-08-29 22:02:00.867087+07	7cd0a950-683f-4b92-8574-5752f3b20b86	\N	["guest"]	pending	\N	\N
user-28-fcd66843@example.com	User 28	hashedpassword	\N	\N	t	2025-08-29 22:02:00.867937+07	2025-08-29 22:02:00.867937+07	fcd66843-fed7-49b9-a3b1-c0e9c7387524	\N	["guest"]	pending	\N	\N
user-31-08360760@example.com	User 31	hashedpassword	\N	\N	t	2025-08-29 22:02:00.869112+07	2025-08-29 22:02:00.869112+07	08360760-6838-4ddc-91ad-f121281b281c	\N	["guest"]	pending	\N	\N
user-48-f679e9f9@example.com	User 48	hashedpassword	\N	\N	t	2025-08-29 22:02:00.877365+07	2025-08-29 22:02:00.877365+07	f679e9f9-255e-40a3-80fa-f723684e4311	\N	["guest"]	pending	\N	\N
user-51-92d9ac90@example.com	User 51	hashedpassword	\N	\N	t	2025-08-29 22:02:00.878647+07	2025-08-29 22:02:00.878647+07	92d9ac90-0032-429b-ab1c-4de369ce5fe2	\N	["guest"]	pending	\N	\N
user-57-7021ae67@example.com	User 57	hashedpassword	\N	\N	t	2025-08-29 22:02:00.881794+07	2025-08-29 22:02:00.881795+07	7021ae67-903e-41d8-a808-36a5f65676a1	\N	["guest"]	pending	\N	\N
user-63-e75e4848@example.com	User 63	hashedpassword	\N	\N	t	2025-08-29 22:02:00.884836+07	2025-08-29 22:02:00.884836+07	e75e4848-bb75-47e8-a8bd-85c6e382f54f	\N	["guest"]	pending	\N	\N
user-65-1c821720@example.com	User 65	hashedpassword	\N	\N	t	2025-08-29 22:02:00.885561+07	2025-08-29 22:02:00.885561+07	1c821720-a6ea-44df-86e0-670a035a1d44	\N	["guest"]	pending	\N	\N
user-69-69a02a4f@example.com	User 69	hashedpassword	\N	\N	t	2025-08-29 22:02:00.887061+07	2025-08-29 22:02:00.887061+07	69a02a4f-333e-4988-9f5e-c5ecabd610c2	\N	["guest"]	pending	\N	\N
user-70-337bc03a@example.com	User 70	hashedpassword	\N	\N	t	2025-08-29 22:02:00.887611+07	2025-08-29 22:02:00.887611+07	337bc03a-e819-4fd6-ab00-e33e8db1ae95	\N	["guest"]	pending	\N	\N
user-71-562c1a45@example.com	User 71	hashedpassword	\N	\N	t	2025-08-29 22:02:00.888074+07	2025-08-29 22:02:00.888074+07	562c1a45-22bc-4a7f-b0cf-019e5b762927	\N	["guest"]	pending	\N	\N
user-75-315b4bd8@example.com	User 75	hashedpassword	\N	\N	t	2025-08-29 22:02:00.890045+07	2025-08-29 22:02:00.890045+07	315b4bd8-101b-455f-a87a-929695ec8129	\N	["guest"]	pending	\N	\N
user-80-4512c688@example.com	User 80	hashedpassword	\N	\N	t	2025-08-29 22:02:00.892327+07	2025-08-29 22:02:00.892328+07	4512c688-71f5-4c7d-b3ab-ccf2a8db4034	\N	["guest"]	pending	\N	\N
user-84-7d9ef741@example.com	User 84	hashedpassword	\N	\N	t	2025-08-29 22:02:00.893988+07	2025-08-29 22:02:00.893988+07	7d9ef741-99cd-41f6-a431-f27f7bab9d6c	\N	["guest"]	pending	\N	\N
user-95-3506edce@example.com	User 95	hashedpassword	\N	\N	t	2025-08-29 22:02:00.89946+07	2025-08-29 22:02:00.89946+07	3506edce-2c90-4cc9-852d-00e2b7041c8b	\N	["guest"]	pending	\N	\N
user-98-4ef6c174@example.com	User 98	hashedpassword	\N	\N	t	2025-08-29 22:02:00.90093+07	2025-08-29 22:02:00.90093+07	4ef6c174-7fc6-467d-8fb0-21019f2da643	\N	["guest"]	pending	\N	\N
concurrent-user-1-a07dc3be@example.com	Concurrent User 1	password	\N	\N	t	2025-08-29 22:02:01.174288+07	2025-08-29 22:02:01.174289+07	a07dc3be-f73c-45fc-8fd8-be21f853ecc7	\N	["guest"]	pending	\N	\N
perf-test-0-56f99ea0@example.com	Performance User 0	password	\N	\N	t	2025-08-29 22:02:01.343463+07	2025-08-29 22:02:01.343463+07	56f99ea0-5457-42a6-8dea-d5927cd288a4	\N	["guest"]	pending	\N	\N
perf-test-1-512a1199@example.com	Performance User 1	password	\N	\N	t	2025-08-29 22:02:01.344004+07	2025-08-29 22:02:01.344004+07	512a1199-34e1-464f-9197-f651a090a323	\N	["guest"]	pending	\N	\N
perf-test-2-3f843bc8@example.com	Performance User 2	password	\N	\N	t	2025-08-29 22:02:01.344372+07	2025-08-29 22:02:01.344372+07	3f843bc8-c519-480c-8201-ee5bc8ff94ca	\N	["guest"]	pending	\N	\N
perf-test-3-1e209263@example.com	Performance User 3	password	\N	\N	t	2025-08-29 22:02:01.344791+07	2025-08-29 22:02:01.344791+07	1e209263-671d-4ed1-9447-d3840b4c8fb2	\N	["guest"]	pending	\N	\N
perf-test-4-d5472e18@example.com	Performance User 4	password	\N	\N	t	2025-08-29 22:02:01.345169+07	2025-08-29 22:02:01.345169+07	d5472e18-29b4-4923-b6e9-0f8fff67b924	\N	["guest"]	pending	\N	\N
perf-test-5-420c3c9e@example.com	Performance User 5	password	\N	\N	t	2025-08-29 22:02:01.345583+07	2025-08-29 22:02:01.345583+07	420c3c9e-046c-4dd6-b678-0a952fcea916	\N	["guest"]	pending	\N	\N
perf-test-6-171de04d@example.com	Performance User 6	password	\N	\N	t	2025-08-29 22:02:01.34596+07	2025-08-29 22:02:01.34596+07	171de04d-2a4e-4c15-87a3-b65ee2437666	\N	["guest"]	pending	\N	\N
perf-test-7-a4e1162c@example.com	Performance User 7	password	\N	\N	t	2025-08-29 22:02:01.346354+07	2025-08-29 22:02:01.346354+07	a4e1162c-96be-4291-bd32-9f7b944dab6b	\N	["guest"]	pending	\N	\N
perf-test-8-4b3656f2@example.com	Performance User 8	password	\N	\N	t	2025-08-29 22:02:01.346788+07	2025-08-29 22:02:01.346788+07	4b3656f2-d638-4676-bb66-5e2cbc3b3d4c	\N	["guest"]	pending	\N	\N
perf-test-9-150a6e91@example.com	Performance User 9	password	\N	\N	t	2025-08-29 22:02:01.347972+07	2025-08-29 22:02:01.347972+07	150a6e91-b321-4688-bb6d-80b56059d6dc	\N	["guest"]	pending	\N	\N
perf-test-10-ddf64fe4@example.com	Performance User 10	password	\N	\N	t	2025-08-29 22:02:01.348669+07	2025-08-29 22:02:01.348669+07	ddf64fe4-8219-4d54-972a-46f44829bf0c	\N	["guest"]	pending	\N	\N
perf-test-11-cb0b4004@example.com	Performance User 11	password	\N	\N	t	2025-08-29 22:02:01.349284+07	2025-08-29 22:02:01.349284+07	cb0b4004-6f28-42bf-904d-689660907291	\N	["guest"]	pending	\N	\N
perf-test-12-8d50f04e@example.com	Performance User 12	password	\N	\N	t	2025-08-29 22:02:01.349858+07	2025-08-29 22:02:01.349858+07	8d50f04e-a189-4073-8e81-1999b3859a68	\N	["guest"]	pending	\N	\N
perf-test-13-64a5c938@example.com	Performance User 13	password	\N	\N	t	2025-08-29 22:02:01.350311+07	2025-08-29 22:02:01.350311+07	64a5c938-d093-473b-8782-c9cabfe1b537	\N	["guest"]	pending	\N	\N
perf-test-14-0b1bd43b@example.com	Performance User 14	password	\N	\N	t	2025-08-29 22:02:01.350809+07	2025-08-29 22:02:01.350809+07	0b1bd43b-d8ef-40ce-a3ec-f93bf2803f65	\N	["guest"]	pending	\N	\N
perf-test-15-7e2eb105@example.com	Performance User 15	password	\N	\N	t	2025-08-29 22:02:01.351202+07	2025-08-29 22:02:01.351202+07	7e2eb105-7772-4b4d-9970-bf713b2e3576	\N	["guest"]	pending	\N	\N
perf-test-16-4b2266e5@example.com	Performance User 16	password	\N	\N	t	2025-08-29 22:02:01.351568+07	2025-08-29 22:02:01.351568+07	4b2266e5-f486-4873-8ef6-26470fbdfb7a	\N	["guest"]	pending	\N	\N
perf-test-17-15ba0871@example.com	Performance User 17	password	\N	\N	t	2025-08-29 22:02:01.351921+07	2025-08-29 22:02:01.351921+07	15ba0871-3d0e-4d35-944e-9fe336ec8252	\N	["guest"]	pending	\N	\N
perf-test-18-8ef9623d@example.com	Performance User 18	password	\N	\N	t	2025-08-29 22:02:01.352292+07	2025-08-29 22:02:01.352292+07	8ef9623d-a163-4fd2-a2cf-5f7d8ca3fd87	\N	["guest"]	pending	\N	\N
perf-test-19-f552bd5a@example.com	Performance User 19	password	\N	\N	t	2025-08-29 22:02:01.35271+07	2025-08-29 22:02:01.35271+07	f552bd5a-1ce4-42c2-a084-5319d7ed31b1	\N	["guest"]	pending	\N	\N
perf-test-20-d0f325ce@example.com	Performance User 20	password	\N	\N	t	2025-08-29 22:02:01.353087+07	2025-08-29 22:02:01.353087+07	d0f325ce-b967-4889-b750-a88e60e2399e	\N	["guest"]	pending	\N	\N
perf-test-21-4a29abf1@example.com	Performance User 21	password	\N	\N	t	2025-08-29 22:02:01.353436+07	2025-08-29 22:02:01.353436+07	4a29abf1-cd25-4536-9ce0-b1bc7e5abb64	\N	["guest"]	pending	\N	\N
perf-test-22-4c3056a2@example.com	Performance User 22	password	\N	\N	t	2025-08-29 22:02:01.353907+07	2025-08-29 22:02:01.353908+07	4c3056a2-4c1f-4d2d-a80f-f8d6bb4612be	\N	["guest"]	pending	\N	\N
perf-test-23-47830248@example.com	Performance User 23	password	\N	\N	t	2025-08-29 22:02:01.354366+07	2025-08-29 22:02:01.354366+07	47830248-602a-49db-a330-9d4632a523cb	\N	["guest"]	pending	\N	\N
perf-test-24-1eb02fc2@example.com	Performance User 24	password	\N	\N	t	2025-08-29 22:02:01.355047+07	2025-08-29 22:02:01.355048+07	1eb02fc2-413b-42b0-9055-abc5b3f63a3b	\N	["guest"]	pending	\N	\N
perf-test-25-cc54f4f7@example.com	Performance User 25	password	\N	\N	t	2025-08-29 22:02:01.355705+07	2025-08-29 22:02:01.355705+07	cc54f4f7-5b52-4bce-b0b8-c5735bf2fa16	\N	["guest"]	pending	\N	\N
perf-test-26-1633cc19@example.com	Performance User 26	password	\N	\N	t	2025-08-29 22:02:01.356396+07	2025-08-29 22:02:01.356396+07	1633cc19-f1f7-4e6e-ba82-34a5b63d7184	\N	["guest"]	pending	\N	\N
perf-test-27-94d2fc8a@example.com	Performance User 27	password	\N	\N	t	2025-08-29 22:02:01.356933+07	2025-08-29 22:02:01.356934+07	94d2fc8a-213b-486e-9537-7a20379885b1	\N	["guest"]	pending	\N	\N
perf-test-28-a8e07586@example.com	Performance User 28	password	\N	\N	t	2025-08-29 22:02:01.357423+07	2025-08-29 22:02:01.357423+07	a8e07586-4c4a-4894-9ee7-7b74f6cb5a59	\N	["guest"]	pending	\N	\N
perf-test-29-8f6bf2e2@example.com	Performance User 29	password	\N	\N	t	2025-08-29 22:02:01.357879+07	2025-08-29 22:02:01.357879+07	8f6bf2e2-b5dd-4bf0-8d25-d226116b5936	\N	["guest"]	pending	\N	\N
perf-test-30-80b12d58@example.com	Performance User 30	password	\N	\N	t	2025-08-29 22:02:01.358273+07	2025-08-29 22:02:01.358273+07	80b12d58-9100-49a3-8746-61ccf52d016d	\N	["guest"]	pending	\N	\N
perf-test-31-118dbd5f@example.com	Performance User 31	password	\N	\N	t	2025-08-29 22:02:01.358693+07	2025-08-29 22:02:01.358693+07	118dbd5f-f469-445d-89f6-a64eb530a54a	\N	["guest"]	pending	\N	\N
perf-test-32-8ac54c2c@example.com	Performance User 32	password	\N	\N	t	2025-08-29 22:02:01.359066+07	2025-08-29 22:02:01.359066+07	8ac54c2c-25f6-4f64-8531-288c5aefc1d8	\N	["guest"]	pending	\N	\N
perf-test-33-f47ffeed@example.com	Performance User 33	password	\N	\N	t	2025-08-29 22:02:01.359469+07	2025-08-29 22:02:01.35947+07	f47ffeed-f739-47b7-a2d2-6f5fac7ddedd	\N	["guest"]	pending	\N	\N
perf-test-34-5233e5c5@example.com	Performance User 34	password	\N	\N	t	2025-08-29 22:02:01.359835+07	2025-08-29 22:02:01.359835+07	5233e5c5-fa50-4e2c-b643-265ffe174a03	\N	["guest"]	pending	\N	\N
perf-test-35-e7b1fe88@example.com	Performance User 35	password	\N	\N	t	2025-08-29 22:02:01.360228+07	2025-08-29 22:02:01.360228+07	e7b1fe88-930a-4cb5-a5cb-ceffac52ef8c	\N	["guest"]	pending	\N	\N
perf-test-36-b25a6372@example.com	Performance User 36	password	\N	\N	t	2025-08-29 22:02:01.360555+07	2025-08-29 22:02:01.360555+07	b25a6372-875a-448e-bb3e-e64293a7b484	\N	["guest"]	pending	\N	\N
perf-test-37-89a87531@example.com	Performance User 37	password	\N	\N	t	2025-08-29 22:02:01.360942+07	2025-08-29 22:02:01.360942+07	89a87531-5bab-42e9-91aa-05924a564f8e	\N	["guest"]	pending	\N	\N
perf-test-38-064199d3@example.com	Performance User 38	password	\N	\N	t	2025-08-29 22:02:01.361318+07	2025-08-29 22:02:01.361318+07	064199d3-cc50-457d-9f3e-2093da943628	\N	["guest"]	pending	\N	\N
perf-test-39-7ffe3a9e@example.com	Performance User 39	password	\N	\N	t	2025-08-29 22:02:01.361712+07	2025-08-29 22:02:01.361712+07	7ffe3a9e-a3ea-4383-bcdc-354000cb5bcc	\N	["guest"]	pending	\N	\N
perf-test-40-d7a825f1@example.com	Performance User 40	password	\N	\N	t	2025-08-29 22:02:01.362092+07	2025-08-29 22:02:01.362092+07	d7a825f1-d6eb-4f37-a0e8-59e513cbd3fb	\N	["guest"]	pending	\N	\N
perf-test-41-35a51de0@example.com	Performance User 41	password	\N	\N	t	2025-08-29 22:02:01.362456+07	2025-08-29 22:02:01.362456+07	35a51de0-4ad1-421d-91e5-295a6176c95b	\N	["guest"]	pending	\N	\N
perf-test-42-ca3b4758@example.com	Performance User 42	password	\N	\N	t	2025-08-29 22:02:01.362837+07	2025-08-29 22:02:01.362837+07	ca3b4758-08c8-46dc-9518-dd0214675e21	\N	["guest"]	pending	\N	\N
perf-test-43-afc95dec@example.com	Performance User 43	password	\N	\N	t	2025-08-29 22:02:01.363228+07	2025-08-29 22:02:01.363228+07	afc95dec-99c3-4592-91bc-738308e28242	\N	["guest"]	pending	\N	\N
perf-test-44-117a398b@example.com	Performance User 44	password	\N	\N	t	2025-08-29 22:02:01.363637+07	2025-08-29 22:02:01.363637+07	117a398b-51f4-42a3-b4f8-39c636ad7800	\N	["guest"]	pending	\N	\N
perf-test-45-b2d6d9f6@example.com	Performance User 45	password	\N	\N	t	2025-08-29 22:02:01.364143+07	2025-08-29 22:02:01.364143+07	b2d6d9f6-813c-4300-a473-2a0d4b71c354	\N	["guest"]	pending	\N	\N
perf-test-46-7ea9623a@example.com	Performance User 46	password	\N	\N	t	2025-08-29 22:02:01.364664+07	2025-08-29 22:02:01.364664+07	7ea9623a-f739-413b-bc50-a1cde665c39c	\N	["guest"]	pending	\N	\N
perf-test-47-500361a4@example.com	Performance User 47	password	\N	\N	t	2025-08-29 22:02:01.3651+07	2025-08-29 22:02:01.3651+07	500361a4-c54b-42eb-9e71-82224d981ebc	\N	["guest"]	pending	\N	\N
perf-test-48-10a63dfd@example.com	Performance User 48	password	\N	\N	t	2025-08-29 22:02:01.365743+07	2025-08-29 22:02:01.365743+07	10a63dfd-0bc2-452b-8681-56f1a1e544cf	\N	["guest"]	pending	\N	\N
perf-test-49-5361afa4@example.com	Performance User 49	password	\N	\N	t	2025-08-29 22:02:01.366292+07	2025-08-29 22:02:01.366292+07	5361afa4-fc46-4199-8460-ec4806dabe88	\N	["guest"]	pending	\N	\N
ryan.kharisma@gmail.com	Ryan	$2a$10$nyZXe/QTaROouMTkr5J3/eFQNHuCsC3xel3GnGG1v08x45meE2hjq	08113999574	Pasteur	t	2025-08-31 11:06:25.417015+07	2025-08-31 11:06:25.417015+07	783c6248-791b-44b3-b780-45ee7946d7b9	\N	["member"]	pending	\N	\N
testuser1757092345614@example.com	Test User	$2a$10$EzGrIIy5sxfTOj2f3f..NOt8MPGz6N6xKV1Ek4ZrKofwd94Irob1O	+1234567890	Test Address	t	2025-09-06 00:12:25.926775+07	2025-09-06 00:12:25.926775+07	94beca0b-23d5-4683-a40e-3edfc33f22ca	\N	["member"]	pending	\N	\N
siti.nurhaliza@example.com	Siti Nurhaliza	$2a$10$KrUPhmSrp8c1XiGLjCSrjuDOwkOgSCPd1cmd1nIBlQQJK7.52fcJi	+62-813-9876-5432	Jl. Merdeka No. 789, Bandung	t	2025-09-19 19:45:52.394079+07	2025-09-19 19:45:52.394079+07	ee7168c8-2c59-40a0-8017-06bf20617045	550e8400-e29b-41d4-a716-446655440002	["investor"]	pending	\N	\N
frontendtest@example.com	Frontend Test User	$2a$10$B0cf6wTAxOKjX0DCvTmie.TMuTZld9Ylmc0iYW3WHfJ8B5J9uGMYm	+62-813-2222-3333	Jl. Frontend No. 789, Bandung	t	2025-09-19 21:29:01.290626+07	2025-09-19 21:29:01.290626+07	c8a866f3-9826-463a-ad3e-c8647883c0ca	550e8400-e29b-41d4-a716-446655440002	["business_owner"]	pending	\N	\N
test-reg-fix@example.com	Test Registration Fix	$2a$10$pdRR4AMjfVHIsN8xynj/5OJpOj6FxxtoG30KVdkP1.PgHTV5NwIaO	+62-814-3333-4444	Jl. Test Registration No. 999, Jakarta	t	2025-09-19 21:37:27.011175+07	2025-09-19 21:37:27.011175+07	017568a0-d8ba-4a5c-b4fe-1f068ad98942	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N	\N
demo-business@example.com	Demo Business Owner	$2a$10$T/HCnsk3/u7giFKS/DYXguvUnaPpJ/72K1cdQTt1pzGI8eV8VFHy2	+62-815-4444-5555	Jl. Demo Business No. 123, Jakarta	t	2025-09-19 21:43:06.344121+07	2025-09-19 21:43:06.344121+07	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	550e8400-e29b-41d4-a716-446655440001	["business_owner", "investor"]	pending	\N	\N
debugowner@hajifund.com	Debug Owner	$2a$10$m/IBFm5.VZtRgnpWNJQkJOQ6ZJ/x0vmo3lU1NMPn3JOGnaUqYSoIi	+62-800-DEBUG	Jl. Debug Owner No. 1	t	2025-09-20 10:42:14.208896+07	2025-09-20 10:42:14.208896+07	8983f8ee-4c06-411e-b86c-9dfbc8af138e	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
debugowner2@hajifund.com	Debug Owner 2	$2a$10$xFIZDas2hBuG7ZH2U5DSXOnVzNFbF6zSKDB3k3iK.VuvrYxMosbgK	+62-800-DEBUG2	Jl. Debug Owner 2 No. 1	t	2025-09-20 10:42:58.561338+07	2025-09-20 10:42:58.561338+07	5e5a3b0d-5433-40cc-a359-70ba45c891cd	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
debugowner6@hajifund.com	Debug Owner 6	$2a$10$JADrOl1ws2xqcUHc0ttalOiixm67DjFuaO4BpcKexjIMoozI2rU.W	+62-800-DEBUG6	Jl. Debug Owner 6 No. 1	t	2025-09-20 10:45:56.66711+07	2025-09-20 10:45:56.66711+07	20bfda9f-89c6-419c-8ce1-b88959a1cec8	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
freshowner@hajifund.com	Fresh Owner	$2a$10$WbDTngStSMRGGXCpmaTxVOG7bwnCDLOCcK428pVbY2MxVtpd2PvJC	+62-800-FRESH	Jl. Fresh Owner No. 1	t	2025-09-20 10:54:07.472529+07	2025-09-20 10:54:07.472529+07	26bae18f-26d5-472a-87fb-001111d3b7cf	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
testadmin@hajifund.com	Test Admin	$2a$10$kopdZvPp.hfH4GuOr0BnheQatMbedflWvy03IQiWUuaaubm2kNb5e	081234567890	Test Address	t	2025-09-20 12:35:15.4556+07	2025-09-20 12:35:15.4556+07	cb7e4ebf-b2c2-45e2-a083-c388640f3b4a	\N	["admin"]	pending	\N	\N
john1758347974@example.com	John Doe	$2a$10$16DOu4CK.nRucAhWCs4reeybL2iCl/KULTSsYp9XnVTWQQ8/gtO42	08123456789	Jakarta, Indonesia	t	2025-09-20 12:59:34.748347+07	2025-09-20 12:59:34.748347+07	6f8a3d8b-2dd0-40e1-9563-934146ac7e3a	\N	["business_owner"]	pending	\N	\N
ryan.kharisma@outlook.com	Ryan Kharisma	$2a$10$nzkiQ4tdFXRuLv0HBXA4G.zbUfANNYjCGB6Jgx37sJFJUVMPSncxm	+628131313131	Jl. Patin Raya No.17 Rumbai Pekanbaru	t	2025-09-20 13:32:21.681773+07	2025-09-20 13:32:21.681773+07	ffcee1b1-019d-4105-8be8-790e0959074e	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N	\N
admin1758356219@test.com	Test Admin	$2a$10$nSJ0Yfi9KhHXdmqDiIeeCeN6/CzQzgQeKy6PWL.VlCDLVgDEh00l6	08123456789	Admin Address	t	2025-09-20 15:16:59.81034+07	2025-09-20 15:16:59.81034+07	1b9cb87d-b507-41cc-a935-e1c0b1e4732b	\N	["admin"]	pending	\N	\N
debugadmin1758356281@test.com	Debug Admin	$2a$10$djpRk0xOvKEunLk3ibrUku33J/gGjsWoTCoTKd9IlHuWs7Xrp3So2	08123456789	Admin Address	t	2025-09-20 15:18:01.156884+07	2025-09-20 15:18:01.156884+07	ff5c6ab8-27c5-4e0a-8abc-4cbcb033ec26	\N	["admin"]	pending	\N	\N
admin@hajifund.com	Demo Admin	$2a$10$2XRDKeBf3XBqM3vPav662Op9tAyAQAZeA9JIDQldGIW6n.FR1E8AG	+6281234567893	Jl. Demo Admin No. 101, Jakarta	t	2025-10-05 09:59:42.47388+07	2025-10-05 09:59:42.47388+07	123e4567-e89b-12d3-a456-426614174004	550e8400-e29b-41d4-a716-446655440001	["member", "admin"]	pending	\N	\N
astahiam@gmail.com	ryan test user kharisma	$2a$10$mblP1Z800B0jDQYqF0phyu6uyBgnXzeQKQhDliwNgqg1EmI5Knk7y	+6281933999574	Jalan Jalan yuuk	t	2025-10-08 07:51:20.675075+07	2025-10-09 02:23:15.049186+07	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N	\N
abcde@gmail.com	abce abcde	$2a$10$98UmR15r.6nSH34FQAN2JuVkN9RMzb7UyYFcgeNkwUL1r/k1hK3KO	081110100101	ab	t	2025-10-11 14:22:21.39717+07	2025-10-11 14:22:21.39717+07	4f4f880b-0243-4309-ad14-2b9e2fa15a2e	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N	\N
alip@gmail.com	alip	$2a$10$dCBm2kGq3sca0YdkRp41be/KuBzYX7zZd7fNFN8qI.As034Rjq6.m	0811234	aleef residence jalan babakan radio no 2	t	2025-10-11 22:33:18.637567+07	2025-10-11 22:33:18.637567+07	04c8e408-6372-44c7-b299-294497db6f5b	550e8400-e29b-41d4-a716-446655440001	["investor"]	pending	\N	\N
user1212@gmail.com	test user1212	$2a$10$V8NZZsWaZdUAWBN6A53JxurIEj1A1MwAZ06e4t585IjnXdiGOhym6	+628113333333	test alamat 1212	t	2025-11-10 12:06:06.082511+07	2025-11-10 12:06:06.082511+07	7373e7bc-845f-427f-b5fa-ba1d1bb271ad	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner", "investor", "business_owner"]	pending	\N	/uploads/documents/register/payment_proof_20251110_120605_6e158f2e.jpg


ALTER TABLE public.users ENABLE TRIGGER ALL;


ALTER TABLE public.projects DISABLE TRIGGER ALL;

COPY public.projects (id, title, description, business_id, funding_goal, minimum_funding, current_funding, funding_deadline, profit_sharing_ratio, project_type, status, milestones, documents, created_at, updated_at, project_image_1, project_image_2, project_image_3, min_investment, risk_level, investment_period, expected_return, start_date, end_date, target_amount, raised_amount, category, owner_id, cooperative_id, approved_by, approved_at, approval_status, rejected_by, rejected_at, rejection_reason, reviewer_comments, sharia_compliant) FROM stdin;
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa	Toko Online Fashion Muslim	Membangun platform e-commerce khusus fashion muslim dengan sistem dropship	09176669-b045-4e33-8ae2-8febe34a16cf	85000000.00	\N	25000000.00	\N	{"business": 30, "investor": 70}	startup	active	[]	{}	2025-10-09 00:32:29.126762+07	2025-10-09 00:32:29.126762+07	\N	\N	\N	500000.00	Medium	18	20-25% per tahun	\N	\N	85000000.00	25000000.00	E-Commerce	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	\N	\N	approved	\N	\N	\N	\N	f
bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb	Katering Harian Sehat	Layanan katering makanan sehat untuk karyawan perkantoran area Jakarta	09176669-b045-4e33-8ae2-8febe34a16cf	60000000.00	\N	0.00	\N	{"business": 30, "investor": 70}	expansion	draft	[]	{}	2025-10-09 00:32:29.126762+07	2025-10-09 00:32:29.126762+07	\N	\N	\N	750000.00	Low	12	15-18% per tahun	\N	\N	60000000.00	0.00	Food & Beverage	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	\N	\N	pending	\N	\N	\N	\N	f
cccccccc-cccc-cccc-cccc-cccccccccccc	Laundry Kiloan Premium	Ekspansi bisnis laundry dengan teknologi modern dan pickup service	09176669-b045-4e33-8ae2-8febe34a16cf	45000000.00	\N	15000000.00	\N	{"business": 30, "investor": 70}	expansion	active	[]	{}	2025-10-09 00:32:29.126762+07	2025-10-09 00:32:29.126762+07	\N	\N	\N	300000.00	Low	24	12-15% per tahun	\N	\N	45000000.00	15000000.00	Services	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	\N	\N	approved	\N	\N	\N	\N	f
163655e7-4f27-4978-a93a-1b26c97cc540	toko baru sembako	baru baru ini dibutuhkan cabang baru	1e96d0f6-e8fa-4535-8e93-26f129006672	\N	\N	0.00	\N	{"business": 30, "investor": 70}	expansion	draft	[]	{}	2025-10-17 10:14:22.513355+07	2025-10-17 10:14:22.513355+07	\N	\N	\N	100000.00	Low	12	15	\N	\N	50000000.00	0.00	\N	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	00000000-0000-0000-0000-000000000000	\N	\N	pending	\N	\N	\N	\N	f
78d0c2e9-3d56-4af9-bf24-9b496c4dc465	ekspani toko baru	cabang baru	a30351c3-3632-4f9a-9799-40d23a4b25ec	\N	\N	0.00	\N	{"business": 30, "investor": 70}	expansion	approved	[]	{}	2025-10-25 16:03:36.258629+07	2025-10-25 16:05:04.116757+07	\N	\N	\N	1000000.00	High	18	10	\N	\N	2000000000.00	0.00	\N	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	00000000-0000-0000-0000-000000000000	123e4567-e89b-12d3-a456-426614174004	2025-10-25 16:05:04.116411+07	approved	\N	\N	\N		f


ALTER TABLE public.projects ENABLE TRIGGER ALL;


ALTER TABLE public.investments DISABLE TRIGGER ALL;

COPY public.investments (id, project_id, investor_id, amount, investment_date, profit_sharing_percentage, status, transaction_ref, created_at, updated_at) FROM stdin;


ALTER TABLE public.investments ENABLE TRIGGER ALL;


ALTER TABLE public.profit_distributions DISABLE TRIGGER ALL;

COPY public.profit_distributions (id, project_id, business_profit, distribution_date, total_distributed, status, created_at, updated_at) FROM stdin;


ALTER TABLE public.profit_distributions ENABLE TRIGGER ALL;


ALTER TABLE public.investment_returns DISABLE TRIGGER ALL;

COPY public.investment_returns (id, investment_id, distribution_id, return_amount, return_percentage, payment_date, status, transaction_ref, created_at, updated_at) FROM stdin;


ALTER TABLE public.investment_returns ENABLE TRIGGER ALL;









-- ============================================
-- VERIFICATION
-- ============================================
SELECT 'Database comfunds01 restored successfully!' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public';
