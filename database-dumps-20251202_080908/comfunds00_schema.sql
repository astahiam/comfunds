--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Postgres.app)
-- Dumped by pg_dump version 16.3 (Postgres.app)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_rejected_by_fkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS fk_users_cooperative;
ALTER TABLE IF EXISTS ONLY public.profit_distributions DROP CONSTRAINT IF EXISTS fk_profit_distributions_project;
ALTER TABLE IF EXISTS ONLY public.investments DROP CONSTRAINT IF EXISTS fk_investments_project;
ALTER TABLE IF EXISTS ONLY public.investments DROP CONSTRAINT IF EXISTS fk_investments_investor;
ALTER TABLE IF EXISTS ONLY public.investment_returns DROP CONSTRAINT IF EXISTS fk_investment_returns_investment;
ALTER TABLE IF EXISTS ONLY public.investment_returns DROP CONSTRAINT IF EXISTS fk_investment_returns_distribution;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
DROP TRIGGER IF EXISTS update_profit_distributions_updated_at ON public.profit_distributions;
DROP TRIGGER IF EXISTS update_investments_updated_at ON public.investments;
DROP TRIGGER IF EXISTS update_investment_returns_updated_at ON public.investment_returns;
DROP TRIGGER IF EXISTS update_cooperatives_updated_at ON public.cooperatives;
DROP TRIGGER IF EXISTS update_businesses_updated_at ON public.businesses;
DROP TRIGGER IF EXISTS trigger_update_images_updated_at ON public.images;
DROP INDEX IF EXISTS public.idx_users_roles;
DROP INDEX IF EXISTS public.idx_users_phone;
DROP INDEX IF EXISTS public.idx_users_name_search;
DROP INDEX IF EXISTS public.idx_users_name;
DROP INDEX IF EXISTS public.idx_users_membership_payment_proof;
DROP INDEX IF EXISTS public.idx_users_kyc_status;
DROP INDEX IF EXISTS public.idx_users_is_active;
DROP INDEX IF EXISTS public.idx_users_email;
DROP INDEX IF EXISTS public.idx_users_created_at;
DROP INDEX IF EXISTS public.idx_users_cooperative_id;
DROP INDEX IF EXISTS public.idx_projects_title_type;
DROP INDEX IF EXISTS public.idx_projects_title;
DROP INDEX IF EXISTS public.idx_projects_status_type;
DROP INDEX IF EXISTS public.idx_projects_status;
DROP INDEX IF EXISTS public.idx_projects_start_date;
DROP INDEX IF EXISTS public.idx_projects_risk_level;
DROP INDEX IF EXISTS public.idx_projects_rejected_by;
DROP INDEX IF EXISTS public.idx_projects_project_type;
DROP INDEX IF EXISTS public.idx_projects_owner_id;
DROP INDEX IF EXISTS public.idx_projects_investment_period;
DROP INDEX IF EXISTS public.idx_projects_funding_goal;
DROP INDEX IF EXISTS public.idx_projects_funding_deadline;
DROP INDEX IF EXISTS public.idx_projects_created_at;
DROP INDEX IF EXISTS public.idx_projects_cooperative_id;
DROP INDEX IF EXISTS public.idx_projects_category;
DROP INDEX IF EXISTS public.idx_projects_business_id;
DROP INDEX IF EXISTS public.idx_projects_approved_by;
DROP INDEX IF EXISTS public.idx_projects_approval_status;
DROP INDEX IF EXISTS public.idx_profit_distributions_status;
DROP INDEX IF EXISTS public.idx_profit_distributions_project_id;
DROP INDEX IF EXISTS public.idx_profit_distributions_distribution_date;
DROP INDEX IF EXISTS public.idx_profit_distributions_created_at;
DROP INDEX IF EXISTS public.idx_investments_transaction_ref;
DROP INDEX IF EXISTS public.idx_investments_status;
DROP INDEX IF EXISTS public.idx_investments_project_id;
DROP INDEX IF EXISTS public.idx_investments_investor_id;
DROP INDEX IF EXISTS public.idx_investments_investment_date;
DROP INDEX IF EXISTS public.idx_investments_created_at;
DROP INDEX IF EXISTS public.idx_investment_returns_transaction_ref;
DROP INDEX IF EXISTS public.idx_investment_returns_status;
DROP INDEX IF EXISTS public.idx_investment_returns_payment_date;
DROP INDEX IF EXISTS public.idx_investment_returns_investment_id;
DROP INDEX IF EXISTS public.idx_investment_returns_distribution_id;
DROP INDEX IF EXISTS public.idx_investment_returns_created_at;
DROP INDEX IF EXISTS public.idx_images_used_by;
DROP INDEX IF EXISTS public.idx_images_created_at;
DROP INDEX IF EXISTS public.idx_idempotency_user_endpoint;
DROP INDEX IF EXISTS public.idx_idempotency_table_name;
DROP INDEX IF EXISTS public.idx_idempotency_sequence;
DROP INDEX IF EXISTS public.idx_idempotency_expires_at;
DROP INDEX IF EXISTS public.idx_cooperatives_registration_number;
DROP INDEX IF EXISTS public.idx_cooperatives_name;
DROP INDEX IF EXISTS public.idx_cooperatives_is_active;
DROP INDEX IF EXISTS public.idx_cooperatives_email;
DROP INDEX IF EXISTS public.idx_cooperatives_created_at;
DROP INDEX IF EXISTS public.idx_businesses_status;
DROP INDEX IF EXISTS public.idx_businesses_registration_number;
DROP INDEX IF EXISTS public.idx_businesses_owner_id;
DROP INDEX IF EXISTS public.idx_businesses_name_type;
DROP INDEX IF EXISTS public.idx_businesses_name;
DROP INDEX IF EXISTS public.idx_businesses_is_active;
DROP INDEX IF EXISTS public.idx_businesses_industry;
DROP INDEX IF EXISTS public.idx_businesses_email;
DROP INDEX IF EXISTS public.idx_businesses_created_at;
DROP INDEX IF EXISTS public.idx_businesses_cooperative_id;
DROP INDEX IF EXISTS public.idx_businesses_business_type;
DROP INDEX IF EXISTS public.idx_businesses_approved_by;
DROP INDEX IF EXISTS public.idx_businesses_approved_at;
DROP INDEX IF EXISTS public.idx_businesses_approval_status;
DROP INDEX IF EXISTS public.idx_audit_logs_user_operation;
DROP INDEX IF EXISTS public.idx_audit_logs_user_id;
DROP INDEX IF EXISTS public.idx_audit_logs_status;
DROP INDEX IF EXISTS public.idx_audit_logs_operation;
DROP INDEX IF EXISTS public.idx_audit_logs_entity_type;
DROP INDEX IF EXISTS public.idx_audit_logs_entity_operation;
DROP INDEX IF EXISTS public.idx_audit_logs_entity_id;
DROP INDEX IF EXISTS public.idx_audit_logs_created_at;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.investments DROP CONSTRAINT IF EXISTS unique_investor_project;
ALTER TABLE IF EXISTS ONLY public.investment_returns DROP CONSTRAINT IF EXISTS unique_investment_distribution;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_pkey;
ALTER TABLE IF EXISTS ONLY public.profit_distributions DROP CONSTRAINT IF EXISTS profit_distributions_pkey;
ALTER TABLE IF EXISTS ONLY public.investments DROP CONSTRAINT IF EXISTS investments_transaction_ref_key;
ALTER TABLE IF EXISTS ONLY public.investments DROP CONSTRAINT IF EXISTS investments_pkey;
ALTER TABLE IF EXISTS ONLY public.investment_returns DROP CONSTRAINT IF EXISTS investment_returns_transaction_ref_key;
ALTER TABLE IF EXISTS ONLY public.investment_returns DROP CONSTRAINT IF EXISTS investment_returns_pkey;
ALTER TABLE IF EXISTS ONLY public.images DROP CONSTRAINT IF EXISTS images_pkey;
ALTER TABLE IF EXISTS ONLY public.idempotency_keys DROP CONSTRAINT IF EXISTS idempotency_keys_pkey;
ALTER TABLE IF EXISTS ONLY public.cooperatives DROP CONSTRAINT IF EXISTS cooperatives_registration_number_key;
ALTER TABLE IF EXISTS ONLY public.cooperatives DROP CONSTRAINT IF EXISTS cooperatives_pkey;
ALTER TABLE IF EXISTS ONLY public.businesses DROP CONSTRAINT IF EXISTS businesses_pkey;
ALTER TABLE IF EXISTS ONLY public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_pkey;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.projects;
DROP TABLE IF EXISTS public.profit_distributions;
DROP TABLE IF EXISTS public.investments;
DROP TABLE IF EXISTS public.investment_returns;
DROP TABLE IF EXISTS public.images;
DROP SEQUENCE IF EXISTS public.idempotency_sequence;
DROP TABLE IF EXISTS public.idempotency_keys;
DROP SEQUENCE IF EXISTS public.global_transaction_seq;
DROP TABLE IF EXISTS public.cooperatives;
DROP TABLE IF EXISTS public.businesses;
DROP TABLE IF EXISTS public.audit_logs;
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.update_images_updated_at();
DROP EXTENSION IF EXISTS "uuid-ossp";
--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_images_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_images_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_images_updated_at() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    operation character varying(20) NOT NULL,
    user_id uuid NOT NULL,
    ip_address inet,
    user_agent text,
    changes jsonb,
    old_values jsonb,
    new_values jsonb,
    reason text,
    status character varying(20) DEFAULT 'SUCCESS'::character varying NOT NULL,
    error_msg text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT audit_logs_operation_check CHECK (((operation)::text = ANY ((ARRAY['CREATE'::character varying, 'READ'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'LOGIN'::character varying, 'LOGOUT'::character varying])::text[]))),
    CONSTRAINT audit_logs_status_check CHECK (((status)::text = ANY ((ARRAY['SUCCESS'::character varying, 'FAILED'::character varying, 'UNAUTHORIZED'::character varying])::text[])))
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: businesses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.businesses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    business_type character varying(100) NOT NULL,
    description text,
    owner_id uuid NOT NULL,
    cooperative_id uuid NOT NULL,
    registration_documents jsonb DEFAULT '{}'::jsonb,
    approval_status character varying(20) DEFAULT 'pending'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    business_image character varying(500),
    registration_number character varying(100),
    tax_id character varying(50),
    legal_structure character varying(100),
    industry character varying(100),
    sector character varying(100),
    address text,
    phone character varying(50),
    email character varying(255),
    website character varying(500),
    established_date date,
    employee_count integer DEFAULT 0,
    annual_revenue numeric(15,2) DEFAULT 0.00,
    currency character varying(3) DEFAULT 'IDR'::character varying,
    bank_account character varying(100),
    business_license character varying(500),
    documents jsonb DEFAULT '[]'::jsonb,
    status character varying(50) DEFAULT 'draft'::character varying,
    approved_by uuid,
    approved_at timestamp with time zone,
    rejection_reason text,
    metadata jsonb DEFAULT '{}'::jsonb,
    performance_metrics jsonb DEFAULT '{}'::jsonb,
    compliance_status jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT chk_approval_status CHECK (((approval_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_business_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'rejected'::character varying, 'suspended'::character varying, 'active'::character varying, 'inactive'::character varying])::text[])))
);


