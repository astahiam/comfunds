-- ============================================
-- STANDALONE RESTORE SCRIPT FOR comfunds03
-- ============================================
-- This is a COMPLETELY SELF-CONTAINED script
-- Usage: psql -U postgres -d postgres -f comfunds03_standalone_restore.sql
-- Or: docker exec -i container_name psql -U postgres -d postgres < comfunds03_standalone_restore.sql
-- 
-- This file contains EVERYTHING needed to restore comfunds03:
-- 1. Database creation
-- 2. Schema migrations (handles missing columns, indexes, etc.)
-- 3. All data
-- ============================================

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE comfunds03'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'comfunds03')\gexec

-- Connect to the database
\c comfunds03

-- Schema Migration Script for comfunds03
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
-- IMPORT DATA FOR comfunds03
-- ============================================






ALTER TABLE public.audit_logs DISABLE TRIGGER ALL;

COPY public.audit_logs (id, entity_type, entity_id, operation, user_id, ip_address, user_agent, changes, old_values, new_values, reason, status, error_msg, created_at) FROM stdin;
8211b5d0-a2b2-4821-9bbb-50b03be6a08f	user	6f2e7758-cc9d-4bb3-9d49-85a315a8e96e	UPDATE	132672e6-0a0a-421e-a668-57be5923c0df	127.0.0.1	curl/8.1.2	{"name": "User", "phone": "", "roles": ["business_owner"], "address": "", "user_profile_image": null}	{"id": "6f2e7758-cc9d-4bb3-9d49-85a315a8e96e", "name": "Arkan Muhammad Rahmat", "email": "rahmatarkan475@gmail.com", "phone": "081214548513", "roles": ["member"], "address": "Majalengka", "is_active": true, "created_at": "2025-09-07T16:34:48.84446+07:00", "kyc_status": "pending", "updated_at": "2025-09-07T16:34:48.84446+07:00", "cooperative_id": null, "user_profile_image": null}	{"id": "6f2e7758-cc9d-4bb3-9d49-85a315a8e96e", "name": "User", "email": "rahmatarkan475@gmail.com", "phone": "081214548513", "roles": ["business_owner"], "address": "Majalengka", "is_active": true, "created_at": "2025-09-07T16:34:48.84446+07:00", "kyc_status": "pending", "updated_at": "2025-09-07T16:56:19.590435+07:00", "cooperative_id": null, "user_profile_image": null}		SUCCESS		2025-09-07 16:56:19.6878+07


ALTER TABLE public.audit_logs ENABLE TRIGGER ALL;


ALTER TABLE public.businesses DISABLE TRIGGER ALL;

COPY public.businesses (id, name, business_type, description, owner_id, cooperative_id, registration_documents, approval_status, is_active, created_at, updated_at, business_image, registration_number, tax_id, legal_structure, industry, sector, address, phone, email, website, established_date, employee_count, annual_revenue, currency, bank_account, business_license, documents, status, approved_by, approved_at, rejection_reason, metadata, performance_metrics, compliance_status) FROM stdin;
58c30113-fedb-4027-a463-898b3f6defff	Test Business 1758353974	retail	Backend test business	5a2b5efd-cd6f-44e0-9b44-6c17e1e8601e	550e8400-e29b-41d4-a716-446655440001	{}	pending	t	2025-09-20 14:39:34.518412+07	2025-09-20 14:39:34.518412+07	\N	TEST-1758353974		PT	Retail		Test Address	08123456789	test1758353974@test.com		2023-01-01	0	0.00	IDR	1234567890		null	draft	\N	\N	\N	null	null	null
e0e92688-3d2f-47dc-add8-3e20a7a91e07	Perusahaan Pertanian Sawit	agriculture	Kebun untuk pengelolaan kelapa sawit	ffcee1b1-019d-4105-8be8-790e0959074e	550e8400-e29b-41d4-a716-446655440001	{}	pending	t	2025-09-20 16:12:18.311665+07	2025-09-20 16:12:18.311665+07	\N	0101-PT-SAWIT-0980947		PT	Agrobisnis		Jl. Patin Raya No.15 Rumbai Pekanbaru	+628131313131	ryan.kharisma@outlook.com		2025-09-20	120	10101010000.00	IDR	2355563218	093-PT00284-CAFE093	[]	draft	\N	\N	\N	null	null	null
000bcafc-cb20-4217-a223-a5c01ab62e0e	No FK Test Business	retail	Testing without foreign key constraints	6f8a3d8b-2dd0-40e1-9563-934146ac7e3a	550e8400-e29b-41d4-a716-446655440001	{}	rejected	t	2025-09-20 14:36:40.314081+07	2025-10-05 10:08:19.043544+07	\N	NOFK-1758353800		PT	Retail		No FK Test Address	08123456789	nofk@test.com		2023-01-01	0	0.00	IDR	7777777777		null	draft	\N	\N	\N	null	null	null
09176669-b045-4e33-8ae2-8febe34a16cf	Restoran ikan Lele	retail	jualan makanan buat malem malem pecel lele enak nih	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-08 09:12:11.778694+07	2025-10-08 09:13:32.289657+07	\N	01234-UD-ikan-lele		UD	FnB		jalan lele no.20 Jakarta	081110100101	astahiam@gmail.com		2025-10-08	10	10000.00	IDR	10987549983		[]	draft	\N	\N	\N	null	null	null
6b128527-e764-4dff-ab70-711c4b8a25d4	Restoran Ayam Bakar	retail	Jualan ayam bakar	7a5327fe-7ac2-45ff-8e9f-3a6a9f006f71	550e8400-e29b-41d4-a716-446655440001	{}	approved	t	2025-10-08 21:39:12.549634+07	2025-10-08 21:40:33.025528+07	\N	01234-UD-AYAM-BKR		UD	FnB		Jalan Ayam No.1	081110100101	tesCoba@hajifund.com		2025-10-07	11	10000000.00	IDR	10987549983		[]	draft	\N	\N	\N	null	null	null


ALTER TABLE public.businesses ENABLE TRIGGER ALL;


ALTER TABLE public.cooperatives DISABLE TRIGGER ALL;

COPY public.cooperatives (id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at, cooperative_image) FROM stdin;
39ab21a4-147f-4679-bc66-b98b7b5c1828	Cooperative 3	COOP-2024-003-0	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-22 16:55:09.114085+07	2025-08-22 16:55:09.114085+07	\N
379645c3-4087-44b5-9d2a-7aa15c425a83	Cooperative 7	COOP-2024-007-6000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-22 16:55:09.118989+07	2025-08-22 16:55:09.118989+07	\N
3336f653-766c-4690-9e94-23fb6747b5ba	Cooperative 11	COOP-2024-011-8000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-22 16:55:09.121381+07	2025-08-22 16:55:09.121381+07	\N
d71cfaaf-461e-46ed-9462-bc9291cc7f97	Cooperative 15	COOP-2024-015-5000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-22 16:55:09.124719+07	2025-08-22 16:55:09.124719+07	\N
5f31647a-3108-4943-bcc8-34a509f6850e	Cooperative 19	COOP-2024-019-3000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-22 16:55:09.127205+07	2025-08-22 16:55:09.127206+07	\N
96aabbcb-f364-422d-a31b-2c7c315938f7	Cooperative 3	COOP-2024-003-5000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-22 16:55:46.027448+07	2025-08-22 16:55:46.027448+07	\N
8a48e55c-fcd0-4730-b86e-052b5671c2b2	Cooperative 3	COOP-2024-003-1755856577351649000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-22 16:56:17.351651+07	2025-08-22 16:56:17.351651+07	\N
b9362f83-dad3-4350-8b81-eabb3f29e33a	Cooperative 7	COOP-2024-007-1755856577356861000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-22 16:56:17.356868+07	2025-08-22 16:56:17.356868+07	\N
deaedcd3-9a50-4695-986e-0c1d8577079f	Cooperative 11	COOP-2024-011-1755856577360403000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-22 16:56:17.360406+07	2025-08-22 16:56:17.360406+07	\N
8e7dca98-166c-426c-aa99-1ec936e16a5d	Cooperative 15	COOP-2024-015-1755856577363747000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-22 16:56:17.363749+07	2025-08-22 16:56:17.36375+07	\N
2185d0cd-3e6c-440d-b298-1ca7af191b3c	Cooperative 19	COOP-2024-019-1755856577365880000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-22 16:56:17.365882+07	2025-08-22 16:56:17.365882+07	\N
2689d8fb-0b54-47fb-9c52-8ed97f2bffdf	Cooperative 3	COOP-2024-003-1755858945246991000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-22 17:35:45.246993+07	2025-08-22 17:35:45.246993+07	\N
2232792d-740b-48ca-8c90-49b3c400145b	Cooperative 7	COOP-2024-007-1755858945249498000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-22 17:35:45.2495+07	2025-08-22 17:35:45.2495+07	\N
2ff12d77-a0f6-4eed-a094-c8342ab1a501	Cooperative 11	COOP-2024-011-1755858945250914000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-22 17:35:45.250916+07	2025-08-22 17:35:45.250916+07	\N
12b09369-9465-40cc-b27d-f68976ad5c9a	Cooperative 15	COOP-2024-015-1755858945252247000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-22 17:35:45.252248+07	2025-08-22 17:35:45.252248+07	\N
18da93bb-f8eb-4333-b259-0a8edbb73583	Cooperative 19	COOP-2024-019-1755858945254080000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-22 17:35:45.254082+07	2025-08-22 17:35:45.254083+07	\N
a0fe794f-5804-4080-a92b-4e826c0cb474	Cooperative 3	COOP-2024-003-1756473775215334000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-29 20:22:55.215336+07	2025-08-29 20:22:55.215336+07	\N
d3958c55-1462-444b-9e8f-51abf4b9cb82	Cooperative 7	COOP-2024-007-1756473775218389000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-29 20:22:55.218391+07	2025-08-29 20:22:55.218391+07	\N
8a3a3b45-549b-44ad-91b8-8f4037e4cabb	Cooperative 11	COOP-2024-011-1756473775221083000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-29 20:22:55.221085+07	2025-08-29 20:22:55.221085+07	\N
9b48a053-4ebd-47fc-bb02-204574afdec9	Cooperative 15	COOP-2024-015-1756473775222992000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-29 20:22:55.22301+07	2025-08-29 20:22:55.22301+07	\N
880d8e2e-06a1-4b64-acc7-c58841320cd2	Cooperative 19	COOP-2024-019-1756473775224569000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-29 20:22:55.224571+07	2025-08-29 20:22:55.224571+07	\N
bbeaad05-e450-4e4d-bdec-f1eca6e9cc3c	Cooperative 3	COOP-2024-003-1756475953205978000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-29 20:59:13.205984+07	2025-08-29 20:59:13.205984+07	\N
79a8729f-7fa5-4e12-8568-86fe52a18e1b	Cooperative 7	COOP-2024-007-1756475953211287000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-29 20:59:13.21129+07	2025-08-29 20:59:13.21129+07	\N
9e13aa13-b43e-41eb-9be9-af5f4dd7ecb3	Cooperative 11	COOP-2024-011-1756475953213984000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-29 20:59:13.213986+07	2025-08-29 20:59:13.213986+07	\N
47c9da67-db40-4328-b997-0715289d3bda	Cooperative 15	COOP-2024-015-1756475953215730000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-29 20:59:13.215732+07	2025-08-29 20:59:13.215732+07	\N
6dd7395c-eb14-44d8-9feb-41b95d8b2578	Cooperative 19	COOP-2024-019-1756475953217182000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-29 20:59:13.217184+07	2025-08-29 20:59:13.217184+07	\N
f7051854-a945-4240-ab2b-90636827489c	Cooperative 3	COOP-2024-003-1756479580177070000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-29 21:59:40.177074+07	2025-08-29 21:59:40.177074+07	\N
49621733-f66c-41b2-a242-193d3a1e80d9	Cooperative 7	COOP-2024-007-1756479580194277000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-29 21:59:40.194282+07	2025-08-29 21:59:40.194282+07	\N
e5378f48-b7ed-4e60-9487-fefff4ef4e20	Cooperative 11	COOP-2024-011-1756479580205958000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-29 21:59:40.205961+07	2025-08-29 21:59:40.205962+07	\N
56211ef1-3f6e-4e42-b507-189b9f2aaa25	Cooperative 15	COOP-2024-015-1756479580249677000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-29 21:59:40.249682+07	2025-08-29 21:59:40.249682+07	\N
9c749a44-f797-4765-9337-f9fdf8ebffeb	Cooperative 19	COOP-2024-019-1756479580253627000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-29 21:59:40.253636+07	2025-08-29 21:59:40.253636+07	\N
87315604-286a-4e05-8e1a-8660d0e8050e	Cooperative 3	COOP-2024-003-1756479720903720000	Address 3	+12345670003	coop3@example.com	1234567893	{}	t	2025-08-29 22:02:00.903723+07	2025-08-29 22:02:00.903723+07	\N
d9a7eb7b-bc25-4857-bb60-b736b3b06a15	Cooperative 7	COOP-2024-007-1756479720906134000	Address 7	+12345670007	coop7@example.com	1234567897	{}	t	2025-08-29 22:02:00.906136+07	2025-08-29 22:02:00.906136+07	\N
dbc94d8b-b111-456c-85aa-e76153eec508	Cooperative 11	COOP-2024-011-1756479720908587000	Address 11	+12345670011	coop11@example.com	12345678911	{}	t	2025-08-29 22:02:00.908589+07	2025-08-29 22:02:00.908589+07	\N
7de0c84a-e542-41a8-9502-b3bff1cc53a8	Cooperative 15	COOP-2024-015-1756479720910356000	Address 15	+12345670015	coop15@example.com	12345678915	{}	t	2025-08-29 22:02:00.910358+07	2025-08-29 22:02:00.910358+07	\N
6d49b543-bc5a-4f6c-80f6-db6c80b43d73	Cooperative 19	COOP-2024-019-1756479720912011000	Address 19	+12345670019	coop19@example.com	12345678919	{}	t	2025-08-29 22:02:00.912013+07	2025-08-29 22:02:00.912013+07	\N
550e8400-e29b-41d4-a716-446655440001	Koperasi Haji	KH-001-2024	Jl. Masjidil Haram No. 123, Jakarta Pusat	+62-21-12345678	info@koperasihaji.id	1234567890	{"platform_fee": 5, "default_business_share": 30, "default_investor_share": 70}	t	2025-09-19 19:44:44.304146+07	2025-09-19 21:37:15.029654+07	\N
550e8400-e29b-41d4-a716-446655440002	Koperasi SIDANA	SIDANA-002-2024	Jl. Simpan Pinjam No. 456, Jakarta Selatan	+62-21-87654321	info@koperasisidana.id	0987654321	{"platform_fee": 3, "default_business_share": 25, "default_investor_share": 75}	t	2025-09-19 19:44:44.304146+07	2025-09-19 21:37:15.029654+07	\N


ALTER TABLE public.cooperatives ENABLE TRIGGER ALL;


ALTER TABLE public.idempotency_keys DISABLE TRIGGER ALL;

COPY public.idempotency_keys (id, user_id, endpoint, request_hash, response_data, status, created_at, expires_at, sequence_number, table_name, random_suffix) FROM stdin;


ALTER TABLE public.idempotency_keys ENABLE TRIGGER ALL;


ALTER TABLE public.images DISABLE TRIGGER ALL;

COPY public.images (id, image_url, image_name, used_by, image_size, created_at, updated_at) FROM stdin;


ALTER TABLE public.images ENABLE TRIGGER ALL;


ALTER TABLE public.users DISABLE TRIGGER ALL;