ALTER TABLE public.businesses OWNER TO postgres;

--
-- Name: COLUMN businesses.business_image; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.businesses.business_image IS 'Business logo/image URL from AWS S3';


--
-- Name: cooperatives; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cooperatives (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    registration_number character varying(100) NOT NULL,
    address text NOT NULL,
    phone character varying(50) NOT NULL,
    email character varying(255) NOT NULL,
    bank_account character varying(100) NOT NULL,
    profit_sharing_policy jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    cooperative_image character varying(500)
);


ALTER TABLE public.cooperatives OWNER TO postgres;

--
-- Name: COLUMN cooperatives.cooperative_image; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cooperatives.cooperative_image IS 'Cooperative logo/image URL from AWS S3';


--
-- Name: global_transaction_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.global_transaction_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.global_transaction_seq OWNER TO postgres;

--
-- Name: idempotency_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.idempotency_keys (
    id character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    endpoint character varying(255) NOT NULL,
    request_hash character varying(64) NOT NULL,
    response_data jsonb,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone NOT NULL,
    sequence_number integer NOT NULL,
    table_name character varying(100) NOT NULL,
    random_suffix character varying(5) NOT NULL
);


ALTER TABLE public.idempotency_keys OWNER TO postgres;

--
-- Name: TABLE idempotency_keys; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.idempotency_keys IS 'Stores idempotency keys to prevent duplicate transactions';


--
-- Name: COLUMN idempotency_keys.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.id IS 'Format: yyyymmddhhmm + sequence_number + table_name + 5_random_chars';


--
-- Name: COLUMN idempotency_keys.sequence_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.sequence_number IS 'Auto-incrementing sequence number';


--
-- Name: COLUMN idempotency_keys.table_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.table_name IS 'Target table name for the transaction';


--
-- Name: COLUMN idempotency_keys.random_suffix; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.idempotency_keys.random_suffix IS '5 random alphanumeric characters';


--
-- Name: idempotency_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.idempotency_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.idempotency_sequence OWNER TO postgres;

--
-- Name: images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    image_url character varying(500) NOT NULL,
    image_name character varying(255) NOT NULL,
    used_by character varying(50) NOT NULL,
    image_size bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.images OWNER TO postgres;

--
-- Name: investment_returns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.investment_returns (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    investment_id uuid NOT NULL,
    distribution_id uuid NOT NULL,
    return_amount numeric(15,2) NOT NULL,
    return_percentage numeric(5,2) NOT NULL,
    payment_date timestamp with time zone,
    status character varying(20) DEFAULT 'pending'::character varying,
    transaction_ref character varying(50) DEFAULT ((('RTN-'::text || (EXTRACT(epoch FROM CURRENT_TIMESTAMP))::bigint) || '-'::text) || nextval('public.global_transaction_seq'::regclass)) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_return_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'paid'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT investment_returns_return_amount_check CHECK ((return_amount >= (0)::numeric)),
    CONSTRAINT investment_returns_return_percentage_check CHECK ((return_percentage >= (0)::numeric))
);