COPY public.users (email, name, password, phone, address, is_active, created_at, updated_at, id, cooperative_id, roles, kyc_status, user_profile_image, membership_payment_proof) FROM stdin;
user-2-88fb018b@example.com	User 2	hashedpassword	\N	\N	t	2025-08-22 16:55:09.038078+07	2025-08-22 16:55:09.038078+07	88fb018b-c6ef-44ba-8014-ee68ad7279c5	\N	["guest"]	pending	\N	\N
user-20-cc0ecc1b@example.com	User 20	hashedpassword	\N	\N	t	2025-08-22 16:55:09.058163+07	2025-08-22 16:55:09.058163+07	cc0ecc1b-7ce1-42b2-bdcb-b9bc00097f42	\N	["guest"]	pending	\N	\N
user-21-e24b3498@example.com	User 21	hashedpassword	\N	\N	t	2025-08-22 16:55:09.059089+07	2025-08-22 16:55:09.059089+07	e24b3498-bd8e-4b31-b35a-7b40af48b7f9	\N	["guest"]	pending	\N	\N
user-36-78c08eca@example.com	User 36	hashedpassword	\N	\N	t	2025-08-22 16:55:09.068122+07	2025-08-22 16:55:09.068122+07	78c08eca-874f-43b0-9212-b74d0fc35faf	\N	["guest"]	pending	\N	\N
user-37-f31c4ec7@example.com	User 37	hashedpassword	\N	\N	t	2025-08-22 16:55:09.068904+07	2025-08-22 16:55:09.068904+07	f31c4ec7-ef9a-4e6e-a63e-dfa1c8d986e9	\N	["guest"]	pending	\N	\N
user-38-8c4df6b9@example.com	User 38	hashedpassword	\N	\N	t	2025-08-22 16:55:09.069549+07	2025-08-22 16:55:09.069549+07	8c4df6b9-e1cb-4256-9027-c255f67c7fa0	\N	["guest"]	pending	\N	\N
user-51-6e1d7416@example.com	User 51	hashedpassword	\N	\N	t	2025-08-22 16:55:09.079426+07	2025-08-22 16:55:09.079426+07	6e1d7416-4846-4ca6-ad6e-a8d6f84f46a2	\N	["guest"]	pending	\N	\N
user-60-d14032bd@example.com	User 60	hashedpassword	\N	\N	t	2025-08-22 16:55:09.083987+07	2025-08-22 16:55:09.083987+07	d14032bd-37ef-465a-8333-607d533980b6	\N	["guest"]	pending	\N	\N
user-62-73b912d1@example.com	User 62	hashedpassword	\N	\N	t	2025-08-22 16:55:09.084732+07	2025-08-22 16:55:09.084732+07	73b912d1-2183-419c-ae60-6b8ed36a7b9c	\N	["guest"]	pending	\N	\N
user-64-b0cb1eea@example.com	User 64	hashedpassword	\N	\N	t	2025-08-22 16:55:09.085441+07	2025-08-22 16:55:09.085441+07	b0cb1eea-87b9-4b8c-ad63-b5262c3fdf3e	\N	["guest"]	pending	\N	\N
user-66-fcca65d0@example.com	User 66	hashedpassword	\N	\N	t	2025-08-22 16:55:09.086123+07	2025-08-22 16:55:09.086123+07	fcca65d0-2933-41ea-ae4e-f8169c8b69bf	\N	["guest"]	pending	\N	\N
user-68-26ec4790@example.com	User 68	hashedpassword	\N	\N	t	2025-08-22 16:55:09.086826+07	2025-08-22 16:55:09.086826+07	26ec4790-ac57-4a95-aaee-c2bbe6afc13d	\N	["guest"]	pending	\N	\N
user-70-9ce973c0@example.com	User 70	hashedpassword	\N	\N	t	2025-08-22 16:55:09.087642+07	2025-08-22 16:55:09.087642+07	9ce973c0-7739-4bfd-b535-ba9e82d7d15d	\N	["guest"]	pending	\N	\N
user-79-23cf5669@example.com	User 79	hashedpassword	\N	\N	t	2025-08-22 16:55:09.094263+07	2025-08-22 16:55:09.094263+07	23cf5669-469b-4a0d-b63a-a1a392e66e1c	\N	["guest"]	pending	\N	\N
user-86-22e9ffc5@example.com	User 86	hashedpassword	\N	\N	t	2025-08-22 16:55:09.097659+07	2025-08-22 16:55:09.097659+07	22e9ffc5-3910-41bf-b798-c572f56e101e	\N	["guest"]	pending	\N	\N
user-88-92163562@example.com	User 88	hashedpassword	\N	\N	t	2025-08-22 16:55:09.098963+07	2025-08-22 16:55:09.098963+07	92163562-93f1-45d5-abef-1eae6e5507d8	\N	["guest"]	pending	\N	\N
user-91-6356c278@example.com	User 91	hashedpassword	\N	\N	t	2025-08-22 16:55:09.101077+07	2025-08-22 16:55:09.101077+07	6356c278-02c8-4410-9a92-2ddfd41f5110	\N	["guest"]	pending	\N	\N
user-92-caa807cc@example.com	User 92	hashedpassword	\N	\N	t	2025-08-22 16:55:09.101546+07	2025-08-22 16:55:09.101546+07	caa807cc-183f-421a-96fe-562b346e9ee0	\N	["guest"]	pending	\N	\N
concurrent-user-3-4f84aa18@example.com	Concurrent User 3	password	\N	\N	t	2025-08-22 16:55:09.326212+07	2025-08-22 16:55:09.326213+07	4f84aa18-2759-4e70-b1e3-6e7d4194248f	\N	["guest"]	pending	\N	\N
perf-test-0-09642e92@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:09.558669+07	2025-08-22 16:55:09.558669+07	09642e92-6162-493a-a068-2cd143c77668	\N	["guest"]	pending	\N	\N
perf-test-1-0bdcd753@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:09.559541+07	2025-08-22 16:55:09.559541+07	0bdcd753-9e50-489a-8724-94bf1cce2d51	\N	["guest"]	pending	\N	\N
perf-test-2-3ad2a945@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:09.560133+07	2025-08-22 16:55:09.560133+07	3ad2a945-949f-4f84-a552-f035491956f4	\N	["guest"]	pending	\N	\N
perf-test-3-bb410e70@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:09.56063+07	2025-08-22 16:55:09.56063+07	bb410e70-9ebc-48f3-8413-d18c112bd1b3	\N	["guest"]	pending	\N	\N
perf-test-4-832933df@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:09.56108+07	2025-08-22 16:55:09.56108+07	832933df-9b43-4a44-a54b-5fb1d6fc797f	\N	["guest"]	pending	\N	\N
perf-test-5-00de39f0@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:09.561646+07	2025-08-22 16:55:09.561647+07	00de39f0-341a-43ef-98e1-1524819a5e98	\N	["guest"]	pending	\N	\N
perf-test-6-2b3662bf@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:09.562423+07	2025-08-22 16:55:09.562423+07	2b3662bf-26f5-45b2-847f-fa449200f470	\N	["guest"]	pending	\N	\N
perf-test-7-2652b400@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:09.563109+07	2025-08-22 16:55:09.563109+07	2652b400-4513-43f5-979c-b955113af62c	\N	["guest"]	pending	\N	\N
perf-test-8-a282bc9e@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:09.563739+07	2025-08-22 16:55:09.563739+07	a282bc9e-fe06-45fe-9174-80818394976e	\N	["guest"]	pending	\N	\N
perf-test-9-e272c1bd@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:09.564321+07	2025-08-22 16:55:09.564321+07	e272c1bd-4640-46d4-9df7-4ae89cbb06fb	\N	["guest"]	pending	\N	\N
perf-test-10-cb87c15f@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:09.564902+07	2025-08-22 16:55:09.564902+07	cb87c15f-4a25-40a2-b34b-cabaa1d4d334	\N	["guest"]	pending	\N	\N
perf-test-11-7fef274c@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:09.565584+07	2025-08-22 16:55:09.565584+07	7fef274c-22a4-4a6b-8aa2-d4af8a10ebad	\N	["guest"]	pending	\N	\N
perf-test-12-deb9dff3@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:09.56635+07	2025-08-22 16:55:09.56635+07	deb9dff3-c2b8-45d1-b6ae-77a3fd7b9ecf	\N	["guest"]	pending	\N	\N
perf-test-13-e74cebd5@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:09.567104+07	2025-08-22 16:55:09.567104+07	e74cebd5-d1c4-47e3-98c5-a1c9cd135229	\N	["guest"]	pending	\N	\N
perf-test-14-f6fb8552@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:09.567857+07	2025-08-22 16:55:09.567857+07	f6fb8552-17f3-42a7-b981-dddd1991de43	\N	["guest"]	pending	\N	\N
perf-test-15-d620f9db@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:09.568524+07	2025-08-22 16:55:09.568524+07	d620f9db-839b-47a3-b25a-3bd2020798a6	\N	["guest"]	pending	\N	\N
perf-test-16-48720404@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:09.569056+07	2025-08-22 16:55:09.569056+07	48720404-c204-4acc-9ac3-0ca09fba44dc	\N	["guest"]	pending	\N	\N
perf-test-17-ef10460f@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:09.569509+07	2025-08-22 16:55:09.56951+07	ef10460f-97d0-4080-8ebd-055decb1dde7	\N	["guest"]	pending	\N	\N
perf-test-18-a7eb7ffc@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:09.569978+07	2025-08-22 16:55:09.569978+07	a7eb7ffc-831a-41e1-951f-b27308b9ee74	\N	["guest"]	pending	\N	\N
perf-test-19-01b1e880@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:09.570405+07	2025-08-22 16:55:09.570405+07	01b1e880-3f64-493a-a5cc-270a33c9d6a3	\N	["guest"]	pending	\N	\N
perf-test-20-2e3bce1a@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:09.570928+07	2025-08-22 16:55:09.570931+07	2e3bce1a-4476-4138-be19-99ded56a4bee	\N	["guest"]	pending	\N	\N
perf-test-21-10081963@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:09.571384+07	2025-08-22 16:55:09.571384+07	10081963-0977-4acb-ad18-a5a0ba394577	\N	["guest"]	pending	\N	\N
perf-test-22-7a675b08@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:09.571946+07	2025-08-22 16:55:09.571946+07	7a675b08-443a-4595-8999-f041fc26db8a	\N	["guest"]	pending	\N	\N
perf-test-23-42e8f36d@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:09.572498+07	2025-08-22 16:55:09.572498+07	42e8f36d-72ee-4fd6-bf4c-90507a8cdef8	\N	["guest"]	pending	\N	\N
perf-test-24-07025076@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:09.573427+07	2025-08-22 16:55:09.573427+07	07025076-ad67-482f-b5c6-fb45b05bb64e	\N	["guest"]	pending	\N	\N
perf-test-25-33a60f03@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:09.574317+07	2025-08-22 16:55:09.574317+07	33a60f03-10b5-4748-bcfc-a329919a6171	\N	["guest"]	pending	\N	\N
perf-test-26-447dba74@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:09.575217+07	2025-08-22 16:55:09.575217+07	447dba74-1744-4988-b7e3-9e324799a57a	\N	["guest"]	pending	\N	\N
perf-test-27-777ad75a@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:09.575844+07	2025-08-22 16:55:09.575844+07	777ad75a-ca0a-4239-b2d2-b8d7d5119d23	\N	["guest"]	pending	\N	\N
perf-test-28-d726223b@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:09.576341+07	2025-08-22 16:55:09.576341+07	d726223b-6020-4721-ba7c-7a5d5fbef4be	\N	["guest"]	pending	\N	\N
perf-test-29-11c8c3ee@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:09.576787+07	2025-08-22 16:55:09.576787+07	11c8c3ee-1dec-44cf-9685-bc2a63a43a58	\N	["guest"]	pending	\N	\N
perf-test-30-a7fd08ed@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:09.577126+07	2025-08-22 16:55:09.577126+07	a7fd08ed-54e2-4bed-bed7-566d1c42cf47	\N	["guest"]	pending	\N	\N
perf-test-31-2a7c265b@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:09.57751+07	2025-08-22 16:55:09.57751+07	2a7c265b-79de-4885-b0aa-80c5f3784889	\N	["guest"]	pending	\N	\N
perf-test-32-b3ef88f1@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:09.577847+07	2025-08-22 16:55:09.577847+07	b3ef88f1-7de8-404b-a7e5-378c2a59edd1	\N	["guest"]	pending	\N	\N
perf-test-33-cace9c92@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:09.578186+07	2025-08-22 16:55:09.578187+07	cace9c92-593f-47da-9204-bd21a59f0ea0	\N	["guest"]	pending	\N	\N
perf-test-34-7892e77a@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:09.578638+07	2025-08-22 16:55:09.578639+07	7892e77a-383e-4fb2-b61e-0052cb51972a	\N	["guest"]	pending	\N	\N
perf-test-35-b9271480@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:09.579501+07	2025-08-22 16:55:09.579501+07	b9271480-1144-4600-ab55-f2faa100f261	\N	["guest"]	pending	\N	\N
perf-test-36-7b9c2e36@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:09.579973+07	2025-08-22 16:55:09.579973+07	7b9c2e36-a617-4fd2-85fd-6dd11d2508e9	\N	["guest"]	pending	\N	\N
perf-test-37-d954f5dd@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:09.580408+07	2025-08-22 16:55:09.580408+07	d954f5dd-f11b-4cea-89b6-e5b9139f0bee	\N	["guest"]	pending	\N	\N
perf-test-38-7689adad@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:09.580944+07	2025-08-22 16:55:09.580944+07	7689adad-1832-4887-892b-1016f38c7162	\N	["guest"]	pending	\N	\N
perf-test-39-55d505f5@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:09.58133+07	2025-08-22 16:55:09.58133+07	55d505f5-26dd-47e1-83d3-aa0dce897b69	\N	["guest"]	pending	\N	\N
perf-test-40-34d96bb4@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:09.581801+07	2025-08-22 16:55:09.581801+07	34d96bb4-057b-4253-88d9-db89deeb498f	\N	["guest"]	pending	\N	\N
perf-test-41-564eef25@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:09.58226+07	2025-08-22 16:55:09.58226+07	564eef25-a7a4-4cdc-b941-6697f3ceb566	\N	["guest"]	pending	\N	\N
perf-test-42-1c1e619c@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:09.582719+07	2025-08-22 16:55:09.582719+07	1c1e619c-1f21-496a-a470-50dd42f7a106	\N	["guest"]	pending	\N	\N
perf-test-43-5e36ca92@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:09.583194+07	2025-08-22 16:55:09.583194+07	5e36ca92-3982-459b-b774-2c04301104d4	\N	["guest"]	pending	\N	\N
perf-test-44-26096058@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:09.583694+07	2025-08-22 16:55:09.583694+07	26096058-e478-4121-9b80-9f587a9396dd	\N	["guest"]	pending	\N	\N
perf-test-45-a24a4660@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:09.58412+07	2025-08-22 16:55:09.58412+07	a24a4660-4920-43bb-a0dd-3b8bf097f122	\N	["guest"]	pending	\N	\N
perf-test-46-6d5ec569@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:09.584527+07	2025-08-22 16:55:09.584528+07	6d5ec569-1212-441d-b70a-952daa5025d1	\N	["guest"]	pending	\N	\N
perf-test-47-28876570@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:09.584939+07	2025-08-22 16:55:09.584939+07	28876570-f01e-41ea-abf8-2a7f3f6a83b4	\N	["guest"]	pending	\N	\N
perf-test-48-dde589ff@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:09.585316+07	2025-08-22 16:55:09.585316+07	dde589ff-215b-4898-aa0e-101c760a9a8d	\N	["guest"]	pending	\N	\N
perf-test-49-e31b00a1@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:09.585646+07	2025-08-22 16:55:09.585646+07	e31b00a1-a63e-49ee-ba97-c791176fab5b	\N	["guest"]	pending	\N	\N
user-3-747d1374@example.com	User 3	hashedpassword	\N	\N	t	2025-08-22 16:55:45.960143+07	2025-08-22 16:55:45.960144+07	747d1374-25f2-481e-9b5b-32751d0059b1	\N	["guest"]	pending	\N	\N
user-7-52414181@example.com	User 7	hashedpassword	\N	\N	t	2025-08-22 16:55:45.969793+07	2025-08-22 16:55:45.969793+07	52414181-9222-48fd-ad3a-97d37e8018b8	\N	["guest"]	pending	\N	\N
user-12-7b13a73c@example.com	User 12	hashedpassword	\N	\N	t	2025-08-22 16:55:45.973471+07	2025-08-22 16:55:45.973471+07	7b13a73c-5246-4cf2-a292-bb050f2ee3b2	\N	["guest"]	pending	\N	\N
user-14-179df57e@example.com	User 14	hashedpassword	\N	\N	t	2025-08-22 16:55:45.974582+07	2025-08-22 16:55:45.974582+07	179df57e-de90-4ef0-be4c-43e9801a28f6	\N	["guest"]	pending	\N	\N
user-21-3e6ca280@example.com	User 21	hashedpassword	\N	\N	t	2025-08-22 16:55:45.977409+07	2025-08-22 16:55:45.977409+07	3e6ca280-11d2-43ef-a775-df70f2b8fd1e	\N	["guest"]	pending	\N	\N
user-25-aa9f524d@example.com	User 25	hashedpassword	\N	\N	t	2025-08-22 16:55:45.979151+07	2025-08-22 16:55:45.979151+07	aa9f524d-ed40-4eb8-b25e-a15cd81b6fab	\N	["guest"]	pending	\N	\N
user-26-70409a05@example.com	User 26	hashedpassword	\N	\N	t	2025-08-22 16:55:45.980092+07	2025-08-22 16:55:45.980092+07	70409a05-a8b5-43c7-b66c-197471373387	\N	["guest"]	pending	\N	\N
user-29-bdab7722@example.com	User 29	hashedpassword	\N	\N	t	2025-08-22 16:55:45.982675+07	2025-08-22 16:55:45.982675+07	bdab7722-a914-42c7-9cef-65f3f32d8934	\N	["guest"]	pending	\N	\N
user-44-f1de3099@example.com	User 44	hashedpassword	\N	\N	t	2025-08-22 16:55:45.991544+07	2025-08-22 16:55:45.991544+07	f1de3099-bd53-4f21-b3eb-a6026cbaa681	\N	["guest"]	pending	\N	\N
user-46-22ff3f5b@example.com	User 46	hashedpassword	\N	\N	t	2025-08-22 16:55:45.992976+07	2025-08-22 16:55:45.992977+07	22ff3f5b-5b22-46a6-a5bc-172cc1a9bc67	\N	["guest"]	pending	\N	\N
user-51-14c40732@example.com	User 51	hashedpassword	\N	\N	t	2025-08-22 16:55:45.99495+07	2025-08-22 16:55:45.994951+07	14c40732-5ad8-444a-8b74-fa3664b10cfe	\N	["guest"]	pending	\N	\N
user-52-21b269ff@example.com	User 52	hashedpassword	\N	\N	t	2025-08-22 16:55:45.995348+07	2025-08-22 16:55:45.995348+07	21b269ff-a958-4cfb-afa1-89b5d027bd4e	\N	["guest"]	pending	\N	\N
user-57-568f56e1@example.com	User 57	hashedpassword	\N	\N	t	2025-08-22 16:55:45.998935+07	2025-08-22 16:55:45.998935+07	568f56e1-f903-490f-80e3-b325c3653474	\N	["guest"]	pending	\N	\N
user-58-63ece99f@example.com	User 58	hashedpassword	\N	\N	t	2025-08-22 16:55:45.999646+07	2025-08-22 16:55:45.999646+07	63ece99f-ddea-4ead-aef5-0f011647f41a	\N	["guest"]	pending	\N	\N
user-64-f138a863@example.com	User 64	hashedpassword	\N	\N	t	2025-08-22 16:55:46.003777+07	2025-08-22 16:55:46.003777+07	f138a863-01ce-46f8-b149-9f2dde2bd79a	\N	["guest"]	pending	\N	\N
user-70-f5233205@example.com	User 70	hashedpassword	\N	\N	t	2025-08-22 16:55:46.007295+07	2025-08-22 16:55:46.007295+07	f5233205-a193-4f15-a449-67a414d54910	\N	["guest"]	pending	\N	\N
user-78-34262b54@example.com	User 78	hashedpassword	\N	\N	t	2025-08-22 16:55:46.010731+07	2025-08-22 16:55:46.010731+07	34262b54-3eca-42fe-a30f-8f2d98a6b377	\N	["guest"]	pending	\N	\N
user-82-a693309d@example.com	User 82	hashedpassword	\N	\N	t	2025-08-22 16:55:46.012843+07	2025-08-22 16:55:46.012844+07	a693309d-e30f-42ce-8c2d-7385121a4a40	\N	["guest"]	pending	\N	\N
user-89-240135a4@example.com	User 89	hashedpassword	\N	\N	t	2025-08-22 16:55:46.019457+07	2025-08-22 16:55:46.019457+07	240135a4-8540-47e0-a23f-3a8b3904f3b5	\N	["guest"]	pending	\N	\N
user-90-38907984@example.com	User 90	hashedpassword	\N	\N	t	2025-08-22 16:55:46.020153+07	2025-08-22 16:55:46.020153+07	38907984-cf7b-4303-8a97-059f13e5b924	\N	["guest"]	pending	\N	\N
user-92-5bbad4b8@example.com	User 92	hashedpassword	\N	\N	t	2025-08-22 16:55:46.021417+07	2025-08-22 16:55:46.021417+07	5bbad4b8-5cf8-414d-bd77-2fb99edb4013	\N	["guest"]	pending	\N	\N
user-93-ad005252@example.com	User 93	hashedpassword	\N	\N	t	2025-08-22 16:55:46.022044+07	2025-08-22 16:55:46.022045+07	ad005252-8644-45d3-94be-fcc1d1f0fc26	\N	["guest"]	pending	\N	\N
user-97-62a5089b@example.com	User 97	hashedpassword	\N	\N	t	2025-08-22 16:55:46.023988+07	2025-08-22 16:55:46.023988+07	62a5089b-0484-4f90-ab04-94751551c9d7	\N	["guest"]	pending	\N	\N
user-99-88d9e356@example.com	User 99	hashedpassword	\N	\N	t	2025-08-22 16:55:46.024762+07	2025-08-22 16:55:46.024762+07	88d9e356-401a-4327-91a6-f78ce6b55be7	\N	["guest"]	pending	\N	\N
concurrent-user-3-97131c75@example.com	Concurrent User 3	password	\N	\N	t	2025-08-22 16:55:46.283285+07	2025-08-22 16:55:46.283285+07	97131c75-c47d-4930-a3ba-08479ff92f78	\N	["guest"]	pending	\N	\N
perf-test-0-f128baa7@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:55:46.539836+07	2025-08-22 16:55:46.539836+07	f128baa7-b436-481e-90f8-b0c80e3ee09e	\N	["guest"]	pending	\N	\N
perf-test-1-1dbca3cf@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:55:46.540291+07	2025-08-22 16:55:46.540291+07	1dbca3cf-47fa-47db-b0c1-b1c05a579046	\N	["guest"]	pending	\N	\N
perf-test-2-fe7153af@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:55:46.540668+07	2025-08-22 16:55:46.540668+07	fe7153af-4a2e-4c13-b38e-1151b786c393	\N	["guest"]	pending	\N	\N
perf-test-3-c6fa680a@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:55:46.541074+07	2025-08-22 16:55:46.541074+07	c6fa680a-ff26-44be-a501-fda893947b4c	\N	["guest"]	pending	\N	\N
perf-test-4-4adf971f@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:55:46.541449+07	2025-08-22 16:55:46.541449+07	4adf971f-f1d5-4c5c-8e7b-d1667717be83	\N	["guest"]	pending	\N	\N
perf-test-5-a0cccfbd@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:55:46.541803+07	2025-08-22 16:55:46.541803+07	a0cccfbd-ac7b-489a-9fae-adf0a99bb583	\N	["guest"]	pending	\N	\N
perf-test-6-5abee1a1@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:55:46.542149+07	2025-08-22 16:55:46.542149+07	5abee1a1-9f93-4db9-a924-150b189321f6	\N	["guest"]	pending	\N	\N
perf-test-7-5269c123@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:55:46.542513+07	2025-08-22 16:55:46.542513+07	5269c123-a98c-440f-ba50-ad682022b2f5	\N	["guest"]	pending	\N	\N
perf-test-8-cc5f2d4e@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:55:46.542847+07	2025-08-22 16:55:46.542847+07	cc5f2d4e-e7e5-4a8a-8b53-ae9270a28f7d	\N	["guest"]	pending	\N	\N
perf-test-9-e0687bd1@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:55:46.543204+07	2025-08-22 16:55:46.543204+07	e0687bd1-c93f-49be-8594-28db3da2d7d3	\N	["guest"]	pending	\N	\N
perf-test-10-be48634e@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:55:46.543607+07	2025-08-22 16:55:46.543607+07	be48634e-7903-473e-8dd0-67d5bf05dc82	\N	["guest"]	pending	\N	\N
perf-test-11-2237e7c0@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:55:46.543947+07	2025-08-22 16:55:46.543947+07	2237e7c0-1a56-45a4-9691-cf2ea6671b2d	\N	["guest"]	pending	\N	\N
perf-test-12-f7546ca0@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:55:46.544317+07	2025-08-22 16:55:46.544317+07	f7546ca0-7097-4cad-9d0f-de9a140dc636	\N	["guest"]	pending	\N	\N
perf-test-13-8fac815a@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:55:46.544763+07	2025-08-22 16:55:46.544764+07	8fac815a-f05b-41f9-a869-5c7a57b04cd3	\N	["guest"]	pending	\N	\N
perf-test-14-3ff796f3@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:55:46.545112+07	2025-08-22 16:55:46.545112+07	3ff796f3-3a6a-400e-80b2-73abe45ad74c	\N	["guest"]	pending	\N	\N
perf-test-15-2c275bbc@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:55:46.54546+07	2025-08-22 16:55:46.54546+07	2c275bbc-4779-4389-a71f-17a007138550	\N	["guest"]	pending	\N	\N
perf-test-16-f87705e7@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:55:46.545837+07	2025-08-22 16:55:46.545837+07	f87705e7-dfeb-46a3-ac1b-35c1b48d13ef	\N	["guest"]	pending	\N	\N
perf-test-17-cc1f0dce@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:55:46.546281+07	2025-08-22 16:55:46.546281+07	cc1f0dce-9c35-401e-abe7-386f94c786d8	\N	["guest"]	pending	\N	\N
perf-test-18-67ecc4d2@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:55:46.546739+07	2025-08-22 16:55:46.546739+07	67ecc4d2-cc03-4189-8c10-ad7b7f9956a5	\N	["guest"]	pending	\N	\N
perf-test-19-214a10f2@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:55:46.547301+07	2025-08-22 16:55:46.547301+07	214a10f2-70b0-45e0-97dd-6341cfa6fbb2	\N	["guest"]	pending	\N	\N
perf-test-20-06bfc360@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:55:46.547851+07	2025-08-22 16:55:46.547851+07	06bfc360-cea5-49d4-96d2-12fd7d0f54e9	\N	["guest"]	pending	\N	\N
perf-test-21-df0507da@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:55:46.548398+07	2025-08-22 16:55:46.548398+07	df0507da-1016-425f-a168-66072bfd7e02	\N	["guest"]	pending	\N	\N
perf-test-22-e6561055@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:55:46.548958+07	2025-08-22 16:55:46.548958+07	e6561055-28f3-432b-8f4b-f9d2775f6c7c	\N	["guest"]	pending	\N	\N
perf-test-23-bf6cab71@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:55:46.549502+07	2025-08-22 16:55:46.549502+07	bf6cab71-9494-4ccd-aa12-5aeee1f3a21f	\N	["guest"]	pending	\N	\N
perf-test-24-3638814d@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:55:46.55004+07	2025-08-22 16:55:46.55004+07	3638814d-0b63-493a-a39e-0fd412c1c15d	\N	["guest"]	pending	\N	\N
perf-test-25-8b00975f@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:55:46.550772+07	2025-08-22 16:55:46.550772+07	8b00975f-5632-454f-93a1-712a1eb74cc9	\N	["guest"]	pending	\N	\N
perf-test-26-dc0f7cb4@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:55:46.551324+07	2025-08-22 16:55:46.551324+07	dc0f7cb4-5a82-4f89-97eb-088caf185ccf	\N	["guest"]	pending	\N	\N
perf-test-27-8832e40a@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:55:46.551808+07	2025-08-22 16:55:46.551808+07	8832e40a-80ae-4442-895b-a8280c9babe5	\N	["guest"]	pending	\N	\N
perf-test-28-177ca146@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:55:46.552228+07	2025-08-22 16:55:46.552228+07	177ca146-68e7-4c94-91d4-0947a6367ff3	\N	["guest"]	pending	\N	\N
perf-test-29-f21be6ff@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:55:46.552808+07	2025-08-22 16:55:46.552808+07	f21be6ff-2fa5-48fa-a139-c8d297f4956b	\N	["guest"]	pending	\N	\N
perf-test-30-ef0b5710@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:55:46.553308+07	2025-08-22 16:55:46.553308+07	ef0b5710-70dc-4a76-92d7-6904ace6bb91	\N	["guest"]	pending	\N	\N
perf-test-31-709223a8@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:55:46.553782+07	2025-08-22 16:55:46.553782+07	709223a8-befb-4f00-8fde-3e548fbc645d	\N	["guest"]	pending	\N	\N
perf-test-32-80de555c@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:55:46.554249+07	2025-08-22 16:55:46.554249+07	80de555c-afb1-4236-aa72-2ee233d48c73	\N	["guest"]	pending	\N	\N
perf-test-33-836103ac@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:55:46.554703+07	2025-08-22 16:55:46.554703+07	836103ac-5c1d-4d89-9a97-36cf8560960f	\N	["guest"]	pending	\N	\N
perf-test-34-4b0d5da1@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:55:46.555206+07	2025-08-22 16:55:46.555206+07	4b0d5da1-afc6-4034-a012-934706404075	\N	["guest"]	pending	\N	\N
perf-test-35-df2cbf21@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:55:46.555571+07	2025-08-22 16:55:46.555572+07	df2cbf21-2a23-4042-a44d-e011b6aaacc3	\N	["guest"]	pending	\N	\N
perf-test-36-42987541@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:55:46.555955+07	2025-08-22 16:55:46.555955+07	42987541-7e91-4047-beec-810cfcb7c5cd	\N	["guest"]	pending	\N	\N
perf-test-37-8335f913@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:55:46.556355+07	2025-08-22 16:55:46.556355+07	8335f913-c70a-4e04-af8e-9741377b115d	\N	["guest"]	pending	\N	\N
perf-test-38-e64a51f4@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:55:46.556727+07	2025-08-22 16:55:46.556727+07	e64a51f4-83c4-4e90-bf20-f92bc5874858	\N	["guest"]	pending	\N	\N
perf-test-39-12f47a99@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:55:46.557104+07	2025-08-22 16:55:46.557104+07	12f47a99-1320-47de-940e-982a8058579f	\N	["guest"]	pending	\N	\N
perf-test-40-e7047ec1@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:55:46.557494+07	2025-08-22 16:55:46.557494+07	e7047ec1-00ac-4091-b601-e75be9647058	\N	["guest"]	pending	\N	\N
perf-test-41-43c325a0@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:55:46.557849+07	2025-08-22 16:55:46.557849+07	43c325a0-610a-474a-8c77-3283217d5540	\N	["guest"]	pending	\N	\N
perf-test-42-3cc49c0a@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:55:46.558202+07	2025-08-22 16:55:46.558202+07	3cc49c0a-e4b1-4c6d-bb13-88bd559721e1	\N	["guest"]	pending	\N	\N
perf-test-43-858e91a6@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:55:46.558537+07	2025-08-22 16:55:46.558537+07	858e91a6-aa64-400c-b79f-d16b91294302	\N	["guest"]	pending	\N	\N
perf-test-44-55edad37@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:55:46.558898+07	2025-08-22 16:55:46.558898+07	55edad37-58c3-44db-a36d-74b01f9aa1fc	\N	["guest"]	pending	\N	\N
perf-test-45-8be7b4e2@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:55:46.559251+07	2025-08-22 16:55:46.559251+07	8be7b4e2-b87d-4989-9476-6459647643cb	\N	["guest"]	pending	\N	\N
perf-test-46-f5a5110e@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:55:46.559598+07	2025-08-22 16:55:46.559598+07	f5a5110e-851c-4ad3-a84e-70951ef7dd4f	\N	["guest"]	pending	\N	\N
perf-test-47-a1d52500@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:55:46.559934+07	2025-08-22 16:55:46.559934+07	a1d52500-7962-4190-a199-a611713bec70	\N	["guest"]	pending	\N	\N
perf-test-48-4848fb42@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:55:46.560308+07	2025-08-22 16:55:46.560308+07	4848fb42-cffe-4bb6-ba74-e2b34202f84b	\N	["guest"]	pending	\N	\N
perf-test-49-37530989@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:55:46.560765+07	2025-08-22 16:55:46.560766+07	37530989-cba7-482a-9695-c3bb5465a704	\N	["guest"]	pending	\N	\N
user-0-c8545292@example.com	User 0	hashedpassword	\N	\N	t	2025-08-22 16:56:17.268388+07	2025-08-22 16:56:17.268388+07	c8545292-6c87-46f2-a965-456d1c2cdc40	\N	["guest"]	pending	\N	\N
user-1-16608c24@example.com	User 1	hashedpassword	\N	\N	t	2025-08-22 16:56:17.273424+07	2025-08-22 16:56:17.273425+07	16608c24-b491-4f41-8925-a9823016606b	\N	["guest"]	pending	\N	\N
user-5-98db7a5e@example.com	User 5	hashedpassword	\N	\N	t	2025-08-22 16:56:17.281738+07	2025-08-22 16:56:17.281738+07	98db7a5e-af6a-49e7-8f4b-5e2a4b078180	\N	["guest"]	pending	\N	\N
user-13-572e762a@example.com	User 13	hashedpassword	\N	\N	t	2025-08-22 16:56:17.29048+07	2025-08-22 16:56:17.29048+07	572e762a-17e7-4552-9573-78c90c5832be	\N	["guest"]	pending	\N	\N
user-21-3b028f4e@example.com	User 21	hashedpassword	\N	\N	t	2025-08-22 16:56:17.296964+07	2025-08-22 16:56:17.296965+07	3b028f4e-54a8-4ca7-ac8b-31ecaf9c1ac1	\N	["guest"]	pending	\N	\N
user-25-dceac93a@example.com	User 25	hashedpassword	\N	\N	t	2025-08-22 16:56:17.299425+07	2025-08-22 16:56:17.299426+07	dceac93a-bf64-419e-9bc1-d614c598ebbe	\N	["guest"]	pending	\N	\N
user-28-e8a9919b@example.com	User 28	hashedpassword	\N	\N	t	2025-08-22 16:56:17.300754+07	2025-08-22 16:56:17.300754+07	e8a9919b-ca97-4b71-878a-c6a3e33aa331	\N	["guest"]	pending	\N	\N
user-34-3ccce78c@example.com	User 34	hashedpassword	\N	\N	t	2025-08-22 16:56:17.306075+07	2025-08-22 16:56:17.306075+07	3ccce78c-fc69-496a-b1e3-4ead875b5fae	\N	["guest"]	pending	\N	\N
user-38-f4337ccb@example.com	User 38	hashedpassword	\N	\N	t	2025-08-22 16:56:17.310481+07	2025-08-22 16:56:17.310481+07	f4337ccb-4b00-4db3-8021-e530774b3ff5	\N	["guest"]	pending	\N	\N
user-39-8ee2a549@example.com	User 39	hashedpassword	\N	\N	t	2025-08-22 16:56:17.311187+07	2025-08-22 16:56:17.311187+07	8ee2a549-c658-48bc-aec3-f499e29f9b0d	\N	["guest"]	pending	\N	\N
user-44-61826b3c@example.com	User 44	hashedpassword	\N	\N	t	2025-08-22 16:56:17.314288+07	2025-08-22 16:56:17.314288+07	61826b3c-2403-4130-8603-5eaa3f264590	\N	["guest"]	pending	\N	\N
user-45-8e53a438@example.com	User 45	hashedpassword	\N	\N	t	2025-08-22 16:56:17.314944+07	2025-08-22 16:56:17.314944+07	8e53a438-e54b-4549-934c-969065dcd270	\N	["guest"]	pending	\N	\N
user-63-fb269643@example.com	User 63	hashedpassword	\N	\N	t	2025-08-22 16:56:17.327254+07	2025-08-22 16:56:17.327254+07	fb269643-7a86-4ac7-a799-0fd4099ac290	\N	["guest"]	pending	\N	\N
user-66-a86bda5d@example.com	User 66	hashedpassword	\N	\N	t	2025-08-22 16:56:17.328891+07	2025-08-22 16:56:17.328891+07	a86bda5d-e711-42ad-9f85-49a79a471245	\N	["guest"]	pending	\N	\N
user-67-e74a4a70@example.com	User 67	hashedpassword	\N	\N	t	2025-08-22 16:56:17.329351+07	2025-08-22 16:56:17.329351+07	e74a4a70-a96e-436a-90e4-45b7e7da5607	\N	["guest"]	pending	\N	\N
user-76-2ad123ed@example.com	User 76	hashedpassword	\N	\N	t	2025-08-22 16:56:17.332651+07	2025-08-22 16:56:17.332651+07	2ad123ed-f0c5-4efb-ab5f-441f1269f3f9	\N	["guest"]	pending	\N	\N
user-79-8271a641@example.com	User 79	hashedpassword	\N	\N	t	2025-08-22 16:56:17.333815+07	2025-08-22 16:56:17.333815+07	8271a641-ac98-4e5f-914e-dea30126b0c1	\N	["guest"]	pending	\N	\N
user-92-ef15bb72@example.com	User 92	hashedpassword	\N	\N	t	2025-08-22 16:56:17.344619+07	2025-08-22 16:56:17.344619+07	ef15bb72-3feb-470c-b8ca-116cf22e430f	\N	["guest"]	pending	\N	\N
user-97-df6f05fa@example.com	User 97	hashedpassword	\N	\N	t	2025-08-22 16:56:17.347779+07	2025-08-22 16:56:17.347779+07	df6f05fa-dc1c-400f-b24c-aaccfeb247a6	\N	["guest"]	pending	\N	\N
user-98-91b4b875@example.com	User 98	hashedpassword	\N	\N	t	2025-08-22 16:56:17.348298+07	2025-08-22 16:56:17.348298+07	91b4b875-226c-4bff-a2ac-21967bd8db28	\N	["guest"]	pending	\N	\N
concurrent-user-3-f2c526ff@example.com	Concurrent User 3	password	\N	\N	t	2025-08-22 16:56:17.628807+07	2025-08-22 16:56:17.628807+07	f2c526ff-9b1d-495f-a9a3-6b3d62404175	\N	["guest"]	pending	\N	\N
perf-test-0-9440a2b4@example.com	Performance User 0	password	\N	\N	t	2025-08-22 16:56:17.883995+07	2025-08-22 16:56:17.883996+07	9440a2b4-3d63-4386-a4fe-8d0d9326cae3	\N	["guest"]	pending	\N	\N
perf-test-1-10e3377f@example.com	Performance User 1	password	\N	\N	t	2025-08-22 16:56:17.884555+07	2025-08-22 16:56:17.884555+07	10e3377f-5a79-436b-ab3a-3f24467ed79a	\N	["guest"]	pending	\N	\N
perf-test-2-69930f44@example.com	Performance User 2	password	\N	\N	t	2025-08-22 16:56:17.885323+07	2025-08-22 16:56:17.885323+07	69930f44-405a-4129-a124-6d44908262fc	\N	["guest"]	pending	\N	\N
perf-test-3-05767491@example.com	Performance User 3	password	\N	\N	t	2025-08-22 16:56:17.885753+07	2025-08-22 16:56:17.885753+07	05767491-fd6b-4b93-8660-1ef0e2325ff8	\N	["guest"]	pending	\N	\N
perf-test-4-c48eb9f8@example.com	Performance User 4	password	\N	\N	t	2025-08-22 16:56:17.886132+07	2025-08-22 16:56:17.886132+07	c48eb9f8-4fb6-4934-a920-b00311db88d7	\N	["guest"]	pending	\N	\N
perf-test-5-2e78af21@example.com	Performance User 5	password	\N	\N	t	2025-08-22 16:56:17.886505+07	2025-08-22 16:56:17.886505+07	2e78af21-36c2-47d2-bf1e-75ef4d59f1b2	\N	["guest"]	pending	\N	\N
perf-test-6-3539b29c@example.com	Performance User 6	password	\N	\N	t	2025-08-22 16:56:17.886921+07	2025-08-22 16:56:17.886921+07	3539b29c-a110-469f-849c-d13227db34bf	\N	["guest"]	pending	\N	\N
perf-test-7-62332fab@example.com	Performance User 7	password	\N	\N	t	2025-08-22 16:56:17.887479+07	2025-08-22 16:56:17.887479+07	62332fab-6b5d-435d-b100-3e2ed8d95035	\N	["guest"]	pending	\N	\N
perf-test-8-413b9217@example.com	Performance User 8	password	\N	\N	t	2025-08-22 16:56:17.888082+07	2025-08-22 16:56:17.888082+07	413b9217-ec14-4a04-8812-ea2f44e085af	\N	["guest"]	pending	\N	\N
perf-test-9-269530de@example.com	Performance User 9	password	\N	\N	t	2025-08-22 16:56:17.889055+07	2025-08-22 16:56:17.889056+07	269530de-8199-43c5-b84e-907f6950c7d8	\N	["guest"]	pending	\N	\N
perf-test-10-34460c71@example.com	Performance User 10	password	\N	\N	t	2025-08-22 16:56:17.8902+07	2025-08-22 16:56:17.8902+07	34460c71-0752-4a55-b65b-0583b6afa149	\N	["guest"]	pending	\N	\N
perf-test-11-ec0b3a28@example.com	Performance User 11	password	\N	\N	t	2025-08-22 16:56:17.891159+07	2025-08-22 16:56:17.89116+07	ec0b3a28-58ca-4959-9af7-482eb636d4db	\N	["guest"]	pending	\N	\N
perf-test-12-92bcd111@example.com	Performance User 12	password	\N	\N	t	2025-08-22 16:56:17.891922+07	2025-08-22 16:56:17.891922+07	92bcd111-9a09-4142-b5ce-57b755085bfc	\N	["guest"]	pending	\N	\N
perf-test-13-dcacf63a@example.com	Performance User 13	password	\N	\N	t	2025-08-22 16:56:17.892596+07	2025-08-22 16:56:17.892596+07	dcacf63a-a56c-427d-8a4c-8b6f6a94dcfe	\N	["guest"]	pending	\N	\N
perf-test-14-2d970e50@example.com	Performance User 14	password	\N	\N	t	2025-08-22 16:56:17.893224+07	2025-08-22 16:56:17.893224+07	2d970e50-fa9e-4f1b-95ad-fee1e3bedef5	\N	["guest"]	pending	\N	\N
perf-test-15-f135cc01@example.com	Performance User 15	password	\N	\N	t	2025-08-22 16:56:17.893831+07	2025-08-22 16:56:17.893831+07	f135cc01-72f8-4b26-bee2-2a6a295de957	\N	["guest"]	pending	\N	\N
perf-test-16-922bdcc2@example.com	Performance User 16	password	\N	\N	t	2025-08-22 16:56:17.894514+07	2025-08-22 16:56:17.894514+07	922bdcc2-e989-4389-9a60-0191bd9bae8f	\N	["guest"]	pending	\N	\N
perf-test-17-1859bde2@example.com	Performance User 17	password	\N	\N	t	2025-08-22 16:56:17.895046+07	2025-08-22 16:56:17.895046+07	1859bde2-38ed-4ff3-aed9-26634e6c47c6	\N	["guest"]	pending	\N	\N
perf-test-18-c86998c6@example.com	Performance User 18	password	\N	\N	t	2025-08-22 16:56:17.895784+07	2025-08-22 16:56:17.895785+07	c86998c6-65b7-4a2a-9abb-900dc91ef2f3	\N	["guest"]	pending	\N	\N
perf-test-19-851131f1@example.com	Performance User 19	password	\N	\N	t	2025-08-22 16:56:17.896563+07	2025-08-22 16:56:17.896563+07	851131f1-acab-4588-a31a-6fb084bf8f82	\N	["guest"]	pending	\N	\N
perf-test-20-6c90d6ef@example.com	Performance User 20	password	\N	\N	t	2025-08-22 16:56:17.897152+07	2025-08-22 16:56:17.897152+07	6c90d6ef-45fd-465b-8336-95305d5725df	\N	["guest"]	pending	\N	\N
perf-test-21-e48c9c96@example.com	Performance User 21	password	\N	\N	t	2025-08-22 16:56:17.897692+07	2025-08-22 16:56:17.897692+07	e48c9c96-f0a6-4084-8780-feb706f9b671	\N	["guest"]	pending	\N	\N
perf-test-22-5146ccd8@example.com	Performance User 22	password	\N	\N	t	2025-08-22 16:56:17.898203+07	2025-08-22 16:56:17.898203+07	5146ccd8-cd8e-4c15-8026-26133ca415f2	\N	["guest"]	pending	\N	\N
perf-test-23-f43f541e@example.com	Performance User 23	password	\N	\N	t	2025-08-22 16:56:17.898657+07	2025-08-22 16:56:17.898657+07	f43f541e-5d0a-489e-805a-a91f397e6f44	\N	["guest"]	pending	\N	\N
perf-test-24-c9bcd57f@example.com	Performance User 24	password	\N	\N	t	2025-08-22 16:56:17.899119+07	2025-08-22 16:56:17.899119+07	c9bcd57f-381b-46e8-861c-70f6e657e1c9	\N	["guest"]	pending	\N	\N
perf-test-25-fd966caa@example.com	Performance User 25	password	\N	\N	t	2025-08-22 16:56:17.899622+07	2025-08-22 16:56:17.899622+07	fd966caa-d191-4167-b971-89d8d8f849b8	\N	["guest"]	pending	\N	\N
perf-test-26-99b78c49@example.com	Performance User 26	password	\N	\N	t	2025-08-22 16:56:17.900119+07	2025-08-22 16:56:17.900119+07	99b78c49-16ff-4ea7-b2a5-e884a972cba5	\N	["guest"]	pending	\N	\N
perf-test-27-0f4327d8@example.com	Performance User 27	password	\N	\N	t	2025-08-22 16:56:17.900678+07	2025-08-22 16:56:17.900678+07	0f4327d8-3fc9-4349-b96d-70ba35384f00	\N	["guest"]	pending	\N	\N
perf-test-28-f0f851ca@example.com	Performance User 28	password	\N	\N	t	2025-08-22 16:56:17.901133+07	2025-08-22 16:56:17.901133+07	f0f851ca-d93b-45c0-ab74-8d0fbb3ba93b	\N	["guest"]	pending	\N	\N
perf-test-29-49b46b72@example.com	Performance User 29	password	\N	\N	t	2025-08-22 16:56:17.901639+07	2025-08-22 16:56:17.901639+07	49b46b72-4efb-4b33-ba3e-57e65a61d173	\N	["guest"]	pending	\N	\N
perf-test-30-d7f0ecd4@example.com	Performance User 30	password	\N	\N	t	2025-08-22 16:56:17.902112+07	2025-08-22 16:56:17.902112+07	d7f0ecd4-2868-4872-ac6c-ac6e2b91f974	\N	["guest"]	pending	\N	\N
perf-test-31-e6bce452@example.com	Performance User 31	password	\N	\N	t	2025-08-22 16:56:17.902552+07	2025-08-22 16:56:17.902552+07	e6bce452-690d-4cf1-b7d8-f6ce6ead8a36	\N	["guest"]	pending	\N	\N
perf-test-32-9e99e985@example.com	Performance User 32	password	\N	\N	t	2025-08-22 16:56:17.902957+07	2025-08-22 16:56:17.902957+07	9e99e985-d80c-4506-909b-1e464306c62b	\N	["guest"]	pending	\N	\N
perf-test-33-0d5ce058@example.com	Performance User 33	password	\N	\N	t	2025-08-22 16:56:17.90348+07	2025-08-22 16:56:17.90348+07	0d5ce058-6e00-48c1-85cf-cf2be3bd48f4	\N	["guest"]	pending	\N	\N
perf-test-34-e382488b@example.com	Performance User 34	password	\N	\N	t	2025-08-22 16:56:17.904405+07	2025-08-22 16:56:17.904405+07	e382488b-9b9c-421e-9ea4-fd8e99f7723f	\N	["guest"]	pending	\N	\N
perf-test-35-f1e1a658@example.com	Performance User 35	password	\N	\N	t	2025-08-22 16:56:17.906194+07	2025-08-22 16:56:17.906194+07	f1e1a658-cba3-4126-b896-d5f7deafa0bd	\N	["guest"]	pending	\N	\N
perf-test-36-40769ce6@example.com	Performance User 36	password	\N	\N	t	2025-08-22 16:56:17.907652+07	2025-08-22 16:56:17.907653+07	40769ce6-0d0e-4028-9329-1d3291c6a5a4	\N	["guest"]	pending	\N	\N
perf-test-37-f17f036f@example.com	Performance User 37	password	\N	\N	t	2025-08-22 16:56:17.908532+07	2025-08-22 16:56:17.908533+07	f17f036f-c5f1-4e1a-bca3-b77d134bd8cd	\N	["guest"]	pending	\N	\N
perf-test-38-c30f78fa@example.com	Performance User 38	password	\N	\N	t	2025-08-22 16:56:17.909197+07	2025-08-22 16:56:17.909198+07	c30f78fa-00fb-4d87-bf1c-0b1d2f99e87d	\N	["guest"]	pending	\N	\N
perf-test-39-1a7fc523@example.com	Performance User 39	password	\N	\N	t	2025-08-22 16:56:17.909987+07	2025-08-22 16:56:17.909987+07	1a7fc523-c40b-4b08-9b9b-7ec652290537	\N	["guest"]	pending	\N	\N
perf-test-40-284e031b@example.com	Performance User 40	password	\N	\N	t	2025-08-22 16:56:17.910645+07	2025-08-22 16:56:17.910645+07	284e031b-0d92-444f-9f1f-317db0ed20ec	\N	["guest"]	pending	\N	\N
perf-test-41-c0a5e14d@example.com	Performance User 41	password	\N	\N	t	2025-08-22 16:56:17.911373+07	2025-08-22 16:56:17.911373+07	c0a5e14d-8eb9-4ab2-933c-fc720c9db869	\N	["guest"]	pending	\N	\N
perf-test-42-7cc1b82c@example.com	Performance User 42	password	\N	\N	t	2025-08-22 16:56:17.912069+07	2025-08-22 16:56:17.912069+07	7cc1b82c-85ba-4938-bdab-3830c4cd5db1	\N	["guest"]	pending	\N	\N
perf-test-43-b29bc189@example.com	Performance User 43	password	\N	\N	t	2025-08-22 16:56:17.9127+07	2025-08-22 16:56:17.912701+07	b29bc189-79e7-40b1-9233-8fc0608549c1	\N	["guest"]	pending	\N	\N
perf-test-44-dc0adbc8@example.com	Performance User 44	password	\N	\N	t	2025-08-22 16:56:17.913259+07	2025-08-22 16:56:17.913259+07	dc0adbc8-d368-4f11-93b9-45337ac7069e	\N	["guest"]	pending	\N	\N
perf-test-45-ad2eb2a6@example.com	Performance User 45	password	\N	\N	t	2025-08-22 16:56:17.913747+07	2025-08-22 16:56:17.913748+07	ad2eb2a6-a32a-443a-8657-df20523cd315	\N	["guest"]	pending	\N	\N
perf-test-46-25c24045@example.com	Performance User 46	password	\N	\N	t	2025-08-22 16:56:17.914211+07	2025-08-22 16:56:17.914211+07	25c24045-f6c1-4f6f-bca3-248c49178246	\N	["guest"]	pending	\N	\N
perf-test-47-726397f7@example.com	Performance User 47	password	\N	\N	t	2025-08-22 16:56:17.914681+07	2025-08-22 16:56:17.914681+07	726397f7-e151-419e-83e9-98cfc192c9db	\N	["guest"]	pending	\N	\N
perf-test-48-abaa37cd@example.com	Performance User 48	password	\N	\N	t	2025-08-22 16:56:17.915081+07	2025-08-22 16:56:17.915081+07	abaa37cd-9699-46d9-b73c-02c992de6719	\N	["guest"]	pending	\N	\N
perf-test-49-ba683eea@example.com	Performance User 49	password	\N	\N	t	2025-08-22 16:56:17.915453+07	2025-08-22 16:56:17.915453+07	ba683eea-84c1-4950-b6ff-c24fa2b8fd60	\N	["guest"]	pending	\N	\N
user-3-ad70f36a@example.com	User 3	hashedpassword	\N	\N	t	2025-08-22 17:35:45.198118+07	2025-08-22 17:35:45.198118+07	ad70f36a-8323-41f2-9ec1-ed023b883514	\N	["guest"]	pending	\N	\N
user-4-82765553@example.com	User 4	hashedpassword	\N	\N	t	2025-08-22 17:35:45.201766+07	2025-08-22 17:35:45.201766+07	82765553-20a0-4c8d-8c35-6fa5d89835d6	\N	["guest"]	pending	\N	\N
user-7-e7c3bd79@example.com	User 7	hashedpassword	\N	\N	t	2025-08-22 17:35:45.203011+07	2025-08-22 17:35:45.203011+07	e7c3bd79-da42-46ed-8345-61bbfa8a1d49	\N	["guest"]	pending	\N	\N
user-10-561d6d8a@example.com	User 10	hashedpassword	\N	\N	t	2025-08-22 17:35:45.207017+07	2025-08-22 17:35:45.207017+07	561d6d8a-9c2a-44b7-a618-6d7de55249e0	\N	["guest"]	pending	\N	\N
user-12-ffe6514f@example.com	User 12	hashedpassword	\N	\N	t	2025-08-22 17:35:45.207736+07	2025-08-22 17:35:45.207736+07	ffe6514f-51c8-4db3-a1ba-5aa638191b36	\N	["guest"]	pending	\N	\N
user-21-8c348da1@example.com	User 21	hashedpassword	\N	\N	t	2025-08-22 17:35:45.211071+07	2025-08-22 17:35:45.211071+07	8c348da1-19d2-4725-814b-bf7feab24086	\N	["guest"]	pending	\N	\N
user-22-c5421c62@example.com	User 22	hashedpassword	\N	\N	t	2025-08-22 17:35:45.211451+07	2025-08-22 17:35:45.211451+07	c5421c62-ef94-43db-8a0b-86709e3094fe	\N	["guest"]	pending	\N	\N
user-27-0ac6d166@example.com	User 27	hashedpassword	\N	\N	t	2025-08-22 17:35:45.213308+07	2025-08-22 17:35:45.213308+07	0ac6d166-e034-4d37-ad51-f704266e5b26	\N	["guest"]	pending	\N	\N
user-28-71ee0c63@example.com	User 28	hashedpassword	\N	\N	t	2025-08-22 17:35:45.214005+07	2025-08-22 17:35:45.214005+07	71ee0c63-f8c0-4528-8165-5c2f4a9d2e5c	\N	["guest"]	pending	\N	\N
user-30-7658d828@example.com	User 30	hashedpassword	\N	\N	t	2025-08-22 17:35:45.215112+07	2025-08-22 17:35:45.215112+07	7658d828-216c-408c-97b6-05839b878613	\N	["guest"]	pending	\N	\N
user-31-1690d223@example.com	User 31	hashedpassword	\N	\N	t	2025-08-22 17:35:45.215519+07	2025-08-22 17:35:45.215519+07	1690d223-958c-41d4-8ee1-8f25d33504c7	\N	["guest"]	pending	\N	\N
user-41-374e5250@example.com	User 41	hashedpassword	\N	\N	t	2025-08-22 17:35:45.219533+07	2025-08-22 17:35:45.219533+07	374e5250-1a06-4329-ab02-4383ecfb98ea	\N	["guest"]	pending	\N	\N
user-42-830fda8b@example.com	User 42	hashedpassword	\N	\N	t	2025-08-22 17:35:45.219921+07	2025-08-22 17:35:45.219921+07	830fda8b-7443-419c-99bd-6c6869a42b58	\N	["guest"]	pending	\N	\N
user-43-6a65311e@example.com	User 43	hashedpassword	\N	\N	t	2025-08-22 17:35:45.220279+07	2025-08-22 17:35:45.220279+07	6a65311e-e814-418d-84b1-ba53e4ffc93f	\N	["guest"]	pending	\N	\N
user-57-214b2560@example.com	User 57	hashedpassword	\N	\N	t	2025-08-22 17:35:45.226227+07	2025-08-22 17:35:45.226227+07	214b2560-c097-4926-bf48-49917432eb2a	\N	["guest"]	pending	\N	\N
user-61-cbe6c74a@example.com	User 61	hashedpassword	\N	\N	t	2025-08-22 17:35:45.227769+07	2025-08-22 17:35:45.227769+07	cbe6c74a-fee5-4f24-938b-d200209a193e	\N	["guest"]	pending	\N	\N
user-63-c2f22ff4@example.com	User 63	hashedpassword	\N	\N	t	2025-08-22 17:35:45.228524+07	2025-08-22 17:35:45.228524+07	c2f22ff4-827c-4cbe-9023-625a96018b4b	\N	["guest"]	pending	\N	\N
user-66-c76bcf73@example.com	User 66	hashedpassword	\N	\N	t	2025-08-22 17:35:45.230191+07	2025-08-22 17:35:45.230192+07	c76bcf73-59d3-4102-a984-f3c4a800cfb7	\N	["guest"]	pending	\N	\N
user-68-df85c9f0@example.com	User 68	hashedpassword	\N	\N	t	2025-08-22 17:35:45.231033+07	2025-08-22 17:35:45.231033+07	df85c9f0-ace7-436c-a40d-2a17008d1e69	\N	["guest"]	pending	\N	\N
user-70-5a49c900@example.com	User 70	hashedpassword	\N	\N	t	2025-08-22 17:35:45.231812+07	2025-08-22 17:35:45.231812+07	5a49c900-73ce-4f9e-9a1a-f95f46f5dae4	\N	["guest"]	pending	\N	\N
user-78-43f6aae2@example.com	User 78	hashedpassword	\N	\N	t	2025-08-22 17:35:45.234742+07	2025-08-22 17:35:45.234742+07	43f6aae2-5111-4e12-8020-6fac287ba8d0	\N	["guest"]	pending	\N	\N
user-80-77cf2f8e@example.com	User 80	hashedpassword	\N	\N	t	2025-08-22 17:35:45.235486+07	2025-08-22 17:35:45.235486+07	77cf2f8e-9a35-4f1c-963a-e9b7047edb77	\N	["guest"]	pending	\N	\N
user-83-5fbebb1c@example.com	User 83	hashedpassword	\N	\N	t	2025-08-22 17:35:45.236573+07	2025-08-22 17:35:45.236573+07	5fbebb1c-7137-49dd-a364-2d70fb929c3a	\N	["guest"]	pending	\N	\N
user-85-12bee78d@example.com	User 85	hashedpassword	\N	\N	t	2025-08-22 17:35:45.237697+07	2025-08-22 17:35:45.237697+07	12bee78d-cf6c-44c3-9dfc-70aff29a7e59	\N	["guest"]	pending	\N	\N
user-91-c14aa7e2@example.com	User 91	hashedpassword	\N	\N	t	2025-08-22 17:35:45.240469+07	2025-08-22 17:35:45.240469+07	c14aa7e2-dd0f-4107-ac8e-93dbf6d38e46	\N	["guest"]	pending	\N	\N
user-92-6c103393@example.com	User 92	hashedpassword	\N	\N	t	2025-08-22 17:35:45.240854+07	2025-08-22 17:35:45.240854+07	6c103393-d5ce-4f43-8356-f7b4830802b7	\N	["guest"]	pending	\N	\N
concurrent-user-3-29fa28d4@example.com	Concurrent User 3	password	\N	\N	t	2025-08-22 17:35:45.432937+07	2025-08-22 17:35:45.432937+07	29fa28d4-b177-4949-8f0c-04e021dd09c3	\N	["guest"]	pending	\N	\N
perf-test-0-3010e83d@example.com	Performance User 0	password	\N	\N	t	2025-08-22 17:35:45.621289+07	2025-08-22 17:35:45.621289+07	3010e83d-ed58-4052-836e-1a5adac6346c	\N	["guest"]	pending	\N	\N
perf-test-1-62a81768@example.com	Performance User 1	password	\N	\N	t	2025-08-22 17:35:45.621767+07	2025-08-22 17:35:45.621768+07	62a81768-5a88-4153-a565-1077bf011aee	\N	["guest"]	pending	\N	\N
perf-test-2-908c5dd0@example.com	Performance User 2	password	\N	\N	t	2025-08-22 17:35:45.622188+07	2025-08-22 17:35:45.622188+07	908c5dd0-4064-4280-bdc0-529718b82c19	\N	["guest"]	pending	\N	\N
perf-test-3-2b27fe2f@example.com	Performance User 3	password	\N	\N	t	2025-08-22 17:35:45.622596+07	2025-08-22 17:35:45.622596+07	2b27fe2f-ec08-4449-910f-aef58c721ef3	\N	["guest"]	pending	\N	\N
perf-test-4-83b0ad01@example.com	Performance User 4	password	\N	\N	t	2025-08-22 17:35:45.622995+07	2025-08-22 17:35:45.622995+07	83b0ad01-4b0e-474f-bd3b-6bacdc77ca14	\N	["guest"]	pending	\N	\N
perf-test-5-543bbdce@example.com	Performance User 5	password	\N	\N	t	2025-08-22 17:35:45.62338+07	2025-08-22 17:35:45.62338+07	543bbdce-5200-472e-93ed-87469d3dc631	\N	["guest"]	pending	\N	\N
perf-test-6-fa2f7f5a@example.com	Performance User 6	password	\N	\N	t	2025-08-22 17:35:45.623816+07	2025-08-22 17:35:45.623816+07	fa2f7f5a-7217-43bf-bd4b-b8daf0eea9e1	\N	["guest"]	pending	\N	\N
perf-test-7-bba988f0@example.com	Performance User 7	password	\N	\N	t	2025-08-22 17:35:45.624521+07	2025-08-22 17:35:45.624521+07	bba988f0-4945-40d9-8591-6f377cd3d47b	\N	["guest"]	pending	\N	\N
perf-test-8-ae395e4b@example.com	Performance User 8	password	\N	\N	t	2025-08-22 17:35:45.625877+07	2025-08-22 17:35:45.625878+07	ae395e4b-ba54-460f-9618-2d46c79d7da8	\N	["guest"]	pending	\N	\N
perf-test-9-64f6398c@example.com	Performance User 9	password	\N	\N	t	2025-08-22 17:35:45.626699+07	2025-08-22 17:35:45.626699+07	64f6398c-ae05-4432-9e3b-c0848a95ffb3	\N	["guest"]	pending	\N	\N
perf-test-10-d2a0178f@example.com	Performance User 10	password	\N	\N	t	2025-08-22 17:35:45.627267+07	2025-08-22 17:35:45.627267+07	d2a0178f-e42b-4129-8e62-ea1e465f79c4	\N	["guest"]	pending	\N	\N
perf-test-11-1cbf1ce0@example.com	Performance User 11	password	\N	\N	t	2025-08-22 17:35:45.62782+07	2025-08-22 17:35:45.62782+07	1cbf1ce0-6169-45ad-bdce-eb256b843c5f	\N	["guest"]	pending	\N	\N
perf-test-12-15b10d53@example.com	Performance User 12	password	\N	\N	t	2025-08-22 17:35:45.628255+07	2025-08-22 17:35:45.628255+07	15b10d53-e3c3-4de5-b818-e5525ff865b4	\N	["guest"]	pending	\N	\N
perf-test-13-626e91f1@example.com	Performance User 13	password	\N	\N	t	2025-08-22 17:35:45.628663+07	2025-08-22 17:35:45.628663+07	626e91f1-3c82-4f42-b4c7-c36a39935a10	\N	["guest"]	pending	\N	\N
perf-test-14-3c1242c3@example.com	Performance User 14	password	\N	\N	t	2025-08-22 17:35:45.629121+07	2025-08-22 17:35:45.629121+07	3c1242c3-5330-46d6-9b68-20be599823e2	\N	["guest"]	pending	\N	\N
perf-test-15-f93210dd@example.com	Performance User 15	password	\N	\N	t	2025-08-22 17:35:45.629506+07	2025-08-22 17:35:45.629506+07	f93210dd-c0ce-4542-b4dd-8f98e7da10d3	\N	["guest"]	pending	\N	\N
perf-test-16-6c4045b8@example.com	Performance User 16	password	\N	\N	t	2025-08-22 17:35:45.629904+07	2025-08-22 17:35:45.629904+07	6c4045b8-7630-4167-a6f1-173649cfa849	\N	["guest"]	pending	\N	\N
perf-test-17-3b912909@example.com	Performance User 17	password	\N	\N	t	2025-08-22 17:35:45.630276+07	2025-08-22 17:35:45.630276+07	3b912909-4c11-49e5-8eed-98c3c171f95a	\N	["guest"]	pending	\N	\N
perf-test-18-ae238465@example.com	Performance User 18	password	\N	\N	t	2025-08-22 17:35:45.63066+07	2025-08-22 17:35:45.63066+07	ae238465-023e-4898-92ff-3caf927a83c8	\N	["guest"]	pending	\N	\N
perf-test-19-a40237da@example.com	Performance User 19	password	\N	\N	t	2025-08-22 17:35:45.631067+07	2025-08-22 17:35:45.631067+07	a40237da-8047-4c70-9dfc-ababed67163c	\N	["guest"]	pending	\N	\N
perf-test-20-37d4b6fc@example.com	Performance User 20	password	\N	\N	t	2025-08-22 17:35:45.631448+07	2025-08-22 17:35:45.631448+07	37d4b6fc-a9b4-45ad-9d31-f936e38e8772	\N	["guest"]	pending	\N	\N
perf-test-21-dc83e120@example.com	Performance User 21	password	\N	\N	t	2025-08-22 17:35:45.631837+07	2025-08-22 17:35:45.631837+07	dc83e120-77df-4323-9704-f3ca58fa02a0	\N	["guest"]	pending	\N	\N
perf-test-22-487dbcb7@example.com	Performance User 22	password	\N	\N	t	2025-08-22 17:35:45.632376+07	2025-08-22 17:35:45.632376+07	487dbcb7-be3b-44af-97ea-90a475749dd8	\N	["guest"]	pending	\N	\N
perf-test-23-164fd0e8@example.com	Performance User 23	password	\N	\N	t	2025-08-22 17:35:45.633162+07	2025-08-22 17:35:45.633162+07	164fd0e8-60a2-413e-9fc8-0d8742349155	\N	["guest"]	pending	\N	\N
perf-test-24-d43c4f8c@example.com	Performance User 24	password	\N	\N	t	2025-08-22 17:35:45.63357+07	2025-08-22 17:35:45.63357+07	d43c4f8c-38d4-41ff-8572-d79d5fcdde94	\N	["guest"]	pending	\N	\N
perf-test-25-1a75a9bd@example.com	Performance User 25	password	\N	\N	t	2025-08-22 17:35:45.633952+07	2025-08-22 17:35:45.633952+07	1a75a9bd-b7d1-421c-b3f5-4677f3349565	\N	["guest"]	pending	\N	\N
perf-test-26-cc0e4a91@example.com	Performance User 26	password	\N	\N	t	2025-08-22 17:35:45.634305+07	2025-08-22 17:35:45.634305+07	cc0e4a91-74ed-4087-9ea5-a719b2f0a2e6	\N	["guest"]	pending	\N	\N
perf-test-27-28b1ab15@example.com	Performance User 27	password	\N	\N	t	2025-08-22 17:35:45.63467+07	2025-08-22 17:35:45.63467+07	28b1ab15-73c2-4031-b9b3-b02ce1036bc5	\N	["guest"]	pending	\N	\N
perf-test-28-f4c99318@example.com	Performance User 28	password	\N	\N	t	2025-08-22 17:35:45.635009+07	2025-08-22 17:35:45.635009+07	f4c99318-b5f2-4876-861b-0ebc903b7638	\N	["guest"]	pending	\N	\N
perf-test-29-467c4fe8@example.com	Performance User 29	password	\N	\N	t	2025-08-22 17:35:45.635339+07	2025-08-22 17:35:45.635339+07	467c4fe8-f0e2-458b-9c3e-434e6b5df5ea	\N	["guest"]	pending	\N	\N
perf-test-30-f1f86f8f@example.com	Performance User 30	password	\N	\N	t	2025-08-22 17:35:45.635698+07	2025-08-22 17:35:45.635698+07	f1f86f8f-9483-47fa-b8e5-02b6da29a52c	\N	["guest"]	pending	\N	\N
perf-test-31-086a11e3@example.com	Performance User 31	password	\N	\N	t	2025-08-22 17:35:45.636069+07	2025-08-22 17:35:45.636069+07	086a11e3-02a9-44ed-b5c6-20dd99172a0d	\N	["guest"]	pending	\N	\N
perf-test-32-3006924b@example.com	Performance User 32	password	\N	\N	t	2025-08-22 17:35:45.636443+07	2025-08-22 17:35:45.636443+07	3006924b-4318-4e25-a15a-e5473842441a	\N	["guest"]	pending	\N	\N
perf-test-33-5072459b@example.com	Performance User 33	password	\N	\N	t	2025-08-22 17:35:45.636798+07	2025-08-22 17:35:45.636798+07	5072459b-3a41-4615-bf8f-7f1c2a96e2b2	\N	["guest"]	pending	\N	\N
perf-test-34-979b887c@example.com	Performance User 34	password	\N	\N	t	2025-08-22 17:35:45.637135+07	2025-08-22 17:35:45.637135+07	979b887c-024e-4c36-a478-38b99fb413a0	\N	["guest"]	pending	\N	\N
perf-test-35-40461e21@example.com	Performance User 35	password	\N	\N	t	2025-08-22 17:35:45.6375+07	2025-08-22 17:35:45.6375+07	40461e21-82de-43b6-88c9-e5a354e3dc35	\N	["guest"]	pending	\N	\N
perf-test-36-a571df0a@example.com	Performance User 36	password	\N	\N	t	2025-08-22 17:35:45.637828+07	2025-08-22 17:35:45.637828+07	a571df0a-f2a1-4c8c-aab2-4bfc98a558c1	\N	["guest"]	pending	\N	\N
perf-test-37-65344d3f@example.com	Performance User 37	password	\N	\N	t	2025-08-22 17:35:45.638166+07	2025-08-22 17:35:45.638166+07	65344d3f-6dd0-4ca9-938d-213809d7ab67	\N	["guest"]	pending	\N	\N
perf-test-38-691a71d2@example.com	Performance User 38	password	\N	\N	t	2025-08-22 17:35:45.638522+07	2025-08-22 17:35:45.638522+07	691a71d2-335b-45d8-a5da-e2472cae8097	\N	["guest"]	pending	\N	\N
perf-test-39-fba931a1@example.com	Performance User 39	password	\N	\N	t	2025-08-22 17:35:45.638875+07	2025-08-22 17:35:45.638875+07	fba931a1-30fc-4d2c-8cf0-e3945221b68d	\N	["guest"]	pending	\N	\N
perf-test-40-054452b0@example.com	Performance User 40	password	\N	\N	t	2025-08-22 17:35:45.639277+07	2025-08-22 17:35:45.639277+07	054452b0-fa98-4844-a589-9cae39b54a9e	\N	["guest"]	pending	\N	\N
perf-test-41-5f8444ba@example.com	Performance User 41	password	\N	\N	t	2025-08-22 17:35:45.639615+07	2025-08-22 17:35:45.639615+07	5f8444ba-6a6d-4fb6-8bf4-93fba39f8d20	\N	["guest"]	pending	\N	\N
perf-test-42-45fc22d8@example.com	Performance User 42	password	\N	\N	t	2025-08-22 17:35:45.640003+07	2025-08-22 17:35:45.640003+07	45fc22d8-ad52-4559-9314-0ea3474a2a3c	\N	["guest"]	pending	\N	\N
perf-test-43-3832f183@example.com	Performance User 43	password	\N	\N	t	2025-08-22 17:35:45.640621+07	2025-08-22 17:35:45.640621+07	3832f183-4428-4591-965e-ed73693b61e7	\N	["guest"]	pending	\N	\N
perf-test-44-6ddaa3e9@example.com	Performance User 44	password	\N	\N	t	2025-08-22 17:35:45.64125+07	2025-08-22 17:35:45.64125+07	6ddaa3e9-6bb8-4977-970a-e2fc87bbd084	\N	["guest"]	pending	\N	\N
perf-test-45-9aa89429@example.com	Performance User 45	password	\N	\N	t	2025-08-22 17:35:45.641659+07	2025-08-22 17:35:45.641659+07	9aa89429-fbe8-404d-b552-3a5e2a50533b	\N	["guest"]	pending	\N	\N
perf-test-46-8784209e@example.com	Performance User 46	password	\N	\N	t	2025-08-22 17:35:45.642084+07	2025-08-22 17:35:45.642084+07	8784209e-5abb-4e89-b79a-10155baf221c	\N	["guest"]	pending	\N	\N
perf-test-47-0892d15d@example.com	Performance User 47	password	\N	\N	t	2025-08-22 17:35:45.642476+07	2025-08-22 17:35:45.642476+07	0892d15d-b4e9-43bd-ac4a-a6c95a487866	\N	["guest"]	pending	\N	\N
perf-test-48-ee6ab058@example.com	Performance User 48	password	\N	\N	t	2025-08-22 17:35:45.642848+07	2025-08-22 17:35:45.642848+07	ee6ab058-4585-4afe-872c-211b31a02f8a	\N	["guest"]	pending	\N	\N
perf-test-49-44436db2@example.com	Performance User 49	password	\N	\N	t	2025-08-22 17:35:45.643214+07	2025-08-22 17:35:45.643214+07	44436db2-208d-4b27-8857-a418f6063765	\N	["guest"]	pending	\N	\N
user-1-e2dd729f@example.com	User 1	hashedpassword	\N	\N	t	2025-08-29 20:22:55.12279+07	2025-08-29 20:22:55.12279+07	e2dd729f-6aab-4f6d-8886-431ed84cfbaa	\N	["guest"]	pending	\N	\N
user-10-57b7958c@example.com	User 10	hashedpassword	\N	\N	t	2025-08-29 20:22:55.155928+07	2025-08-29 20:22:55.155928+07	57b7958c-c804-4a80-af89-77d0eb19718e	\N	["guest"]	pending	\N	\N
user-16-1b4462b2@example.com	User 16	hashedpassword	\N	\N	t	2025-08-29 20:22:55.15998+07	2025-08-29 20:22:55.15998+07	1b4462b2-4afa-4f4d-a51f-e629f99ac48a	\N	["guest"]	pending	\N	\N
user-21-d866895a@example.com	User 21	hashedpassword	\N	\N	t	2025-08-29 20:22:55.1644+07	2025-08-29 20:22:55.1644+07	d866895a-861e-483f-a05e-87073c67a000	\N	["guest"]	pending	\N	\N
user-29-6c0f5cdd@example.com	User 29	hashedpassword	\N	\N	t	2025-08-29 20:22:55.16859+07	2025-08-29 20:22:55.16859+07	6c0f5cdd-a5f0-4e4f-8a58-6da25f66c4b9	\N	["guest"]	pending	\N	\N
user-33-a2d4db77@example.com	User 33	hashedpassword	\N	\N	t	2025-08-29 20:22:55.171056+07	2025-08-29 20:22:55.171056+07	a2d4db77-8c00-4e55-9e76-e9da9a8d5709	\N	["guest"]	pending	\N	\N
user-35-068effeb@example.com	User 35	hashedpassword	\N	\N	t	2025-08-29 20:22:55.172128+07	2025-08-29 20:22:55.172128+07	068effeb-6d8a-47d1-9427-5619a733dae0	\N	["guest"]	pending	\N	\N
user-36-7973e8f0@example.com	User 36	hashedpassword	\N	\N	t	2025-08-29 20:22:55.172549+07	2025-08-29 20:22:55.172549+07	7973e8f0-cd6e-49ce-81d5-1941800fe1bd	\N	["guest"]	pending	\N	\N
user-40-6404e615@example.com	User 40	hashedpassword	\N	\N	t	2025-08-29 20:22:55.174272+07	2025-08-29 20:22:55.174272+07	6404e615-4801-4794-8bc2-ec53dbbed3e8	\N	["guest"]	pending	\N	\N
user-44-80e5e9fa@example.com	User 44	hashedpassword	\N	\N	t	2025-08-29 20:22:55.176524+07	2025-08-29 20:22:55.176525+07	80e5e9fa-2807-4b3a-afc7-7ad1cfbae0cd	\N	["guest"]	pending	\N	\N
user-45-de1b548d@example.com	User 45	hashedpassword	\N	\N	t	2025-08-29 20:22:55.17794+07	2025-08-29 20:22:55.17794+07	de1b548d-8287-49e9-be53-b2df6648e7ef	\N	["guest"]	pending	\N	\N
user-52-1a409324@example.com	User 52	hashedpassword	\N	\N	t	2025-08-29 20:22:55.182037+07	2025-08-29 20:22:55.182037+07	1a409324-a823-4381-a4e9-fe6ed0e7ee89	\N	["guest"]	pending	\N	\N
user-54-e152e9fe@example.com	User 54	hashedpassword	\N	\N	t	2025-08-29 20:22:55.18278+07	2025-08-29 20:22:55.18278+07	e152e9fe-bb5e-42e0-a108-918608dc55d5	\N	["guest"]	pending	\N	\N
user-62-ad9387e2@example.com	User 62	hashedpassword	\N	\N	t	2025-08-29 20:22:55.187158+07	2025-08-29 20:22:55.187158+07	ad9387e2-bca0-4590-a7f2-e5a78527ec10	\N	["guest"]	pending	\N	\N
user-63-19868080@example.com	User 63	hashedpassword	\N	\N	t	2025-08-29 20:22:55.187748+07	2025-08-29 20:22:55.187748+07	19868080-4ae9-4ce8-843c-10b319e20e81	\N	["guest"]	pending	\N	\N
user-64-c600222a@example.com	User 64	hashedpassword	\N	\N	t	2025-08-29 20:22:55.188277+07	2025-08-29 20:22:55.188277+07	c600222a-c3e5-4847-baa3-38f395f94874	\N	["guest"]	pending	\N	\N
user-73-a8f833e4@example.com	User 73	hashedpassword	\N	\N	t	2025-08-29 20:22:55.193703+07	2025-08-29 20:22:55.193703+07	a8f833e4-574a-4326-b710-4550efe02c63	\N	["guest"]	pending	\N	\N
user-74-2e0e5e6b@example.com	User 74	hashedpassword	\N	\N	t	2025-08-29 20:22:55.194891+07	2025-08-29 20:22:55.194892+07	2e0e5e6b-5cb8-4e6f-8079-21f0909207e6	\N	["guest"]	pending	\N	\N
user-82-fc64bd30@example.com	User 82	hashedpassword	\N	\N	t	2025-08-29 20:22:55.199506+07	2025-08-29 20:22:55.199506+07	fc64bd30-95d9-46bf-973e-6942d06f3b67	\N	["guest"]	pending	\N	\N
user-87-3ee2723e@example.com	User 87	hashedpassword	\N	\N	t	2025-08-29 20:22:55.20182+07	2025-08-29 20:22:55.20182+07	3ee2723e-8eae-4977-abe1-4daa4a9759a6	\N	["guest"]	pending	\N	\N
user-89-f9323182@example.com	User 89	hashedpassword	\N	\N	t	2025-08-29 20:22:55.203063+07	2025-08-29 20:22:55.203064+07	f9323182-63f4-43f1-94ab-9383d2bb990f	\N	["guest"]	pending	\N	\N
user-90-e1e5197e@example.com	User 90	hashedpassword	\N	\N	t	2025-08-29 20:22:55.20369+07	2025-08-29 20:22:55.20369+07	e1e5197e-2009-4976-ac11-192e077f7cd6	\N	["guest"]	pending	\N	\N
user-91-3ec280dc@example.com	User 91	hashedpassword	\N	\N	t	2025-08-29 20:22:55.204265+07	2025-08-29 20:22:55.204266+07	3ec280dc-3738-4784-9edd-c4dcc41c97b9	\N	["guest"]	pending	\N	\N
user-94-c4601374@example.com	User 94	hashedpassword	\N	\N	t	2025-08-29 20:22:55.205689+07	2025-08-29 20:22:55.20569+07	c4601374-0562-461d-8bf4-a5ce451bbdbb	\N	["guest"]	pending	\N	\N
user-97-89552046@example.com	User 97	hashedpassword	\N	\N	t	2025-08-29 20:22:55.206932+07	2025-08-29 20:22:55.206932+07	89552046-c09e-4c28-b0a1-7cc7f7a0b0e2	\N	["guest"]	pending	\N	\N
user-99-2e9e9611@example.com	User 99	hashedpassword	\N	\N	t	2025-08-29 20:22:55.207811+07	2025-08-29 20:22:55.207811+07	2e9e9611-68aa-4ad3-800a-a91807c1ef85	\N	["guest"]	pending	\N	\N
concurrent-user-3-22ae5951@example.com	Concurrent User 3	password	\N	\N	t	2025-08-29 20:22:55.469358+07	2025-08-29 20:22:55.469358+07	22ae5951-123e-4b75-ab28-7ab24db4e4f7	\N	["guest"]	pending	\N	\N
perf-test-0-793c98b2@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:22:55.693772+07	2025-08-29 20:22:55.693772+07	793c98b2-f756-43e6-a1d5-57bc2a0134b7	\N	["guest"]	pending	\N	\N
perf-test-1-3b44385a@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:22:55.694959+07	2025-08-29 20:22:55.694959+07	3b44385a-0234-49d7-8dcf-cf2f9b8ec45b	\N	["guest"]	pending	\N	\N
perf-test-2-d823b27a@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:22:55.695752+07	2025-08-29 20:22:55.695752+07	d823b27a-f05f-4652-bfcc-b8ed98b5bef4	\N	["guest"]	pending	\N	\N
perf-test-3-b245b85f@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:22:55.696451+07	2025-08-29 20:22:55.696451+07	b245b85f-8d03-4d94-b917-fe5cd0ccfd8e	\N	["guest"]	pending	\N	\N
perf-test-4-fdfde984@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:22:55.696978+07	2025-08-29 20:22:55.696979+07	fdfde984-e4f3-4e07-bb15-12b82202be4c	\N	["guest"]	pending	\N	\N
perf-test-5-fbad3253@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:22:55.697419+07	2025-08-29 20:22:55.697419+07	fbad3253-77bc-4b74-a72e-678cd851729b	\N	["guest"]	pending	\N	\N
perf-test-6-81a455f1@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:22:55.697791+07	2025-08-29 20:22:55.697791+07	81a455f1-b2b0-46a7-9d03-3ad5d1d9ad2e	\N	["guest"]	pending	\N	\N
perf-test-7-31b33706@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:22:55.698293+07	2025-08-29 20:22:55.698293+07	31b33706-2667-4e57-a134-7f20ed23e384	\N	["guest"]	pending	\N	\N
perf-test-8-27d24f3b@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:22:55.69865+07	2025-08-29 20:22:55.698651+07	27d24f3b-b78e-47d2-b0e7-6fa87aea1d4e	\N	["guest"]	pending	\N	\N
perf-test-9-fb9714ae@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:22:55.699142+07	2025-08-29 20:22:55.699142+07	fb9714ae-a170-4b99-8680-28cd02edfed5	\N	["guest"]	pending	\N	\N
perf-test-10-baa3b1c1@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:22:55.699537+07	2025-08-29 20:22:55.699537+07	baa3b1c1-51bc-44cf-8292-57269b8c22a4	\N	["guest"]	pending	\N	\N
perf-test-11-d783bdbc@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:22:55.699914+07	2025-08-29 20:22:55.699914+07	d783bdbc-bfea-45d7-aa80-09309ad5667c	\N	["guest"]	pending	\N	\N
perf-test-12-5ada1fd7@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:22:55.700314+07	2025-08-29 20:22:55.700314+07	5ada1fd7-23e9-4f9a-883f-528dad1a399e	\N	["guest"]	pending	\N	\N
perf-test-13-992775e0@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:22:55.700916+07	2025-08-29 20:22:55.700916+07	992775e0-0ff9-46c0-b4dc-daea37a8236d	\N	["guest"]	pending	\N	\N
perf-test-14-d048b703@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:22:55.701334+07	2025-08-29 20:22:55.701334+07	d048b703-869b-4647-9c6c-e22a55ce1d3a	\N	["guest"]	pending	\N	\N
perf-test-15-a8f10bca@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:22:55.701772+07	2025-08-29 20:22:55.701772+07	a8f10bca-8999-41c1-93b9-a91c98bcde0a	\N	["guest"]	pending	\N	\N
perf-test-16-7d93a0cc@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:22:55.702176+07	2025-08-29 20:22:55.702176+07	7d93a0cc-e62e-480b-9142-ae97d8415d27	\N	["guest"]	pending	\N	\N
perf-test-17-be8fa940@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:22:55.702651+07	2025-08-29 20:22:55.702651+07	be8fa940-9d5d-4ba2-b273-2646e727ca48	\N	["guest"]	pending	\N	\N
perf-test-18-1b6185dd@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:22:55.703267+07	2025-08-29 20:22:55.703267+07	1b6185dd-dd2e-48cf-ba53-6ee1b2f513d4	\N	["guest"]	pending	\N	\N
perf-test-19-f480842f@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:22:55.703784+07	2025-08-29 20:22:55.703784+07	f480842f-2045-4e2e-9bff-0299a4a18db6	\N	["guest"]	pending	\N	\N
perf-test-20-5ce4ef8d@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:22:55.7043+07	2025-08-29 20:22:55.7043+07	5ce4ef8d-607c-4c7a-b6c9-870d82e7844f	\N	["guest"]	pending	\N	\N
perf-test-21-84163b82@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:22:55.704775+07	2025-08-29 20:22:55.704776+07	84163b82-f2e3-45c1-be69-a9497f7da286	\N	["guest"]	pending	\N	\N
perf-test-22-f806d3bb@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:22:55.705293+07	2025-08-29 20:22:55.705293+07	f806d3bb-6ef3-4a53-a13d-53b7091d44c7	\N	["guest"]	pending	\N	\N
perf-test-23-5addb320@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:22:55.705696+07	2025-08-29 20:22:55.705696+07	5addb320-667c-4c4d-8003-c5730970f71c	\N	["guest"]	pending	\N	\N
perf-test-24-8bf5afe1@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:22:55.706077+07	2025-08-29 20:22:55.706078+07	8bf5afe1-662e-42d0-ad94-f5c73270cef6	\N	["guest"]	pending	\N	\N
perf-test-25-a5b2b47a@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:22:55.706457+07	2025-08-29 20:22:55.706457+07	a5b2b47a-bead-4e50-907e-82254865fb5d	\N	["guest"]	pending	\N	\N
perf-test-26-786f4045@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:22:55.706833+07	2025-08-29 20:22:55.706833+07	786f4045-ff04-4011-afa1-33765bf02e0b	\N	["guest"]	pending	\N	\N
perf-test-27-ba902e0b@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:22:55.707228+07	2025-08-29 20:22:55.707228+07	ba902e0b-2e43-4eb7-95df-a9f8212de933	\N	["guest"]	pending	\N	\N
perf-test-28-255a19b4@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:22:55.707586+07	2025-08-29 20:22:55.707586+07	255a19b4-972c-4bc8-bee2-a0df9f64e7ef	\N	["guest"]	pending	\N	\N
perf-test-29-7d98ca96@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:22:55.707975+07	2025-08-29 20:22:55.707976+07	7d98ca96-ff4b-4b37-9a7d-de8f5a206c1a	\N	["guest"]	pending	\N	\N
perf-test-30-17071300@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:22:55.70839+07	2025-08-29 20:22:55.70839+07	17071300-ea00-4a3f-ae13-27c727ea5645	\N	["guest"]	pending	\N	\N
perf-test-31-c2a2e259@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:22:55.709155+07	2025-08-29 20:22:55.709155+07	c2a2e259-0d21-4117-a815-e93ce4be9903	\N	["guest"]	pending	\N	\N
perf-test-32-feae6025@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:22:55.709876+07	2025-08-29 20:22:55.709876+07	feae6025-9101-4dd9-9dcb-ebc32c2a6a38	\N	["guest"]	pending	\N	\N
perf-test-33-5fa70815@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:22:55.710489+07	2025-08-29 20:22:55.710489+07	5fa70815-067c-490e-b793-f48f3c1c9e6e	\N	["guest"]	pending	\N	\N
perf-test-34-b87b007c@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:22:55.711086+07	2025-08-29 20:22:55.711086+07	b87b007c-526e-420d-be42-afb457943086	\N	["guest"]	pending	\N	\N
perf-test-35-9f41c39d@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:22:55.711707+07	2025-08-29 20:22:55.711707+07	9f41c39d-6d59-4e33-a662-a7644286eedb	\N	["guest"]	pending	\N	\N
perf-test-36-0c0041cd@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:22:55.712287+07	2025-08-29 20:22:55.712287+07	0c0041cd-0717-4ca7-aafa-106256d08695	\N	["guest"]	pending	\N	\N
perf-test-37-7dc3aecd@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:22:55.712828+07	2025-08-29 20:22:55.712828+07	7dc3aecd-33b8-4274-b4f3-f613c9896b3d	\N	["guest"]	pending	\N	\N
perf-test-38-67f5a992@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:22:55.713354+07	2025-08-29 20:22:55.713354+07	67f5a992-7915-449d-8b17-598b9b6e36fb	\N	["guest"]	pending	\N	\N
perf-test-39-76b16a32@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:22:55.713752+07	2025-08-29 20:22:55.713752+07	76b16a32-f8f1-4b06-82ec-a27c837d8593	\N	["guest"]	pending	\N	\N
perf-test-40-f8f10e13@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:22:55.714122+07	2025-08-29 20:22:55.714122+07	f8f10e13-9c62-4a68-b0cd-5f89f4aaef97	\N	["guest"]	pending	\N	\N
perf-test-41-354fd6fd@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:22:55.714487+07	2025-08-29 20:22:55.714487+07	354fd6fd-2f76-4830-bd4d-6d2840e903e6	\N	["guest"]	pending	\N	\N
perf-test-42-e0ea2732@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:22:55.714856+07	2025-08-29 20:22:55.714856+07	e0ea2732-c099-4e62-8381-483e5cd45a42	\N	["guest"]	pending	\N	\N
perf-test-43-1605aa2f@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:22:55.715213+07	2025-08-29 20:22:55.715213+07	1605aa2f-68e0-4fdb-9d59-c970a4bcf484	\N	["guest"]	pending	\N	\N
perf-test-44-5155df34@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:22:55.71558+07	2025-08-29 20:22:55.715581+07	5155df34-0206-493b-bc99-482f8e49c18b	\N	["guest"]	pending	\N	\N
perf-test-45-cbe17034@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:22:55.715934+07	2025-08-29 20:22:55.715934+07	cbe17034-66e2-4d8d-958e-c14d11c7e859	\N	["guest"]	pending	\N	\N
perf-test-46-3d100f76@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:22:55.71644+07	2025-08-29 20:22:55.71644+07	3d100f76-8ab0-4400-9618-6a5c37fef70d	\N	["guest"]	pending	\N	\N
perf-test-47-42c680f5@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:22:55.716934+07	2025-08-29 20:22:55.716934+07	42c680f5-db5b-4e46-b1f3-1c321f75fd14	\N	["guest"]	pending	\N	\N
perf-test-48-d0def1c7@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:22:55.717583+07	2025-08-29 20:22:55.717583+07	d0def1c7-f979-40b7-add7-fa2f29d7c748	\N	["guest"]	pending	\N	\N
perf-test-49-6828c1e7@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:22:55.718024+07	2025-08-29 20:22:55.718024+07	6828c1e7-c9d2-4cbd-8c42-52b3516a45e1	\N	["guest"]	pending	\N	\N
user-1-2a8e428f@example.com	User 1	hashedpassword	\N	\N	t	2025-08-29 20:59:13.127402+07	2025-08-29 20:59:13.127402+07	2a8e428f-90aa-478f-a740-5c090828dd8f	\N	["guest"]	pending	\N	\N
user-8-3822b37e@example.com	User 8	hashedpassword	\N	\N	t	2025-08-29 20:59:13.141504+07	2025-08-29 20:59:13.141504+07	3822b37e-c996-411c-8c09-66c1aa2c3eea	\N	["guest"]	pending	\N	\N
user-11-f8776e40@example.com	User 11	hashedpassword	\N	\N	t	2025-08-29 20:59:13.144938+07	2025-08-29 20:59:13.144938+07	f8776e40-bfa0-4e8e-bca3-a078bb22657c	\N	["guest"]	pending	\N	\N
user-15-0cec4034@example.com	User 15	hashedpassword	\N	\N	t	2025-08-29 20:59:13.147734+07	2025-08-29 20:59:13.147734+07	0cec4034-7928-4452-92d8-d4e277ff4c56	\N	["guest"]	pending	\N	\N
user-21-321d8b26@example.com	User 21	hashedpassword	\N	\N	t	2025-08-29 20:59:13.15079+07	2025-08-29 20:59:13.15079+07	321d8b26-3396-4503-90cd-3e5defd67aa3	\N	["guest"]	pending	\N	\N
user-22-2bc86334@example.com	User 22	hashedpassword	\N	\N	t	2025-08-29 20:59:13.151186+07	2025-08-29 20:59:13.151186+07	2bc86334-97af-4aa4-bee0-033a8b16ce8d	\N	["guest"]	pending	\N	\N
user-24-b8888f9c@example.com	User 24	hashedpassword	\N	\N	t	2025-08-29 20:59:13.152043+07	2025-08-29 20:59:13.152043+07	b8888f9c-1eb7-4731-819f-7d90fa01f7be	\N	["guest"]	pending	\N	\N
user-30-c4cdd1df@example.com	User 30	hashedpassword	\N	\N	t	2025-08-29 20:59:13.158638+07	2025-08-29 20:59:13.158638+07	c4cdd1df-253d-4a04-99a0-d774453bd32b	\N	["guest"]	pending	\N	\N
user-42-278d575b@example.com	User 42	hashedpassword	\N	\N	t	2025-08-29 20:59:13.166087+07	2025-08-29 20:59:13.166087+07	278d575b-791f-449f-8763-e8bb218a1f3f	\N	["guest"]	pending	\N	\N
user-46-f91664a5@example.com	User 46	hashedpassword	\N	\N	t	2025-08-29 20:59:13.167626+07	2025-08-29 20:59:13.167626+07	f91664a5-4d95-471d-8eca-46b76e591786	\N	["guest"]	pending	\N	\N
user-51-aacc561e@example.com	User 51	hashedpassword	\N	\N	t	2025-08-29 20:59:13.172438+07	2025-08-29 20:59:13.172438+07	aacc561e-1971-4637-957c-2dfb05d02db9	\N	["guest"]	pending	\N	\N
user-52-b0ee156b@example.com	User 52	hashedpassword	\N	\N	t	2025-08-29 20:59:13.173803+07	2025-08-29 20:59:13.173803+07	b0ee156b-c483-4612-ba85-7f531d24c6d8	\N	["guest"]	pending	\N	\N
user-54-a1a88af0@example.com	User 54	hashedpassword	\N	\N	t	2025-08-29 20:59:13.175492+07	2025-08-29 20:59:13.175492+07	a1a88af0-3608-4f2e-a314-4f571c0cb51d	\N	["guest"]	pending	\N	\N
user-56-62ceb813@example.com	User 56	hashedpassword	\N	\N	t	2025-08-29 20:59:13.176744+07	2025-08-29 20:59:13.176744+07	62ceb813-d110-4257-8444-f2b247004d7c	\N	["guest"]	pending	\N	\N
user-58-c0d3f627@example.com	User 58	hashedpassword	\N	\N	t	2025-08-29 20:59:13.178096+07	2025-08-29 20:59:13.178096+07	c0d3f627-749f-4111-aeed-8d73403d66b4	\N	["guest"]	pending	\N	\N
user-59-1624d719@example.com	User 59	hashedpassword	\N	\N	t	2025-08-29 20:59:13.178797+07	2025-08-29 20:59:13.178797+07	1624d719-8d5b-4d25-995f-7a669dc0ad91	\N	["guest"]	pending	\N	\N
user-65-59a10909@example.com	User 65	hashedpassword	\N	\N	t	2025-08-29 20:59:13.181229+07	2025-08-29 20:59:13.181229+07	59a10909-ca5a-47e5-82d4-d09673882c9c	\N	["guest"]	pending	\N	\N
user-66-b9241a1b@example.com	User 66	hashedpassword	\N	\N	t	2025-08-29 20:59:13.181588+07	2025-08-29 20:59:13.181588+07	b9241a1b-0324-405d-87b8-bcc2123dff4e	\N	["guest"]	pending	\N	\N
user-68-45a90515@example.com	User 68	hashedpassword	\N	\N	t	2025-08-29 20:59:13.182378+07	2025-08-29 20:59:13.182378+07	45a90515-e52f-427c-b07c-dd08a8ee081e	\N	["guest"]	pending	\N	\N
user-78-cd0b32dc@example.com	User 78	hashedpassword	\N	\N	t	2025-08-29 20:59:13.187689+07	2025-08-29 20:59:13.187689+07	cd0b32dc-2e5e-49d2-aaa0-cc5833725c21	\N	["guest"]	pending	\N	\N
user-79-20247eef@example.com	User 79	hashedpassword	\N	\N	t	2025-08-29 20:59:13.189084+07	2025-08-29 20:59:13.189084+07	20247eef-97aa-407c-ae1a-43430d9a78e2	\N	["guest"]	pending	\N	\N
user-80-e0392db9@example.com	User 80	hashedpassword	\N	\N	t	2025-08-29 20:59:13.190324+07	2025-08-29 20:59:13.190339+07	e0392db9-51d8-499a-b323-fc31fc4210bb	\N	["guest"]	pending	\N	\N
user-86-de6bf352@example.com	User 86	hashedpassword	\N	\N	t	2025-08-29 20:59:13.19532+07	2025-08-29 20:59:13.19532+07	de6bf352-ca53-4ee5-9dc1-fd80f82de6fd	\N	["guest"]	pending	\N	\N
user-89-bc91d4a0@example.com	User 89	hashedpassword	\N	\N	t	2025-08-29 20:59:13.196734+07	2025-08-29 20:59:13.196734+07	bc91d4a0-bf60-407f-9cff-ef04ac81610e	\N	["guest"]	pending	\N	\N
user-91-25b10f0a@example.com	User 91	hashedpassword	\N	\N	t	2025-08-29 20:59:13.197554+07	2025-08-29 20:59:13.197554+07	25b10f0a-03c8-435b-9b1f-eb9ae9a17119	\N	["guest"]	pending	\N	\N
user-95-27d52f21@example.com	User 95	hashedpassword	\N	\N	t	2025-08-29 20:59:13.199142+07	2025-08-29 20:59:13.199142+07	27d52f21-935c-4916-802b-298e0a3467f6	\N	["guest"]	pending	\N	\N
user-98-e9619796@example.com	User 98	hashedpassword	\N	\N	t	2025-08-29 20:59:13.200423+07	2025-08-29 20:59:13.200423+07	e9619796-387b-4e87-a752-510beacf9587	\N	["guest"]	pending	\N	\N
concurrent-user-3-223409e5@example.com	Concurrent User 3	password	\N	\N	t	2025-08-29 20:59:13.418716+07	2025-08-29 20:59:13.418716+07	223409e5-e25d-4560-bed8-441613945330	\N	["guest"]	pending	\N	\N
perf-test-0-1facaac1@example.com	Performance User 0	password	\N	\N	t	2025-08-29 20:59:13.708815+07	2025-08-29 20:59:13.708815+07	1facaac1-8a59-4b86-b861-94c695443392	\N	["guest"]	pending	\N	\N
perf-test-1-0b66e6ad@example.com	Performance User 1	password	\N	\N	t	2025-08-29 20:59:13.7097+07	2025-08-29 20:59:13.709701+07	0b66e6ad-5c7a-4956-893f-ae9c607c1f27	\N	["guest"]	pending	\N	\N
perf-test-2-1720b66b@example.com	Performance User 2	password	\N	\N	t	2025-08-29 20:59:13.710432+07	2025-08-29 20:59:13.710432+07	1720b66b-f1c4-493e-8f0b-67b7a8bfac41	\N	["guest"]	pending	\N	\N
perf-test-3-ffe99f5e@example.com	Performance User 3	password	\N	\N	t	2025-08-29 20:59:13.71103+07	2025-08-29 20:59:13.71103+07	ffe99f5e-69cd-4a76-9f11-a7d338822aa4	\N	["guest"]	pending	\N	\N
perf-test-4-3cbabe35@example.com	Performance User 4	password	\N	\N	t	2025-08-29 20:59:13.711684+07	2025-08-29 20:59:13.711684+07	3cbabe35-4cd9-4916-b7c0-0ac0b50c229d	\N	["guest"]	pending	\N	\N
perf-test-5-c6c85b67@example.com	Performance User 5	password	\N	\N	t	2025-08-29 20:59:13.712169+07	2025-08-29 20:59:13.71217+07	c6c85b67-780a-4c36-ad97-f81f03675d3f	\N	["guest"]	pending	\N	\N
perf-test-6-1bc138b4@example.com	Performance User 6	password	\N	\N	t	2025-08-29 20:59:13.712617+07	2025-08-29 20:59:13.712617+07	1bc138b4-f1c9-4c2b-94fd-db949366b832	\N	["guest"]	pending	\N	\N
perf-test-7-3abe2071@example.com	Performance User 7	password	\N	\N	t	2025-08-29 20:59:13.713044+07	2025-08-29 20:59:13.713044+07	3abe2071-1630-43d6-94b0-4bfb9a725e6d	\N	["guest"]	pending	\N	\N
perf-test-8-0185afb3@example.com	Performance User 8	password	\N	\N	t	2025-08-29 20:59:13.713409+07	2025-08-29 20:59:13.713409+07	0185afb3-8de9-4d34-9d5e-32de3538acc5	\N	["guest"]	pending	\N	\N
perf-test-9-db01f9cc@example.com	Performance User 9	password	\N	\N	t	2025-08-29 20:59:13.713788+07	2025-08-29 20:59:13.713788+07	db01f9cc-ba1b-424c-8b85-179e05498908	\N	["guest"]	pending	\N	\N
perf-test-10-eef814df@example.com	Performance User 10	password	\N	\N	t	2025-08-29 20:59:13.71413+07	2025-08-29 20:59:13.71413+07	eef814df-d85a-4f7d-bff7-2113bfc44d5e	\N	["guest"]	pending	\N	\N
perf-test-11-b8e312af@example.com	Performance User 11	password	\N	\N	t	2025-08-29 20:59:13.715055+07	2025-08-29 20:59:13.715055+07	b8e312af-eaf1-436d-ab16-985d1bb34e22	\N	["guest"]	pending	\N	\N
perf-test-12-7cdff5f9@example.com	Performance User 12	password	\N	\N	t	2025-08-29 20:59:13.715438+07	2025-08-29 20:59:13.715438+07	7cdff5f9-cbb1-4818-8470-def1d5acb109	\N	["guest"]	pending	\N	\N
perf-test-13-511bcf32@example.com	Performance User 13	password	\N	\N	t	2025-08-29 20:59:13.715854+07	2025-08-29 20:59:13.715854+07	511bcf32-e453-495b-9384-378bf56a5d80	\N	["guest"]	pending	\N	\N
perf-test-14-98b8fa86@example.com	Performance User 14	password	\N	\N	t	2025-08-29 20:59:13.716233+07	2025-08-29 20:59:13.716233+07	98b8fa86-ecc6-4e40-8622-931e08324e64	\N	["guest"]	pending	\N	\N
perf-test-15-ad3e7964@example.com	Performance User 15	password	\N	\N	t	2025-08-29 20:59:13.716618+07	2025-08-29 20:59:13.716618+07	ad3e7964-6219-4ef8-9a5e-84822e458819	\N	["guest"]	pending	\N	\N
perf-test-16-f67faeea@example.com	Performance User 16	password	\N	\N	t	2025-08-29 20:59:13.716982+07	2025-08-29 20:59:13.716982+07	f67faeea-f074-47eb-a463-104d92db7bb2	\N	["guest"]	pending	\N	\N
perf-test-17-145601b6@example.com	Performance User 17	password	\N	\N	t	2025-08-29 20:59:13.717355+07	2025-08-29 20:59:13.717355+07	145601b6-4bec-4a98-b091-4da80a28dd12	\N	["guest"]	pending	\N	\N
perf-test-18-e50ab2bc@example.com	Performance User 18	password	\N	\N	t	2025-08-29 20:59:13.717714+07	2025-08-29 20:59:13.717714+07	e50ab2bc-8ccf-436e-b5d2-a4fcc3ad6917	\N	["guest"]	pending	\N	\N
perf-test-19-d6d4d507@example.com	Performance User 19	password	\N	\N	t	2025-08-29 20:59:13.718087+07	2025-08-29 20:59:13.718087+07	d6d4d507-d110-433b-86b7-33ce52a32784	\N	["guest"]	pending	\N	\N
perf-test-20-86acd9bd@example.com	Performance User 20	password	\N	\N	t	2025-08-29 20:59:13.718484+07	2025-08-29 20:59:13.718484+07	86acd9bd-f693-43db-bd36-e605c6573d3c	\N	["guest"]	pending	\N	\N
perf-test-21-eb9f76dc@example.com	Performance User 21	password	\N	\N	t	2025-08-29 20:59:13.718927+07	2025-08-29 20:59:13.718927+07	eb9f76dc-6a13-47ad-be14-98cb0104da1c	\N	["guest"]	pending	\N	\N
perf-test-22-63e6a3f1@example.com	Performance User 22	password	\N	\N	t	2025-08-29 20:59:13.719536+07	2025-08-29 20:59:13.719537+07	63e6a3f1-3210-447b-bd87-7499058132a8	\N	["guest"]	pending	\N	\N
perf-test-23-0046a490@example.com	Performance User 23	password	\N	\N	t	2025-08-29 20:59:13.72009+07	2025-08-29 20:59:13.72009+07	0046a490-d9f2-4c42-a8bd-928b3f80c3bd	\N	["guest"]	pending	\N	\N
perf-test-24-5de75ca3@example.com	Performance User 24	password	\N	\N	t	2025-08-29 20:59:13.7214+07	2025-08-29 20:59:13.7214+07	5de75ca3-2350-4e5b-92df-b1003a4bf0f1	\N	["guest"]	pending	\N	\N
perf-test-25-4e665436@example.com	Performance User 25	password	\N	\N	t	2025-08-29 20:59:13.724268+07	2025-08-29 20:59:13.724268+07	4e665436-9ca4-4929-af1b-2b2e1c9300c6	\N	["guest"]	pending	\N	\N
perf-test-26-da7ae2bf@example.com	Performance User 26	password	\N	\N	t	2025-08-29 20:59:13.725605+07	2025-08-29 20:59:13.725605+07	da7ae2bf-50a7-4685-8578-934ba7281cbf	\N	["guest"]	pending	\N	\N
perf-test-27-ffdddf4c@example.com	Performance User 27	password	\N	\N	t	2025-08-29 20:59:13.726227+07	2025-08-29 20:59:13.726227+07	ffdddf4c-3069-4002-9f88-e3492f274e49	\N	["guest"]	pending	\N	\N
perf-test-28-52a006ca@example.com	Performance User 28	password	\N	\N	t	2025-08-29 20:59:13.726923+07	2025-08-29 20:59:13.726923+07	52a006ca-1a12-4c4c-9a16-508cc68cb37b	\N	["guest"]	pending	\N	\N
perf-test-29-4108c467@example.com	Performance User 29	password	\N	\N	t	2025-08-29 20:59:13.727628+07	2025-08-29 20:59:13.727628+07	4108c467-45d0-4e4a-944e-8a117fd89bfe	\N	["guest"]	pending	\N	\N
perf-test-30-c0f4bf58@example.com	Performance User 30	password	\N	\N	t	2025-08-29 20:59:13.728289+07	2025-08-29 20:59:13.728289+07	c0f4bf58-66c7-4854-9d50-a32c08695271	\N	["guest"]	pending	\N	\N
perf-test-31-aaa2bfa5@example.com	Performance User 31	password	\N	\N	t	2025-08-29 20:59:13.729105+07	2025-08-29 20:59:13.729105+07	aaa2bfa5-f499-4386-bf5d-6c80da1d99fb	\N	["guest"]	pending	\N	\N
perf-test-32-cc992263@example.com	Performance User 32	password	\N	\N	t	2025-08-29 20:59:13.729822+07	2025-08-29 20:59:13.729822+07	cc992263-b076-45b0-b10f-cace22411144	\N	["guest"]	pending	\N	\N
perf-test-33-540a1b7c@example.com	Performance User 33	password	\N	\N	t	2025-08-29 20:59:13.730482+07	2025-08-29 20:59:13.730482+07	540a1b7c-9a2d-4d8e-8ed2-5c22142269ba	\N	["guest"]	pending	\N	\N
perf-test-34-d0664111@example.com	Performance User 34	password	\N	\N	t	2025-08-29 20:59:13.731199+07	2025-08-29 20:59:13.731199+07	d0664111-913b-4cd7-9e45-2a946fc3f007	\N	["guest"]	pending	\N	\N
perf-test-35-b30d1fda@example.com	Performance User 35	password	\N	\N	t	2025-08-29 20:59:13.731705+07	2025-08-29 20:59:13.731705+07	b30d1fda-a95a-4787-b55e-bacedf9ab105	\N	["guest"]	pending	\N	\N
perf-test-36-c83144ef@example.com	Performance User 36	password	\N	\N	t	2025-08-29 20:59:13.732372+07	2025-08-29 20:59:13.732372+07	c83144ef-4953-4ddb-b5c4-a3963ddc26cd	\N	["guest"]	pending	\N	\N
perf-test-37-5e7f82aa@example.com	Performance User 37	password	\N	\N	t	2025-08-29 20:59:13.732959+07	2025-08-29 20:59:13.732959+07	5e7f82aa-4b4d-4101-8187-88a196ac9502	\N	["guest"]	pending	\N	\N
perf-test-38-3fe6368f@example.com	Performance User 38	password	\N	\N	t	2025-08-29 20:59:13.73343+07	2025-08-29 20:59:13.73343+07	3fe6368f-bc7a-4f4b-91ce-eaec61b69bb1	\N	["guest"]	pending	\N	\N
perf-test-39-8174878a@example.com	Performance User 39	password	\N	\N	t	2025-08-29 20:59:13.733842+07	2025-08-29 20:59:13.733842+07	8174878a-37ff-4f3b-899b-67e34a0c1277	\N	["guest"]	pending	\N	\N
perf-test-40-472af9ba@example.com	Performance User 40	password	\N	\N	t	2025-08-29 20:59:13.734265+07	2025-08-29 20:59:13.734265+07	472af9ba-3ba6-46bd-b5e3-2c4483c74215	\N	["guest"]	pending	\N	\N
perf-test-41-0ead8d25@example.com	Performance User 41	password	\N	\N	t	2025-08-29 20:59:13.734667+07	2025-08-29 20:59:13.734668+07	0ead8d25-2b43-4541-84c0-8fc791d5b9fe	\N	["guest"]	pending	\N	\N
perf-test-42-86fefde3@example.com	Performance User 42	password	\N	\N	t	2025-08-29 20:59:13.735136+07	2025-08-29 20:59:13.735137+07	86fefde3-6c7d-459a-be18-65b1341a45e1	\N	["guest"]	pending	\N	\N
perf-test-43-08e57f44@example.com	Performance User 43	password	\N	\N	t	2025-08-29 20:59:13.735567+07	2025-08-29 20:59:13.735567+07	08e57f44-5329-48e0-995a-ba7a4c1de1a1	\N	["guest"]	pending	\N	\N
perf-test-44-633fcaef@example.com	Performance User 44	password	\N	\N	t	2025-08-29 20:59:13.736014+07	2025-08-29 20:59:13.736014+07	633fcaef-6596-42af-8509-4f3b97cb6a84	\N	["guest"]	pending	\N	\N
perf-test-45-96e8098e@example.com	Performance User 45	password	\N	\N	t	2025-08-29 20:59:13.736528+07	2025-08-29 20:59:13.736528+07	96e8098e-32b3-40a5-9c24-fa66d3f185c7	\N	["guest"]	pending	\N	\N
perf-test-46-317caedb@example.com	Performance User 46	password	\N	\N	t	2025-08-29 20:59:13.737154+07	2025-08-29 20:59:13.737154+07	317caedb-a8bf-4d88-a4cd-b64466b3e9ec	\N	["guest"]	pending	\N	\N
perf-test-47-50df304a@example.com	Performance User 47	password	\N	\N	t	2025-08-29 20:59:13.738695+07	2025-08-29 20:59:13.738696+07	50df304a-d51d-4159-b533-8153c130fb53	\N	["guest"]	pending	\N	\N
perf-test-48-1530a5e2@example.com	Performance User 48	password	\N	\N	t	2025-08-29 20:59:13.740465+07	2025-08-29 20:59:13.740465+07	1530a5e2-dbdd-49ed-8704-bc654e088d46	\N	["guest"]	pending	\N	\N
perf-test-49-f3e8d8f7@example.com	Performance User 49	password	\N	\N	t	2025-08-29 20:59:13.741849+07	2025-08-29 20:59:13.74185+07	f3e8d8f7-50da-4de4-80f5-288e6122af28	\N	["guest"]	pending	\N	\N
user-4-b4f50f96@example.com	User 4	hashedpassword	\N	\N	t	2025-08-29 21:59:39.970547+07	2025-08-29 21:59:39.970547+07	b4f50f96-f6da-4e5f-a2ae-f3c736f4977f	\N	["guest"]	pending	\N	\N
user-14-f3afc827@example.com	User 14	hashedpassword	\N	\N	t	2025-08-29 21:59:39.990623+07	2025-08-29 21:59:39.990623+07	f3afc827-a51a-4e9f-91f3-575bd3125cb9	\N	["guest"]	pending	\N	\N
user-29-a58bc364@example.com	User 29	hashedpassword	\N	\N	t	2025-08-29 21:59:40.00802+07	2025-08-29 21:59:40.00802+07	a58bc364-ff0f-4d10-ab93-fb096675c858	\N	["guest"]	pending	\N	\N
user-41-eec1bccc@example.com	User 41	hashedpassword	\N	\N	t	2025-08-29 21:59:40.020879+07	2025-08-29 21:59:40.020879+07	eec1bccc-2388-4c85-a046-ef526839057d	\N	["guest"]	pending	\N	\N
user-42-44623d11@example.com	User 42	hashedpassword	\N	\N	t	2025-08-29 21:59:40.022156+07	2025-08-29 21:59:40.022156+07	44623d11-430e-4da4-a412-0f7cb75e8e8b	\N	["guest"]	pending	\N	\N
user-45-a93af75b@example.com	User 45	hashedpassword	\N	\N	t	2025-08-29 21:59:40.024343+07	2025-08-29 21:59:40.024343+07	a93af75b-3a47-4f6d-9374-0cd9e9279f32	\N	["guest"]	pending	\N	\N
user-49-c0c3d5aa@example.com	User 49	hashedpassword	\N	\N	t	2025-08-29 21:59:40.028173+07	2025-08-29 21:59:40.028173+07	c0c3d5aa-ff89-4faf-b65b-98933ffd274e	\N	["guest"]	pending	\N	\N
user-56-2463a5d7@example.com	User 56	hashedpassword	\N	\N	t	2025-08-29 21:59:40.035964+07	2025-08-29 21:59:40.035964+07	2463a5d7-ee7d-499f-b5ec-12a7fd6ce40a	\N	["guest"]	pending	\N	\N
user-58-a6caeaf3@example.com	User 58	hashedpassword	\N	\N	t	2025-08-29 21:59:40.039255+07	2025-08-29 21:59:40.039255+07	a6caeaf3-59c7-44dc-abde-5f1f8ce454d5	\N	["guest"]	pending	\N	\N
user-59-6dc09e38@example.com	User 59	hashedpassword	\N	\N	t	2025-08-29 21:59:40.042139+07	2025-08-29 21:59:40.04214+07	6dc09e38-18c8-4057-ba68-2487d0af07d2	\N	["guest"]	pending	\N	\N
user-62-a6b68f9d@example.com	User 62	hashedpassword	\N	\N	t	2025-08-29 21:59:40.047529+07	2025-08-29 21:59:40.047529+07	a6b68f9d-b5a6-4e3c-abfe-527801063dc9	\N	["guest"]	pending	\N	\N
user-64-0b21c3f4@example.com	User 64	hashedpassword	\N	\N	t	2025-08-29 21:59:40.049627+07	2025-08-29 21:59:40.049627+07	0b21c3f4-fd5c-4401-899e-225470b6935e	\N	["guest"]	pending	\N	\N
user-65-732998e1@example.com	User 65	hashedpassword	\N	\N	t	2025-08-29 21:59:40.050926+07	2025-08-29 21:59:40.050927+07	732998e1-afbe-4085-b52f-a14020286893	\N	["guest"]	pending	\N	\N
user-66-1e62ec8b@example.com	User 66	hashedpassword	\N	\N	t	2025-08-29 21:59:40.052111+07	2025-08-29 21:59:40.052111+07	1e62ec8b-19c7-45ba-baf1-8fb724b4d80a	\N	["guest"]	pending	\N	\N
user-72-c0fd1ee9@example.com	User 72	hashedpassword	\N	\N	t	2025-08-29 21:59:40.13938+07	2025-08-29 21:59:40.139381+07	c0fd1ee9-a8cb-48e1-812f-b22f6dd041c6	\N	["guest"]	pending	\N	\N
user-78-dff6bad0@example.com	User 78	hashedpassword	\N	\N	t	2025-08-29 21:59:40.146301+07	2025-08-29 21:59:40.146301+07	dff6bad0-cf89-43bc-a65a-809eecb88328	\N	["guest"]	pending	\N	\N
user-83-58459bf1@example.com	User 83	hashedpassword	\N	\N	t	2025-08-29 21:59:40.149867+07	2025-08-29 21:59:40.149867+07	58459bf1-ef1d-420a-93a6-564d3a3eae8e	\N	["guest"]	pending	\N	\N
user-85-1ea83d2a@example.com	User 85	hashedpassword	\N	\N	t	2025-08-29 21:59:40.150978+07	2025-08-29 21:59:40.150978+07	1ea83d2a-0e6a-4c12-a5f8-18f522c66d1f	\N	["guest"]	pending	\N	\N
user-86-1fb7318d@example.com	User 86	hashedpassword	\N	\N	t	2025-08-29 21:59:40.151431+07	2025-08-29 21:59:40.151431+07	1fb7318d-a417-49ee-bae6-667e6207e1ef	\N	["guest"]	pending	\N	\N
user-89-fb333cbe@example.com	User 89	hashedpassword	\N	\N	t	2025-08-29 21:59:40.153656+07	2025-08-29 21:59:40.153656+07	fb333cbe-d1e3-426f-af84-31afaef90949	\N	["guest"]	pending	\N	\N
user-95-633f3e1e@example.com	User 95	hashedpassword	\N	\N	t	2025-08-29 21:59:40.15921+07	2025-08-29 21:59:40.159211+07	633f3e1e-48b1-41da-8ff3-5b42f3ffd298	\N	["guest"]	pending	\N	\N
user-96-9f487e33@example.com	User 96	hashedpassword	\N	\N	t	2025-08-29 21:59:40.160329+07	2025-08-29 21:59:40.160329+07	9f487e33-b088-4351-ac55-6330ecc88992	\N	["guest"]	pending	\N	\N
concurrent-user-3-68a030b6@example.com	Concurrent User 3	password	\N	\N	t	2025-08-29 21:59:40.598857+07	2025-08-29 21:59:40.598857+07	68a030b6-3979-4b92-921d-d1796758f820	\N	["guest"]	pending	\N	\N
perf-test-0-7ca9746f@example.com	Performance User 0	password	\N	\N	t	2025-08-29 21:59:41.279359+07	2025-08-29 21:59:41.279359+07	7ca9746f-fa20-4f11-83ff-43fac06c580d	\N	["guest"]	pending	\N	\N
perf-test-1-2bcaba02@example.com	Performance User 1	password	\N	\N	t	2025-08-29 21:59:41.280774+07	2025-08-29 21:59:41.280774+07	2bcaba02-cbf3-4c15-99fc-58c15e210f58	\N	["guest"]	pending	\N	\N
perf-test-2-d900ec69@example.com	Performance User 2	password	\N	\N	t	2025-08-29 21:59:41.281532+07	2025-08-29 21:59:41.281532+07	d900ec69-ae1c-4212-80c4-73d2a362b0ee	\N	["guest"]	pending	\N	\N
perf-test-3-3eb8e9ac@example.com	Performance User 3	password	\N	\N	t	2025-08-29 21:59:41.282189+07	2025-08-29 21:59:41.282189+07	3eb8e9ac-1908-4ad7-987e-3b8d0f21a6b7	\N	["guest"]	pending	\N	\N
perf-test-4-144b4bcf@example.com	Performance User 4	password	\N	\N	t	2025-08-29 21:59:41.282801+07	2025-08-29 21:59:41.282802+07	144b4bcf-ffe8-4a60-8a9b-56af1326b0f7	\N	["guest"]	pending	\N	\N
perf-test-5-f30add62@example.com	Performance User 5	password	\N	\N	t	2025-08-29 21:59:41.283246+07	2025-08-29 21:59:41.283246+07	f30add62-4dd3-43f5-a2ad-7048d9107466	\N	["guest"]	pending	\N	\N
perf-test-6-e68be031@example.com	Performance User 6	password	\N	\N	t	2025-08-29 21:59:41.283825+07	2025-08-29 21:59:41.283825+07	e68be031-6f0a-4c81-af04-9ca1da928b80	\N	["guest"]	pending	\N	\N
perf-test-7-77e9b12d@example.com	Performance User 7	password	\N	\N	t	2025-08-29 21:59:41.284229+07	2025-08-29 21:59:41.284229+07	77e9b12d-304b-4b70-85d1-d9fee8ef867d	\N	["guest"]	pending	\N	\N
perf-test-8-05a7bebe@example.com	Performance User 8	password	\N	\N	t	2025-08-29 21:59:41.284623+07	2025-08-29 21:59:41.284623+07	05a7bebe-dc7c-4c03-a46d-f993fd11af7e	\N	["guest"]	pending	\N	\N
perf-test-9-c1697d73@example.com	Performance User 9	password	\N	\N	t	2025-08-29 21:59:41.284997+07	2025-08-29 21:59:41.284997+07	c1697d73-46bf-446b-a72f-b5527d774f8f	\N	["guest"]	pending	\N	\N
perf-test-10-0f3eb7b1@example.com	Performance User 10	password	\N	\N	t	2025-08-29 21:59:41.28543+07	2025-08-29 21:59:41.28543+07	0f3eb7b1-bcbc-44de-9575-bc188293c3e5	\N	["guest"]	pending	\N	\N
perf-test-11-79ac751b@example.com	Performance User 11	password	\N	\N	t	2025-08-29 21:59:41.285959+07	2025-08-29 21:59:41.285959+07	79ac751b-0813-40c6-8228-6efe8af31d3e	\N	["guest"]	pending	\N	\N
perf-test-12-7e842b3e@example.com	Performance User 12	password	\N	\N	t	2025-08-29 21:59:41.286713+07	2025-08-29 21:59:41.286713+07	7e842b3e-9914-4ab2-9c3e-2d0800388813	\N	["guest"]	pending	\N	\N
perf-test-13-0ebb212a@example.com	Performance User 13	password	\N	\N	t	2025-08-29 21:59:41.287196+07	2025-08-29 21:59:41.287196+07	0ebb212a-2e83-44cb-adf0-ec929d30be58	\N	["guest"]	pending	\N	\N
perf-test-14-d059dda0@example.com	Performance User 14	password	\N	\N	t	2025-08-29 21:59:41.28773+07	2025-08-29 21:59:41.28773+07	d059dda0-0367-40f4-9893-cd9d57223770	\N	["guest"]	pending	\N	\N
perf-test-15-f416eb10@example.com	Performance User 15	password	\N	\N	t	2025-08-29 21:59:41.288166+07	2025-08-29 21:59:41.288167+07	f416eb10-a4e1-4cc8-af58-2e26cfb0ed61	\N	["guest"]	pending	\N	\N
perf-test-16-9e0b877c@example.com	Performance User 16	password	\N	\N	t	2025-08-29 21:59:41.28865+07	2025-08-29 21:59:41.28865+07	9e0b877c-df9b-44bc-afce-bae51cd4b778	\N	["guest"]	pending	\N	\N
perf-test-17-c71c1119@example.com	Performance User 17	password	\N	\N	t	2025-08-29 21:59:41.289174+07	2025-08-29 21:59:41.289174+07	c71c1119-e649-465e-bbc4-65493aef1664	\N	["guest"]	pending	\N	\N
perf-test-18-c461e594@example.com	Performance User 18	password	\N	\N	t	2025-08-29 21:59:41.289671+07	2025-08-29 21:59:41.289671+07	c461e594-9980-42de-a799-09b561f923cd	\N	["guest"]	pending	\N	\N
perf-test-19-d801fb59@example.com	Performance User 19	password	\N	\N	t	2025-08-29 21:59:41.290147+07	2025-08-29 21:59:41.290148+07	d801fb59-b40c-4cc5-89dd-a39c6da81d87	\N	["guest"]	pending	\N	\N
perf-test-20-74951d55@example.com	Performance User 20	password	\N	\N	t	2025-08-29 21:59:41.290637+07	2025-08-29 21:59:41.290637+07	74951d55-f868-4daa-8e50-6f3520c82a8b	\N	["guest"]	pending	\N	\N
perf-test-21-05dd8481@example.com	Performance User 21	password	\N	\N	t	2025-08-29 21:59:41.291112+07	2025-08-29 21:59:41.291112+07	05dd8481-73da-4894-a165-76623346a396	\N	["guest"]	pending	\N	\N
perf-test-22-b2ec9756@example.com	Performance User 22	password	\N	\N	t	2025-08-29 21:59:41.291508+07	2025-08-29 21:59:41.291508+07	b2ec9756-125c-4e57-b257-3a49cb803d7c	\N	["guest"]	pending	\N	\N
perf-test-23-ea9a48dd@example.com	Performance User 23	password	\N	\N	t	2025-08-29 21:59:41.291899+07	2025-08-29 21:59:41.291899+07	ea9a48dd-c0e8-4773-bf7d-14c8fa3336f9	\N	["guest"]	pending	\N	\N
perf-test-24-cb6938e8@example.com	Performance User 24	password	\N	\N	t	2025-08-29 21:59:41.292261+07	2025-08-29 21:59:41.292262+07	cb6938e8-8904-40a9-9536-b69b1babb6a2	\N	["guest"]	pending	\N	\N
perf-test-25-d21260f5@example.com	Performance User 25	password	\N	\N	t	2025-08-29 21:59:41.292624+07	2025-08-29 21:59:41.292624+07	d21260f5-0963-46a0-bd79-792cdd029ffc	\N	["guest"]	pending	\N	\N
perf-test-26-5673e690@example.com	Performance User 26	password	\N	\N	t	2025-08-29 21:59:41.293006+07	2025-08-29 21:59:41.293006+07	5673e690-2df2-43f0-ab00-47f428cbc330	\N	["guest"]	pending	\N	\N
perf-test-27-83fa19e2@example.com	Performance User 27	password	\N	\N	t	2025-08-29 21:59:41.29341+07	2025-08-29 21:59:41.29341+07	83fa19e2-ae45-47de-90e0-ae7eeb284584	\N	["guest"]	pending	\N	\N
perf-test-28-dd2aaa26@example.com	Performance User 28	password	\N	\N	t	2025-08-29 21:59:41.293763+07	2025-08-29 21:59:41.293766+07	dd2aaa26-f175-49ea-b2ff-e398b2d9fe2a	\N	["guest"]	pending	\N	\N
perf-test-29-a70f8617@example.com	Performance User 29	password	\N	\N	t	2025-08-29 21:59:41.294285+07	2025-08-29 21:59:41.294285+07	a70f8617-202b-4781-b8b1-321b022e4b62	\N	["guest"]	pending	\N	\N
perf-test-30-cff2a4bb@example.com	Performance User 30	password	\N	\N	t	2025-08-29 21:59:41.294811+07	2025-08-29 21:59:41.294811+07	cff2a4bb-c774-49f5-99ca-ff1bd48b2a9c	\N	["guest"]	pending	\N	\N
perf-test-31-27fbca50@example.com	Performance User 31	password	\N	\N	t	2025-08-29 21:59:41.29543+07	2025-08-29 21:59:41.29543+07	27fbca50-152d-4c3c-a1b1-542f6f02e9f6	\N	["guest"]	pending	\N	\N
perf-test-32-0dea91e4@example.com	Performance User 32	password	\N	\N	t	2025-08-29 21:59:41.296303+07	2025-08-29 21:59:41.296303+07	0dea91e4-77d5-4578-bc6c-2ed9de7fa8e2	\N	["guest"]	pending	\N	\N
perf-test-33-4d5f0b0f@example.com	Performance User 33	password	\N	\N	t	2025-08-29 21:59:41.297091+07	2025-08-29 21:59:41.297091+07	4d5f0b0f-cdc6-4116-a3ec-d206d0f79eff	\N	["guest"]	pending	\N	\N
perf-test-34-9834fa8f@example.com	Performance User 34	password	\N	\N	t	2025-08-29 21:59:41.297716+07	2025-08-29 21:59:41.297716+07	9834fa8f-c233-4739-9753-a81d28972348	\N	["guest"]	pending	\N	\N
perf-test-35-1e9d2b91@example.com	Performance User 35	password	\N	\N	t	2025-08-29 21:59:41.298248+07	2025-08-29 21:59:41.298248+07	1e9d2b91-e0b6-497d-898a-c2773fec52ab	\N	["guest"]	pending	\N	\N
perf-test-36-f7502950@example.com	Performance User 36	password	\N	\N	t	2025-08-29 21:59:41.298796+07	2025-08-29 21:59:41.298796+07	f7502950-f280-4eee-9f18-eaeefb0f1be0	\N	["guest"]	pending	\N	\N
perf-test-37-595bc630@example.com	Performance User 37	password	\N	\N	t	2025-08-29 21:59:41.29928+07	2025-08-29 21:59:41.29928+07	595bc630-85e4-40da-90be-fd4c50bedc55	\N	["guest"]	pending	\N	\N
perf-test-38-8162fd8d@example.com	Performance User 38	password	\N	\N	t	2025-08-29 21:59:41.299733+07	2025-08-29 21:59:41.299733+07	8162fd8d-07a3-4ecd-a7f6-dffa649626f2	\N	["guest"]	pending	\N	\N
perf-test-39-63e8ef6b@example.com	Performance User 39	password	\N	\N	t	2025-08-29 21:59:41.300132+07	2025-08-29 21:59:41.300133+07	63e8ef6b-f3cc-4880-a04e-c6d337302418	\N	["guest"]	pending	\N	\N
perf-test-40-d8e24fc6@example.com	Performance User 40	password	\N	\N	t	2025-08-29 21:59:41.300522+07	2025-08-29 21:59:41.300522+07	d8e24fc6-4f7c-4aa1-8790-e631195ead88	\N	["guest"]	pending	\N	\N
perf-test-41-bfedd859@example.com	Performance User 41	password	\N	\N	t	2025-08-29 21:59:41.300978+07	2025-08-29 21:59:41.300978+07	bfedd859-7e89-4a99-89a8-3c3c956ac16e	\N	["guest"]	pending	\N	\N
perf-test-42-58228068@example.com	Performance User 42	password	\N	\N	t	2025-08-29 21:59:41.301362+07	2025-08-29 21:59:41.301363+07	58228068-37c0-4b99-82ae-eb3f6f4dfc3f	\N	["guest"]	pending	\N	\N
perf-test-43-0d0eb443@example.com	Performance User 43	password	\N	\N	t	2025-08-29 21:59:41.301743+07	2025-08-29 21:59:41.301743+07	0d0eb443-877f-40f3-a10a-6815f7fbf77c	\N	["guest"]	pending	\N	\N
perf-test-44-5afd61e1@example.com	Performance User 44	password	\N	\N	t	2025-08-29 21:59:41.302382+07	2025-08-29 21:59:41.302382+07	5afd61e1-d325-4a8c-8294-19933e9fff9b	\N	["guest"]	pending	\N	\N
perf-test-45-4eb8d8dc@example.com	Performance User 45	password	\N	\N	t	2025-08-29 21:59:41.303012+07	2025-08-29 21:59:41.303012+07	4eb8d8dc-a351-4d50-96c6-b151106a0cd2	\N	["guest"]	pending	\N	\N
perf-test-46-96fa1806@example.com	Performance User 46	password	\N	\N	t	2025-08-29 21:59:41.303508+07	2025-08-29 21:59:41.303508+07	96fa1806-ad87-4198-90ee-91e95c60a5b1	\N	["guest"]	pending	\N	\N
perf-test-47-5add7854@example.com	Performance User 47	password	\N	\N	t	2025-08-29 21:59:41.30399+07	2025-08-29 21:59:41.30399+07	5add7854-442c-46a6-b809-b44499f39c31	\N	["guest"]	pending	\N	\N
perf-test-48-9be40586@example.com	Performance User 48	password	\N	\N	t	2025-08-29 21:59:41.304595+07	2025-08-29 21:59:41.304596+07	9be40586-8694-4763-8004-003835db84fb	\N	["guest"]	pending	\N	\N
perf-test-49-91ca8405@example.com	Performance User 49	password	\N	\N	t	2025-08-29 21:59:41.305128+07	2025-08-29 21:59:41.305128+07	91ca8405-6bb0-45d4-96d1-daa4d38f6ed8	\N	["guest"]	pending	\N	\N
user-2-d9e05b39@example.com	User 2	hashedpassword	\N	\N	t	2025-08-29 22:02:00.844807+07	2025-08-29 22:02:00.844808+07	d9e05b39-6c2e-437b-8427-d6028fd25bb1	\N	["guest"]	pending	\N	\N
user-4-09d7f2f6@example.com	User 4	hashedpassword	\N	\N	t	2025-08-29 22:02:00.850463+07	2025-08-29 22:02:00.850464+07	09d7f2f6-5feb-44f9-9afc-72c7ad51d085	\N	["guest"]	pending	\N	\N
user-11-6c3cda82@example.com	User 11	hashedpassword	\N	\N	t	2025-08-29 22:02:00.858377+07	2025-08-29 22:02:00.858377+07	6c3cda82-96e8-44e9-b105-3e060e86604c	\N	["guest"]	pending	\N	\N
user-12-10e0204e@example.com	User 12	hashedpassword	\N	\N	t	2025-08-29 22:02:00.859173+07	2025-08-29 22:02:00.859173+07	10e0204e-2028-4926-9c4e-6ab219e6ab98	\N	["guest"]	pending	\N	\N
user-19-15f549b9@example.com	User 19	hashedpassword	\N	\N	t	2025-08-29 22:02:00.862924+07	2025-08-29 22:02:00.862924+07	15f549b9-8172-4786-b41d-da6a938a202f	\N	["guest"]	pending	\N	\N
user-27-4f4a0c60@example.com	User 27	hashedpassword	\N	\N	t	2025-08-29 22:02:00.867512+07	2025-08-29 22:02:00.867512+07	4f4a0c60-3191-45ed-9faa-bc3a9d857f4a	\N	["guest"]	pending	\N	\N
user-29-795a7b83@example.com	User 29	hashedpassword	\N	\N	t	2025-08-29 22:02:00.86828+07	2025-08-29 22:02:00.86828+07	795a7b83-5503-4a81-8e84-477e3b21810b	\N	["guest"]	pending	\N	\N
user-30-31785b6b@example.com	User 30	hashedpassword	\N	\N	t	2025-08-29 22:02:00.868651+07	2025-08-29 22:02:00.868651+07	31785b6b-ea26-4478-ae22-2933d56c79a8	\N	["guest"]	pending	\N	\N
user-35-7f390c8e@example.com	User 35	hashedpassword	\N	\N	t	2025-08-29 22:02:00.870919+07	2025-08-29 22:02:00.870919+07	7f390c8e-5618-4fcc-91dd-700b899fd3da	\N	["guest"]	pending	\N	\N
user-38-5f188d7d@example.com	User 38	hashedpassword	\N	\N	t	2025-08-29 22:02:00.872823+07	2025-08-29 22:02:00.872823+07	5f188d7d-90f9-4eee-b15b-fdf33813d006	\N	["guest"]	pending	\N	\N
user-43-ba796344@example.com	User 43	hashedpassword	\N	\N	t	2025-08-29 22:02:00.875379+07	2025-08-29 22:02:00.875379+07	ba796344-efcf-4ece-a9c3-b1f15301f7fe	\N	["guest"]	pending	\N	\N
user-46-dad3072e@example.com	User 46	hashedpassword	\N	\N	t	2025-08-29 22:02:00.876584+07	2025-08-29 22:02:00.876584+07	dad3072e-c016-4a72-bc21-657fec9355e8	\N	["guest"]	pending	\N	\N
user-49-f5a6ea48@example.com	User 49	hashedpassword	\N	\N	t	2025-08-29 22:02:00.877766+07	2025-08-29 22:02:00.877766+07	f5a6ea48-2cfd-4d21-9b77-1269e7fd6ab4	\N	["guest"]	pending	\N	\N
user-50-38fd1a73@example.com	User 50	hashedpassword	\N	\N	t	2025-08-29 22:02:00.878136+07	2025-08-29 22:02:00.878136+07	38fd1a73-1a92-4b9c-8305-1b56070bf699	\N	["guest"]	pending	\N	\N
user-55-dfdb9916@example.com	User 55	hashedpassword	\N	\N	t	2025-08-29 22:02:00.880393+07	2025-08-29 22:02:00.880394+07	dfdb9916-8577-405d-9945-704eeb440995	\N	["guest"]	pending	\N	\N
user-58-6e942fb7@example.com	User 58	hashedpassword	\N	\N	t	2025-08-29 22:02:00.882525+07	2025-08-29 22:02:00.882525+07	6e942fb7-7cbd-4c54-87d7-62bc6d1a9d06	\N	["guest"]	pending	\N	\N
user-62-e716adb3@example.com	User 62	hashedpassword	\N	\N	t	2025-08-29 22:02:00.884468+07	2025-08-29 22:02:00.884468+07	e716adb3-284f-43df-b56a-157ad409f00c	\N	["guest"]	pending	\N	\N
user-64-5e9addd2@example.com	User 64	hashedpassword	\N	\N	t	2025-08-29 22:02:00.885223+07	2025-08-29 22:02:00.885223+07	5e9addd2-04b4-473f-ac9c-a012cc8501b8	\N	["guest"]	pending	\N	\N
user-72-a28e4793@example.com	User 72	hashedpassword	\N	\N	t	2025-08-29 22:02:00.888556+07	2025-08-29 22:02:00.888556+07	a28e4793-5b69-43d0-ab38-603988574699	\N	["guest"]	pending	\N	\N
user-73-d3f8ceb9@example.com	User 73	hashedpassword	\N	\N	t	2025-08-29 22:02:00.889004+07	2025-08-29 22:02:00.889004+07	d3f8ceb9-36b9-4ba4-805c-10f0470494ea	\N	["guest"]	pending	\N	\N
user-77-fe3b4852@example.com	User 77	hashedpassword	\N	\N	t	2025-08-29 22:02:00.891039+07	2025-08-29 22:02:00.89104+07	fe3b4852-c1ea-47e5-ae5f-e4e6ffca535e	\N	["guest"]	pending	\N	\N
user-78-064af6bb@example.com	User 78	hashedpassword	\N	\N	t	2025-08-29 22:02:00.891513+07	2025-08-29 22:02:00.891513+07	064af6bb-62a9-463c-b774-029cb6f67739	\N	["guest"]	pending	\N	\N
user-79-eb2ec3ca@example.com	User 79	hashedpassword	\N	\N	t	2025-08-29 22:02:00.891952+07	2025-08-29 22:02:00.891952+07	eb2ec3ca-2e14-4bb7-8f6d-e362125127ce	\N	["guest"]	pending	\N	\N
user-85-7826f8d6@example.com	User 85	hashedpassword	\N	\N	t	2025-08-29 22:02:00.894381+07	2025-08-29 22:02:00.894381+07	7826f8d6-e30c-4a39-a65c-5ff47b06c465	\N	["guest"]	pending	\N	\N
user-87-bd5eed68@example.com	User 87	hashedpassword	\N	\N	t	2025-08-29 22:02:00.895175+07	2025-08-29 22:02:00.895175+07	bd5eed68-b668-43af-9227-51e3086b6611	\N	["guest"]	pending	\N	\N
user-89-08c2898f@example.com	User 89	hashedpassword	\N	\N	t	2025-08-29 22:02:00.896129+07	2025-08-29 22:02:00.896129+07	08c2898f-0b56-4dea-aef6-b68b6ce50b60	\N	["guest"]	pending	\N	\N
user-99-00c4e6d6@example.com	User 99	hashedpassword	\N	\N	t	2025-08-29 22:02:00.901327+07	2025-08-29 22:02:00.901327+07	00c4e6d6-64fb-4e76-b69f-5f8041166770	\N	["guest"]	pending	\N	\N
concurrent-user-3-ccd7ae83@example.com	Concurrent User 3	password	\N	\N	t	2025-08-29 22:02:01.174356+07	2025-08-29 22:02:01.174356+07	ccd7ae83-abda-40a5-8a0a-ece2af9fdaed	\N	["guest"]	pending	\N	\N
perf-test-0-5cc06e41@example.com	Performance User 0	password	\N	\N	t	2025-08-29 22:02:01.388772+07	2025-08-29 22:02:01.388772+07	5cc06e41-4f07-42cb-b9d5-f8f5cc6c5f23	\N	["guest"]	pending	\N	\N
perf-test-1-fd7d86b2@example.com	Performance User 1	password	\N	\N	t	2025-08-29 22:02:01.389522+07	2025-08-29 22:02:01.389522+07	fd7d86b2-a0d9-4af6-970a-621b13f5e0da	\N	["guest"]	pending	\N	\N
perf-test-2-3cdf60a0@example.com	Performance User 2	password	\N	\N	t	2025-08-29 22:02:01.390158+07	2025-08-29 22:02:01.390158+07	3cdf60a0-07f3-45dd-9396-fd7ed240b66c	\N	["guest"]	pending	\N	\N
perf-test-3-fbaa74c8@example.com	Performance User 3	password	\N	\N	t	2025-08-29 22:02:01.39072+07	2025-08-29 22:02:01.390721+07	fbaa74c8-4d26-4ae0-8031-8c39f501a215	\N	["guest"]	pending	\N	\N
perf-test-4-f073c24d@example.com	Performance User 4	password	\N	\N	t	2025-08-29 22:02:01.391264+07	2025-08-29 22:02:01.391264+07	f073c24d-6954-4a0d-b339-6af1c9f5bd0e	\N	["guest"]	pending	\N	\N
perf-test-5-fc882718@example.com	Performance User 5	password	\N	\N	t	2025-08-29 22:02:01.391663+07	2025-08-29 22:02:01.391663+07	fc882718-0f5d-4665-8c64-1a7d7bf20313	\N	["guest"]	pending	\N	\N
perf-test-6-3c74687b@example.com	Performance User 6	password	\N	\N	t	2025-08-29 22:02:01.392104+07	2025-08-29 22:02:01.392104+07	3c74687b-8820-4c84-a355-a30371ad562b	\N	["guest"]	pending	\N	\N
perf-test-7-c0574b3f@example.com	Performance User 7	password	\N	\N	t	2025-08-29 22:02:01.392474+07	2025-08-29 22:02:01.392474+07	c0574b3f-6edd-4c34-a45b-8d3ddcbae9ca	\N	["guest"]	pending	\N	\N
perf-test-8-1e5f5a74@example.com	Performance User 8	password	\N	\N	t	2025-08-29 22:02:01.392909+07	2025-08-29 22:02:01.392909+07	1e5f5a74-d284-4e49-8747-82b0c2f98314	\N	["guest"]	pending	\N	\N
perf-test-9-28034b61@example.com	Performance User 9	password	\N	\N	t	2025-08-29 22:02:01.393265+07	2025-08-29 22:02:01.393265+07	28034b61-4646-4c18-9bec-05167adf2a40	\N	["guest"]	pending	\N	\N
perf-test-10-6fd88bda@example.com	Performance User 10	password	\N	\N	t	2025-08-29 22:02:01.393677+07	2025-08-29 22:02:01.393677+07	6fd88bda-04b4-4602-b38c-8d33fd1dc985	\N	["guest"]	pending	\N	\N
perf-test-11-ba61d12d@example.com	Performance User 11	password	\N	\N	t	2025-08-29 22:02:01.394054+07	2025-08-29 22:02:01.394054+07	ba61d12d-0ac7-4f17-9d81-ff178ca32046	\N	["guest"]	pending	\N	\N
perf-test-12-a9363ccf@example.com	Performance User 12	password	\N	\N	t	2025-08-29 22:02:01.394401+07	2025-08-29 22:02:01.394401+07	a9363ccf-aaa3-4ab1-a124-df9f9b9dc46b	\N	["guest"]	pending	\N	\N
perf-test-13-e9066ad1@example.com	Performance User 13	password	\N	\N	t	2025-08-29 22:02:01.394781+07	2025-08-29 22:02:01.394781+07	e9066ad1-ddc3-46a4-b208-546a953d2370	\N	["guest"]	pending	\N	\N
perf-test-14-98fc405b@example.com	Performance User 14	password	\N	\N	t	2025-08-29 22:02:01.395119+07	2025-08-29 22:02:01.395119+07	98fc405b-8a2f-424b-b4f1-6499c7fbe84d	\N	["guest"]	pending	\N	\N
perf-test-15-168959cd@example.com	Performance User 15	password	\N	\N	t	2025-08-29 22:02:01.395556+07	2025-08-29 22:02:01.395556+07	168959cd-250b-488e-b13a-3240ae3dd22b	\N	["guest"]	pending	\N	\N
perf-test-16-bd3681f3@example.com	Performance User 16	password	\N	\N	t	2025-08-29 22:02:01.395932+07	2025-08-29 22:02:01.395932+07	bd3681f3-7925-4aa0-99e8-31bdf2e9f5d4	\N	["guest"]	pending	\N	\N
perf-test-17-e63e11b2@example.com	Performance User 17	password	\N	\N	t	2025-08-29 22:02:01.396332+07	2025-08-29 22:02:01.396332+07	e63e11b2-2998-4655-a5db-911987c6faff	\N	["guest"]	pending	\N	\N
perf-test-18-0fe8c4fd@example.com	Performance User 18	password	\N	\N	t	2025-08-29 22:02:01.396833+07	2025-08-29 22:02:01.396833+07	0fe8c4fd-6c3b-4759-ae27-46639808f7b2	\N	["guest"]	pending	\N	\N
perf-test-19-6ecc6a9e@example.com	Performance User 19	password	\N	\N	t	2025-08-29 22:02:01.397404+07	2025-08-29 22:02:01.397404+07	6ecc6a9e-252a-4674-b496-ac76ba4a9f6c	\N	["guest"]	pending	\N	\N
perf-test-20-cf0b4b2d@example.com	Performance User 20	password	\N	\N	t	2025-08-29 22:02:01.398026+07	2025-08-29 22:02:01.398026+07	cf0b4b2d-2b79-49b4-9f38-e27d934024fb	\N	["guest"]	pending	\N	\N
perf-test-21-4fc639fe@example.com	Performance User 21	password	\N	\N	t	2025-08-29 22:02:01.398611+07	2025-08-29 22:02:01.398611+07	4fc639fe-ba37-45ef-bf67-ff1d347f1fdf	\N	["guest"]	pending	\N	\N
perf-test-22-b761c172@example.com	Performance User 22	password	\N	\N	t	2025-08-29 22:02:01.39917+07	2025-08-29 22:02:01.39917+07	b761c172-acc4-4028-ad02-ea84e1d76672	\N	["guest"]	pending	\N	\N
perf-test-23-5926442f@example.com	Performance User 23	password	\N	\N	t	2025-08-29 22:02:01.3997+07	2025-08-29 22:02:01.3997+07	5926442f-4393-449e-aff9-9691f6b33508	\N	["guest"]	pending	\N	\N
perf-test-24-8716a397@example.com	Performance User 24	password	\N	\N	t	2025-08-29 22:02:01.400176+07	2025-08-29 22:02:01.400176+07	8716a397-3785-4e06-abfb-48abef87ecb0	\N	["guest"]	pending	\N	\N
perf-test-25-8134b557@example.com	Performance User 25	password	\N	\N	t	2025-08-29 22:02:01.400657+07	2025-08-29 22:02:01.400657+07	8134b557-6e31-4f29-830f-bdd738d91abf	\N	["guest"]	pending	\N	\N
perf-test-26-0c574bd3@example.com	Performance User 26	password	\N	\N	t	2025-08-29 22:02:01.401032+07	2025-08-29 22:02:01.401033+07	0c574bd3-0a59-4096-bedf-7a929443fe26	\N	["guest"]	pending	\N	\N
perf-test-27-49086ab3@example.com	Performance User 27	password	\N	\N	t	2025-08-29 22:02:01.401415+07	2025-08-29 22:02:01.401415+07	49086ab3-2e13-45ac-a9ce-8a05edda3c10	\N	["guest"]	pending	\N	\N
perf-test-28-56ac419f@example.com	Performance User 28	password	\N	\N	t	2025-08-29 22:02:01.401735+07	2025-08-29 22:02:01.401735+07	56ac419f-00e2-4ccb-9766-d9357f710d13	\N	["guest"]	pending	\N	\N
perf-test-29-756f569f@example.com	Performance User 29	password	\N	\N	t	2025-08-29 22:02:01.402138+07	2025-08-29 22:02:01.402138+07	756f569f-d682-4347-acb9-f599aac62bfb	\N	["guest"]	pending	\N	\N
perf-test-30-58276b2b@example.com	Performance User 30	password	\N	\N	t	2025-08-29 22:02:01.402461+07	2025-08-29 22:02:01.402461+07	58276b2b-c7ca-43d2-becd-faba5c223085	\N	["guest"]	pending	\N	\N
perf-test-31-59cd99aa@example.com	Performance User 31	password	\N	\N	t	2025-08-29 22:02:01.40284+07	2025-08-29 22:02:01.40284+07	59cd99aa-ca21-4b51-aafb-29174dab31c6	\N	["guest"]	pending	\N	\N
perf-test-32-7c1090fd@example.com	Performance User 32	password	\N	\N	t	2025-08-29 22:02:01.403175+07	2025-08-29 22:02:01.403175+07	7c1090fd-0d69-47e2-9b7d-d9ba84229aa0	\N	["guest"]	pending	\N	\N
perf-test-33-9db3f47d@example.com	Performance User 33	password	\N	\N	t	2025-08-29 22:02:01.40365+07	2025-08-29 22:02:01.40365+07	9db3f47d-4e5b-447c-95ac-489236caef35	\N	["guest"]	pending	\N	\N
perf-test-34-37623386@example.com	Performance User 34	password	\N	\N	t	2025-08-29 22:02:01.404188+07	2025-08-29 22:02:01.404188+07	37623386-7f80-4f97-9a11-e9d8da41adf2	\N	["guest"]	pending	\N	\N
perf-test-35-55438aca@example.com	Performance User 35	password	\N	\N	t	2025-08-29 22:02:01.404626+07	2025-08-29 22:02:01.404627+07	55438aca-ba2a-4988-a275-63d11caea396	\N	["guest"]	pending	\N	\N
perf-test-36-805bd61b@example.com	Performance User 36	password	\N	\N	t	2025-08-29 22:02:01.405136+07	2025-08-29 22:02:01.405136+07	805bd61b-b792-47f7-8114-c6342a2f7642	\N	["guest"]	pending	\N	\N
perf-test-37-e02d6d0f@example.com	Performance User 37	password	\N	\N	t	2025-08-29 22:02:01.405726+07	2025-08-29 22:02:01.405726+07	e02d6d0f-a6fa-4860-b996-0fa844ddb0c2	\N	["guest"]	pending	\N	\N
perf-test-38-64a13930@example.com	Performance User 38	password	\N	\N	t	2025-08-29 22:02:01.40693+07	2025-08-29 22:02:01.40693+07	64a13930-1112-4f3f-966e-e2e9c38629f7	\N	["guest"]	pending	\N	\N
perf-test-39-bce212e9@example.com	Performance User 39	password	\N	\N	t	2025-08-29 22:02:01.408194+07	2025-08-29 22:02:01.408194+07	bce212e9-6c99-4990-bb57-65f747c3cc6f	\N	["guest"]	pending	\N	\N
perf-test-40-2f8a1a4e@example.com	Performance User 40	password	\N	\N	t	2025-08-29 22:02:01.408668+07	2025-08-29 22:02:01.408668+07	2f8a1a4e-3242-493d-94cf-a6f4c396c3c3	\N	["guest"]	pending	\N	\N
perf-test-41-cba690f5@example.com	Performance User 41	password	\N	\N	t	2025-08-29 22:02:01.409053+07	2025-08-29 22:02:01.409053+07	cba690f5-7bfb-4aef-b56b-ccb666ffa32c	\N	["guest"]	pending	\N	\N
perf-test-42-83eddf41@example.com	Performance User 42	password	\N	\N	t	2025-08-29 22:02:01.409494+07	2025-08-29 22:02:01.409494+07	83eddf41-cf6d-4f29-8ca0-bf43a2ddbcd6	\N	["guest"]	pending	\N	\N
perf-test-43-82fd5c20@example.com	Performance User 43	password	\N	\N	t	2025-08-29 22:02:01.409876+07	2025-08-29 22:02:01.409876+07	82fd5c20-d834-4990-8894-168b3076a23e	\N	["guest"]	pending	\N	\N
perf-test-44-709d7ea2@example.com	Performance User 44	password	\N	\N	t	2025-08-29 22:02:01.410262+07	2025-08-29 22:02:01.410262+07	709d7ea2-3bc2-4baf-aceb-3e71e8c9660d	\N	["guest"]	pending	\N	\N
perf-test-45-f10819b1@example.com	Performance User 45	password	\N	\N	t	2025-08-29 22:02:01.410604+07	2025-08-29 22:02:01.410604+07	f10819b1-06fd-44ef-a27c-d09f0e6621d0	\N	["guest"]	pending	\N	\N
perf-test-46-966f6d18@example.com	Performance User 46	password	\N	\N	t	2025-08-29 22:02:01.410986+07	2025-08-29 22:02:01.410986+07	966f6d18-2879-4118-9408-155beb465d04	\N	["guest"]	pending	\N	\N
perf-test-47-c779d490@example.com	Performance User 47	password	\N	\N	t	2025-08-29 22:02:01.411331+07	2025-08-29 22:02:01.411331+07	c779d490-ec8c-4774-aed7-5c95dd6881d2	\N	["guest"]	pending	\N	\N
perf-test-48-7289b5d8@example.com	Performance User 48	password	\N	\N	t	2025-08-29 22:02:01.411732+07	2025-08-29 22:02:01.411732+07	7289b5d8-bc50-46dc-ab20-4ee41967f721	\N	["guest"]	pending	\N	\N
perf-test-49-99d57795@example.com	Performance User 49	password	\N	\N	t	2025-08-29 22:02:01.412123+07	2025-08-29 22:02:01.412123+07	99d57795-172f-4170-8546-037f9ba74cde	\N	["guest"]	pending	\N	\N
testuser1756491699592@example.com	Test User	$2a$10$iHSQuUcI6i5MBX.auMQHFeAT1wYN3cM/pDlFgA2vh6LReX6usbKti	+1234567890	Test Address	t	2025-08-30 01:21:39.718193+07	2025-08-30 01:21:39.718193+07	05fa57c3-456d-4c60-bcc2-32f68b0458bb	\N	["member"]	pending	\N	\N
testuser1756491722741@example.com	Test User	$2a$10$D4jA/C4X14YwP9y5DFh8mOH3DTFHqcYyGhIJOKwOrdwck2p244j2G	+1234567890	Test Address	t	2025-08-30 01:22:02.873573+07	2025-08-30 01:22:02.873573+07	854f9ed7-341e-49d0-a01a-3b459b3094c6	\N	["member"]	pending	\N	\N
kharisma@hajifund.coop	Kharisma	$2a$10$AH4Bpxp3LRmwYbXFvcR6j.BDdXcVpuHcY2r3lP62FvN3T.e6o6tW.	+62-812-34567890	Jl. Kharisma No. 10, Jakarta	t	2025-08-31 12:17:19.930347+07	2025-08-31 12:17:19.930347+07	9aa65130-e96a-4f2a-bc6a-a4aae4090b6f	\N	["member", "business_owner"]	pending	\N	\N
investor2@comfunds.com	Test Investor 2	$2a$10$78b0F/iIP3P./7s1ccJlhehacdDRP1Z1vOuAaN.XVGJLNAfUmaB6u	+62-822-22222222	Jl. Investor No. 2, Jakarta	t	2025-08-31 12:20:23.530136+07	2025-08-31 12:20:23.530136+07	abf6eea3-7fb4-42f0-b0d6-74462b902633	\N	["investor"]	pending	\N	\N
test_user_007@hajifund.com	test_user_007	$2a$10$EjwohLo6BHso3rDMyxiuwu5zodOCLAGt1voQpPZ3Rlu6NNHKnc3gW	+62812345007	Jakarta, Indonesia	t	2025-09-05 22:52:02.693784+07	2025-09-05 22:52:02.693784+07	73d68f5d-d239-4e2a-9567-9a9520a5e153	\N	["member"]	pending	\N	\N
admin@comfunds.com	System Admin	$2a$10$HvRfCNvBK/OBlbwF8.jOG.w9aqbWxJo.qzMbbn9NccLyYO501HxXS	+6281234567890	Admin Address	t	2025-09-07 16:55:49.863207+07	2025-09-07 16:55:49.863207+07	132672e6-0a0a-421e-a668-57be5923c0df	\N	["admin"]	pending	\N	\N
rahmatarkan475@gmail.com	User	$2a$10$UOzXJTwmtMeJ9gDf3UqkbegRNRkZjqCWWakv6XBDIGozKcObYsUnu	081214548513	Majalengka	t	2025-09-07 16:34:48.84446+07	2025-09-07 16:56:19.590435+07	6f2e7758-cc9d-4bb3-9d49-85a315a8e96e	\N	["business_owner"]	pending	\N	\N
ahmad.rahman@example.com	Ahmad Rahman	$2a$10$AFLit4VhclSRGObPVrkJJutH8Oxs7x0TmH1uKB5jRhMzL8K.GTn1i	+62-812-3456-7890	Jl. Sudirman No. 123, Jakarta	t	2025-09-19 19:44:52.471861+07	2025-09-19 19:44:52.471861+07	6a8f4a85-7ec4-4033-9746-8d963c069ebb	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N	\N
testHaji01@hajifund.com	testHaji01	$2a$10$N.uQnaw7ChUsb9pR0MeRWuOpA8JbDzVqjMYZH5A2ACdg9S8RfViJK	081110100101	Jl. Haji Nawi No.17 Jakarta Selatan	t	2025-09-19 19:50:29.800842+07	2025-09-19 19:50:29.800842+07	acb211e5-21b2-4270-aad8-843d650c92f5	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
testbusinessowner1758339156@hajifund.com	Test Business Owner	$2a$10$xpuSa85kukb.eVZfPXEeO.hpbmJj/QmwXjmIbcHTOQjj9zkiBo78C	+62-800-TEST-01	Jl. Test Business Owner No. 1	t	2025-09-20 10:32:36.781192+07	2025-09-20 10:32:36.781192+07	11bc4c81-43de-4f36-9db1-3dce1cecc48d	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
testowner@hajifund.com	Test Owner	$2a$10$bi1xcDHgwtTHHpYGkaJzBuhMqThuFTWsP9T34MEI3Qo7wbCeOHIJ2	+62-800-TEST-01	Jl. Test Owner No. 1	t	2025-09-20 10:41:06.167616+07	2025-09-20 10:41:06.167616+07	192f42c5-f89b-4c9d-b96b-60d02a303c4a	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
debugowner4@hajifund.com	Debug Owner 4	$2a$10$90G9A0bYpS19Q87RzR.1g.QpqnH6dil2XuHGEi4/0dWj0ylJ0nJ8K	+62-800-DEBUG4	Jl. Debug Owner 4 No. 1	t	2025-09-20 10:44:33.992208+07	2025-09-20 10:44:33.992208+07	9d7d3584-9b3a-4692-86f7-f87695b2f7a7	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
fixedowner@hajifund.com	Fixed Owner	$2a$10$q2D/bG5z1qeVxKz1hSURJe6dW1.GsdNyqyvRfd5/zS9Et0.wEhq3C	+62-800-FIXED	Jl. Fixed Owner No. 1	t	2025-09-20 10:48:56.521355+07	2025-09-20 10:48:56.521355+07	dc2b0274-a407-46ae-8030-28c27859a5f2	550e8400-e29b-41d4-a716-446655440001	["business_owner"]	pending	\N	\N
testuser1758353974@example.com	Test User	$2a$10$.lx4zv5c/e8Y5BZ5rC.yHeZUilIlkxArP6iCqnJQ06H4bEoIW0fka	08123456789	Test Address	t	2025-09-20 14:39:34.330101+07	2025-09-20 14:39:34.330101+07	5a2b5efd-cd6f-44e0-9b44-6c17e1e8601e	\N	["business_owner"]	pending	\N	\N
quickadmin1758356101@test.com	Quick Admin	$2a$10$phnohOwZT0AvxZE9eu/jMOR4OyPLgaxdZYjAj8AWitqGEsg2x5qOS	08123456789	Admin Address	t	2025-09-20 15:15:25.441201+07	2025-09-20 15:15:25.441201+07	b83a14eb-e400-4f22-baa6-7bd2502f4f98	\N	["admin"]	pending	\N	\N
cobauser@gmail.com	Test User Coba 13456	$2a$10$vV0ceFDSQWTe05ipQe7ReOnyXQDjeL/s4oV4jDqX7QfCTmFDSWgN.	+628113333333456	contoh alamat	t	2025-10-11 12:08:52.459251+07	2025-10-11 12:09:17.108432+07	9354b628-5c47-401e-84f4-a14a803ee9b0	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner"]	pending	\N	\N
user1234@gmail.com	Coba User1234	$2a$10$ltYdxaFQ9IblxVvyq7G7Cee7eCTulWbZfgfNEOFwKP/k6AjHDVp2K	+62811399999999	Contoh Alamat User 1234 akan di ketik disini yaa.	t	2025-11-18 17:25:13.322259+07	2025-11-18 17:25:13.322259+07	b3823ee7-b0a6-4de5-a196-628609faf486	550e8400-e29b-41d4-a716-446655440001	["investor", "business_owner", "investor", "business_owner"]	pending	\N	/uploads/documents/register/payment_proof_20251118_172513_3150fd2f.jpg