ALTER TABLE public.investment_returns OWNER TO postgres;

--
-- Name: investments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.investments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    investor_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    investment_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    profit_sharing_percentage numeric(5,2) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    transaction_ref character varying(50) DEFAULT ((('TXN-'::text || (EXTRACT(epoch FROM CURRENT_TIMESTAMP))::bigint) || '-'::text) || nextval('public.global_transaction_seq'::regclass)) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_investment_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'refunded'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT investments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT investments_profit_sharing_percentage_check CHECK (((profit_sharing_percentage >= (0)::numeric) AND (profit_sharing_percentage <= (100)::numeric)))
);


ALTER TABLE public.investments OWNER TO postgres;

--
-- Name: profit_distributions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profit_distributions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    business_profit numeric(15,2) NOT NULL,
    distribution_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    total_distributed numeric(15,2) NOT NULL,
    status character varying(20) DEFAULT 'calculated'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_distribution_status CHECK (((status)::text = ANY ((ARRAY['calculated'::character varying, 'approved'::character varying, 'distributed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT profit_distributions_total_distributed_check CHECK ((total_distributed >= (0)::numeric))
);


ALTER TABLE public.profit_distributions OWNER TO postgres;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    business_id uuid NOT NULL,
    funding_goal numeric(15,2),
    minimum_funding numeric(15,2),
    current_funding numeric(15,2) DEFAULT 0 NOT NULL,
    funding_deadline timestamp with time zone,
    profit_sharing_ratio jsonb DEFAULT '{"business": 30, "investor": 70}'::jsonb NOT NULL,
    project_type character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying,
    milestones jsonb DEFAULT '[]'::jsonb,
    documents jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    project_image_1 character varying(500),
    project_image_2 character varying(500),
    project_image_3 character varying(500),
    min_investment numeric(15,2),
    risk_level character varying(20),
    investment_period integer,
    expected_return character varying(50),
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    target_amount numeric(15,2),
    raised_amount numeric(15,2) DEFAULT 0,
    category character varying(100),
    owner_id uuid,
    cooperative_id uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    approval_status character varying(20) DEFAULT 'pending'::character varying,
    rejected_by uuid,
    rejected_at timestamp with time zone,
    rejection_reason text,
    reviewer_comments text,
    sharia_compliant boolean DEFAULT false,
    CONSTRAINT chk_project_approval_status CHECK (((approval_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT chk_project_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'submitted'::character varying, 'approved'::character varying, 'active'::character varying, 'funded'::character varying, 'closed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT chk_project_type CHECK (((project_type)::text = ANY ((ARRAY['startup'::character varying, 'expansion'::character varying, 'equipment'::character varying])::text[]))),
    CONSTRAINT projects_current_funding_check CHECK ((current_funding >= (0)::numeric)),
    CONSTRAINT projects_investment_period_check CHECK (((investment_period >= 6) AND (investment_period <= 120))),
    CONSTRAINT projects_min_investment_check CHECK ((min_investment >= (100)::numeric)),
    CONSTRAINT projects_minimum_funding_check CHECK ((minimum_funding >= (0)::numeric)),
    CONSTRAINT projects_raised_amount_check CHECK ((raised_amount >= (0)::numeric)),
    CONSTRAINT projects_risk_level_check CHECK (((risk_level)::text = ANY ((ARRAY['Low'::character varying, 'Medium'::character varying, 'High'::character varying])::text[]))),
    CONSTRAINT projects_target_amount_check CHECK ((target_amount >= (1000)::numeric))
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: COLUMN projects.project_image_1; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.project_image_1 IS 'Primary project image URL from AWS S3';


--
-- Name: COLUMN projects.project_image_2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.project_image_2 IS 'Secondary project image URL from AWS S3';


--
-- Name: COLUMN projects.project_image_3; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.project_image_3 IS 'Tertiary project image URL from AWS S3';


--
-- Name: COLUMN projects.min_investment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.min_investment IS 'Minimum investment amount per investor';


--
-- Name: COLUMN projects.risk_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.risk_level IS 'Project risk level: Low, Medium, or High';


--
-- Name: COLUMN projects.investment_period; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.investment_period IS 'Investment period in months (6-120)';


--
-- Name: COLUMN projects.expected_return; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.expected_return IS 'Expected return percentage or description';


--
-- Name: COLUMN projects.start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.start_date IS 'Project start date';


--
-- Name: COLUMN projects.end_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.end_date IS 'Project end date';


--
-- Name: COLUMN projects.target_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.target_amount IS 'Target funding amount';


--
-- Name: COLUMN projects.raised_amount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.raised_amount IS 'Current raised amount';


--
-- Name: COLUMN projects.category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.projects.category IS 'Project category (Agriculture, Technology, etc.)';


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    email character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    phone character varying(50),
    address text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    cooperative_id uuid,
    roles jsonb DEFAULT '["guest"]'::jsonb,
    kyc_status character varying(20) DEFAULT 'pending'::character varying,
    user_profile_image character varying(500),
    membership_payment_proof character varying(500)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: COLUMN users.user_profile_image; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.user_profile_image IS 'User profile image URL from AWS S3';


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: businesses businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (id);


--
-- Name: cooperatives cooperatives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cooperatives
    ADD CONSTRAINT cooperatives_pkey PRIMARY KEY (id);


--
-- Name: cooperatives cooperatives_registration_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cooperatives
    ADD CONSTRAINT cooperatives_registration_number_key UNIQUE (registration_number);


--
-- Name: idempotency_keys idempotency_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.idempotency_keys
    ADD CONSTRAINT idempotency_keys_pkey PRIMARY KEY (id);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: investment_returns investment_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_pkey PRIMARY KEY (id);


--
-- Name: investment_returns investment_returns_transaction_ref_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_transaction_ref_key UNIQUE (transaction_ref);


--
-- Name: investments investments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_pkey PRIMARY KEY (id);


--
-- Name: investments investments_transaction_ref_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_transaction_ref_key UNIQUE (transaction_ref);


--
-- Name: profit_distributions profit_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profit_distributions
    ADD CONSTRAINT profit_distributions_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: investment_returns unique_investment_distribution; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT unique_investment_distribution UNIQUE (investment_id, distribution_id);


--
-- Name: investments unique_investor_project; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT unique_investor_project UNIQUE (project_id, investor_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at DESC);


--
-- Name: idx_audit_logs_entity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity_id ON public.audit_logs USING btree (entity_id);


--
-- Name: idx_audit_logs_entity_operation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity_operation ON public.audit_logs USING btree (entity_type, entity_id, operation);


--
-- Name: idx_audit_logs_entity_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_entity_type ON public.audit_logs USING btree (entity_type);


--
-- Name: idx_audit_logs_operation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_operation ON public.audit_logs USING btree (operation);


--
-- Name: idx_audit_logs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_status ON public.audit_logs USING btree (status);


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_audit_logs_user_operation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user_operation ON public.audit_logs USING btree (user_id, operation, created_at DESC);


--
-- Name: idx_businesses_approval_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_approval_status ON public.businesses USING btree (approval_status);


--
-- Name: idx_businesses_approved_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_approved_at ON public.businesses USING btree (approved_at);


--
-- Name: idx_businesses_approved_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_approved_by ON public.businesses USING btree (approved_by);


--
-- Name: idx_businesses_business_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_business_type ON public.businesses USING btree (business_type);


--
-- Name: idx_businesses_cooperative_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_cooperative_id ON public.businesses USING btree (cooperative_id);


--
-- Name: idx_businesses_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_created_at ON public.businesses USING btree (created_at);


--
-- Name: idx_businesses_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_email ON public.businesses USING btree (email);


--
-- Name: idx_businesses_industry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_industry ON public.businesses USING btree (industry);


--
-- Name: idx_businesses_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_is_active ON public.businesses USING btree (is_active);


--
-- Name: idx_businesses_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_name ON public.businesses USING btree (name);


--
-- Name: idx_businesses_name_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_name_type ON public.businesses USING btree (name, business_type);


--
-- Name: idx_businesses_owner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_owner_id ON public.businesses USING btree (owner_id);


--
-- Name: idx_businesses_registration_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_registration_number ON public.businesses USING btree (registration_number);


--
-- Name: idx_businesses_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_businesses_status ON public.businesses USING btree (status);


--
-- Name: idx_cooperatives_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_created_at ON public.cooperatives USING btree (created_at);


--
-- Name: idx_cooperatives_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_email ON public.cooperatives USING btree (email);


--
-- Name: idx_cooperatives_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_is_active ON public.cooperatives USING btree (is_active);


--
-- Name: idx_cooperatives_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_name ON public.cooperatives USING btree (name);


--
-- Name: idx_cooperatives_registration_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cooperatives_registration_number ON public.cooperatives USING btree (registration_number);


--
-- Name: idx_idempotency_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_expires_at ON public.idempotency_keys USING btree (expires_at);


--
-- Name: idx_idempotency_sequence; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_sequence ON public.idempotency_keys USING btree (sequence_number);


--
-- Name: idx_idempotency_table_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_table_name ON public.idempotency_keys USING btree (table_name);


--
-- Name: idx_idempotency_user_endpoint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idempotency_user_endpoint ON public.idempotency_keys USING btree (user_id, endpoint);


--
-- Name: idx_images_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_images_created_at ON public.images USING btree (created_at);


--
-- Name: idx_images_used_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_images_used_by ON public.images USING btree (used_by);


--
-- Name: idx_investment_returns_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_created_at ON public.investment_returns USING btree (created_at);


--
-- Name: idx_investment_returns_distribution_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_distribution_id ON public.investment_returns USING btree (distribution_id);


--
-- Name: idx_investment_returns_investment_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_investment_id ON public.investment_returns USING btree (investment_id);


--
-- Name: idx_investment_returns_payment_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_payment_date ON public.investment_returns USING btree (payment_date);


--
-- Name: idx_investment_returns_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_status ON public.investment_returns USING btree (status);


--
-- Name: idx_investment_returns_transaction_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investment_returns_transaction_ref ON public.investment_returns USING btree (transaction_ref);


--
-- Name: idx_investments_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_created_at ON public.investments USING btree (created_at);


--
-- Name: idx_investments_investment_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_investment_date ON public.investments USING btree (investment_date);


--
-- Name: idx_investments_investor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_investor_id ON public.investments USING btree (investor_id);


--
-- Name: idx_investments_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_project_id ON public.investments USING btree (project_id);


--
-- Name: idx_investments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_status ON public.investments USING btree (status);


--
-- Name: idx_investments_transaction_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_investments_transaction_ref ON public.investments USING btree (transaction_ref);


--
-- Name: idx_profit_distributions_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_created_at ON public.profit_distributions USING btree (created_at);


--
-- Name: idx_profit_distributions_distribution_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_distribution_date ON public.profit_distributions USING btree (distribution_date);


--
-- Name: idx_profit_distributions_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_project_id ON public.profit_distributions USING btree (project_id);


--
-- Name: idx_profit_distributions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profit_distributions_status ON public.profit_distributions USING btree (status);


--
-- Name: idx_projects_approval_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_approval_status ON public.projects USING btree (approval_status);


--
-- Name: idx_projects_approved_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_approved_by ON public.projects USING btree (approved_by);


--
-- Name: idx_projects_business_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_business_id ON public.projects USING btree (business_id);


--
-- Name: idx_projects_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_category ON public.projects USING btree (category);


--
-- Name: idx_projects_cooperative_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_cooperative_id ON public.projects USING btree (cooperative_id);


--
-- Name: idx_projects_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_created_at ON public.projects USING btree (created_at);


--
-- Name: idx_projects_funding_deadline; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_funding_deadline ON public.projects USING btree (funding_deadline);


--
-- Name: idx_projects_funding_goal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_funding_goal ON public.projects USING btree (funding_goal);


--
-- Name: idx_projects_investment_period; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_investment_period ON public.projects USING btree (investment_period);


--
-- Name: idx_projects_owner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_owner_id ON public.projects USING btree (owner_id);


--
-- Name: idx_projects_project_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_project_type ON public.projects USING btree (project_type);


--
-- Name: idx_projects_rejected_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_rejected_by ON public.projects USING btree (rejected_by);


--
-- Name: idx_projects_risk_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_risk_level ON public.projects USING btree (risk_level);


--
-- Name: idx_projects_start_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_start_date ON public.projects USING btree (start_date);


--
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status ON public.projects USING btree (status);


--
-- Name: idx_projects_status_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status_type ON public.projects USING btree (status, project_type);


--
-- Name: idx_projects_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_title ON public.projects USING btree (title);


--
-- Name: idx_projects_title_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_title_type ON public.projects USING btree (title, project_type);


--
-- Name: idx_users_cooperative_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_cooperative_id ON public.users USING btree (cooperative_id);


--
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_is_active ON public.users USING btree (is_active);


--
-- Name: idx_users_kyc_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_kyc_status ON public.users USING btree (kyc_status);


--
-- Name: idx_users_membership_payment_proof; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_membership_payment_proof ON public.users USING btree (membership_payment_proof) WHERE (membership_payment_proof IS NOT NULL);


--
-- Name: idx_users_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_name ON public.users USING btree (name);


--
-- Name: idx_users_name_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_name_search ON public.users USING btree (name);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- Name: idx_users_roles; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_roles ON public.users USING gin (roles);


--
-- Name: images trigger_update_images_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_images_updated_at BEFORE UPDATE ON public.images FOR EACH ROW EXECUTE FUNCTION public.update_images_updated_at();


--
-- Name: businesses update_businesses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_businesses_updated_at BEFORE UPDATE ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: cooperatives update_cooperatives_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_cooperatives_updated_at BEFORE UPDATE ON public.cooperatives FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_returns update_investment_returns_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_investment_returns_updated_at BEFORE UPDATE ON public.investment_returns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investments update_investments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_investments_updated_at BEFORE UPDATE ON public.investments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: profit_distributions update_profit_distributions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_profit_distributions_updated_at BEFORE UPDATE ON public.profit_distributions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: projects update_projects_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_returns fk_investment_returns_distribution; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT fk_investment_returns_distribution FOREIGN KEY (distribution_id) REFERENCES public.profit_distributions(id) ON DELETE CASCADE;


--
-- Name: investment_returns fk_investment_returns_investment; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT fk_investment_returns_investment FOREIGN KEY (investment_id) REFERENCES public.investments(id) ON DELETE CASCADE;


--
-- Name: investments fk_investments_investor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT fk_investments_investor FOREIGN KEY (investor_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: investments fk_investments_project; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT fk_investments_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: profit_distributions fk_profit_distributions_project; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profit_distributions
    ADD CONSTRAINT fk_profit_distributions_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: users fk_users_cooperative; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_cooperative FOREIGN KEY (cooperative_id) REFERENCES public.cooperatives(id) ON DELETE SET NULL;


--
-- Name: projects projects_rejected_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