ALTER TABLE public.users ENABLE TRIGGER ALL;


ALTER TABLE public.projects DISABLE TRIGGER ALL;

COPY public.projects (id, title, description, business_id, funding_goal, minimum_funding, current_funding, funding_deadline, profit_sharing_ratio, project_type, status, milestones, documents, created_at, updated_at, project_image_1, project_image_2, project_image_3, min_investment, risk_level, investment_period, expected_return, start_date, end_date, target_amount, raised_amount, category, owner_id, cooperative_id, approved_by, approved_at, approval_status, rejected_by, rejected_at, rejection_reason, reviewer_comments, sharia_compliant) FROM stdin;
624326bf-5f06-4b60-b83b-fadcbeca1054	Ekspansi Restoran Pecel Lele - Buka Cabang Kedua	Kami ingin membuka cabang kedua Restoran Pecel Lele kami di lokasi strategis dekat kampus. Dengan pengalaman 3 tahun menjalankan restoran pertama yang sudah profitable, kami yakin dapat mereplikasi kesuksesan ini. Dana akan digunakan untuk: renovasi tempat (40%), peralatan dapur (30%), modal kerja awal (20%), dan marketing (10%). Target BEP 8 bulan.	09176669-b045-4e33-8ae2-8febe34a16cf	\N	\N	0.00	\N	{"business": 30, "investor": 70}	expansion	draft	[]	{}	2025-10-09 02:00:52.603335+07	2025-10-09 02:00:52.603335+07	\N	\N	\N	5000000.00	Medium	24	15-20% per tahun	\N	\N	150000000.00	0.00	Food & Beverage	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	\N	\N	pending	\N	\N	\N	\N	f
2c15c509-dda1-4612-858c-c256447ce874	Upgrade Peralatan Dapur & Sistem POS Modern	Untuk meningkatkan efisiensi operasional, kami membutuhkan upgrade peralatan dapur yang lebih modern dan implementasi sistem POS terintegrasi. Investasi ini akan: meningkatkan kecepatan pelayanan 40%, mengurangi food waste 25%, dan memberikan data analytics untuk pengambilan keputusan bisnis yang lebih baik. ROI diperkirakan 18 bulan.	09176669-b045-4e33-8ae2-8febe34a16cf	\N	\N	0.00	\N	{"business": 30, "investor": 70}	equipment	submitted	[]	{}	2025-10-02 02:01:04.831282+07	2025-10-09 02:01:04.831282+07	\N	\N	\N	2000000.00	Low	18	12-18% per tahun	\N	\N	75000000.00	15000000.00	Food & Beverage	e88a50d6-20c7-4eae-b83a-af850166bb01	550e8400-e29b-41d4-a716-446655440001	\N	\N	approved	\N	\N	\N	\N	f


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
SELECT 'Database comfunds03 restored successfully!' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public';
